package ph.mealpal.server.plan;

/**
 * A plan as the app sees it. {@code week} is the last accepted week (kept
 * while a swap builds); {@code message} says why the last run failed.
 */
public record PlanRecord(String id, PlanStatus status, WeekPlan week, String message) {}
