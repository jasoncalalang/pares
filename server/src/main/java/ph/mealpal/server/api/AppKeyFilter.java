package ph.mealpal.server.api;

import jakarta.inject.Inject;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.Optional;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Every call must carry the app's key in X-MealPal-Key, so a stranger who
 * finds the URL cannot start sessions on the account. It ships inside the
 * app, so it slows abuse rather than stopping it; the workspace spend limit
 * is the hard stop. With no key configured (local dev) nothing is checked.
 */
@Provider
public class AppKeyFilter implements ContainerRequestFilter {

    static final String HEADER = "X-MealPal-Key";

    @Inject
    @ConfigProperty(name = "mealpal.api.app-key")
    Optional<String> appKey;

    @Override
    public void filter(ContainerRequestContext request) {
        if (appKey.isEmpty() || appKey.get().isBlank()) {
            return;
        }
        String sent = request.getHeaderString(HEADER);
        if (sent == null || !MessageDigest.isEqual(
                sent.getBytes(StandardCharsets.UTF_8), appKey.get().getBytes(StandardCharsets.UTF_8))) {
            request.abortWith(Response.status(Response.Status.UNAUTHORIZED)
                    .type(MediaType.APPLICATION_JSON)
                    .entity(Map.of("message", "Missing or wrong " + HEADER + "."))
                    .build());
        }
    }
}
