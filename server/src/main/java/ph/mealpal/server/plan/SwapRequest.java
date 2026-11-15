package ph.mealpal.server.plan;

import org.eclipse.microprofile.openapi.annotations.media.Schema;
import ph.mealpal.server.bank.Slot;

/** One meal the person wants changed, with an optional note ("something cheaper"). */
@Schema(requiredProperties = {"weekday", "slot"})
public record SwapRequest(Weekday weekday, Slot slot, String note) {}
