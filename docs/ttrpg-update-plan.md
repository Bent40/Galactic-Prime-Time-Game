# GPT TTRPG v0.92 Update & Character-Sheet Reconciliation — PLAN

**Status:** PROPOSED (awaiting owner approval) · **Date:** 2026-07-23
**Scope:** (A) fold every RULES ruling back into the tabletop game as an updated book;
(B) bring the character-sheet app (the live campaign tool) into line with those rules.
**Explicitly out of scope:** the video game's setting change. The TTRPG keeps its
ORIGINAL setting — reality-TV dungeon crawler, The Corporation™, alien broadcast,
Viewers/Followers/Patrons as the audience economy. Everything Cosmic-Casino-flavored is
video-game-only and stays out of the book and the app.

---

## 0. The no-mix-ups guard — three canons, kept separate

| Canon | Artifact | What lives there |
|---|---|---|
| **TTRPG book** (this plan updates it) | `DCC esque System` v0.91 → **v0.92** | Table rules, original reality-show setting, the live campaign's races/characters/tags |
| **Digital rules** (already canon, unchanged by this plan) | `docs/rules-addendum.md` R0–R23 | Engine rulings; where the book stays silent the sim implements the addendum |
| **Video-game setting layer** (NEVER ported to TTRPG) | `docs/cosmic-casino-canon.md`, `docs/design/patron-gods.md`, DIRECTION D3–D5 | Cosmic Casino, patron gods, divinity economy, Forsaken runs, epithets, verdict/spine |

**Hard exclusions from the TTRPG update** (game-only, most are setting/mythology):

