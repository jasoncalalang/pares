package ph.mealpal.server.prices;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.junit.jupiter.api.Test;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.prices.Observation.Status;

class PriceIntakeTest {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final LocalDate RUN_ON = LocalDate.of(2026, 11, 22);

    private final PriceIntake intake = new PriceIntake(MealBank.fromClasspath("meal-bank.json"),
            Set.of("palengke", "puregold"), Set.of("da.gov.ph", "puregold.com.ph"));

    /** A palengke price for 1 kg of rice from the DA, with [changes] laid over it. */
    private static Map<String, Object> line(Object... changes) {
        Map<String, Object> line = new HashMap<>(Map.of(
                "ingredientId", "rice",
                "store", "palengke",
                "pricePhp", 52,
                "per", Map.of("qty", 1, "unit", "kg"),
                "source", "DA Bantay Presyo",
                "sourceUrl", "https://www.da.gov.ph/wp-content/uploads/2026/11/Price-Monitoring-Nov-21.pdf",
                "observedOn", "2026-11-21"));
        for (int i = 0; i < changes.length; i += 2) {
            line.put((String) changes[i], changes[i + 1]);
        }
        return line;
    }

    private List<Observation> check(Map<PriceKey, BigDecimal> last, List<Map<String, Object>> lines) {
        try {
            String report = JSON.writeValueAsString(Map.of("prices", lines));
            return intake.check(PriceReport.parse(report), RUN_ON, last);
        } catch (com.fasterxml.jackson.core.JsonProcessingException e) {
            throw new AssertionError(e);
        }
    }

    private Observation one(Map<String, Object> line) {
        return check(Map.of(), List.of(line)).get(0);
    }

    private static void assertRejected(Observation o, String reason) {
        assertEquals(Status.REJECTED, o.status(), o.toString());
        assertEquals(reason, o.reason());
        assertNull(o.unitPricePhp());
    }

    @Test
    void aPricePerKiloBecomesAPricePerGram() {
        Observation rice = one(line());
        assertEquals(Status.ACCEPTED, rice.status(), rice.reason());
        assertEquals(new BigDecimal("0.052000"), rice.unitPricePhp());
        assertEquals("rice", rice.ingredientId());
        assertEquals("palengke", rice.storeId());
        assertEquals(LocalDate.of(2026, 11, 21), rice.observedOn());
    }

    @Test
    void aPricePerTrayBecomesAPricePerEgg() {
        Observation eggs = one(line("ingredientId", "egg", "pricePhp", 240, "per", Map.of("qty", 30, "unit", "pc")));
        assertEquals(Status.ACCEPTED, eggs.status(), eggs.reason());
        assertEquals(new BigDecimal("8.000000"), eggs.unitPricePhp());
    }

    @Test
    void aPricePerKiloOfSomethingCountedInPiecesUsesTheBanksPieceWeight() {
        // Saba is counted in pieces of 81 g: 80 per kg is 6.48 a piece.
        Observation saba = one(line("ingredientId", "saba", "pricePhp", 80));
        assertEquals(Status.ACCEPTED, saba.status(), saba.reason());
        assertEquals(new BigDecimal("6.480000"), saba.unitPricePhp());
    }

    @Test
    void aPricePerLitreBecomesAPricePerMillilitre() {
        Observation soy = one(line("ingredientId", "soy-sauce", "store", "puregold", "pricePhp", 45,
                "per", Map.of("qty", 1, "unit", "l"), "sourceUrl", "https://puregold.com.ph/soy-sauce-1l"));
        assertEquals(Status.ACCEPTED, soy.status(), soy.reason());
        assertEquals(new BigDecimal("0.045000"), soy.unitPricePhp());
    }

    @Test
    void aPriceThatCannotBeTurnedIntoTheBanksUnitIsRejected() {
        assertRejected(one(line("ingredientId", "garlic", "per", Map.of("qty", 1, "unit", "pc"))),
                "garlic is counted in g; a price per pc cannot be turned into that.");
        assertRejected(one(line("ingredientId", "egg", "per", Map.of("qty", 1, "unit", "l"))),
                "egg is counted in pc; a price per l cannot be turned into that.");
        assertRejected(one(line("per", Map.of("qty", 1, "unit", "bundle"))),
                "per.unit must be kg, g, l, ml or pc.");
        assertRejected(one(line("per", Map.of("qty", 0, "unit", "kg"))), "per.qty must be above zero.");
    }

