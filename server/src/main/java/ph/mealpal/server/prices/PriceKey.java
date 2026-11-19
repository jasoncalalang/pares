package ph.mealpal.server.prices;

/** One ingredient at one store: what a price is for. */
public record PriceKey(String ingredientId, String storeId) {}
