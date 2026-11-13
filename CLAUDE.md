# mealpal_ph: MealPal PH

Flutter app (Android + iOS) for the Philippine market: welcome → body
stats → daily calorie target → stores + ₱ budget → Filipino meal plan →
grocery list.
Warm, editorial, grounded: a Filipino food magazine, not a clinical
tracker. GitHub repo is `jasoncalalang/pares`; the product name stays
MealPal PH.

## Working rules

- **TDD, always.** Failing test first, watch it fail, then implement.
- Run tools with `~/development/flutter/bin/flutter` (`test` / `analyze`).
  `flutter analyze` must stay at zero issues. Never commit red.
- Domain core under `lib/src/` is **pure Dart** (no Flutter import) and its
  tests use `package:test`; app code uses `flutter_test`. Both run under
  `flutter test`.
- No AI attribution in commits or PRs.

## Layout

- `lib/src/`: domain: `nutrition/` (Mifflin–St Jeor target, macro split),
  `plan/` (meal slots, day plans, grocery lists), `stores/` (PH catalog incl.
  palengke + sari-sari), `locale/` (peso + thousands formatting).
  Exported through `lib/mealpal_ph.dart`.
- `lib/design_system/`: tokens + theme (pinned by `test/design_system/`).
- `lib/widgets/<core|forms|data>/`: components; barrel `widgets.dart`.
- `lib/screens/`: the six screens (Welcome, then the four steps, then the
  grocery list). Every screen has an on-screen way back: the fade routes
  have no iOS edge swipe.
- `lib/src/plan/planner.dart`: the `Planner` interface, `PlanBrief`,
  `PlanSnapshot`, `PlanStatus` and `PlannerException`. `plan_json.dart` reads
  the server's plan record; `http_planner.dart` is the `Planner` over the
  server's HTTP API (package:http, tested with `MockClient`).
- `lib/state/plan_draft.dart`: one `ChangeNotifier` for the whole flow;
  `brief` is what the planner is asked for. `week_plan_controller.dart`
  drives a `Planner`: builds, polls, swaps, retries. The This week screen
  only reads it.
- `lib/data/`: the offline sample bank (`sample_bank.dart`, a copy of
  `server/src/main/resources/meal-bank.json`: meals, ingredient catalog,
  ingredient refs), the sample week built from it (some dishes at 0.75 servings, so every day is within 3% of the default 2,087 kcal target; `sample_week_test.dart` holds it), store tiles and
  `shopping_stops.dart` (picked store ids to `ShoppingStop`s, in Where you
  shop order). `test/data/bank_parity_test.dart` fails if the Dart bank and
  the JSON differ, so the two copies cannot drift: edit both together. The
  Dart copy keeps only what the app reads (no USDA provenance); the 20
  dishes after the first ten are offered by the offline swap at every slot
  they list, in bank order. `nextAlternative` drives the offline meal swap.
  `sample_planner.dart` is the `Planner` used when no server is configured.
- `lib/app.dart` picks the planner (`plannerFor`, https-only in release) and
  owns the controller.
  The grocery route rebuilds from the controller's current week and the
  draft's picked stores (`ListenableBuilder`), so a swap changes the list in
  sample and server mode alike. The Welcome collage stays on
  `sampleWeek().first`.
- `lib/src/plan/grocery.dart`: `groceryListFor` sums every planned meal's
  ingredients by id across the week, rounds the amounts up, and files each
  line under a picked store. Ingredient unit prices live in the bank; that
  is where the price checker's price book will plug in later.
- `test/` mirrors `lib/`; `test/helpers.dart` has `host()`, `phone()`,
  `contrast()` and `paintedColor()`. `test/flutter_test_config.dart` loads
  the real Fraunces and Plus Jakarta Sans for every test, so widths and
  wrapping match a phone (the default test font is a full em per glyph).

## Design system (lib/design_system/)

Direction lives in `DESIGN.md` (identity, palette, type, motion, dials, and
the reasons); read it before any UI work, then apply the antislop rules as
the filter. The tokens mirror the approved Superdesign mockups, on the white
paper ground the owner chose on 2026-11-13. **Never hard-code a colour, size,
radius, duration or font family**: read:

