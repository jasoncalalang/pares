package ph.mealpal.server.agent;

/** How an agent turn ended. {@code detail} explains a failure. */
public record SessionEnd(Kind kind, String detail) {

    public enum Kind {
        /** The agent finished its turn. */
        END_TURN,
        /** The session's spend cap paused it. */
        BUDGET_REACHED,
        /** The session errored, was refused or terminated. */
        FAILED
    }

    public static SessionEnd endTurn() {
        return new SessionEnd(Kind.END_TURN, null);
    }

    public static SessionEnd budgetReached() {
        return new SessionEnd(Kind.BUDGET_REACHED, null);
    }

    public static SessionEnd failed(String detail) {
        return new SessionEnd(Kind.FAILED, detail);
    }
}
