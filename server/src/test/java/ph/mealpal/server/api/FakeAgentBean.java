package ph.mealpal.server.api;

import io.quarkus.test.Mock;
import jakarta.inject.Singleton;
import ph.mealpal.server.agent.FakeAgent;

/** Replaces Managed Agents in @QuarkusTest. Singleton, so tests read its fields directly. */
@Mock
@Singleton
public class FakeAgentBean extends FakeAgent {}
