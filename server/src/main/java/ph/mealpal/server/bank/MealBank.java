package ph.mealpal.server.bank;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/** The vetted dishes a planner may choose from. */
public final class MealBank {

    private record RawIngredient(String name, String kind, String unit, Double pricePhpPerUnit) {}

    private record RawRef(String id, Double qty) {}

    private record RawMeal(String id, List<Slot> slots, String name, int kcal, int pricePhp, String image,
            List<RawRef> ingredients) {}

    private record File(Map<String, RawIngredient> ingredients, List<RawMeal> meals) {}

    private static final ObjectMapper JSON = new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

    private final List<Meal> meals;
    private final Map<String, Meal> byId;
    private final Map<String, Ingredient> catalog;

    private MealBank(List<Meal> meals, Map<String, Ingredient> catalog) {
        this.meals = List.copyOf(meals);
        this.byId = meals.stream().collect(Collectors.toUnmodifiableMap(Meal::id, Function.identity()));
        this.catalog = Map.copyOf(catalog);
    }

    public static MealBank fromClasspath(String resource) {
        try (InputStream in = MealBank.class.getClassLoader().getResourceAsStream(resource)) {
            if (in == null) {
                throw new IllegalStateException("No meal bank at classpath:" + resource);
            }
            return build(JSON.readValue(in, File.class));
        } catch (IOException e) {
            throw new UncheckedIOException("Could not read the meal bank " + resource, e);
        }
    }

    /** Reads a bank from JSON text; refuses it with an IllegalStateException that names what is wrong. */
    public static MealBank fromJson(String json) {
        try {
            return build(JSON.readValue(json, File.class));
        } catch (IOException e) {
            throw new UncheckedIOException("Could not read the meal bank", e);
        }
    }

    private static MealBank build(File file) {
        Map<String, Ingredient> catalog = new LinkedHashMap<>();
        if (file.ingredients() != null) {
            file.ingredients().forEach((id, raw) -> catalog.put(id, ingredient(id, raw)));
        }
        List<Meal> meals = new ArrayList<>();
        for (RawMeal raw : file.meals()) {
            meals.add(meal(raw, catalog));
        }
        return new MealBank(meals, catalog);
    }

    private static Ingredient ingredient(String id, RawIngredient raw) {
        Ingredient.Kind kind = raw == null ? null : Ingredient.Kind.parse(raw.kind());
        if (kind == null) {
            throw new IllegalStateException("Ingredient '" + id + "' has an unknown kind '"
                    + (raw == null ? null : raw.kind()) + "'.");
        }
        Ingredient.Unit unit = Ingredient.Unit.parse(raw.unit());
        if (unit == null) {
            throw new IllegalStateException("Ingredient '" + id + "' has an unknown unit '" + raw.unit()
                    + "' (use g, ml or pc).");
        }
        if (raw.pricePhpPerUnit() == null || raw.pricePhpPerUnit() < 0) {
            throw new IllegalStateException("Ingredient '" + id + "' needs a pricePhpPerUnit of zero or more.");
        }
        return new Ingredient(id, raw.name(), kind, unit, raw.pricePhpPerUnit());
    }

    private static Meal meal(RawMeal raw, Map<String, Ingredient> catalog) {
        if (raw.ingredients() == null || raw.ingredients().isEmpty()) {
            throw new IllegalStateException("Meal '" + raw.id() + "' has no ingredients.");
        }
        List<MealIngredient> refs = new ArrayList<>();
        BigDecimal cost = BigDecimal.ZERO;
        for (RawRef ref : raw.ingredients()) {
            Ingredient ingredient = ref.id() == null ? null : catalog.get(ref.id());
            if (ingredient == null) {
                throw new IllegalStateException("Meal '" + raw.id() + "' uses unknown ingredient '" + ref.id() + "'.");
            }
            if (ref.qty() == null || !(ref.qty() > 0)) {
                throw new IllegalStateException("Meal '" + raw.id() + "' has a quantity of " + ref.qty()
                        + " for ingredient '" + ref.id() + "'; a quantity must be more than zero.");
            }
            refs.add(new MealIngredient(ref.id(), ref.qty()));
            cost = cost.add(BigDecimal.valueOf(ref.qty()).multiply(BigDecimal.valueOf(ingredient.pricePhpPerUnit())));
        }
        int expected = cost.setScale(0, RoundingMode.HALF_UP).intValueExact();
        if (expected != raw.pricePhp()) {
            throw new IllegalStateException("Meal '" + raw.id() + "' has pricePhp " + raw.pricePhp()
                    + " but its ingredients cost " + expected + " (" + cost.stripTrailingZeros().toPlainString()
                    + " before rounding).");
        }
        return new Meal(raw.id(), raw.slots(), raw.name(), raw.kcal(), raw.pricePhp(), raw.image(), List.copyOf(refs));
    }

    public List<Meal> meals() {
        return meals;
    }

    public Optional<Ingredient> ingredient(String id) {
        return Optional.ofNullable(catalog.get(id));
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
            fields.put("slots", meal.slots().stream().map(Slot::json).toList());
            fields.put("name", meal.name());
            fields.put("kcal", meal.kcal());
            fields.put("pricePhp", meal.pricePhp());
            return JSON.writeValueAsString(fields);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
