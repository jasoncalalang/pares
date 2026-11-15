package ph.mealpal.server.api;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
import org.eclipse.microprofile.openapi.annotations.enums.SecuritySchemeIn;
import org.eclipse.microprofile.openapi.annotations.enums.SecuritySchemeType;
import org.eclipse.microprofile.openapi.annotations.Operation;
import org.eclipse.microprofile.openapi.annotations.media.Content;
import org.eclipse.microprofile.openapi.annotations.media.Schema;
import org.eclipse.microprofile.openapi.annotations.responses.APIResponse;
import org.eclipse.microprofile.openapi.annotations.security.SecurityRequirement;
import org.eclipse.microprofile.openapi.annotations.security.SecurityScheme;
import org.eclipse.microprofile.openapi.annotations.tags.Tag;
import ph.mealpal.server.plan.PlanRecord;
import ph.mealpal.server.plan.PlanRequest;
import ph.mealpal.server.plan.PlanService;
import ph.mealpal.server.plan.PlannerUnavailable;
import ph.mealpal.server.plan.SwapRequest;

/**
 * The app's API. POSTs answer 202 with the plan's id; the app polls
 * GET /v1/plans/{id}, and each poll moves the planner along, until the plan
 * is ready or failed.
 *
 * Installed apps cannot be made to update, so the version is in the path: a
 * change an older app cannot read goes under /v2 while /v1 keeps answering.
 * The annotations feed server/openapi.json; OpenApiContractTest holds them to
 * what the methods really answer.
 */
@Path("/v1/plans")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
@SecurityScheme(securitySchemeName = "appKey", type = SecuritySchemeType.APIKEY, in = SecuritySchemeIn.HEADER,
        apiKeyName = AppKeyFilter.HEADER, description = "The app's key. Unchecked when the server has none set.")
@SecurityRequirement(name = "appKey")
@Tag(name = "Plans")
@APIResponse(responseCode = "401", description = "Missing or wrong app key.",
        content = @Content(mediaType = MediaType.APPLICATION_JSON, schema = @Schema(implementation = Message.class)))
public class PlanResource {

    @Inject
    PlanService plans;

    @POST
    @Operation(summary = "Start a plan",
            description = "Opens a planner session for the person's numbers. The calorie target is the app's.")
    @APIResponse(responseCode = "202", description = "The plan is building; poll it by id.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = PlanRecord.class)))
    @APIResponse(responseCode = "400", description = "The request is incomplete or out of range.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = Problems.class)))
    @APIResponse(responseCode = "503", description = "The planner could not be reached; nothing was started.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = Message.class)))
    public Response create(PlanRequest request) {
        if (request == null) {
            return problems(List.of("Send the plan request as JSON."));
        }
        List<String> problems = request.problems();
        if (!problems.isEmpty()) {
            return problems(problems);
        }
        try {
            return Response.accepted(plans.create(request)).build();
        } catch (PlannerUnavailable e) {
            return message(Status.SERVICE_UNAVAILABLE, e.getMessage());
        }
    }

    @GET
    @Path("{id}")
    @Operation(summary = "Read a plan")
    @APIResponse(responseCode = "200", description = "Where the plan stands. Reading it moves the planner along.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = PlanRecord.class)))
    @APIResponse(responseCode = "404", description = "No such plan.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = Message.class)))
    public Response get(@PathParam("id") String id) {
        return plans.find(id)
                .map(plan -> Response.ok(plan).build())
                .orElseGet(() -> message(Status.NOT_FOUND, "No plan " + id + "."));
    }

    @POST
    @Path("{id}/swaps")
    @Operation(summary = "Swap a meal",
            description = "Asks for a different dish at one day and slot, with an optional note.")
    @APIResponse(responseCode = "202", description = "The swap is building; poll the plan. The last week stays.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = PlanRecord.class)))
    @APIResponse(responseCode = "400", description = "The day or the slot is missing.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = Problems.class)))
    @APIResponse(responseCode = "404", description = "No such plan.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = Message.class)))
    @APIResponse(responseCode = "409", description = "The week is still building.",
            content = @Content(mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = Message.class)))
    public Response swap(@PathParam("id") String id, SwapRequest swap) {
        List<String> problems = new ArrayList<>();
        if (swap == null || swap.weekday() == null) {
            problems.add("weekday is required: mon to sun.");
        }
        if (swap == null || swap.slot() == null) {
            problems.add("slot is required: breakfast, lunch, dinner or snack.");
        }
        if (!problems.isEmpty()) {
            return problems(problems);
        }
        try {
            return Response.accepted(plans.swap(id, swap)).build();
        } catch (NoSuchElementException e) {
            return message(Status.NOT_FOUND, "No plan " + id + ".");
        } catch (IllegalStateException e) {
            return message(Status.CONFLICT, e.getMessage());
        }
    }

    private static Response problems(List<String> problems) {
        return Response.status(Status.BAD_REQUEST).entity(new Problems(problems)).build();
    }

    private static Response message(Status status, String message) {
        return Response.status(status).entity(new Message(message)).build();
    }
}
