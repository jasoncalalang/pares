package ph.mealpal.server.prices;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/** Where checked prices are kept: the pricebook schema in Postgres. */
public interface PriceBook {

    /** The latest accepted price per bank unit for each ingredient and store. */
    Map<PriceKey, BigDecimal> currentUnitPrices();

    /**
     * Records one run of the price checker and every line it reported, checked. Returns false, and
     * records nothing, when this session's run is already in the book: the run's webhook can arrive
     * twice.
     */
    boolean record(String sessionId, LocalDate runOn, List<Observation> observations);
}
