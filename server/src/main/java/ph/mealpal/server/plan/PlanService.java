package ph.mealpal.server.plan;

import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executor;
import ph.mealpal.server.agent.AgentGateway;
import ph.mealpal.server.agent.SessionEnd;
import ph.mealpal.server.agent.ToolReply;

/**
 * Runs plans: one agent session per plan, a turn to build the week and a turn
 * per swap. Plans live in memory; this is a proof of concept.
 */
public final class PlanService {

    /** Rejected submissions allowed in one turn before the plan fails. */
    static final int MAX_TRIES = 3;

    static final String SUBMIT_PLAN = "submit_plan";

    private final AgentGateway gateway;
    private final PlanCheck check;
    private final PlanBriefs briefs;
    private final Executor executor;
    private final Map<String, Plan> plans = new ConcurrentHashMap<>();

    public PlanService(AgentGateway gateway, PlanCheck check, PlanBriefs briefs, Executor executor) {
        this.gateway = gateway;
        this.check = check;
        this.briefs = briefs;
        this.executor = executor;
    }

    /** Opens the plan's session and starts building in the background. */
    public PlanRecord create(PlanRequest request) {
        String sessionId;
        try {
            sessionId = gateway.openSession("MealPal week: " + Format.thousands(request.targetKcal()) + " kcal");
        } catch (RuntimeException e) {
            throw new PlannerUnavailable("Could not open a planner session: " + e.getMessage(), e);
        }
        Plan plan = new Plan(UUID.randomUUID().toString(), sessionId, request);
        plans.put(plan.id, plan);
        executor.execute(() -> runTurn(plan, briefs.kickoff(request), false));
        return plan.snapshot();
    }

    public Optional<PlanRecord> find(String id) {
        return Optional.ofNullable(plans.get(id)).map(Plan::snapshot);
    }

    /** Sends the swap into the plan's session; the plan builds again until the new week is accepted. */
    public PlanRecord swap(String id, SwapRequest swap) {
        Plan plan = plans.get(id);
        if (plan == null) {
            throw new NoSuchElementException("No plan " + id);
        }
        synchronized (plan) {
            if (plan.status == PlanStatus.BUILDING) {
                throw new IllegalStateException("The week is still building.");
            }
            if (plan.week == null) {
                throw new IllegalStateException("There is no week to swap in.");
            }
            plan.status = PlanStatus.BUILDING;
            plan.message = null;
        }
        executor.execute(() -> runTurn(plan, briefs.swap(swap), true));
        return plan.snapshot();
    }

    private void runTurn(Plan plan, String message, boolean isSwap) {
        Turn turn = new Turn(plan);
        String failure;
        try {
            SessionEnd end = gateway.converse(plan.sessionId, message, turn::answer);
            failure = turn.accepted != null ? null : turn.gaveUp ? turn.failure : reason(end);
        } catch (RuntimeException e) {
            failure = turn.accepted != null ? null : "Lost the connection to the planner: " + e.getMessage() + ".";
        }
        synchronized (plan) {
            if (failure == null) {
                plan.week = turn.accepted;
                plan.status = PlanStatus.READY;
                plan.message = null;
            } else if (isSwap) {
                plan.status = PlanStatus.READY;
                plan.message = "The swap did not go through: " + lowerFirst(failure);
            } else {
                plan.status = PlanStatus.FAILED;
                plan.message = failure;
            }
        }
    }

    private static String reason(SessionEnd end) {
        return switch (end.kind()) {
            case END_TURN -> "The planner stopped without sending a week.";
            case BUDGET_REACHED -> "The planner hit its spending cap before it finished.";
            case FAILED -> "The planner stopped: " + end.detail() + ".";
        };
    }

    private static String lowerFirst(String s) {
        return Character.toLowerCase(s.charAt(0)) + s.substring(1);
    }

    /** One turn's tool calls: counts tries, keeps the accepted week. */
    private final class Turn {
        private final Plan plan;
        private int rejected;
        private boolean gaveUp;
        private String failure;
        private WeekPlan accepted;

        Turn(Plan plan) {
            this.plan = plan;
        }

        ToolReply answer(String tool, String input) {
            if (!SUBMIT_PLAN.equals(tool)) {
                return ToolReply.error("There is no tool called " + tool + ". Send the week with submit_plan.");
            }
            if (gaveUp) {
                return ToolReply.error("Stop. This plan has already failed.");
            }
            List<String> problems;
            SubmittedPlan submitted = null;
            try {
                submitted = PlanJson.readSubmission(input);
                problems = check.problems(plan.request, submitted);
            } catch (InvalidSubmission e) {
                problems = List.of("submit_plan input is not a valid week: " + e.getMessage());
            }
            if (problems.isEmpty()) {
                accepted = check.toWeek(submitted);
                return ToolReply.ok("Accepted. The week is saved. Reply with one short sentence and stop.");
            }
            rejected++;
            String list = "- " + String.join("\n- ", problems);
            if (rejected >= MAX_TRIES) {
                gaveUp = true;
                failure = "The planner could not fit a week to your target and budget after " + MAX_TRIES + " tries.";
                return ToolReply.error("Stop. That was the last try; the plan has failed. Problems were:\n" + list);
            }
            return ToolReply.error("Not accepted. Fix these, then call submit_plan again with the whole week:\n" + list);
        }
    }

    /** Mutable state behind a plan; guarded by its own monitor. */
    private static final class Plan {
        final String id;
        final String sessionId;
        final PlanRequest request;
        PlanStatus status = PlanStatus.BUILDING;
        WeekPlan week;
        String message;

        Plan(String id, String sessionId, PlanRequest request) {
            this.id = id;
            this.sessionId = sessionId;
            this.request = request;
        }

        synchronized PlanRecord snapshot() {
            return new PlanRecord(id, status, week, message);
        }
    }
}
