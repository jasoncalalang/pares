package ph.mealpal.server.agent;

import java.util.Map;
import java.util.Optional;

/**
 * The planner agent as the server sees it. The server holds no plan state:
 * a plan is its session, and its event history is the record.
 */
public interface AgentGateway {

    /** Starts a session tagged with {@code metadata} that begins working on {@code kickoff}; returns its id. */
    String startSession(String title, Map<String, String> metadata, String kickoff);

    /** The session's metadata and full event history; empty when there is no such session. */
    Optional<SessionView> view(String sessionId);

    void sendToolResult(String sessionId, String toolUseId, ToolReply reply);

    /** Starts a new turn in the session. */
    void sendMessage(String sessionId, String text);
}
