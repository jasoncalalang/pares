package ph.mealpal.server.prices;

import com.fasterxml.jackson.databind.JsonNode;
import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * One line of a price report after the server checked it. {@code unitPricePhp} is the price of one
 * of the bank's units (a g, a ml or a pc) and is null when the line was rejected. {@code raw} is the
 * line as the agent wrote it, kept for whoever reviews a held or rejected price.
 */
public record Observation(String ingredientId, String storeId, BigDecimal pricePhp, BigDecimal perQty,
        String perUnit, BigDecimal unitPricePhp, String source, String sourceUrl, LocalDate observedOn,
        Status status, String reason, String raw) {

    public enum Status {
        /** Checked and in range: the planner may price meals with it. */
        ACCEPTED,
        /** Well formed but far from the last price or the bank's estimate: kept for a person to look at. */
        HELD,
        /** Not usable as it stands; {@code reason} says why. */
        REJECTED
    }

    static Observation rejected(JsonNode line, String reason) {
        return new Observation(textOrNull(line, "ingredientId"), textOrNull(line, "store"), null, null, null, null,
                textOrNull(line, "source"), textOrNull(line, "sourceUrl"), null, Status.REJECTED, reason,
                line.toString());
    }

    private static String textOrNull(JsonNode line, String field) {
        JsonNode value = line.get(field);
        return value != null && value.isTextual() ? value.asText() : null;
    }
}
