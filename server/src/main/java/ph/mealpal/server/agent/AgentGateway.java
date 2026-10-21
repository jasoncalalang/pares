package ph.mealpal.server.agent;

/**
 * The planner agent as the rest of the server sees it: a session per plan,
 * and turns within it. The real one talks to Claude Managed Agents.
 */
public interface AgentGateway {

    /** Opens an idle session for the planner and returns its id. */
    String openSession(String title);

    /**
     * Sends {@code message} into the session and blocks until the agent's turn
     * ends, answering each custom tool call with {@code tools} on the way.
     */
    SessionEnd converse(String sessionId, String message, ToolHandler tools);
}
