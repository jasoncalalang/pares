# antislop Delivery Gate: MealPal PH

Run on 2026-11-13 against `main` after the merge (`eae34c2`), antislop 3.2.29,
mode during. Direction: `DESIGN.md`, dial ENERGY 2 / RHYTHM 2 / MOTION 2.

**Result: PASS at `1c2eb11`** (branch `ccr-036e5144-cvhuwe`, three commits on
top of the merge). The merged commit itself did not pass.

## How it was run

| Pass | What | Outcome |
| --- | --- | --- |
| 1 | Five auditors on a web build of `eae34c2`, each failure challenged by a second agent | 68 PASS, 30 FAIL, 4 NA; 14 distinct defects after 5 were refuted and duplicates merged |
| Fix 1 | 14 defects fixed test-first, 4 of them by owner decision | `e4f9ea5`, `4bbc61a`; 401 tests pass |
| 2 | Three independent checkers on a build of `4bbc61a` | All 14 confirmed fixed in the running app; 12 further items found |
| Fix 2 | 11 of the 12 fixed test-first; 1 was already settled (hyphen break, renamed anyway) | `1c2eb11`; 409 tests pass, analyze clean, server tests and bank check pass |
| 3 | My own check of fix 2: full suite, a fresh build walked at 390, 360 and 320 wide, no console errors | Not independently re-audited |

Evidence key: **[1]** first-pass auditor, **[2]** independent re-check on the
fixed build, **[3]** tests and my own screenshots after the second fix.

## Block 1: Hard Gate

| Rule | Status | Evidence |
| --- | --- | --- |
| R-02 em dash | PASS | None in `lib/`, `DESIGN.md`, `CLAUDE.md`, `server/` or on screen. The only two in the tree are search needles inside tests that enforce the ban. [1][2] |
| R-03 mobile | PASS, one recorded exception | No horizontal overflow from 320 to 430 wide. Picked store names whole at 360 and 375. Tile border, halo and badge unclipped while scrolling. Number fields take a tap anywhere in the 64px box (48 of 48 clicks). Day buttons 44px from 352dp; 39px at 320dp is the owner's exception of 2026-11-13. [2] Budget row gap at 320 and the meal detail line at 360. [3] |
| R-17 numbers | PASS | Every figure is the app's arithmetic or labelled an estimate. Welcome stickers unlabelled by owner override of 2026-11-02. [1][2] |
| R-18 testimonials | PASS | None exist. [1] |
| R-23 assets | PASS | Wordmark is type, stores are monograms, photos and provider marks were committed by the owner. [1] |
| R-24 navigation | PASS | No navbar; every step, back link and the grocery button was clicked and landed on a real screen. [1][2] |
| R-25 contrast | PASS | Ink 16.8, muted 6.4, faint 5.4, annatto 5.7, green 5.1, amber 5.6 on white; disabled label 5.0 on its fill (was 4.2); arc 8.1 on the hero card (was 2.97); control outline 3.4. [2] |
| R-26 controls | PASS | Every control clicked, each did something. Sign-in and the GrabMart handoff carry a `TODO` and a visible "coming soon" line. [1][2] |
| R-27 states | PASS | Building, failed, swapping, empty list, no-ingredients, over and under budget, disabled buttons with a helper line. Building and failed cannot be reached in sample mode, so they rest on code and tests. [1] |
| R-28 FAQ | PASS | None exists. [1] |
| R-32 keyboard | PASS | Tab order follows the screen, Enter and Space activate, Escape closes the sheet. The number fields now show the ring. Rings are whole at the gutter [2] and at the top and bottom scroll edge [3]. |
| R-33 patch scripts | PASS | None. [1] |
| R-34 themes | PASS | One light theme, no toggle. [1] |
| R-35 run and click | PASS | Built and clicked through element by element twice, by different agents, with no console or page errors. [1][2] Third build walked at three widths, no errors. [3] |
| R-36 claims | PASS | No security, compliance or performance claims. [1] |
| R-37 direction | PASS | `DESIGN.md` exists with dials; four pattern conflicts were put to the owner and recorded. |
| R-38 real content | PASS | The offline week was an unlabelled stand-in under the person's own target and budget. It now says "This is a sample week. It is not matched to your target, budget or stores yet." on screen, after swaps and day changes too. [2] |
| R-39 semantics | PASS | No unnamed image nodes, one heading per screen, disabled swap, stepper and CTA look disabled, reduced motion honoured, click cursor on enabled controls. [2][3] |
| R-40 performance | NA | Native app; the rule is about HTML documents. No performance figure is reported because none was measured. |

## Block 2: Purpose-Gate

