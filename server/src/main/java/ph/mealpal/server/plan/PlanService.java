package ph.mealpal.server.plan;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.Set;
import ph.mealpal.server.agent.AgentGateway;
import ph.mealpal.server.agent.SessionEvent;
import ph.mealpal.server.agent.SessionEvent.Idle;
import ph.mealpal.server.agent.SessionEvent.Stop;
import ph.mealpal.server.agent.SessionEvent.ToolCall;
import ph.mealpal.server.agent.SessionEvent.ToolResult;
import ph.mealpal.server.agent.SessionEvent.UserMessage;
import ph.mealpal.server.agent.SessionView;
import ph.mealpal.server.agent.ToolReply;

/**
 * Plans with no server-side state. A plan is its agent session: the request
 * rides in the session's metadata, and every read replays the session's
 * events, answers any submit_plan still waiting on the server, and reports
 * where the plan stands. The app's polling is what moves a plan along, so any
 * instance can serve any read and nothing is lost when one stops.
 */
public final class PlanService {

    /** Rejected submissions allowed in one turn before the plan fails. */
    static final int MAX_TRIES = 3;

    static final String SUBMIT_PLAN = "submit_plan";

    private final AgentGateway gateway;
    private final PlanCheck check;
    private final PlanBriefs briefs;

    public PlanService(AgentGateway gateway, PlanCheck check, PlanBriefs briefs) {
        this.gateway = gateway;
        this.check = check;
        this.briefs = briefs;
    }

    /** Starts the plan's session; the planner begins work straight away. */
    public PlanRecord create(PlanRequest request) {
        String id;
        try {
            id = gateway.startSession("MealPal week: " + Format.thousands(request.targetKcal()) + " kcal",
                    PlanMeta.write(request), briefs.kickoff(request));
        } catch (RuntimeException e) {
            throw new PlannerUnavailable("Could not open a planner session: " + e.getMessage(), e);
        }
        return new PlanRecord(id, PlanStatus.BUILDING, null, null);
    }

    /** Reads the plan, answering whatever the planner is waiting on. Empty for anything that is not a MealPal plan. */
    public Optional<PlanRecord> find(String id) {
        Optional<SessionView> view = gateway.view(id);
        Optional<PlanRequest> request = view.flatMap(v -> PlanMeta.read(v.metadata()));
        if (request.isEmpty()) {
            return Optional.empty();
        }
        History history = new History(view.get().events(), request.get());
        boolean answered = history.answerPending(id);
        return Optional.of(history.record(id, answered));
    }

    /** Sends the swap into the plan's session; the plan builds again until the new week is accepted. */
    public PlanRecord swap(String id, SwapRequest swap) {
        PlanRecord plan = find(id).orElseThrow(() -> new NoSuchElementException("No plan " + id));
        if (plan.status() == PlanStatus.BUILDING) {
            throw new IllegalStateException("The week is still building.");
        }
        if (plan.week() == null) {
            throw new IllegalStateException("There is no week to swap in.");
        }
        gateway.sendMessage(id, briefs.swap(swap));
        return new PlanRecord(id, PlanStatus.BUILDING, plan.week(), null);
    }

    /** One pass over a session's events: the turns so far and where the current one stands. */
    private final class History {
        private final PlanRequest request;
        private final Map<String, ToolCall> calls = new HashMap<>();
        private final Set<String> answered = new HashSet<>();
        private int turns;
        private String turnMessage;
        private List<ToolCall> turnCalls = new ArrayList<>();
        private WeekPlan earlierWeek;
        private WeekPlan acceptedThisTurn;
        private int rejectedThisTurn;
        private Stop lastStop;

        History(List<SessionEvent> events, PlanRequest request) {
            this.request = request;
            for (SessionEvent event : events) {
                switch (event) {
                    case UserMessage m -> startTurn(m.text());
                    case ToolCall c -> {
                        calls.put(c.id(), c);
                        turnCalls.add(c);
                    }
                    case ToolResult r -> recordResult(r);
                    case Idle i -> lastStop = i.stop();
                }
            }
        }

        private void startTurn(String message) {
            turns++;
            if (acceptedThisTurn != null) {
                earlierWeek = acceptedThisTurn;
            }
            acceptedThisTurn = null;
            rejectedThisTurn = 0;
            lastStop = null;
            turnMessage = message;
            turnCalls = new ArrayList<>();
        }

        private void recordResult(ToolResult r) {
            answered.add(r.toolUseId());
            ToolCall call = calls.get(r.toolUseId());
            if (call == null || !SUBMIT_PLAN.equals(call.name())) {
                return;
            }
            if (r.error()) {
                rejectedThisTurn++;
            } else {
                try {
                    acceptedThisTurn = check.toWeek(PlanJson.readSubmission(call.inputJson()));
                } catch (InvalidSubmission | NoSuchElementException e) {
                    // Only a week that passed the check is ever accepted; a bank change since can orphan it.
                }
            }
        }

