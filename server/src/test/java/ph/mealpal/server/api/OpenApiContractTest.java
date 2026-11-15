package ph.mealpal.server.api;

import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.fail;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.quarkus.test.junit.QuarkusTest;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import org.junit.jupiter.api.Test;

/**
 * The API's contract is server/openapi.json, checked in so a change to it
 * shows in review and the app's tests can read it. The server must serve
 * exactly that document.
 */
@QuarkusTest
class OpenApiContractTest {

    private static final Path CONTRACT = Path.of("openapi.json");
    private static final Path SERVED = Path.of("build", "openapi.json");
    private static final ObjectMapper JSON = new ObjectMapper();

    private static JsonNode served() throws IOException {
        String body = given().queryParam("format", "json").get("/q/openapi")
                .then().statusCode(200).extract().asString();
        return JSON.readTree(body);
    }

    @Test
    void theCheckedInContractIsWhatTheServerServes() throws IOException {
        JsonNode served = served();
        if (Files.exists(CONTRACT) && JSON.readTree(CONTRACT.toFile()).equals(served)) {
            return;
        }
        Files.createDirectories(SERVED.getParent());
        JSON.writerWithDefaultPrettyPrinter().writeValue(SERVED.toFile(), served);
        fail("openapi.json is not what the server serves. The served document is in build/openapi.json; "
                + "if the API change is meant, copy it over: cp build/openapi.json openapi.json");
    }

    @Test
    void theContractListsTheThreeCallsUnderV1WithTheirAnswers() throws IOException {
        JsonNode paths = served().path("paths");
        Map<String, Set<String>> answers = new TreeMap<>();
        paths.properties().forEach(path -> path.getValue().properties().forEach(op -> {
            Set<String> codes = new TreeSet<>();
            op.getValue().path("responses").fieldNames().forEachRemaining(codes::add);
            answers.put(op.getKey().toUpperCase() + " " + path.getKey(), codes);
        }));

        assertEquals(Map.of(
                "POST /v1/plans", Set.of("202", "400", "401", "503"),
                "GET /v1/plans/{id}", Set.of("200", "401", "404"),
                "POST /v1/plans/{id}/swaps", Set.of("202", "400", "401", "404", "409")), answers);
    }

    @Test
    void everyCallDeclaresTheAppKeyHeader() throws IOException {
        JsonNode doc = served();
        JsonNode scheme = doc.path("components").path("securitySchemes").path("appKey");
        assertEquals("apiKey", scheme.path("type").asText());
        assertEquals("header", scheme.path("in").asText());
        assertEquals("X-MealPal-Key", scheme.path("name").asText());

        List<String> unsecured = new ArrayList<>();
        doc.path("paths").properties().forEach(path -> path.getValue().properties().forEach(op -> {
            if (!op.getValue().path("security").toString().contains("appKey")) {
                unsecured.add(op.getKey() + " " + path.getKey());
            }
        }));
        assertEquals(List.of(), unsecured);
    }

    @Test
    void theAnswersCarryTheirShapes() throws IOException {
        JsonNode doc = served();
        JsonNode plans = doc.path("paths").path("/v1/plans").path("post").path("responses");
        assertEquals("#/components/schemas/PlanRecord", ref(plans.path("202")));
        assertEquals("#/components/schemas/Problems", ref(plans.path("400")));
        assertEquals("#/components/schemas/Message", ref(plans.path("503")));

        JsonNode schemas = doc.path("components").path("schemas");
        assertEquals(Set.of("building", "ready", "failed"), enumOf(schemas.path("PlanStatus")));
        assertEquals(Set.of("lose", "maintain", "gain"), enumOf(schemas.path("Goal")));
        assertEquals(Set.of("mon", "tue", "wed", "thu", "fri", "sat", "sun"), enumOf(schemas.path("Weekday")));
        assertEquals(Set.of("breakfast", "lunch", "dinner", "snack"), enumOf(schemas.path("Slot")));
    }

    @Test
    void theShapesNameTheFieldsTheyAlwaysCarry() throws IOException {
        JsonNode schemas = served().path("components").path("schemas");
        Map<String, Set<String>> required = new TreeMap<>();
        schemas.properties().forEach(s -> {
            Set<String> fields = new TreeSet<>();
            s.getValue().path("required").forEach(f -> fields.add(f.asText()));
            if (s.getValue().has("properties")) {
                required.put(s.getKey(), fields);
            }
        });

        assertEquals(Map.of(
                "PlanRequest", Set.of("targetKcal", "budgetPhp", "goal", "storeIds"),
                "SwapRequest", Set.of("weekday", "slot"),
                // week is null until the first week is accepted; message only when there is one.
                "PlanRecord", Set.of("id", "status"),
                "WeekPlan", Set.of("days", "pricePhp"),
                "PlannedDay", Set.of("weekday", "meals", "kcal", "pricePhp"),
                "PlannedMeal", Set.of("slot", "id", "name", "kcal", "pricePhp", "image", "servings", "ingredients"),
                "PlannedIngredient", Set.of("id", "name", "kind", "unit", "qty", "pricePhp"),
                "Problems", Set.of("problems"),
                "Message", Set.of("message")), required);
    }

    @Test
    void theCallsHaveNamesAPersonWouldUse() throws IOException {
        JsonNode paths = served().path("paths");
        assertEquals("Start a plan", paths.path("/v1/plans").path("post").path("summary").asText());
        assertEquals("Read a plan", paths.path("/v1/plans/{id}").path("get").path("summary").asText());
        assertEquals("Swap a meal", paths.path("/v1/plans/{id}/swaps").path("post").path("summary").asText());
        assertEquals("[\"Plans\"]", paths.path("/v1/plans").path("post").path("tags").toString());
    }

    private static String ref(JsonNode response) {
        return response.path("content").path("application/json").path("schema").path("$ref").asText();
    }

    private static Set<String> enumOf(JsonNode schema) {
        Set<String> values = new TreeSet<>();
        schema.path("enum").forEach(v -> values.add(v.asText()));
        return values;
    }
}