| Rule | Status | Evidence |
| --- | --- | --- |
| R-01 gradients | PASS | None in `lib/`. [1] |
| R-04 icons | PASS | Reason for the set is written; a lab flask, cutlery, a shopping bag and a carrot on garlic were replaced with glyphs that picture the item. [2][3] |
| R-06 typography | PASS | No monospace; kickers, Fraunces and Plus Jakarta Sans each have a written reason. [2] |
| R-07 background | PASS | Plain white, no pattern. [1] |
| R-08 arrows | PASS | Right arrow only on a step forward, left arrow on every way back, including "Go back" (was pointing forward). [2] |
| R-09 badges | PASS | Pills carry data (target, budget); the eyebrow is the step and back link. [1] |
| R-10 glass | PASS | No blur. [1] |
| R-12 shadow | PASS | Only the Welcome plates and their stickers, with a written reason; the grocery total shadow is gone. [2] |
| R-13 glow | PASS | None. [1] |
| R-14 cards | PASS | Repeated cards are rows of data, not feature tiles. [1] |
| R-19 animation | PASS | Only the progress segment just reached animates (earlier ones replayed on every screen); motion matches the written list and MOTION 2. [2] |
| R-22 illustrations | PASS | None. [1] |

## Block 3: Liveliness

| Question | Status | Evidence |
| --- | --- | --- |
| Dials declared | YES | `DESIGN.md`, ENERGY 2 / RHYTHM 2 / MOTION 2. |
| Output matches the dials | YES | One column with deliberate breaks; motion only on data, selection and press. [1][2] |
| One focal point per screen | YES | Collage, form, hero number, budget and grid, the day's meals, the total. [1][2] |
| Whitespace is structural | YES | [1] |
| One deliberate accent | YES | Filled annatto buttons per screen: 1, 1, 1, 1, 1, 0. [2] |
| Identity motif | YES | Plates on a table, Fraunces numerals, store monograms. [1] |
| Design Read declared | YES | In `DESIGN.md`. It was written on 2026-11-13, after the screens were first built. |
| Sterile after the white ground | NO | Checked against the "Sterile Default" pattern on fresh screenshots of all six screens. [1][2] |

## Block 4: Craftsmanship and Quality Locks

| Rule | Status | Evidence |
| --- | --- | --- |
| C-1 intentionality | PASS | Colour roles now match what is written: lunch and dinner tiles and the Activity choice are annatto, the budget + is outlined, grocery families are documented. [2][3] |
| C-2 function | PASS | See R-26. |
| C-3 content-driven | PASS | Six screens, each a step of the product; no template sections. [1] |
| C-4 resilience | PASS | States, 320 to 1024 wide, keyboard only. Column capped at 430 on tablets, sign-in sheet included. [2][3] |
| C-5 evidence | PASS | See R-17 and R-38. |
| R-05 layout | PASS | An app flow, not a landing page template. [1] |
| R-11 radius | PASS | Radius varies with size; `DESIGN.md` now lists the tokens as they are. [3] |
| R-15 CTAs | PASS | Every button names its action. [1] |
| R-16 buzzwords | PASS | None. [1] |
| R-20 identity | PASS | Reads as this product with the wordmark removed. [1] |
| R-21 theme | PASS | Single light theme, reason written. [1] |
| R-29 palette | PASS | Annatto, green, amber, plus warm neutrals. [1] |
| R-30 clones | PASS | Resembles no known product. [1] |
| R-31 reasons | PASS | One line each for colour, layout, both typefaces, spacing, cards, icons, imagery, hero card, halo and theme. [2] |

## What changed in the app

- **Access:** focus ring on the number fields, rings and halos no longer
  clipped, taps land anywhere in a number field, disabled controls look
  disabled, screen titles are headings, dish photos are decoration for
  screen readers.
- **Honesty:** the sample week is labelled on This week.
- **Layout:** picked store names whole at 360 and 375dp, column capped at one
  phone width, servings on their own line when the meal detail does not fit.
- **By your decision:** light annatto calorie arc, outlined budget steppers,
  flat grocery total, day strip left at 39px on 320dp phones.

## Changed on my own reading of DESIGN.md, not asked

- The Activity choice on Tell us about you picks in annatto, not green.
- Lunch and dinner tiles without a photo are annatto, not green.
- Onion, garlic and ginger rows show a green leaf, not an annatto carrot.
- "Chicken (bone-in)" is "Chicken (bone in)" in the app and the server bank.

## Not verified

- The second round of fixes was checked by tests and by me, not by an
  independent agent.
- The mouse click fix on an already focused number field is the standard
  Flutter mechanism but I could not reproduce the before or after in the
  browser myself.
- Nothing was run on Android or iOS; every live check was on the web build.
- Large text is covered by tests only.
- The disabled swap button cannot be seen in sample mode (the swap finishes
  in one frame); it rests on code and a test.

## For you to confirm

- The reasons I wrote for Plus Jakarta Sans and Lucide in `DESIGN.md`.
- `DESIGN.md` calls the four meal images photographs; the record does not
  say whether they are photographs or generated.
- The pills on This week still read "≤ ₱500" in sample mode, beside the line
  saying the week is not matched to the budget.
- A phone on its side works but is cramped; locking to portrait is an option.
