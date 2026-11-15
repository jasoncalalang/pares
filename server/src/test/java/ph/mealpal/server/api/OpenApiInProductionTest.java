package ph.mealpal.server.api;

import static io.restassured.RestAssured.given;

import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.QuarkusTestProfile;
import io.quarkus.test.junit.TestProfile;
import java.util.Map;
import org.junit.jupiter.api.Test;

/**
 * Production does not publish the document: the contract lives in the repo,
 * and a stranger who finds the URL gets no map of the API.
 */
@QuarkusTest
@TestProfile(OpenApiInProductionTest.Production.class)
class OpenApiInProductionTest {

    public static class Production implements QuarkusTestProfile {
        @Override
        public String getConfigProfile() {
            return "prod";
        }

        @Override
        public Map<String, String> getConfigOverrides() {
            return Map.of("mealpal.api.app-key", "test-key");
        }
    }

    @Test
    void theDocumentIsNotServed() {
        given().get("/q/openapi").then().statusCode(404);
    }

    @Test
    void theApiStillAnswers() {
        given().header("X-MealPal-Key", "test-key").get("/v1/plans/nope").then().statusCode(404);
    }
}
