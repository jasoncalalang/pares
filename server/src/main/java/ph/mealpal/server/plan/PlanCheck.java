package ph.mealpal.server.plan;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import ph.mealpal.server.bank.Ingredient;
import ph.mealpal.server.bank.Meal;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.bank.Slot;

/**
 * Decides whether a submitted week is acceptable. Every number it checks comes
 * from the meal bank times the servings, never from what the agent wrote, so
 * a week that passes cannot carry made-up calories or prices.
 */
public final class PlanCheck {

    /** How far a day may sit from the target, as a fraction of it. */
    static final double KCAL_TOLERANCE = 0.10;

    static final List<Double> SERVINGS = List.of(0.5, 0.75, 1.0, 1.25, 1.5, 2.0);

    private final MealBank bank;

    public PlanCheck(MealBank bank) {
        this.bank = bank;
    }

    /** Lowest daily total that still counts as on target. */
    static int lowestKcal(int target) {
        return (int) Math.ceil(target * (1 - KCAL_TOLERANCE) - 1e-9);
    }

    /** Highest daily total that still counts as on target. */
    static int highestKcal(int target) {
        return (int) Math.floor(target * (1 + KCAL_TOLERANCE) + 1e-9);
    }

    /** What is wrong with the week, one sentence each; empty when it can be accepted. */
    public List<String> problems(PlanRequest request, SubmittedPlan plan) {
        List<String> problems = new ArrayList<>();
        Map<Weekday, Long> counts = plan.days().stream()
                .collect(Collectors.groupingBy(SubmittedDay::weekday, () -> new EnumMap<>(Weekday.class),
                        Collectors.counting()));
        for (Map.Entry<Weekday, Long> e : counts.entrySet()) {
            if (e.getValue() > 1) {
                problems.add(e.getKey().label() + " appears " + e.getValue() + " times; each day goes in once.");
            }
        }
        List<String> missing = Weekday.stream().filter(d -> !counts.containsKey(d)).map(Weekday::label).toList();
        if (!missing.isEmpty()) {
            problems.add("The week needs each day once. Missing: " + String.join(", ", missing) + ".");
        }

        int low = lowestKcal(request.targetKcal());
        int high = highestKcal(request.targetKcal());
        int weekPrice = 0;
        for (SubmittedDay day : plan.days()) {
            String label = day.weekday().label();
            boolean known = true;
            int kcal = 0;
            for (SubmittedMeal sm : day.meals()) {
                Optional<Meal> found = bank.find(sm.mealId());
                if (found.isEmpty()) {
                    problems.add(label + ": '" + sm.mealId() + "' is not in the meal bank. Use only ids from the bank.");
                    known = false;
                    continue;
                }
                Meal meal = found.get();
                if (!meal.slots().contains(sm.slot())) {
                    problems.add(label + ": '" + meal.id() + "' is a " + meal.slotsInWords() + ", not a "
                            + sm.slot().json() + ".");
                }
                if (!SERVINGS.contains(sm.servings())) {
                    problems.add(label + ": '" + meal.id() + "' has " + Format.servings(sm.servings())
                            + " servings; use 0.5, 0.75, 1, 1.25, 1.5 or 2.");
                    known = false;
                    continue;
                }
                kcal += scaled(meal.kcal(), sm.servings());
                weekPrice += scaled(meal.pricePhp(), sm.servings());
            }
            Set<Slot> slots = day.meals().stream().map(SubmittedMeal::slot).collect(Collectors.toSet());
            if (day.meals().size() != Slot.values().length || slots.size() != Slot.values().length) {
                problems.add(label + " needs exactly one breakfast, lunch, dinner and snack.");
            }
            if (known && (kcal < low || kcal > high)) {
                problems.add(label + " comes to " + Format.thousands(kcal) + " kcal; it must be between "
                        + Format.thousands(low) + " and " + Format.thousands(high) + " (target "
                        + Format.thousands(request.targetKcal()) + ").");
            }
        }
        if (weekPrice > request.budgetPhp()) {
            problems.add("The week costs " + Format.peso(weekPrice) + "; the budget is "
                    + Format.peso(request.budgetPhp()) + ".");
        }
        return problems;
    }

    /** The accepted week with the bank's numbers. Call only when {@link #problems} is empty. */
    public WeekPlan toWeek(SubmittedPlan plan) {
        List<PlannedDay> days = plan.days().stream()
                .sorted(Comparator.comparing(SubmittedDay::weekday))
                .map(day -> new PlannedDay(day.weekday(), day.meals().stream()
                        .sorted(Comparator.comparing(SubmittedMeal::slot))
                        .map(this::planned)
                        .toList()))
                .toList();
        return new WeekPlan(days);
    }

    private PlannedMeal planned(SubmittedMeal sm) {
        Meal meal = bank.find(sm.mealId()).orElseThrow();
        return new PlannedMeal(sm.slot(), meal.id(), meal.name(), scaled(meal.kcal(), sm.servings()),
                scaled(meal.pricePhp(), sm.servings()), meal.image(), sm.servings(),
                ingredientsFor(meal, sm.servings()));
    }

    private List<PlannedIngredient> ingredientsFor(Meal meal, double servings) {
        return meal.ingredients().stream().map(ref -> {
            Ingredient ingredient = bank.ingredient(ref.id()).orElseThrow();
            BigDecimal qty = BigDecimal.valueOf(ref.qty()).multiply(BigDecimal.valueOf(servings));
            BigDecimal price = qty.multiply(BigDecimal.valueOf(ingredient.pricePhpPerUnit()));
            return new PlannedIngredient(ingredient.id(), ingredient.name(), ingredient.kind(), ingredient.unit(),
                    twoDecimals(qty), twoDecimals(price));
        }).toList();
    }

    private static double twoDecimals(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP).doubleValue();
    }

    private static int scaled(int perServing, double servings) {
        return (int) Math.round(perServing * servings);
    }
}
