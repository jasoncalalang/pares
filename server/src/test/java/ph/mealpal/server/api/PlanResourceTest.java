package ph.mealpal.server.api;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.notNullValue;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import io.quarkus.test.InjectMock;
import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import ph.mealpal.server.agent.AgentGateway;
import ph.mealpal.server.agent.SessionEnd;
import ph.mealpal.server.agent.ToolHandler;
import ph.mealpal.server.plan.Weekday;

@QuarkusTest
class PlanResourceTest {

    private static final String REQUEST = """
            {"targetKcal": 2087, "budgetPhp": 2000, "goal": "lose", "storeIds": ["palengke"]}
            """;

    private static String week(String lunch) {
        return Weekday.stream()
                .map(d -> """
                        {"weekday": "%s", "meals": [
                          {"slot": "breakfast", "meal_id": "tapsilog"},
                          {"slot": "lunch", "meal_id": "%s"},
                          {"slot": "dinner", "meal_id": "munggo"},
                          {"slot": "snack", "meal_id": "saba-peanuts"}]}""".formatted(d.json(), lunch))
                .collect(Collectors.joining(",", "{\"days\": [", "]}"));
    }

    @InjectMock
    AgentGateway gateway;

    @BeforeEach
    void plannerSubmitsAValidWeek() {
        when(gateway.openSession(anyString())).thenReturn("sesn_test");
        when(gateway.converse(anyString(), anyString(), any())).thenAnswer(call -> {
            String message = call.getArgument(1);
            ToolHandler tools = call.getArgument(2);
            tools.handle("submit_plan", week(message.contains("different dish") ? "adobo" : "tinola"));
            return SessionEnd.endTurn();
        });
    }

    /** Polls until the plan stops building; the planner runs on its own thread. */
    private static io.restassured.response.ValidatableResponse settled(String id) throws InterruptedException {
        for (int i = 0; i < 50; i++) {
            String status = given().get("/plans/" + id).then().statusCode(200).extract().path("status");
            if (!"building".equals(status)) {
                break;
            }
            Thread.sleep(20);
        }
        return given().get("/plans/" + id).then().statusCode(200);
    }

    @Test
    void aPlanIsAcceptedAndBuildsIntoAWeek() throws InterruptedException {
        String id = given().contentType(ContentType.JSON).body(REQUEST)
                .post("/plans")
                .then().statusCode(202)
                .body("id", notNullValue())
                .extract().path("id");

        settled(id)
                .body("status", equalTo("ready"))
                .body("week.days.size()", equalTo(7))
                .body("week.days[0].weekday", equalTo("mon"))
                .body("week.days[0].kcal", equalTo(2087))
                .body("week.days[0].meals[0].slot", equalTo("breakfast"))
                .body("week.days[0].meals[0].name", equalTo("Tapsilog: beef tapa, garlic rice and egg"))
                .body("week.days[0].meals[0].image", equalTo("tapsilog"))
                .body("week.pricePhp", equalTo(1750));
    }

    @Test
    void aSwapRebuildsTheWeekInTheSameSession() throws InterruptedException {
        String id = given().contentType(ContentType.JSON).body(REQUEST)
                .post("/plans").then().statusCode(202).extract().path("id");
        settled(id).body("status", equalTo("ready"));

        given().contentType(ContentType.JSON)
                .body("{\"weekday\": \"tue\", \"slot\": \"lunch\", \"note\": \"no tinola\"}")
                .post("/plans/" + id + "/swaps")
                .then().statusCode(202);

        settled(id)
                .body("status", equalTo("ready"))
                .body("week.days[1].meals[1].name", equalTo("Chicken adobo with rice"));
    }

    @Test
    void anIncompleteRequestIsRefusedWithItsProblems() {
        given().contentType(ContentType.JSON)
                .body("{\"targetKcal\": 900, \"budgetPhp\": 2000, \"goal\": \"lose\", \"storeIds\": []}")
                .post("/plans")
                .then().statusCode(400)
                .body("problems", hasItem("targetKcal must be between 1,200 and 4,500."))
                .body("problems", hasItem("Pick at least one store."));
    }

    @Test
    void anUnknownGoalIsABadRequest() {
        given().contentType(ContentType.JSON)
                .body("{\"targetKcal\": 2087, \"budgetPhp\": 2000, \"goal\": \"bulk\", \"storeIds\": [\"palengke\"]}")
                .post("/plans")
                .then().statusCode(400);
    }

    @Test
    void whenThePlannerCannotBeReachedThePlanIsNotStarted() {
        when(gateway.openSession(anyString())).thenThrow(new IllegalStateException("no credentials"));
        given().contentType(ContentType.JSON).body(REQUEST)
                .post("/plans")
                .then().statusCode(503)
                .body("message", equalTo("Could not open a planner session: no credentials"));
    }

    @Test
    void unknownPlansAreNotFound() {
        given().get("/plans/nope").then().statusCode(404);
        given().contentType(ContentType.JSON)
                .body("{\"weekday\": \"tue\", \"slot\": \"lunch\"}")
                .post("/plans/nope/swaps")
                .then().statusCode(404);
    }

    @Test
    void aSwapNeedsADayAndASlot() throws InterruptedException {
        String id = given().contentType(ContentType.JSON).body(REQUEST)
                .post("/plans").then().statusCode(202).extract().path("id");
        settled(id);
        given().contentType(ContentType.JSON).body("{\"slot\": \"lunch\"}")
                .post("/plans/" + id + "/swaps")
                .then().statusCode(400)
                .body("problems", hasItem("weekday is required: mon to sun."));
    }
}
