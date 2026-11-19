package ph.mealpal.server.prices;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import ph.mealpal.server.db.TestDatabase;
import ph.mealpal.server.prices.Observation.Status;

@Tag("postgres")
class JdbcPriceBookTest {

    private static TestDatabase db;
    private static JdbcPriceBook book;

    @BeforeAll
    static void migrate() throws Exception {
        db = TestDatabase.create();
        book = new JdbcPriceBook(db.dataSource());
    }

    @AfterAll
    static void drop() throws SQLException {
        db.close();
    }

    private static Observation seen(String ingredient, String store, String unitPrice, String observedOn,
            Status status) {
        return new Observation(ingredient, store, new BigDecimal("52"), BigDecimal.ONE, "kg",
                status == Status.REJECTED ? null : new BigDecimal(unitPrice), "DA Bantay Presyo",
                "https://www.da.gov.ph/prices.pdf", observedOn == null ? null : LocalDate.parse(observedOn), status,
                status == Status.ACCEPTED ? null : "why", "{\"ingredientId\": \"" + ingredient + "\"}");
    }

    private static long count(String sql) throws SQLException {
        try (Connection c = db.dataSource().getConnection(); Statement s = c.createStatement();
                ResultSet r = s.executeQuery(sql)) {
            r.next();
            return r.getLong(1);
        }
    }

    @Test
    void theTablesSitOutsideTheApiSchemaWithRowSecurityOn() throws SQLException {
        assertEquals(2, count("""
                select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
                where n.nspname = 'pricebook' and c.relname in ('runs', 'observations') and c.relrowsecurity"""));
        assertEquals(0, count("""
                select count(*) from pg_class c join pg_namespace n on n.oid = c.relnamespace
                where n.nspname = 'public' and c.relkind in ('r', 'v')"""));
    }

    @Test
    void onlyTheLatestAcceptedPriceIsCurrent() {
        assertTrue(book.record("sesn_week1", LocalDate.of(2026, 11, 15), List.of(
                seen("rice", "palengke", "0.050000", "2026-11-14", Status.ACCEPTED),
                seen("egg", "palengke", "8.000000", "2026-11-14", Status.ACCEPTED))));
        assertTrue(book.record("sesn_week2", LocalDate.of(2026, 11, 22), List.of(
                seen("rice", "palengke", "0.052000", "2026-11-21", Status.ACCEPTED),
                seen("egg", "palengke", "16.000000", "2026-11-21", Status.HELD),
                seen("garlic", "palengke", null, "2026-11-21", Status.REJECTED),
                seen("rice", "puregold", "0.060000", "2026-11-20", Status.ACCEPTED))));

        assertEquals(Map.of(
                new PriceKey("rice", "palengke"), new BigDecimal("0.052000"),
                new PriceKey("rice", "puregold"), new BigDecimal("0.060000"),
                new PriceKey("egg", "palengke"), new BigDecimal("8.000000")), book.currentUnitPrices());
    }

    @Test
    void aRunIsRecordedOncePerSession() throws SQLException {
        List<Observation> run = List.of(seen("vinegar", "puregold", "0.050000", "2026-11-21", Status.ACCEPTED));
        assertTrue(book.record("sesn_twice", LocalDate.of(2026, 11, 22), run));
        assertFalse(book.record("sesn_twice", LocalDate.of(2026, 11, 22), run));
        assertEquals(1, count("select count(*) from pricebook.observations where ingredient_id = 'vinegar'"));
    }

    @Test
    void heldAndRejectedLinesAreKeptWithTheirReasonAndTheAgentsWords() throws SQLException {
        book.record("sesn_review", LocalDate.of(2026, 11, 22), List.of(
                seen("calamansi", "palengke", null, null, Status.REJECTED)));
        assertEquals(1, count("""
                select count(*) from pricebook.observations
                where ingredient_id = 'calamansi' and status = 'rejected' and reason = 'why'
                  and raw ->> 'ingredientId' = 'calamansi'"""));
    }

    @Test
    void theSchemaRefusesAnAcceptedPriceWithoutAUnitPrice() throws SQLException {
        try (Connection c = db.dataSource().getConnection(); Statement s = c.createStatement()) {
            s.execute("insert into pricebook.runs (session_id, run_on) values ('sesn_bad', '2026-11-22')");
            assertThrows(SQLException.class, () -> s.execute("""
                    insert into pricebook.observations (run_id, ingredient_id, store_id, status, raw)
                    select id, 'rice', 'palengke', 'accepted', '{}' from pricebook.runs
                    where session_id = 'sesn_bad'"""));
        }
    }
}
