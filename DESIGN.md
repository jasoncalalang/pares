# MealPal PH: design direction

This file is the direction for every screen: what the product is, how it
should feel, and the palette, type and motion that carry that. The antislop
skills are the filter that runs on top of it; they remove generic output but
do not choose a look. The enforced rules (tokens, tap targets, contrast
checks, copy rules) live in `CLAUDE.md` and in `lib/design_system/`. When
this file and the tokens disagree, fix one of them in the same change.

## Design read

Reading this as: a phone app that plans a week of Filipino meals for a
household on a peso budget, in a food-magazine editorial style, dial ENERGY 2
/ RHYTHM 2 / MOTION 2.

Dial: ENERGY 2 / RHYTHM 2 / MOTION 2

- ENERGY 2. Confident, not loud. One dark hero number, one annatto action
  per screen, real food photography. No hype.
- RHYTHM 2. One column of cards with a few deliberate breaks: the plate
  collage on Welcome, the dark hero card on Daily target, the store grid, the
  day strip.
- MOTION 2. Motion only where it carries information or feedback: the
  calorie arc and gauges fill, a selection settles, a press dips, a grocery
  section opens, screens fade. Nothing decorative enters on load: the data
  fills and the one new progress segment play once when their screen opens.

## Identity

MealPal PH turns body stats into a daily calorie target, and that target into
a week of real Filipino meals bought at the stores a person already uses,
within a weekly budget in pesos.

- Audience: adults in the Philippines who cook at home and watch both
  calories and the grocery bill. They shop at a supermarket chain, a wet
  market (palengke), a corner store (sari-sari), or all three.
- Promise: the numbers are honest. The target is arithmetic, a meal's
  calories are computed from its ingredients, and anything still estimated
  says so on screen.
- It is a food magazine that happens to do the math. It is not a clinical
  tracker, a fitness dashboard or a wellness brand.

## Personality

Warm, editorial, grounded.

- Warm: the food is the hero, and the colour comes from the kitchen
  (annatto, leaf green, the brown of a wooden table).
- Editorial: a serif headline, a clear lede, generous white space, photos
  given room. One idea per screen.
- Grounded: plain words, real dish names, real store types, peso amounts.
  No promises about results, no invented statistics.

## Ground: white paper

The page is white, `#FFFFFF` (`MpColors.paper`). Decided by the owner on
2026-11-13 after seeing four grounds side by side on the real screens; it
replaces the earlier cream `#FCF8EF`.

Why: a cream page under a serif headline with a terracotta button is the
most common machine-made look of the moment, and the cream was the part of
that trio doing no work. Food magazines print on white and let the
photography carry the warmth. So does this app: warmth comes from the
photos, the warm near-black ink, annatto, and the warm hairlines, never from
tinting the page.

Consequences that are intended:

- Cards are white on white. Their 1px warm hairline is the boundary, the
  way a rule separates items on a printed page. Do not add fills or shadows
  to make cards stand out.
- The dark hero card and the plate photos are the only heavy shapes on a
  screen, so they read first.
- There is one theme. No dark mode: the brand surface is the white page.

## Palette

Every colour the app chooses is a token on `MpColors`. Names below are the
token names. The one exception is the Google and Apple marks on the sign-in
buttons, which are the providers' own shapes and colours.

| Token | Hex | Role |
| --- | --- | --- |
| `paper` | `#FFFFFF` | Page ground |
| `surface` | `#FFFFFF` | Card surface |
| `ink` | `#241C15` | Primary text, the dark hero card (`heroSurface`) |
| `muted` | `#6B5D4C` | Secondary text |
| `faint` | `#776855` | Helper copy, quantities, small labels |
| `annatto` | `#B5401C` | The accent: the one primary action, step eyebrows, supermarket chains, meals |
| `annattoDeep` | `#A8370F` | Small annatto text, notices, and text on the annatto tint |
| `annattoTint` | `#FBEDE5` | Selected and chip fills in the annatto family |
| `green` | `#2E7D4F` | Local stores, budget progress, protein |
| `greenDeep` | `#1F6B3F` | Small green text, and text on the green tint |
| `greenTint` | `#EAF4EC` | Selected and chip fills in the green family |
| `amber` | `#8C5F10` | Snack slot, fat macro |
| `amberTint` | `#FBF0D8` | Amber fills |
| `hairline` | `#ECE3D2` | Decorative card borders |
| `outline` | `#998871` | The edge of every interactive control |
| `divider` | `#F2EADB` | Row dividers inside cards |
| `track` | `#EEE6D7` | Empty part of bars and step segments |
| `annattoFleck` | `#F0A36B` | Annatto on the dark hero card: its eyebrow and the calorie arc (8.1:1 there; plain annatto is under 3:1) |
| `heroText` | `#FCF8EF` | Text on the dark hero card |
| `heroMuted` | `#C9BEB0` | Secondary text on the dark hero card |

How the colours are used:

- Annatto is the single accent. At most one filled annatto button per
  screen, the pinned action; every other control, the budget steppers
  included, is outlined (the Apple sign-in button is ink, as its mark
  requires). The rest of the annatto on a screen is small: an eyebrow, a
  monogram, a slot label, a picked choice, a deficit.
- Green and amber are categories, not decoration. Green means local stores,
  the budget and anything within it (the under-budget total, a ticked
  grocery row), protein, produce, and a surplus over maintenance. Amber
  means snack, fat and dry goods. On the grocery list the small kind tile
  sorts rows by family: annatto for meat, fish and condiments, green for
  produce, amber for dry goods. A colour never appears only because a
  section needed variety.
