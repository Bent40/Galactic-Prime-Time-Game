# Skill Tiers — Per-Skill Shape Proposal

**Status: RULED — decision #35 (owner 2026-08-18, by number).** The 48 stamps and 8
recipes below **stand as proposed**; the five open questions were answered:

- **Q1 = route (a):** orphans stay LINEAR; the override mechanism is **authored
  Modification-Center special offers on broad-only pairs** — the three data-supported
  candidates (camouflage×nightlurking, feint×vibe_control, telekinesis×pressure_hold)
  entered as PROVISIONAL offers awaiting blessing. Taxonomy growth (route b) not adopted
  now.
- **Q2 = flat unlock + minimum fodder level:** ABSORB flat-unlocks the survivor's L6–8
  band, gated on a minimum fodder level **authored PER ABSORB** (the owner's fairness
  rationale: *"it might be unfair depending on skill stat dependency"* — mirroring Q5's
  per-recipe spirit). **⚠ Recorded-reading flag: this is the recorded interpretation of
  the ruling — correct it if "levels convert" was intended** (the decision-log #35 entry
  carries the same flag).
- **Q3 = tier-3 merges WILL exist** (*"for sure... We need a lot more skills"*): tier-2
  skills keep short linear bands FOR NOW, and the recipe schema must never forbid tier-2
  skills as future parents. Content-growth direction recorded.
- **Q4 = strong_strike + acrobatics CONFIRMED LINEAR for now** — owner intent recorded:
  they become mergeable later (revisit with the tier-3/content-growth wave).
