package ph.mealpal.server.bank;

import java.util.List;

/**
 * One dish in the meal bank. kcal and pricePhp are per serving; they are the
 * only nutrition and price numbers a plan is ever built from. {@code slots}
 * lists every slot the dish fits: ulam with rice is lunch or dinner.
 * {@code pricePhp} is the rounded cost of the {@code ingredients} per serving;
 * the bank refuses to load when the two disagree.
 */
public record Meal(String id, List<Slot> slots, String name, int kcal, int pricePhp, String image,
        List<MealIngredient> ingredients) {

    /** "lunch or dinner", for messages. */
    public String slotsInWords() {
        return String.join(" or ", slots.stream().map(Slot::json).toList());
    }
}
