package ph.mealpal.server.plan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.concurrent.Executor;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import ph.mealpal.server.agent.AgentGateway;
import ph.mealpal.server.agent.SessionEnd;
import ph.mealpal.server.agent.ToolHandler;
import ph.mealpal.server.agent.ToolReply;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.bank.Slot;

class PlanServiceTest {

    private static final PlanRequest REQUEST = new PlanRequest(2087, 2000, Goal.LOSE, List.of("palengke"));

    /** The app's Monday every day: 2,087 kcal, ₱1,750 for the week. */
    private static String week(String lunch) {
        return Weekday.stream()
                .map(d -> """
                        {"weekday": "%s", "meals": [
                          {"slot": "breakfast", "meal_id": "tapsilog"},
                          {"slot": "lunch", "meal_id": "%s"},
                          {"slot": "dinner", "meal_id": "munggo"},
                          {"slot": "snack", "meal_id": "saba-peanuts"}]}""".formatted(d.json(), lunch))
                .collect(Collectors.joining(",", "{\"days\": [", "]}"));
    }

    private static final String VALID = week("tinola");
    private static final String OVER_TARGET = week("tinola").replace("\"meal_id\": \"tapsilog\"",
            "\"meal_id\": \"tapsilog\", \"servings\": 2");

    /** One scripted turn: the tool calls the agent makes, then how the turn ends. */
    record Turn(List<String[]> calls, SessionEnd end, RuntimeException failure) {
        static Turn of(SessionEnd end, String... submissions) {
            List<String[]> calls = new ArrayList<>();
            for (String s : submissions) {
                calls.add(new String[] {"submit_plan", s});
            }
            return new Turn(calls, end, null);
        }

        static Turn failing(RuntimeException e) {
            return new Turn(List.of(), null, e);
        }
    }

    static class FakeGateway implements AgentGateway {
        final Deque<Turn> turns = new ArrayDeque<>();
        final List<String> sessions = new ArrayList<>();
        final List<String> messages = new ArrayList<>();
        final List<ToolReply> replies = new ArrayList<>();
        RuntimeException openFailure;

        FakeGateway script(Turn... script) {
            turns.addAll(List.of(script));
            return this;
        }

        @Override
        public String openSession(String title) {
            if (openFailure != null) {
                throw openFailure;
            }
            String id = "sesn_" + (sessions.size() + 1);
            sessions.add(id);
            return id;
        }

        @Override
        public SessionEnd converse(String sessionId, String message, ToolHandler handler) {
            assertTrue(sessions.contains(sessionId), "talks to a session it opened");
            messages.add(message);
            Turn turn = turns.removeFirst();
            if (turn.failure() != null) {
                throw turn.failure();
            }
            for (String[] call : turn.calls()) {
                replies.add(handler.handle(call[0], call[1]));
            }
            return turn.end();
        }
    }

    private final MealBank bank = MealBank.fromClasspath("meal-bank.json");
    private final Executor now = Runnable::run;

    private PlanService service(FakeGateway gateway, Executor executor) {
        return new PlanService(gateway, new PlanCheck(bank), new PlanBriefs(bank), executor);
    }

    @Test
    void theAcceptedWeekIsPublishedWhenTheTurnEnds() {
        FakeGateway gateway = new FakeGateway().script(Turn.of(SessionEnd.endTurn(), VALID));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        assertEquals(PlanStatus.READY, plan.status());
        assertEquals(7, plan.week().days().size());
        assertEquals(1750, plan.week().pricePhp());
        assertFalse(gateway.replies.getFirst().error());
        assertTrue(gateway.messages.getFirst().contains("2,087 kcal a day"));
    }

    @Test
    void aRejectedWeekGoesBackWithItsProblemsAndTheFixIsAccepted() {
        FakeGateway gateway = new FakeGateway().script(Turn.of(SessionEnd.endTurn(), OVER_TARGET, VALID));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        ToolReply first = gateway.replies.getFirst();
        assertTrue(first.error());
        assertTrue(first.text().contains("Monday comes to 2,647 kcal"), first.text());
        assertTrue(first.text().contains("call submit_plan again"), first.text());
        assertEquals(PlanStatus.READY, plan.status());
    }

    @Test
    void threeRejectedWeeksFailThePlan() {
        FakeGateway gateway = new FakeGateway()
                .script(Turn.of(SessionEnd.endTurn(), OVER_TARGET, OVER_TARGET, OVER_TARGET));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        assertEquals(PlanStatus.FAILED, plan.status());
        assertEquals("The planner could not fit a week to your target and budget after 3 tries.", plan.message());
        assertTrue(gateway.replies.getLast().text().startsWith("Stop."), gateway.replies.getLast().text());
    }

    @Test
    void inputThatIsNotAWeekCountsAsATry() {
        FakeGateway gateway = new FakeGateway().script(Turn.of(SessionEnd.endTurn(), "not json", VALID));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        assertTrue(gateway.replies.getFirst().error());
        assertTrue(gateway.replies.getFirst().text().contains("not a valid week"), gateway.replies.getFirst().text());
        assertEquals(PlanStatus.READY, plan.status());
    }

