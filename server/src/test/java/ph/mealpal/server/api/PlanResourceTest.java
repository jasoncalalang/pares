package ph.mealpal.server.api;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.startsWith;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import jakarta.inject.Inject;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import ph.mealpal.server.agent.FakeAgent.Turn;
import ph.mealpal.server.agent.SessionEvent.Stop;
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

    @Inject
    FakeAgentBean agent;

    @BeforeEach
    void plannerSubmitsAValidWeekThenAnAdoboSwap() {
        agent.reset();
        agent.script(Turn.submitting(Stop.END_TURN, week("tinola")), Turn.submitting(Stop.END_TURN, week("adobo")));
    }

    /** The app: every call carries the app key from the build. */
    private static RequestSpecification app() {
        return given().header("X-MealPal-Key", "test-key");
    }

    /** Polls until the plan stops building; each read moves the planner along. */
    private static ValidatableResponse settled(String id) {
        for (int i = 0; i < 20; i++) {
            String status = app().get("/plans/" + id).then().statusCode(200).extract().path("status");
            if (!"building".equals(status)) {
                break;
            }
        }
        return app().get("/plans/" + id).then().statusCode(200);
    }

    private static String newPlan() {
        return app().contentType(ContentType.JSON).body(REQUEST)
                .post("/plans")
                .then().statusCode(202)
                .body("status", equalTo("building"))
                .body("id", startsWith("sesn_"))
                .extract().path("id");
    }

    @Test
    void aPlanIsAcceptedAndBuildsIntoAWeek() {
        settled(newPlan())
                .body("status", equalTo("ready"))
                .body("week.days.size()", equalTo(7))
                .body("week.days[0].weekday", equalTo("mon"))
                .body("week.days[0].kcal", equalTo(2087))
                .body("week.days[0].meals[0].slot", equalTo("breakfast"))
                .body("week.days[0].meals[0].name", equalTo("Tapsilog: beef tapa, garlic rice and egg"))
                .body("week.days[0].meals[0].image", equalTo("tapsilog"))
                .body("week.pricePhp", equalTo(1365));
    }

    @Test
    void aSwapRebuildsTheWeekInTheSameSession() {
        String id = newPlan();
        settled(id).body("status", equalTo("ready"));

        app().contentType(ContentType.JSON)
                .body("{\"weekday\": \"tue\", \"slot\": \"lunch\", \"note\": \"no tinola\"}")
                .post("/plans/" + id + "/swaps")
                .then().statusCode(202).body("status", equalTo("building"));

        settled(id)
                .body("status", equalTo("ready"))
                .body("week.days[1].meals[1].name", equalTo("Chicken adobo with rice"));
    }

    @Test
    void aSwapWhileBuildingIsAConflict() {
        String id = newPlan();
        app().contentType(ContentType.JSON).body("{\"weekday\": \"tue\", \"slot\": \"lunch\"}")
                .post("/plans/" + id + "/swaps")
                .then().statusCode(409)
                .body("message", equalTo("The week is still building."));
    }

    @Test
    void anIncompleteRequestIsRefusedWithItsProblems() {
        app().contentType(ContentType.JSON)
                .body("{\"targetKcal\": 900, \"budgetPhp\": 2000, \"goal\": \"lose\", \"storeIds\": []}")
                .post("/plans")
                .then().statusCode(400)
                .body("problems", hasItem("targetKcal must be between 1,200 and 4,500."))
                .body("problems", hasItem("Pick at least one store."));
    }

    @Test
    void anUnknownGoalIsABadRequest() {
        app().contentType(ContentType.JSON)
                .body("{\"targetKcal\": 2087, \"budgetPhp\": 2000, \"goal\": \"bulk\", \"storeIds\": [\"palengke\"]}")
                .post("/plans")
                .then().statusCode(400);
    }

    @Test
    void whenThePlannerCannotBeReachedThePlanIsNotStarted() {
        agent.startFailure = new IllegalStateException("no credentials");
        app().contentType(ContentType.JSON).body(REQUEST)
                .post("/plans")
                .then().statusCode(503)
                .body("message", equalTo("Could not open a planner session: no credentials"));
    }

    @Test
    void unknownPlansAndOtherAppsSessionsAreNotFound() {
        app().get("/plans/nope").then().statusCode(404);
        app().get("/plans/" + agent.foreignSession()).then().statusCode(404);
        app().contentType(ContentType.JSON)
                .body("{\"weekday\": \"tue\", \"slot\": \"lunch\"}")
                .post("/plans/nope/swaps")
                .then().statusCode(404);
    }

    @Test
    void aSwapNeedsADayAndASlot() {
        String id = newPlan();
        settled(id);
        app().contentType(ContentType.JSON).body("{\"slot\": \"lunch\"}")
                .post("/plans/" + id + "/swaps")
                .then().statusCode(400)
                .body("problems", hasItem("weekday is required: mon to sun."));
    }

    @Test
    void callsWithoutTheAppKeyAreRefused() {
        given().get("/plans/nope").then().statusCode(401);
        given().header("X-MealPal-Key", "guess").contentType(ContentType.JSON).body(REQUEST)
                .post("/plans").then().statusCode(401);
        org.junit.jupiter.api.Assertions.assertEquals(0, agent.sessionCount(), "no session was started");
    }
}
