package ph.mealpal.server.plan;

/** The planner could not be reached to start a plan. */
public class PlannerUnavailable extends RuntimeException {

    public PlannerUnavailable(String message, Throwable cause) {
        super(message, cause);
    }
}
