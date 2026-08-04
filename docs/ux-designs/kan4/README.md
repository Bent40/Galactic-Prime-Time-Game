# KAN-4 mockups — recruitment beat + character creation (owner-approval gate)

**Status: AWAITING OWNER APPROVAL — nothing here is built.** Per working rule 4
(design/UI work ships a mockup + approval before building), these two screens are
the KAN-4 mockup gate. Structure and flow are the deliverable; every number on
screen is either a real system number (sources below) or covered by the
`PLACEHOLDER NUMBERS · R14` watermark stamped on both frames.

| screen | source | render |
|---|---|---|
| Recruitment beat (post-encounter offer, party 2 → 3) | `recruitment-beat.html` | `recruitment-beat.png` |
| Character creation (casting-tape audition, R21 filter-first) | `character-creation.html` | `character-creation.png` |

Rendered for real: headless Chromium (Playwright) at 1600×1000, zero console
errors, same broadcast frame as `../demo-slice-2026-07-19/DESIGN.md` (the
approved visual-identity spine — palette, mono numbers, LIVE pill, chyron,
watermark all reused verbatim).

---

## Decisions the owner is asked to approve

### Mockup 1 — the recruitment beat

1. **Screen structure** — a full-screen post-encounter overlay inside the
   broadcast frame (HUD v2 Mode D): roster-preview rail left (mirrors the HUD
   party rail), the recruit's card center, crowd + patron reactions right,
   ACCEPT / DECLINE as a full-width footer, Momus chyron below.
2. **Recruit card contents** — portrait placeholder, persona blurb, **part-based
   HP always shown** (HUD v2 owner correction #3: non-mob allies show anatomy,
   never just a bar), skills with levels + the R16 cap-trade badge, patron sigil
   slot, camera-call stacks, and the authored BIT as its own framed block (with
   the "not everyone has a bit — no bit, no button" texture stated on-card).
3. **"Joins as-is" rule** — the recruit carries the damage from the encounter you
   met them in (torso 3/5, L-arm 1/2 shown). Approve or rule that recruits join
   healed.
4. **Accept/decline consequence framing** — DECLINE is honest and final: *"He
   walks. Recruits are permanently losable — this offer does not return."* This
   extends the canon "recruits are permanently losable" to declined offers.
   Approve, or soften (e.g. re-offer later in the run).
5. **Broadcast drama on the offer** — Momus chyron line, a crowd "sign him /
   let him walk" lean meter, and patron reaction chips (Enyo/Hestia approve,
   Ares disapproves, Tyche "buys in"). **Flavor only** — chips carry no
   mechanics; the patron economy stays deferred.
