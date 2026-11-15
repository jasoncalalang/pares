package ph.mealpal.server.plan;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;
import org.eclipse.microprofile.openapi.annotations.media.Schema;

@Schema(requiredProperties = {"weekday", "meals", "kcal", "pricePhp"})
public record PlannedDay(Weekday weekday, List<PlannedMeal> meals) {

    @JsonProperty
    public int kcal() {
        return meals.stream().mapToInt(PlannedMeal::kcal).sum();
    }

    @JsonProperty
    public int pricePhp() {
        return meals.stream().mapToInt(PlannedMeal::pricePhp).sum();
    }
}