        /** Answers the calls of the current turn that have no result yet; true when any were answered. */
        boolean answerPending(String sessionId) {
            List<ToolCall> pending = turnCalls.stream().filter(c -> !answered.contains(c.id())).toList();
            for (ToolCall call : pending) {
                ToolReply reply = answer(call);
                gateway.sendToolResult(sessionId, call.id(), reply);
                answered.add(call.id());
            }
            return !pending.isEmpty();
        }

        private ToolReply answer(ToolCall call) {
            if (!SUBMIT_PLAN.equals(call.name())) {
                return ToolReply.error("There is no tool called " + call.name() + ". Send the week with submit_plan.");
            }
            if (rejectedThisTurn >= MAX_TRIES) {
                return ToolReply.error("Stop. This plan has already failed.");
            }
            SubmittedPlan submitted = null;
            List<String> problems;
            try {
                submitted = PlanJson.readSubmission(call.inputJson());
                problems = check.problems(request, submitted);
            } catch (InvalidSubmission e) {
                problems = List.of("submit_plan input is not a valid week: " + e.getMessage());
            }
            if (problems.isEmpty()) {
                acceptedThisTurn = check.toWeek(submitted);
                return ToolReply.ok("Accepted. The week is saved. Reply with one short sentence and stop.");
            }
            rejectedThisTurn++;
            String list = "- " + String.join("\n- ", problems);
            if (rejectedThisTurn >= MAX_TRIES) {
                return ToolReply.error("Stop. That was the last try; the plan has failed. Problems were:\n" + list);
            }
            return ToolReply.error("Not accepted. Fix these, then call submit_plan again with the whole week:\n" + list);
        }

        PlanRecord record(String id, boolean answeredNow) {
            boolean ended = !answeredNow && lastStop != null && lastStop != Stop.REQUIRES_ACTION;
            boolean gaveUp = rejectedThisTurn >= MAX_TRIES;
            String tries = "The planner could not fit a week to your target and budget after " + MAX_TRIES + " tries.";
            if (turns <= 1) {
                if (gaveUp) {
                    return new PlanRecord(id, PlanStatus.FAILED, null, tries);
                }
                if (ended) {
                    return acceptedThisTurn != null
                            ? new PlanRecord(id, PlanStatus.READY, acceptedThisTurn, null)
                            : new PlanRecord(id, PlanStatus.FAILED, null, reason(lastStop));
                }
                return new PlanRecord(id, PlanStatus.BUILDING, null, null);
            }
            if (!ended) {
                return new PlanRecord(id, PlanStatus.BUILDING, earlierWeek, null);
            }
            if (acceptedThisTurn != null) {
                return new PlanRecord(id, PlanStatus.READY, acceptedThisTurn, unchangedSwap());
            }
            String why = gaveUp ? tries : reason(lastStop);
            return new PlanRecord(id, PlanStatus.READY, earlierWeek, "The swap did not go through: " + lowerFirst(why));
        }

        /** Says so when a swap's accepted week still has the meal the person asked to change. */
        private String unchangedSwap() {
            Optional<SwapRequest> swap = briefs.readSwap(turnMessage);
            if (swap.isEmpty() || earlierWeek == null) {
                return null;
            }
            PlannedMeal before = mealAt(earlierWeek, swap.get());
            PlannedMeal after = mealAt(acceptedThisTurn, swap.get());
            if (before == null || after == null || !before.id().equals(after.id())) {
                return null;
            }
            return "No other " + swap.get().slot().json() + " in the meal bank fits this week, so "
                    + swap.get().weekday().label() + " keeps " + after.name() + ".";
        }
    }

    private static PlannedMeal mealAt(WeekPlan week, SwapRequest swap) {
        return week.days().stream()
                .filter(d -> d.weekday() == swap.weekday())
                .flatMap(d -> d.meals().stream())
                .filter(m -> m.slot() == swap.slot())
                .findFirst()
                .orElse(null);
    }

    private static String reason(Stop stop) {
        return switch (stop) {
            case END_TURN -> "The planner stopped without sending a week.";
            case BUDGET_REACHED -> "The planner hit its spending cap before it finished.";
            case RETRIES_EXHAUSTED -> "The planner stopped: it ran out of retries.";
            case REFUSAL -> "The planner stopped: the request was refused.";
            case TERMINATED -> "The planner stopped: the session ended.";
            case REQUIRES_ACTION, OTHER -> "The planner stopped for an unknown reason.";
        };
    }

    private static String lowerFirst(String s) {
        return Character.toLowerCase(s.charAt(0)) + s.substring(1);
    }
}
