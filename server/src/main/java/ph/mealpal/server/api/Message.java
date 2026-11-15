package ph.mealpal.server.api;

import org.eclipse.microprofile.openapi.annotations.media.Schema;

/** Any other refusal: one sentence the app can show. */
@Schema(requiredProperties = {"message"})
public record Message(String message) {}
