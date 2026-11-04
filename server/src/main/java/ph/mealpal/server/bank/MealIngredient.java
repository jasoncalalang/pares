package ph.mealpal.server.bank;

/** An ingredient a meal uses: {@code qty} per serving, in the ingredient's own unit. */
public record MealIngredient(String id, double qty) {}
