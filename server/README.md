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
kcal multiplied by its servings, its pricePhp (the scaled ingredient cost, rounded once), plus its `ingredients`:

```json
{"slot": "breakfast", "id": "tapsilog", "name": "Tapsilog: ...", "kcal": 840, "pricePhp": 127,
 "image": "tapsilog", "servings": 1.5,
 "ingredients": [{"id": "beef-tapa", "name": "Beef tapa cut", "kind": "meat", "unit": "g",
                  "qty": 225, "pricePhp": 101.25}]}
```

`qty` is the bank's quantity per serving times the servings, in `unit` (`g`,
`ml` or `pc`); `pricePhp` is `qty` times the ingredient's unit price. Both are
rounded to two decimals. `kind` is one of meat, poultry, fish, produce, fruit,
aromatics, grain, egg, legume, oil, condiment, spice, pantry.

The budget check uses the figure the app's grocery list shows: each
ingredient's cost over the whole week, rounded once per ingredient, then added.

The planner agent never sees ingredients: the bank it reads is still id,
slots, name, kcal and pricePhp. The server does the arithmetic from
`src/main/resources/meal-bank.json`, which holds an `ingredients` catalog and,
per meal, the quantity per serving of each ingredient. The bank holds 30
Filipino dishes. A meal's `pricePhp` and `kcal` are both computed from its
ingredients, and the bank refuses to load when either disagrees. Quantities and
unit prices are placeholder estimates until the price checker's price book
exists; the calories are not placeholders (below).

## Where the calories come from

Every ingredient names a USDA FoodData Central food (SR Legacy 2018-04 or
Foundation 2025-04-24). The owner chose USDA because FNRI's PhilFCT site blocks
automated access. Nothing is guessed: each kcal traces to a USDA food id.

Catalog entries keep `name`, `kind`, `unit` and `pricePhpPerUnit` and add:

| Field | Meaning |
| --- | --- |
| `kcalPer100g` | USDA energy for `usda.fdcId`, exactly as published |
| `gramsPerUnit` | grams in one `unit`: 1 for `g`; the weight of one piece for `pc` (a USDA portion); grams per ml for `ml` (portion grams / portion ml, 3 decimals half up) |
| `usda` | `{fdcId, description, match, note}`: the food's id, USDA's own description, `exact` or `closest`; a `closest` match must say in `note` what differs ("USDA has no longganisa; fresh pork sausage") |
| `portion` | required for `pc` and `ml`: `{label, grams}` for pc, `{label, grams, ml}` for ml; the label is one of USDA's portion labels for that food |
| `edible` | optional `{fraction, note}` when part of the bought amount is not eaten (bone-in chicken); `fraction` is above 0 and below 1 and `note` names the USDA figure it comes from. Left out when everything bought is eaten |

Quantities are per serving, raw or dry (rice 90 g is uncooked rice). Produce is
trimmed weight; meat and fish are as bought, with bone taken out through
`edible`. Cooking oil in a recipe counts as eaten.

A meal's kcal is

```
round_half_up( sum( qty * gramsPerUnit * edible.fraction * kcalPer100g / 100 ) )
```

computed with `BigDecimal`, so 436.5 is 437 and nothing drifts. A plan's kcal at
`servings` is still `round(kcal * servings)`. `MealBank` refuses a bank where an
ingredient lacks any of these fields or breaks their rules, or where a meal's
`kcal` is not what its ingredients add up to; the message names the meal or
ingredient. Per-serving bands catch amount typos (a test and the checker both
enforce them): breakfast 300-850, lunch and dinner 350-950, snack 80-450. Where
a USDA food is only the closest, the `note` says which way the figure is off;
saba, for one, is filed as a dessert banana and probably understates.

## USDA tools

`tools/usda/` looks foods up and checks a bank against the USDA data. Run
`tools/usda/fetch.sh` once to download the data (it goes in the gitignored
`tools/usda/data/`), then:

```sh
python3 -I tools/usda/usda.py search chicken breast raw
python3 -I tools/usda/usda.py show 171077
python3 -I tools/usda/check_bank.py src/main/resources/meal-bank.json
```

`check_bank.py` prints one `PROBLEM` line per fault and ends with `OK` or
`FAIL`. See `tools/usda/README.md`.

## Tests

`./gradlew test` (use `./gradlew cleanTest test` to rerun cached results). No Docker needed: the HTTP tests mock the agent gateway.
