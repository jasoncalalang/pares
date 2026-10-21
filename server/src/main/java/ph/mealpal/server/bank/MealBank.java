package ph.mealpal.server.bank;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/** The vetted dishes a planner may choose from. */
public final class MealBank {

    private record File(List<Meal> meals) {}

    private static final ObjectMapper JSON = new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

    private final List<Meal> meals;
    private final Map<String, Meal> byId;

    private MealBank(List<Meal> meals) {
        this.meals = List.copyOf(meals);
        this.byId = meals.stream().collect(Collectors.toUnmodifiableMap(Meal::id, Function.identity()));
    }

    public static MealBank fromClasspath(String resource) {
        try (InputStream in = MealBank.class.getClassLoader().getResourceAsStream(resource)) {
            if (in == null) {
                throw new IllegalStateException("No meal bank at classpath:" + resource);
            }
            return new MealBank(JSON.readValue(in, File.class).meals());
        } catch (IOException e) {
            throw new UncheckedIOException("Could not read the meal bank " + resource, e);
        }
    }

    public List<Meal> meals() {
        return meals;
    }

    public Optional<Meal> find(String id) {
        return Optional.ofNullable(byId.get(id));
    }

    /** One compact JSON object per line: how the agent reads the bank. */
    public String asJsonLines() {
        return meals.stream().map(MealBank::line).collect(Collectors.joining("\n"));
    }

    private static String line(Meal meal) {
        try {
            // Fixed key order, so the same bank always reads the same way.
            Map<String, Object> fields = new LinkedHashMap<>();
            fields.put("id", meal.id());
            fields.put("slot", meal.slot().json());
            fields.put("name", meal.name());
            fields.put("kcal", meal.kcal());
            fields.put("pricePhp", meal.pricePhp());
            return JSON.writeValueAsString(fields);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
