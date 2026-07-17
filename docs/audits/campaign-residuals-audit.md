# Campaign Residuals Audit — live-TTRPG inheritance (excluding skills & items)

**Date:** 2026-07-17 · **Status:** AUDIT — every verdict below is a *proposal for owner
ruling*, not a ruling. Nothing here edits seed data.
**Scope:** everything inherited from the live tabletop campaign that is not skills or
items (those have separate audits — deliberate non-overlap; cross-audit handoffs are
flagged where found).
**Files audited:** `data/tags.json`, `data/enemies.json`, `data/conditions.json`,
`data/skill_thresholds.json`, `docs/GPT_Master_Compendium.md`,
`docs/rules-questionnaire.md` — verified against `docs/DIRECTION.md` (D3–D5),
`docs/rules-addendum.md` (R3, R10–R18), `docs/design/patron-gods.md`,
`docs/cosmic-casino-canon.md`, `docs/story-canon.md`, `docs/setting-rebrand-options.md`,
`docs/review/review-5-compendium-delta.md`, `docs/gdd/gdd.md`,
`data/migrations/001_initial_schema.sql`, and `simulation/condition_engine.gd`.

---

## 1. `data/tags.json` — 100 tags, all effect fields empty

**Canon frame for the verdicts (GDD "Tags vs epithets", patron-gods.md §Epithets):**
tags are the **audience's crowd labels** — performable, fakeable, pop-culture noise from
a god-audience that binge-watched humanity. **Epithets are a separate track**: the
pantheon's comparisons, earned by trait accumulation + myth recreation ("Sasha the
Nine-Lived" pattern). The old TVTropes.org sourcing dependency (compendium §2.17) is
flagged debt — internalized, per GDD. The discriminator used per tag: *does the NAME
read as something a watching crowd would chant about a contestant's on-camera behavior?*
Essence/legend words belong to epithets; real-world trademarks and insider trope names
don't survive contact with shipping.

**Data state (verified):** all 100 rows have empty `description`, `effect`,
`unlock_conditions`, and `goal_modifier_weights`. The SQLite schema
(`001_initial_schema.sql:74–96`) already carries `unlock_conditions`,
`goal_modifier_weights`, `character_tags.weight`, and a `patron_goals.tag_id` FK — the
effect model below fills fields that already exist.

### 1.1 Verdicts (KEEP 79 · RENAME 9 · MIGRATE-TO-EPITHET 5 · CUT 7)

#### Show & narrative labels (ids 1–51)

| id | name | verdict | note |
|---|---|---|---|
| 1 | Documentary | KEEP | calm/observational-play label; broadcast-native |
| 2 | Playa | KEEP | crowd slang, generic |
| 3 | Absolute Cinema | KEEP | meme-native crowd praise; generic words |
| 4 | Edgy | KEEP | |
| 5 | Anime | KEEP | pop-culture style label — diegetic under the VIP-table skin |
| 6 | LEEROY JENKINS | RENAME → "The Charge" | real-world meme handle / WoW-adjacent IP; the reckless-charge behavior label survives the rename |
| 7 | Scrub | KEEP | fighting-game slang, generic |
| 8 | Stinker | KEEP | |
| 9 | Pinky Promise | KEEP | promise-keeper label; natural patron `favor_conditions` hook |
| 10 | Unkillable | MIGRATE-TO-EPITHET | "the Unkillable" is myth-grade essence, not crowd framing |
| 11 | Oops | KEEP | blunder label |
| 12 | Vengeful | MIGRATE-TO-EPITHET | "avenger" is literally in the epithet trait vocabulary (patron-gods.md §Epithets) |
| 13 | Menace | KEEP | crowd-voice reading ("public menace") is strong |
| 14 | Animal Planet | RENAME → "Nature Special" | real Discovery-network trademark |
| 15 | Fan Favorite | KEEP | core audience mechanic; referenced by the brand contract (story-canon.md) |
| 16 | Corporate Asset | RENAME → "House Asset" | Corporation-as-power is dead canon (D3); casino re-voice. Story-canon's cold-read-tag example list needs the same touch-up |
| 17 | Tragic | KEEP | |
| 18 | Bolivian Army Ending | RENAME → "Last Stand" | TVTropes-ism; obscure without the wiki |
| 19 | Chunky Salsa Rule | RENAME → "Splatter Reel" | TTRPG-insider trope; "Rule" is rules-lawyer voice, not crowd voice |
| 20 | Coconut Superpowers | CUT | production-trivia trope (off-screen budget saving); no behavioral read on a contestant |
| 21 | Protagonist | KEEP | audience narrative framing — exactly what tags are |
| 22 | Antagonist | KEEP | |
| 23 | Anti-Hero | KEEP | |
| 24 | Incorrigible | MIGRATE-TO-EPITHET | essence trait-word, not a performance label (borderline — could stay a tag if the owner likes the crowd reading) |
| 25 | No Cure For Evil | KEEP | reads naturally despite trope origin; low confidence |
| 26 | Munchkin | KEEP | audience labels the min-maxer; generic slang |
| 27 | Little Dead Rising Hood | CUT | table inside-joke + *Dead Rising* (Capcom) IP echo; no general read. Fallback if the slot should live: rename "Grimm Episode" |
| 28 | Mascot | KEEP | brand-contract empathy tag (story-canon.md) |
| 29 | Butcher | MIGRATE-TO-EPITHET | "X the Butcher" is the classic historical epithet shape — pantheon comparison, not crowd chant |
| 30 | Survivor | KEEP | reality-TV pun is native to the frame |
| 31 | Spy | KEEP | |
| 32 | Liability | KEEP | |
| 33 | Method Actor | KEEP | show-native |
| 34 | Understudy | KEEP | |
| 35 | Typecast | KEEP | repeats-the-same-approach label |
| 36 | Prima Donna | KEEP | |
| 37 | Scene Stealer | KEEP | |
| 38 | The Monologue | KEEP | speech-mechanics hook (director speech scoring) — flagship-rider candidate |
| 39 | Fourth Wall | KEEP | plays-to-camera; two-information-planes hook |
| 40 | Box Office Bomb | KEEP | hype-flop label |
| 41 | Director's Cut | KEEP | resonates with judge-god-shaped arenas (casino canon §4) |
| 42 | Certified Fresh | RENAME → "Critics' Darling" | "Certified Fresh" is a Rotten Tomatoes trademark |
| 43 | SAG Dispute | RENAME → "Contract Dispute" | real union; the Directive-refusal joke (Q39) survives the rename |
| 44 | Direct to DVD | KEEP | dated-tech joke is diegetic (gods binged old human media) |
| 45 | Callback | KEEP | signature-move repetition; synergizes with myth-template deeds |
| 46 | Nepotism Hire | KEEP | lands *harder* under patron-god sponsorship |
| 47 | One Star Review | KEEP | |
| 48 | Student Film | KEEP | |
| 49 | Craft Services | KEEP | support-role label |
| 50 | Resting Loser Face | KEEP | |
| 51 | Applause Machine | KEEP | hype-fishing label |

