package ph.mealpal.server.plan;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

/** The week as the agent sent it through submit_plan, before any checking. */
public record SubmittedPlan(@JsonProperty(required = true) List<SubmittedDay> days) {}