- **Q5 = per-recipe min-levels** (no global convention; the proposed 5/3 pairs are each
  recipe's own authored values, changeable per recipe).

**ENABLEMENT SHIPPED (tier-2 enablement story):** the ruled machinery is now data +
forge operations — recipes M2–M8 + M8's mirrored animal-side twin in
`data/skill_mutations.json`, the 4 absorptions in `data/skill_absorptions.json`, the 3
PROVISIONAL offers in `data/mod_center_offers.json`,
`SkillForge.validate_absorption/apply_absorption/validate_offer`, validator coverage in
`scripts/validate_seeds.py`, tests in `tests/test_tier2_enablement.gd`, and addendum
ruling **R31**. Result skills are DATA-declared only (tier-2 rung content = next content
pass); result names and all min-level/min-fodder values stay PROVISIONAL; pricing stays
KAN-7.

The body below is preserved as proposed (it is now the ruled record). The data facts
(keyword compatibilities, row counts) were verified at proposal time.
**Directed by:** `docs/gdd/decision-log.md` **decision #34** (owner 2026-08-18, "Rule it
in") — the tier model's directed artifact: every skill stamped MERGE / ABSORB / LINEAR
with recipe/absorb candidates from the keyword data + the threshold re-map plan; ruled
by **decision #35**.
**How to answer: by number.** Stamp rows are **#1–#48**; merge recipes are **M1–M8**;
open questions are **Q1–Q5**. "1–10 yes, 11 absorb instead, Q2 = levels" is a complete
answer. *(Answered 2026-08-18 — see the status block above.)*
**Tabletop-shared:** skills are shared spine — the book already carries the merge rule
(`Galactic-Prime-Time/rulebook/gpt-system-v1.0.md` §4.5: keyword compatibility, the
Gemstone, the Intercept+Brace worked example). After the owner's pass this proposal syncs
to the TTRPG side; **this document does not touch the other repo.**
**Inputs:** decision-log #34 + the R19 framework rulings in entry #14 ·
`docs/design/skills-r19-ladders-FINAL.md` (43 ladders + tail annotations) ·
`data/skills.json` (48 rows) · `data/skill_thresholds.json` (88 rows) ·
`data/skill_keywords.json` (taxonomy: 9 broad groups / 31 narrow members; 49 entries) ·
`data/skill_mutations.json` (the shipped `iron_stance` recipe) ·
`simulation/skill_keywords.gd` (`compatible()`) · `docs/audits/skills-audit.md`.

---

## 1. The model restated (decision #34)

**Tier 1 = every skill's L1–5, authored deeply; L5 = mastery of the base form.** The L1–4
content pass is unaffected — it is identical under every shape. Past 5, each skill is
authored as exactly **one** of three shapes (per-skill, not universal):

| Shape | What it is | Cost/character |
|---|---|---|
| **MERGE** | Gemstone mutation: two narrow-compatible parents, **both consumed**, yielding a **tier-2 skill with its own L1–5** (the shipped `iron_stance` recipe is the canon: Intercept Lv 5 + Brace Lv 3 → Iron Stance Lv 1). | The expensive, identity-changing evolution. |
| **ABSORB** | Consume **one** compatible lesser skill to push the **survivor** into **L6–8**. Cheaper than a merge; the survivor keeps its identity. | The mid path. |
| **LINEAR 6–10** | An earned 6–10 band on the skill's own ladder — **reserved for skills ruled to deserve it**: magic's L10 rule-transcending tier stays source-gated (R19 framework ruling **#2**, entry #14); performance/signature skills carry the shared spectacle L10 (ruling **#6**). | The rare, no-consumption path. |

**Legality is the keyword tree (G3, load-bearing):** merge/absorb requires a shared
**NARROW** keyword (`SkillKeywords.compatible` → `narrow_shared`). A **broad-only** share
is *not* legal at the Gemstone — decision #34 maps broad-only pairs to **Modification
Center special offers** (authored, offered, never automatic; the recipe schema's
`compatibility_override` is the machine form). No overlap = incompatible.

**Consume/mutate capstones sit outside the ladder** (ruling **#5**): Elemental
Confluence's triple-consume unlock and any cap-10 growth stay Patron-Token-gated on a
separate axis — a LINEAR stamp on a ball/wall skill does **not** block its use as
Confluence fodder; consuming a parent is always exclusive with walking that parent's own
past-5 path.

**Supersession:** this model replaces the R19 framework's universal "6+ earned in-run /
cap-10 token-gated" shape. The authored L5+ threshold rows (78 at ruling time → **88**
today, after content Batch B added the five G6 skills' rows) re-map into tier-2 rungs and
absorb bonuses — **nothing is discarded** (§3).

**EXPLICITLY DEFERRED — tokens/economy:** what Patron Tokens gate under tiers (merge
fees, absorb fees, linear 6–10 unlock costs, Mod-Center offer pricing) is the **KAN-7
sitting's** decision. This proposal stamps shapes and re-maps content; **it prices
nothing.**

**Conventions used below (all PROVISIONAL):** new recipes follow the iron_stance pattern
— the identity-primary parent at **Lv 5** (its past-5 moment is the merge point), the
secondary at **Lv 3+** (Q5). All merged-skill names are placeholders for the owner to
rename. Magnitudes stay PLACEHOLDER per R14.

---

## 2. The per-skill stamp table — all 48 rows

**Distribution: 16 MERGE · 4 ABSORB · 28 LINEAR.** Grouped by the 9 broad keyword groups
(+ the one unassigned skill). Markers: **†** = data-only today (not yet in
`SkillBook.KNOWN_KEYS` — the shape is still a design fact, stamped now); **®** = one of
the four v2 display-rename skills (stamped under the **sim key**; the rename caution from
`skills-r19-ladders-FINAL.md` applies — mechanics under the sim key, display names
data-sourced, never baked into flavor text). Every claimed pair below is
**verified against `data/skill_keywords.json`** (§4); shared narrow keyword in
parentheses.

### MAGIC (10) — all LINEAR per ruling #2

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 1 | `poison_ball` † | **LINEAR** | Magic: authored 6–10 with the rule-transcending, source-gated L10 (ruling #2; ladder #10 — Cytotoxic bloom). | No consumption needed. Legal partners if ever wanted: poison_wall (toxin), elemental_confluence (toxin). Confluence consume-parent (ruling #5). |
| 2 | `poison_wall` † | **LINEAR** | Magic (ruling #2); ladder #11's toxic-storm L10 is source-gated. | Legal partners: poison_ball (toxin), elemental_confluence (toxin). |
| 3 | `frost_ball` † | **LINEAR** | Magic (ruling #2); absolute-zero L10 source-gated (ladder #12). | Legal partners: frost_wall (cold), elemental_confluence (cold). Confluence consume-parent. |
| 4 | `frost_wall` † | **LINEAR** | Magic (ruling #2); glacier L10 source-gated (ladder #13). | Legal partners: frost_ball (cold), elemental_confluence (cold). |
| 5 | `fire_ball` † | **LINEAR** | Magic (ruling #2); radiant-fire L10 source-gated (ladder #14; R2: no "Explosion" skill exists). | Legal partners: fire_wall (fire), elemental_confluence (fire). Confluence consume-parent. |
| 6 | `fire_wall` † | **LINEAR** | Magic (ruling #2); inferno L10 source-gated (ladder #15). | Legal partners: fire_ball (fire), elemental_confluence (fire). |
| 7 | `elemental_confluence` † | **LINEAR** (qualified) | Already a **tier-2 consume result** (three L5 masteries consumed — the second shipped consume precedent). Past its own L5: **no earned 6–9 band**; growth = discrete Patron-Token cap-raises per ruling #5 (off-ladder). | No further recipe proposed. See Q3 (tier-2 continuation). |
| 8 | `telekinesis` † | **LINEAR** | Magic (ruling #2); psychic-force L10 (boss-pin breach window) source-gated. Also a de-facto orphan: sole `force` carrier. | No narrow partner in the data (verified). `control`-broad share with pressure_hold = Mod-Center offer tier only. |
| 9 | `telepathy` † | **LINEAR** | Magic (ruling #2); the manipulation lane (R3 ruling: read→write→influence→R5-gated collapse) is authored as its own 6–10. | Legal partner: mind_burst (psychic) — merge NOT recommended: both L10s carry ruled, R5-gated content that presupposes their own ladders. |
| 10 | `mind_burst` † | **LINEAR** | Magic (ruling #2); the L10 mind-shatter is *the* ruled example of really-high-tier-magic-only (entry #14, R3). | Legal partner: telepathy (psychic) — same caution as #9. Keeps its "Telepathy Lv 3" prereq. |

### STRIKES (12)

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 11 | `controlled_sweep` | **ABSORB** | Identity is the anti-swarm arc (audit: engine-expressible wave-clear) — absorption keeps it itself while buying the ladder's L6–8 situations. | Targets: **pounce** (blade — the absorbed leap lets the arc originate off-center / a step out, ladder L8–9) or **slice_n_dice** (blade — the twin-arc widens the sweep). Adds at L6–8: on-kill splash (row id 2), Elite-catching, rider-spreading. |
| 12 | `strong_strike` | **LINEAR** | Its L10 "reliable breach" is a ruled systemic role — the designed **mundane answer to Surface-Immunity bosses** (ladder #4, F2 lineage); keeping it earnable without eating a second skill keeps the boss-counter accessible. Zero threshold rows to re-map. | Legal partners exist (power: overhead_slam, execution, heroic_punch) — see **Q4** (discretionary linear). |
| 13 | `counter_surge` | **MERGE → M2** | "They shouldn't have gone flashy in front of you" — the counter IS a read made violent; fusing with the read that feeds it is the identity endpoint. | Partners: **read_the_pattern (patterning)** — best; decapitate (precision); pressure_strike (precision). Recipe M2 "Counterscript". |
| 14 | `pounce` | **MERGE → M3** | Sasha's opener; its ladder tops out as a combo-enabler — the natural tier-2 is the leap fused with the kill it opens. Chain note: the tier-2 counts as Pounce for Slip Through's gate (authored loosening, ruling #4). | Partners: **decapitate (blade)** — best (decapitate already requires Pounce Lv 5); acrobatics (leaping); slice_n_dice (blade). Recipe M3 "Predator's Arc". |
| 15 | `decapitate` | **MERGE → M3** | The chain finisher's own ladder (L9 chain-release, L10 highlight-reel kill) is exactly what a fused leap-to-kill tier-2 delivers. | Partner: **pounce (blade)** — recipe M3; alts: counter_surge / pressure_strike (precision), thousand_cuts (blade). |
| 16 | `overhead_slam` | **MERGE → M4** | The wind-up that downs them + the finisher that ends them share **two** narrows (blunt+power) — the heavy chain's opener and finisher fuse into one gravity arc. | Partner: **execution (blunt+power)** — best pair in the power cluster (execution already requires Overhead Slam Lv 5); alts: shockwave (blunt), strong_strike (power). Recipe M4 "Earthbreaker". |
| 17 | `shockwave` | **ABSORB** | The link keeps its identity (the cone/ring tremor) and internalizes its own opener — absorbing the slam satisfies its chain gate from within (authored loosening, ruling #4). | Targets: **overhead_slam** (blunt — standalone tremor; row id 44's 360° ring lands at L6) or **execution** (blunt). Adds at L6–8: full ring, remote tremor, Elite forced-action (ladder). |
| 18 | `execution` | **MERGE → M4** | See #16 — the finisher's L6 row ("impact triggers a free Shockwave") is already tier-2-rung material. | Partner: **overhead_slam (blunt+power)** — recipe M4; alts: shockwave (blunt), strong_strike / heroic_punch (power). |
| 19 | `pressure_strike` | **ABSORB** | The feint-chain link **cannot** merge inside its own chain (feint shares no keyword with it — verified); absorption keeps the tempo-strike identity and generalizes its opening. | Targets: **counter_surge** (precision — the interrupt instinct → fires off ANY Forced-Action opening, ladder L8, incl. an ally's feint per R15) or **decapitate** (precision). Row id 50 lands at L6 (⚠ re-expressed, see §3). |
| 20 | `thousand_cuts` | **MERGE → M5** | Shares **blade+flurry** with slice_n_dice — the strongest pair in the whole dataset (the only 2-narrow pair outside M4); both are bleed-stacking flurries. Zero threshold rows; its 6–10 exists only as ladder rungs — the merge gives that content a home. | Partner: **slice_n_dice (blade+flurry)** — recipe M5 "Vivisection"; alts: pounce / decapitate / controlled_sweep (blade). |
| 21 | `heroic_punch` ® | **LINEAR** | Performance/signature per ruling **#6**: carries the authored spectacle L10 (Camera-Call-tier Cinematic Kill, Charm scales the payoff) — Mario's character-locked signature. | Legal partners (power: strong_strike, overhead_slam, execution) noted, not recommended — consuming a signature into a merge erases the ruled spectacle capstone. Rename pending (→ Champion's Fist). |
| 22 | `slice_n_dice` ® | **MERGE → M5** | Sasha's core; its L6 row (Bleed T2) and the ladder's bleed-to-death L10 are the same fantasy Vivisection completes. | Partner: **thousand_cuts (blade+flurry)** — recipe M5; alts: pounce / decapitate / controlled_sweep (blade). Rename pending (→ Twin Fangs / Crossing Cuts). |

### MOVEMENT (5)

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 23 | `quick_step` † | **LINEAR** | Orphan: sole `rushing` carrier — no legal partner exists (verified). Traversal utility generalizes continuously (ladder #2, flow-state L10). | None legal. Broad-only movement shares (tactical_roll, acrobatics, dance) = Mod-Center offer tier only (Q1). |
| 24 | `tactical_roll` | **MERGE → M6** | Both defensive reactions, both R25 STANCE/movement-forfeit-gated, both `tumbling` — two halves of "you can't pin me down" fuse into the complete evasion suite. | Partner: **acrobatic_save (tumbling)** — recipe M6 "Perfect Evasion"; alts: slip_through, acrobatics (tumbling). |
| 25 | `slip_through` | **ABSORB** | The chain's link survives its merging neighbors (it shares **no** keyword with pounce or decapitate — verified); absorbing a tumbling reaction pushes the dash to L6–8 without losing the chain identity. | Targets: **tactical_roll** (tumbling — the reactive dodge feeds the dash; row id 38's reposition-anywhere lands at L6) or **acrobatics** (tumbling — slip through anything, ladder L8). |
| 26 | `acrobatic_save` † | **MERGE → M6** | See #24 — its L6 row (negate a Forced Action — Body once per Clock) is a tier-2 rung of the fused evasion suite. | Partner: **tactical_roll (tumbling)** — recipe M6; alts: slip_through, acrobatics. |
| 27 | `acrobatics` † | **LINEAR** | Always-on traversal passive (ladder #42 generalizes as a passive to the free-runner L10); fusing it away would delete the always-on utility mid-run. | Legal partners exist (tumbling: tactical_roll, slip_through, acrobatic_save; leaping: pounce) — see **Q4** (discretionary linear). |

### PERFORMANCE (6)

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 28 | `feint` | **LINEAR** | Orphan: sole `deception` carrier (verified) — its own chain-mates share nothing with it. Its authored 6–10 (total-misdirection L10, mundane) stands alone. | None legal. Broad-only performance shares (vibe_control, dance, juggling, voicebox, play_to_the_camera) = Mod-Center offer tier (Q1). |
| 29 | `vibe_control` †® | **LINEAR** | Performance per ruling **#6**: authored spectacle L10 (mass fixate/rout; Charm scales the crowd payoff). | Legal partners: dance, play_to_the_camera (presence) — not recommended (both carry their own ruled #6 capstones). Missing its L6 row (audit) — author it in place. Rename pending (→ Presence / Hold the Room). |
| 30 | `juggling` † | **LINEAR** | Performance per ruling **#6** (spectacle L10: the continuous juggling act) — and an orphan besides: sole `throw` carrier; even telekinesis shares nothing literal (verified: basis `none`). | None legal. Uniquely already has an L7 row (id 58) — a head start on the linear band. |
| 31 | `dance` | **LINEAR** | Performance per ruling **#6** (spectacle L10: the Camera-Call-tier crowd moment; Reflexes executes, Charm pays). | Legal partners: vibe_control, play_to_the_camera (presence) — noted, not recommended. |
| 32 | `voicebox` † | **LINEAR** | Deception lane, deliberately **not** spectacle (ladder note) — and an orphan in-sim: its only narrow partner (`sound`: ignore_all_previous_commands) is **cut from the game** (G5, table-canon only). | None legal in-sim (verified). Table-side, the sound pair exists — a TTRPG-only recipe is possible after sync (owner's call there, not here). |
| 33 | `play_to_the_camera` †® | **LINEAR** | THE audience skill (Camera-Call-stack spender, G6) — under ruling **#6** its L10 is almost definitionally the spectacle capstone; no authored ladder yet (postdates R19), so linear authoring is the direct path. | Legal partners: vibe_control, dance (presence) — noted as alternates if the owner prefers a broadcast tier-2. Rename pending (→ Play to the Gallery / Work the Odds). |

### SURVIVAL (6)

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 34 | `seal_the_wound` † | **MERGE → M7** | The self/adjacent condition-delayer and the ally-ranged kit medic are one archetype split in two (both `treatment`); the fused tier-2 IS the arena medic the ladder's L7–L10 describes (arrest, ranged triage, stabilize — all default-#8-safe: delay/manage only, never HP, never full cure). | Partner: **field_triage (treatment)** — recipe M7 "Combat Medic" (only legal partner; verified). Alt shape if the owner prefers cheap: seal ABSORBS triage (or vice-versa for a support build). |
| 35 | `brace` | **MERGE → M1 (shipped)** | Decision #34 names it: the merge is canonical, R1's fold-into-Brace is **retired**. Brace is the Lv-3+ secondary parent of the shipped recipe. Its L6 row's content (extends to Bleed/Chill) is *already shipped* as Iron Stance's L4 effect — the re-map mechanism, proven live. | Partner: **intercept (bracing)** → `iron_stance` (`data/skill_mutations.json`). No other stamp is possible without contradicting shipped data. |
| 36 | `swim` † | **LINEAR** | Orphan: sole `aquatic` carrier (verified). Passive environment-generalizer (ladder #30, amphibious-apex L10 with the R9 suffocation caps). | None legal. Broad-only survival shares = Mod-Center tier (Q1). |
| 37 | `intercept` | **MERGE → M1 (shipped)** | The canonical example: Intercept **Lv 5 is the merge point** (decision #34 verbatim); primary parent of the shipped recipe. | Partner: **brace (bracing)** → `iron_stance`. Its L6 row ("guard two allies") re-maps as an iron_stance tier-2 rung (§3). |
| 38 | `iron_stance` | **LINEAR** (tier-2 band) | Already the tier-2 merge result with its own L1–5 **and** an authored L6 row — a short linear continuation of the merged identity is the honest default; its only narrow kin are its own consumed parents. | No further recipe proposed. See **Q3** (tier-2 continuation / no tier-3 for now). |
| 39 | `field_triage` † | **MERGE → M7** | See #34. Its L6 row (once per combat, fully resolve a condition) is the fused medic's signature rung — big enough that it should cost a merge, not ride a lone skill's linear band. | Partner: **seal_the_wound (treatment)** — recipe M7 (only legal partner; verified). |

### CONTROL (2)

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 40 | `pressure_hold` | **MERGE → M8** | The hand-grapple and the jaw-grapple are one identity with two anatomies (`grapple` shared); the fused hold is the perfected grapple regardless of body plan — R9's boss/size Suffocation caps ride along uncut. | Partner: **death_grip_jaws (grapple)** — recipe M8 "Vice Grip" (only legal partner; verified). |
| 41 | `death_grip_jaws` | **MERGE → M8** | The animal-body grapple (audit: load-bearing for handless bodies); its L6 bleed-per-Clock rider becomes a Vice Grip rung. For animal characters the mirrored recipe (jaws Lv 5 + hold Lv 3) may be wanted — noted under M8. | Partner: **pressure_hold (grapple)** — recipe M8 (only legal partner). |

### PERCEPTION (2)

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 42 | `read_the_pattern` † | **MERGE → M2** | The read that exists to be acted on fuses with the counter that acts on it (`patterning` shared — verified); the tier-2 keeps the intel role and weaponizes it (ladder #6 L7 "share the read" and L9 boss-tells become tier-2 rungs). | Partner: **counter_surge (patterning)** — recipe M2 "Counterscript" (only legal partner; verified). Consuming Nikita's intel tool is a real cost — the alt is counter_surge ABSORBING it instead (cheaper, keeps `read_the_pattern` gone either way once consumed; the no-consumption alternative is stamping both LINEAR, which #34 reserves for ruled cases). |
| 43 | `aura_reading` † | **LINEAR** | Orphan: sole `empathy` carrier (verified). Ladder #29 deliberately keeps it in the FEELING lane (never actions/thoughts) — a lane that must not converge is a lane that must not merge. | None legal. Broad-only perception share with read_the_pattern = Mod-Center tier (Q1). |

### INFILTRATION (3) — a family with zero legal merges

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 44 | `nightlurking` † | **LINEAR** | Orphan: `awareness`+`squeezing`, both unique (verified). Sasha's traversal-intel passive; ladder #40 authored full (escape-artist L10). | None legal. The infiltration trio shares **broad only**, pairwise — the poster family for Mod-Center special offers (Q1; e.g. nightlurking × camouflage "The Unseen"). |
| 45 | `lockpicking` † | **LINEAR** | Orphan: sole `locks` carrier (verified). Its data is already a linear tier ladder (Simple→Moderate→Complex→Magical). | None legal (broad-only kin: camouflage, nightlurking — Q1). |
| 46 | `camouflage` † | **LINEAR** | Orphan: sole `stealth` carrier (verified). The R20 stealth engine's skill-side consumer; ladder #44 authored full (ghost L10, mundane). | None legal (broad-only kin as above — Q1). |

### CRAFT (1)

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 47 | `full_potential` † | **LINEAR** | Orphan: sole carrier of `repair` **and** `improvisation` — the entire craft group (verified). Mario's character-locked kit skill; ladder #38 authored full (masterwork L10, R12-economy-flagged). | None legal. No broad kin either (sole craft skill) — the hardest orphan in the file (Q1). |

### UNASSIGNED (1)

| # | skill | shape | rationale | candidates / notes |
|---|---|---|---|---|
| 48 | `reversion` † | **LINEAR** (N/A — **NPC-content**) | Ladder default #7: NPC-only, no player 0–10 track — its "levels" are the owner-authored per-encounter escalation beats E1–E5. It also has **no ruled keywords** (`skill_keywords.json` `_meta.unassigned`; flagged, not invented here) → compatible with nothing; merge/absorb impossible by data. | No candidates possible. Note the #33 tension: the G7 acquisition gate means a player COULD in principle earn it — if that ever happens, the escalation beats, not a 6–10 band, remain the authoring surface (owner's call then, not now). Zero threshold rows. |

### The proposed merge recipes (M1–M8) — all verified `narrow_shared`

Names PROVISIONAL. Min-levels follow the iron_stance pattern (primary Lv 5 + secondary
Lv 3 — Q5). Every pair verified against `data/skill_keywords.json` via the
`SkillKeywords.compatible` logic; **none needs a `compatibility_override`.**

| # | recipe (parents → result) | shared narrow | one-line identity of the tier-2 |
|---|---|---|---|
| **M1** | **Intercept Lv 5 + Brace Lv 3 → Iron Stance** — **SHIPPED** (`data/skill_mutations.json`; book §4.5 canonical example) | bracing | The mobile bodyguard consumes the self-brace and becomes the rooted bulwark. |
| **M2** | Counter-Surge Lv 5 + Read The Pattern Lv 3 → **"Counterscript"** | patterning | You don't read the pattern and then counter — every declared action near you is already an opening you answer. |
| **M3** | Pounce Lv 5 + Decapitate Lv 3 → **"Predator's Arc"** | blade | The leap and the kill are one motion — the apex-predator takedown that still opens/loops through Slip Through (authored chain rung, ruling #4). |
| **M4** | Overhead Slam Lv 5 + Execution Lv 3 → **"Earthbreaker"** | blunt + power | Down them and end them in a single gravity arc; counts as Overhead Slam for Shockwave's chain gate (authored rung, ruling #4). |
| **M5** | Slice n' Dice Lv 5 + Thousand Cuts Lv 3 → **"Vivisection"** | blade + flurry | The complete shredder — many wounds on many parts, every wound worsening; the bleed-out clock made a skill. |
| **M6** | Tactical Roll Lv 5 + Acrobatic Save Lv 3 → **"Perfect Evasion"** | tumbling | The whole evasion suite in one stance — dodge-move and forced-action save fused (both stay R25 movement-forfeit-gated). |
| **M7** | Seal The Wound Lv 5 + Field Triage Lv 3 → **"Combat Medic"** | treatment | The arena medic: anyone, anywhere, conditions held — delay/arrest/stabilize only, never HP, never a full cure (default #8). |
| **M8** | Pressure Hold Lv 5 + Death Grip Jaws Lv 3 → **"Vice Grip"** | grapple | The perfected hold regardless of anatomy — hands, jaws, whatever you have (R9 size/boss caps uncut). A mirrored animal-side recipe (Jaws Lv 5 + Hold Lv 3) is a cheap authored twin if wanted. |

**Excluded from the 48 by data:** `generate_visual_media` and
`ignore_all_previous_commands` are table-canon only (cut from the game, G5) — they carry
keywords in `skill_keywords.json` but have no `skills.json` rows and are not stamped
here.

---

## 3. The threshold re-map plan (88 rows — nothing discarded)

**Dispositions** (per decision #34: the L5+ rows re-map into tier-2 rungs and absorb
bonuses, nothing discarded):

- **STAYS-LINEAR (unchanged)** — the row stays at its authored level on its skill's own
  ladder. This covers **every L5 row regardless of shape** (L5 is *inside* Tier 1 —
  decision #34 makes L5 the mastery rung, untouched by the tier model) and every row of a
  LINEAR-stamped skill.
- **BECOMES-TIER-2-RUNG** — the row's content moves into the named merged skill's own
  L1–5/rung table (exact rung placement is tier-2 authoring, done at content-pass time).
- **BECOMES-ABSORB-BONUS** — the row's content becomes the survivor's L6–8 bonus at the
  stated level, unlocked by the absorption.

**Summary counts:**

| disposition | rows | breakdown |
|---|---|---|
| STAYS-LINEAR | **69** | 44 L5 mastery rows (all 44 skills that have rows — in place under every shape) + 24 L6 rows on LINEAR-stamped skills + juggling's L7 (id 58) |
| BECOMES-TIER-2-RUNG | **15** | the L6 rows of the 15 MERGE-stamped skills that have rows (thousand_cuts has none) |
| BECOMES-ABSORB-BONUS | **4** | the L6 rows of the 4 ABSORB-stamped skills |
| **total** | **88** | nothing discarded ✓ |

Rows-per-skill facts (verified): 44 skills carry rows (44×L5); 43 carry an L6
(vibe_control has L5 only — its missing L6 is an audit item, authored in place under its
LINEAR stamp); juggling alone carries an L7. Four skills carry **no** rows at all
(strong_strike, telepathy, thousand_cuts, reversion) — for them the re-map is vacuous;
their past-5 content is authored fresh from the R19 ladder rungs under their stamps.

**Two flags carried into the re-map (default #2 — no resistance-bypass outside magic):**
row **id 42** ("+4 Crush. Ignores 3 Resistance") and row **id 50** ("The hit ignores
resistance completely") are non-magic resistance-bypasses; they re-map **re-expressed**
(as added force through the R14 gate, not a bypass) — content kept, wording fixed, per
the same discipline that demoted Execution's draft L10.

**Shipped precedent:** brace's L6 row content ("works against Bleeding and Chill") is
already live as Iron Stance's **L4** effect in `data/skills.json` — the
BECOMES-TIER-2-RUNG mechanism has an existing, working example.

### Appendix — per-row disposition (all 88)

| id | skill | L | row gist | disposition |
|---|---|---|---|---|
| 1 | controlled_sweep | 5 | attack all adjacent positions | STAYS-LINEAR (Tier-1 L5 mastery) |
| 2 | controlled_sweep | 6 | on-kill splash to out-of-reach Mobs | **ABSORB-BONUS @L6** (survivor: controlled_sweep) |
| 3 | quick_step | 5 | +4 duration | STAYS-LINEAR (Tier-1 L5) |
| 4 | quick_step | 6 | ignore physical terrain effects | STAYS-LINEAR |
| 5 | seal_the_wound | 5 | +3 Clock; resolve Infection | STAYS-LINEAR (Tier-1 L5) |
| 6 | seal_the_wound | 6 | resolve Infection, Bleed or Crush | **TIER-2-RUNG → M7 Combat Medic** (audit fix rides along: drop Crush — not a treatable condition) |
| 7 | counter_surge | 5 | reduce remaining cost by 5 | STAYS-LINEAR (Tier-1 L5) |
| 8 | counter_surge | 6 | non-collapsed action can't affect you 3 Moments | **TIER-2-RUNG → M2 Counterscript** |
| 9 | read_the_pattern | 5 | +4 actions foreseen | STAYS-LINEAR (Tier-1 L5) |
| 10 | read_the_pattern | 6 | read a second enemy | **TIER-2-RUNG → M2 Counterscript** |
| 11 | pressure_hold | 5 | 4 movement/Moment while holding | STAYS-LINEAR (Tier-1 L5) |
| 12 | pressure_hold | 6 | 5 move/Moment or suffocate within 1 Clock | **TIER-2-RUNG → M8 Vice Grip** (R9 suffocation gates apply — audit) |
| 13 | brace | 5 | reduce damage by 5 | STAYS-LINEAR (Tier-1 L5) |
| 14 | brace | 6 | works vs Bleeding and Chill | **TIER-2-RUNG → M1 Iron Stance** (already shipped as its L4 effect) |
| 15 | tactical_roll | 5 | +2 space, −1 Moment chained | STAYS-LINEAR (Tier-1 L5) |
| 16 | tactical_roll | 6 | usable twice per chain | **TIER-2-RUNG → M6 Perfect Evasion** (re-express the chain/cooldown wording per R25 at authoring) |
| 17 | poison_ball | 5 | +2 space, +10 range | STAYS-LINEAR (Tier-1 L5) |
| 18 | poison_ball | 6 | choose poison type | STAYS-LINEAR |
| 19 | poison_wall | 5 | +4 space | STAYS-LINEAR (Tier-1 L5) |
| 20 | poison_wall | 6 | choose poison type | STAYS-LINEAR |
| 21 | frost_ball | 5 | +2 damage, +2 area | STAYS-LINEAR (Tier-1 L5) |
| 22 | frost_ball | 6 | hit enemies pinned 5 Moments | STAYS-LINEAR |
| 23 | frost_wall | 5 | +8 wall HP | STAYS-LINEAR (Tier-1 L5) |
| 24 | frost_wall | 6 | wall healed by chill damage | STAYS-LINEAR |
| 25 | fire_ball | 5 | +4 burn damage | STAYS-LINEAR (Tier-1 L5) |
| 26 | fire_ball | 6 | cluster balls | STAYS-LINEAR |
| 27 | fire_wall | 5 | +4 space | STAYS-LINEAR (Tier-1 L5) |
| 28 | fire_wall | 6 | passers take Shock T2 | STAYS-LINEAR |
| 29 | elemental_confluence | 5 | +2 space, +10 range | STAYS-LINEAR (Tier-1 L5) |
| 30 | elemental_confluence | 6 | redeploy the field once | STAYS-LINEAR (token-gated axis per ruling #5 — Q3) |
| 31 | telekinesis | 5 | +12 range | STAYS-LINEAR (Tier-1 L5) |
| 32 | telekinesis | 6 | no longer Exposed while sustaining | STAYS-LINEAR (reconcile with the inline L6 text — audit) |
| 33 | mind_burst | 5 | +20 range | STAYS-LINEAR (Tier-1 L5) |
| 34 | mind_burst | 6 | multiple targets in range | STAYS-LINEAR |
| 35 | pounce | 5 | +2 damage, +2 space | STAYS-LINEAR (Tier-1 L5) |
| 36 | pounce | 6 | self-chain up to ×4 at 1 Moment | **TIER-2-RUNG → M3 Predator's Arc** |
| 37 | slip_through | 5 | +4 damage | STAYS-LINEAR (Tier-1 L5) |
| 38 | slip_through | 6 | reposition anywhere within 2 of target | **ABSORB-BONUS @L6** (survivor: slip_through) |
| 39 | decapitate | 5 | +4 Bleed | STAYS-LINEAR (Tier-1 L5) |
| 40 | decapitate | 6 | may chain to another Slip Through | **TIER-2-RUNG → M3 Predator's Arc** |
| 41 | overhead_slam | 5 | +4 Crush | STAYS-LINEAR (Tier-1 L5) |
| 42 | overhead_slam | 6 | +4 Crush, ignores 3 Resistance | **TIER-2-RUNG → M4 Earthbreaker** ⚠ re-expressed (default #2 — no non-magic bypass) |
| 43 | shockwave | 5 | +2 Crush, +2 space | STAYS-LINEAR (Tier-1 L5) |
| 44 | shockwave | 6 | circle instead of cone | **ABSORB-BONUS @L6** (survivor: shockwave — matches ladder L6 "full ring") |
| 45 | execution | 5 | +8 damage | STAYS-LINEAR (Tier-1 L5) |
| 46 | execution | 6 | impact triggers a free Shockwave | **TIER-2-RUNG → M4 Earthbreaker** (audit rewording rides along) |
| 47 | feint | 5 | +2 space, +2 die, choose result | STAYS-LINEAR (Tier-1 L5) |
| 48 | feint | 6 | chained Pressure Strike twice in one Moment | STAYS-LINEAR |
| 49 | pressure_strike | 5 | +2 Bleed, +2 space | STAYS-LINEAR (Tier-1 L5) |
| 50 | pressure_strike | 6 | hit ignores resistance completely | **ABSORB-BONUS @L6** ⚠ re-expressed (default #2) |
| 51 | aura_reading | 5 | +4 range | STAYS-LINEAR (Tier-1 L5) |
| 52 | aura_reading | 6 | reveals lying / suppressed emotion | STAYS-LINEAR |
| 53 | swim | 5 | +1 movement | STAYS-LINEAR (Tier-1 L5) |
| 54 | swim | 6 | +2 Clocks suffocation grace; water not difficult terrain | STAYS-LINEAR |
| 55 | vibe_control | 5 | +2 range | STAYS-LINEAR (Tier-1 L5; the missing L6 row is authored in place — audit) |
| 56 | juggling | 5 | +12 range | STAYS-LINEAR (Tier-1 L5) |
| 57 | juggling | 6 | catch a thrown attack, negate its damage | STAYS-LINEAR |
| 58 | juggling | 7 | pick 2 targets | STAYS-LINEAR (the file's only L7) |
| 59 | dance | 5 | +1 Charm | STAYS-LINEAR (Tier-1 L5) |
| 60 | dance | 6 | +1 Charm aura for allies within 2 | STAYS-LINEAR |
| 61 | voicebox | 5 | +1 strength | STAYS-LINEAR (Tier-1 L5) |
| 62 | voicebox | 6 | fools machinery / voice recognition | STAYS-LINEAR |
| 67 | acrobatic_save | 5 | +4 die | STAYS-LINEAR (Tier-1 L5) |
| 68 | acrobatic_save | 6 | negate Forced Action — Body once per Clock | **TIER-2-RUNG → M6 Perfect Evasion** |
| 69 | full_potential | 5 | Crude/Basic +1 use; Quality craftable | STAYS-LINEAR (Tier-1 L5) |
| 70 | full_potential | 6 | Quality items; creations permanent | STAYS-LINEAR |
| 71 | heroic_punch | 5 | +4 Crush | STAYS-LINEAR (Tier-1 L5) |
| 72 | heroic_punch | 6 | damage adds onto Martial Arts skills | STAYS-LINEAR ("Martial Arts" category undefined — audit item, resolve at authoring) |
| 73 | nightlurking | 5 | +20 range | STAYS-LINEAR (Tier-1 L5) |
| 74 | nightlurking | 6 | 5 km minimap; rat-hole squeeze | STAYS-LINEAR (scale fix per audit: district-level, not km) |
| 75 | lockpicking | 5 | Complex locks; −1 Moment | STAYS-LINEAR (Tier-1 L5) |
| 76 | lockpicking | 6 | Magical locks; −1 Moment all tiers | STAYS-LINEAR |
| 77 | acrobatics | 5 | +1 movement, +1 safe fall | STAYS-LINEAR (Tier-1 L5) |
| 78 | acrobatics | 6 | +1 jump; mid-jump direction change | STAYS-LINEAR |
| 79 | slice_n_dice | 5 | +2/+1 Bleed; 2 Bleed on Head hit | STAYS-LINEAR (Tier-1 L5) |
| 80 | slice_n_dice | 6 | apply Bleed Tier 2 instead | **TIER-2-RUNG → M5 Vivisection** |
| 81 | camouflage | 5 | −4 reveal space | STAYS-LINEAR (Tier-1 L5) |
| 82 | camouflage | 6 | move one space without breaking | STAYS-LINEAR |
| 83 | intercept | 5 | −2 physical damage when intercepting | STAYS-LINEAR (Tier-1 L5 — the shipped recipe's merge point) |
| 84 | intercept | 6 | guard two allies | **TIER-2-RUNG → M1 Iron Stance** |
| 85 | death_grip_jaws | 5 | drag the hold 2 spaces/Moment | STAYS-LINEAR (Tier-1 L5) |
| 86 | death_grip_jaws | 6 | bitten part takes 1 Bleed per Clock reset | **TIER-2-RUNG → M8 Vice Grip** |
| 87 | field_triage | 5 | treat at 2 spaces of range | STAYS-LINEAR (Tier-1 L5) |
| 88 | field_triage | 6 | once per combat, fully resolve the condition | **TIER-2-RUNG → M7 Combat Medic** |
| 89 | iron_stance | 5 | stance damage reduction −3 | STAYS-LINEAR (Tier-1 L5 of the tier-2 skill) |
| 90 | iron_stance | 6 | +1 Moment for enemies moving past you | STAYS-LINEAR (tier-2 band — Q3) |
| 91 | play_to_the_camera | 5 | +3 Moments; surge survives a hit | STAYS-LINEAR (Tier-1 L5) |
| 92 | play_to_the_camera | 6 | losses no longer double during the surge | STAYS-LINEAR |

*(Row ids 63–66 do not exist in the data — the id sequence skips them, matching the two
G5-cut skills; 88 rows total, verified by script.)*

---

## 4. Consistency checks — done and reported

1. **Every claimed compatibility verified against the data.** A throwaway script
   mirroring `SkillKeywords.compatible()` (narrow_shared / broad_only / none, literal
   shared keywords) ran **54 pairwise checks** over `data/skill_keywords.json` plus a
   **full 48-skill partner scan**. Results: **8/8 recommended merge recipes are
   `narrow_shared` — zero recipes need a `compatibility_override`**; **8/8 absorb
   candidate pairs are `narrow_shared`**; all alternate-partner claims in §2 verified.
   Two of my pre-check expectations were corrected *by* the data and are reported as the
   data has them: pressure_strike × thousand_cuts = `broad_only` (shared broad
   `strikes`), and telekinesis × pressure_hold = `broad_only` (shared broad `control`) —
   both are therefore Mod-Center-offer-tier pairs, not incompatible ones. No illegal pair
   is proposed anywhere in this document.
2. **No skill left shapeless:** 48/48 stamped — 16 MERGE + 4 ABSORB + 28 LINEAR = 48.
   The 28 LINEAR decompose (without double-counting) into: 10 magic per ruling #2 —
   including elemental_confluence, which is also a shipped consume result (Q3); 5
   performance/signature per ruling #6 (dance, vibe_control, juggling, heroic_punch,
   play_to_the_camera); 10 further orphans with no legal partner (LINEAR by elimination —
   Q1); 1 shipped tier-2 merge result (iron_stance — Q3); and 2 discretionary calls with
   legal partners (strong_strike, acrobatics — Q4). The
   12-orphan scan result: quick_step, telekinesis, feint, aura_reading, swim, juggling,
   voicebox, full_potential, nightlurking, lockpicking, camouflage, reversion (telekinesis
   and juggling are covered by rulings #2/#6 regardless).
3. **The iron_stance precedent is honored.** intercept (#37) and brace (#35) are stamped
   MERGE referencing the **shipped** recipe exactly as `data/skill_mutations.json` has it
   (Intercept Lv 5 + Brace Lv 3 → Iron Stance Lv 1, shared narrow `bracing`, both parents
   consumed). Decision #34's F2 resolution is applied: **the merge is canonical; R1's
   "Intercept/Iron Stance fold into Brace L8/L9" is retired** — those two ladder rungs
   are NOT re-mapped as Brace-native content (they are *realized by* Iron Stance itself).
   Supporting evidence that the re-map mechanism works: brace's L6 threshold content
   already ships as Iron Stance's L4 effect.
4. **The four display-rename skills** are stamped under their **sim keys** with the
   rename caution noted per row (®): `vibe_control`, `heroic_punch`, `slice_n_dice`,
   `play_to_the_camera` — mechanics under sim keys, display names data-sourced, final v2
   wordings still unpinned for two.
5. **Deferred/data-only skills are stamped too** (†, 27 of 48 — everything not yet in
   `SkillBook.KNOWN_KEYS`): their shape is a design fact ahead of implementation; nothing
   in this proposal requires them implemented first.
6. **reversion** (#48) is noted as **NPC-content** (ladder default #7) with zero
   keywords (the data's own `_meta.unassigned` flag — no keywords invented here), zero
   threshold rows, and the #33 G7-acquisition tension surfaced rather than resolved.
7. **Consumption is exclusive — deliberate contention, flagged not hidden:** several
   skills appear both as a recipe parent and as another skill's absorb fodder
   (tactical_roll: M6 parent *and* slip_through fodder; overhead_slam: M4 parent *and*
   shockwave fodder; counter_surge: M2 parent *and* pressure_strike fodder; pounce: M3
   parent *and* controlled_sweep fodder; decapitate, execution, acrobatics likewise as
   alternates). A character can walk only one of the contending paths — that is the
   model's build-choice texture, not an inconsistency. No recipe consumes the same skill
   twice, and no recommended path is impossible under the data.
8. **Count integrity:** 48 skill rows (ids 1–34, 37–50 — 35/36 are the G5-cut,
   keyword-carrying, table-canon-only pair, excluded); 88 threshold rows = 44 L5 + 43 L6
   + 1 L7 (78 at decision time → 88 after Batch B's ten G6-skill rows); re-map totals
   15 + 4 + 69 = 88, nothing discarded.

**Honesty caveats.** (a) The stamps and recipes are recommendations — identity readings
grounded in `skills-r19-ladders-FINAL.md` and `docs/audits/skills-audit.md`, not rulings;
(b) all merged-skill names are PROVISIONAL; (c) tier-2 rung *placement* (which rung of
the new skill's L1–5 each inherited row lands on) is deliberately left to the tier-2
content pass — this document fixes disposition and destination only; (d) all magnitudes
remain PLACEHOLDER per R14; (e) nothing here was play-verified — no sim run was needed or
performed for this design artifact.

---

## 5. Open questions for the owner (only what the data cannot decide)

- **Q1 — Orphans that might still want a merge.** 12 skills have **no**
  narrow-compatible partner in the data (verified): quick_step, telekinesis, feint,
  aura_reading, swim, juggling, voicebox, full_potential, nightlurking, lockpicking,
  camouflage, reversion. All are stamped LINEAR by elimination (telekinesis/juggling also
  by rulings #2/#6). If any should evolve by consumption instead, the override routes
  are: **(a)** an authored **Modification-Center special offer** on a `broad_only` pair
  (decision #34 maps broad-only there — tempting examples the data supports: camouflage ×
  nightlurking [infiltration], feint × vibe_control [performance], telekinesis ×
  pressure_hold [control]), or **(b)** growing the taxonomy deliberately (book §4.5
  allows; e.g. a second `deception` or `throw` carrier). Which, if any?
- **Q2 — Absorb semantics.** Does ABSORB consume the target's **levels** (invested
  levels convert into how far past 5 the survivor is pushed — a Lv 4 fodder pushes
  further than a Lv 1) or just the **skill** (flat unlock of the L6–8 band)? And is there
  a minimum fodder level? The data has a `min_level` convention for merges only.
- **Q3 — Tier-2 continuation.** iron_stance and elemental_confluence are already
  tier-2/consume results with authored L6 content. Confirm that tier-2 skills default to
  a **short LINEAR band** (their existing rows) with **no tier-3 merges for now** — and
  that Confluence's growth specifically stays Patron-Token-gated per ruling #5?
- **Q4 — The two discretionary LINEARs with legal partners.** strong_strike (LINEAR for
  its ruled L10 mundane-breach role; legal `power` partners exist) and acrobatics (LINEAR
  as an always-on traversal passive; legal `tumbling`/`leaping` partners exist). Confirm
  LINEAR, or reassign using the alternates in §2?
- **Q5 — Recipe min-level convention.** The seven new recipes assume the iron_stance
  pattern: identity-primary parent **Lv 5** (the merge point) + secondary **Lv 3+**.
  Confirm as the standard, or set per-recipe?
