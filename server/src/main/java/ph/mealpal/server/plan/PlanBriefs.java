package ph.mealpal.server.plan;

import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.bank.Slot;

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

                Meal bank, one dish per line. kcal and pricePhp are per serving; slots lists the meals it can be:
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
                Swap: %s %s
                The person wants a different dish for %s's %s.%s
                Keep every other meal as it is unless the day's total or the budget needs a change.
                Call submit_plan with the whole week again.
                """.formatted(s.weekday().json(), s.slot().json(), s.weekday().label(), s.slot().json(), note);
    }

    /** The day and slot of a swap message this class wrote; empty for any other message. */
    public Optional<SwapRequest> readSwap(String message) {
        Matcher m = SWAP_LINE.matcher(message);
        if (!m.lookingAt()) {
            return Optional.empty();
        }
        try {
            return Optional.of(new SwapRequest(Weekday.fromJson(m.group(1)), Slot.fromJson(m.group(2)), null));
        } catch (IllegalArgumentException e) {
            return Optional.empty();
        }
    }

    private static final Pattern SWAP_LINE = Pattern.compile("Swap: ([a-z]+) ([a-z]+)\\n");
}
