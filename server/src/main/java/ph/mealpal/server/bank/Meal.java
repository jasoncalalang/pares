package ph.mealpal.server.bank;

/**
 * One dish in the meal bank. kcal and pricePhp are per serving; they are the
 * only nutrition and price numbers a plan is ever built from.
 */
public record Meal(String id, Slot slot, String name, int kcal, int pricePhp, String image) {}
