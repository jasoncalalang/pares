package ph.mealpal.server.prices;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.sql.DataSource;

/** The price book in Postgres (supabase/migrations). */
public final class JdbcPriceBook implements PriceBook {

    private static final String INSERT_RUN = """
            insert into pricebook.runs (session_id, run_on) values (?, ?)
            on conflict (session_id) do nothing
            returning id""";

    private static final String INSERT_OBSERVATION = """
            insert into pricebook.observations (run_id, ingredient_id, store_id, price_php, per_qty, per_unit,
              unit_price_php, source, source_url, observed_on, status, reason, raw)
            values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?::jsonb)""";

    private final DataSource dataSource;

    public JdbcPriceBook(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public Map<PriceKey, BigDecimal> currentUnitPrices() {
        Map<PriceKey, BigDecimal> prices = new HashMap<>();
        try (Connection c = dataSource.getConnection();
                PreparedStatement s = c.prepareStatement(
                        "select ingredient_id, store_id, unit_price_php from pricebook.current_prices");
                ResultSet r = s.executeQuery()) {
            while (r.next()) {
                prices.put(new PriceKey(r.getString(1), r.getString(2)), r.getBigDecimal(3));
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Could not read the current prices: " + e.getMessage(), e);
        }
        return prices;
    }

    @Override
    public boolean record(String sessionId, LocalDate runOn, List<Observation> observations) {
        try (Connection c = dataSource.getConnection()) {
            c.setAutoCommit(false);
            try {
                Long runId = insertRun(c, sessionId, runOn);
                if (runId == null) {
                    c.rollback();
                    return false;
                }
                insertObservations(c, runId, observations);
                c.commit();
                return true;
            } catch (SQLException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new IllegalStateException("Could not record run " + sessionId + ": " + e.getMessage(), e);
        }
    }

    private static Long insertRun(Connection c, String sessionId, LocalDate runOn) throws SQLException {
        try (PreparedStatement s = c.prepareStatement(INSERT_RUN)) {
            s.setString(1, sessionId);
            s.setDate(2, Date.valueOf(runOn));
            try (ResultSet r = s.executeQuery()) {
                return r.next() ? r.getLong(1) : null;
            }
        }
    }

    private static void insertObservations(Connection c, long runId, List<Observation> observations)
            throws SQLException {
        try (PreparedStatement s = c.prepareStatement(INSERT_OBSERVATION)) {
            for (Observation o : observations) {
                s.setLong(1, runId);
                s.setString(2, o.ingredientId());
                s.setString(3, o.storeId());
                s.setBigDecimal(4, o.pricePhp());
                s.setBigDecimal(5, o.perQty());
                s.setString(6, o.perUnit());
                s.setBigDecimal(7, o.unitPricePhp());
                s.setString(8, o.source());
                s.setString(9, o.sourceUrl());
                s.setDate(10, o.observedOn() == null ? null : Date.valueOf(o.observedOn()));
                s.setString(11, o.status().name().toLowerCase(java.util.Locale.ROOT));
                s.setString(12, o.reason());
                s.setString(13, o.raw());
                s.addBatch();
            }
            s.executeBatch();
        }
    }
}