    @Test
    void anUnknownToolIsRefused() {
        FakeGateway gateway = new FakeGateway().script(new Turn(
                List.of(new String[] {"order_groceries", "{}"}, new String[] {"submit_plan", VALID}),
                SessionEnd.endTurn(), null));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        assertTrue(gateway.replies.getFirst().error());
        assertTrue(gateway.replies.getFirst().text().contains("submit_plan"));
        assertEquals(PlanStatus.READY, plan.status());
    }

    @Test
    void stoppingWithoutAWeekFails() {
        FakeGateway gateway = new FakeGateway().script(Turn.of(SessionEnd.endTurn()));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        assertEquals(PlanStatus.FAILED, plan.status());
        assertEquals("The planner stopped without sending a week.", plan.message());
    }

    @Test
    void hittingTheSpendCapFails() {
        FakeGateway gateway = new FakeGateway().script(Turn.of(SessionEnd.budgetReached()));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        assertEquals(PlanStatus.FAILED, plan.status());
        assertEquals("The planner hit its spending cap before it finished.", plan.message());
    }

    @Test
    void aSessionErrorFailsWithItsReason() {
        FakeGateway gateway = new FakeGateway().script(Turn.of(SessionEnd.failed("retries exhausted")));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        assertEquals(PlanStatus.FAILED, plan.status());
        assertEquals("The planner stopped: retries exhausted.", plan.message());
    }

    @Test
    void losingTheConnectionMidRunFails() {
        FakeGateway gateway = new FakeGateway().script(Turn.failing(new IllegalStateException("stream closed")));
        PlanRecord plan = service(gateway, now).create(REQUEST);

        assertEquals(PlanStatus.FAILED, plan.status());
        assertEquals("Lost the connection to the planner: stream closed.", plan.message());
    }

    @Test
    void whenNoSessionCanBeOpenedCreateSaysSo() {
        FakeGateway gateway = new FakeGateway();
        gateway.openFailure = new IllegalStateException("401");
        assertThrows(PlannerUnavailable.class, () -> service(gateway, now).create(REQUEST));
    }

    @Test
    void aSwapGoesIntoTheSameSessionAndPublishesTheNewWeek() {
        FakeGateway gateway = new FakeGateway().script(
                Turn.of(SessionEnd.endTurn(), VALID),
                Turn.of(SessionEnd.endTurn(), week("adobo")));
        PlanService plans = service(gateway, now);
        PlanRecord first = plans.create(REQUEST);

        PlanRecord swapped = plans.swap(first.id(), new SwapRequest(Weekday.TUE, Slot.LUNCH, "no tinola"));

        assertEquals(1, gateway.sessions.size(), "one session for the plan's whole life");
        assertTrue(gateway.messages.getLast().contains("Tuesday's lunch"));
        assertEquals(PlanStatus.READY, swapped.status());
        assertEquals("Chicken adobo with rice", swapped.week().days().get(1).meals().get(1).name());
    }

    @Test
    void aFailedSwapKeepsTheWeekItHad() {
        FakeGateway gateway = new FakeGateway().script(
                Turn.of(SessionEnd.endTurn(), VALID),
                Turn.of(SessionEnd.endTurn()));
        PlanService plans = service(gateway, now);
        PlanRecord first = plans.create(REQUEST);

        PlanRecord after = plans.swap(first.id(), new SwapRequest(Weekday.TUE, Slot.LUNCH, null));

        assertEquals(PlanStatus.READY, after.status());
        assertEquals(first.week(), after.week());
        assertEquals("The swap did not go through: the planner stopped without sending a week.", after.message());
    }

    @Test
    void aSwapWhileTheWeekIsStillBuildingIsRefused() {
        List<Runnable> queued = new ArrayList<>();
        FakeGateway gateway = new FakeGateway().script(Turn.of(SessionEnd.endTurn(), VALID));
        PlanService plans = service(gateway, queued::add);
        PlanRecord building = plans.create(REQUEST);

        assertEquals(PlanStatus.BUILDING, building.status());
        assertThrows(IllegalStateException.class,
                () -> plans.swap(building.id(), new SwapRequest(Weekday.MON, Slot.SNACK, null)));

        queued.getFirst().run();
        assertEquals(PlanStatus.READY, plans.find(building.id()).orElseThrow().status());
    }

    @Test
    void plansAreFoundByIdAndUnknownIdsAreNot() {
        FakeGateway gateway = new FakeGateway().script(Turn.of(SessionEnd.endTurn(), VALID));
        PlanService plans = service(gateway, now);
        PlanRecord plan = plans.create(REQUEST);

        assertNotNull(plans.find(plan.id()).orElse(null));
        assertTrue(plans.find("nope").isEmpty());
        assertThrows(java.util.NoSuchElementException.class,
                () -> plans.swap("nope", new SwapRequest(Weekday.MON, Slot.SNACK, null)));
    }
}
