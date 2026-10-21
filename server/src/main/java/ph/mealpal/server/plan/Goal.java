package ph.mealpal.server.plan;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

/** What the person chose on Daily target. */
public enum Goal {
    LOSE,
    MAINTAIN,
    GAIN;

    @JsonValue
    public String json() {
        return name().toLowerCase();
    }

    @JsonCreator
    public static Goal fromJson(String value) {
        for (Goal g : values()) {
            if (g.json().equals(value)) {
                return g;
            }
        }
        throw new IllegalArgumentException("'" + value + "' is not a goal (lose, maintain, gain)");
    }
}