#### Animal cluster (ids 52–70) — survives: animals are playable (R16) and Sasha is in-game

| id | name | verdict | note |
|---|---|---|---|
| 52 | Unlikely Menace | KEEP | |
| 53 | Adorable Threat | KEEP | |
| 54 | Waddled Into Frame | KEEP | broadcast-native |
| 55 | The Bit | KEEP | |
| 56 | Bark Bark Bark | KEEP | |
| 57 | Sea World Reject | RENAME → "Aquarium Escapee" | SeaWorld is a real trademark |
| 58 | Flipper Mode | KEEP | "flipper" is generic anatomy; low IP risk |
| 59 | Crowd's Baby | KEEP | brand-contract empathy tag |
| 60 | Nine Lives | MIGRATE-TO-EPITHET | THE canonical epithet example — "Sasha the Nine-Lived" (setting-rebrand-options.md, narrative-design.md) |
| 61 | Knock It Off The Table | KEEP | cat meme + free casino-table pun |
| 62 | Feral Consultant | KEEP | |
| 63 | Witnessed | KEEP | the audience's act of witnessing — tag-native |
| 64 | Murder Mittens | KEEP | |
| 65 | Dead Drop | KEEP | spy/cat-gift dual read |
| 66 | Vet Visit | KEEP | condition-prone label |
| 67 | Territory Marked | KEEP | |
| 68 | 3am Energy | KEEP | |
| 69 | Indoor Cat | KEEP | caution label — hooks the anti-safe-play economy |
| 70 | Birdwatcher | KEEP | fixation label |

#### K-pop cluster (ids 71–82) — authored for XQUEZ/T, who is out of the game (story-canon IP split). Verdicts test each name *without* that anchor.

| id | name | verdict | note |
|---|---|---|---|
| 71 | Main Vocalist | KEEP | party-face/talker label |
| 72 | Visual | KEEP | literally the R18 Charm reading (objective presentability) — best stat-linked tag in the set |
| 73 | Maknae | RENAME → "The Rookie" | insider K-pop term (youngest member); the meaning generalizes, the word doesn't |
| 74 | Rap Line | CUT | group-role term with no per-contestant read; orphaned |
| 75 | Formation | KEEP | re-anchor to R15 combined actions — the choreography/team-play label |
| 76 | Comeback Stage | KEEP | comeback-after-downed label; flagship-rider candidate |
| 77 | Internal Dispute | KEEP | party-drama label |
| 78 | Solo Debut | KEEP | solo-play label; Forsaken resonance |
| 79 | Parasocial | KEEP | audience-relationship native |
| 80 | All-Kill | KEEP | full-sweep label; chart term generalizes |
| 81 | Disbandment Arc | KEEP | party-breakup drama label |
| 82 | Fan Service | KEEP | plays-to-the-crowd hype hook |

#### Software cluster (ids 83–93) — authored for the removed robot race (R16). Tech memes are still human pop culture; verdicts test for a clean behavioral read on ANY contestant.

