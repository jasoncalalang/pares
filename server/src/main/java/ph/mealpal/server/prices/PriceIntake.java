package ph.mealpal.server.prices;

import com.fasterxml.jackson.databind.JsonNode;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.net.URISyntaxException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import ph.mealpal.server.bank.Ingredient;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.prices.Observation.Status;

/**
 * Checks what the price checker reported before any of it can price a meal. The agent reads the web,
 * and a web page can be wrong or hostile, so nothing it writes is trusted: every line must name a bank
 * ingredient and a covered store, come from an allowed site, be dated in the two weeks before the run,
 * and convert into the bank's unit. A line that passes but sits far from the last accepted price, or
 * from the bank's estimate when there is none, is held for a person instead of used.
 */
public final class PriceIntake {

    /** How old a price may be when the run reads it. */
    static final int MAX_AGE_DAYS = 14;

    /** A move beyond this factor from the last accepted price is held. */
    static final BigDecimal SWING = new BigDecimal("1.5");

    /** A first price beyond this factor from the bank's estimate is held: usually a unit mix-up. */
    static final BigDecimal FIRST_SEEN_BAND = new BigDecimal("3");

    private static final int SCALE = 6;
    private static final BigDecimal THOUSAND = BigDecimal.valueOf(1000);
    private static final Set<String> UNITS = Set.of("kg", "g", "l", "ml", "pc");

    private final MealBank bank;
    private final Set<String> stores;
    private final Set<String> sourceHosts;

    public PriceIntake(MealBank bank, Set<String> stores, Set<String> sourceHosts) {
        this.bank = bank;
        this.stores = Set.copyOf(stores);
        this.sourceHosts = Set.copyOf(sourceHosts);
    }

    /**
     * Checks every line of [report], in order. [lastAccepted] holds the last accepted price per bank
     * unit for each ingredient and store, from earlier runs.
     */
    public List<Observation> check(PriceReport report, LocalDate runOn, Map<PriceKey, BigDecimal> lastAccepted) {
        List<Observation> out = new ArrayList<>();
        Set<PriceKey> seen = new HashSet<>();
        for (JsonNode line : report.prices()) {
            Observation o;
            try {
                o = checkLine(line, runOn, lastAccepted, seen);
            } catch (Rejected r) {
                o = Observation.rejected(line, r.getMessage());
            }
            if (o.status() != Status.REJECTED) {
                seen.add(new PriceKey(o.ingredientId(), o.storeId()));
            }
            out.add(o);
        }
        return out;
    }

    private Observation checkLine(JsonNode line, LocalDate runOn, Map<PriceKey, BigDecimal> lastAccepted,
            Set<PriceKey> seen) throws Rejected {
        if (!line.isObject()) {
            throw new Rejected("Each price must be a JSON object.");
        }
        String ingredientId = text(line, "ingredientId");
        Ingredient ingredient = bank.ingredient(ingredientId)
                .orElseThrow(() -> new Rejected(ingredientId + " is not in the meal bank."));
        String store = text(line, "store");
        if (!stores.contains(store)) {
            throw new Rejected(store + " is not a store the price checker covers.");
        }

        BigDecimal price = positive(line, "pricePhp");
        BigDecimal low = optionalNumber(line, "lowPhp");
        BigDecimal high = optionalNumber(line, "highPhp");
        if ((low != null && price.compareTo(low) < 0) || (high != null && price.compareTo(high) > 0)) {
            throw new Rejected("pricePhp must lie between lowPhp and highPhp.");
        }

        JsonNode per = line.get("per");
        if (per == null || per.isNull()) {
            throw new Rejected("per is required.");
        }
        if (!per.isObject()) {
            throw new Rejected("per must be an object with qty and unit.");
        }
        BigDecimal perQty = positive(per, "qty", "per.qty");
        String perUnit = text(per, "unit", "per.unit");
        if (!UNITS.contains(perUnit)) {
            throw new Rejected("per.unit must be kg, g, l, ml or pc.");
        }
        BigDecimal unitPrice = unitPrice(ingredient, price, perQty, perUnit);

        String source = text(line, "source");
        String sourceUrl = text(line, "sourceUrl");
        checkSource(sourceUrl);
        LocalDate observedOn = date(line, "observedOn");
        if (observedOn.isAfter(runOn)) {
            throw new Rejected("observedOn is after the run.");
        }
        if (observedOn.isBefore(runOn.minusDays(MAX_AGE_DAYS))) {
            throw new Rejected("observedOn is more than " + MAX_AGE_DAYS + " days before the run.");
        }

        PriceKey key = new PriceKey(ingredientId, store);
        if (seen.contains(key)) {
            throw new Rejected(ingredientId + " at " + store + " is already in this run.");
        }

        String unit = ingredient.unit().json();
        String held = null;
        BigDecimal last = lastAccepted.get(key);
        if (last != null) {
            if (outside(unitPrice, last, SWING)) {
                held = "More than " + SWING.toPlainString() + " times away from the last accepted price ("
                        + last.toPlainString() + " per " + unit + ").";
            }
        } else {
            BigDecimal estimate = BigDecimal.valueOf(ingredient.pricePhpPerUnit());
            if (outside(unitPrice, estimate, FIRST_SEEN_BAND)) {
                held = "More than " + FIRST_SEEN_BAND.toPlainString() + " times away from the meal bank's estimate ("
                        + estimate.toPlainString() + " per " + unit + "); check the unit.";
            }
        }
        return new Observation(ingredientId, store, price, perQty, perUnit, unitPrice, source, sourceUrl,
                observedOn, held == null ? Status.ACCEPTED : Status.HELD, held, line.toString());
    }

