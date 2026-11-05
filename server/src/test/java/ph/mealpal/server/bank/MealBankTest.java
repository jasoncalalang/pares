package ph.mealpal.server.bank;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.util.List;
import org.junit.jupiter.api.Test;

class MealBankTest {

    private final MealBank bank = MealBank.fromClasspath("meal-bank.json");

    @Test
    void loadsTheShippedBank() {
        assertEquals(30, bank.meals().size());
    }

    @Test
    void findsAMealByIdWithItsNumbers() {
        Meal tapsilog = bank.find("tapsilog").orElseThrow();
        assertEquals(List.of(Slot.BREAKFAST), tapsilog.slots());
        assertEquals(797, tapsilog.kcal());
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
        assertEquals(30, lines.strip().split("\n").length);
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

    private static final String RICE = "\"rice\": {\"name\": \"Rice\", \"kind\": \"grain\", \"unit\": \"g\","
            + " \"pricePhpPerUnit\": 0.05, \"kcalPer100g\": 365, \"gramsPerUnit\": 1,"
            + " \"usda\": {\"fdcId\": 168877, \"description\": \"Rice, white, long-grain, regular, raw, enriched\","
            + " \"match\": \"exact\"}}";

    private static final String EGG = "\"egg\": {\"name\": \"Egg\", \"kind\": \"egg\", \"unit\": \"pc\","
            + " \"pricePhpPerUnit\": 8, \"kcalPer100g\": 143, \"gramsPerUnit\": 50,"
            + " \"usda\": {\"fdcId\": 171287, \"description\": \"Egg, whole, raw, fresh\", \"match\": \"exact\"},"
            + " \"portion\": {\"label\": \"1 large\", \"grams\": 50}}";

    private static final String OIL = "\"oil\": {\"name\": \"Cooking oil\", \"kind\": \"oil\", \"unit\": \"ml\","
            + " \"pricePhpPerUnit\": 0.11, \"kcalPer100g\": 884, \"gramsPerUnit\": 0.92,"
            + " \"usda\": {\"fdcId\": 171411, \"description\": \"Oil, soybean, salad or cooking\","
            + " \"match\": \"closest\", \"note\": \"Philippine oil is coconut or palm olein; all pure oils are about 884 kcal\"},"
            + " \"portion\": {\"label\": \"1 tbsp\", \"grams\": 13.6, \"ml\": 14.787}}";

    private static final String CHICKEN = "\"chicken\": {\"name\": \"Chicken (bone-in)\", \"kind\": \"poultry\","
            + " \"unit\": \"g\", \"pricePhpPerUnit\": 0.2, \"kcalPer100g\": 215, \"gramsPerUnit\": 1,"
            + " \"usda\": {\"fdcId\": 171447, \"description\": \"Chicken, broilers or fryers, meat and skin, raw\","
            + " \"match\": \"closest\", \"note\": \"bone-in pieces; USDA meat and skin\"},"
            + " \"edible\": {\"fraction\": 0.608, \"note\": \"USDA 171447 yield: 276 g from 453.6 g\"}}";

    private static String catalog(String... entries) {
        return "\"ingredients\": {" + String.join(",\n", entries) + "},";
    }

    private static final String CATALOG = catalog(RICE, EGG);

    private static String bankWith(String catalog, String meal) {
        return "{\"note\": \"x\", " + catalog + " \"meals\": [" + meal + "]}";
    }

    private static String meal(int kcal, int price, String ingredients) {
        return "{\"id\": \"egg-rice\", \"slots\": [\"breakfast\"], \"name\": \"Egg rice\", \"kcal\": " + kcal
                + ", \"pricePhp\": " + price + ", \"ingredients\": [" + ingredients + "]}";
    }

    /** 100 g rice + 1 egg: 365 + 71.5 = 436.5 kcal, which rounds half up to 437. Costs 13. */
    private static final String OK = "{\"id\": \"rice\", \"qty\": 100}, {\"id\": \"egg\", \"qty\": 1}";

    private static String refusal(String json) {
        return assertThrows(IllegalStateException.class, () -> MealBank.fromJson(json)).getMessage();
    }

    private static String refusalOf(String ingredientEntry, String edit, String to) {
        assertTrue(ingredientEntry.contains(edit), "test fixture lacks " + edit);
        String edited = ingredientEntry.replace(edit, to);
        return refusal(bankWith(catalog(ingredientEntry == RICE ? edited : RICE, ingredientEntry == EGG ? edited : EGG),
                meal(437, 13, OK)));
    }

    private static void assertNames(String message, String... parts) {
        for (String part : parts) {
            assertTrue(message.contains(part), "'" + part + "' missing from: " + message);
        }
    }

    @Test
    void aWellFormedBankLoads() {
        Meal meal = MealBank.fromJson(bankWith(CATALOG, meal(437, 13, OK))).meals().getFirst();
        assertEquals(13, meal.pricePhp());
        assertEquals(437, meal.kcal());
    }

    @Test
    void refusesAnUnknownIngredientAndNamesIt() {
        String message = refusal(bankWith(CATALOG, meal(437, 13, OK + ", {\"id\": \"truffle\", \"qty\": 1}")));
        assertNames(message, "egg-rice", "truffle");
    }

    @Test
    void refusesAQuantityThatIsNotPositive() {
        String zero = refusal(bankWith(CATALOG, meal(72, 8, "{\"id\": \"egg\", \"qty\": 0}")));
        assertNames(zero, "egg-rice", "egg", "quantity");
        refusal(bankWith(CATALOG, meal(72, 8, "{\"id\": \"egg\", \"qty\": -1}")));
    }

    @Test
    void refusesAMealWithoutIngredients() {
        assertTrue(refusal(bankWith(CATALOG, meal(0, 0, ""))).contains("egg-rice"));
    }

    @Test
    void refusesAnUnknownUnitOrKind() {
        assertNames(refusalOf(RICE, "\"unit\": \"g\"", "\"unit\": \"cup\""), "rice", "cup");
        assertNames(refusalOf(RICE, "\"kind\": \"grain\"", "\"kind\": \"dessert\""), "rice", "dessert");
    }

    @Test
    void refusesAPriceThatIsNotTheCostOfTheIngredients() {
        String message = refusal(bankWith(CATALOG, meal(437, 14, OK)));
        assertNames(message, "egg-rice", "14", "13");
    }

    @Test
    void thePriceRoundsHalfUpAtTheHalfPeso() {
        // 1 pc * 8 + 10 g * 0.05 = 8.5 -> 9; 72 kcal is 71.5 + 36.5 = 108 here, so the kcal is 108.
        String ok = "{\"id\": \"egg\", \"qty\": 1}, {\"id\": \"rice\", \"qty\": 10}";
        assertEquals(9, MealBank.fromJson(bankWith(CATALOG, meal(108, 9, ok))).meals().getFirst().pricePhp());
        refusal(bankWith(CATALOG, meal(108, 8, ok)));
    }

    // ---- USDA fields on an ingredient

    @Test
    void anIngredientKeepsItsUsdaSource() {
        MealBank bank = MealBank.fromJson(bankWith(catalog(RICE, EGG, OIL, CHICKEN), meal(437, 13, OK)));
        Ingredient rice = bank.ingredient("rice").orElseThrow();
        assertEquals(0, new BigDecimal("365").compareTo(rice.kcalPer100g()));
        assertEquals(0, BigDecimal.ONE.compareTo(rice.gramsPerUnit()));
        assertEquals(168877, rice.usda().fdcId());
        assertEquals("Rice, white, long-grain, regular, raw, enriched", rice.usda().description());
        assertEquals("exact", rice.usda().match());
        assertEquals(null, rice.portion());
        assertEquals(null, rice.edible());
        assertEquals("1 large", bank.ingredient("egg").orElseThrow().portion().label());
        assertEquals(0, new BigDecimal("14.787").compareTo(bank.ingredient("oil").orElseThrow().portion().ml()));
        assertEquals("closest", bank.ingredient("oil").orElseThrow().usda().match());
        assertEquals(0, new BigDecimal("0.608").compareTo(bank.ingredient("chicken").orElseThrow().edible().fraction()));
    }

    @Test
    void refusesAnIngredientWithoutAUsdaSource() {
        String noUsda = RICE.replaceAll(", \"usda\": \\{.*\\}\\}$", "}");
        assertNames(refusal(bankWith(catalog(noUsda, EGG), meal(437, 13, OK))), "rice", "usda");
    }

    @Test
    void refusesAMissingOrNonPositiveFdcId() {
        assertNames(refusalOf(RICE, "\"fdcId\": 168877, ", ""), "rice", "fdcId");
        assertNames(refusalOf(RICE, "\"fdcId\": 168877", "\"fdcId\": 0"), "rice", "fdcId");
    }

    @Test
    void refusesABlankUsdaDescription() {
        assertNames(refusalOf(RICE, "\"description\": \"Rice, white, long-grain, regular, raw, enriched\"",
                "\"description\": \"  \""), "rice", "description");
        assertNames(refusalOf(RICE, "\"description\": \"Rice, white, long-grain, regular, raw, enriched\",", ""),
                "rice", "description");
    }

    @Test
    void refusesAMatchThatIsNeitherExactNorClosest() {
        assertNames(refusalOf(RICE, "\"match\": \"exact\"", "\"match\": \"roughly\""), "rice", "match", "roughly");
        assertNames(refusalOf(RICE, ", \"match\": \"exact\"", ""), "rice", "match");
    }

    @Test
    void aClosestMatchMustSayWhatDiffers() {
        assertNames(refusalOf(RICE, "\"match\": \"exact\"", "\"match\": \"closest\""), "rice", "closest", "note");
        assertNames(refusalOf(RICE, "\"match\": \"exact\"", "\"match\": \"closest\", \"note\": \" \""),
                "rice", "note");
    }

    @Test
    void refusesKcalPer100gThatIsMissingOrNotPositive() {
        assertNames(refusalOf(RICE, "\"kcalPer100g\": 365,", ""), "rice", "kcalPer100g");
        assertNames(refusalOf(RICE, "\"kcalPer100g\": 365", "\"kcalPer100g\": 0"), "rice", "kcalPer100g");
        assertNames(refusalOf(RICE, "\"kcalPer100g\": 365", "\"kcalPer100g\": -4"), "rice", "kcalPer100g");
    }

    @Test
    void refusesGramsPerUnitThatIsMissingOrNotPositive() {
        assertNames(refusalOf(RICE, "\"gramsPerUnit\": 1,", ""), "rice", "gramsPerUnit");
        assertNames(refusalOf(EGG, "\"gramsPerUnit\": 50", "\"gramsPerUnit\": 0"), "egg", "gramsPerUnit");
    }

    @Test
    void anIngredientBoughtByTheGramHasOneGramPerUnit() {
        assertNames(refusalOf(RICE, "\"gramsPerUnit\": 1", "\"gramsPerUnit\": 2"), "rice", "gramsPerUnit", "1");
    }

    @Test
    void aPieceOrMillilitreNeedsAUsdaPortion() {
        String noPortion = EGG.replace(", \"portion\": {\"label\": \"1 large\", \"grams\": 50}", "");
        assertTrue(!noPortion.contains("portion"), "fixture");
        assertNames(refusal(bankWith(catalog(RICE, noPortion), meal(437, 13, OK))), "egg", "portion");
        String noOilPortion = OIL.replaceAll(", \"portion\": \\{.*\\}\\}$", "}");
        assertNames(refusal(bankWith(catalog(RICE, EGG, noOilPortion), meal(437, 13, OK))), "oil", "portion");
    }

    @Test
    void thePortionNeedsALabelAndGrams() {
        assertNames(refusalOfEgg("\"label\": \"1 large\", ", ""), "egg", "portion", "label");
        assertNames(refusalOfEgg("\"grams\": 50}", "\"grams\": 0}"), "egg", "portion", "grams");
    }

    private static String refusalOfEgg(String edit, String to) {
        assertTrue(EGG.contains(edit), "test fixture lacks " + edit);
        return refusal(bankWith(catalog(RICE, EGG.replace(edit, to)), meal(437, 13, OK)));
    }

    @Test
    void aPieceWeighsWhatItsPortionWeighs() {
        assertNames(refusalOfEgg("\"gramsPerUnit\": 50", "\"gramsPerUnit\": 60"), "egg", "gramsPerUnit", "50");
    }

    @Test
    void aMillilitreWeighsItsPortionOverItsMillilitres() {
        String message = refusal(bankWith(catalog(RICE, EGG, OIL.replace("\"gramsPerUnit\": 0.92", "\"gramsPerUnit\": 0.9")),
                meal(437, 13, OK)));
        assertNames(message, "oil", "gramsPerUnit", "0.920");
        String noMl = refusal(bankWith(catalog(RICE, EGG, OIL.replace(", \"ml\": 14.787", "")), meal(437, 13, OK)));
        assertNames(noMl, "oil", "portion", "ml");
    }

    @Test
    void anEdibleFractionIsBetweenZeroAndOneAndSaysWhereItCameFrom() {
        for (String bad : new String[] {"0", "1", "1.2", "-0.5"}) {
            String message = refusal(bankWith(catalog(CHICKEN.replace("0.608", bad)), chickenMeal(0, 0)));
            assertNames(message, "chicken", "edible", "fraction");
        }
        String noNote = CHICKEN.replace(", \"note\": \"USDA 171447 yield: 276 g from 453.6 g\"", "");
        assertNames(refusal(bankWith(catalog(noNote), chickenMeal(262, 40))), "chicken", "edible", "note");
    }

    // ---- a meal's kcal is computed

    /** 200 g bought * 0.608 edible * 215 / 100 = 261.44 kcal; costs 40. */
    private static String chickenMeal(int kcal, int price) {
        return meal(kcal, price, "{\"id\": \"chicken\", \"qty\": 200}");
    }

    @Test
    void theEdibleFractionShrinksTheKcal() {
        assertEquals(261, MealBank.fromJson(bankWith(catalog(CHICKEN), chickenMeal(261, 40))).meals().getFirst().kcal());
        // Without the fraction it would be 430.
        assertNames(refusal(bankWith(catalog(CHICKEN), chickenMeal(430, 40))), "egg-rice", "430", "261");
    }

    @Test
    void aMillilitreCountsItsGramsPerMillilitre() {
        // 10 ml * 0.92 g/ml * 884 / 100 = 81.328 -> 81
        String oil = meal(81, 1, "{\"id\": \"oil\", \"qty\": 10}");
        assertEquals(81, MealBank.fromJson(bankWith(catalog(OIL), oil)).meals().getFirst().kcal());
    }

    @Test
    void theKcalRoundsHalfUp() {
        // 436.5 exactly: 437, never 436 (banker's rounding or float drift).
        refusal(bankWith(CATALOG, meal(436, 13, OK)));
        assertEquals(437, MealBank.fromJson(bankWith(CATALOG, meal(437, 13, OK))).meals().getFirst().kcal());
    }

    @Test
    void refusesAKcalThatIsNotWhatTheIngredientsAddUpToAndNamesBothNumbers() {
        String message = refusal(bankWith(CATALOG, meal(560, 13, OK)));
        assertNames(message, "egg-rice", "kcal", "560", "437");
    }
}
