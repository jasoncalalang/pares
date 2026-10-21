package ph.mealpal.server.agent;

/** The parts of a session's event history the server reads a plan from. */
public sealed interface SessionEvent {

    /** A message the server sent: the kickoff or a swap. Starts a turn. */
    record UserMessage(String text) implements SessionEvent {}

    /** The agent called one of the server's tools. */
    record ToolCall(String id, String name, String inputJson) implements SessionEvent {}

    /** The server's answer to a tool call. */
    record ToolResult(String toolUseId, String text, boolean error) implements SessionEvent {}

    /** The session stopped working, and why. */
    record Idle(Stop stop) implements SessionEvent {}

    enum Stop {
        /** Waiting for the server to answer a tool call. */
        REQUIRES_ACTION,
        END_TURN,
        BUDGET_REACHED,
        RETRIES_EXHAUSTED,
        REFUSAL,
        TERMINATED,
        OTHER
    }
}
