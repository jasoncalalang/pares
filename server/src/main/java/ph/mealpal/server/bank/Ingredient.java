package ph.mealpal.server.bank;

import java.util.Locale;

/** One entry of the bank's ingredient catalog. The unit price is per unit: per g, per ml or per pc. */
public record Ingredient(String id, String name, Kind kind, Unit unit, double pricePhpPerUnit) {

    /** What sort of food it is; the app decides where to buy it from this. */
    public enum Kind {
        MEAT, POULTRY, FISH, PRODUCE, FRUIT, AROMATICS, GRAIN, EGG, LEGUME, OIL, CONDIMENT, SPICE, PANTRY;

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
