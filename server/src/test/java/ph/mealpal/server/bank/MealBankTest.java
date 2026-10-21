package ph.mealpal.server.bank;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class MealBankTest {

    private final MealBank bank = MealBank.fromClasspath("meal-bank.json");

    @Test
    void loadsTheStandInBank() {
        assertEquals(10, bank.meals().size());
    }

    @Test
    void findsAMealByIdWithItsNumbers() {
        Meal tapsilog = bank.find("tapsilog").orElseThrow();
        assertEquals(Slot.BREAKFAST, tapsilog.slot());
        assertEquals(560, tapsilog.kcal());
        assertEquals(95, tapsilog.pricePhp());
        assertEquals("tapsilog", tapsilog.image());
    }

    @Test
    void aMealWithoutAPhotoHasNoImage() {
        assertEquals(null, bank.find("adobo").orElseThrow().image());
    }

    @Test
    void anUnknownIdFindsNothing() {
        assertTrue(bank.find("lechon").isEmpty());
    }

    @Test
    void theAgentSeesEveryMealAsOneJsonLine() {
        String lines = bank.asJsonLines();
        for (Meal meal : bank.meals()) {
            assertTrue(lines.contains("\"id\":\"" + meal.id() + "\""), meal.id());
        }
        assertEquals(10, lines.strip().split("\n").length);
    }
}
