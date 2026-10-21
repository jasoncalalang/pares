package ph.mealpal.server.plan;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * The plan request, stored as the session's metadata so any server instance
 * can check a submission without a database. "app" marks MealPal's sessions
 * apart from other agents in the same workspace.
 */
public final class PlanMeta {

    static final String APP = "mealpal";

    private PlanMeta() {}

    public static Map<String, String> write(PlanRequest r) {
        Map<String, String> m = new LinkedHashMap<>();
        m.put("app", APP);
        m.put("targetKcal", Integer.toString(r.targetKcal()));
        m.put("budgetPhp", Integer.toString(r.budgetPhp()));
        m.put("goal", r.goal().json());
        m.put("storeIds", String.join(",", r.storeIds()));
        return m;
    }

    /** The request, or empty when the session is not a MealPal plan. */
    public static Optional<PlanRequest> read(Map<String, String> m) {
        if (!APP.equals(m.get("app"))) {
            return Optional.empty();
        }
        try {
            List<String> stores = Arrays.stream(m.getOrDefault("storeIds", "").split(","))
                    .filter(s -> !s.isBlank())
                    .toList();
            return Optional.of(new PlanRequest(
                    Integer.parseInt(m.get("targetKcal")),
                    Integer.parseInt(m.get("budgetPhp")),
                    Goal.fromJson(m.get("goal")),
                    stores));
        } catch (RuntimeException e) {
            return Optional.empty();
        }
    }
}
