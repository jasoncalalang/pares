# mealpal_ph — MealPal PH

Flutter app (Android + iOS) for the Philippine market: body stats → daily
calorie target → stores + ₱ budget → Filipino meal plan → grocery list.
Warm, editorial, grounded — a Filipino food magazine, not a clinical
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

- `lib/src/` — domain: `nutrition/` (Mifflin–St Jeor target, macro split),
  `plan/` (meal slots, day plans, grocery lists), `stores/` (PH catalog incl.
  palengke + sari-sari), `locale/` (peso + thousands formatting).
  Exported through `lib/mealpal_ph.dart`.
- `lib/design_system/` — tokens + theme (pinned by `test/design_system/`).
- `lib/widgets/<core|forms|data>/` — components; barrel `widgets.dart`.
- `lib/screens/` — the five screens.
- `lib/state/plan_draft.dart` — one `ChangeNotifier` for the whole flow.
- `lib/data/` — sample week / grocery list / store tiles (stand-ins for the
  meal bank + AI recommender).
- `test/` mirrors `lib/`; `test/helpers.dart` has `host()` and `phone()`.

## Design system (lib/design_system/)

Mirrors the approved Superdesign mockups. **Never hard-code a colour, size,
radius, duration or font family** — read:

- `MpColors` (ThemeExtension, `context.mp`) — cream ground `#FCF8EF`, ink,
  annatto primary, green secondary, amber, tints, hairlines, hero surface.
  `MpAccent` (annatto | green | amber) picks a family: chains/CTAs/meals =
  annatto, local stores/budget/protein = green, snack/fat = amber.
- `MpTypography` — Fraunces for headings, hero numbers, wordmark and
  monograms; Plus Jakarta Sans for everything else. Both are variable fonts;
  styles set `fontVariations` so weights actually move the axis.
- `MpSpacing` / `MpRadius` / `MpSize` / `MpStroke`.
- `MpMotion` — rise 380ms + 50ms stagger, press 0.97/120ms, select 250ms,
  reveal 850ms, `ease = Cubic(.2,.7,.3,1)`. Always read durations through
  `MpMotion.of(context, …)` so `disableAnimations` collapses them.
- `MpTheme.light()` — the only theme.

## Brand rules

- UI copy is English; Filipino dish names are proper nouns (Tapsilog,
  Tinola, Ginisang munggo). Gender field is "Gender" (Male/Female).
- Metric only (kg, cm); currency is ₱ via `formatPeso`.
- Icons: Lucide stroke icons only. No emoji. No retailer logos — monograms.
- Motion: fade/rise/fill/slide; nothing bouncy, no gradients, no parallax.
- Calorie target is deterministic math; the model (later) only selects
  from the meal bank and never invents nutrition numbers.

## Preview

`web/` is gitignored and exists only for `flutter run -d web-server
--web-port 8777` (or `-d chrome`) to eyeball screens at 390×844.
