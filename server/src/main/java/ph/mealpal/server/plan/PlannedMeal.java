package ph.mealpal.server.plan;

import ph.mealpal.server.bank.Slot;

/** A meal in an accepted week, with the bank's numbers scaled by its servings. */
public record PlannedMeal(Slot slot, String id, String name, int kcal, int pricePhp, String image, double servings) {}
