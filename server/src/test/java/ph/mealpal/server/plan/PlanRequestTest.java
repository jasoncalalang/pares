package ph.mealpal.server.plan;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import org.junit.jupiter.api.Test;

class PlanRequestTest {

    @Test
    void aCompleteRequestHasNoProblems() {
        assertEquals(List.of(), new PlanRequest(2087, 2000, Goal.LOSE, List.of("palengke")).problems());
    }

    @Test
    void theTargetStaysInsideTheSafeRange() {
        assertEquals(List.of("targetKcal must be between 1,200 and 4,500."),
                new PlanRequest(900, 2000, Goal.LOSE, List.of("palengke")).problems());
        assertEquals(List.of("targetKcal must be between 1,200 and 4,500."),
                new PlanRequest(5000, 2000, Goal.GAIN, List.of("palengke")).problems());
    }

    @Test
    void theBudgetStartsWhereTheAppsStepperStops() {
        assertEquals(List.of("budgetPhp must be at least ₱500."),
                new PlanRequest(2087, 400, Goal.LOSE, List.of("palengke")).problems());
    }

    @Test
    void atLeastOneStoreAndAGoalAreNeeded() {
        assertEquals(List.of("goal is required: lose, maintain or gain.", "Pick at least one store."),
                new PlanRequest(2087, 2000, null, List.of()).problems());
        assertEquals(List.of("Pick at least one store."),
                new PlanRequest(2087, 2000, Goal.MAINTAIN, null).problems());
    }
}
