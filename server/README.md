# MealPal server

Proof-of-concept API between the MealPal PH app and Claude Managed Agents.
The app never holds an Anthropic credential; this server does.

## How a plan is built

1. `POST /plans` with the person's numbers opens a planner session and answers
   `202` with the plan's id. The calorie target is computed in the app.
2. The planner agent picks dishes from the meal bank and calls the
   `submit_plan` tool. The server re-adds calories and prices from the bank
   (`PlanCheck`) and either accepts the week or sends the problems back.
   After three rejected weeks the plan fails.
3. The app polls `GET /plans/{id}` until `status` is `ready` or `failed`.
   The server keeps no plan state: each read replays the session's events,
   answers any `submit_plan` call still waiting, and works out the status.
   The plan's id is the session id, and the request rides in the session's
   metadata, so any instance can answer and the service can scale to zero.
   The polling is what moves the plan along.
4. `POST /plans/{id}/swaps` sends a swap into the same session and the plan
   builds again; a failed swap keeps the last week.

## Run it

```sh
# 1. Create or update the agent and its environment (from this directory's anthropic/)
cd anthropic
ant apply --dry-run -v agents/meal-planner.md environments/planner.yaml
ant apply agents/meal-planner.md environments/planner.yaml

# 2. Point the server at them and start it
export MEALPAL_AGENT_PLANNER_ID=$(jq -r '.resources["./agents/meal-planner.md"].id' claude-lock.json)
export MEALPAL_AGENT_ENVIRONMENT_ID=$(jq -r '.resources["./environments/planner.yaml"].id' claude-lock.json)
cd .. && ./gradlew quarkusDev
```

Credentials: the Anthropic SDK uses `ANTHROPIC_API_KEY` when it is set,
otherwise the profile from `ant auth login`.

When `MEALPAL_API_APP_KEY` is set, every call needs the header
`X-MealPal-Key` with that value, or it gets `401`. It keeps strangers from
spending the planner budget; it is not a user login.

## Deploy to Cloud Run

`deploy/cloud-run.sh` builds the image with Cloud Build (from `Dockerfile`)
and deploys to `asia-southeast1`, scaling to zero with at most two
instances. The two keys live in Secret Manager; create them by hand first so
neither passes through the script or the shell history:

```sh
gcloud secrets create anthropic-api-key --data-file=-    # paste the key, then Ctrl-D
openssl rand -base64 32 | tr -d '\n' | gcloud secrets create mealpal-app-key --data-file=-

PROJECT=<project id> deploy/cloud-run.sh setup     # once
PROJECT=<project id> deploy/cloud-run.sh deploy    # every release
```

The agent and environment ids come from `anthropic/claude-lock.json`, so run
`ant apply` against the same workspace as the API key.

## API

| Call | Body | Answer |
| --- | --- | --- |
| `POST /plans` | `{"targetKcal": 2087, "budgetPhp": 2000, "goal": "lose", "storeIds": ["palengke"]}` | `202` plan, `400 {problems}`, `503 {message}` |
| `GET /plans/{id}` | | `200` plan, `404` |
| `POST /plans/{id}/swaps` | `{"weekday": "tue", "slot": "lunch", "note": "something cheaper"}` | `202` plan, `400`, `404`, `409` while building |

A plan is `{id, status: building | ready | failed, week, message}`. `week.days`
run Monday first; each meal carries the bank's name, image key, kcal and
pricePhp already multiplied by its servings.

## Tests

`./gradlew test`. No Docker needed: the HTTP tests mock the agent gateway.