- `MpColors` (ThemeExtension, `context.mp`): white `paper` ground, ink,
  annatto primary, green secondary, amber, tints, hero surface. `hairline`
  is for decorative card borders only; every interactive control draws its
  boundary with `outline` (3:1 on the white page). `faint` and `amber`
  were darkened so 11-12px labels clear 4.5:1.
  `MpAccent` (annatto | green | amber) picks a family: chains/CTAs/meals =
  annatto, local stores/budget/protein = green, snack/fat = amber.
- `MpTypography`: Fraunces for headings, hero numbers, wordmark and
  monograms; Plus Jakarta Sans for everything else. Both are variable fonts;
  styles set `fontVariations` so weights actually move the axis.
- `MpSpacing` / `MpRadius` / `MpSize` / `MpStroke`.
- `MpMotion`: press 0.97/120ms, select 250ms, reveal 850ms, expand 350ms,
  `ease = Cubic(.2,.7,.3,1)`. There is deliberately NO page-load entrance
  animation (dial MOTION 2: motion only where it carries information or
  feedback). Always read durations through `MpMotion.of(context, …)` so
  `disableAnimations` collapses them.
- `MpTheme.light()`: the only theme (the brand surface is white paper).
  Do not tint the ground: cream was dropped as a generic look (DESIGN.md).

## Brand rules

- UI copy is English; Filipino dish names are proper nouns (Tapsilog,
  Tinola, Ginisang munggo). Gender field is "Gender" (Male/Female).
- Metric only (kg, cm); currency is ₱ via `formatPeso`.
- Icons: Lucide stroke icons only. No emoji. No retailer logos: monograms.
- Motion: data fills, selection, press, expand, screen fades; no entrance
  animation, nothing bouncy, no gradients, no parallax, no endless loops.
- Calorie target is deterministic math; the model only selects from the
  meal bank and never invents nutrition numbers.
- A meal's kcal is computed, never typed: round_half_up(sum(qty *
  gramsPerUnit * edible fraction * kcalPer100g / 100)) from USDA FoodData
  Central (SR Legacy and Foundation) energy per ingredient, each with its
  `usda.fdcId`. FNRI's PhilFCT blocks automated access, so USDA is the
  source. The lookup and check tools are in `server/tools/usda/` (see its
  README and `server/README.md`); `bank_parity_test.dart` recomputes every
  meal's kcal from the JSON so the app suite guards the rule too. Add a dish
  by adding USDA-backed ingredients, then run `check_bank.py`.

## antislop (applied 2026-10-21, mode DURING)

The design is filtered with the antislop rules; keep it that way:

- No em dashes anywhere (UI copy, comments, tests). Use a comma, colon or
  a new sentence.
- No generic CTAs ("Get started", "Learn more"). Every button names its
  action: "Compute my target", "Build my plan (n)", "See grocery list".
- Every control does something real, or it does not exist. A placeholder
  needs a `// TODO(...)` in code AND a visible "coming soon" line in the UI
  (the GrabMart handoff; the Welcome sign-in buttons).
- Data screens carry their states: This week has building/failed, the
  grocery list has an empty state, CTAs disable with a helper line when
  inputs are missing.
- `MpPress` is the only tap primitive: it is keyboard-operable (Enter/Space),
  paints a 2px annatto focus ring 2px OUTSIDE the control (so it shows on
  an annatto fill or an accent border; don't put one inside a clipping
  parent), announces disabled, and carries `selected` / `expanded` for
  screen readers. Never reach for a bare `GestureDetector` for something
  a person taps.
- Screen readers hear each thing once: decorative text (monograms, the
  visible label of a field that names itself) is excluded; choices, store
  tiles and days say whether they are selected.
- Tap targets are 44px or larger (`MpSize.tap`); pill buttons, header back
  links and grocery section headers reserve it.
- Large text (150-200%, iOS up to 310%) must not overflow or break a word
  in two: numbers and one-word labels shrink to fit, CTAs wrap and grow,
  the store grid shrinks names (to 80%) or drops to one column, a meal card
  drops its thumbnail from 150% so dish names keep their width and shrinks
  a name (to 60%) only when its longest word still does not fit, dish names
  carry no hyphenated compounds (a line breaks after a hyphen), and a
  pinned footer scrolls past half the screen. `large_text_test.dart`
  checks it, meal names at every common step from 1x to 3.1x on 320dp and
  360dp in the real page frame.
- Contrast is checked, not eyeballed: text 4.5:1, control edges 3:1
  (`outline`), via the antislop contrast script or `contrast()` in tests.
  Dim with the `faint` token, never with opacity.
