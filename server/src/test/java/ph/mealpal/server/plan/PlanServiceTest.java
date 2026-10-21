package ph.mealpal.server.plan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import ph.mealpal.server.agent.FakeAgent;
import ph.mealpal.server.agent.FakeAgent.Turn;
import ph.mealpal.server.agent.SessionEvent.Stop;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.bank.Slot;

/**
 * The server keeps no plan state: each read of a plan replays its agent
 * session, answers any submit_plan waiting for the server, and reports where
 * the plan stands. These tests poll the way the app does.
 */
class PlanServiceTest {

    private static final PlanRequest REQUEST = new PlanRequest(2087, 2000, Goal.LOSE, List.of("palengke", "sm"));

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
    private static final String OVER_TARGET = VALID.replace("\"meal_id\": \"tapsilog\"",
            "\"meal_id\": \"tapsilog\", \"servings\": 2");

    private final MealBank bank = MealBank.fromClasspath("meal-bank.json");
    private final FakeAgent agent = new FakeAgent();
    private final PlanService plans = new PlanService(agent, new PlanCheck(bank), new PlanBriefs(bank));

    /** Reads the plan until it stops building, as the app's polling does. */
    private PlanRecord settle(String id) {
        PlanRecord plan = null;
        for (int i = 0; i < 20; i++) {
            plan = plans.find(id).orElseThrow();
            if (plan.status() != PlanStatus.BUILDING) {
                return plan;
            }
        }
        return plan;
    }

    @Test
    void creatingAPlanStartsASessionWithTheKickoffAndAnswersBuilding() {
        agent.script(Turn.submitting(Stop.END_TURN, VALID));
        PlanRecord plan = plans.create(REQUEST);

        assertEquals(PlanStatus.BUILDING, plan.status());
        assertNull(plan.week());
        assertTrue(agent.messages.getFirst().contains("2,087 kcal a day"));
        assertTrue(agent.replies.isEmpty(), "nothing is answered until the plan is read");
    }

    @Test
    void readingThePlanAnswersTheSubmissionAndTheWeekIsReadyWhenTheTurnEnds() {
        agent.script(Turn.submitting(Stop.END_TURN, VALID));
        String id = plans.create(REQUEST).id();

        PlanRecord first = plans.find(id).orElseThrow();
        assertEquals(PlanStatus.BUILDING, first.status(), "answered, but the agent has not finished its turn");
        assertFalse(agent.replies.getFirst().error());

        PlanRecord ready = plans.find(id).orElseThrow();
        assertEquals(PlanStatus.READY, ready.status());
        assertEquals(7, ready.week().days().size());
        assertEquals(1750, ready.week().pricePhp());
        assertEquals(1, agent.replies.size(), "each submission is answered once");
    }

    @Test
    void theRequestTravelsWithTheSessionSoAnyServerCanCheckIt() {
        agent.script(Turn.submitting(Stop.END_TURN, VALID));
        String id = plans.create(REQUEST).id();
        PlanService another = new PlanService(agent, new PlanCheck(bank), new PlanBriefs(bank));

        PlanRecord plan = another.find(id).orElseThrow();
        plan = another.find(id).orElseThrow();
        assertEquals(PlanStatus.READY, plan.status());
    }

    @Test
    void aRejectedWeekGoesBackWithItsProblemsAndTheFixIsAccepted() {
        agent.script(Turn.submitting(Stop.END_TURN, OVER_TARGET, VALID));
        PlanRecord plan = settle(plans.create(REQUEST).id());

        assertTrue(agent.replies.getFirst().error());
        assertTrue(agent.replies.getFirst().text().contains("Monday comes to 2,647 kcal"));
        assertTrue(agent.replies.getFirst().text().contains("call submit_plan again"));
        assertEquals(PlanStatus.READY, plan.status());
    }

    @Test
    void threeRejectedWeeksFailThePlan() {
        agent.script(Turn.submitting(Stop.END_TURN, OVER_TARGET, OVER_TARGET, OVER_TARGET));
        PlanRecord plan = settle(plans.create(REQUEST).id());

        assertEquals(PlanStatus.FAILED, plan.status());
        assertEquals("The planner could not fit a week to your target and budget after 3 tries.", plan.message());
        assertTrue(agent.replies.getLast().text().startsWith("Stop."));
    }

    @Test
    void submissionsAfterGivingUpAreToldToStop() {
        agent.script(Turn.submitting(Stop.END_TURN, OVER_TARGET, OVER_TARGET, OVER_TARGET, VALID));
        String id = plans.create(REQUEST).id();
        assertEquals(PlanStatus.FAILED, settle(id).status(), "failed as soon as the third week is rejected");

        PlanRecord later = plans.find(id).orElseThrow();
        assertEquals(PlanStatus.FAILED, later.status());
        assertEquals("Stop. This plan has already failed.", agent.replies.getLast().text());
    }

    @Test
    void inputThatIsNotAWeekCountsAsATry() {
        agent.script(Turn.submitting(Stop.END_TURN, "not json", VALID));
        PlanRecord plan = settle(plans.create(REQUEST).id());

        assertTrue(agent.replies.getFirst().text().contains("not a valid week"));
        assertEquals(PlanStatus.READY, plan.status());
    }

    @Test
    void anUnknownToolIsRefusedWithoutCountingAsATry() {
        agent.script(new Turn(List.of(
                new String[] {"order_groceries", "{}"},
                new String[] {"submit_plan", OVER_TARGET},
                new String[] {"submit_plan", OVER_TARGET},
                new String[] {"submit_plan", VALID}), Stop.END_TURN));
        PlanRecord plan = settle(plans.create(REQUEST).id());

        assertTrue(agent.replies.getFirst().error());
        assertTrue(agent.replies.getFirst().text().contains("submit_plan"));
        assertEquals(PlanStatus.READY, plan.status());
    }

