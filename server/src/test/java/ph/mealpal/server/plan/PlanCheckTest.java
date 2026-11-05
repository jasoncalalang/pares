package ph.mealpal.server.plan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.bank.Slot;

class PlanCheckTest {

    private final PlanCheck check = new PlanCheck(MealBank.fromClasspath("meal-bank.json"));

    /** 2,565 kcal (797 + 674 + 774 + 320, from USDA) and ₱195 a day. */
    private static final List<SubmittedMeal> MONDAY = List.of(
            new SubmittedMeal(Slot.BREAKFAST, "tapsilog", 1.0),
            new SubmittedMeal(Slot.LUNCH, "tinola", 1.0),
            new SubmittedMeal(Slot.DINNER, "munggo", 1.0),
            new SubmittedMeal(Slot.SNACK, "saba-peanuts", 1.0));

    private static SubmittedPlan everyDay(List<SubmittedMeal> meals) {
        List<SubmittedDay> days = new ArrayList<>();
        for (Weekday d : Weekday.values()) {
            days.add(new SubmittedDay(d, meals));
        }
        return new SubmittedPlan(days);
    }

    private static PlanRequest request(int targetKcal, int budgetPhp) {
        return new PlanRequest(targetKcal, budgetPhp, Goal.MAINTAIN, List.of("palengke"));
    }

    @Test
    void aWeekOnTargetAndUnderBudgetPasses() {
        assertEquals(List.of(), check.problems(request(2565, 2000), everyDay(MONDAY)));
    }

    @Test
    void everyDayOfTheWeekIsNeeded() {
        List<SubmittedDay> days = new ArrayList<>(everyDay(MONDAY).days());
        days.removeLast();
        List<String> problems = check.problems(request(2565, 2000), new SubmittedPlan(days));
        assertEquals(List.of("The week needs each day once. Missing: Sunday."), problems);
    }

    @Test
    void aDayTwiceIsRejected() {
        List<SubmittedDay> days = new ArrayList<>(everyDay(MONDAY).days());
        days.set(6, new SubmittedDay(Weekday.MON, MONDAY));
        List<String> problems = check.problems(request(2565, 2000), new SubmittedPlan(days));
        assertTrue(problems.contains("Monday appears 2 times; each day goes in once."), problems.toString());
        assertTrue(problems.contains("The week needs each day once. Missing: Sunday."), problems.toString());
    }

    @Test
    void aMealIdOutsideTheBankIsRejected() {
        List<SubmittedMeal> meals = new ArrayList<>(MONDAY);
        meals.set(1, new SubmittedMeal(Slot.LUNCH, "lechon", 1.0));
        List<String> problems = check.problems(request(2565, 2000), everyDay(meals));
        assertTrue(problems.contains(
                "Monday: 'lechon' is not in the meal bank. Use only ids from the bank."), problems.toString());
    }

    @Test
    void aMealInTheWrongSlotIsRejected() {
        List<SubmittedMeal> meals = new ArrayList<>(MONDAY);
        meals.set(0, new SubmittedMeal(Slot.BREAKFAST, "adobo", 1.0));
        List<String> problems = check.problems(request(2565, 2000), everyDay(meals));
        assertTrue(problems.contains("Monday: 'adobo' is a lunch or dinner, not a breakfast."), problems.toString());
    }

    @Test
    void ulamFromTheDinnerListCanBeLunch() {
        List<SubmittedMeal> meals = new ArrayList<>(MONDAY);
        meals.set(1, new SubmittedMeal(Slot.LUNCH, "pinakbet", 1.25));
        assertEquals(List.of(), check.problems(request(2684, 2000), everyDay(meals)));
        assertEquals(Slot.LUNCH, check.toWeek(everyDay(meals)).days().getFirst().meals().get(1).slot());
    }

    @Test
    void aDayNeedsOneMealPerSlot() {
        List<SubmittedMeal> meals = List.of(
                new SubmittedMeal(Slot.BREAKFAST, "tapsilog", 1.0),
                new SubmittedMeal(Slot.LUNCH, "tinola", 1.0),
                new SubmittedMeal(Slot.DINNER, "munggo", 1.0));
        List<String> problems = check.problems(request(1740, 2000), everyDay(meals));
        assertTrue(problems.contains(
                "Monday needs exactly one breakfast, lunch, dinner and snack."), problems.toString());
    }

    @Test
    void aDayFarFromTheTargetIsRejectedWithTheAllowedRange() {
        List<String> problems = check.problems(request(2000, 2000), everyDay(MONDAY));
        assertTrue(problems.contains(
                "Monday comes to 2,565 kcal; it must be between 1,800 and 2,200 (target 2,000)."),
                problems.toString());
    }

    @Test
    void largerServingsReachAHigherTarget() {
        List<SubmittedMeal> bigger = MONDAY.stream()
                .map(m -> new SubmittedMeal(m.slot(), m.mealId(), 1.25))
                .toList();
        // 797 * 1.25 = 996.25 -> 996, 674 * 1.25 = 842.5 -> 843, 774 * 1.25 = 967.5 -> 968, 320 * 1.25 = 400.
        assertEquals(List.of(), check.problems(request(3207, 3000), everyDay(bigger)));
        assertEquals(7, check.problems(request(2565, 3000), everyDay(bigger)).size());
    }

    @Test
    void servingsComeFromAFixedList() {
        List<SubmittedMeal> meals = new ArrayList<>(MONDAY);
        meals.set(3, new SubmittedMeal(Slot.SNACK, "saba-peanuts", 3.0));
        List<String> problems = check.problems(request(2565, 3000), everyDay(meals));
        assertTrue(problems.contains(
                "Monday: 'saba-peanuts' has 3 servings; use 0.5, 0.75, 1, 1.25, 1.5 or 2."),
                problems.toString());
    }

