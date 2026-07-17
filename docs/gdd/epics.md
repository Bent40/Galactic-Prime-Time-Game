# Development Epics — detailed breakdown

*Companion to `gdd.md` §Development Epics. Epic order is the architecture PDF's KAN
sequence (authoritative — don't start a later epic early). Stories here are shaped for
`gds-create-story` → per-story dev with review gates; each story gets EARS acceptance
criteria at creation time (that also clears `wf audit`'s SETUP-NEEDED). States:
✅ done · 🔨 partial · ⬜ pending.*

## KAN-1 — Data foundation ✅

Schema (246-line SQLite migration), JSON seeds (races, enemies incl. Incinedile 6-phase,
9 conditions w/ tier tables, 44 skills, 82 thresholds, 28 items, 100 tags, 27 modifiers,
3 patron-god stubs), `validate_seeds.py` (172 rows green, wired into `wf validate`).

## KAN-2 — Combat engine 🔨 (core ✅ 29/29)

Done: command-stream reducer (R0–R2), Moment clock, per-part HP + deaths/bleed-out (R5),
all 9 condition engines + treat/heal (R4/R10), Forced Action d6 tables (logged rolls),
requirements gate (R10), RPM/magazine/reload (R8), grapples (R9), movement/statuses/
exposure (R3/R7), resistances + boss hooks (R6), shock R13-as-provisional, levels (R6),
hype engine v1, determinism + save/resume tests.
- ⬜ **S2.1 Priming system** — replace dormant cooldown path with prime states
  (channels/stacks/stances/conditions), item prime-skips. *Gated on the owner skills
  passover (vocabulary).*
- ⬜ **S2.2 R13 shock finalization** — apply owner confirm/amendments; regression tests.
- ⬜ **S2.3 R14 numbers pass** — force-vs-robustness gate (co-design), unarmed/weapon
  damage table, re-seed placeholders; mutation pass (`wf mutate`) after.
- ⬜ **S2.4 Free-action/actions-per-tick audit** — verify addendum rulings hold under
  real-time declare windows (APM-contest guard).

## KAN-3 — Scaffolding ⬜ (next)

- **S3.1** Main scene + `GameController` autoload; signal catalog per architecture PDF.
- **S3.2** DAL: JSON-first for the slice (SQLite deferral recorded in ISSUES); single
  owner `controller/dal.gd`; save_manager owns files; snapshot+log-offset saves.
- **S3.3** Hex renderer: field grid, occupancy, part/condition badges (readability
  spike — feeds the KAN-6 mockup).
- **S3.4** Clock driver (paused-on-decision solo) feeding `advance_tick` commands.

## KAN-4 — Party ⬜

- **S4.1** OC creation: 7/7 traits, race pick, skills per race rule, background picks
  (origin/vice/virtue/want) — the picks seed traits + patron bidding.
- **S4.2** Recruitment encounters: offer/earn/join flow; party roster (no cap);
  per-fight deployment + exhaustion rotation.
- **S4.3** Sasha & Nikita kits: data + `exclusive_to` skills (Reversion = first real
  prime, after S2.1); recognition-asymmetry hook (Sasha reads Nikita's state).
- **S4.4** Permadeath handling for recruits (loss states, roster continuity).

## KAN-5 — Exploration ⬜

- **S5.1** Floor/route graph with exclusivity + time-skip transitions.
- **S5.2** Combat fields: boundary, join-at-Clock-reset, leaver-forfeits.
- **S5.3** Noise/absorption: noise budget per fight; eligible-encounter pull at resets.
- **S5.4** Overworld coarse clock (conditions advance between fields).

## KAN-6 — UI ⬜ (mockup gate before build)

- **S6.1** Declare UI + consequence preview (the pillar-2 UX; mockup first).
- **S6.2** Broadcast chrome: hype bar, odds board, lower-thirds, Camera Call moment.
- **S6.3** Party/condition readouts (per-part states at a glance).
- **S6.4** A11y baseline (contrast, scale, input remap) — `dod.accessibility_gate`.

## KAN-7 — Progression & audience ⬜ (grew 3× with the casino frame)

- **S7.1** Exposure tiers + hype tuning (weights from slice playtests).
- **S7.2** Patron gods: roster data (real content past the 3 stubs), bidding at
  creation, affection ledgers + multiplier boon economy, `patron_tip` via director
  interface, buy-out event, abandonment modes, Forsaken run flag.
- **S7.3** Epithets: traits vocabulary, myth templates, match-and-grant; tags drift
  kept separate.
- **S7.4** Verdict: axes data structure, floor-set scoring hooks, unlock graph,
  verdict function; convergence-matrix state store.
- **S7.5** Directives/Goals through the director interface (deterministic policy).

## SLICE (W3) — the MVP assembly

One arena (Incinedile P1, party of 3), OC creation-lite, two recruitment encounters,
visible hype meter, broadcast win/lose framing. Requires: KAN-2 core ✅, S3.1–S3.4,
S4.1–S4.3, S6.1–S6.3 minimum. Gate: the fun bar (stranger, 20 minutes, clip-worthy
moment, wants another run) + `gds-check-implementation-readiness` before assembly starts.

## W4 — Story track (content, runs parallel after slice)

Floor-set questions 1–6 authoring, convergence matrix content, Nikita/Sasha key scenes,
Medium-route forks + brand-breach rules, production cast — per `story-canon.md` queue.
(Dual-prose presentation: post-MVP, set aside.)
