package ph.mealpal.server;

import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import ph.mealpal.server.agent.AgentGateway;
import ph.mealpal.server.bank.MealBank;
import ph.mealpal.server.plan.PlanBriefs;
import ph.mealpal.server.plan.PlanCheck;
import ph.mealpal.server.plan.PlanService;

/** Wires the plain domain classes into CDI. */
public class Beans {

    @Produces
    @Singleton
    MealBank mealBank() {
        return MealBank.fromClasspath("meal-bank.json");
    }

    @Produces
    @Singleton
    PlanService planService(AgentGateway gateway, MealBank bank) {
        return new PlanService(gateway, new PlanCheck(bank), new PlanBriefs(bank));
    }
}
