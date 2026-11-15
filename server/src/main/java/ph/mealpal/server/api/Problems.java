package ph.mealpal.server.api;

import java.util.List;
import org.eclipse.microprofile.openapi.annotations.media.Schema;

/** A 400: everything wrong with the request, in words the app can show. */
@Schema(requiredProperties = {"problems"})
public record Problems(List<String> problems) {}