    @Test
    void stoppingWithoutAWeekFails() {
        agent.script(Turn.submitting(Stop.END_TURN));
        PlanRecord plan = settle(plans.create(REQUEST).id());

        assertEquals(PlanStatus.FAILED, plan.status());
        assertEquals("The planner stopped without sending a week.", plan.message());
    }

    @Test
    void hittingTheSpendCapFails() {
        agent.script(Turn.submitting(Stop.BUDGET_REACHED));
        PlanRecord plan = settle(plans.create(REQUEST).id());

        assertEquals("The planner hit its spending cap before it finished.", plan.message());
    }

    @Test
    void aSessionThatGivesUpFailsWithTheReason() {
        agent.script(Turn.submitting(Stop.RETRIES_EXHAUSTED));
        assertEquals("The planner stopped: it ran out of retries.", settle(plans.create(REQUEST).id()).message());

        agent.script(Turn.submitting(Stop.TERMINATED));
        assertEquals("The planner stopped: the session ended.", settle(plans.create(REQUEST).id()).message());
    }

    @Test
    void whenNoSessionCanBeStartedCreateSaysSo() {
        agent.startFailure = new IllegalStateException("401");
        PlannerUnavailable e = assertThrows(PlannerUnavailable.class, () -> plans.create(REQUEST));
        assertEquals("Could not open a planner session: 401", e.getMessage());
    }

    @Test
    void aSwapGoesIntoTheSameSessionAndPublishesTheNewWeek() {
        agent.script(Turn.submitting(Stop.END_TURN, VALID), Turn.submitting(Stop.END_TURN, week("adobo")));
        PlanRecord first = settle(plans.create(REQUEST).id());

        PlanRecord building = plans.swap(first.id(), new SwapRequest(Weekday.TUE, Slot.LUNCH, "no tinola"));
        assertEquals(PlanStatus.BUILDING, building.status());
        assertEquals(first.week(), building.week(), "the last week stays visible while the swap builds");

        PlanRecord swapped = settle(first.id());
        assertEquals(1, agent.sessionCount(), "one session for the plan's whole life");
        assertTrue(agent.messages.getLast().contains("Tuesday's lunch"));
        assertEquals(PlanStatus.READY, swapped.status());
        assertNull(swapped.message());
        assertEquals("Chicken adobo with rice", swapped.week().days().get(1).meals().get(1).name());
    }

    @Test
    void aSwapThatLeavesTheMealAsItWasSaysSo() {
        agent.script(Turn.submitting(Stop.END_TURN, VALID), Turn.submitting(Stop.END_TURN, VALID));
        String id = settle(plans.create(REQUEST).id()).id();
        plans.swap(id, new SwapRequest(Weekday.TUE, Slot.LUNCH, "no chicken"));

        PlanRecord after = settle(id);
        assertEquals(PlanStatus.READY, after.status());
        assertEquals("No other lunch in the meal bank fits this week, so Tuesday keeps "
                + "Chicken tinola with moringa and rice.", after.message());
    }

    @Test
    void aFailedSwapKeepsTheWeekItHad() {
        agent.script(Turn.submitting(Stop.END_TURN, VALID), Turn.submitting(Stop.END_TURN));
        PlanRecord first = settle(plans.create(REQUEST).id());
        plans.swap(first.id(), new SwapRequest(Weekday.TUE, Slot.LUNCH, null));

        PlanRecord after = settle(first.id());
        assertEquals(PlanStatus.READY, after.status());
        assertEquals(first.week(), after.week());
        assertEquals("The swap did not go through: the planner stopped without sending a week.", after.message());
    }

    @Test
    void aSwapThatRunsOutOfTriesKeepsTheWeekItHad() {
        agent.script(Turn.submitting(Stop.END_TURN, VALID),
                Turn.submitting(Stop.END_TURN, OVER_TARGET, OVER_TARGET, OVER_TARGET));
        PlanRecord first = settle(plans.create(REQUEST).id());
        plans.swap(first.id(), new SwapRequest(Weekday.WED, Slot.DINNER, null));

        PlanRecord after = settle(first.id());
        assertEquals(PlanStatus.READY, after.status());
        assertEquals(first.week(), after.week());
        assertTrue(after.message().startsWith("The swap did not go through: the planner could not fit"),
                after.message());
    }

    @Test
    void aSwapWhileTheWeekIsStillBuildingIsRefused() {
        agent.script(Turn.submitting(Stop.END_TURN, VALID));
        String id = plans.create(REQUEST).id();

        assertThrows(IllegalStateException.class,
                () -> plans.swap(id, new SwapRequest(Weekday.MON, Slot.SNACK, null)));
    }

    @Test
    void aFailedPlanCannotBeSwapped() {
        agent.script(Turn.submitting(Stop.END_TURN));
        String id = settle(plans.create(REQUEST).id()).id();

        assertThrows(IllegalStateException.class,
                () -> plans.swap(id, new SwapRequest(Weekday.MON, Slot.SNACK, null)));
    }

    @Test
    void onlyMealPalSessionsAreReadAsPlans() {
        assertTrue(plans.find("nope").isEmpty());
        assertTrue(plans.find(agent.foreignSession()).isEmpty(), "another app's session in the workspace");
        assertThrows(NoSuchElementException.class,
                () -> plans.swap("nope", new SwapRequest(Weekday.MON, Slot.SNACK, null)));
    }
}
