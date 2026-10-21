package ph.mealpal.server.plan;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record SubmittedDay(
        @JsonProperty(required = true) Weekday weekday,
        @JsonProperty(required = true) List<SubmittedMeal> meals) {}