| id | name | verdict | note |
|---|---|---|---|
| 83 | Blue Screen | KEEP | chokes/freezes under pressure (Shock T2 Stutter resonance) |
| 84 | Legacy Code | CUT | robot-anchored; "outdated methods" read is weak |
| 85 | Corrupted File | CUT | robot-anchored; vague |
| 86 | Unpatched | KEEP | "known flaw keeps getting exploited" — clean read + director/enemy-AI hook |
| 87 | 404 | KEEP | never-where-expected / no-show label |
| 88 | Out of Memory | KEEP | forgets-the-plan label |
| 89 | Safe Mode | KEEP | over-cautious play — hooks spectacle-over-safety as a negative label |
| 90 | Null Pointer | CUT | no behavioral read |
| 91 | Overclock | KEEP | overexertion label (Exhausted-condition resonance) |
| 92 | Peer Review | CUT | no crowd voice |
| 93 | Technical Difficulties | KEEP | broadcast-native |

#### Show-meta (ids 94–100)

| id | name | verdict | note |
|---|---|---|---|
| 94 | Off Script | KEEP | Directive-defiance label |
| 95 | Crossover Event | KEEP | Stage-2 cross-party resonance |
| 96 | Genre Shift | KEEP | playstyle-change label |
| 97 | Background Character | KEEP | low-hype label |
| 98 | The Recast | KEEP | new-contestant-after-death; candidate diegesis for R17 softcore respawn |
| 99 | Blooper Reel | KEEP | Forced-Action-prone label |
| 100 | Post-Credits Scene | KEEP | outlives-the-expected-end label |

**Migration mechanics for the 5 MIGRATE tags:** they leave `tags.json` when the KAN-7
`traits` / `myth_templates` seed tables land (patron-gods.md data model) and enter the
epithet vocabulary/myth catalog instead ("the Unkillable", "the Avenger", "the
Incorrigible", "the Butcher", "the Nine-Lived"). Until then they cost nothing where
they are.

**Dead references found (cross-audit handoff → items audit):** compendium §2.13's
Spark-volver requires Tags **"Flashy"** and **"Catchphrase"** — neither exists in the
100-tag DB. Either dead requirements or two missing tags; owner call at the items pass.

### 1.2 Effect-model proposal — what a tag SHOULD do (5 patterns, not 100 bespoke effects)

All patterns are declarative weights/predicates over the sim event log — same
determinism discipline as patron affection (patron-gods.md rule 2). This is the
proposed answer to questionnaire **Q42**; it fills fields the schema already has.

1. **Hype resonance (multiplier lens).** Each tag declares 1–3 event domains from the
   live hype engine's taxonomy (kills, breaches, damage, forced actions, speech,
   stunts…) plus an on-brand multiplier (and optionally a small off-brand damper). The
   crowd rewards you for being who they decided you are. Cheapest to ship — the v1 hype
   meter and its event weights already exist (GDD "Hype ✅ v1 live").
2. **Goal/Directive generation bias (`goal_modifier_weights` — the field that already
   exists, empty on all 100 rows).** Tags weight which crowd Goals (and house Directive
   flavors) get generated for you: Menace pulls cruelty/overkill dares, Fan Favorite
   pulls crowd-pleasers, Safe Mode pulls "No Safety Play" dares. The
   `patron_goals.tag_id` FK in the schema anticipates exactly this.
3. **Patron-impression lens.** Tags amplify matching domain-tagged impressions in the
   patron multiplier model (boon economy): butcher-ish play under a gore tag draws
   war-domain god attention faster; empathy tags (Mascot, Crowd's Baby) draw
   hearth-domain gods; ties into buy-out interest. Can reuse pattern 1's domain
   declaration — one `domains` list serves both.
4. **Lifecycle weight as the universal dial.** The compendium's canon lifecycle
   (acquired → Reinforced → Faded → Lost) becomes a 0–3 `weight`
   (`character_tags.weight` already exists) that scales patterns 1–3; max weight =
   permanent. The brand contract's tag-drift effects (empathy tags fade, cold-read tags
   easier — story-canon.md) are drift modifiers on this dial, free of charge.
5. **Flagship riders (scarce, ≤10 tags).** A minority of hand-picked tags get one
   bespoke conditional trigger each (e.g. The Monologue: one boosted speech action per
   session; Comeback Stage: hype-floor bonus on returning from bleed-out). Everything
   else stays declarative. Keeps authoring cost sane and the 100-row table honest.

**Unlock model (same discipline):** `unlock_conditions` = event predicates
(achievement-style detection) for the detectable tags; director/audience-granted for
the rest — replacing the table-consensus + TVTropes channel (compendium §2.17).

---

## 2. `data/enemies.json` — 3 enemies

### 2.1 Conformance vs addendum + casino frame

