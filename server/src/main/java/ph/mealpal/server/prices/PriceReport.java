package ph.mealpal.server.prices;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.List;

/**
 * The price checker's prices.json, read leniently: the file must be a JSON object with a
 * {@code prices} list, but each line is kept as written so that one bad line is rejected on its own
 * instead of sinking the run.
 */
public record PriceReport(List<JsonNode> prices) {

    private static final ObjectMapper JSON = new ObjectMapper();

    public static PriceReport parse(String json) {
        JsonNode root;
        try {
            root = JSON.readTree(json);
        } catch (JsonProcessingException e) {
            throw new IllegalArgumentException("The price report is not JSON: " + e.getOriginalMessage(), e);
        }
        if (root == null || !root.isObject()) {
            throw new IllegalArgumentException("The price report must be a JSON object.");
        }
        JsonNode prices = root.get("prices");
        if (prices == null || !prices.isArray()) {
            throw new IllegalArgumentException("prices must be a list.");
        }
        List<JsonNode> lines = new ArrayList<>();
        prices.forEach(lines::add);
        return new PriceReport(List.copyOf(lines));
    }
}