    /**
     * The price of one bank unit. Weight converts to anything: to g directly, and to ml or pc through
     * the bank's grams per unit (the density, or the USDA piece weight). Volume converts only to ml and
     * a count only to pc.
     */
    private static BigDecimal unitPrice(Ingredient ingredient, BigDecimal price, BigDecimal qty, String unit)
            throws Rejected {
        Ingredient.Unit bankUnit = ingredient.unit();
        switch (unit) {
            case "kg", "g" -> {
                BigDecimal grams = unit.equals("kg") ? qty.multiply(THOUSAND) : qty;
                BigDecimal perGram = price;
                if (bankUnit != Ingredient.Unit.G) {
                    perGram = price.multiply(ingredient.gramsPerUnit());
                }
                return perGram.divide(grams, SCALE, RoundingMode.HALF_UP);
            }
            case "l", "ml" -> {
                if (bankUnit == Ingredient.Unit.ML) {
                    BigDecimal ml = unit.equals("l") ? qty.multiply(THOUSAND) : qty;
                    return price.divide(ml, SCALE, RoundingMode.HALF_UP);
                }
            }
            default -> {
                if (bankUnit == Ingredient.Unit.PC) {
                    return price.divide(qty, SCALE, RoundingMode.HALF_UP);
                }
            }
        }
        throw new Rejected(ingredient.id() + " is counted in " + bankUnit.json() + "; a price per " + unit
                + " cannot be turned into that.");
    }

    private void checkSource(String sourceUrl) throws Rejected {
        URI uri;
        try {
            uri = new URI(sourceUrl);
        } catch (URISyntaxException e) {
            throw new Rejected("sourceUrl must be an http or https link.");
        }
        String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase(Locale.ROOT);
        if (!scheme.equals("http") && !scheme.equals("https") || uri.getHost() == null) {
            throw new Rejected("sourceUrl must be an http or https link.");
        }
        String host = uri.getHost().toLowerCase(Locale.ROOT);
        for (String allowed : sourceHosts) {
            if (host.equals(allowed) || host.endsWith("." + allowed)) {
                return;
            }
        }
        throw new Rejected(host + " is not one of the allowed price sources.");
    }

    private static boolean outside(BigDecimal value, BigDecimal reference, BigDecimal factor) {
        return value.compareTo(reference.multiply(factor)) > 0 || value.multiply(factor).compareTo(reference) < 0;
    }

    private static String text(JsonNode node, String field) throws Rejected {
        return text(node, field, field);
    }

    private static String text(JsonNode node, String field, String name) throws Rejected {
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) {
            throw new Rejected(name + " is required.");
        }
        if (!value.isTextual()) {
            throw new Rejected(name + " must be text.");
        }
        return value.asText();
    }

    private static BigDecimal positive(JsonNode node, String field) throws Rejected {
        return positive(node, field, field);
    }

    private static BigDecimal positive(JsonNode node, String field, String name) throws Rejected {
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) {
            throw new Rejected(name + " is required.");
        }
        if (!value.isNumber()) {
            throw new Rejected(name + " must be a number.");
        }
        BigDecimal number = value.decimalValue();
        if (number.signum() <= 0) {
            throw new Rejected(name + " must be above zero.");
        }
        return number;
    }

    private static BigDecimal optionalNumber(JsonNode node, String field) throws Rejected {
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) {
            return null;
        }
        if (!value.isNumber()) {
            throw new Rejected(field + " must be a number.");
        }
        return value.decimalValue();
    }

    private static LocalDate date(JsonNode node, String field) throws Rejected {
        String text = text(node, field);
        try {
            return LocalDate.parse(text);
        } catch (DateTimeParseException e) {
            throw new Rejected(field + " must be a date like 2026-11-21.");
        }
    }

    /** Why one line cannot be used. Checked, so every reject path is visible in the signatures. */
    private static final class Rejected extends Exception {
        Rejected(String message) {
            super(message, null, false, false);
        }
    }
}
