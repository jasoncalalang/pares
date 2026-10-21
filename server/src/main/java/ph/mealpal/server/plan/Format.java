package ph.mealpal.server.plan;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.Locale;

/** Numbers the way the app shows them: 2,087 and ₱1,750. */
final class Format {

    private Format() {}

    static String thousands(int n) {
        return NumberFormat.getIntegerInstance(Locale.US).format(n);
    }

    static String peso(int n) {
        return "₱" + thousands(n);
    }

    /** 1.0 reads "1", 1.25 reads "1.25". */
    static String servings(double s) {
        return BigDecimal.valueOf(s).stripTrailingZeros().toPlainString();
    }
}
