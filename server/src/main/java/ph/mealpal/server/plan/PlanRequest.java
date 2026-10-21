package ph.mealpal.server.plan;

import java.util.ArrayList;
import java.util.List;

/**
 * What the app sends to start a plan. The calorie target is computed in the
 * app (Mifflin-St Jeor); the server and the agent never recompute it.
 */
public record PlanRequest(int targetKcal, int budgetPhp, Goal goal, List<String> storeIds) {

    static final int MIN_KCAL = 1200;
    static final int MAX_KCAL = 4500;
    static final int MIN_BUDGET_PHP = 500;

    /** What is wrong with this request, in words the app can show; empty when it is fine. */
    public List<String> problems() {
        List<String> problems = new ArrayList<>();
        if (targetKcal < MIN_KCAL || targetKcal > MAX_KCAL) {
            problems.add("targetKcal must be between " + Format.thousands(MIN_KCAL) + " and "
                    + Format.thousands(MAX_KCAL) + ".");
        }
        if (budgetPhp < MIN_BUDGET_PHP) {
            problems.add("budgetPhp must be at least " + Format.peso(MIN_BUDGET_PHP) + ".");
        }
        if (goal == null) {
            problems.add("goal is required: lose, maintain or gain.");
        }
        if (storeIds == null || storeIds.isEmpty()) {
            problems.add("Pick at least one store.");
        }
        return problems;
    }
}
