package ph.mealpal.server.agent;

/** What the server answers a custom tool call with. */
public record ToolReply(String text, boolean error) {

    public static ToolReply ok(String text) {
        return new ToolReply(text, false);
    }

    public static ToolReply error(String text) {
        return new ToolReply(text, true);
    }
}
