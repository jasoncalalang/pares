package ph.mealpal.server.plan;

import org.eclipse.microprofile.openapi.annotations.media.Schema;

/**
 * A plan as the app sees it. {@code week} is the last accepted week (kept
 * while a swap builds); {@code message} says why the last run failed.
 */
@Schema(requiredProperties = {"id", "status"})
public record PlanRecord(String id, PlanStatus status, WeekPlan week, String message) {}