| key | category | conformance findings |
|---|---|---|
| `roach_dog` | Mob (Small) | PASS mechanically: 1-HP lethal carapace matches "dies to one meaningful blow" (§2.14, Q46 seeding). Data gaps: `reward_table` empty; "never alone" is prose only — no pack-size/spawn-group field for KAN-4/5 to consume. |
| `little_brother_roach` | Elite (Large) | PASS: 8 parts, summner/healer/puller kit exercises range + summon + heal + forced movement. Nits: `drag_back` uses a one-off `moment_cost_per_2_spaces` schema key; `reward_table` empty; no reorganization-beat data (§2.14) anywhere in schema. |
| `incinedile` | Boss (Huge) | PASS vs rulings: breach B = 7+ **single hit** (NQ2 note embedded), 6 phases (NQ3 note embedded), Reflexes-gated counters match the R2 refinement, fire-heals + surface-immunity + hidden `network` implement "discoverable win condition, never a damage race" (CLAUDE.md hard rule). `breach_resets_after_phase: 2` matches compendium §3.1 Pressure Valve I. Phase `effects` arrays all empty (upgrades ride `behavior` instead — consistent but the field is dead weight). |

**Casino-frame / re-voice findings:**
- **No Corporation-flavored text exists in `enemies.json`** — the anticipated re-voice
  burden is (pleasantly) zero here. The re-voice work lives in items copy and the
  schema enum (see §3.3).
