package ph.mealpal.server.plan;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

class PlanMetaTest {

    @Test
    void theRequestRoundTripsThroughSessionMetadata() {
        PlanRequest request = new PlanRequest(2087, 2000, Goal.LOSE, List.of("palengke", "sm"));
        Map<String, String> metadata = PlanMeta.write(request);

        assertEquals("mealpal", metadata.get("app"));
        assertEquals(java.util.Optional.of(request), PlanMeta.read(metadata));
    }

    @Test
    void anotherAppsSessionIsNotAPlan() {
        assertTrue(PlanMeta.read(Map.of("app", "ridgewell")).isEmpty());
        assertTrue(PlanMeta.read(Map.of()).isEmpty());
    }

    @Test
    void damagedMetadataIsNotAPlan() {
        assertTrue(PlanMeta.read(Map.of("app", "mealpal", "targetKcal", "lots", "budgetPhp", "2000",
                "goal", "lose", "storeIds", "palengke")).isEmpty());
        assertTrue(PlanMeta.read(Map.of("app", "mealpal", "targetKcal", "2087", "budgetPhp", "2000",
                "goal", "bulk", "storeIds", "palengke")).isEmpty());
    }
}