    @Test
    void aWeekOverBudgetIsRejected() {
        List<String> problems = check.problems(request(2565, 1300), everyDay(MONDAY));
        assertEquals(List.of("The week costs ₱1,371; the budget is ₱1,300."), problems);
    }

    @Test
    void theAcceptedWeekCarriesTheBanksNumbersTimesServings() {
        List<SubmittedMeal> meals = new ArrayList<>(MONDAY);
        meals.set(0, new SubmittedMeal(Slot.BREAKFAST, "tapsilog", 1.5));
        WeekPlan week = check.toWeek(everyDay(meals));

        assertEquals(7, week.days().size());
        PlannedDay monday = week.days().getFirst();
        assertEquals(Weekday.MON, monday.weekday());
        PlannedMeal breakfast = monday.meals().getFirst();
        assertEquals(Slot.BREAKFAST, breakfast.slot());
        assertEquals("Tapsilog: beef tapa, garlic rice and egg", breakfast.name());
        assertEquals(1196, breakfast.kcal());
        assertEquals(127, breakfast.pricePhp());
        assertEquals(1.5, breakfast.servings());
        assertEquals(2964, monday.kcal());
        assertEquals(238, monday.pricePhp());
        assertEquals(7 * 238, week.pricePhp());
    }

    @Test
    void theWeekIsReturnedInDayAndSlotOrderWhateverOrderItWasSentIn() {
        List<SubmittedDay> days = new ArrayList<>(everyDay(MONDAY.reversed()).days().reversed());
        WeekPlan week = check.toWeek(new SubmittedPlan(days));
        assertEquals(Weekday.MON, week.days().getFirst().weekday());
        assertEquals(Slot.BREAKFAST, week.days().getFirst().meals().getFirst().slot());
        assertEquals(Slot.SNACK, week.days().getFirst().meals().getLast().slot());
    }

    private PlannedMeal planned(String mealId, Slot slot, double servings) {
        return check.toWeek(everyDay(List.of(new SubmittedMeal(slot, mealId, servings))))
                .days().getFirst().meals().getFirst();
    }

    private static PlannedIngredient line(PlannedMeal meal, String id) {
        return meal.ingredients().stream().filter(i -> i.id().equals(id)).findFirst().orElseThrow();
    }

    @Test
    void aPlannedMealCarriesItsIngredientsScaledByServings() {
        PlannedMeal tapsilog = planned("tapsilog", Slot.BREAKFAST, 1.5);
        assertEquals(7, tapsilog.ingredients().size());
        PlannedIngredient tapa = tapsilog.ingredients().getFirst();
        assertEquals("beef-tapa", tapa.id());
        assertEquals("Beef tapa cut", tapa.name());
        assertEquals("meat", tapa.kind().json());
        assertEquals("g", tapa.unit().json());
        assertEquals(225.0, tapa.qty());
        assertEquals(101.25, tapa.pricePhp());
        assertEquals(1.5, line(tapsilog, "egg").qty());
        assertEquals(12.0, line(tapsilog, "egg").pricePhp());
    }

    @Test
    void ingredientNumbersRoundToTwoDecimalsHalfUp() {
        PlannedMeal tapsilog = planned("tapsilog", Slot.BREAKFAST, 1.5);
        // 22.5 ml of oil at 0.11 a ml is 2.475.
        assertEquals(22.5, line(tapsilog, "cooking-oil").qty());
        assertEquals(2.48, line(tapsilog, "cooking-oil").pricePhp());
        // 0.75 of 90 g rice is 67.5 g, costing 3.375.
        PlannedMeal tinola = planned("tinola", Slot.LUNCH, 0.75);
        assertEquals(67.5, line(tinola, "rice").qty());
        assertEquals(3.38, line(tinola, "rice").pricePhp());
        // 0.75 of 15 g malunggay is 11.25 g at 0.1 a g: 1.125.
        assertEquals(11.25, line(tinola, "malunggay").qty());
        assertEquals(1.13, line(tinola, "malunggay").pricePhp());
    }

    @Test
    void aMealsPriceIsItsScaledIngredientsRoundedOnce() {
        // 84.40 a serving, so 126.60 for one and a half: 127, not round(84 * 1.5).
        assertEquals(127, planned("tapsilog", Slot.BREAKFAST, 1.5).pricePhp());
        // kcal keeps the servings arithmetic: 797 * 1.5 = 1,195.5 rounds half up.
        assertEquals(1196, planned("tapsilog", Slot.BREAKFAST, 1.5).kcal());
    }

    @Test
    void theBudgetIsCheckedAgainstTheFigureTheGroceryListShows() {
        List<SubmittedMeal> meals = List.of(
                new SubmittedMeal(Slot.BREAKFAST, "tapsilog", 0.75),
                new SubmittedMeal(Slot.LUNCH, "tinola", 1.0),
                new SubmittedMeal(Slot.DINNER, "adobo", 1.25),
                new SubmittedMeal(Slot.SNACK, "boiled-saba", 0.75));
        // Summing rounded meal prices gives 1,400 and would accept this week;
        // the list sums the exact ingredient costs per ingredient: 1,412.
        List<String> problems = check.problems(request(2365, 1400), everyDay(meals));
        assertEquals(List.of("The week costs ₱1,412; the budget is ₱1,400."), problems);
        assertEquals(List.of(), check.problems(request(2365, 1500), everyDay(meals)));
    }
}
