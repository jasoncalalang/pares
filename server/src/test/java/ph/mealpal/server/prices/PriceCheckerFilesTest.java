package ph.mealpal.server.prices;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.yaml.snakeyaml.Yaml;
import ph.mealpal.server.bank.MealBank;

/**
 * The price checker lives in four places: its agent file, its sandbox, its weekly deployment and the
 * server config that checks what it reports. These tests keep them saying the same thing, and keep
 * the weekly run asking for exactly the meal bank's ingredients.
 */
class PriceCheckerFilesTest {

    private static final Path AGENT = Path.of("anthropic/agents/price-checker.md");
    private static final Path ENVIRONMENT = Path.of("anthropic/environments/price-checker.yaml");
    private static final Path DEPLOYMENT = Path.of("anthropic/deployments/price-check-weekly.yaml");
    private static final Path APP_STORES = Path.of("../lib/src/stores/catalog.dart");

    private static final String CATALOG_START = "Ingredients to price (id | name | counted in):";

    private static String read(Path path) throws IOException {
        return Files.readString(path);
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> frontmatter(Path markdown) throws IOException {
        String[] parts = read(markdown).split("(?m)^---\\s*$", 3);
        return (Map<String, Object>) new Yaml().load(parts[1]);
    }

    private static String body(Path markdown) throws IOException {
        return read(markdown).split("(?m)^---\\s*$", 3)[2];
    }

    @SuppressWarnings("unchecked")
    private static Map<String, Object> yaml(Path path) throws IOException {
        return (Map<String, Object>) new Yaml().load(read(path));
    }

    private static Set<String> config(String key) throws IOException {
        Properties properties = new Properties();
        try (InputStream in = PriceCheckerFilesTest.class.getResourceAsStream("/application.properties")) {
            properties.load(in);
        }
        return Arrays.stream(properties.getProperty(key, "").split(","))
                .map(String::trim).filter(s -> !s.isEmpty()).collect(Collectors.toCollection(TreeSet::new));
    }

    @SuppressWarnings("unchecked")
    private static Set<String> allowedDomains(String tool) throws IOException {
        List<Map<String, Object>> tools = (List<Map<String, Object>>) frontmatter(AGENT).get("tools");
        for (Map<String, Object> config : (List<Map<String, Object>>) tools.get(0).get("configs")) {
            if (tool.equals(config.get("name"))) {
                return new TreeSet<>((List<String>) config.get("allowed_domains"));
            }
        }
        throw new AssertionError("no " + tool + " config in " + AGENT);
    }

    @Test
    @SuppressWarnings("unchecked")
    void theServerTakesPricesOnlyFromTheSitesTheAgentCanReach() throws IOException {
        Set<String> sources = config("mealpal.prices.source-hosts");
        assertEquals(sources, allowedDomains("web_search"));
        assertEquals(sources, allowedDomains("web_fetch"));

        Map<String, Object> networking = (Map<String, Object>) ((Map<String, Object>) yaml(ENVIRONMENT)
                .get("config")).get("networking");
        Set<String> hosts = new TreeSet<>((List<String>) networking.get("allowed_hosts"));
        Set<String> expected = new TreeSet<>();
        sources.forEach(d -> {
            expected.add(d);
            expected.add("*." + d);
        });
        assertEquals(expected, hosts);
    }

    @Test
    void theAgentAndTheServerNameTheSameStoresAndTheAppKnowsThemAll() throws IOException {
        String stores = body(AGENT).split("(?m)^## Stores\\s*$", 2)[1].split("(?m)^## ", 2)[0];
        Set<String> named = new TreeSet<>();
        Matcher m = Pattern.compile("`([a-z0-9-]+)`").matcher(stores);
        while (m.find()) {
            named.add(m.group(1));
        }
        assertEquals(config("mealpal.prices.stores"), named);

        Set<String> app = new TreeSet<>();
        Matcher ids = Pattern.compile("Store\\(id: '([^']+)'").matcher(read(APP_STORES));
        while (ids.find()) {
            app.add(ids.group(1));
        }
        assertTrue(app.containsAll(named), "stores the app does not have: " + named.stream()
                .filter(s -> !app.contains(s)).toList());
    }

    @Test
    @SuppressWarnings("unchecked")
    void theWeeklyRunAsksForEveryIngredientInTheBankAndNothingElse() throws IOException {
        StringBuilder expected = new StringBuilder();
        MealBank bank = MealBank.fromClasspath("meal-bank.json");
        bank.ingredients().forEach(i -> expected.append("- ").append(i.id()).append(" | ").append(i.name())
                .append(" | ").append(i.unit().json()).append('\n'));

        Map<String, Object> outcome = ((List<Map<String, Object>>) yaml(DEPLOYMENT).get("initial_events")).get(0);
        String description = (String) outcome.get("description");
        assertTrue(description.contains(CATALOG_START), "the description must hold the catalog block");
        List<String> listed = new ArrayList<>();
        for (String line : description.split(Pattern.quote(CATALOG_START), 2)[1].strip().split("\n")) {
            if (!line.startsWith("- ")) {
                break;
            }
            listed.add(line);
        }
        assertEquals(expected.toString(), String.join("\n", listed) + "\n",
                "The weekly run's catalog differs from the meal bank. Replace the lines under '"
                        + CATALOG_START + "' in " + DEPLOYMENT + " with:\n" + expected);
    }

    @Test
    @SuppressWarnings("unchecked")
    void theWeeklyRunIsAnOutcomeWithACapScheduledInManilaWithThePriceBook() throws IOException {
        Map<String, Object> deployment = yaml(DEPLOYMENT);
        assertEquals("../agents/price-checker.md", deployment.get("agent"));
        assertEquals("../environments/price-checker.yaml", deployment.get("environment_id"));

        Map<String, Object> schedule = (Map<String, Object>) deployment.get("schedule");
        assertEquals("cron", schedule.get("type"));
        assertEquals("Asia/Manila", schedule.get("timezone"));

        Map<String, Object> budget = (Map<String, Object>) deployment.get("budget");
        assertEquals("limit", budget.get("type"));
        assertEquals("USD", ((Map<String, Object>) budget.get("max_list_cost")).get("currency"));

        List<Object> resources = (List<Object>) deployment.get("resources");
        assertEquals(List.of(Map.of("path", "../memory_stores/price-book.yaml", "access", "read_write")), resources);

        List<Map<String, Object>> events = (List<Map<String, Object>>) deployment.get("initial_events");
        assertEquals(1, events.size());
        assertEquals("user.define_outcome", events.get(0).get("type"));
        Map<String, Object> rubric = (Map<String, Object>) events.get(0).get("rubric");
        assertEquals("text", rubric.get("type"));
        assertTrue(((String) rubric.get("content")).contains("prices.json"));
    }
}
