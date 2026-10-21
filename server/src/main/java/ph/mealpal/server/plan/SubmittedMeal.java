package ph.mealpal.server.plan;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import ph.mealpal.server.bank.Slot;

/** One meal as the agent submitted it: a bank id and a portion, nothing else. */
public record SubmittedMeal(Slot slot, String mealId, double servings) {

    @JsonCreator
    static SubmittedMeal fromJson(
            @JsonProperty(value = "slot", required = true) Slot slot,
            @JsonProperty(value = "meal_id", required = true) String mealId,
            @JsonProperty("servings") Double servings) {
        return new SubmittedMeal(slot, mealId, servings == null ? 1.0 : servings);
    }
}
