package ph.mealpal.server.agent;

import io.smallrye.config.ConfigMapping;
import io.smallrye.config.WithDefault;
import java.util.Optional;

/**
 * Ids of the Managed Agents resources, copied from anthropic/claude-lock.json
 * after `ant apply`. Optional so the server starts (and tests run) without
 * them; opening a session without them fails with a clear message.
 */
@ConfigMapping(prefix = "mealpal.agent")
public interface AgentConfig {

    Optional<String> plannerId();

    Optional<String> environmentId();

    /** Shared store the price-check agent fills; mounted read-only into plans when set. */
    Optional<String> priceBookId();

    /** Hard spend cap per plan session, in US cents at list price. */
    @WithDefault("100")
    int sessionBudgetCents();

    /** Console workspace segment for the session links in the log. */
    @WithDefault("default")
    String workspace();
}
