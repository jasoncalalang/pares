package ph.mealpal.server.agent;

/** Answers the agent's custom tool calls during a turn. */
@FunctionalInterface
public interface ToolHandler {

    /** {@code inputJson} is the call's input as the agent wrote it. */
    ToolReply handle(String toolName, String inputJson);
}
