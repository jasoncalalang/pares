package ph.mealpal.server.plan;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/** An accepted week, Monday first, each day's meals in slot order. */
public record WeekPlan(List<PlannedDay> days) {

    @JsonProperty
    public int pricePhp() {
        return days.stream().mapToInt(PlannedDay::pricePhp).sum();
    }
}
