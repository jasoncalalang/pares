package ph.mealpal.server.bank;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/** The four meal slots a day is planned around, in the order a day is eaten. */
public enum Slot {
    BREAKFAST,
    LUNCH,
    DINNER,
    SNACK;

    /** The lowercase name the app, the bank and the agent all use. */
    @JsonValue
    public String json() {
        return name().toLowerCase();
    }

    @JsonCreator
    public static Slot fromJson(String value) {
        for (Slot s : values()) {
            if (s.json().equals(value)) {
                return s;
            }
        }
        throw new IllegalArgumentException("'" + value + "' is not a meal slot (breakfast, lunch, dinner, snack)");
    }
}
