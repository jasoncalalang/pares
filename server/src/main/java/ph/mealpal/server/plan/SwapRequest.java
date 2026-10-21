package ph.mealpal.server.plan;

import ph.mealpal.server.bank.Slot;

/** One meal the person wants changed, with an optional note ("something cheaper"). */
public record SwapRequest(Weekday weekday, Slot slot, String note) {}
