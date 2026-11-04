package ph.mealpal.server.bank;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
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
        assertEquals(List.of(Slot.BREAKFAST), tapsilog.slots());
        assertEquals(560, tapsilog.kcal());
        assertEquals(84, tapsilog.pricePhp());
        assertEquals("tapsilog", tapsilog.image());
    }

    @Test
    void ulamWithRiceFitsLunchOrDinner() {
        assertEquals(List.of(Slot.LUNCH, Slot.DINNER), bank.find("adobo").orElseThrow().slots());
        assertEquals(List.of(Slot.LUNCH, Slot.DINNER), bank.find("pinakbet").orElseThrow().slots());
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

    @Test
    void theAgentLinesCarryOnlyTheCurrentFieldsAndNeverIngredients() {
        for (String line : bank.asJsonLines().split("\n")) {
            assertFalse(line.contains("ingredients"), line);
            assertTrue(line.matches("\\{\"id\":\"[^\"]+\",\"slots\":\\[[^\\]]+\\],\"name\":\"[^\"]+\","
                    + "\"kcal\":\\d+,\"pricePhp\":\\d+\\}"), line);
        }
    }

    @Test
    void everyMealCarriesItsIngredientsFromTheCatalog() {
        Meal tapsilog = bank.find("tapsilog").orElseThrow();
        assertEquals(7, tapsilog.ingredients().size());
        MealIngredient tapa = tapsilog.ingredients().getFirst();
        assertEquals("beef-tapa", tapa.id());
        assertEquals(150.0, tapa.qty());
        Ingredient beef = bank.ingredient("beef-tapa").orElseThrow();
        assertEquals("Beef tapa cut", beef.name());
        assertEquals(Ingredient.Kind.MEAT, beef.kind());
        assertEquals(Ingredient.Unit.G, beef.unit());
        assertEquals(0.45, beef.pricePhpPerUnit());
        for (Meal meal : bank.meals()) {
            assertFalse(meal.ingredients().isEmpty(), meal.id());
        }
    }

    @Test
    void sharedIngredientsUseOneIdSoTheListCanAddThemUp() {
        long riceMeals = bank.meals().stream()
                .filter(m -> m.ingredients().stream().anyMatch(i -> i.id().equals("rice"))).count();
        assertTrue(riceMeals >= 6, "rice is shared");
        assertTrue(bank.ingredient("steamed-rice").isEmpty());
    }

    @Test
    void aMealPriceIsTheRoundedCostOfItsIngredients() {
        // lugaw costs 16.50: rounds half up to 17.
        assertEquals(17, bank.find("lugaw").orElseThrow().pricePhp());
        assertEquals(22, bank.find("saba-peanuts").orElseThrow().pricePhp());
    }

    private static final String CATALOG = """
            "ingredients": {
              "rice": {"name": "Rice", "kind": "grain", "unit": "g", "pricePhpPerUnit": 0.05},
              "egg": {"name": "Egg", "kind": "egg", "unit": "pc", "pricePhpPerUnit": 8}
            },""";

    private static String bankWith(String catalog, String meal) {
        return "{\"note\": \"x\", " + catalog + " \"meals\": [" + meal + "]}";
    }

    private static String meal(int price, String ingredients) {
        return "{\"id\": \"egg-rice\", \"slots\": [\"breakfast\"], \"name\": \"Egg rice\", \"kcal\": 300,"
                + " \"pricePhp\": " + price + ", \"ingredients\": [" + ingredients + "]}";
    }

    private static final String OK = "{\"id\": \"rice\", \"qty\": 100}, {\"id\": \"egg\", \"qty\": 1}";

    private static String refusal(String json) {
        return assertThrows(IllegalStateException.class, () -> MealBank.fromJson(json)).getMessage();
    }

    @Test
    void aWellFormedBankLoads() {
        // 100 g * 0.05 + 1 pc * 8 = 13
        assertEquals(13, MealBank.fromJson(bankWith(CATALOG, meal(13, OK))).meals().getFirst().pricePhp());
    }

    @Test
    void refusesAnUnknownIngredientAndNamesIt() {
        String message = refusal(bankWith(CATALOG, meal(13, OK + ", {\"id\": \"truffle\", \"qty\": 1}")));
        assertTrue(message.contains("egg-rice") && message.contains("truffle"), message);
    }

    @Test
    void refusesAQuantityThatIsNotPositive() {
        String zero = refusal(bankWith(CATALOG, meal(8, "{\"id\": \"egg\", \"qty\": 0}")));
        assertTrue(zero.contains("egg-rice") && zero.contains("egg") && zero.contains("quantity"), zero);
        refusal(bankWith(CATALOG, meal(8, "{\"id\": \"egg\", \"qty\": -1}")));
    }

    @Test
    void refusesAMealWithoutIngredients() {
        assertTrue(refusal(bankWith(CATALOG, meal(0, ""))).contains("egg-rice"));
    }

    @Test
    void refusesAnUnknownUnitOrKind() {
        String badUnit = CATALOG.replace("\"unit\": \"g\"", "\"unit\": \"cup\"");
        String unit = refusal(bankWith(badUnit, meal(13, OK)));
        assertTrue(unit.contains("rice") && unit.contains("cup"), unit);
        String badKind = CATALOG.replace("\"kind\": \"grain\"", "\"kind\": \"dessert\"");
        String kind = refusal(bankWith(badKind, meal(13, OK)));
        assertTrue(kind.contains("rice") && kind.contains("dessert"), kind);
    }

    @Test
    void refusesAPriceThatIsNotTheCostOfTheIngredients() {
        String message = refusal(bankWith(CATALOG, meal(14, OK)));
        assertTrue(message.contains("egg-rice") && message.contains("14") && message.contains("13"), message);
    }

    @Test
    void thePriceRoundsHalfUpAtTheHalfPeso() {
        // 1 pc * 8 + 10 g * 0.05 = 8.5 -> 9
        String ok = "{\"id\": \"egg\", \"qty\": 1}, {\"id\": \"rice\", \"qty\": 10}";
        assertEquals(9, MealBank.fromJson(bankWith(CATALOG, meal(9, ok))).meals().getFirst().pricePhp());
        refusal(bankWith(CATALOG, meal(8, ok)));
    }
}