    @Test
    void onlyTheBanksIngredientsAndTheKnownStoresAreTaken() {
        assertRejected(one(line("ingredientId", "truffle")), "truffle is not in the meal bank.");
        assertRejected(one(line("store", "costco")), "costco is not a store the price checker covers.");
    }

    @Test
    void onlyPricesFromTheAllowedSitesAreTaken() {
        assertRejected(one(line("sourceUrl", "https://da.gov.ph.example.com/prices.pdf")),
                "da.gov.ph.example.com is not one of the allowed price sources.");
        assertRejected(one(line("sourceUrl", "ftp://da.gov.ph/prices.pdf")),
                "sourceUrl must be an http or https link.");
        assertRejected(one(line("sourceUrl", null)), "sourceUrl is required.");
        assertEquals(Status.ACCEPTED, one(line("sourceUrl", "https://da.gov.ph/prices")).status());
    }

    @Test
    void aPriceMustBeAPositiveNumberInsideItsOwnRange() {
        assertRejected(one(line("pricePhp", 0)), "pricePhp must be above zero.");
        assertRejected(one(line("pricePhp", "fifty-two")), "pricePhp must be a number.");
        assertRejected(one(line("pricePhp", null)), "pricePhp is required.");
        assertRejected(one(line("lowPhp", 55, "highPhp", 60)), "pricePhp must lie between lowPhp and highPhp.");
        assertEquals(Status.ACCEPTED, one(line("lowPhp", 48, "highPhp", 56)).status());
    }

    @Test
    void aPriceMustBeSeenInTheTwoWeeksBeforeTheRun() {
        assertRejected(one(line("observedOn", "2026-11-23")), "observedOn is after the run.");
        assertRejected(one(line("observedOn", "2026-11-07")), "observedOn is more than 14 days before the run.");
        assertRejected(one(line("observedOn", "last Tuesday")), "observedOn must be a date like 2026-11-21.");
        assertRejected(one(line("observedOn", null)), "observedOn is required.");
        assertEquals(Status.ACCEPTED, one(line("observedOn", "2026-11-08")).status());
    }

    @Test
    void theSameIngredientAndStoreIsTakenOncePerRun() {
        List<Observation> out = check(Map.of(), List.of(line(), line("pricePhp", 54)));
        assertEquals(Status.ACCEPTED, out.get(0).status());
        assertRejected(out.get(1), "rice at palengke is already in this run.");
    }

    @Test
    void aBigSwingFromTheLastAcceptedPriceIsHeldForReview() {
        Map<PriceKey, BigDecimal> last = Map.of(new PriceKey("rice", "palengke"), new BigDecimal("0.050000"));

        Observation up = check(last, List.of(line("pricePhp", 80))).get(0);
        assertEquals(Status.HELD, up.status());
        assertEquals("More than 1.5 times away from the last accepted price (0.050000 per g).", up.reason());
        assertEquals(new BigDecimal("0.080000"), up.unitPricePhp());

        assertEquals(Status.HELD, check(last, List.of(line("pricePhp", 30))).get(0).status());
        assertEquals(Status.ACCEPTED, check(last, List.of(line("pricePhp", 70))).get(0).status());
    }

    @Test
    void aFirstPriceFarFromTheBanksEstimateIsHeldBecauseTheUnitIsProbablyWrong() {
        // 52 per gram is a price per kilo written against the wrong unit.
        Observation rice = one(line("per", Map.of("qty", 1, "unit", "g")));
        assertEquals(Status.HELD, rice.status());
        assertEquals("More than 3 times away from the meal bank's estimate (0.05 per g); check the unit.",
                rice.reason());
    }

    @Test
    void oneBadLineDoesNotSinkTheReport() {
        List<Observation> out = check(Map.of(), List.of(line("ingredientId", 42), line("ingredientId", "egg",
                "pricePhp", 240, "per", Map.of("qty", 30, "unit", "pc"))));
        assertRejected(out.get(0), "ingredientId must be text.");
        assertEquals(Status.ACCEPTED, out.get(1).status());
    }

    @Test
    void aReportThatIsNotJsonIsRefusedWhole() {
        assertThrows(IllegalArgumentException.class, () -> PriceReport.parse("prices: rice 52"));
        assertThrows(IllegalArgumentException.class, () -> PriceReport.parse("{\"prices\": 3}"));
        assertTrue(PriceReport.parse("{\"prices\": []}").prices().isEmpty());
    }
}