- **Dev-voice in player-facing fields:** descriptions carry provenance ("Ported from
  the live campaign bestiary", "Fully play-tested at the live table") and production
  notes. Fine while data is dev-only; must not surface in UI. Recommend a `notes`
  field split at the KAN-4 content pass.
- **Licensed music reference cannot ship:** `incinedile.description` names boss music
  "God Shattering Star" (Fire Emblem: Three Houses — Nintendo/KT). Same residual class
  as the compendium §3.5 Dissolution songs (Daft Punk "Human", "Dark is the Night",
  Grant Steller). Keep all of these as dev vibe references only; they are live-table
  flavor, not shippable content.

**Engine cross-check (real gap, see §3.2):** Incinedile's breach path A requires
*Bleeding T2 on any part* — but `conditions.json` legality lists don't contain any
enemy part key, and the engine remaps illegal parts (details in §3.2). The boss's own
win condition depends on conditions landing on non-human morphology. Verify before
KAN-4 enemy integration.

### 2.2 Gap analysis — what a floors-1–6 campaign + slice actually needs

**Slice (Stage 1, Incinedile P1, party of 3):** the existing 3 stat blocks suffice —
roach waves + elite + boss P1 is a complete tutorial arena. Optional nicety: one ranged
mob for variety. **No new enemies block the slice.**

**Campaign floors 1–6 (compendium §4 routes + §2.14 ladder):** currently 0 of the
story-required roster exists. Story-committed encounters needing stat blocks:

| floor | route-committed enemies (from §4.2–4.6) | role |
|---|---|---|
| F1 | possessed mask-man (Easy — win = *chain him*, not kill); demon girl (Medium — social, combat optional); Loong Kin (Hard — persuasion win condition); war hounds (Sasha's maze) | 3 route "bosses" with non-damage win conditions + 1 mob pack |
| F2 | exit-blocking demon (Easy); rival demon noble w/ Dissolution songs (Medium — the R12 encounter pattern); demon hunting party (Hard escort) | 2 bosses + 1 elite wave |
| F3 | Nullrot (Easy — fight-or-help dual condition); human-farm leader + demon buyer (Medium); disease-cure protection waves (Hard) | 2 bosses + 1 elite |
| F4–6 | continent-merge content; **War Nikita** (win = reach Old Nikita — recognition, not damage); demonic queen | 2+ bosses |

**Proposed roster budget (~23 new stat blocks for the full F1–6 campaign):**
- **5 mobs** (each showcasing one condition system, "never alone" as data): forest
  bleed-pack vermin · desert poison swarm · capital crush mob · ghoul (dissolution
  lore's leftovers) · war hound (doubles into Sasha/Nikita content).
- **5 elites** (each forcing one mechanic): ranged/artillery elite · grappler
  (suffocation showcase, R9 gates) · chiller · infector · reaction/counter elite
  (first consumer of the reaction rules).
- **9 route bosses** (3 per floor × F1–F3; only one route plays per campaign — the
  other 6 are replay value, matching "one route per campaign, others resolve
  offscreen"). Every one carries `surface_immunity`-style discoverable win-condition
  data — the Incinedile schema already proves the pattern, including the three
  *social* win conditions (chain / persuade / recognize).
- **3 merge-phase bosses** (War Nikita + demonic queen + one district-tier variant)
  + **1 Super Boss template** (Stage-tier, "not expected to be beaten", §2.14).

Mythology-sourced monster design (Asag template, casino canon §6) is the licensed-free
filler pool for anything not story-committed. All numbers placeholder per R14.

---

## 3. `data/conditions.json` + `data/skill_thresholds.json` — conformance sweep

### 3.1 `conditions.json` — VERDICT: PASS (2 findings)

Verified clean: all 9 rulebook conditions present and matching the CLAUDE.md vocabulary
(bleeding / crushed / suffocation / chilled / exhausted / infected / burn / poison /
dissolution). **No cooldown language, no corporate language.** Tier tables complete and
addendum-conformant: Bleeding 4 (T3/T4 per book+R4), Crushed 4 (T3–T4 are the R4
additions, cited in-line), Chilled 3 (E2 respecification: resolves at Clock reset
without re-apply), Exhausted 3 (R4 PROVISIONAL, flagged in-line), Infected 3 (T3 death
timer per R4), Burn 4 (T1 Shock cost per R4, closing the free-cure exploit), Poison 3
(+ entry conditions, 5 types, soup rule per R10), Suffocation and Dissolution correctly
tierless timers (R5/R6 psychic-resist slow encoded). Addendum citations embedded in
descriptions keep the file self-documenting. Delayed/PROVISIONAL markers honest.

**Finding C1 (real, engine-level — verify before KAN-4):** every `target_body_parts`
list is the six-part *human* template. `condition_engine.gd:134–136` remaps an unlisted
part to `legal_parts[0]` — so a condition applied to an enemy part key (`carapace`,
`network`, `top_left_hand`, `left_hand`…) silently relocates to `head` (or the list's
first entry), which `roach_dog` doesn't even have. Incinedile breach path A (Bleeding
T2 "on any_part") runs through exactly this path. KAN-2 tests only build human bodies
(`tests/test_kan2_acceptance.gd`, `add_human`), so the enemy-morphology path is
untested. Fix direction: legality from the combatant's actual part list (or a
part-category mapping), not a global human list.

**Finding C2 (nit):** descriptions are dev-voiced (rule citations); fine for the data
layer, but like enemies they need a presentation split if ever surfaced in UI.

### 3.2 `skill_thresholds.json` — VERDICT: CONDITIONAL PASS (known content debt + 4 findings)

82 rows, ids 1–82, effects/stat_requirements uniformly empty (same "empty effects"
state as tags — expected: threshold *text* is the content, structured effects await the
skill passover).

**Coverage vs the 44-skill list:**
- **3 skills have no thresholds at all:** id 4 (Strong Strike), id 18 (Telepathy — its
  L6 behavior lives in prose inside `skills.json` effect text instead), id 28
  (Thousand Cuts).
- **1 skill missing its L6 row:** id 31 (Vibe Control) has L5 only.
- **1 outlier:** id 32 (Juggling) uniquely has an L7 row (threshold id 58). Legal (caps
  reach 10 via Patron Tokens) but inconsistent — every other skill stops at 6.
  Thresholds 7–10 are undesigned across the board; that is the known content frontier
  (compendium §2.4 "thresholds every level from 5 up"), not corruption.

**Stale-language findings:**
| ids | skill | text | problem |
|---|---|---|---|
| 15, 16 | 9 Tactical Roll | "-4 Moment cooldown", "twice per **cooldown Rotation**" | violates R3 **no-cooldowns** — KNOWN (NQ1/review-5 flagged these exact rows); awaiting priming re-expression in the owner skill passover. Recorded here so the sweep is honest: still present as of this audit. |
| 78 | 42 Acrobatics | "+1 Jump per **turn**" | "turn" is not system vocabulary (Moments/Clocks; the game is turnless) |
| 61 | 34 Voicebox | "+1 **Strength**" | "Strength" is not a trait (physique/reflexes/mind/charm) — likely means +1 Physique-equivalent on commands; needs the passover's eye |
| 11 | 7 Pressure Hold | "4 Movement space per moment" (L5) | tension with R11.7 — *the grappler can't reposition while holding*. If L5 deliberately unlocks dragging, say so; as written it contradicts the engine log |

**No corporate language in either file.** Bonus sweep findings adjacent to scope:
- `data/migrations/001_initial_schema.sql:212` — `patron_goals.source_type` CHECK enum
  is `('Patron', 'Corporate', 'Crowd')`: the one true **Corporation residue in the
  data layer**. Casino re-voice: `'Corporate'` → `'House'` (migration + any readers).
- `simulation/action_resolver.gd:62–63, 457–466` + `combatant.gd:57` still carry the
  live cooldown execution path — R3 marks it deprecated, removal scheduled with the
  priming pass. Known; listed for completeness.
- `skills.json` lines 273, 287, 291, 1199 carry cooldown text (Tactical Roll,
  Acrobatic Save) — **handoff to the skills audit**, noted here only because the
  thresholds point at the same NQ1 debt.

---

## 4. `docs/GPT_Master_Compendium.md` — dead canon vs live canon

The compendium is source-of-truth #3 (DIRECTION precedence list) and review-5 catalogs
the *May-era* deltas (NQ1–NQ4). This section catalogs what the **post-compendium
rulings (2026-07-14 → 07-16)** kill, so future readers don't resurrect it.

### 4.1 Contradicted — compendium section → superseding ruling

| # | compendium section (what it says) | superseded by (what's true now) |
|---|---|---|
| 1 | §1, §11 — "alien conglomerate ('The Corporation™') films humans to justify colonization"; "beneficial — nay, necessary"; "refusing to join: 'we can't guarantee what will happen to you'" | **D3 (DIRECTION) + setting-rebrand RULED:** the show is a VIP table in the Cosmic Casino, run by a **fallen (bankrupt) god**; the divinity economy is the motive; the reality-show skin survives only diegetically. Corporation-as-power and the colonization motive are dead canon. "The house" speaks where the Corporation spoke (narrative-design.md). |
| 2 | §1 "humans (and animals/**AI**)", §2.1 "Race: Human (start)" | **R16:** Robot/AI race **removed entirely**; playable = Humans + Animals (verified: `data/races.json` = `human`, `animal`). Backgrounds grant starting skills. |
| 3 | §2.1/§2.4 "each trait grants skill points equal to its level" | **R6:** app formula wins — `max(0, traitTotal − 1 − spent)`, multi-stat skills cost 1 from each stat. |
| 4 | §2.3 Mind cap "`[OPEN]` app seeds /10" | **R6 + review-5:** verified /15 in the app; the OPEN flag is stale. Closed. |
| 5 | §2.16 "Patrons — paying audience members" | **D5 + patron-gods.md:** the Patrons tier = **donator gods**; THE patron god is a singular escort slot above it. |
| 6 | §2.16 "Exchange: 3 Boss Tokens → 1 Patron Token" | **R10:** exchange **CUT** from the digital game. |
| 7 | §2.17 "player-proposed tags must appear on TVTropes.org" | **GDD/rebrand:** dependency internalized — tags are the seeded in-game crowd vocabulary; **epithets** are the separate pantheon track. TVTropes is not an authority. |
| 8 | §2.19 "Directives issued by The Corporation/subsidiaries" | **D3:** the house (fallen god) issues Directives; System messages are the house channel. Mechanics unchanged, voice re-skinned. |
| 9 | §2.15 "the Lounge — party's **corporate-controlled** modular base" | Casino re-voice: **the comp suite** — the house comps your room; surveillance = the house watching its assets. Module tree itself is live (see 4.2). |
| 10 | §3.1 Incineradile: 4-phase writeup, "Frenzy (HP 35→19)" | **NQ3 RULED:** 6 phases (fight/explosion ×2, fight, large explosion), seeded in `data/enemies.json` (35–18 boundary). The compendium's phase list is superseded tuning history. |
| 11 | §3.3 XQUEZ/T tank kit (robot fiction), §5 XQUEZ/T as party content | **R16 + story-canon IP split:** the character is TTRPG-only; robot race gone. The *kit* (Intercept / Iron Stance) survives as generic skill drafts (R12; NQ6 pending). |
| 12 | §3.5 Dissolution songs per party member | **IP split:** only Sasha's remains game-relevant (recruitable NPC); licensed tracks ("Human", "Dark is the Night", Grant Steller) are dev vibe references, never shippable. The encounter **pattern** is adopted canon (R12). |
| 13 | §5 live party as game characters | **Story-canon RULED:** players' characters stay OUT; **Sasha & Nikita only**, as recruitable NPCs; the player is an OC (D4). §5 stays valuable as engine fixtures (acceptance test 16) + the animal-morphology precedent (Sasha torso 3 HP). |
| 14 | §6.2 "Party: fully custom party"; §6.4 open "party size cap" | **D4 + NQ4:** player OC + predesigned NPC recruits; **no party cap** — recruitment is the economy. |
| 15 | §6.2 "Death: checkpoint rewind — full world state reset"; §11 "No respawns" | **R17:** death rules depend on **run type** — softcore (respawn), hardcore (permadeath, owner-preferred), Forsaken (god-initiated hardcore). "No respawns" as an absolute is dead; checkpoint rewind survives at most as softcore's mechanism ⟨framing TBD⟩. |
| 16 | §6.2 "Moments = discrete turns with visible countdown" | **DIRECTION combat-fields SKETCH:** real-time ticks with declare windows; pluggable drivers (the paused solo driver preserves the turn feel). Sketch-level tension, not yet a full contradiction — don't quote §6.2 as the final combat presentation. |
| 17 | §9 items 5 (psychic threshold) and 7 (tutorial HP tuning) | Item 5 closed (R6). Item 7 **absorbed by R14** — the whole numbers system is a rework pass; all seeded damage/HP are placeholders. |
| 18 | §2.21 "Big Brain: Mind Crush all Mobs in **50m**" | R10 B8: distances are **spaces** (hexes). Content-pass nit. |
| 19 | §2.13 Spark-volver "Tags Flashy + Catchphrase" | Neither tag exists in the canonical 100 — dead reference (see §1.1 handoff). |
| 20 | (absence) no announcer anywhere in the compendium | **Momus RULED shared host** (rebrand decision 4) — don't re-derive "the game lacks an announcer" from the compendium. Likewise: the **starving-pantheon** motive (option E) was REJECTED — gods go bankrupt through debauchery (casino canon §4); never re-import E from older drafts. |

Confirmed-not-contradicted: §2.4 "cooldowns removed" (R3 agrees — priming replaces
them; the *content* still lags, NQ1), §2.6–2.12 combat/condition rules (seeded), §2.14
enemy ladder, §10 principles.

### 4.2 Still LIVE and unadopted — usable as-is

| compendium section | asset | lands with |
|---|---|---|
| §2.15 | Lounge module tree (5 sections, submodule costs) — needs only casino re-voice | KAN-7 |
| §2.19 / §2.20 | Directive + Goal type taxonomies — direct seed material for the empty `patron_goals` table | KAN-7 (schema exists now) |
| §2.21 | Achievement categories + Bronze→Godly loot ladder | KAN-7 |
| §2.14 | Boss variant ladder (Neighbourhood→City; Precinct→Stage) + reorganization rules | KAN-4 AI |
| §3.2 | Modifier economy (adopted R12) + Lesser modifier working list | items pass |
| §3.4 | Sasha/Filipe/XQUEZ-T skill revision notes | owner skill passover |
| §4.1–4.6 | Full three-route floor structure, Nullrot, Loong Kin, human farm, Nikita arc, Sasha's maze — the narrative source material; demons/Loong explicitly survive the frame swap | KAN-5+ |
| §2.8 | Demonic-nobility Dissolution encounter pattern (adopted R12) | KAN-5+ |
| §5 | Party stats as engine fixture data (acceptance test 16); animal morphology precedent | KAN-2/4 (in use) |
| §6.2 | Noise/absorption, two-mode structure, overworld state machine (adopted into DIRECTION) | KAN-5 |
| §6.3 | Translation-debts checklist — still the active list (tags dependency = §1 of this audit) | ongoing |
| §8 | Session recorder pipeline — TTRPG-side tooling; future Stage-2 ingestion idea | out of game scope |

---

## 5. `docs/rules-questionnaire.md` — open-question census

### 5.1 Counts per section (79 questions total: Q1–Q72 + NQ1–NQ7)

| section | total | closed | open | notes |
|---|---|---|---|---|
| A Creation & advancement | 6 | 0 | 6 | Q1 is a residual sliver only (bonusPoints default) |
| B Skills | 10 | 2 (Q13, Q16) | 8 | |
| C Combat timing | 10 | 0 | 10 | Q21 has a full proposed model (R13) awaiting one owner nod |
| D Conditions & healing | 7 | 1 (Q33) | 6 | |
| E Exposure & metagame | 10 | 0 | 10 | Q42 = this audit's §1.2 proposal |
| F Enemies & encounters | 5 | 0 | 5 | |
| G Items & economy | 7 | 1 (Q52) | 6 | Q53 is a sliver (pre-affixed drops?) |
| H World & environment | 5 | 0 | 5 | |
| I Races & bodies | 4 | 0 | 4 | **Q62 is largely OBSOLETE** (R16 removed robots) — recommend closing it with a strike-through |
| J Lounge & downtime | 3 | 0 | 3 | |
| K Digital-only | 5 | 0 | 5 | Q68 pre-answered ⟨PROPOSED⟩ by story-canon slice shape; Q70 partially superseded by R17 |
| L Compendium NQs | 7 | 5 (NQ1–4 ruled; NQ5 absorbed by R14) | 2 | NQ6, NQ7 |
| **Total** | **79** | **9** | **70** | |

### 5.2 The 10 highest-impact open questions (KAN-3/4 next, slice after)

1. **Q72 — bless or itemize the PROVISIONAL bundle** (R2 miss model, R3 caps, R4
   Burn-Shock, R8 RPM, R9 grapple, R10 halving, R11 log). Everything the slice ships
   sits on these; one sitting de-risks the whole engine.
2. **Q7 — what skill levels 1–4 actually do.** Blocks the skill passover, the priming
   re-expression (R3/NQ1 — including the stale threshold rows in §3.2), and every
   KAN-4 kit.
3. **Q68 — slice party confirm** (one OC + Sasha & Nikita ⟨PROPOSED⟩, Incinedile P1
   balanced for 3). Determines KAN-4 S4.1/S4.2 scope and slice tuning.
4. **Q69 — friendly fire.** Engine-level targeting rule; a 10-hex flamethrower cone +
   a party of 3 makes it visible in the slice's first minute.
5. **Q21 — Shock recovery: nod/adjust R13.** The engine currently never decays Shock
   in combat; R13's event model dissolves the gap but is unsigned.
6. **NQ6 — tank kit (Intercept / Iron Stance).** First reaction-skill test cases; the
   generic survivors of the XQUEZ/T material; KAN-4 seed skills.
7. **Q47 — encounter shape scaled to small parties.** Compendium budgets assume a
   table of 4–5; the slice runs 3. Feeds KAN-4 AI and every arena.
8. **Q61 — the Animal body template** (Filipe's actual parts/HP). R16 made animals a
   creation option; Sasha's torso-3 is the only morphology precedent on file.
9. **Q29 — treatment items: uses + Moment costs (self vs ally).** The slice's survival
   loop (bandage vs the Bleed clock) is untunable without it.
10. **Q71 — declare-window starting value** (~3–5s/Moment). The KAN-3 clock-driver
    story builds the paused driver now; the timed driver's shape decision should land
    before Stage-1 co-op.

Runners-up: Q42 (tags — §1.2 is the proposal awaiting ruling), Q45 (boss action budget
per Clock — Incinedile P1 tuning), Q44 (enemy statting heuristic — needed before the
§2.2 roster build-out).

---

## 6. Consolidated summary

### Counts

| subject | headline numbers |
|---|---|
| tags.json | 100 audited → **79 KEEP · 9 RENAME · 5 MIGRATE-TO-EPITHET · 7 CUT**; 100% of description/effect/unlock/weight fields empty; 5-pattern effect model proposed; 2 dead tag references (Flashy, Catchphrase) |
| enemies.json | 3 seeded, all conformant with NQ2/NQ3/R2; 0 Corporation text; 1 unshippable music reference; 2 dev-voice descriptions; roster gap ≈ **23 new stat blocks** for F1–6 (5 mobs, 5 elites, 12 bosses, 1 super-boss); **slice needs 0 new enemies** |
| conditions.json | PASS — 9/9 conditions, tier tables complete per R4, zero stale language; **1 real engine-data gap** (enemy morphology remap, untested path) |
| skill_thresholds.json | 82 rows; 3 skills uncovered (Strong Strike, Telepathy, Thousand Cuts) + Vibe Control L6 missing; 2 stale-cooldown rows (known NQ1 debt, still present); 2 vocabulary nits ("turn", "Strength"); 1 R11.7 tension (Pressure Hold L5) |
| compendium | **20 contradiction entries** mapped section → superseding ruling; **12 live-unadopted assets** cataloged |
| questionnaire | **70 of 79 open**; top-10 ranked; 1 obsolete question (Q62), 2 slivers (Q1, Q53), 2 partially superseded (Q70, NQ5-absorbed) |

### Top 10 most urgent items overall

1. **Q72 sitting** — sign off / itemize the PROVISIONAL engine bundle.
2. **Tag effect-model ruling** (Q42 + §1.2) — unblocks 100 empty rows, the
   `goal_modifier_weights` schema, and KAN-7 hype/goal integration design.
3. **Owner skill passover** (Q7 + NQ1) — also clears the stale threshold rows, the
   priming vocabulary, and the threshold coverage gaps (§3.2).
4. **Enemy-part condition legality gap** (§3.1 C1) — silent misbehavior risk sitting
   under the boss's own win condition; fix at the KAN-4 boundary.
5. **Slice party confirm** (Q68) — gates KAN-4 story scoping.
6. **Friendly fire** (Q69) — engine rule the slice exposes immediately.
7. **Shock model nod** (Q21/R13) — one yes/no closes a combat-correctness hole.
8. **Enemy roster plan** (§2.2 + Q44/Q47) — ~23 stat blocks needed before KAN-5
   content; statting heuristic first.
9. **Compendium delta adoption** — link this audit's §4.1 table from the compendium
   header (or DIRECTION's precedence note) so dead canon can't be resurrected by a
   future reader of source-of-truth #3.
10. **De-license + re-voice pass** — strip licensed music references from shippable
    data (keep as dev notes); migrate `'Corporate'` → `'House'` in the
    `patron_goals.source_type` enum; rename `corporate_asset`.

### Throw away entirely (dead canon — never re-import)

- The Corporation as the power running the show: colonization motive, "beneficial —
  nay, necessary", the refusal threat (compendium §1/§11).
- TVTropes.org as a tag-sourcing authority (§2.17).
- The Robot/AI race and XQUEZ/T-as-game-content (R16 + IP split) — including the tag
  cluster anchors; the tank kit survives as generic drafts.
- Boss-Token → Patron-Token exchange (R10 cut).
- Cooldowns — text and engine path both scheduled for removal (R3).
- The starving-pantheon motive (rebrand option E — explicitly REJECTED).
- "No respawns" as an absolute (§11) and checkpoint-rewind as *the* death model (R17).
- The 4-phase Incineradile description (§3.1; 6 phases are canon).
- Licensed music as shippable content (God Shattering Star, the Dissolution songs).
- 7 cut tags: coconut_superpowers, little_dead_rising_hood, rap_line, legacy_code,
  corrupted_file, null_pointer, peer_review.

### Usable as-is (no rework needed beyond scheduling)

- **79 kept tag names** (effects pending the §1.2 model ruling).
- **All 3 enemy stat blocks** (numbers placeholder per R14, like everything else).
- **conditions.json wholesale** (modulo the engine-side legality fix).
- **Compendium live assets** (§4.2): Directive/Goal taxonomies, Lounge tree,
  achievement/loot ladders, enemy ladder + reorganization rules, modifier economy,
  Forced-Action tables, the full three-route campaign story, the Dissolution encounter
  pattern, party data as fixtures, the session-recorder concept.
- **The questionnaire itself** — structure is sound; it needs 9 strike-throughs
  (§5.1 notes) and an owner sitting, not a rewrite.