- The neutrals are warm (brown-black ink, tan hairlines) on purpose. No cool
  greys.
- No gradients, glows, glass, neon, pastel blocks, pink or purple.

Contrast on the white page, measured: ink 16.8:1, muted 6.4:1, faint 5.4:1,
annatto 5.7:1, green 5.1:1, greenDeep 6.5:1, amber 5.6:1; the control
`outline` is 3.4:1. Text needs 4.5:1 and control edges 3:1. Dim with
`faint`, never with opacity.

## Typography

Two faces, strictly divided. Both are variable fonts shipped in the app.

- Fraunces (serif): headings, the hero numbers, the wordmark, peso totals
  and store monograms. It is the editorial voice and the reason the numbers
  feel printed, not displayed. Weight 600, tight leading (1.0 to 1.2),
  optical size matched to point size.
- Plus Jakarta Sans: everything else. Body 14, labels 12 to 13, buttons 15
  bold. A plain, open sans that stays readable at 11 to 14px and stays
  quiet, so Fraunces carries the editorial voice alone.

Scale in use: display 30, h1 28, hero number 50, ring number 30, total 34,
body 14, small 12, kickers 10 to 12.

Uppercase kickers (`STEP 2 OF 4`, `BREAKFAST`, `WEEKLY BUDGET`) are small,
bold and letter-spaced 0.04 to 0.12em. They label a section the way a
magazine department line does. They are the only uppercase text.

## Shape and space

- Single column, 22px gutters, one phone width. Pinned action at the bottom.
  On a wider screen (a tablet, a phone on its side) the column stays 430
  wide at most and sits in the middle; it is never stretched.
- Radius follows size, soft but not round: hero card, plates and the
  sign-in sheet 20, cards 16 to 18, the primary button and macro cards 15,
  store tiles 14, inputs, the gender choice, meal photos and secondary
  buttons 13, the goal choice and day cells 12, small squares 7 to 11.
  Fully round: chips, pills, bars and the round steppers.
- Borders do the work: 1px hairlines on cards, a 1 to 1.5px `outline` on
  controls, 1.5px accent border plus a faint 3px halo on a selected control.
- Flat. Two shadows exist: a plate photo resting on the table and the
  sticker on it (Welcome). Nothing else lifts, the grocery total included.
- Tap targets are 44px or more. One recorded exception: on a 320dp-wide
  phone the seven day buttons are 39px wide (and 52 tall), so the whole
  week stays in view without scrolling. From 352dp up they are 44px.

## Imagery

- Photographs of the actual dishes, shot from above or at a low angle on
  wood and woven surfaces, in natural light. The plate fills the frame.
  Four of the thirty dishes have a photograph so far; a dish without one
  shows its initial in Fraunces on its slot tint, never a stand-in picture.
- The Welcome collage is the motif: four plates tilted on a table, with
  small paper stickers for a calorie figure and a peso price. It shows an
  example day; it is not a claim.
- Stores are monograms in Fraunces on a tinted square. No retailer logos.
- Icons are Lucide stroke icons at 2px: one set whose stroke matches the
  1 to 2px outlines of the controls, used only where a glyph pictures the
  thing (an arrow for direction, a fish for fish, a bottle for condiments).
  A glyph that does not picture its content is dropped. No emoji, no
  illustrations, no 3D.

## Motion

Press 0.97 scale in 120ms. Selection 250ms; a picked store tile pops to
1.03 over 400ms. Data reveals (arc, gauges, bars, count-up) take 850ms
after a short delay: 250 to 350ms, the three gauges one after another up to
310ms later. The progress segment for the step just reached fills in 700ms,
so the bar says "one step on"; steps already done are drawn full. The day
highlight slides and the swap glyph turns in 320ms. Expand and collapse
350ms. Easing `cubic-bezier(.2, .7, .3, 1)` on every move and fill; the
press dip and colour fades are linear. Reduced-motion settings collapse
every duration to zero. No decorative entrance, nothing bouncy, no parallax,
no endless loops: the only repeating motion is the spinner while a plan
builds or a meal swaps.

## Voice

- English interface copy; Filipino dish names are proper nouns and stay in
  Filipino (Tapsilog, Tinola, Ginisang munggo).
- Buttons name what they do: "Compute my target", "Build my plan (2)",
  "See grocery list".
- Money is pesos with the ₱ sign; measures are metric.
- Estimates are labelled as estimates, where the number appears. A week
  that is a sample, not built to the person's target and budget, says so on
  This week.

## One focal point per screen

| Screen | The thing that leads |
| --- | --- |
| Welcome | The plate collage, then the headline |
| Tell us about you | The form itself; the action waits until it is filled |
| Your daily target | The dark hero card with the calorie number |
| Where do you shop? | The weekly budget, then the store grid |
| This week | The selected day's four meal cards |
| Grocery list | The estimated total against the budget |

## Kept on purpose

A filter pass may question these. Each has a reason, so they stay:

- A serif display face: it is the editorial voice and sets the numerals.
- Lucide icons: one stroke set at the weight of the control outlines, each
  glyph picturing its content.
- Uppercase kickers: department labels, small and rare.
- The dark hero card: the one heavy block, on the screen whose whole point
  is one number.
- The plate and sticker shadows: the collage is plates on a table.
- The 3px selection halo: selection must not rely on colour alone.
- A single light theme.