6. **Content stand-in** — Dario "Encore" (demo loadout id 2) drives the card
   because it is the only data with the full authored shape (bit + skills +
   patron + stacks, all engine-real). Canon recruit encounters remain
   **Sasha & Nikita** (character-IP ruling 2026-07-15); everything is rewireable
   (decision #13). The stand-in is declared on the frame itself.

### Mockup 2 — character creation

7. **Filter-first flow** — the recorded R21 UX direction made concrete: choose by
   **properties** (aquatic / flying / grab-limb / small / armored / stinger /
   long-bodied) narrowing a body-plan grid — **never a flat list**.
8. **Single screen with a 5-step rail** — 1 Properties → 2 Body Plan → 3 Traits →
   4 Skills → 5 Identity, all visible at once (no wizard paging). Approve the
   single-screen shape or ask for paged steps.
9. **Human default front-and-center; animals honest** — Human is the one
   AVAILABLE plan (R16 Earth-life only); Cat / Crab / Snake tiles (the R21
   examples) are shown dimmed as **IN PRODUCTION** — visible, not clickable, no
   fake promise (Q61 deferral).
10. **Part map presentation** — per-part HP + LETHAL badges on a Lego-slot-styled
    body diagram, with the R21 sentence ("a plan is which parts, how many, what
    size") stated on-panel.
11. **Trait step surface** — direct allocation of the **7 Body / 7 Core pools
    (max 5 per trait)** with a live "what these numbers buy" readout (R22 dodge
    reach vs the Dash threshold, R24 feint-read reach, camera-call stacks; FORCE
    marked `PENDING R14`). **Note the open tension:** R16 says the *background*
    is the single creation surface (epithet track grants traits). This mockup
    presents direct allocation as the 60-second-creation surface — approve that,
    or redirect to a background-driven trait step.
12. **Skills step** — 4 background-granted picks (R16) from the six
    engine-implemented skills, with the trade affordance (give up pick 4 → +1 cap
    on one skill, 5→6) shown as slot 4; the remaining catalog appears as one
    dimmed `FUTURE` row, not as pickable content.
13. **Bit editor presence** — an optional AUTHOR-A-BIT editor in Identity with an
    explicit skip affordance ("not everyone has a bit — skipping is a real
    choice", decision #25).
14. **Patron courtship teaser** — the audition tape's structured picks
    (origin / virtue / vice / wants back home, from the slice-contestants
    proposal) shown as "the keywords the gods bid on", with the five roster gods
    watching dimmed; submission leads into the already-approved Bidding screen.
15. **Casting-tape skin** — REC pill + "pre-season talent intake" + applicant
    number + Momus intake commentary as the creation frame (the show signs
    contestants).

---

## Explicitly NOT in scope

- **Animal body plans** — no authored part layouts exist (Q61 deferred; Sasha's
  cat plan is OPEN on her sheet). Tiles are display-only.
- **The patron economy** — bids, favor, boons, taboos. Reaction chips and the
  courtship teaser are flavor/preview only.
- **Epithet-track mechanics** — the background→traits pipeline is not designed
  here; see decision 11.
- **Final numbers** — everything numeric is PLACEHOLDER (R14) except the
  engine-real values listed below; the watermark stays until the numbers pass.
- **Portrait/art** — placeholder hatching + glyphs; art pass is separate.
- **Party-of-6 roster UI** — this beat only takes the party from 2 to 3.

## Honesty notes (what on screen is real vs. placeholder)

**Real system numbers:** human part HPs 2/5/2/2/3/3 + LETHAL flags and the
17-HP total (`data/races.json`); trait spreads (Dario 2/5/2/5; sample OC 3/4/4/3
— both creation-legal 7 Body / 7 Core = 14, matching the demo pair's budget);
skill names, levels, Moment costs and effects (`simulation/skill_book.gd`:
Feint Lv3 read-threshold 7 = 4+Lv per R24, Pressure Strike 2 Bleed = 1+Lv,
Dance +2 Charm = +Lv, Strong Strike 6 Crush, Brace guard-by-Lv, Overhead Slam
2+Lv Crush); the cap-6 trade (`data/demo_loadouts.json`, R16); camera-call ×1
(the slice testing override, §RULED item 5) and the "0 stacks at Charm 3, 1 per
20" derivation (R6); dodge/feint-read derivations (R22/R24, d4 default die);
hype band ELECTRIC at meter 118 (hot = 100–179 in `simulation/hype_engine.gd`;
display name per `controller/game_controller.gd` BAND_DISPLAY); patron roster +
Enyo signing (`data/patron_gods.json`, `data/demo_loadouts.json`); the six
implemented skills vs "+37 pending" (`skill_book.gd` KNOWN_KEYS + its fallback
note); the bit "The Bow" (authored in the loadout data).

**Placeholder/flavor (covered by the R14 watermark):** viewer count, crowd meter
value/delta, the 71/29 lean split, "tonight's tape" stat lines, patron reaction
verdicts and quotes, Momus lines, applicant number, the recruit's specific
damage state.

**Known simplification:** Sasha appears in the roster rail at rail granularity
only (name/state/patron) — her authored body plan does not exist yet and nothing
anatomical is shown or implied for her.
