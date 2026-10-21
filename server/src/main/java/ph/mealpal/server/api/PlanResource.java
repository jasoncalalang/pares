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
import java.util.Map;
import java.util.NoSuchElementException;
import ph.mealpal.server.plan.PlanRequest;
import ph.mealpal.server.plan.PlanService;
import ph.mealpal.server.plan.PlannerUnavailable;
import ph.mealpal.server.plan.SwapRequest;

/**
 * The app's API. Building a week takes minutes, so POSTs answer 202 with the
 * plan's id and the app polls GET /plans/{id} until it is ready or failed.
 */
@Path("/plans")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class PlanResource {

    @Inject
    PlanService plans;

    @POST
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
    public Response get(@PathParam("id") String id) {
        return plans.find(id)
                .map(plan -> Response.ok(plan).build())
                .orElseGet(() -> message(Status.NOT_FOUND, "No plan " + id + "."));
    }

    @POST
    @Path("{id}/swaps")
    public Response swap(@PathParam("id") String id, SwapRequest swap) {
        if (plans.find(id).isEmpty()) {
            return message(Status.NOT_FOUND, "No plan " + id + ".");
        }
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
        return Response.status(Status.BAD_REQUEST).entity(Map.of("problems", problems)).build();
    }

    private static Response message(Status status, String message) {
        return Response.status(status).entity(Map.of("message", message)).build();
    }
}
