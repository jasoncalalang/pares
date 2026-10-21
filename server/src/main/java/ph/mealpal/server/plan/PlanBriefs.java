package ph.mealpal.server.plan;

import ph.mealpal.server.bank.MealBank;

/**
 * The messages the server sends the planner. The standing rules live in the
 * agent's system prompt; these carry one person's numbers and the bank.
 */
public final class PlanBriefs {

    private final MealBank bank;

    public PlanBriefs(MealBank bank) {
        this.bank = bank;
    }

    public String kickoff(PlanRequest r) {
        int target = r.targetKcal();
        return """
                Plan one week (Monday to Sunday) for this person.

                Daily target: %s kcal a day. Each day must total between %s and %s kcal.
                Budget: %s for the week.
                Goal: %s.
                Stores they shop at: %s.

                Meal bank, one dish per line. kcal and pricePhp are per serving:
                %s

                When the week is ready, call submit_plan with all seven days.
                """.formatted(
                Format.thousands(target),
                Format.thousands(PlanCheck.lowestKcal(target)),
                Format.thousands(PlanCheck.highestKcal(target)),
                Format.peso(r.budgetPhp()),
                r.goal().json(),
                String.join(", ", r.storeIds()),
                bank.asJsonLines());
    }

    public String swap(SwapRequest s) {
        String note = s.note() == null || s.note().isBlank() ? "" : " They said: \"" + s.note().strip() + "\".";
        return """
                The person wants a different dish for %s's %s.%s
                Keep every other meal as it is unless the day's total or the budget needs a change.
                Call submit_plan with the whole week again.
                """.formatted(s.weekday().label(), s.slot().json(), note);
    }
}
