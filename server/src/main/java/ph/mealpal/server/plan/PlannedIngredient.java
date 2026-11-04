package ph.mealpal.server.plan;

import ph.mealpal.server.bank.Ingredient;

/**
 * One ingredient line of a planned meal, already multiplied by the meal's
 * servings. {@code qty} is in {@code unit}; both numbers carry two decimals.
 */
public record PlannedIngredient(String id, String name, Ingredient.Kind kind, Ingredient.Unit unit, double qty,
        double pricePhp) {}
