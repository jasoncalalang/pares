package ph.mealpal.server.agent;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import ph.mealpal.server.agent.SessionEvent.Idle;
import ph.mealpal.server.agent.SessionEvent.Stop;
import ph.mealpal.server.agent.SessionEvent.ToolCall;
import ph.mealpal.server.agent.SessionEvent.ToolResult;
import ph.mealpal.server.agent.SessionEvent.UserMessage;

/**
 * A scripted stand-in for Managed Agents that behaves like the real thing
 * between polls: each turn makes its tool calls one at a time, waiting idle
 * (requires_action) until the server answers, then ends the way the script says.
 */
public class FakeAgent implements AgentGateway {

    /** One scripted turn: the tool calls the agent makes, then how it stops. */
    public record Turn(List<String[]> calls, Stop end) {
        public static Turn submitting(Stop end, String... weeks) {
            List<String[]> calls = new ArrayList<>();
            for (String w : weeks) {
                calls.add(new String[] {"submit_plan", w});
            }
            return new Turn(calls, end);
        }
    }

    private final class Session {
        final Map<String, String> metadata;
        final List<SessionEvent> events = new ArrayList<>();
        Turn turn;
        int next;

        Session(Map<String, String> metadata) {
            this.metadata = metadata;
        }
    }

    private final Map<String, Session> sessions = new HashMap<>();
    private final Deque<Turn> script = new ArrayDeque<>();
    public final List<String> messages = new ArrayList<>();
    public final List<ToolReply> replies = new ArrayList<>();
    public RuntimeException startFailure;
    private int ids;

    public synchronized FakeAgent script(Turn... turns) {
        script.addAll(List.of(turns));
        return this;
    }

    public synchronized void reset() {
        sessions.clear();
        script.clear();
        messages.clear();
        replies.clear();
        startFailure = null;
    }

    /** A session that is not MealPal's, as another agent in the workspace would leave. */
    public synchronized String foreignSession() {
        String id = "sesn_other_" + (++ids);
        sessions.put(id, new Session(Map.of("app", "ridgewell")));
        return id;
    }

    public synchronized int sessionCount() {
        return sessions.size();
    }

    @Override
    public synchronized String startSession(String title, Map<String, String> metadata, String kickoff) {
        if (startFailure != null) {
            throw startFailure;
        }
        String id = "sesn_" + (++ids);
        sessions.put(id, new Session(new LinkedHashMap<>(metadata)));
        say(sessions.get(id), kickoff);
        return id;
    }

    @Override
    public synchronized Optional<SessionView> view(String sessionId) {
        Session s = sessions.get(sessionId);
        return s == null
                ? Optional.empty()
                : Optional.of(new SessionView(sessionId, Map.copyOf(s.metadata), List.copyOf(s.events)));
    }

    @Override
    public synchronized void sendToolResult(String sessionId, String toolUseId, ToolReply reply) {
        Session s = sessions.get(sessionId);
        replies.add(reply);
        s.events.add(new ToolResult(toolUseId, reply.text(), reply.error()));
        step(s);
    }

    @Override
    public synchronized void sendMessage(String sessionId, String text) {
        say(sessions.get(sessionId), text);
    }

    private void say(Session s, String text) {
        messages.add(text);
        s.events.add(new UserMessage(text));
        s.turn = script.isEmpty() ? Turn.submitting(Stop.END_TURN) : script.removeFirst();
        s.next = 0;
        step(s);
    }

    private void step(Session s) {
        if (s.next < s.turn.calls().size()) {
            String[] call = s.turn.calls().get(s.next++);
            s.events.add(new ToolCall("tool_" + (++ids), call[0], call[1]));
            s.events.add(new Idle(Stop.REQUIRES_ACTION));
        } else {
            s.events.add(new Idle(s.turn.end()));
        }
    }
}
