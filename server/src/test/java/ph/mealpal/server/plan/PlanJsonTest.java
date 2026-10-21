package ph.mealpal.server.plan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import ph.mealpal.server.bank.Slot;

class PlanJsonTest {

    @Test
    void readsTheSubmitPlanToolInput() {
        SubmittedPlan plan = PlanJson.readSubmission("""
                {"days": [{"weekday": "tue", "meals": [
                  {"slot": "breakfast", "meal_id": "lugaw", "servings": 1.5},
                  {"slot": "snack", "meal_id": "boiled-saba", "servings": 1}
                ]}]}
                """);
        SubmittedDay tuesday = plan.days().getFirst();
        assertEquals(Weekday.TUE, tuesday.weekday());
        assertEquals(new SubmittedMeal(Slot.BREAKFAST, "lugaw", 1.5), tuesday.meals().getFirst());
        assertEquals(new SubmittedMeal(Slot.SNACK, "boiled-saba", 1.0), tuesday.meals().getLast());
    }

    @Test
    void aMissingServingsCountsAsOne() {
        SubmittedPlan plan = PlanJson.readSubmission("""
                {"days": [{"weekday": "mon", "meals": [{"slot": "lunch", "meal_id": "adobo"}]}]}
                """);
        assertEquals(1.0, plan.days().getFirst().meals().getFirst().servings());
    }

    @Test
    void inputThatIsNotAWeekSaysWhatIsWrong() {
        InvalidSubmission e = assertThrows(InvalidSubmission.class,
                () -> PlanJson.readSubmission("{\"days\": [{\"weekday\": \"funday\", \"meals\": []}]}"));
        assertTrue(e.getMessage().contains("funday"), e.getMessage());

        assertThrows(InvalidSubmission.class, () -> PlanJson.readSubmission("not json"));
        assertThrows(InvalidSubmission.class, () -> PlanJson.readSubmission("{}"));
    }
}
