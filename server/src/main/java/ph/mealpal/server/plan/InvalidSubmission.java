package ph.mealpal.server.plan;

/** submit_plan input that could not be read as a week. */
public class InvalidSubmission extends RuntimeException {

    public InvalidSubmission(String message, Throwable cause) {
        super(message, cause);
    }
}
