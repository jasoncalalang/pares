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

/** The vetted dishes a planner may choose from. A meal's kcal and price are checked against its ingredients at load. */
public final class MealBank {

    private record RawUsda(Integer fdcId, String description, String match, String note) {}

    private record RawPortion(String label, BigDecimal grams, BigDecimal ml) {}

    private record RawEdible(BigDecimal fraction, String note) {}

    private record RawIngredient(String name, String kind, String unit, Double pricePhpPerUnit,
            BigDecimal kcalPer100g, BigDecimal gramsPerUnit, RawUsda usda, RawPortion portion, RawEdible edible) {}

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
        Ingredient.Usda usda = usda(id, raw.usda());
        if (raw.kcalPer100g() == null || raw.kcalPer100g().signum() <= 0) {
            throw new IllegalStateException("Ingredient '" + id + "' needs a kcalPer100g of more than zero (USDA's energy for "
                    + usda.fdcId() + ").");
        }
        if (raw.gramsPerUnit() == null || raw.gramsPerUnit().signum() <= 0) {
            throw new IllegalStateException("Ingredient '" + id + "' needs a gramsPerUnit of more than zero.");
        }
        if (unit == Ingredient.Unit.G && raw.gramsPerUnit().compareTo(BigDecimal.ONE) != 0) {
            throw new IllegalStateException("Ingredient '" + id + "' is sold by the gram, so its gramsPerUnit must be 1, not "
                    + raw.gramsPerUnit().toPlainString() + ".");
        }
        Ingredient.Portion portion = portion(id, unit, raw);
        Ingredient.Edible edible = edible(id, raw.edible());
        return new Ingredient(id, raw.name(), kind, unit, raw.pricePhpPerUnit(), raw.kcalPer100g(), raw.gramsPerUnit(),
                usda, portion, edible);
    }

    private static Ingredient.Usda usda(String id, RawUsda raw) {
        if (raw == null) {
            throw new IllegalStateException("Ingredient '" + id + "' needs a usda source: {fdcId, description, match}.");
        }
        if (raw.fdcId() == null || raw.fdcId() <= 0) {
            throw new IllegalStateException("Ingredient '" + id + "' needs a usda.fdcId, a positive USDA food id.");
        }
        if (isBlank(raw.description())) {
            throw new IllegalStateException("Ingredient '" + id + "' needs the usda.description of food " + raw.fdcId() + ".");
        }
        if (!"exact".equals(raw.match()) && !"closest".equals(raw.match())) {
            throw new IllegalStateException("Ingredient '" + id + "' has usda.match '" + raw.match()
                    + "' (use exact or closest).");
        }
        if ("closest".equals(raw.match()) && isBlank(raw.note())) {
            throw new IllegalStateException("Ingredient '" + id
                    + "' is a closest USDA match, so usda.note must say what differs.");
        }
        return new Ingredient.Usda(raw.fdcId(), raw.description(), raw.match(), raw.note());
    }

    private static Ingredient.Portion portion(String id, Ingredient.Unit unit, RawIngredient raw) {
        RawPortion p = raw.portion();
        if (unit == Ingredient.Unit.G) {
            return p == null ? null : new Ingredient.Portion(p.label(), p.grams(), p.ml());
        }
        if (p == null) {
            throw new IllegalStateException("Ingredient '" + id + "' is sold by the " + unit.json()
                    + ", so it needs a USDA portion: {label, grams" + (unit == Ingredient.Unit.ML ? ", ml" : "") + "}.");
        }
        if (isBlank(p.label())) {
            throw new IllegalStateException("Ingredient '" + id + "' needs the portion.label of the USDA portion it uses.");
        }
        if (p.grams() == null || p.grams().signum() <= 0) {
            throw new IllegalStateException("Ingredient '" + id + "' needs a portion.grams of more than zero.");
        }
        if (unit == Ingredient.Unit.PC) {
            if (raw.gramsPerUnit().compareTo(p.grams()) != 0) {
                throw new IllegalStateException("Ingredient '" + id + "' has gramsPerUnit " + raw.gramsPerUnit().toPlainString()
                        + " but its portion weighs " + p.grams().toPlainString() + " g; one piece is that portion.");
            }
        } else {
            if (p.ml() == null || p.ml().signum() <= 0) {
                throw new IllegalStateException("Ingredient '" + id + "' is sold by the ml, so its portion needs a portion.ml"
                        + " of more than zero.");
            }
            BigDecimal perMl = p.grams().divide(p.ml(), 3, RoundingMode.HALF_UP);
            if (raw.gramsPerUnit().compareTo(perMl) != 0) {
                throw new IllegalStateException("Ingredient '" + id + "' has gramsPerUnit " + raw.gramsPerUnit().toPlainString()
                        + " but portion.grams / portion.ml is " + perMl.toPlainString() + " g per ml.");
            }
        }
        return new Ingredient.Portion(p.label(), p.grams(), p.ml());
    }

    private static Ingredient.Edible edible(String id, RawEdible raw) {
        if (raw == null) {
            return null;
        }
        if (raw.fraction() == null || raw.fraction().signum() <= 0 || raw.fraction().compareTo(BigDecimal.ONE) >= 0) {
            throw new IllegalStateException("Ingredient '" + id + "' has an edible.fraction of "
                    + (raw.fraction() == null ? null : raw.fraction().toPlainString())
                    + "; it must be more than 0 and less than 1 (leave edible out when all of it is eaten).");
        }
        if (isBlank(raw.note())) {
            throw new IllegalStateException("Ingredient '" + id + "' needs an edible.note saying where the fraction comes from.");
        }
        return new Ingredient.Edible(raw.fraction(), raw.note());
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private static Meal meal(RawMeal raw, Map<String, Ingredient> catalog) {
        if (raw.ingredients() == null || raw.ingredients().isEmpty()) {
            throw new IllegalStateException("Meal '" + raw.id() + "' has no ingredients.");
        }
        List<MealIngredient> refs = new ArrayList<>();
        BigDecimal cost = BigDecimal.ZERO;
        BigDecimal kcal = BigDecimal.ZERO;
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
            BigDecimal qty = BigDecimal.valueOf(ref.qty());
            cost = cost.add(qty.multiply(BigDecimal.valueOf(ingredient.pricePhpPerUnit())));
            kcal = kcal.add(kcalOf(qty, ingredient));
        }
        int expected = cost.setScale(0, RoundingMode.HALF_UP).intValueExact();
        if (expected != raw.pricePhp()) {
            throw new IllegalStateException("Meal '" + raw.id() + "' has pricePhp " + raw.pricePhp()
                    + " but its ingredients cost " + expected + " (" + cost.stripTrailingZeros().toPlainString()
                    + " before rounding).");
        }
        int expectedKcal = kcal.setScale(0, RoundingMode.HALF_UP).intValueExact();
        if (expectedKcal != raw.kcal()) {
            throw new IllegalStateException("Meal '" + raw.id() + "' has kcal " + raw.kcal()
                    + " but its ingredients add up to " + expectedKcal + " (" + kcal.stripTrailingZeros().toPlainString()
                    + " before rounding).");
        }
        return new Meal(raw.id(), raw.slots(), raw.name(), raw.kcal(), raw.pricePhp(), raw.image(), List.copyOf(refs));
    }

    /** USDA kcal for {@code qty} of an ingredient as bought: grams eaten times kcal per 100 g, exactly. */
    private static BigDecimal kcalOf(BigDecimal qty, Ingredient ingredient) {
        BigDecimal eaten = qty.multiply(ingredient.gramsPerUnit());
        if (ingredient.edible() != null) {
            eaten = eaten.multiply(ingredient.edible().fraction());
        }
        return eaten.multiply(ingredient.kcalPer100g()).movePointLeft(2);
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
