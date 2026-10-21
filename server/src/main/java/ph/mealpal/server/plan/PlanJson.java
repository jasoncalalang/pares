package ph.mealpal.server.plan;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;

/** Reads the agent's submit_plan input. */
public final class PlanJson {

    private static final ObjectMapper JSON = new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

    private PlanJson() {}

    public static SubmittedPlan readSubmission(String json) {
        SubmittedPlan plan;
        try {
            plan = JSON.readValue(json, SubmittedPlan.class);
        } catch (JsonProcessingException e) {
            throw new InvalidSubmission(e.getOriginalMessage(), e);
        }
        if (plan == null || plan.days() == null
                || plan.days().stream().anyMatch(d -> d == null || d.weekday() == null || d.meals() == null)) {
            throw new InvalidSubmission("every day needs a weekday and a meals list", null);
        }
        return plan;
    }
}
