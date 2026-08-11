# D — Skills, combat engine, conditions & enemies: v1→v2 change inventory

**Scope:** rulebook §4 (all), §5, §6, §7, §8, §9, §10, §11, §13, §14, §15, §21 (all), plus the
live skill catalogue and its flavour text.
**Primary source:** `/home/user/Galactic-Prime-Time/rulebook/gpt-system-v1.0.md` (v1.1, 1315 lines).
**v2 canon consulted:** `/home/user/Galactic-Prime-Time-Game/docs/{cosmic-casino-canon.md,
setting-rebrand-options.md,DIRECTION.md,rules-addendum.md}`, `docs/design/{patron-gods.md,
mythology-research-spec.md,skills-r19-ladders-FINAL.md,skills-passover-worksheet.md}`,
`docs/audits/{skills-audit.md,campaign-residuals-audit.md}`, `data/*.json`.

**Headline.** This slice is overwhelmingly **KEEP**. §5–§15 is a physics engine written in
plain English — bodies, wounds, timers, dice-on-failure — and it does not know who is
watching. Across the ~700 lines of §4–§15 + §21 that I own, **exactly 6 lines carry
broadcast/corporate vocabulary** and **9 more carry economy coupling** (Patron Token,
Gemstone, Loot Box, Lounge module, Surgeon's Table, Augmentation Hub, Tattoo Artist).
Everything else is premise-free. The value of this report is therefore (a) the proof, (b) the
precise leak list, and (c) three places where the gods premise is not a cost but a **gap in
v1** — the fate/odds surface, curses, and enemy allegiance.

**Data-honesty note.** `galactic-prime-time.skilltemplates.json` is a **stale export**: max
`updatedAt` = `2026-04-16`, 44 rows, `keywords` absent on all of them. The live campaign DB is
past it — the skill passover of 2026-07-25 applied 27 template repairs, 44 keyword sets and
**5 new skills** (`Galactic-Prime-Time/CLAUDE.md` "Known Backlog" §2;
`server/apply-skill-passover.js:264` KEYWORDS, `:314` NEW_SKILLS). All exact counts below are
stated against the 44-row export as instructed, with the +5 called out separately.

---

## Summary table

| ID | Element | §/file:line | Verdict | Effort | One-line change |
|---|---|---|---|---|---|
| D-01 | §4.1 the 0–10 architecture | `gpt-system-v1.0.md:154-167` | KEEP | — | Pure progression grammar; no premise anywhere in it. |
| D-02 | §4.1 the "exotic damage class" top rung (R19 L10 = radiant/psychic-class) | `:166-167`; `rules-addendum.md:614-630`; `skills-r19-ladders-FINAL.md:35-39` | RESKIN | S | Name the reserved exotic class **divine/radiant** — the slot already exists, unnamed. |
| D-03 | §4.2 cap ladder 5→10 bought with Patron Tokens | `:169-174`; `:890-893` | RESKIN | S | Same math; the fiction becomes "a god buys your ceiling" — mapping already ruled. |
| D-04 | §4.2/§4.5 upgrades & mutations happen at the Skill Gemstone, in the Lounge | `:177-178`, `:201-206` | RESKIN | S | Lounge → the house's comp suite (already mapped); Gemstone name is myth-neutral, keep. |
| D-05 | §4.3 multi-stat skills | `:180-186` | KEEP | — | Point-economy rule; premise-free. |
| D-06 | §4.4 "most skills unlock by doing" | `:190-191` | KEEP | — | Achievement-gated acquisition; the strongest myth-compatible rule in §4. |
| D-07 | §4.4 external sources: Loot Boxes / Achievements / Wizard's Tower | `:192-193` | RESKIN | S | Boxes → comps & jackpots (already mapped); Wizard's Tower is fantasy-native already. |
| D-08 | §4.4 Skill Tomes | `:194-197` | RESKIN | M | Upgrade, not repair: a tome becomes a **dead god's scripture** — "loot must feel like remnants of belief". |
| D-09 | §4.4 character-exclusive skills | `:198-199`; `rulebook/skills-passover.md:29-33` | KEEP | — | Table-side already RULED to acquisition-requirements instead; game side keeps `exclusive_to`. |
| D-10 | §4.4 has no *teacher* — nobody explains where skills come from | `:188-199` (absence) | NEW | M | v2 supplies the missing author: patron reveals, the table's fallen god offers, myth re-enactment teaches. |
| D-11 | §4.5 consuming skills + the broad/narrow keyword tree | `:201-232`; `apply-skill-passover.js:264-309` | KEEP | — | 9 broad / 30 narrow keywords; zero premise words in the taxonomy. |
| D-12 | §4.6 Priming — "there are no cooldowns" | `:234-248` | KEEP | — | Five prime types, all fiction-free. Only leak: the STACK example cites Camera Call (`:243`). |
| D-13 | §4.7 passive & reactive skills | `:250-255` | KEEP | — | Trigger grammar; premise-free. |
| D-14 | §5 The Clock (5.1–5.7) | `:259-354` | KEEP | — | 96 lines, zero premise words. Only §1's "broadcast's slow-motion replay" flavour touches it. |
| D-15 | §1 timescale flavour: "the table's deliberation is the broadcast's slow-motion replay" | `:34-36` | RESKIN | S | → the gallery's replay / the house's instant replay. One sentence. |
| D-16 | §6 Forced Actions (both d6 tables + the requirements gate) | `:358-395` | KEEP | — | Pure consequence tables — and the single best divine-intervention insertion point (D-33). |
| D-17 | §7 Bodies & Damage | `:399-458` | KEEP | — | Part HP, targeting, disabled parts, death & bleed-out — anatomy, not setting. |
| D-18 | §7.4 recovery routes name Lounge modules (Surgeon's Table, Augmentation Hub) | `:444-446` | RESKIN | S | Re-voice as house services; machine bodies are casino-canon, not alien-locked. |
| D-19 | §8.1 the universal condition engine | `:464-477` | KEEP | — | Apply/advance/delay/resolve. Independently audited "no corporate language". |
| D-20 | §8.2 the nine condition names & tier tables | `:479-567`; `data/conditions.json` | KEEP | — | All plain-English physiology; 26 god-domains map onto them with no new type needed. |
| D-21 | §8.2 Dissolution (ex-"Psychic") | `:562-567` | KEEP | — | Already myth-friendly — the rename moved the vocabulary *toward* myth. This IS v2's soul-damage. |
| D-22 | §9 Shock | `:577-601` | KEEP | — | Pain response, high-water mark, combat-end reset. No premise. |
| D-23 | §10 Resistances | `:605-618` | KEEP | — | One v2 gain: "player affliction resistance is GM-awarded" becomes a patron boon lane. |
| D-24 | §11 States glossary | `:622-632` | KEEP | — | Seven states, all mechanical adjectives. |
| D-25 | §13 Grappling | `:778-790` | KEEP | — | Includes the anti-cheese boss rule; premise-free. |
| D-26 | §14 Dodge Thresholds | `:794-815` | KEEP | — | The die ladder is v2's best permanent-boon vehicle (D-27). |
| D-27 | §14 threshold dice upgraded at the **Tattoo Artist** | `:809-812` | RESKIN | S | → a **god's mark**: permanent boon lane the patron economy explicitly allows. |
| D-28 | §15 Stealth, Detection & Cover | `:819-841` | KEEP | — | Geometric; the only theme line is the audience one, already re-ruled. |
| D-29 | §15 "Stealth does not suppress the audience" | `:837-839` | KEEP | — | **Already decided**: R20 makes rival gods the diegetic destealth lever. |
| D-30 | §21.1 categories Mob / Elite / Boss / Super Boss | `:1250-1256` | KEEP | — | Pure scale ladder; the engine hard-codes it. |
| D-31 | §21.1 Boss ladder **Neighbourhood → District → City** | `:1254` | RESKIN | S | Optional. Urban-civic, not TV — myth-compatible, but a belief-scale ladder reads better. |
| D-32 | §21.1 Super Boss ladder **Precinct → Country → Stage** | `:1255-1256` | RESKIN | S | Required. "Precinct" is civic-police, "Stage" is TV. v2 ladder proposed below. |
| D-33 | §21.2 construction guidance + the horde doctrine | `:1258-1273` | KEEP | — | Material-band mob math; "enemies win by creating problems" is premise-free doctrine. |
| D-34 | §21.3 boss doctrine — discoverable win conditions | `:1275-1297` | MECHANICAL | S | Add one line: the win condition should be **recoverable from the creature's myth**. |
| D-35 | §21.4 terrain (three authoring questions) | `:1299-1308` | MECHANICAL | S | Add a fourth question: *whose psyche is this arena?* (casino canon's arena rule). |
| D-36 | §21.5 falling | `:1310-1315` | KEEP | — | Dice sketch; premise-free. |
| D-37 | Bestiary flavour (demons, Loong, Incinedile, roach-dogs) | `GPT_Master_Compendium.md:100-106,206-208,282-284`; `campaign-residuals-audit.md:386` | KEEP | — | **Already decided**: demons/Loong explicitly survive the frame swap. |
| D-38 | Enemies have no **allegiance/disposition** field | `data/enemies.json` (absence); `cosmic-casino-canon.md:150-155` | NEW | M | Canon has Insane / Sane Followers / Worshipped Creatures; the data model has no slot. |
| D-39 | Skill NAMES (44 in export) | `galactic-prime-time.skilltemplates.json` | KEEP (32) / RESKIN (12) | S | 22 myth-neutral + 10 already myth-friendly; 9 tech-coded, 3 pop-coded. |
| D-40 | Skill DESCRIPTIONS — pop-culture quips | same file, `description` field ×44 | KEEP | — | Counter-intuitive: canon *licenses* them (the VIP table is themed on human pop culture). |
| D-41 | Broadcast vocabulary inside effect/level text (6 skills) | Decapitate, Heroic Punch, Dance, Strong Strike, Nightlurking, Generate Visual Media | RESKIN | S | "Viewer spike"→ the house's term; "minimap"/"POW graphic"/"Face Screen" are the real leaks. |
| D-42 | The two robot/AI joke skills | Generate Visual Media, Ignore All Previous Commands | CUT | — | **Already decided** (game): cut 2026-07-17 under R16. Table-side kept (G5). |
| D-43 | The "spectacle L10" rung (ladder default #6) | `skills-r19-ladders-FINAL.md:47-49,585-591` | RESKIN | S | Camera-Call-tier capstone → odds-board-tier capstone. Mechanically identical. |
| D-44 | **The fate/odds surface** — no external agent can touch any die | `:364-389`, `:794-815`; `data/patron_roster.json` | NEW | M | 11 of 24 MVP patron gods carry `luck_gambling`, which maps to **nothing** in combat. |
| D-45 | **Curses have no chassis** | `patron-gods.md:222-225`; `rules-addendum.md:658-660` | NEW | M | Propose the **anti-prime**: a curse adds/invalidates a prime requirement. Zero new machinery. |
| D-46 | Divine damage type? | `data/domain_condition_map.json`; `data/conditions.json` | KEEP (no new type) | — | 26 domains → 9 conditions with 13 deliberate empties. The answer is "no new type"; see D-02. |

Counts: **KEEP 25 · RESKIN 14 · MECHANICAL 2 · NEW 4 · CUT 1** (46 findings).

---

## Findings

### D-01 — §4.1 The 0–10 architecture (`gpt-system-v1.0.md:154-167`)

- **v1 (alien):** L0 revealed-but-untrained → L1 works → L1–5 numeric scaling → L6–10 each level
  *generalizes the skill to more situations*.
- **v2 (gods):** identical.
- **Verdict:** KEEP. **Effort:** —
- **Why:** There is not one premise-bearing word in the section. The one flavour example — "a
  fire-throwing skill might learn to cluster, carry a secondary damage type, originate away from
  you…" (`:165-167`) — is elemental fantasy, which the myth frame wants more than the alien frame did.
- **Already decided?** Yes — R19 (`rules-addendum.md:614-630`) rules the architecture, and
  `skills-r19-ladders-FINAL.md` has already driven **43 ladders to FINAL** under it with owner-accepted
  defaults. Do not reopen.
- **Open question for the owner:** none.

### D-02 — §4.1's unnamed "exotic damage class" / the R19 L10 rung (`:166-167`; `rules-addendum.md:614-630`; `skills-r19-ladders-FINAL.md:35-39`)

- **v1 (alien):** the top of a generalization ladder "finally touch[es] an exotic damage class"
  (`:167`). R19's worked example says L10 "unlocks **psychic/radiant-class damage**"
  (`rules-addendum.md:626`). Ladder default #2 rules this rung **magic-only and source-gated**
  (cap-raise Patron Token + Wizard's Tower), and 9 magic ladders now carry it explicitly — e.g. Fire
  Ball L10 "**Radiant/psychic-class fire that bypasses fire-resistance and standard tiers**"
  (`skills-r19-ladders-FINAL.md:439`).
- **v2 (gods):** the slot is already cut, already gated on a god's favour, and already called
  *radiant*. v2 should simply **name it**: `divine` (or keep `radiant`) as the declared exotic class
  that sits outside the seven resistance keys.
- **Verdict:** RESKIN. **Effort:** S (one glossary line + a data enum value; no rule change).
- **Why:** This is the single cheapest way to give a gods premise a "divine damage" answer without
  adding a tenth condition. The mechanics are already written: it *bypasses resistance and standard
  tiers*, which is exactly what a god-tier effect should do, and it is already gated behind the
  Patron-Token/Wizard's-Tower source pair so it can never be farmed.
- **Already decided?** Partly — the rung, the gating and the magic-only restriction are RULED
  (`skills-r19-ladders-FINAL.md:35-39`, owner accepted all 10 defaults). The *name* is not.
- **Open question for the owner:** is the exotic class called **Divine**, **Radiant**, or does it
  stay deliberately unnamed so each L10 describes its own transcendence?

### D-03 — §4.2 The cap ladder: Patron Tokens buy levels 6–10 (`:169-174`, `:890-893`)

- **v1 (alien):** "each step past 5 costs a **Patron Token** (+1 max level per token), to the ceiling
  of 10" (`:173-174`). Patron Tokens are earned "when a **Goal converts a new Patron**" (`:892`) —
  a Patron being a one-time large donor, the streamer-gets-$5,000 tier (`:882-885`).
- **v2 (gods):** patrons are gods. `setting-rebrand-options.md:30` maps
  "Viewers / Followers / **Patrons** → Spectator gods / devotees / **patron gods** — the mechanic
  already has the right name," and `patron-gods.md:14-23` splits it into the *patrons* tier (donator
  gods) and **THE patron god** (singular escort). So §4.2 becomes: *your skill ceiling is bought by
  divine favour*.
- **Verdict:** RESKIN. **Effort:** S — no arithmetic changes at all.
- **Why:** This is the most flattering accident in the whole book. The currency that gates
  build-defining power is already named after the thing v2 makes literal. It also gives the patron
  layer a *permanent* boon lane, which `patron-gods.md:114-120` explicitly allows ("permanent —
  sometimes, depending on the buff").
- **Already decided?** Yes for the exposure-ladder mapping (`setting-rebrand-options.md:30`,
  `patron-gods.md:77-84`). Not decided: whether the token stays a token or becomes a favour
  threshold.
- **Open question for the owner:** does the cap-raise stay a *spendable token*, or become an
  **affection threshold** with the patron god (i.e. the god raises your ceiling when you please it)?
  Token = player agency; threshold = the god decides. The second is more on-theme and more brutal.

### D-04 — §4.2/§4.5 The Skill Gemstone, in the Lounge (`:177-178`, `:201-206`, `:223-232`)

- **v1 (alien):** "The work itself happens only in the Lounge, at the **Skill Gemstone**"; the
  Gemstone is where all merging/upgrading/mutation happens; canonical example Intercept Lv5 + Brace
  Lv3 → **Iron Stance** (`:228-232`), now seeded (`server/apply-skill-passover.js:377`).
- **v2 (gods):** the Lounge becomes the house's comp suite (`setting-rebrand-options.md:36` — "The
  comp suite — the house always comps your room; surveillance = the house watching its assets").
  "Skill Gemstone" is myth-neutral as a name and can stand unchanged; if anything a gemstone reads
  *more* mythic than corporate.
- **Verdict:** RESKIN (of the containing Lounge only). **Effort:** S.
- **Why:** the only alien-coded thing here is the Lounge's *corporate* voice, which lives in §20 —
  another slice. §4's dependency is a pointer, not a fiction.
- **Already decided?** Yes — Lounge → comp suite is in the adopted Option A mapping.
- **Open question for the owner:** none for this slice.

### D-05 — §4.3 Multi-stat skills (`:180-186`)

- **v1/v2:** identical. "A skill attributed to more than one stat levels only with points from
  **every** listed stat"; "no stat binds the skill's maximum"; three-stat skills are legal
  (Camouflage).
- **Verdict:** KEEP. **Effort:** —
- **Why:** pure point economy. Note only that the stat *names* (Physique/Reflexes/Mind/Charm) are
  Slice C's business; Charm's meaning is RULED as **presentability** (R18,
  `rules-addendum.md:594-601`), which is if anything more myth-legible ("the gods watch the
  beautiful ones") than corporate.
- **Already decided?** R18 yes. **Open question:** none.

### D-06 — §4.4 "Most skills unlock by doing" (`:190-191`)

- **v1 (alien):** "fulfil the obtaining requirement and the skill is revealed at level 0." Every one
  of the 44 templates carries an `achievementUnlock` string (verified: 44/44 present in the export)
  — e.g. Decapitate: "Kill an enemy with a strike to the head from behind with claws."
- **v2 (gods):** unchanged, and *strengthened*. Deed-gated acquisition is the same shape as the
  epithet track, where "when your accumulated pattern **recreates someone's myth, you gain an
  epithet from it**" (`patron-gods.md:135-137`). Skills-by-deed and epithets-by-deed become one
  design language.
- **Verdict:** KEEP. **Effort:** —
- **Why:** an acquisition rule that says "the world notices what you did" needs no alien
  broadcaster. It needed one *less* than the corporate frame, which never explained who was
  watching the unlock.
- **Already decided?** The epithet track is RULED (`patron-gods.md:126-150`, Q2). The *link* between
  skill unlocks and myth templates is not.
- **Open question for the owner:** should a skill's `achievementUnlock` and a myth template's
  `reenactment_hook` (`mythology-research-spec.md:139`) share a detector vocabulary, so that
  earning a skill can partially satisfy a myth? Cheap synergy; risk of double-dipping rewards.

### D-07 — §4.4 External sources: Loot Boxes, Achievements, Lounge modules (`:192-193`)

- **v1 (alien):** "Magic and similar require an **external source**: appropriate-tier Loot Boxes,
  Achievements, or Lounge modules (e.g. the **Wizard's Tower**)."
- **v2 (gods):** boxes → "**Jackpots & comps**; Lounge box-opening = the prize floor"
  (`setting-rebrand-options.md:35`). The Wizard's Tower needs nothing — it is already fantasy
  furniture, and `Loot box tiers: Bronze…Godly` (`:931-933`) already tops out at **Godly**, which
  under v2 stops being a joke about rarity and becomes literal provenance.
- **Verdict:** RESKIN. **Effort:** S (naming only, and the naming lives in §17/§19/§20 — other slices).
- **Why:** "Loot box" is genre-wide LitRPG furniture, not DCC-specific or alien-specific
  (`setting-rebrand-options.md:55-56` makes exactly this argument for the frame swap).
- **Already decided?** Yes (box→jackpot/comp mapping).
- **Open question for the owner:** none for this slice.

### D-08 — §4.4 Skill Tomes (`:194-197`)

- **v1 (alien):** "**Skill Tomes are a legal external source**: consumed in downtime, the named skill
  becomes acquirable at level 0 (named `Skill Tome: <book title>`)… **Limited-magic items** instead
  *cast* one specific skill without ever teaching it (the fireball orb)."
- **v2 (gods):** the mechanism is untouched, but the *object* gets a canon upgrade. Casino canon's
  hard loot rule is: "**loot must feel like remnants of belief**, never generic stat sticks", with
  **God Relics** (true divine artifacts, jackpot-rare) and **Follower Relics** (objects empowered by
  faith) as the two classes (`cosmic-casino-canon.md:156-159`). A Skill Tome becomes a *dead
  religion's scripture, a hero's remembered technique, a fallen god's confiscated grimoire* — and
  the fireball orb becomes a **Follower Relic**.
- **Verdict:** RESKIN. **Effort:** M (a naming/content pass over tome and limited-magic items).
- **Why:** this is the highest-yield RESKIN in §4. v1 never answered "where do tomes come from"; v2
  answers it with an existing hard rule, and the answer generates content for free — every forgotten
  tradition in `data/mythology/` (14 extracted traditions) is a tome supplier.
- **Already decided?** The loot rule is canon (bible material that stands, `cosmic-casino-canon.md:156`).
  The tome→relic mapping is not.
- **Open question for the owner:** do tomes split into the two canon classes (God Relic tomes teach
  magic-class skills; Follower Relic tomes teach mundane ones)? That would let the box tiers
  (`:943-950`) carry the split without new rules.

### D-09 — §4.4 Character-exclusive skills (`:198-199`)

- **v1 (alien):** "Some skills are **character-exclusive** — tied to one contestant's nature."
- **v2 (gods):** unchanged mechanically. Note the two repos have **deliberately diverged**: the
  table RULED **G7 — NO exclusive skills**, replaced by acquisition requirements ("Full Potential =
  'be savvy with your hands and have real repair experience'"; `rulebook/skills-passover.md:29-33`),
  while the game keeps `exclusive_to` for Nikita's Reversion (R12, `rules-addendum.md:485-486`;
  `skills-audit.md` §2 flags it as the one real blocker).
- **Verdict:** KEEP. **Effort:** —
- **Why:** exclusivity is a content-locking device with no premise attached. Under v2 it gains a
  better justification than "your nature": a **patron-granted** skill, or a skill that only exists
  because you re-enacted a specific myth.
- **Already decided?** Yes, twice, differently, on purpose (table G7 vs game R12). Don't reconcile.
- **Open question for the owner:** in the game, should any exclusive skill be **patron-exclusive**
  rather than character-exclusive (i.e. a boon only Ares' champions can ever earn)? That is a
  retention hook and costs nothing.

### D-10 — §4.4's missing teacher (`:188-199`, by absence)

- **v1 (alien):** the book never says *who* teaches you. Skills reveal themselves; boxes contain
  them; the Wizard's Tower produces them. The Corporation is never depicted teaching anyone — the
  premise had no answer, and did not need one because the show was a black box.
- **v2 (gods):** the frame supplies three authors at once, all already canon:
  1. **your patron god** — boons include "conditional blessings" and are delivered diegetically as
     "an inexplicable kindness of the dungeon" (`patron-gods.md:114-120`, `:199-203`);
  2. **the table's fallen god** — the game is run by bankrupt gods of forgotten religions with
     explicit "anything goes" license (`cosmic-casino-canon.md:60-63`), and Enki is canon precedent
     for a *runner who teaches the champion while remaining impartial* (`cosmic-casino-canon.md:105-108`);
  3. **the myth catalog** — recreating a legend's pattern is literally re-walking a past champion's
     shape (`patron-gods.md:139-142`).
- **Verdict:** NEW (an opportunity, not a defect). **Effort:** M.
- **Why:** §4.2's mutation rule already says "**The GM offers** the available upgrade or mutation"
  (`:176-177`) — an unattributed offer. v2 can attribute it: the offer comes from your god, and
  taking a mutation from a *rival's* domain should cost affection. That converts a piece of GM
  furniture into a relationship mechanic at zero rules cost.
- **Already decided?** No.
- **Open question for the owner:** should skill mutations at the Gemstone be **domain-attributed**
  (each mutation tagged to a god's domain, so upgrading is a small act of worship)? Powerful, but it
  couples the skill tree to the patron roster — a real content-maintenance cost.

### D-11 — §4.5 Consuming skills + the keyword tree (`:201-232`; `apply-skill-passover.js:264-309`)

- **v1 (alien):** compatibility runs on 2–4 keywords per skill from a 9-broad / ~30-narrow
  hierarchy: magic (fire·cold·toxin·psychic·force) · strikes · movement · performance · survival ·
  control · perception · infiltration · craft. Share a **narrow** keyword = compatible; broad-only =
  GM call.
- **v2 (gods):** unchanged. I read all 44 keyword assignments: **not one keyword is premise-bearing**
  — the closest is `performance → projection` (assigned to Generate Visual Media and Play to the
  Camera), which is a stagecraft word, not a TV word.
- **Verdict:** KEEP. **Effort:** —
- **Why:** the taxonomy was chosen for *mechanical* joinability, and it happens to be the vocabulary
  of every mythic technique tree ever written.
- **Already decided?** Yes — G3 RULED model A, the keyword tree, 2026-07-23
  (`rulebook/skills-passover.md:11-14`).
- **Open question for the owner:** if D-02 lands (a named divine/radiant class), does `magic` gain a
  sixth narrow keyword (`divine`/`radiant`)? It would make god-granted magic *incompatible* with
  mortal magic at the Gemstone unless the GM allows it — a nice, cheap piece of texture.

### D-12 — §4.6 Priming — "there are no cooldowns" (`:234-248`)

- **v1 (alien):** five prime types — CHAIN, STANCE, STACK, STATE/POSITION, PREP/CHANNEL. "Powerful
  skills are gated by **preparation, not waiting**."
- **v2 (gods):** unchanged, and this is the **load-bearing design idea of the whole system for v2**
  (see D-45): a prime is a *requirement*, and requirements are the only thing in the engine that an
  outside agent can legitimately supply or deny.
- **Verdict:** KEEP. **Effort:** —
- **Why:** the single theme leak is the STACK row's example — "Camera Call stacks" (`:243`) — which
  is an *example*, not the rule, and Camera Call itself is already mapped ("the odds board turns to
  you", `setting-rebrand-options.md:33`).
- **Already decided?** R3 rules no-cooldowns for the digital sim (`rules-addendum.md:68-108`); the
  last two cooldown texts (Tactical Roll, Acrobatic Save) were re-ruled by G1/R25 as a
  **movement-forfeit** dodge (`rules-addendum.md:811-869`). Note the stale export still contains
  "Cooldown: 1 Clock" on both — data debt, not a v2 issue.
- **Open question for the owner:** none.

### D-13 — §4.7 Passive and reactive skills (`:250-255`)

- **v1/v2:** identical. Passives always on; reactives declare a trigger and pay by delaying your
  next scheduled action (§5.6).
- **Verdict:** KEEP. **Effort:** —
- **Why:** trigger grammar. No fiction.
- **Already decided?** Ladder default #1 governs how passives generalize
  (`skills-r19-ladders-FINAL.md:29-31,619-624`). **Open question:** none.

### D-14 — §5 The Clock, all of it (`:259-354`)

- **v1 (alien):** 10 Moments counting 10→1, declare-and-resolve scheduling, cross-boundary
  arithmetic, instants vs windups, simultaneity ("two lethal same-Moment attacks **both land**"),
  the per-Moment action cap, movement and inventory economies, reactions, and combined actions
  ("assists provide requirements"; merged damage counts as ONE hit).
- **v2 (gods):** identical. **Proof:** grepping §5's 96 lines for
  `corporation|alien|broadcast|camera|viewer|audience|crowd|sponsor|TV|show|ratings|studio` returns
  **exactly one hit** — `:243`, which is in §4.6, not §5. §5 itself is clean.
- **Verdict:** KEEP. **Effort:** —
- **Why:** this is a timing model. It would be identical in a submarine sim.
- **Already decided?** Extensively — R0/R1/R2/R3/R15 in the addendum, and the engine implements it
  with 22 green tests (`setting-rebrand-options.md:102-103` lists "the Moment clock, all combat
  rules, per-part HP, the addendum, the engine and its 22 green tests" among *what stays untouched*
  under the frame swap). This is the strongest existing statement that my slice is a KEEP.
- **Open question for the owner:** none.

### D-15 — §1's timescale flavour (`:34-36`)

- **v1 (alien):** "in the fiction, a full Clock is roughly **five seconds**… the table's
  deliberation is **the broadcast's slow-motion replay**."
- **v2 (gods):** the gods' gallery gets a replay too — this is one sentence, and the casino frame
  keeps the broadcast diegetically anyway (`setting-rebrand-options.md:110-119`: GPT becomes a VIP
  table whose in-fiction skin *is* a human reality show).
- **Verdict:** RESKIN (optional). **Effort:** S.
- **Why:** listed only because it is the sole place the Clock's *fiction* is explained, and it is
  explained in TV terms. Cheapest possible fix; arguably needs none at all.
- **Already decided?** The broadcast survives diegetically — RULED (`setting-rebrand-options.md:118-119`).
- **Open question:** none.

### D-16 — §6 Forced Actions (`:358-395`)

- **v1 (alien):** "Any action taken while unsafe, impaired, or unqualified. **Always allowed.**"
  Two d6 tables (Body: Tear Something / Lock-Up / Condition Surge / Drop / Shock Spike / Stumble;
  Tool: Whiff / Overcommit / Collateral / Slip / Strained Grip / Overextension) + §6.2's
  requirements gate (Forced Action **and** halve the effect).
- **v2 (gods):** unchanged — and this is where the divine layer should attach (D-44).
- **Verdict:** KEEP. **Effort:** —
- **Why:** twelve consequences, all physical or mechanical. Not one of them references the show, the
  Corporation, or the audience. The d6 is also the only *player-visible* random number in melee,
  which makes it the natural target for a god's tip.
- **Already decided?** The spine is a hard rule in the game repo
  (`Galactic-Prime-Time-Game/CLAUDE.md`: "No to-hit rolls — requirements auto-succeed; Forced Action
  d6 handles the failure path").
- **Open question for the owner:** see D-44.

### D-17 — §7 Bodies & Damage (`:399-458`)

- **v1 (alien):** localized HP (Head 2 lethal, Torso 5 lethal, arms 2, legs 3); head untargetable
  unless Exposed/Helpless/Overwhelmed; damage → part → condition; disabled-part consequences; death
  and the 1-Clock bleed-out.
- **v2 (gods):** identical. R21's Lego-style part composition (`rules-addendum.md:670-693`) already
  generalizes bodies past humans, which a myth setting wants (a hydra needs seven head-equivalents).
- **Verdict:** KEEP. **Effort:** —
- **Why:** anatomy. The only sentence with any setting in it is the Robot/AI sidebar at `:74-85`,
  which is §2 (Slice C) and is already game-side removed by R16.
- **Already decided?** R4/R5/R7/R14/R21. **Open question:** none.

### D-18 — §7.4's recovery routes (`:444-446`)

- **v1 (alien):** severed parts come back via "the **Surgeon's Table**, prosthetics (the
  **Augmentation Hub**), regeneration skills, high-end healing skills, and truly exceptional potions."
- **v2 (gods):** the two named modules are Lounge furniture (Slice E). Worth flagging here only
  because a *gods* frame invites the question "is a mechanical arm still on-theme?" — and canon says
  yes, loudly: Viola is reforged into a machine by a race that worships **Deus Ex Machina**, keeping
  a miniature sun in her chest (`cosmic-casino-canon.md:113-122`). Machine bodies are casino-native.
- **Verdict:** RESKIN (names only). **Effort:** S.
- **Why:** prevents a false "cut the cyberware" conclusion downstream.
- **Already decided?** R16 removed the **Robot race** from the game
  (`rules-addendum.md:574-578`) — that is a *playable-race* ruling, not a ban on prosthetics.
- **Open question for the owner:** does the Augmentation Hub get a myth patron (Hephaestus /
  Daedalus / Ptah) as its in-fiction proprietor? Free flavour, and it makes a craft-god relevant.

### D-19 — §8.1 The universal condition engine (`:464-477`)

- **v1 (alien):** apply at T1 on first application; re-application advances one tier (max one
  attack-driven advance per part per Moment); **every Clock reset advances every active non-delayed
  condition**; Active/Delayed/Resolved; field treatment delays, full resolution needs downtime.
- **v2 (gods):** identical.
- **Verdict:** KEEP. **Effort:** —
- **Why:** independently audited and found premise-free: the game repo's residuals audit says of
  `data/conditions.json` — "all 9 rulebook conditions present and matching the CLAUDE.md
  vocabulary… **No cooldown language, no corporate language**"
  (`campaign-residuals-audit.md:279-283`). That is a third-party proof of theme-neutrality for the
  entire condition layer, done before this question was asked.
- **Already decided?** R4. **Open question:** none.

### D-20 — §8.2 The nine condition names and their tiers (`:479-567`)

- **v1 (alien):** Bleeding · Crushed · Burn · Chilled · Exhausted · Infected · Poison (5 types +
  Poison Soup + spread) · Suffocation · Dissolution. Damage types = the 7 resistance keys
  (Bleed/Crush/Burn/Chill/Poison/Infection/Dissolution).
- **v2 (gods):** unchanged. Every name is plain-English physiology or plain-English chemistry —
  none is sci-fi (contrast: no "plasma", "radiation", "EMP", "nanite", "neural spike"). Even the
  poison sub-types (Neuro/Hemo/Myo/Pneumo/Cyto-toxin) are Greek-rooted medical vocabulary, which
  reads *classical*, not futuristic.
- **Verdict:** KEEP. **Effort:** —
- **Why (the proof for "does a gods premise want new damage types"):** the v2 side already ran this
  experiment. `data/domain_condition_map.json` maps all **26 controlled mythology domains** onto
  the **9 rulebook conditions** and records the result honestly: 13 domains get a condition
  affinity, **13 deliberately get an empty list** with a stated rationale, under an explicit
  `empty_list_rule` ("a domain with no clean condition fit gets an empty list ON PURPOSE (owner:
  leave empty rather than force)"). War→bleeding+crushed, sea→suffocation+chilled,
  sun_fire→burn, death_underworld→dissolution, disease_poison→poison+infected,
  madness_dream→dissolution, travel_speed→exhausted, beasts_wild→bleeding+poison. **Not one domain
  demanded a condition the book lacks.** The empties are all domains that act on *tags, affixes and
  hype* (wisdom, luck_gambling, wealth_commerce, love_beauty, poetry_story, justice_oaths,
  protection_home, healing, earth_harvest, magic, trickery, chaos, time_fate) — i.e. the gods want
  a **non-damage** surface, not a new damage type. That is finding D-44.
- **Already decided?** Yes — the map is Wave-5 output, generated against the owner-approved domain
  vocabulary (`mythology-research-spec.md:274-288`).
- **Open question for the owner:** none on damage types. (The real question is D-44.)

### D-21 — §8.2 Dissolution, ex-"Psychic" (`:562-567`)

- **v1 (alien):** "the Mind's Suffocation: a **tierless 2-Clock death timer on the Mind**… cannot be
  applied by standard attacks — requires an explicit source… **Completion = the mind collapses: the
  contestant is permanently removed from play.** No revival… it is worse than death."
- **v2 (gods):** this is already v2's soul-damage and needs no change. The vocabulary migration
  Psy→Dissolution was executed on the campaign DB on 2026-07-25
  (`Galactic-Prime-Time/CLAUDE.md` Known Backlog §2) — and "Dissolution" is an *alchemical* word
  (the **solve** of solve-et-coagula), not a sci-fi one. The rename moved the vocabulary **toward**
  myth before anyone asked it to.
- **Verdict:** KEEP (and flag as an asset). **Effort:** —
- **Why:** a gods premise needs a fate worse than death that gods can inflict and mortals mostly
  cannot. §8.2 already wrote it, already made it source-gated ("requires an explicit source"), and
  R5's amendment already made the victim **a puppet of the collapser**
  (`rules-addendum.md:713-716`). The demonic-nobility encounter pattern — presence alone starts the
  Mind timer, each victim hears a **personal song** targeting their core emotional drive, embrace =
  ghoul, escape = permanent scar (`GPT_Master_Compendium.md:100-106`, adopted as R12) — is a
  ready-made *divine-presence* encounter with the serial numbers already filed off.
- **Already decided?** R4/R5/R12/R13 and the 2026-07-25 migration.
- **Open question for the owner:** should **divine presence** (a god or a god's avatar physically at
  the table) use the demonic-nobility Dissolution pattern verbatim? It is the strongest "you are in
  the presence of something you should not be near" mechanic the book has, and re-using it costs
  nothing.

### D-22 — §9 Shock (`:577-601`)

- **v1 (alien):** momentary events, not a pool; stated tier applies directly; high-water mark;
  repeated abuse of the same wound elevates +1; T1 Shout / T2 Stutter / T3 Faint / T4 Helpless;
  no decay, full reset at combat end; Burn T1's cauterize costs Shock T1.
- **v2 (gods):** identical.
- **Verdict:** KEEP. **Effort:** —
- **Why:** a pain-response model. Zero premise words. The only interesting v2 note is upside: Shock
  T1 "**breaks stealth**" is exactly the hook a rival god's curse would want to force (R20's
  destealth curse, `rules-addendum.md:658-660`) — the mechanism already exists.
- **Already decided?** R13, approved and finalized (`rules-addendum.md:495-519`).
- **Open question:** none.

### D-23 — §10 Resistances (`:605-618`)

- **v1 (alien):** flat resistances reduce HP damage and **never** block condition application;
  Physical (flat) / Affliction (tiered) / Psychic (tiered); psychic tiers **slow the Dissolution
  timer by +1 Clock each**; enemy mental resistance is FLAT and beating it by a margin grants a
  bonus ("**viewer spike** / secondary effect"); "player affliction resistance… is GM-awarded,
  explicitly, when earned."
- **v2 (gods):** two small gains. (1) "viewer spike" is the one broadcast word in §10 — it becomes
  the odds board / bet-volume spike, already mapped. (2) The GM-awarded affliction resistance
  becomes the cleanest **patron boon lane** in the book: a ward from a `protection_home` or
  `healing` god is exactly "GM-awarded, explicitly, when earned", and
  `domain_condition_map.json` already records that these domains "prevent and resist rather than
  inflict… applied as ward/resist boons across conditions".
- **Verdict:** KEEP (with one word reskinned). **Effort:** S.
- **Why:** the resistance taxonomy is mechanical; only the reward flavour is premised.
- **Already decided?** The domain-as-ward reading is in the map's `direction_note`
  ("an affinity is a thematic link the systems may use to INFLICT (enemy/curse) OR to CURE/RESIST
  (boon)"). The *binding* of affliction resistance to patron boons is not.
- **Open question for the owner:** is tiered affliction resistance **the** signature permanent boon
  of protection/healing gods? It is currently the only stat in the game with no automatic source —
  a perfect vacancy for the patron layer to fill.

### D-24 — §11 States Glossary (`:622-632`)

- **v1/v2:** Exposed · Helpless · Prone · Slowed · Channeling · Overwhelmed · Alerted.
- **Verdict:** KEEP. **Effort:** —
- **Why:** seven mechanical adjectives, each defined purely in terms of what you may and may not do.
  No premise is expressible here.
- **Already decided?** R7 (`rules-addendum.md:186-202`). **Open question:** none.

### D-25 — §13 Grappling (`:778-790`)

- **v1/v2:** free hand + at most one size larger; initiate auto-succeeds on Physique ≥ theirs, else
  Forced Action–Body; two-sided lock (both Exposed, neither repositions); escape 2 Moments
  automatic / 1 at Physique parity; grapple-Suffocation needs both hands + a coverable airway and
  **bosses are immune** — "Boss win conditions are discovered, not choked out."
- **Verdict:** KEEP. **Effort:** —
- **Why:** wrestling physics plus an anti-cheese clause. Nothing to reskin. Note the myth-facing
  upside: grappling is the *most* mythologically loaded combat verb in the book (Herakles &
  Antaeus, Jacob & the angel, Gilgamesh & Enkidu) — several already-extracted myth records are
  grapple-shaped.
- **Already decided?** R9. **Open question:** none.

### D-26 — §14 Dodge Thresholds (`:794-815`)

- **v1/v2:** "Miss" is never universal; a threshold asks the dodger's **Reflexes** — meet it and
  auto-dodge, else add the stat's threshold die (default 1d4); no dodging while Helpless/Exposed/
  Prone; collateral, condition, forced-action and environmental damage are never dodged; authored
  counter-ladders (Reflexes 7 = sidestep, 9 = free counterattack).
- **Verdict:** KEEP. **Effort:** —
- **Why:** premise-free. But note: this is the **second** random surface in the engine (after the
  Forced Action d6), it is explicitly **per-stat and upgradeable**, and R22 already generalizes it
  ("the field is per-stat so future stat-threshold checks (Mind vs fear, Physique vs forced
  movement) inherit the mechanism", `rules-addendum.md:740-742`). That makes it the natural home for
  divine influence — see D-27 and D-44.
- **Already decided?** R22 (`rules-addendum.md:724-760`), R24 extends the same machinery to
  feint-reads on Mind, R25 keeps Tactical Roll orthogonal to it.
- **Open question:** none here; see D-44.

### D-27 — §14's threshold-die upgrades happen at the **Tattoo Artist** (`:809-812`)

- **v1 (alien):** "Threshold dice are upgradeable, per stat (d4 → d6 → d8) at the **Tattoo Artist**
  (§20.3 — d4→d6 = 5 UT, d6→d8 = 40 UT)."
- **v2 (gods):** a tattoo parlour in a comp suite is fine, but a **god's mark** is better and
  already sanctioned: patron boons may be "**permanent** — sometimes, depending on the buff"
  (`patron-gods.md:118-120`), and the epithet track is explicitly about being *marked* by
  comparison to legends.
- **Verdict:** RESKIN. **Effort:** S.
- **Why:** it converts an Upgrade-Token sink into a favour sink without touching a single number,
  and gives the patron layer its one genuinely permanent mechanical footprint in combat.
- **Already decided?** No.
- **Open question for the owner:** do threshold-die upgrades stay purchasable with Upgrade Tokens,
  become patron-granted, or both (bought marks are shallow; god-given marks are deep)? Note this
  interacts with D-03 — if both the skill cap and the dice ladder become favour-gated, the patron
  becomes the *entire* progression economy, which may be more than you want.

### D-28 — §15 Stealth, Detection & Cover (`:819-841`)

- **v1/v2:** vision ≈ 2× Mind in spaces through a cone; seen = not stealthed; hearing →
  investigate/ignore/react, with **Alerted** (knows something, not where) as deliberate design
  space; disguise defeats recognition outside a stated range; cover is geometric with real heights
  and sized gaps; Shock T1 breaks stealth.
- **Verdict:** KEEP. **Effort:** —
- **Why:** geometry and perception. Nothing setting-bearing except the audience line (D-29).
- **Already decided?** R20 is the complete model, RULED (`rules-addendum.md:632-668`).
- **Open question:** none.

### D-29 — §15 "Stealth does not suppress the audience" (`:837-839`)

- **v1 (alien):** "Sneaking impeccably past every guard IS spectacle… What you *do* with stealth
  determines the crowd's reaction, not the hiding itself."
- **v2 (gods):** unchanged in substance — the gallery is still watching — and the *enforcement*
  question is already answered: R20 rules that "**Production NEVER interferes directly in the
  show**… The diegetic destealth lever is **rival gods**: a rival patron can **curse you unstealthy
  / out you** as a divine intervention" (`rules-addendum.md:656-660`).
- **Verdict:** KEEP. **Effort:** —
- **Why:** flag it as **already decided** so nobody re-litigates it: this is the first and currently
  only place in the ruleset where a *god* is named as the mechanism of an in-combat effect. It is
  the precedent D-45 generalizes.
- **Open question:** none.

### D-30 — §21.1 Enemy categories (`:1250-1256`)

- **v1/v2:** Mobs (die in one meaningful blow, never alone) · Elites (real statlines, personalities)
  · Bosses · Super Bosses.
- **Verdict:** KEEP. **Effort:** —
- **Why:** a pure scale ladder, and it is load-bearing in code:
  `simulation/enemy_ai.gd:33` — `const AI_CATEGORIES := ["Mob","Elite","Boss","Super Boss"]`, with
  behaviour branching on it at `:117`; `data/enemies.json` uses `category` on all 3 seeded enemies.
  Renaming the categories costs engine work for no thematic gain.
- **Already decided?** Implemented. **Open question:** none.

### D-31 — §21.1 The Boss variant ladder: **Neighbourhood → District → City** (`:1254`)

- **v1 (alien):** three rungs describing the scale of what the boss dominates.
- **v2 (gods):** urban-civic rather than TV-coded, so it *survives* — but it is a modern-municipal
  register in a setting whose other ladders are myth-graded (folk_tale < local_legend < heroic_epic
  < world_myth, `mythology-research-spec.md:260-271`) or house-graded (Normal/VIP/VVIP;
  Bronze→Godly).
- **Verdict:** RESKIN (optional). **Effort:** S.
- **Why:** consistency, not necessity. If D-32 changes the Super Boss rungs, leaving the Boss rungs
  municipal creates a two-register ladder.
- **Already decided?** No. The ladder is catalogued as "still LIVE and unadopted — usable as-is",
  landing with KAN-4 AI (`campaign-residuals-audit.md:383`).
- **Open question for the owner:** see D-32's proposal, which covers both halves.

### D-32 — §21.1 The Super Boss ladder: **Precinct → Country → Stage** (`:1255-1256`)

- **v1 (alien):** "Super Bosses — Precinct → Country → Stage (a **Stage boss is not expected to be
  beaten**)." "Precinct" is US civic-police vocabulary; "Stage" is television — it means *the level
  of the show at which this thing is a fixture*.
- **v2 (gods):** needs replacing. The requirement is a **six-rung escalation** (3 Boss + 3 Super)
  whose top rung means "not expected to be beaten", expressed in the casino/myth register — and it
  must **not collide** with three ladders that already exist: table tiers (Normal/VIP/VVIP), box
  tiers (Bronze→**Godly**), and myth grades (folk_tale→world_myth). That rules out any proposal
  ending in "Godly" or "World Myth" as ambiguous.
- **Verdict:** RESKIN. **Effort:** S (naming + one engine enum if the Boss rungs are ever encoded;
  today they are prose only — `enemy_ai.gd` encodes the *category*, not the *variant*).
- **Why:** it is the one genuinely premise-locked name in §21.
- **Proposal — recommended: the belief-scale ladder.** Bosses: **Shrine → Temple → Pantheon**.
  Super Bosses: **Legend → Age-Ender → The House**.
  Rationale: the rungs measure *how much belief feeds the thing*, which is the divinity economy's
  own unit (`cosmic-casino-canon.md:38-46`); "The House" carries "not expected to be beaten"
  perfectly (you do not beat the house), and it is casino-native rather than borrowed; "Age-Ender"
  ties to the ~250-year cycle without stealing the myth-grade vocabulary.
- **Alternative A — wager-graded (most casino-native):** Bosses **Side Bet → Table Stakes → High
  Roller**; Super Bosses **Jackpot → All-In → The House**. Pro: uses the tipping/wager language
  verbatim. Con: bets are about *the audience*, not about the monster — the rungs stop describing the
  creature.
- **Alternative B — myth-graded (maximum content synergy):** Bosses **Folk Tale → Local Legend →
  Heroic Epic**; Super Bosses **World Myth → Cataclysm → The House**. Pro: a boss's rung is then the
  same grade as the myth a player could re-enact, so the epithet catalog and the bestiary index each
  other. Con: overloads `grade`, which is already a `myths.jsonl` field
  (`mythology-research-spec.md:133`) — two meanings, one word.
- **Already decided?** No. The ladder is unadopted (`campaign-residuals-audit.md:383`) and one
  Stage-tier Super Boss template is budgeted (`:269`).
- **Open question for the owner:** pick a ladder — and confirm whether the Boss and Super Boss
  ladders must share a register (I recommend yes).

### D-33 — §21.2 Construction guidance + the horde doctrine (`:1258-1273`)

- **v1 (alien):** asymmetric statting is by design (player parts 2–5 HP, boss parts 6–50); "stat the
  *character*, not the process"; **mobs are hordes — nearly always one-shot** by an on-band weapon
  (~5 HP at F1 doubling per floor to ~1.3k at F9); a mob that survives does it through a **special
  effect**, never a fat HP bar; first-pass ratios elite ≈ ×12, boss ≈ ×25, Super ≈ ×60; "**enemies
  win by creating problems faster than the party can manage** — never by out-rolling."
- **v2 (gods):** identical. The only coupling is to the **material band** of the floor (§12.7), and
  material progression (bronze → iron → star-metal) is *more* myth-native than sci-fi-native.
- **Verdict:** KEEP. **Effort:** —
- **Why:** this is the most premise-free page in the chapter — it is arithmetic and doctrine. The
  horde doctrine in particular ("mob fights are about the crowd: cones, lines, positioning, ammo
  burn", `:1267`) uses "crowd" to mean *the crowd of enemies*, not the audience — worth noting so
  nobody grep-reskins it by mistake.
- **Already decided?** Encounter baseline (party of 3 handles ~12/room) is ruled
  (`rules-addendum.md:702-703`). **Open question:** none.

### D-34 — §21.3 Boss doctrine — discoverable win conditions (`:1275-1297`)

- **v1 (alien):** "Most bosses' win condition is reaching the position where a killing hit is even
  possible — not the hit itself. Raw damage races are anti-design." Authored patterns: surface
  immunity (breach at Bleeding T2 or 7+ single-hit damage), phase machines, dodge thresholds with
  Reflexes counter-ladders, fire that heals, destroyable sub-parts. Bosses immune to grapple-
  Suffocation "and to anything else that skips discovery". Super Bosses are multi-stage, multi-area
  campaign arcs (the five-zone flower).
- **v2 (gods):** unchanged mechanically, and *massively* strengthened in content. v2 supplies the
  best possible answer to "what is the discoverable condition?" — **the myth says how it dies.** The
  already-executed mythology research authors exactly this shape without being asked to: Beelzebub —
  "immune while his fly-swarm feeds on a filth-source; discoverable win condition is to burn the
  corpse/refuse pile that spawns the swarm — **starve, don't out-DPS**"; Asmodeus — "rage-scaling:
  he grows stronger each time you attack in wrath, so **fight cold**"; Lilith — "**ward-not-force**:
  recover and inscribe the three-angel amulet to bind her"
  (`docs/research/mythology/abrahamic_folk.md:51,56,61`). The research spec already *requires* it:
  beasts must fill `game_hooks` with "a discoverable-win-condition idea — bosses are never damage
  races" (`mythology-research-spec.md:121-126`).
- **Verdict:** MECHANICAL (one added doctrine line). **Effort:** S.
- **Why:** the doctrine currently lists *patterns*; v2 should add a *sourcing rule* — "prefer a win
  condition the party could deduce from the creature's story; the bestiary entry is a hint sheet."
  This turns lore-reading into a mechanical advantage, which is the whole point of a myth setting,
  and it makes the enemy pool self-authoring.
- **Already decided?** The research contract is RULED and executed for 14 traditions.
  The doctrine line is not.
- **Open question for the owner:** should the **Wiki/HUD bestiary** be allowed to *state* the myth
  (making the win condition findable out-of-combat), or must it be discovered in the fight? The
  first is a knowledge-reward loop; the second protects the discovery beat.

### D-35 — §21.4 Terrain authoring framework (`:1299-1308`)

- **v1 (alien):** stat terrain by answering three questions — is it hard to walk in (and why)? is it
  a hazard (and how)? what non-danger effects does it have (vision, noise, cover, flammability,
  smell)?
- **v2 (gods):** the three questions are premise-free and stay. But casino canon adds a **hard
  authoring rule the framework does not ask**: "each arena is shaped by the **judge/director god's
  psyche** — symbolic, psychological, surreal; never just physical"
  (`cosmic-casino-canon.md:75-77`).
- **Verdict:** MECHANICAL (add a fourth question). **Effort:** S.
- **Why:** without it, terrain authoring will keep producing mud and fire, and the arenas will not
  carry the setting. The fourth question — *whose mind is this room, and what does it want you to
  feel?* — is free to ask and changes every table it touches.
- **Already decided?** The arena rule is bible material carried into the canon inventory; its
  application to §21.4 is not.
- **Open question for the owner:** is the arena's god the **table's fallen-god runner** (one psyche
  per run, coherent dungeon) or **per-floor** (a different god per floor, anthology-style)? The
  first is cheaper and more legible; the second gives more variety.

### D-36 — §21.5 Falling (`:1310-1315`)

- **v1/v2:** falls over 3 hexes deal ~1d4–5d4 across 3–8 m, 2d6–6d6 across 9–14 m, "(A sketch —
  falling has barely come up in play; tune it when it matters.)"
- **Verdict:** KEEP. **Effort:** —
- **Why:** gravity. Note only that it is a *third* dice surface (D-44) and that §14 explicitly makes
  environmental damage undodgeable (`:807-808`), so a fate god's nudge would be the only counterplay
  to a fall — a small, evocative design space.
- **Already decided?** No; explicitly parked by the book itself. **Open question:** none.

### D-37 — The existing bestiary's myth-compatibility (`GPT_Master_Compendium.md:100-106,206-208,282-284`; `data/enemies.json`)

- **v1 (alien):** the seeded/campaign bestiary is **demons** (normal demons = fallen comprehensible
  humans; **demonic nobility** corrupts through existence alone), the **Loong** and **Loong Kin**
  (an East-Asian dragon the party persuades, escorts, and protects across three floors), the
  **Incinedile** (apparent flamethrower reptile, actually a **mycelium puppet** with a hidden 50-HP
  network and a surface-immunity breach), plus roach-dogs and the Little Brother Roach elite.
- **v2 (gods):** it is *already* a myth bestiary. A dragon, a hierarchy of demons with a corrupting
  nobility, and a body-snatching fungal false-beast are three of the most mythologically legible
  monsters you could pick — none of them requires aliens, a Corporation, or a broadcast. The only
  alien-coupled thing in this area was the setting's *mycelium-Corporation*, which the rebrand doc
  named as the problem (`setting-rebrand-options.md:4-5`) — and that is the **Corporation**, not the
  Incinedile: the boss keeps its puppet design untouched (`data/enemies.json` id 3;
  `docs/gdd/decision-log.md:194,206,261,271`).
- **Verdict:** KEEP. **Effort:** —
- **Why / already decided:** stated outright — "demons/Loong **explicitly survive the frame swap**"
  (`campaign-residuals-audit.md:386`), and "**What stays untouched:** the dungeon itself (floors,
  routes, time skips, demons, Loong, Incinedile)…" (`setting-rebrand-options.md:101-104`). Do not
  re-litigate.
- **Open question for the owner:** do demons get **re-parented** to a tradition (goetic/Abrahamic
  folk is already extracted and full of them, `abrahamic_folk.md`), or stay the campaign's own
  original species? Re-parenting buys a hundred authored enemies; staying original protects the
  demonic-brand contract story (`story-canon.md:6-37`).

### D-38 — Enemies have no allegiance/disposition axis (`data/enemies.json` by absence; `cosmic-casino-canon.md:150-155`)

- **v1 (alien):** enemies are enemies. §21.1's only axis is *scale*; the data model
  (`data/enemies.json`) carries `category, size, body_parts, stat_block, resistances, abilities,
  reward_table, personality` — **no allegiance, disposition or faction field**. Hostility is decided
  purely by a differing `team` string (`rules-addendum.md:331`).
- **v2 (gods):** canon defines monsters as "collateral **followers of gods** dragged into the
  framework", in **three states** — **Insane Followers** (hostile, XP), **Sane Followers** (aware:
  traders, allies, quest-givers) and **Worshipped Creatures** (revered beings, moral dilemmas)
  (`cosmic-casino-canon.md:150-153`). That third state already exists in the campaign as the Loong
  (persuade it, escort it, protect it — `GPT_Master_Compendium.md:282-284`), but it exists as
  *narrative*, with no data field saying so.
- **Verdict:** NEW. **Effort:** M (a field + AI branch + content pass).
- **Why:** this is the one place where v2's premise genuinely asks the enemy system for something
  v1's does not model. It also pays: a "Sane Follower" is a mid-dungeon trader without a new system,
  and a "Worshipped Creature" is a moral-dilemma encounter whose *win condition is not killing it* —
  which is exactly §21.3's doctrine pointed at a non-combat target, and exactly the spine's
  question-architecture (`story-canon.md:60-93`).
- **Already decided?** The three states are canon (bible material that stands). The data model is not.
- **Open question for the owner:** does disposition belong on the **enemy template** (a species is
  sane or insane) or on the **encounter** (the same species appears in all three states depending on
  the floor)? Per-encounter is far more interesting and only slightly more expensive.

### D-39 — Skill NAMES: the classification (`galactic-prime-time.skilltemplates.json`, 44 rows)

Full counts, buckets and ~15 worked examples are in the dedicated section below
("Skill-name classification"). Summary: **22 myth-neutral · 10 already myth-friendly · 9
sci-fi/tech-coded · 3 TV/pop-coded**. Verdict: KEEP 32, RESKIN 12 (of which only ~4 are worth
actually renaming). **Effort:** S.

### D-40 — Skill DESCRIPTIONS: the pop-culture quips (44 `description` fields)

- **v1 (alien):** every skill carries a one-line quip, and at least **9 of 44 are direct pop-culture
  quotations**: "Another one bites the dust" (Queen), "Bullet time" (The Matrix), "Hold me close,
  Jack" (Titanic), "We need to build a wall" (a political catchphrase), "Fireball!" (tabletop),
  "Look at MacGyver over here", "Like a superhero landing, only lethal!", "Do a barrel roll!" (Star
  Fox), "Bug, or Feature?" (software culture). Several more are idiom-or-meme shaped ("Yoink",
  "Bonk", "Sneaky sneaky", "Slice n' Dice", "Not even close, baby!").
- **v2 (gods):** **keep every one of them.** This is the counter-intuitive finding of the slice. The
  quips look like the most premise-locked text in the catalogue and are in fact the most
  *canon-licensed*: VIP tables are "**special games designed around what the gods found interesting
  during the quarter-millennium — mostly human pop culture**" (`cosmic-casino-canon.md:24`), and the
  rebrand explicitly concludes "**A reality-TV dungeon crawler is exactly what gods who binge-watched
  humanity would build**" (`setting-rebrand-options.md:110-117`). A god quoting Queen at a dying
  contestant is not a leak; it is the thesis.
- **Verdict:** KEEP. **Effort:** —
- **Already decided?** Yes — the diegetic-TV ruling (`setting-rebrand-options.md:118-119`,
  D3 in DIRECTION.md).
- **Open question for the owner:** only one, and it is tonal: should the *system voice* (the HUD)
  keep quoting human pop culture in the game, given canon says the HUD "renders Greek then shuffles
  to English" (`cosmic-casino-canon.md:163-165`)? A pantheon that quotes badly is funnier than one
  that quotes well.

### D-41 — Broadcast vocabulary inside effect and level text (6 skills, exact list)

- **v1 (alien):** grepping all 44 templates' `effect|description|requirements|target|range|
  achievementUnlock|levelEffects` for broadcast words returns **6 skills**:
  **Decapitate** ("Cinematic Kill — gain 1 Viewer spike"), **Heroic Punch** ("a visible POW graphic…
  Gain 1 Viewer spike on a Head hit"), **Generate Visual Media** ("Face Screen", "Viewer spike",
  "images/video"), **Dance** ("crowd reactions"), **Strong Strike** ("The crowd holds its breath" —
  description only), **Nightlurking** (L6: "**Minimap** reveals layout 5 km around").
  A second grep for machine/tech words returns **4**: **Voicebox** ("fools **machinery** and **voice
  recognition software**"), **Generate Visual Media** ("Face Screen"), **Ignore All Previous
  Commands** ("**Prompt Mode**"), **Nightlurking** ("minimap").
- **v2 (gods):** "Viewer spike" and "crowd" survive as the house's own vocabulary (spectator gods,
  bet volume) — a one-word swap at most, and arguably none. The genuine leaks are **three specific
  strings**: `Face Screen` (robot hardware — already cut, D-42), `voice recognition software` (a
  modern-tech listener), and `Minimap … 5 km` (a HUD element *and* a scale error the audit already
  flagged, `skills-audit.md` nightlurking row).
- **Verdict:** RESKIN. **Effort:** S — three strings.
- **Why:** worth stating precisely because "the skills are full of TV language" is the intuitive
  guess and it is **false**: 6 of 44 (13.6%), and 4 of those 6 are single words.
- **Already decided?** The minimap wording is already flagged for rewrite ("keep 'minimap' diegetic —
  the System's chat/HUD channel"; scale-honest L6 proposed).
- **Open question for the owner:** does the in-fiction HUD stay a HUD in v2? Canon says yes (the
  System with its "chipper intrusive personality", `cosmic-casino-canon.md:160-166`) — which means
  "minimap" is fine and only the 5 km is wrong.

### D-42 — The two robot/AI joke skills (Generate Visual Media, Ignore All Previous Commands)

- **v1 (alien):** Generate Visual Media requires "Face Screen must be operational" (robot hardware);
  Ignore All Previous Commands is an LLM prompt-injection gag ("enter **Prompt Mode**").
- **v2 (gods):** **already cut from the game.** Owner ruling 2026-07-17: "Joke skills cut
  (ignore_all_previous_commands, generate_visual_media — robot orphans)"
  (`rules-addendum.md:706-707`), following R16's removal of the Robot race
  (`rules-addendum.md:574-578`). Table-side they **stay** — G5 confirms XQUEZ/T exists at the live
  table so both remain table-canon with concrete definitions (`rulebook/skills-passover.md:35-44`).
- **Verdict:** CUT (game) / KEEP (table). **Effort:** — (done).
- **Why:** listed so the divergence is not mistaken for drift. It is deliberate: the video game
  removed robots, the TTRPG did not.
- **Open question:** none.

### D-43 — The "spectacle L10" rung (`skills-r19-ladders-FINAL.md:47-49,585-591`)

- **v1 (alien):** ladder default #6 — "Performance/audience skills: CHARM scales the crowd payoff,
  and a shared '**spectacle rung**' (a **Camera-Call-tier capstone**) is the STANDARD L10", applied
  to Dance, Vibe Control, Heroic Punch, Juggling; deliberately *not* given to Voicebox (infiltration,
  not crowd-work) or to combat skills that merely spike Viewers as a by-product.
- **v2 (gods):** identical mechanic, different noun: the capstone swings the room and "spikes
  Viewers/patron bids" — under v2, **patron bids** is already the more interesting half, and
  Camera Call is already mapped to the odds board.
- **Verdict:** RESKIN. **Effort:** S.
- **Why:** the *discrimination* the default makes (audience-facing vs not) is exactly the
  discrimination v2 wants, because the gods are the audience. Nothing to redesign.
- **Already decided?** Yes — owner accepted all 10 framework defaults (decision-log #14).
- **Open question:** none.

### D-44 — **The fate/odds surface: the one real gap** (`:364-389`, `:794-815`, `:1310-1315`; `data/patron_roster.json`; `data/domain_condition_map.json`)

- **v1 (alien):** the engine exposes randomness in exactly four places — the **Forced Action d6**
  (§6.1), the **R22 threshold die** (§14, d4 default, per-stat, upgradeable), the **R24 feint-read
  die** (same machinery on Mind), and the **R23 antagonism draw** (one salted draw per targeting
  decision, `rules-addendum.md:762-786`) — plus falling dice (§21.5) and loot rolls. **None of them
  can be touched by anything outside the combatant.** Damage itself is deterministic subtraction
  (R14: `damage = max(0, Force − Robustness)`).
- **v2 (gods):** the premise's central verb is "**tipping the dealer**" — "at every non-Forsaken
  table, gods can tip the dealer to help their luck — boons, buffs, items — or hinder others with
  trials, monsters, curses" (`cosmic-casino-canon.md:32-34`). And the roster proves the demand:
  in the **owner-approved 24-god MVP roster** (`data/patron_roster.json`, `roster_count: 24`),
  **`luck_gambling` is the single most common domain — 11 of 24 gods** (Ganesha, Palden Lhamo,
  Caishen, Santa Muerte, Eshu, Benzaiten, Hermes, Tezcatlipoca, Gad, Lucifer, Mammon), with
  `time_fate` on 5 more. `domain_condition_map.json` maps **both to nothing**: "Fortune skews roll
  quality, tier odds, and windfalls — not a damaging condition" / "Fate/time domain — bends clocks,
  odds, and reversals; not a damaging condition of its own." Cross-referencing the two files:
  **3 of 24 MVP gods (Ganesha, Loki, Mammon) have ZERO condition affinity across all their
  domains** — they cannot express themselves in combat at all, only in loot and boons.
- **Verdict:** NEW. **Effort:** M.
- **Why:** this is the honest answer to "does the gods premise need a mechanic v1 has no slot for."
  It does not need a divine damage type (D-20/D-46) and it must not get a to-hit roll (that would
  break the spine). What it needs is a **single verb that lets an off-table agent touch the four
  dice** — the casino's own metaphor, a loaded die.
- **Precedent, and it is a strong one:** v1 already contains exactly this rider, once. §18.2's
  flagship tag **Nine Lives — "Once per session, reroll one Forced Action die where the escape was
  movement-based"** (`:1006`), and **Unkillable — "Once per campaign arc, refuse a death"**
  (`:1007`). And the owner has **already moved both of them off the crowd-tag track onto the
  EPITHET (god/myth) track**: the epithet backlog is `nine_lives, unkillable, vengeful, butcher,
  incorrigible` (`patron-gods.md:147-150`; "5 words moved to the epithet track",
  `rules-addendum.md:708-710`). The two fate-bending riders in the entire book are the two the owner
  reassigned to the divine layer. The design has already voted.
- **Proposed shape (minimum viable, no new subsystem):** one schema-bound command,
  `patron_tip(kind, magnitude, target)` — which `patron-gods.md:195-198` **already specifies** as
  the interface ("Patron actions are dealer tips, entering the sim as schema-bound commands…
  emitted by the director interface, never direct state mutation") — with three `kind`s:
  1. **NUDGE** — step or reroll one already-emitted die (Forced Action d6, threshold die,
     feint-read die). Deterministic and replayable because R22/R24 already **emit every roll with
     its die size and threshold**, so a nudge is a logged transform of a logged value.
  2. **ASSIST** — supply one missing requirement or satisfy one prime. **Zero new machinery**: R15
     already rules that "**assists provide requirements**… Teamwork's primary power is *unlocking*"
     (`:344-346`, `rules-addendum.md:556-559`). A boon is simply an assist from off-table.
  3. **CURSE** — the inverse; see D-45.
- **Already decided?** The *interface* is (patron_tip as a schema-bound command). The *effects* are
  not — `data/patron_gods.json`'s five stubs list boon tables of `melee_buff`, `tier_up_melee`,
  `war_trophy_drop`, `healing_comp`, `ward_buff`, `supply_drop`: **not one entry touches a die.**
- **Open question for the owner (the big one):** may a god's tip touch a **die** at all, or must
  divine influence stay outside the combat resolution (boons before, loot after, curses as
  conditions)? A yes makes gods felt in every fight and makes 11 of 24 patrons mechanically real;
  a no keeps combat sacred and pushes luck gods entirely into the loot/affix economy (which
  `patron-gods.md:114-116` already permits: buffs cover "loot/affix roll quality"). **This single
  ruling decides whether the casino is a frame or a system.**

### D-45 — **Curses have no chassis; propose the anti-prime** (`patron-gods.md:222-225`; `rules-addendum.md:658-660`)

- **v1 (alien):** the book has no curse concept. The nearest thing is a condition (which is a wound)
  or a tag (which is an identity).
- **v2 (gods):** curses are required, repeatedly and specifically: rival gods "**can bless or curse
  the party**, gated on higher/lower affection" (Q5 RULED, `patron-gods.md:222-225`); every god
  carries a `trial_table` of "what displeasure/rival-tips look like (trials, curses, spawns)"
  (`patron-gods.md:173`); R20 names a specific one — "a rival patron can **curse you unstealthy /
  out you**" (`rules-addendum.md:658-660`); and `no_retreat_curse` is already seeded in Ares' trial
  table (`data/patron_gods.json`).
- **Verdict:** NEW. **Effort:** M.
- **Why the anti-prime is the right chassis:** §4.6 already establishes that power is gated by
  **requirements you must satisfy**, in five named shapes (CHAIN/STANCE/STACK/STATE/PREP). A curse
  is the same object with the sign flipped: it **adds** a prime requirement to a skill that had
  none ("you may not strike first until you have been struck" — a genuine Ares punishment for
  cowardice), **raises** an existing one, or **invalidates** a prime you were holding. This needs no
  new state machine — the prime evaluator already exists — it reads as mythologically correct
  (curses in myth are almost always *conditions on action*, not damage), and it degrades gracefully:
  §6.2 already rules that acting with an unmet requirement is **legal but costly** (Forced Action +
  halved effect), so a cursed player is never locked out, only pushed toward the d6. That is
  precisely the "trials to max out on you even if you break" extractive mode
  (`patron-gods.md:52-56`).
- **Alternative chassis considered:** (a) curse-as-**tag** — supported, since tags may **gate**
  items/skills/unlocks (§18.1 pattern 6, `:987-988`; RULED `rules-addendum.md:708-711`) — good for
  *narrative* curses, poor for in-combat ones since tags are slow-moving identity;
  (b) curse-as-**condition** — wrong, because conditions are wounds with tiers and Clock
  advancement, and a curse is not a wound;
  (c) curse-as-**Dissolution source** — reserved for the worst ones only (D-21).
  Recommendation: **anti-prime for combat curses, tag for narrative curses**, Dissolution for the
  catastrophic ones. Three tiers, all built from existing parts.
- **Already decided?** That curses exist and are affection-gated: yes. What a curse *is*
  mechanically: **no**.
- **Open question for the owner:** approve the anti-prime as the curse chassis? And: can a curse be
  **removed** by satisfying it (myth-shaped: curses have terms), by a rival god's counter-tip, or
  only by time?

### D-46 — Does v2 want divine/curse **damage types** v1 lacks? (`data/domain_condition_map.json`; `data/conditions.json`; `:605-618`)

- **v1 (alien):** 7 damage types = 7 resistance keys (Bleed/Crush/Burn/Chill/Poison/Infection/
  Dissolution), 9 conditions, 3 resistance classes (Physical flat / Affliction tiered / Psychic
  tiered).
- **v2 (gods):** **no new damage type.** The evidence is direct and was produced independently of
  this question (D-20): all 26 mythology domains were mapped onto the 9 conditions, 13 fit, 13 were
  deliberately left empty under an explicit "leave empty rather than force" rule, and the empties
  are all non-damage domains. No god in the 24-god roster demands a channel the book lacks. Where
  transcendent damage *is* wanted, the slot already exists and is already gated: the L10
  radiant/psychic-class rung (D-02). Where *curses* are wanted, the answer is not a damage type
  (D-45). Where *fate* is wanted, the answer is not a damage type either (D-44).
- **Verdict:** KEEP (no new type); the only change is naming the existing exotic rung.
- **Why this matters:** adding an eighth damage type would cost a resistance key, a stat-cap
  allocation lane (§3.2 gives Reflexes-over-10 points to Bleed/Crush/Burn only), an item-affix
  family, a condition table, and an engine enum — for a need that the data says does not exist.
- **Already decided?** Effectively yes, by the Wave-5 mapping.
- **Open question for the owner:** confirm — is "divine/radiant" a **damage type with a resistance
  key**, or (recommended) a **rule-transcending property** that bypasses resistance entirely and
  therefore never needs one? The ladder doc already wrote it as the latter
  (`skills-r19-ladders-FINAL.md:439` — "bypasses fire-resistance and standard tiers").

---

## The theme-neutral core (explicit list of chapters that are pure machinery, with proof)

**Provably theme-neutral, in full:** §4.1, §4.3, §4.5, §4.6, §4.7, **§5 (all of 5.1–5.7)**, **§6
(both tables + 6.2)**, **§7.1–§7.3, §7.5**, **§8 (all: 8.1, 8.2, 8.3)**, **§9**, **§10** (one word),
**§11**, **§13**, **§14** (one venue name), **§15** (one already-re-ruled line), **§21.2**, **§21.5**.

The proof is a keyword census, not an impression. Grepping the rulebook, case-insensitively, for
`corporation|alien|broadcast|camera|viewer|audience|crowd|sponsor|TV|show|ratings|studio|precinct|
stage` and restricting to my slice's line ranges (150–650, 770–850, 1240–1315) returns **six lines
in total**:

| line | text | disposition |
|---|---|---|
| `:243` | prime table's STACK example: "Camera Call stacks" | example only; Camera Call already mapped to the odds board |
| `:616` | enemy mental resistance bonus: "(viewer spike / secondary effect)" | one word |
| `:837-839` | "Stealth does not suppress the audience… the crowd's reaction" | already re-ruled by R20 (rival gods) |
| `:1255-1256` | Super Boss ladder "Precinct → Country → **Stage**" | the one genuine premise-lock (D-32) |
| `:1267` | horde doctrine "Mob fights are about the crowd" | **false positive** — "crowd" = the crowd of enemies |
| `:1291` | "Super Bosses are large, **multi-stage**, multi-area" | **false positive** — "stage" = phase |

A second census for economy coupling (`lounge|gemstone|loot box|patron token|achievement|directive|
corporation|med bay|tattoo|wizard|surgeon|augmentation`) returns **9 lines**, all pointers into
chapters that belong to other slices: `:173` (Patron Token), `:178`+`:204`+`:223`+`:229` (Skill
Gemstone/Lounge), `:192-193` (Loot Boxes/Achievements/Wizard's Tower), `:417` (achievements as an
HP source), `:444-445` (Surgeon's Table/Augmentation Hub), `:809-810` (Tattoo Artist). **None is a
rule; all are venue names.**

Three independent corroborations, all pre-existing:
1. `setting-rebrand-options.md:101-104` — "**What stays untouched:** the dungeon itself (floors,
   routes, time skips, demons, Loong, Incinedile), **the Moment clock, all combat rules, per-part
   HP, the addendum, the engine and its 22 green tests**… This is a FRAME swap, not a redesign —
   **the engine doesn't know who's watching.**"
2. `campaign-residuals-audit.md:279-283` — the conditions data audit: "**No cooldown language, no
   corporate language.**"
3. `data/domain_condition_map.json` — 26 god-domains map onto the 9 conditions with no additions
   required.

**Where theme genuinely lives in my slice** (the complete list): the Super Boss ladder (D-32); the
acquisition *sources* in §4.4 (D-07, D-08); the venue names in §4.2/§4.5/§7.4/§14 (D-04, D-18,
D-27); one word in §10 and one example in §4.6; three strings in the skill data (D-41); and the
descriptions, which v2 actively wants (D-40). That is the whole of it.

---

## Skill-name classification (exact counts + 15 examples with proposed v2 forms)

**Corpus:** `/home/user/Galactic-Prime-Time/galactic-prime-time.skilltemplates.json` — **44 rows**,
all `capacity: 5`, **7 passive / 37 active**, `keywords` absent on all rows (stale export, see the
data-honesty note). **+5 post-export skills** exist live (Intercept, Death Grip Jaws, Field Triage,
Iron Stance, Play to the Camera — `server/apply-skill-passover.js:314-410`), counted separately.

### Counts over the 44 exported names

| bucket | count | % | names |
|---|---|---|---|
| **Myth-neutral** (plain martial / physical / plain-English; works unchanged in any setting) | **22** | 50.0% | Controlled Sweep · Quick Step · Seal The Wound · Strong Strike · Counter-Surge · Read The Pattern · Pressure Hold · Brace · Pounce · Slip Through · Decapitate · Overhead Slam · Execution · Feint · Pressure Strike · Swim · Juggling · Dance · Lockpicking · Acrobatics · Acrobatic Save · Full Potential |
| **Already myth-friendly** (actively helps the register: elemental-fantasy, folkloric, legendary) | **10** | 22.7% | Poison Ball · Poison Wall · Frost Ball · Frost Wall · Fire Ball · Fire Wall · Elemental Confluence · Thousand Cuts · Aura Reading · Nightlurking |
| **Sci-fi / modern-technical-coded** (psi vocabulary, modern-military, machine) | **9** | 20.5% | Telekinesis · Telepathy · Mind Burst · Shockwave · Tactical Roll · Camouflage · Voicebox · Generate Visual Media · Ignore All Previous Commands |
| **TV / pop-culture-coded** | **3** | 6.8% | Vibe Control · Heroic Punch · Slice n' Dice |

**Read:** **32 of 44 (72.7%) need no thought at all.** Of the 12 that are coded, **2 are already
cut from the game** (D-42), leaving **10**, of which only ~4 are worth actually renaming — the psi
trio (Telekinesis/Telepathy/Mind Burst) reads as sci-fi only because of 19th-century spiritualist
etymology; the words are Greek and a myth setting can simply own them.

**The +5 live skills:** Intercept (neutral) · Death Grip Jaws (neutral/animal) · Field Triage
(**modern-medical-coded** — "triage" is a WWI-era term) · Iron Stance (neutral, arguably
myth-friendly) · **Play to the Camera** (**TV-coded**, the most premise-locked skill name in the
live catalogue). Adjusted totals across 49: myth-neutral 25 · myth-friendly 10 · tech 10 · TV 4.

### 15 representative examples with proposed v2 forms

| # | v1 name | bucket | proposed v2 form | rationale |
|---|---|---|---|---|
| 1 | **Controlled Sweep** | neutral | *(keep)* | Martial description of a physical act. Nothing to change. |
| 2 | **Fire Ball** | myth-friendly | *(keep)* | Elemental fantasy is the myth register's native tongue; the R19 ladder already ends in "radiant fire". |
| 3 | **Thousand Cuts** | myth-friendly | *(keep)* | Already a real-world execution idiom (lingchi); reads as legend, not TV. |
| 4 | **Nightlurking** | myth-friendly | *(keep)* | Folkloric compound; "little blot of ink" flavour is myth-shaped already. |
| 5 | **Aura Reading** | myth-friendly | *(keep)* | Occult register; under v2 becomes reading the *divine* mood of a thing. |
| 6 | **Telepathy** | tech (psi) | *(keep)* — or **Mind's Ear** | The Greek roots are fine; rename only if the psi-trio's spiritualist flavour bothers you. Note the R18 sweep already drops its Charm secondary. |
| 7 | **Telekinesis** | tech (psi) | *(keep)* — or **Unseen Hand** | "Unseen Hand" is myth-native and describes the mechanic exactly (grip, lift, throw). |
| 8 | **Mind Burst** | tech (psi) | **Skullsong** / **Clamor** | The effect is overwhelming psychic noise; a noise-word beats a videogame compound and links to the Dissolution "song" pattern. |
| 9 | **Shockwave** | tech (comic) | **Earthbreak** | The effect is a ground-driven cone that Prones and knocks back. "Earthbreak" is myth-register and more accurate. |
| 10 | **Tactical Roll** | tech (modern-military) | **Duck and Roll** / **Sidewind** | "Tactical" is the only modern-military adjective in the catalogue. R25 makes it a *declared-hex* dodge — a plainer name fits better. |
| 11 | **Camouflage** | tech (modern-military) | **Stillness** / **Blend** | 20th-century French military term. "Stillness" also encodes the break-on-move rule. |
| 12 | **Voicebox** | tech (anatomical/device) | **Mockingtongue** | Larynx-as-device reads modern; a mimicry-bird compound is folkloric and keeps the joke. Note G4 also moves it Charm→Mind (table G4 kept it Charm under the G4 stat freeze — check which repo you mean). |
| 13 | **Vibe Control** | TV/pop (slang) | **Presence** / **Hold the Room** | "Vibe" is contemporary slang and the weakest name in the catalogue; R18 already re-reads the skill as battlefield *presence*, so the name should follow the ruling. |
| 14 | **Heroic Punch** | TV/pop (superhero) | **Champion's Fist** | Keeps the joke's shape ("aspire wholeheartedly to be a hero while being extremely weak" — its ruled acquisition line, G7) while landing in myth register; "champion" is the casino's own word for a contestant. |
| 15 | **Slice n' Dice** | TV/pop (infomercial) | **Twin Fangs** / **Crossing Cuts** | Infomercial cadence; the skill is Sasha's dual-claw signature, and a beast-name serves the character better. |
| — | **Play to the Camera** (live, +5) | TV | **Play to the Gallery** / **Work the Odds** | One-word swap; "the gallery" is already the canon term for the watching gods. |

**Recommendation:** do **not** run a bulk rename. Rename the four genuine offenders (Vibe Control,
Heroic Punch, Slice n' Dice, Play to the Camera), consider the two modern-military ones (Tactical
Roll, Camouflage), and leave the other 43 alone. Every rename costs player-facing memory and breaks
the char-sheet↔game name matching that `apply-skill-passover.js` relies on (it matches templates
**by name**).

---

## Damage types & conditions under a gods premise

**Verdict: the vocabulary is myth-neutral, and no new damage type is warranted.**

1. **Nothing in the list reads sci-fi.** Bleed · Crush · Burn · Chill · Poison · Infection ·
   Dissolution are plain-English wounds. The catalogue contains no plasma, radiation, EMP, nanite,
   or neural-spike vocabulary anywhere in §7–§10. Even the poison sub-types (Neurotoxin, Hemotoxin,
   Myotoxin, Pneumotoxin, Cytotoxin, `:546-551`) are Greek-rooted clinical words — classical
   register, not futurist.
2. **"Dissolution" is the best-named thing in the book for v2.** It replaced "Psychic" in the
   2026-07-25 migration; it is an alchemical term; and its rules text ("the mind collapses… whether
   what remains is a husk, a puppet, or something worse", `:565-567`) is already god-horror. It is
   the soul-damage a divine setting needs, and it is already source-gated ("cannot be applied by
   standard attacks — requires an explicit source", `:562-563`).
3. **The empirical test has already been run.** `data/domain_condition_map.json` maps the
   owner-approved 26-domain mythology vocabulary onto the 9 conditions. Result: 13 domains map,
   13 are deliberately empty, **0 demand a new condition**. The empties are all *non-damage*
   domains (luck_gambling, wealth_commerce, wisdom, trickery, chaos, time_fate, justice_oaths,
   love_beauty, music_performance, poetry_story, protection_home, healing, earth_harvest), and the
   file states plainly that these "act on tags/affixes/hype, not on the 9 damaging conditions."
4. **Where transcendence is wanted, the slot exists.** §4.1 already reserves "an exotic damage
   class" at the top of a generalization ladder (`:167`), R19 names it "psychic/**radiant**-class"
   (`rules-addendum.md:626`), and ladder default #2 gates it to magic skills bought with a Patron
   Token at the Wizard's Tower. v2 should **name** it, not invent alongside it (D-02).
5. **Where curses are wanted, a damage type is the wrong tool** (D-45): myth curses are conditions
   *on action*, which is what §4.6's prime system already models.
6. **Cost of the alternative.** An eighth damage type would need a resistance key, a slot in §3.2's
   over-10 allocation (currently Bleed/Crush/Burn only), a condition tier table, an affix family,
   the `DMG_TYPES` enum in the char-sheet app, and the sim's condition enum — for a demand the data
   says is zero.

**Minor v2 gains available for free:** §10's "player affliction resistance… is GM-awarded,
explicitly, when earned" (`:617-618`) is a vacancy the patron layer should fill (D-23); §8.1's
"treatment usually **delays**" model gives healing gods a lane that never trivialises wounds; and
Burn T1's cauterize-costs-Shock trade (`:500`) is a nice place for a fire god's boon to waive the
price.

---

## The Super Boss ladder and bestiary

### The ladder

`:1254-1256` gives two three-rung ladders: Bosses **Neighbourhood → District → City**; Super Bosses
**Precinct → Country → Stage**, "a Stage boss is not expected to be beaten." "Precinct" is
civic-police; "Stage" means *the show's level of production*. Neither is adopted in the game yet —
they are catalogued as live-and-unadopted, landing with KAN-4 AI
(`campaign-residuals-audit.md:383`), and one Stage-tier Super Boss template is budgeted (`:269`).
Only the **category** enum is in code (`simulation/enemy_ai.gd:33`), so renaming the *variants*
costs nothing today. This is the cheapest moment to change it.

**Constraint to respect:** three ladders already exist and must not be shadowed — table tiers
(Normal / VIP / VVIP-Forsaken), box tiers (Bronze → Silver → Gold → Legendary → Mythic → **Godly**),
and myth grades (folk_tale → local_legend → heroic_epic → **world_myth**). A boss ladder ending in
"Godly" or "World Myth" would be ambiguous with the other two.

**Recommended — belief-scale:** Bosses **Shrine → Temple → Pantheon**; Super Bosses **Legend →
Age-Ender → The House**. The rungs measure how much belief feeds the thing (the divinity economy's
own unit); "The House" carries "not expected to be beaten" natively and is casino-native rather than
borrowed.
**Alt A — wager-graded:** Side Bet → Table Stakes → High Roller / Jackpot → All-In → The House.
**Alt B — myth-graded:** Folk Tale → Local Legend → Heroic Epic / World Myth → Cataclysm → The
House. (Maximum content synergy with the epithet catalog; overloads the word "grade".)

### The bestiary

**Already myth-compatible, and already ruled to survive.** "Demons/Loong explicitly survive the
frame swap" (`campaign-residuals-audit.md:386`); "What stays untouched: … demons, Loong, Incinedile"
(`setting-rebrand-options.md:101-102`).

- **Demons** (`GPT_Master_Compendium.md:100-106`, adopted as R12): a two-class hierarchy where
  normal demons are fallen comprehensible humans and **nobility corrupts through existence alone**
  (Dissolution + emotion amplification), plus the demonic-brand contract (`story-canon.md:6-37`).
  This is Abrahamic-folk-shaped *already*, and `data/mythology/abrahamic_folk.md` has extracted a
  full goetic roster with boss designs (Beelzebub, Asmodeus, Lilith) that would slot straight in.
- **The Loong / Loong Kin** (`GPT_Master_Compendium.md:282-284`): an East-Asian dragon the party
  **persuades, escorts and protects** across three floors. Perfectly myth-native, and the canonical
  example of the missing "Worshipped Creature" disposition (D-38).
- **Incinedile** (`data/enemies.json` id 3): a mycelium puppet with a hidden 50-HP `network` part,
  surface immunity, bleed-immunity, and two discoverable breach paths. The mycelium **Corporation**
  was the on-the-nose problem (`setting-rebrand-options.md:4-5`); the mycelium **boss** is not — a
  false beast animated from within is a folklore staple, and the fight is fully playtested.
- **Roach-dog / Little Brother Roach**: vermin and a brood-tender elite. Generic and fine; the
  Asag-offspring template (`cosmic-casino-canon.md:154-155`) is the stated model for
  mythology-sourced replacements.

**Gap:** enemies carry scale (`category`), body, stats, resistances, abilities and R23 personality —
but **no allegiance/disposition field**, so canon's Insane / Sane / Worshipped states have nowhere
to live (D-38). That is the one enemy-side change the premise actually forces.

---

## Does v2 need a divine-intervention mechanic v1 lacks?

**Short answer: yes — exactly one, and it is not a damage type, a to-hit roll, or a luck stat.**

**The spine must not be touched.** "No to-hit rolls. Actions auto-succeed when their requirements
are met" (`:29-31`), restated as a hard rule in the game repo's CLAUDE.md. A "divine dodge" or a
god-granted hit chance would break the thing that makes the system distinctive. Any divine hook must
attach *around* the spine, not inside it.

**Where the spine leaves room.** Requirements auto-succeed — so the interesting question is always
"is the requirement met?", and §5.7/R15 already rule that **assists provide requirements** and that
a partner can supply what you lack (`:344-346`). Failure runs through the **Forced Action d6**, and
danger through **thresholds and timers**. So the engine has exactly two legitimate handles for an
outside agent: **requirements** and **dice**.

**The gap, stated precisely.** Four random surfaces exist (Forced Action d6; R22 threshold die;
R24 feint-read die; R23 antagonism draw), all emitted and logged, and **none is addressable from
outside the combatant**. Meanwhile the premise's central verb is *tipping the dealer*, and
**11 of the 24 MVP patron gods carry `luck_gambling`**, which maps to no condition, no action tag
and no combat effect. Three of the twenty-four (Ganesha, Loki, Mammon) cannot express themselves in
a fight at all. A casino whose fortune gods cannot touch a die is a casino in name only.

**Proposed mechanic — the Tip (one verb, three faces).** Ride the interface that
`patron-gods.md:195-198` already mandates (`patron_tip(boon|trial, magnitude, target)` as a
schema-bound command emitted by the director, never a direct state mutation):

1. **NUDGE** — step or reroll one already-emitted die. Legal and deterministic because R22/R24
   already emit every roll with its die size and threshold, so the nudge is a logged transform of a
   logged value, and the replay stays byte-identical. **Precedent in v1: §18.2's Nine Lives rider,
   `:1006`** — the only reroll in the book, and the owner has already migrated it (with Unkillable)
   from the crowd-tag track to the **epithet/god track** (`patron-gods.md:147-150`;
   `rules-addendum.md:708-710`). The design has already decided where die-bending belongs.
2. **ASSIST** — supply one missing requirement or satisfy one prime, exactly as an ally's assist
   does (R15). Costs **zero** new machinery and is the most on-theme intervention possible: the god
   does not swing for you, it *makes the swing possible*. This is also the honest reading of
   "boons arrive diegetically — an inexplicable kindness of the dungeon"
   (`patron-gods.md:199-203`).
3. **CURSE (the anti-prime)** — add, raise or invalidate a prime requirement (D-45). §6.2 makes an
   unmet requirement legal-but-costly, so a curse pressures rather than locks, which is precisely
   the extractive-patron mode canon describes.

**What v2 does NOT need:** a divine damage type (D-46); a to-hit roll; a luck/fate stat (R22's
per-stat threshold die already generalizes — "Mind vs fear, Physique vs forced movement",
`rules-addendum.md:740-742`); or a new condition. Everything above is assembled from parts the book
already ships.

**Second-order note:** if NUDGE is approved, §14's threshold-die ladder (d4→d6→d8) becomes the
natural **permanent** boon (D-27, a god's mark instead of a tattoo), and the whole divine layer gets
a coherent story: gods give you better dice, better openings, and worse requirements.

---

## Cross-cutting observations

1. **The engine is the asset; the fiction is the veneer.** Six premise-bearing lines in ~700. The
   frame swap costs this slice almost nothing, which is exactly what
   `setting-rebrand-options.md:104` predicted — "the engine doesn't know who's watching."
2. **v2 mostly *answers* v1's silences rather than contradicting v1's statements.** §4.4 never said
   who teaches you; §21.3 never said where a win condition comes from; §21.4 never asked whose room
   this is; §10 never said who awards affliction resistance. The gods answer all four for free.
3. **The three real design questions are all one question:** may a god touch the resolution layer
   (dice + requirements), or only the layers around it (loot, boons-before, curses-as-narrative)?
   D-44, D-45 and D-27 all collapse into that ruling.
4. **Two repos have deliberately diverged and must not be "reconciled".** Robots and their two joke
   skills are cut in the game (R16 + 2026-07-17) and kept at the table (G5); exclusives are removed
   at the table (G7) and retained in the game (R12). Both are correct.
5. **Beware bulk grep-reskins.** "crowd" at `:1267` means enemies, "stage" at `:1291` means phase,
   and "Patron" at `:173` is *already* the v2 word. A careless find-and-replace would damage three
   correct lines and miss the one real leak.
6. **The stale export is a trap.** `galactic-prime-time.skilltemplates.json` predates the
   2026-07-25 passover by three months: no `keywords`, no `prime`, 44 rows instead of 49, and it
   still contains the two "Cooldown: 1 Clock" strings that G1/R3/R25 killed. Any future skill work
   should pull fresh from the live DB, not from this file.
7. **The catalogue's real weakness is not theme, it is shape.** The skills audit found strikers
   over-served, tanks/support/control thin, and — its words — "the social-broadcast layer, the
   game's signature, has almost no active skills". Under v2 that layer becomes the *divine-attention*
   layer, which makes the gap more expensive, not less. Five of the ~25 proposed skills have since
   been seeded (Intercept, Death Grip Jaws, Field Triage, Iron Stance, Play to the Camera); ~20
   remain parked.
8. **Nothing in this slice blocks anything.** Every RESKIN is a string edit; the two MECHANICAL
   items are one added sentence each; the four NEW items are all KAN-7-era (patron layer) or
   KAN-4-era (enemy disposition), none of them in the current epic.

---

## Open questions for the owner

Ordered by how much downstream work they unblock.

1. **May a patron god's tip touch a die or a requirement inside combat resolution?** (D-44) — the
   ruling that decides whether the casino is a frame or a system, and whether 11 of your 24 MVP
   gods are mechanically real. Recommendation: **yes, via ASSIST and NUDGE only**, never a to-hit.
2. **Approve the anti-prime as the chassis for curses?** (D-45) — with tags for narrative curses and
   Dissolution for catastrophic ones. Zero new machinery; unblocks every `trial_table` in the roster.
3. **Pick the Super Boss ladder** (D-32) — recommended: Bosses **Shrine → Temple → Pantheon**, Super
   Bosses **Legend → Age-Ender → The House**. Confirm whether both halves share a register.
4. **Name the exotic damage class** (D-02) — Divine, Radiant, or unnamed? And is it a *type with a
   resistance key* or (recommended) a *rule-transcending property* with none?
5. **Does the skill cap ladder stay a spendable Patron Token, or become an affection threshold?**
   (D-03) — and, together with D-27, how much of progression should the patron own before the
   player stops feeling like an agent?
6. **Enemy disposition: template-level or encounter-level?** (D-38) — encounter-level is far richer
   and only slightly costlier.
7. **Should a boss's discoverable win condition be recoverable from its myth, and may the bestiary
   state it?** (D-34) — knowledge-as-power loop vs protecting the discovery beat.
8. **Whose psyche shapes an arena — the table's runner, or a different god per floor?** (D-35).
9. **Do Skill Tomes split into God Relics and Follower Relics?** (D-08) — lets the existing box
   tiers carry the split with no new rules.
10. **Rename the four TV-coded skills** (Vibe Control, Heroic Punch, Slice n' Dice, Play to the
    Camera)? (D-39) — and do you also want the two modern-military names (Tactical Roll,
    Camouflage)? Note renames break the name-matching in `apply-skill-passover.js`.
11. **Should divine presence reuse the demonic-nobility Dissolution pattern verbatim?** (D-21).
12. **Do demons get re-parented to the extracted goetic roster, or stay an original species?**
    (D-37) — a hundred authored enemies vs the integrity of the demonic-brand contract story.
