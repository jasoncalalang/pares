package ph.mealpal.server.bank;

import com.fasterxml.jackson.annotation.JsonValue;
import java.math.BigDecimal;
import java.util.Locale;

/**
 * One entry of the bank's ingredient catalog. The unit price is per unit: per g, per ml or per pc.
 *
 * <p>The calories behind a meal's kcal come from USDA FoodData Central: {@code kcalPer100g} is the
 * energy USDA publishes for {@code usda.fdcId}, and {@code gramsPerUnit} turns one catalog unit into
 * grams (1 for g; a USDA piece weight for pc; grams per ml for ml, from {@code portion}).
 * {@code edible} is present only when part of the bought amount is not eaten.
 */
public record Ingredient(String id, String name, Kind kind, Unit unit, double pricePhpPerUnit,
        BigDecimal kcalPer100g, BigDecimal gramsPerUnit, Usda usda, Portion portion, Edible edible) {

    /** The USDA food an ingredient is measured from. {@code match} is "exact" or "closest" (then {@code note} says what differs). */
    public record Usda(int fdcId, String description, String match, String note) {}

    /** A USDA household portion: grams for one piece, or grams and millilitres for a spoon or cup. */
    public record Portion(String label, BigDecimal grams, BigDecimal ml) {}

    /** The fraction of the bought amount that is eaten, and where the figure comes from. */
    public record Edible(BigDecimal fraction, String note) {}

    /** What sort of food it is; the app decides where to buy it from this. */
    public enum Kind {
        MEAT, POULTRY, FISH, PRODUCE, FRUIT, AROMATICS, GRAIN, EGG, LEGUME, OIL, CONDIMENT, SPICE, PANTRY;

        @JsonValue
        public String json() {
            return name().toLowerCase(Locale.ROOT);
        }

        static Kind parse(String value) {
            for (Kind k : values()) {
                if (k.json().equals(value)) {
                    return k;
                }
            }
            return null;
        }
    }

    public enum Unit {
        G, ML, PC;

        @JsonValue
        public String json() {
            return name().toLowerCase(Locale.ROOT);
        }

        static Unit parse(String value) {
            for (Unit u : values()) {
                if (u.json().equals(value)) {
                    return u;
                }
            }
            return null;
        }
    }
}
