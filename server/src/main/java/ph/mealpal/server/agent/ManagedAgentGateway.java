package ph.mealpal.server.agent;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.core.JsonValue;
import com.anthropic.core.ObjectMappers;
import com.anthropic.errors.NotFoundException;
import com.anthropic.models.beta.BetaCurrency;
import com.anthropic.models.beta.BetaMonetaryAmount;
import com.anthropic.models.beta.sessions.BetaManagedAgentsBudgetLimit;
import com.anthropic.models.beta.sessions.BetaManagedAgentsMemoryStoreResourceParam;
import com.anthropic.models.beta.sessions.BetaManagedAgentsSession;
import com.anthropic.models.beta.sessions.SessionCreateParams;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsSessionEvent;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsSessionStatusIdleEvent;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsTextBlock;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsUserCustomToolResultEventParams;
import com.anthropic.models.beta.sessions.events.BetaManagedAgentsUserMessageEventParams;
import com.anthropic.models.beta.sessions.events.EventSendParams;
import com.fasterxml.jackson.core.JsonProcessingException;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.jboss.logging.Logger;
import ph.mealpal.server.agent.SessionEvent.Idle;
import ph.mealpal.server.agent.SessionEvent.Stop;
import ph.mealpal.server.agent.SessionEvent.ToolCall;
import ph.mealpal.server.agent.SessionEvent.ToolResult;
import ph.mealpal.server.agent.SessionEvent.UserMessage;

/**
 * The planner on Claude Managed Agents. Credentials resolve the way the `ant`
 * CLI's do: ANTHROPIC_API_KEY when set (Cloud Run reads it from Secret
 * Manager), otherwise the profile from `ant auth login` on a dev machine.
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
    public String startSession(String title, Map<String, String> metadata, String kickoff) {
        String agentId = config.plannerId().orElseThrow(() -> new IllegalStateException(
                "mealpal.agent.planner-id is not set; copy it from anthropic/claude-lock.json"));
        String environmentId = config.environmentId().orElseThrow(() -> new IllegalStateException(
                "mealpal.agent.environment-id is not set; copy it from anthropic/claude-lock.json"));

        SessionCreateParams.Metadata.Builder tags = SessionCreateParams.Metadata.builder();
        metadata.forEach((k, v) -> tags.putAdditionalProperty(k, JsonValue.from(v)));
        SessionCreateParams.Builder params = SessionCreateParams.builder()
                .agent(agentId)
                .environmentId(environmentId)
                .title(title)
                .metadata(tags.build())
                .budget(BetaManagedAgentsBudgetLimit.builder()
                        .type(BetaManagedAgentsBudgetLimit.Type.LIMIT)
                        .maxListCost(BetaMonetaryAmount.builder()
                                .amount(Integer.toString(config.sessionBudgetCents()))
                                .currency(BetaCurrency.USD)
                                .build())
                        .build())
                .addInitialEvent(userMessage(kickoff));
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
    public Optional<SessionView> view(String sessionId) {
        if (!sessionId.startsWith("sesn_")) {
            return Optional.empty();
        }
        BetaManagedAgentsSession session;
        try {
            session = client().beta().sessions().retrieve(sessionId);
        } catch (NotFoundException e) {
            return Optional.empty();
        }
        Map<String, String> metadata = new LinkedHashMap<>();
        session.metadata()._additionalProperties().forEach((k, v) -> {
            Optional<?> text = v.asString(); // JsonValue extends a raw JsonField, so this is untyped
            text.ifPresent(s -> metadata.put(k, s.toString()));
        });

        List<SessionEvent> events = new ArrayList<>();
        for (BetaManagedAgentsSessionEvent e : client().beta().sessions().events().list(sessionId).autoPager()) {
            toEvent(e).ifPresent(events::add);
        }
        return Optional.of(new SessionView(sessionId, metadata, events));
    }

    @Override
    public void sendToolResult(String sessionId, String toolUseId, ToolReply reply) {
        client().beta().sessions().events().send(sessionId, EventSendParams.builder()
                .addEvent(BetaManagedAgentsUserCustomToolResultEventParams.builder()
                        .type(BetaManagedAgentsUserCustomToolResultEventParams.Type.USER_CUSTOM_TOOL_RESULT)
                        .customToolUseId(toolUseId)
                        .addTextContent(reply.text())
                        .isError(reply.error())
                        .build())
                .build());
    }

    @Override
    public void sendMessage(String sessionId, String text) {
        client().beta().sessions().events().send(sessionId, EventSendParams.builder()
                .addEvent(userMessage(text))
                .build());
    }

    private static BetaManagedAgentsUserMessageEventParams userMessage(String text) {
        return BetaManagedAgentsUserMessageEventParams.builder()
                .type(BetaManagedAgentsUserMessageEventParams.Type.USER_MESSAGE)
                .addTextContent(text)
                .build();
    }

    private static Optional<SessionEvent> toEvent(BetaManagedAgentsSessionEvent e) {
        if (e.isUserMessage()) {
            StringBuilder text = new StringBuilder();
            e.asUserMessage().content().forEach(c -> {
                if (c.isText()) {
                    text.append(c.asText().text());
                }
            });
            return Optional.of(new UserMessage(text.toString()));
        }
        if (e.isAgentCustomToolUse()) {
            var call = e.asAgentCustomToolUse();
            return Optional.of(new ToolCall(call.id(), call.name(), json(call.input()._additionalProperties())));
        }
        if (e.isUserCustomToolResult()) {
            var result = e.asUserCustomToolResult();
            String text = result.content().orElse(List.of()).stream()
                    .filter(c -> c.isText())
                    .map(c -> c.asText())
                    .map(BetaManagedAgentsTextBlock::text)
                    .reduce("", String::concat);
            return Optional.of(new ToolResult(result.customToolUseId(), text, result.isError().orElse(false)));
        }
        if (e.isSessionStatusIdle()) {
            return Optional.of(new Idle(stop(e.asSessionStatusIdle())));
        }
        if (e.isSessionStatusTerminated()) {
            return Optional.of(new Idle(Stop.TERMINATED));
        }
        return Optional.empty();
    }

    private static Stop stop(BetaManagedAgentsSessionStatusIdleEvent idle) {
        var reason = idle.stopReason();
        if (reason.isRequiresAction()) {
            return Stop.REQUIRES_ACTION;
        }
        if (reason.isEndTurn()) {
            return Stop.END_TURN;
        }
        if (reason.isBudgetReached()) {
            return Stop.BUDGET_REACHED;
        }
        if (reason.isRetriesExhausted()) {
            return Stop.RETRIES_EXHAUSTED;
        }
        if (reason.isRefusal()) {
            return Stop.REFUSAL;
        }
        return Stop.OTHER;
    }

    private static String json(Map<String, JsonValue> input) {
        try {
            return ObjectMappers.jsonMapper().writeValueAsString(input);
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Could not read the tool input", e);
        }
    }
}
