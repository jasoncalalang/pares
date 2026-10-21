# mealpal_ph: MealPal PH

Flutter app (Android + iOS) for the Philippine market: body stats → daily
calorie target → stores + ₱ budget → Filipino meal plan → grocery list.
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
- `lib/screens/`: the five screens.
- `lib/state/plan_draft.dart`: one `ChangeNotifier` for the whole flow.
- `lib/data/`: sample week / grocery list / store tiles (stand-ins for the
  meal bank + AI recommender). `nextAlternative` drives the meal swap.
- `test/` mirrors `lib/`; `test/helpers.dart` has `host()` and `phone()`.

## Design system (lib/design_system/)

Mirrors the approved Superdesign mockups. **Never hard-code a colour, size,
radius, duration or font family**: read:

- `MpColors` (ThemeExtension, `context.mp`): cream ground `#FCF8EF`, ink,
  annatto primary, green secondary, amber, tints, hero surface. `hairline`
  is for decorative card borders only; every interactive control draws its
  boundary with `outline` (3:1 on cream and white). `faint` and `amber`
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
- `MpTheme.light()`: the only theme (the brand surface is cream paper).

## Brand rules

- UI copy is English; Filipino dish names are proper nouns (Tapsilog,
  Tinola, Ginisang munggo). Gender field is "Gender" (Male/Female).
- Metric only (kg, cm); currency is ₱ via `formatPeso`.
- Icons: Lucide stroke icons only. No emoji. No retailer logos: monograms.
- Motion: data fills, selection, press, expand, screen fades; no entrance
  animation, nothing bouncy, no gradients, no parallax, no endless loops.
- Calorie target is deterministic math; the model (later) only selects
  from the meal bank and never invents nutrition numbers.

## antislop (applied 2026-10-21, mode DURING)

The design is filtered with the antislop rules; keep it that way:

- No em dashes anywhere (UI copy, comments, tests). Use a comma, colon or
  a new sentence.
- No generic CTAs ("Get started", "Learn more"). Every button names its
  action: "Compute my target", "Build my plan (n)", "See grocery list".
- Every control does something real, or it does not exist. A placeholder
  needs a `// TODO(...)` in code AND a visible "coming soon" line in the UI
  (the GrabMart handoff is the one example).
- Data screens carry their states: This week has building/failed, the
  grocery list has an empty state, CTAs disable with a helper line when
  inputs are missing.
- `MpPress` is the only tap primitive: it is keyboard-operable (Enter/Space),
  paints a 2px annatto focus ring, and announces disabled. Never reach for a
  bare `GestureDetector` for something a person taps.
- Tap targets are 44px or larger (`MpSize.tap`); pill buttons reserve it.
- Contrast is checked, not eyeballed: text 4.5:1, control edges 3:1
  (`outline`), via the antislop contrast script.
- Uppercase kickers, Lucide glyphs, the selection halo and the two shadows
  are deliberate and written up in the design-system doc; do not add more
  decoration without writing the reason down.

## Preview

`web/` is gitignored and exists only for `flutter run -d web-server
--web-port 8777` (or `-d chrome`) to eyeball screens at 390×844.
