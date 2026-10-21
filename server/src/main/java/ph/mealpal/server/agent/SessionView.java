package ph.mealpal.server.agent;

import java.util.List;
import java.util.Map;

/** A session as read back: the metadata it was started with and its events, oldest first. */
public record SessionView(String id, Map<String, String> metadata, List<SessionEvent> events) {}
