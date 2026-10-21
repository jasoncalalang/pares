package ph.mealpal.server.plan;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.bank.Slot;

class PlanBriefsTest {

    private final MealBank bank = MealBank.fromClasspath("meal-bank.json");
    private final PlanBriefs briefs = new PlanBriefs(bank);

    @Test
    void theKickoffCarriesThePersonsNumbersAndTheBank() {
        String text = briefs.kickoff(new PlanRequest(2087, 2000, Goal.LOSE, List.of("palengke", "sm-supermarket")));
        assertTrue(text.contains("2,087 kcal a day"), text);
        assertTrue(text.contains("between 1,879 and 2,295"), text);
        assertTrue(text.contains("₱2,000 for the week"), text);
        assertTrue(text.contains("palengke, sm-supermarket"), text);
        assertTrue(text.contains("Goal: lose"), text);
        assertTrue(text.contains(bank.asJsonLines()), "the whole bank goes in");
        assertTrue(text.contains("submit_plan"), text);
    }

    @Test
    void aSwapNamesTheMealAndAsksForTheWholeWeekBack() {
        String text = briefs.swap(new SwapRequest(Weekday.TUE, Slot.LUNCH, "something cheaper"));
        assertTrue(text.contains("Tuesday's lunch"), text);
        assertTrue(text.contains("something cheaper"), text);
        assertTrue(text.contains("whole week"), text);
        assertTrue(text.contains("submit_plan"), text);
    }

    @Test
    void aSwapWithoutANoteStillReads() {
        String text = briefs.swap(new SwapRequest(Weekday.SUN, Slot.SNACK, null));
        assertTrue(text.contains("Sunday's snack"), text);
        assertTrue(!text.contains("null"), text);
    }
}
