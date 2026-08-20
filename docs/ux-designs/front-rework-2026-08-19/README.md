# Front-rework mockups — the HUD v2 gate (owner-approval)

**Status: REVISED 2026-08-19 after the owner's ruling on all ten decisions (decision
log #36, addendum R34) — awaiting sign-off on the revised frames. Nothing here is
built into scenes.** Per working
rule 4 (design/UI work ships a mockup + approval before building), these five frames
are the front-rework mockup gate. They realize the owner's structural spec
(`../hud-v2/ARCHITECTURE.md`, adopted 2026-07-22) in the APPROVED visual identity
(`../demo-slice-2026-07-19/DESIGN.md`) — structure and information design are the
deliverable; **every number is PLACEHOLDER (R14)** and **emoji are placeholder art**
(banned in the final release by ARCHITECTURE.md §7, kept here per the approved
mockups' precedent).

Rendered for real: headless Chromium at 1600×1000 @2x (`render.sh`; the headless
viewport is ~95px shorter than `--window-size` in this build, so frames render in a
1120-tall window and `crop_png.py` trims to the canvas). Rebuild everything with
`python3 build_mockups.py && ./render.sh`.

| frame | mode (ARCHITECTURE.md §4) | file |
|---|---|---|
| 1 | **B — party member ready** (den fight, Dario on the clock) | `hud-ready.html/.png` |
| 2 | **C — targeting a body part** (Feint → Left Hand, full preview chain) | `hud-targeting.html/.png` |
| 3 | **reaction** — the R22 dodge ask + the R26 undodgable **intent** | `hud-dodge-ask.html/.png` |
| 4 | **A — free-form exploration** (R29 branch: Kennel vs Service Corridor, no clock) | `explore-branch.html/.png` |
| 5 | **D — popup** (Mod-Center tier-2 special offers, all three BLESSED) | `mod-center.html/.png` |

All content is real slice data: Imani/Dario (`data/demo_run.json` loadouts, verbatim
traits + skills), Sasha "Little shadow" (`data/recruit_loadouts.json`, joined as-is
with her L-ARM 1/2), the Incine-Dile's true part list with the network hidden
(`data/enemies.json`), the war-hound pack read (herders, blood-scent), the den arena's
real doors/walls/cans, the Brood-Landing exits, and the three blessed Mod-Center
offers. The gods/odds panel reuses the approved bid-screen cast (Hestia/Enyo/Ares).

## The owner's ruling (2026-08-19) — what changed

| # | verdict | what the frames do now |
|---|---|---|
| 1 | ✅ approved | layout unchanged |
| 2 | ❌ **changed** | **intent icons on every enemy** (Slay-the-Spire), hover = full explanation; timeline keeps order/timing only; ⛔ undodgable now declared on the icon; unread enemies show **UNREAD ❓** |
| 3 | ✅ approved | dodge-ask card unchanged (its footnote now points at the icon) |
| 4 | ✅ approved | unchanged |
| 5 | ✅ approved | unchanged |
| 6 | ✅ approved | unchanged — and now extended to intent (read vs unread) |
| 7 | ✅ approved | unchanged |
| 8 | ❌ **changed** | **exploration is free-form** — no Clock, no Moment order, no turn to end; route breadcrumb replaces the timing strip; WALK is free; the clock starts on contact; ENTER ▸ ⟨route⟩ is the commit |
| 9 | ❌ **changed** | **parents cap at 5** unless already linear; declining costs nothing but the ceiling (Mod-Center copy corrected) |
| 10 | ✅ approved **+ amendment** | free actions stay in the category **but carry a per-turn budget** — the button reads `FREE ACTIONS 1/2` |

**Not built, tracked as follow-ups:** free-form exploration in the engine (today's sim
is clock-driven end to end; "contact" is undefined), and the free-action budget (free
actions are uncapped in the resolver). Both are recorded in R34 with their PROVISIONAL
edges named.

## Decisions as originally put (superseded where the table above says changed)

1. **The §2 layout, realized** — party rail left (3/6, scroll note), selected-actor
   summary top-left, popup shortcuts + Moment/Clock timeline + compact odds across the
   top, crowd + inspector as floating glass over the world's right edge, chat +
   action launcher + End Turn bottom, Momus ticker at the base. The world keeps ~72%
   of the screen. (Vocabulary per the 2026-07-22 ruling: CLOCK 3 · MOMENT 07; costs in
   Moments.)
2. **The timeline is the warning surface** — declared actions and windups render as
   bands on the 0–10 track (flamethrower windup with interrupt state), scheduled
   condition ticks as chips (🔥 BURN II → DARIO), and **R26 undodgable attacks carry
   the ⛔ UNDODGABLE badge on the band from the moment of windup** (frame 3) — the
   mandated transparency lives here, stable, not in the ticker.
3. **The dodge ask is a blocking reaction card** (frame 3) — bottom-center, never
   covering the target; states the R22 math plainly (Reflexes 2 vs threshold 4 →
   threshold die d4, roll 3+); four options: DODGE (d4), TACTICAL ROLL (R25
   declared-hex, forfeits movement), BRACE, TAKE IT (with the honest cost).
4. **Status effects are load-bearing everywhere** (the "more prevalent" ask):
   condition dots on tokens, urgent part flags on party cards (🩸 R-ARM 1/2), the
   selected panel's urgent line, per-part condition/state chips in the inspector,
   scheduled ticks on the timeline.
5. **Stealth + facing are first-class board surfaces** — conceal ring with reveal
   radius (dashed) under Sasha, CONCEALED chips on token/card, the boss's facing
   wedge (R30 front arc) and the flamethrower cone telegraph; exploration carries
   the hearing texture ("BARKING · LOUD", **alerted ≠ located** chip).
6. **Discovery-state vocabulary in the inspector** — VISIBLE / KNOWN / SUSPECTED /
   HIDDEN / MISIDENTIFIED? chips; the Incine-Dile shows the pre-breach masked row
   ("UNKNOWN INTERNAL STRUCTURE · 🔒 ???"), never the answer.
7. **Targeting shows three information levels** (frame 2, §10): near-cursor tip
   (part, in-range, predicted), the action preview card (target/cost/read-risk/
   consequences + CONFIRM/BACK), and the inspector in targeting mode (every part
   VALID / OUT OF ARC with predicted damage). Read risk is stated (Mind 1 — feints
   unreadable).
8. **Exploration is Mode A** (frame 4) — exits are interactable objects (inspector
   focuses the door: leads-to, heard-through-it, the pack read), the hype-chain
   banner states the R29 carry math (68 → 27 at 40%), and the commit button becomes
   **ADVANCE ▸ ⟨route⟩** with an End-Turn-grade consequence line. Voicebox appears as
   the free-action decoy option.
9. **The Mod-Center is a Mode D popup** (frame 5) — three BLESSED offers with
   broad-only group chips, the focused offer's requirement rows (IN PROGRESS / NOT
   LEARNED), the CONSUMES-BOTH-PARENTS warning, "offered, never automatic" framing,
   and the declared PAUSED state. (Where it appears in the run flow + pricing is
   KAN-7 scope — stamped on the price row.)
10. **Camera Call and The Bit stay inside Free Actions** with the Mode E badge pulse
    (spec §6 ruling) — no permanent extra buttons.

## Honest caveats

- The board is a CSS/SVG approximation of the 2.5D tilt — proportions and hex
  positions are composition, not sim-accurate coordinates; the real scene reads
  positions from the view API.
- Chat content, wager copy, and Momus lines are draft flavor; ticker copy is
  editorializing by design (broadcast plane), never tactical truth (§11 limitation
  honored — every warning also exists in a stable surface).
- Frame 1's consequence line mentions the cross-character chain (owner-approved
  2026-08-19) — the engine mechanic merged the same day.
- The 4th-skill-slot question and controller glyphs are not addressed here (owner
  court / later parity pass).