- Cosmic Casino frame, patron gods, god bidding, boons, buy-outs, Forsaken runs,
  epithet track, rival-god interventions (incl. R20's god-based destealth lever),
  mythology roster — all of it.
- **"Patrons" in the TTRPG remain paying audience members** (System §Exposure), never
  gods. Patron Tokens stay the audience-earned skill-cap currency. Any sentence that
  needs the word "god" does not belong in the book.
- R5's "puppet **of the collapser**" epilogue and R16's background/bidding creation flow —
  game creation systems. (The mind-collapse *mechanic* itself ports; see A-13.)
- R16 races "Earth-life only / Robot removed" — **game-only.** The ruling itself says the
  rulebook's Robot entry becomes TTRPG history; XQUEZ/T (AI) is a live table character.
  The book keeps Human / Animal / Robot-AI.
- R17 run types (softcore/hardcore respawn) and the checkpoint-rewind death model — the
  table has a GM and one campaign; book death rules are R5's.
- The 2026-07-17 tag cuts/renames (84-tag game list, K-pop cluster removed, 5 words to
  the epithet track) — **game-only.** The table's K-pop tags are XQUEZ/T's identity. The
  book keeps the full owner tag list (`docs/rulebook-tag-descriptions.md`, 2026-07-18) as
  authoritative.
- R23 Antagonism engine, R11 #13–#18 (hype/goal/AI/phase machines), noise-absorption,
  declare windows, friendly-fire ruling — digital engine/AI/pacing; the GM is the table's
  version of all of these. (Optional: a one-paragraph GM sidebar on enemy attention.)
- R21 Lego part-composition + animal-parts library — digital creation system; the book
  keeps GM-statted animal bodies (Filipe/Sasha precedent), pending the deferred
  animal-parts sitting.

**One deliberate divergence to decide, not assume (Decision D-1):** R14
force-vs-robustness (`damage = max(0, Force − Robustness)`) was ruled as the *video-game*
numbers rework. Recommendation: TTRPG v0.92 **keeps the listed-damage model** (R4) —
it's what the table has played for months — and R14 is reconsidered for a table edition
only after the digital playtest proves the feel. If the owner wants one damage model
everywhere, that's a v1.0-scale rewrite of every weapon/enemy statline.

---

## 1. Sources being reconciled (precedence for this effort)

1. Owner rulings 2026-07-14 → 07-23 (questionnaire answers, decision log, addendum
   AMENDED/RULED blocks) — highest.
2. `docs/rules-addendum.md` R0–R23 — the rulings pool to port (filtered per §0).
3. `docs/GPT_Master_Compendium.md` §2 — the v0.91 system baseline the book update edits.
4. `docs/review/review-1-ttrpg.md` A1–F10 — the defect catalog v0.92 must close.
5. Live DB (44 skills / 28 items / 100 tags / 27 affixes / 5 characters) — content ground
   truth; content errata ride Phase 2.
6. Character-sheet app code — the de-facto second rulebook; where the app's live-tested
   formula was adopted by ruling (R6), the app IS the rule.

## 2. Workstream A — the book: "GPT System v0.92"

**Target artifact:** a markdown master (`docs/ttrpg/gpt-system-v0.92.md`, new dir) built
from compendium §2, with a changelog appendix mapping every change to its defect id +
ruling. The owner exports to docx/PDF from there; markdown becomes the editable source of
truth (the docx/PDF stop being editable canon).

### A. Rulings promoted into the book (rules only — all table-compatible)

| # | Book change | Closes | Source ruling |
|---|---|---|---|
| A-1 | **Clock & scheduling chapter rewrite:** Moments 10→1 display, absolute scheduling (`next action = current + cost`, continues across Clock resets), order of operations at a tick (resolve → forced-action consequences → Clock-reset advancement/reorganization) | C1 | R0/R1 |
| A-2 | **Declare/resolve timing:** cost ≤1 declares+resolves same Moment; multi-Moment = windup, Exposed, dodgeable by leaving range before resolution; resolution re-checks validity → Forced Action–Tool on invalidation; simultaneous resolutions use start-of-Moment state (trades happen; no priority) | C2, A5 | R2 |
| A-3 | **Reaction economy (new section):** reactive skill = declared trigger; resolves immediately; its Moment cost delays the reactor's next scheduled action; max one reaction per combatant per Moment; 0-cost reactions also consume the free-action slot | A5 | R2/R3 |
| A-4 | **Action caps:** per Moment = 1 scheduled + 1 free (0-cost) + 1 reaction; 0-cost skills legal; free move 1–3 spaces once per Moment; longer moves `ceil((spaces−3)/4)` Moments; inventory: first interaction of a combat free, then 1 Moment each — **reset clause deleted**; item's own Moment cost replaces (never adds to) the interaction cost | D1, D2, C6, F5, F10 | R3 |
| A-5 | **No cooldowns — priming (new section):** the 5-type prime vocabulary (CHAIN / STANCE / STACK / STATE-POSITION / PREP-CHANNEL); high-tier items may skip named primes; cooldown-texted skills re-expressed as primes (content pass, owner's skill passover) | F5, NQ1 | R3 + decision #20 |
| A-6 | **Damage & conditions engine:** attack deals **listed damage** ("usually 1" deleted); flat resistance floor 0; condition applies at T1, re-application advances one tier (max one attack-driven advance per part per Moment-tick); **universal Clock-reset advancement**; Delayed skips exactly one; missing tiers filled (Crushed T3/T4, Burn T1 = cauterize + Shock T1 / T4 death, Exhausted T1–T3, Infected T1–T3); Suffocation/Dissolution stay tierless timers; "Suffocation Tier 1" items re-read as "delay 1 Clock" | A4, C8, E1, E2, E3, D3, E4 | R4 |
| A-7 | **Death & bleed-out fix:** death = head/torso 0 HP; bleed-out only via delayable conditions (Bleeding, Poison, Infection, Burn timer) — Helpless 1 Clock, any damage kills, delay/cure stabilizes at 0; direct damage/Crushed = immediate death; **Exhausted removed from the death list**; Bleeding T4 kills from any part | A1, A2 | R5 + R11 #12 |
| A-8 | **Advancement chapter (new — the biggest hole):** levels are GM-awarded at milestones; 1 level point/level → +1 on any one trait; creation = 7 Body + 7 Core, max 5, **1–5 scale is creation-only (stated)**; over-10 caps: Physique /5 → +1 part HP, Reflexes /12 → +1 allocatable physical resistance, Mind /15 → +1 psychic tier, Charm /20 → +1 Camera Call stack; skill points per trait = traitTotal − 1, multi-stat skills cost from each stat, refunds follow spend history; **no free respec ever** (items/Lounge only, at cost); XP variant flagged optional-future | B1, C3, C4, Q6 | R6 |
| A-9 | **Psychic resistance semantics:** tier N = immunity to psychic effects ≤N; Dissolution timer not tiered — each tier **slows it +1 Clock** | A3 | R6 |
| A-10 | **States glossary (new):** Helpless, Prone, Slowed, Channeling (=multi-Moment alias), Sizes (Small/Medium/Large/Huge on every combatant), Shock stacking `max(current+1, source_tier)` | B2–B4, B6, B7, E5 | R7 + R11 #4 |
| A-11 | **Shock rework:** momentary events, not a pool — stated tier applies directly; high-water mark per combat; repeat-part abuse elevates +1; T1 Shout / T2 Stutter / T3 Faint (Helpless 1 Clock + drop items) / T4 Helpless+Exposed rest of combat; **full reset at combat end, no decay**; Burn T1 → Shock T1 kept | E5, Q21 | R13 + decision #21 |
| A-12 | **Ranged weapons:** firing = 1 Moment delivers up to RPM rounds (split allowed in arc), listed damage per round; `magazine` stat (defaults light 6 / heavy 2); reload 2 Moments, both hands; multi-RPM item damage rebalance flagged (Spark-volver) | C5 | R8 |
| A-13 | **Dissolution completion:** mind collapses — the character is permanently removed from play, no revival; worse than death (the book keeps the fiction open: brainwashing/ghoul/puppet per the campaign — no god framing) | A2 | R5 amended |
| A-14 | **Grapple (new):** free hand + target ≤1 size larger; initiate 1 Moment auto if Physique ≥ target's, else Forced–Body; grappled can't reposition, both Exposed, grappler locked too; escape 2 Moments (1 if Physique ≥); Suffocation-by-grapple needs both hands + coverable airway; **bosses & ≥2-size-larger immune to grapple-Suffocation** | B5, D4 | R9 |
| A-15 | **Poison types & incompatibility:** the 5 types are the compatibility classes — different types = incompatible (Poison Soup), same type stacks tiers; Soup burst capped at part max HP − 1 on head/torso | B12, D5 | R10 |
| A-16 | **Requirements gate:** unmet requirements → Forced Action AND effect halved (round down) | D6 | R10 |
| A-17 | **Units:** 1 space = 1 hex (item "tiles" = spaces); "session" for per-session charges = one dungeon deployment (leave Lounge → return/extract/die) | B8, B9 | R10 |
| A-18 | **Healing & downtime (new):** in the field conditions only Delay/Resolve per treatments, HP never regenerates, applying a treatment costs a Moment, **no item restores HP**; at the Lounge HP restores fully + resolvable conditions resolve | B11, Q29 | R10 + 07-17 ruling |
| A-19 | **Reward contracts:** Directives pay tiered loot via Achievements; Goals that convert a new Patron pay Patron Tokens — one contract per system (replaces the three conflicting Directive texts) | A6 | R10 |
| A-20 | **Dodge thresholds (new, authored-ability pattern — not a universal dodge):** a threshold asks the dodger's Reflexes: ≥ threshold auto-dodges; else add the stat's threshold die (default 1d4); impossible if max < threshold; no dodging while Helpless/Exposed/Prone; conditions/collateral/environment never dodged; Dash counter ladder (Reflexes 7 sidestep / 9 counter) as the worked example | B15 partially, table's own homebrew | R22 |
| A-21 | **Weapon tiers & modifiers (promote session design):** Crude 0/0 → Exceptional 2/2 slots; modifier-tier ACCESS gated by weapon tier; extraction friction ladder; Lesser modifier list + flagged swaps (Padded/Reinforced out); Draining capped 1/Clock/target | — | R12 (compendium §3.2) |
| A-22 | **Skill architecture 0–10:** 0 revealed/unusable, 1 works, 1–5 stat scaling, 6–10 generalization ladder (more situations, stats keep scaling); cap 5 default, Patron Tokens raise to 10; thresholds keep Upgrade/Mutate at 5+ re-read under the ladder | — | R19 |
| A-23 | **Combined actions (new):** linked same-Moment declarations; each pays own cost; assists can satisfy a partner's requirements; merged damage counts as ONE hit for thresholds; a failing partner degrades (their d6 lands, partners still resolve); handoffs ride the inventory economy | — | R15 |
| A-24 | **Charm clarification:** Charm = presentability/photogenics (the camera-facing stat); warmth/likability live in the audience layer, not the number | — | R18 |
| A-25 | **Stealth & detection (new, table-adapted):** sight range ≈ 2× Mind with facing/cones (GM-adjudicated at table), seen = unstealthed; hearing → investigate or ALERTED (knows *something*, not where — enables decoys/scapegoats); disguise defeats recognition outside its range; cover blocks sight per real geometry (GM maps); Camouflage + Shock-Shout as the existing seeds. **The god-based destealth lever stays game-only.** | B10 | R20 minus setting |
| A-26 | **Enemy construction chapter (new GM guidance):** categories (Mob = one meaningful blow / Elite / Boss / Super Boss), asymmetric part HP is by design, discoverable boss win conditions doctrine, dodge-threshold + surface-immunity as authored patterns, encounter baseline (party of 5 ↔ ~12/room), reorganization beats | B15, Q44 partial | compendium §2.14 + live practice |
| A-27 | **Errata micro-fixes:** declare the stat-valued-range convention ("Range: Reflexes" = range equals current stat) (F2); items may deviate from class baselines (F4); terrain layer gets a named minimal list or is explicitly GM-fiat pending Q57 (F1); Controlled Sweep unlock reworded non-circularly (F7); "turn/round" vocabulary purged for Moments/Clocks (F9); Chill-damage skill errata (F9); action table floor "1–3" corrected to "0–3" (F10); Fang Cover gets a compliant poison statline (F3) | F1–F10 | review-1 |

### B. Owner decision points for the book (Phase 0 sitting — nothing above proceeds past draft without these)

| # | Decision | Recommendation |
|---|---|---|
| D-1 | R14 force-vs-robustness at the table? | **No for v0.92** — keep listed damage; revisit post-digital-playtest |
| D-2 | Boss-Token → Patron-Token exchange (cut in digital per R10/D7) | Cut in book too, or make it tier-aware; as-written it bypasses the audience metagame |
| D-3 | Camera Call self-targeting (D8) + exact "doubled" scope (Q37) | Rule it explicitly; digital reading (spotlit combatant's swings, one spotlight at a time) works at table |
| D-4 | Robot/AI race entry: keep as-is, or write real machine-condition rules (Q62 was closed only for the game) | Keep race; add a half-page "machines & conditions" sidebar |
| D-5 | Threshold-die upgrades (R22) at the table — what raises d4→d6→d8? | Achievement/Lounge purchases; GM-priced until the economy pass |
| D-6 | Tag list edition for the book | Book adopts `rulebook-tag-descriptions.md` verbatim (owner-authored); game's 84-tag pruned list stays game-only |
| D-7 | Remaining open questionnaire lines that gate book text: Q4 (achievement +1 stat → which field), Q5 (intended endgame totals), Q8 (upgrade vs mutate choice), Q15 (multi-stat level binding), Q31 (poison type differences), Q42 (tag mechanical effects), Q49–Q55 (economy/slots/hands), Q57 (terrain), Q63–Q67 (parts recovery, Lounge) | Answer in one sitting; anything unanswered ships as explicit "GM adjudicates" boxes rather than silence |
| D-8 | Where the book master lives | `docs/ttrpg/` in this repo (versioned, next to its sources) |

### C. Content errata pass (live DB + book examples, Phase 2)

- Cooldown-texted skills (Tactical Roll, Acrobatic Save, "-4 Moment cooldown"
  thresholds) → prime-gated re-expressions — **rides the owner's skill passover**.
- Item text sweeps: "Suffocation Tier 1" → delay wording; tiles → spaces; turn/round →
  Moment/Clock; Fang Cover poison contract; RPM items gain magazine values.
- Tag descriptions port into the campaign DB (empty `effect`/`description` fields) from
  `rulebook-tag-descriptions.md` — shared work with app backlog item 3.

## 3. Workstream B — the character-sheet app

Ground truth from a full code survey (2026-07-23). Architecture note that shapes all of
it: the server stores `state` as a Mixed blob and performs **no rules math or
validation** — every formula lives client-side, duplicated per tab. Backlog status
first, because it's mostly good news: **4 of the 5 known backlog items are already
implemented** (item uses/charges; player chat send in CommsTab — broadcast-only; player
tag picker from the DB master list; player-editable subtask checkboxes; RPM field on
items). What remains of them is polish, folded into B-4 below.

### B-1 Logic bugs (fix first; no rules decisions needed)

| # | Bug | Where |
|---|---|---|
| B-1a | **Combat Mode ignores the Physique HP bonus and `baseHp`** — BodyTab computes `effectiveMax = baseHp + hpBonus` while CombatModeTab displays/clamps on raw `maxHp`; BodyTab edits write `baseHp` only, so `maxHp` goes stale and the two tabs disagree on the same part | `CombatModeTab.jsx:6-20` vs `BodyTab.jsx:215-233` |
| B-1b | **Skill level-down refund counts from the CURRENT template's stat list** (`n = stats.length`), not the recorded `traitCosts` — a template edit after leveling orphans or over-refunds points; the true history is already in `traitCosts` | `SkillsTab.jsx:70-85` |
| B-1c | **Affliction resistances (chill/poison/infection) are unreachable** — rendered "admin-controlled" but no route or UI ever writes them; permanently 0 | `BodyTab.jsx:342-350` |
| B-1d | **Duplicated constants drifted**: InventoryTab hardcodes its own tier lists and a truncated category list (missing System Items / Key Items → players can't file items there); affix tiers exist in 4 copies; `traitTotal` in 5 copies | `InventoryTab.jsx:16,110,159` etc. |
| B-1e | New body parts created without `baseHp` (only `maxHp:3`), inconsistent with B-1a's scheme | `BodyTab.jsx:42` |
| B-1f | `capacity` default comes from three different fallbacks (enrich vs normalize vs UI) | `skillUtils.js:27,58` |
| B-1g | Verify I-14 (skill-enrichment render) is fully closed — recent commits (`_id`/`templateId` lookup + passive projection) suggest yes; confirm and close it | recent commits |

### B-2 Rules-alignment changes (from Workstream A; each cites its ruling)

| # | Change | Ruling |
|---|---|---|
| B-2a | **Damage-type vocabulary migration:** `DMG_TYPES = Crush/Bleed/Burn/Shock/Toxic/Psy` → the book taxonomy **Bleed/Crush/Burn/Chill/Poison/Infection** (Suffocation/Dissolution stay condition timers; Shock is the pain system, not a damage type). This makes damage types finally line up with the resistance keys the app already uses. **Requires a data migration** for item templates/instances using Shock/Toxic/Psy — script + mongodump, never hand edits | A-6 / R4 |
| B-2b | **Races list:** `Human/Cyborg/Android/Mutant/Alien/Clone/Hybrid/Synthetic` → book canon `Human / Animal / Robot-AI` + freetext species (live chars are "Sea Lion", "AI"). Explicitly NOT the game's Earth-life-only rule (D-4 confirms the sidebar text) | §0 + D-4 |
| B-2c | **Remove `cooldownRemaining` everywhere** (schema copies, admin routes, migrate) — dead field; cooldowns are removed from the system (NQ1). After the owner's skill passover, show each skill's **prime** (the 5-type vocabulary) from the template instead | A-5 / R3 |
| B-2d | **Condition tiers T4:** part-condition editor caps at T3; R4's filled tier tables go to T4 (Bleeding/Crushed/Burn death tiers). Also offer the canonical condition names as a picker (freetext stays available) | A-6 / R4 |
| B-2e | **Shock per R13:** keep tiers 0–4, add the high-water-mark semantic and a "Reset (combat end)" affordance mirroring the existing Camera Call session reset | A-11 / R13 |
| B-2f | **Skill level 0** ("revealed, untrained") displays properly, matching the 0–10 architecture; cap/token flow already matches (cap 5 default, Patron Tokens → 10, hard max 10 ✓) | A-22 / R19 |
| B-2g | **Magazine field** next to RPM on ranged items (defaults light 6 / heavy 2), reload note "2 Moments, both hands" — pending Q25 (does the table want ammo tracked?) | A-12 / R8, D-7 |
| B-2h | **Tag data backfill:** seed `description`/`effect` fields from `rulebook-tag-descriptions.md` (owner-authoritative). The game's 84-tag pruned list is NOT applied here | D-6 |

### B-3 Hardening (recommended, scoped small — it's the live campaign tool)

- Minimal server-side guards for the spend paths (level points, skill points, cap
  raises, bonus-point lock at level 2+) — today any client can POST arbitrary state; the
  compendium's own principle prefers typed sub-schemas over the Mixed blob. Do it
  field-by-field, not a big-bang schema rewrite.
- Single shared `traitTotal` + `effectiveMax` helpers imported everywhere (kills the
  5-copy drift class permanently).

### B-4 Polish (existing-feature completions, do last)

- CommsTab: recipient/whisper selector (route already supports `recipientId`, style).
- Admin PlayerPanel tag entry → same picker the player side already has.
- Optional: auto-decrement item uses on "use" click; Moment tracker display as 10→1
  countdown to match the book's presentation.
- Vestigial `statCapBonuses.dissolution/.cameraCall` keys: drop or document (values are
  recomputed live from Mind/Charm).

### B-5 Explicitly NOT applied to the app (no mix-ups)

Earth-life-only races · game tag cuts/renames · force-vs-robustness damage ·
run types/permadeath · patron-god anything (the app's "Top Patron" slots are audience
patrons — correct as-is) · engine-only systems (hype, antagonism, AI). The app models
the TTRPG book, full stop.

## 4. Sequencing

- **Phase 0 — Decision sitting (owner, ~1 hour):** table D-1…D-8 + the open Q-lines
  above. Everything else is unblocked mechanical work.
- **Phase 1 — Book draft (me):** build v0.92 from compendium §2 + table A-1…A-27, with
  per-change changelog. PROVISIONAL markers preserved where the digital ruling was
  playtest-pending, so the book inherits honest confidence levels.
- **Phase 2 — Content errata (me + owner passover):** §2.C. DB edits coordinate with the
  live campaign calendar (never break a session week).
- **Phase 3 — App changes (me):** §3, bugs first, then schema/vocab migrations behind a
  DB backup, then backlog features.
- **Phase 4 — Cross-validation (me):** three-way consistency table (book ↔ app ↔ digital
  addendum) committed as an appendix; the KAN-2 fixture test (criterion 16: app-identical
  derived stats for the five live sheets) is the anchor that all three agree on the
  advancement math.

## 5. Risks

- **The app is the LIVE campaign tool.** Every schema/vocab migration needs a mongodump
  backup + a dry-run against a copy; deploy between sessions.
- **Vocabulary migration touches stored data** (item damage classes, race strings) — not
  just constants; plan scripts, not hand-edits.
- **Divergence creep:** book and digital addendum will now share ~80% of rules text with
  deliberate differences (D-1 damage model, races, tags). The Phase-4 divergence table is
  the guard — every difference is either listed there or is a bug.
- **Owner bandwidth:** all Phase-0 items batched into one sitting, mirroring the
  questionnaire pattern that worked before.
