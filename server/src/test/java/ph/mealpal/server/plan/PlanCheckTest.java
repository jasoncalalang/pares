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

    /** 2,087 kcal and ₱250 a day: the app's Monday. */
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
        assertEquals(List.of(), check.problems(request(2087, 2000), everyDay(MONDAY)));
    }

    @Test
    void everyDayOfTheWeekIsNeeded() {
        List<SubmittedDay> days = new ArrayList<>(everyDay(MONDAY).days());
        days.removeLast();
        List<String> problems = check.problems(request(2087, 2000), new SubmittedPlan(days));
        assertEquals(List.of("The week needs each day once. Missing: Sunday."), problems);
    }

    @Test
    void aDayTwiceIsRejected() {
        List<SubmittedDay> days = new ArrayList<>(everyDay(MONDAY).days());
        days.set(6, new SubmittedDay(Weekday.MON, MONDAY));
        List<String> problems = check.problems(request(2087, 2000), new SubmittedPlan(days));
        assertTrue(problems.contains("Monday appears 2 times; each day goes in once."), problems.toString());
        assertTrue(problems.contains("The week needs each day once. Missing: Sunday."), problems.toString());
    }

    @Test
    void aMealIdOutsideTheBankIsRejected() {
        List<SubmittedMeal> meals = new ArrayList<>(MONDAY);
        meals.set(1, new SubmittedMeal(Slot.LUNCH, "lechon", 1.0));
        List<String> problems = check.problems(request(2087, 2000), everyDay(meals));
        assertTrue(problems.contains(
                "Monday: 'lechon' is not in the meal bank. Use only ids from the bank."), problems.toString());
    }

    @Test
    void aMealInTheWrongSlotIsRejected() {
        List<SubmittedMeal> meals = new ArrayList<>(MONDAY);
        meals.set(0, new SubmittedMeal(Slot.BREAKFAST, "adobo", 1.0));
        List<String> problems = check.problems(request(2087, 2000), everyDay(meals));
        assertTrue(problems.contains("Monday: 'adobo' is a lunch, not a breakfast."), problems.toString());
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
        List<String> problems = check.problems(request(2500, 2000), everyDay(MONDAY));
        assertTrue(problems.contains(
                "Monday comes to 2,087 kcal; it must be between 2,250 and 2,750 (target 2,500)."),
                problems.toString());
    }

    @Test
    void largerServingsReachAHigherTarget() {
        List<SubmittedMeal> bigger = MONDAY.stream()
                .map(m -> new SubmittedMeal(m.slot(), m.mealId(), 1.25))
                .toList();
        assertEquals(List.of(), check.problems(request(2500, 3000), everyDay(bigger)));
    }

    @Test
    void servingsComeFromAFixedList() {
        List<SubmittedMeal> meals = new ArrayList<>(MONDAY);
        meals.set(3, new SubmittedMeal(Slot.SNACK, "saba-peanuts", 3.0));
        List<String> problems = check.problems(request(2087, 3000), everyDay(meals));
        assertTrue(problems.contains(
                "Monday: 'saba-peanuts' has 3 servings; use 0.5, 0.75, 1, 1.25, 1.5 or 2."),
                problems.toString());
    }

    @Test
    void aWeekOverBudgetIsRejected() {
        List<String> problems = check.problems(request(2087, 1500), everyDay(MONDAY));
        assertEquals(List.of("The week costs ₱1,750; the budget is ₱1,500."), problems);
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
        assertEquals(840, breakfast.kcal());
        assertEquals(143, breakfast.pricePhp());
        assertEquals(1.5, breakfast.servings());
        assertEquals(2367, monday.kcal());
        assertEquals(298, monday.pricePhp());
        assertEquals(7 * 298, week.pricePhp());
    }

    @Test
    void theWeekIsReturnedInDayAndSlotOrderWhateverOrderItWasSentIn() {
        List<SubmittedDay> days = new ArrayList<>(everyDay(MONDAY.reversed()).days().reversed());
        WeekPlan week = check.toWeek(new SubmittedPlan(days));
        assertEquals(Weekday.MON, week.days().getFirst().weekday());
        assertEquals(Slot.BREAKFAST, week.days().getFirst().meals().getFirst().slot());
        assertEquals(Slot.SNACK, week.days().getFirst().meals().getLast().slot());
    }
}