- Numbers on screen are the math's, not the goal's: when the target is
  raised to the safe floor, Daily target shows the real change from
  maintenance and drops the weekly-rate claim.
- This week labels its numbers: "Calories and prices are rough estimates
  for now." sits under the day line in sample and server mode alike (a
  meal's kcal is computed from USDA data, but the recipe amounts are
  estimates and the prices are placeholders). Remove it only with the
  `TODO(meal-bank)` once the amounts and prices are checked. A
  target capped for the planner reads "(planner max)" in its pill.
  Owner override (2026-11-02): the Welcome collage keeps its kcal and
  price stickers unlabelled; they illustrate the example day, not a claim.
  Do not hard-code the sticker price in copy or tests: read it from
  `sampleWeek().first`.
- One grocery CTA on This week: the pinned "See grocery list" footer. Do
  not bring back a second entry (the old title-row pill).
- The calorie ring's centre shows the target as a share of maintenance
  (`81%` over `OF MAINTENANCE`, the math's real ratio, not clamped; only
  the arc fill is clamped). It must not repeat the target, which the hero
  number beside it already states: the target appears once on Daily target.
- Step eyebrows carry the same left arrow as `MpBackHeader` when they go
  back, so the link looks tappable. The button announces "Back"; the step
  is heard once, from the progress segments. Back headers announce "Back to
  <label>".
- The grocery list labels its numbers in every mode (`groceryListNote`):
  "Amounts are what your meals use. Prices are rough estimates for now."
  Remove the price half only once the price checker's price book feeds the
  unit prices.
- Store assignment: each ingredient kind has an ordered list of store types
  that sell it, and the first picked stop of a listed type gets it (fresh
  kinds: wet market, supermarket, hypermarket, warehouse club, online;
  aromatics may also use a sari-sari store; eggs and pantry kinds have
  longer lists). A type not in a kind's list never gets that kind, so a
  sari-sari store never gets fresh meat. Items no picked stop sells go to a
  last "Elsewhere" section ("(not sold at the stores you picked)"); that
  is honest, never a guess. Fresh tofu and grated coconut are kind
  `produce` for that reason.
- One money story: a meal's price is its scaled ingredient cost rounded
  once, and the server checks the budget against the grocery list's own
  figure (each ingredient's week cost rounded once, then added), so a week
  the server accepts never shows "over budget" on the list. Ticks and
  collapsed sections on the list are keyed by store and ingredient id, not
  position, because a swap can land while it is open. Meals that arrive
  with no ingredients (an older server) get their own state, not "Nothing
  to buy yet". At large text the store header and row prices move under
  the name so no word breaks.
- Screen-reader merges: a meal card is one live node ("Breakfast, Tapsilog,
  797 kcal, ₱84"; the swap button stays its own), a macro card is one node
  ("Protein, 157 grams") with its gauge excluded, and the ring centre is
  one sentence. `MpCta` takes a `semanticLabel` when the visible text is
  not the spoken one ("Build my plan from 2 stores").
- The selected day name uses the `heroMuted` token, never opacity.
- `HttpPlanner` maps only `Exception`s to a network error; an `Error` is a
  bug and propagates.
- Uppercase kickers, Lucide glyphs, the selection halo and the two shadows
  are deliberate and written up in the design-system doc; do not add more
  decoration without writing the reason down.

## Run against the server

Without a server the app plans from the local sample bank, so tests, the web
preview and the CI APK need nothing. To have the server build the week, start
it as `server/README.md` says, then pass its URL (and the app key, if the
server has one) at build time:

```
~/development/flutter/bin/flutter run \
  --dart-define=MEALPAL_SERVER_URL=http://192.168.42.202:8090 \
  --dart-define=MEALPAL_APP_KEY=<key>
```

Android: the main manifest has INTERNET. The app's HTTP goes through dart:io
sockets, which Android's `usesCleartextTraffic` and iOS App Transport
Security do not gate, so neither is set. The only guard is `plannerFor` in
`lib/app.dart`: a release build throws on a server URL that is not https
(Cloud Run). Debug and profile builds accept an http LAN URL on both
platforms.

## Preview

`web/` is gitignored and exists only for `flutter run -d web-server
--web-port 8777` (or `-d chrome`) to eyeball screens at 390×844.
