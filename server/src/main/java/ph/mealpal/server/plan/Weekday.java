package ph.mealpal.server.plan;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import java.util.Arrays;
import java.util.stream.Stream;

/** Days of the planned week, Monday first, with the app's short ids. */
public enum Weekday {
    MON("Monday"),
    TUE("Tuesday"),
    WED("Wednesday"),
    THU("Thursday"),
    FRI("Friday"),
    SAT("Saturday"),
    SUN("Sunday");

    private final String label;

    Weekday(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }

    @JsonValue
    public String json() {
        return name().toLowerCase();
    }

    @JsonCreator
    public static Weekday fromJson(String value) {
        for (Weekday d : values()) {
            if (d.json().equals(value)) {
                return d;
            }
        }
        throw new IllegalArgumentException("'" + value + "' is not a weekday (mon to sun)");
    }

    public static Stream<Weekday> stream() {
        return Arrays.stream(values());
    }
}
