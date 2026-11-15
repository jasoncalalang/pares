package ph.mealpal.server.plan;

import java.util.List;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import ph.mealpal.server.bank.Slot;

/**
 * A meal in an accepted week, with the bank's numbers scaled by its servings.
 * {@code ingredients} are scaled the same way, so the app can add them up.
 */
@Schema(requiredProperties = {"slot", "id", "name", "kcal", "pricePhp", "image", "servings", "ingredients"})
public record PlannedMeal(Slot slot, String id, String name, int kcal, int pricePhp, String image, double servings,
        List<PlannedIngredient> ingredients) {}
