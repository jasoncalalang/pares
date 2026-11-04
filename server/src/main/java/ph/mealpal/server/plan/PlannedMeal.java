package ph.mealpal.server.plan;

import java.util.List;
import ph.mealpal.server.bank.Slot;

/**
 * A meal in an accepted week, with the bank's numbers scaled by its servings.
 * {@code ingredients} are scaled the same way, so the app can add them up.
 */
public record PlannedMeal(Slot slot, String id, String name, int kcal, int pricePhp, String image, double servings,
        List<PlannedIngredient> ingredients) {}
