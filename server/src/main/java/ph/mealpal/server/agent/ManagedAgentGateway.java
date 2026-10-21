package ph.mealpal.server.agent;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.core.ObjectMappers;
import com.anthropic.models.beta.BetaCurrency;
import com.anthropic.models.beta.BetaMonetaryAmount;
import com.anthropic.models.beta.sessions.BetaManagedAgentsBudgetLimit;
import com.anthropic.models.beta.sessions.BetaManagedAgentsMemoryStoreResourceParam;
import com.anthropic.models.beta.sessions.SessionCreateParams;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsAgentCustomToolUseEvent;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsSessionStatusIdleEvent;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsStreamSessionEvents;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsUserCustomToolResultEventParams;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsUserMessageEventParams;
import com.anthropic.models.beta.sessions.events.EventSendParams;
import com.fasterxml.jackson.core.JsonProcessingException;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.jboss.logging.Logger;

/**
 * The planner on Claude Managed Agents. The client resolves credentials the
 * way the `ant` CLI does: ANTHROPIC_API_KEY if set, else the profile from
 * `ant auth login`.
 */
@ApplicationScoped
public class ManagedAgentGateway implements AgentGateway {

    private static final Logger LOG = Logger.getLogger(ManagedAgentGateway.class);

    @Inject
    AgentConfig config;

    private volatile AnthropicClient client;

    private AnthropicClient client() {
        if (client == null) {
            synchronized (this) {
                if (client == null) {
                    client = AnthropicOkHttpClient.fromEnv();
                }
            }
        }
        return client;
    }

    @PreDestroy
    void close() {
        if (client != null) {
            client.close();
        }
    }

    @Override
    public String openSession(String title) {
        String agentId = config.plannerId().orElseThrow(() -> new IllegalStateException(
                "mealpal.agent.planner-id is not set; run ant apply and copy the id from claude-lock.json"));
        String environmentId = config.environmentId().orElseThrow(() -> new IllegalStateException(
                "mealpal.agent.environment-id is not set; run ant apply and copy the id from claude-lock.json"));

        SessionCreateParams.Builder params = SessionCreateParams.builder()
                .agent(agentId)
                .environmentId(environmentId)
                .title(title)
                .budget(BetaManagedAgentsBudgetLimit.builder()
                        .type(BetaManagedAgentsBudgetLimit.Type.LIMIT)
                        .maxListCost(BetaMonetaryAmount.builder()
                                .amount(Integer.toString(config.sessionBudgetCents()))
                                .currency(BetaCurrency.USD)
                                .build())
                        .build());
        config.priceBookId().ifPresent(store -> params.addResource(BetaManagedAgentsMemoryStoreResourceParam.builder()
                .type(BetaManagedAgentsMemoryStoreResourceParam.Type.MEMORY_STORE)
                .memoryStoreId(store)
                .access(BetaManagedAgentsMemoryStoreResourceParam.Access.READ_ONLY)
                .instructions("Current store prices and availability, written by the price-check agent. "
                        + "Read it before choosing meals.")
                .build()));

        String sessionId = client().beta().sessions().create(params.build()).id();
        LOG.infof("Planner session %s: https://platform.claude.com/workspaces/%s/sessions/%s",
                sessionId, config.workspace(), sessionId);
        return sessionId;
    }

    @Override
    public SessionEnd converse(String sessionId, String message, ToolHandler tools) {
        var events = client().beta().sessions().events();
        // Open the stream before sending, so no event of this turn is missed.
        try (var stream = events.streamStreaming(sessionId)) {
            events.send(sessionId, EventSendParams.builder()
                    .addEvent(BetaManagedAgentsUserMessageEventParams.builder()
                            .type(BetaManagedAgentsUserMessageEventParams.Type.USER_MESSAGE)
                            .addTextContent(message)
                            .build())
                    .build());

            for (BetaManagedAgentsStreamSessionEvents event
                    : (Iterable<BetaManagedAgentsStreamSessionEvents>) stream.stream()::iterator) {
                if (event.isAgentCustomToolUse()) {
                    answer(sessionId, event.asAgentCustomToolUse(), tools);
                } else if (event.isSessionStatusIdle()) {
                    SessionEnd end = endFor(event.asSessionStatusIdle());
                    if (end != null) {
                        return end;
                    }
                } else if (event.isSessionStatusTerminated()) {
                    return SessionEnd.failed("the session ended");
                } else if (event.isSessionError()) {
                    // Retryable errors are followed by more events; a final one ends in an idle.
                    var error = event.asSessionError().error();
                    LOG.warnf("Session %s error: %s", sessionId, error.message());
                }
            }
        }
        return SessionEnd.failed("the event stream closed before the turn ended");
    }

    private void answer(String sessionId, BetaManagedAgentsAgentCustomToolUseEvent call, ToolHandler tools) {
        ToolReply reply = tools.handle(call.name(), inputJson(call));
        client().beta().sessions().events().send(sessionId, EventSendParams.builder()
                .addEvent(BetaManagedAgentsUserCustomToolResultEventParams.builder()
                        .type(BetaManagedAgentsUserCustomToolResultEventParams.Type.USER_CUSTOM_TOOL_RESULT)
                        .customToolUseId(call.id())
                        .addTextContent(reply.text())
                        .isError(reply.error())
                        .build())
                .build());
    }

    private static String inputJson(BetaManagedAgentsAgentCustomToolUseEvent call) {
        try {
            return ObjectMappers.jsonMapper().writeValueAsString(call.input()._additionalProperties());
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not read the tool input", e);
        }
    }

    /** Null while the session waits on us (a tool result is on its way); otherwise how the turn ended. */
    private static SessionEnd endFor(BetaManagedAgentsSessionStatusIdleEvent idle) {
        var stop = idle.stopReason();
        if (stop.isRequiresAction()) {
            return null;
        }
        if (stop.isEndTurn()) {
            return SessionEnd.endTurn();
        }
        if (stop.isBudgetReached()) {
            return SessionEnd.budgetReached();
        }
        if (stop.isRetriesExhausted()) {
            return SessionEnd.failed("it ran out of retries");
        }
        if (stop.isRefusal()) {
            return SessionEnd.failed("the request was refused");
        }
        return SessionEnd.failed("it stopped for an unknown reason");
    }
}
