package ph.mealpal.server.bank;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;

/** The bank the server ships, held to the owner's size and calorie rules. */
class ShippedBankTest {

    private static final Map<Slot, int[]> BANDS = Map.of(
            Slot.BREAKFAST, new int[] {300, 850},
            Slot.LUNCH, new int[] {350, 950},
            Slot.DINNER, new int[] {350, 950},
            Slot.SNACK, new int[] {80, 450});

    private final MealBank bank = MealBank.fromClasspath("meal-bank.json");

    @Test
    void holdsThirtyDishesWithUniqueIds() {
        List<Meal> meals = bank.meals();
        assertEquals(30, meals.size());
        Set<String> ids = new HashSet<>();
        meals.forEach(m -> assertTrue(ids.add(m.id()), "duplicate id " + m.id()));
    }

    @Test
    void everyKcalIsInsideItsSlotBand() {
        for (Meal meal : bank.meals()) {
            for (Slot slot : meal.slots()) {
                int[] band = BANDS.get(slot);
                assertTrue(meal.kcal() >= band[0] && meal.kcal() <= band[1],
                        meal.id() + " is " + meal.kcal() + " kcal, outside the " + slot.json() + " band "
                                + band[0] + "-" + band[1]);
            }
        }
    }

    @Test
    void everySlotHasAtLeastSixDishes() {
        for (Slot slot : Slot.values()) {
            long count = bank.meals().stream().filter(m -> m.slots().contains(slot)).count();
            assertTrue(count >= 6, slot.json() + " has only " + count);
        }
    }

    @Test
    void everyIngredientNamesItsUsdaFood() {
        assertTrue(bank.meals().stream().flatMap(m -> m.ingredients().stream()).count() > 0);
        for (Meal meal : bank.meals()) {
            for (MealIngredient ref : meal.ingredients()) {
                Ingredient ing = bank.ingredient(ref.id()).orElseThrow();
                assertTrue(ing.usda().fdcId() > 0, ing.id());
                assertTrue(ing.kcalPer100g().signum() > 0, ing.id());
            }
        }
    }

    @Test
    void freshPerishablesAreNeverFiledAsPantry() {
        // A sari-sari store must not be sent fresh food (CLAUDE.md "Store assignment").
        for (String id : List.of("lumpia-wrapper", "tofu", "silken-tofu", "grated-coconut", "calamansi")) {
            assertTrue(bank.ingredient(id).orElseThrow().kind() != Ingredient.Kind.PANTRY, id);
        }
    }
}
