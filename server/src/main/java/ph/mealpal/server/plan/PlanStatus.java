package ph.mealpal.server.plan;

import com.fasterxml.jackson.annotation.JsonValue;

/** Matches the app's PlanStatus on This week. */
public enum PlanStatus {
    BUILDING,
    READY,
    FAILED;

    @JsonValue
    public String json() {
        return name().toLowerCase();
    }
}
