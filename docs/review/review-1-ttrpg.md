# Review 1 — Galactic Prime Time as a TTRPG

**Scope:** the full ruleset (`DCC esque System` doc), Items and Skill List docs, the live
campaign database (5 characters, 44 skill templates, 28 items, 100 tags, 27 affixes, 3
enemies), and the rules encoded in the character-sheet app.
**Method:** direct read of all documents; an independent adversarial rules-consistency pass
(findings below individually verified against the source text before inclusion); live-data
cross-checks against the MongoDB export.

---

## Verdict

**A genuinely original system with a professional-grade mechanical core, surrounded by
subsystems at very different maturity levels.** The combat engine (Moment clock, per-part
HP, tiered conditions, Forced Actions, requirements-not-dice) is coherent, distinctive, and
near-table-ready. The identity/audience layer (Tags, Exposure, Goals/Directives) is
inspired but leans on GM judgment by design. The economy and progression layers are
sketches. As a home-campaign system run by its author it demonstrably works — five real
characters at level 6 and a six-phase boss fight prove it. As a *publishable book for
strangers*, it needs a rules-completeness pass; as a *video-game source spec*, the gaps
matter far less because they're exactly the things a designer must nail down in data anyway
(see Review 2).

## What's genuinely strong

1. **Requirements-not-dice resolution.** Attacks and skills auto-succeed when stat/equipment
   requirements are met; the failure path is the Forced Action d6 table, triggered by *doing
   things you're not qualified for* rather than by luck. This kills whiff-turns, makes
   character building the central skill test, and is (rare among TTRPGs) directly
   compilable to code.
2. **The Moment clock.** A shared 10-count timeline where actions cost Moments and overlap
   rather than interrupt — real simultaneity pressure, no initiative bookkeeping, natural
   support for multi-Moment "channeled and Exposed" commitments. It's the system's most
   distinctive combat idea and it holds up under scrutiny.
3. **Conditions instead of hit points as the real damage language.** HP pools are tiny
   (2–5); the actual fight is condition management — 9 damage/condition types with tiered
   escalation per Clock, entry conditions (poison), spread rules, and interlocking cures
   (Burn T1 stops bleeding and removes chill — elegant, thematic, exploitable in exactly
   the fun way). Combined with per-body-part targeting and disable states, ordinary fights
   have surgical texture without a single to-hit roll.
4. **The audience metagame is a real design layer, not flavor.** Viewers→Followers→Patrons
   is a conversion funnel with distinct mechanical hooks (reward volatility, directive
   frequency, patron tokens → skill-cap raises), Camera Call converts Charm into an economy
   multiplier, and the ~100-tag list doubles as an achievement/identity system. This is the
   part no other system on the market has.
5. **Boss design philosophy.** "Most bosses have win conditions that are less about giving
   them a hit on the head" — and the live data proves it's practiced: the tutorial boss has
   a 50 HP mycelium Network as its true pool, a destroyable 30 HP arm, escalating explosion
   phases, and dodge-threshold mechanics. Asymmetric enemy statting (boss parts at 6–50 HP
   vs. player parts at 2–5) works.

## Completeness map — subsystem maturity

| Subsystem | State | Evidence |
|---|---|---|
| Combat clock, actions, Forced Actions | **Table-ready** | Fully specified incl. edge timing ("consequences apply after resolution") |
| Body parts, damage types, conditions | **Table-ready** with tier gaps (see findings) | 9 types, tier tables mostly complete |
| Weapons (melee/ranged classes, RPM, reload) | **Table-ready** | Class table with requirements/damage |
| Skills (levels, caps, thresholds, consuming) | **Usable, thin at thresholds** | Cap/threshold economy defined; mutation/upgrade adjudication is GM-space |
| Stats & skill points | **Usable** with a scale seam at creation (1–5) vs growth (10–20+) — see findings | Live chars at 3–7 by level 6 |
| Tags | **Usable at a table, GM-heavy** | 100 tags authored with acquisition conditions |
| Exposure (Viewers/Followers/Patrons) | **Structured sketch** | Counters + conversion events defined; no rate math |
| Directives / Goals / Achievements | **Structured sketch** | Taxonomies + reward channels; content authored ad hoc |
| Lounge (base building) | **Sketch** | Module tree + unlock costs; no economy numbers, no module effects detail |
| Races | **Sketch** | 3 races, one paragraph each; Animal/Robot balance is pure GM judgment |
| Progression (levels, XP) | **Undefined in the book** | Level-ups exist in play (all chars level 6) but the book never says what a level grants or when one is earned — it lives in the author's head and the char-sheet app's level-point pool |
| Economy (prices, bartering) | **Undefined** | Store items have no prices |
| Magic | **Explicitly deferred** | Acquisition path named (loot/achievements/Wizard's Tower); no spell rules |

This distribution is normal for a living home campaign — the GM patches at the table. The
findings below list the specific holes that would bite a *cold* table (or a programmer)
first.

## What the live data proves

- **The system survives real players.** Five sheets at level 6 with full inventories,
  7-skill loadouts, tags earned, patron tokens spent. The loops that matter (skills, items,
  conditions, boss fights) have been exercised for months.
- **The Animal race fantasy works** — a playable sea lion with a coherent sheet (Reflexes/
  Mind 6, animal-appropriate skills) and the tag list has grown a whole animal-behavior
  section to support it. Player buy-in is visibly high (portraits, backstories, in-character
  chat logs in the export).
- **Content authoring is real but small-N:** 44 skills, 28 items, 27 affixes, 3 enemies.
  A video game needs 10–50× that; the templates show the *shapes* scale fine.
- **The trait scale has already outgrown the book:** the rulebook presents traits as 1–5
  ("Rare talent. Top percentile"); every live character has 6s and 7s by level 6, and the
  stat-cap system assumes 10–20+. The 1–5 fiction table is creation-only in practice — the
  book never says so.

## Doc ↔ code drift (rulebook vs character-sheet app)

The character-sheet app is the de-facto second rulebook, and the two have drifted:

| Concept | Rulebook | Char-sheet app (`constants.js`) |
|---|---|---|
| Damage types | Bleed/Crush/Burn/Chill/Poison/Infection (+Suffocation, Dissolution, Exhausted as conditions) | `DMG_TYPES = Crush, Bleed, Burn, Shock, Toxic, Psy` — different taxonomy; "Shock" collides with the shock-tier pain system |
| Races | Human / Animal / Robot | `RACES = Human, Cyborg, Android, Mutant, Alien, Clone, Hybrid, Synthetic` — neither list contains the other; live chars use "Sea Lion" and "AI" freetext |
| Enemy default body HP | (not specified for enemies) | Enemy defaults Head 3/Torso 5/Arm 3/Leg 4 ≠ player 2/5/2/3 — fine as asymmetry, but undocumented |
| Level points | Not in book (levels undefined) | Unified `levelPoints.pool`, admin-granted — the *actual* progression rule |
| Skill cooldowns | Some skills have cooldowns (e.g. Tactical Roll "1 clock") | `cooldownRemaining` stored but never decremented or enforced — dead field |

None of these block the table (the author is both GM and developer), but any conversion must
pick one canonical vocabulary per concept — recommended: the rulebook's condition taxonomy +
the game repo's seed enums, which already match each other.

## Findings — rules defects (adversarial pass, spot-verified against source text)

Severity: 🟥 blocker-at-table (a cold GM/programmer cannot proceed without inventing a rule)
· 🟧 friction · ⬜ cosmetic. All quotes verified in the source docs unless marked (DB) —
cross-checked against the live database export.

### Contradictions

| # | Finding | Sev |
|---|---|---|
| A1 | **Bleed-out list contradicts the conditions' own rules.** Death-by-condition states are listed as "Bleeding / Crushed / Poisoned / Infected / Exhausted" — but Crushed tops out at Tier 2, Exhausted has no tiers or death mechanism, and Infected has no lethality mechanism. Three of five listed death-states can't cause death as written. | 🟥 |
| A2 | **Dissolution both KOs and kills** in the same section ("They are KO'd" … "A character afflicted with Dissolution dies"). Bleed-out, healing, and the Narrative-Token "no raising the dead" rule all hinge on which. | 🟧 |
| A3 | **Psychic resistance is tiered; Dissolution (its only condition) is tierless** — the Mind-15 stat-cap reward grants immunity to a tier that doesn't exist. (Same family: an item grants "immune to Suffocation Tier 1"; Suffocation has no tiers.) | 🟧 |
| A4 | **"Reduce HP on that part (usually 1)" vs every listed weapon dealing 2–4.** The core damage-resolution sentence and the weapon table cannot both be true; a 2-damage dagger one-shots a 2-HP arm. The single most important number in the game is ambiguous. | 🟥 |
| A5 | **Reactive skills exist; the clock chapter forbids interrupts.** "Actions do not interrupt each other — they overlap" vs Counter-Surge ("strike immediately" when an enemy starts an action), Tactical Roll, Brace, Slick Hide. No reaction economy exists (what does a reaction's cost deduct from?). | 🟥 |
| A6 | **Three different reward contracts for Directives** (guaranteed Patron Token / "rewards vary" / achievement-style loot boxes) — and Patron Tokens are the skill-cap currency, so it matters. | 🟧 |

### Undefined load-bearing terms

| # | Finding | Sev |
|---|---|---|
| B1 | **Character advancement does not exist in the book.** No XP, no level-up trigger, no statement of what a level grants, no rule for raising a stat past creation — while stat caps key off 10/12/15/20 and the book's own example skill requires 20 Physique. The live table runs on app-invented level points (all five characters are level 6 with traits at 6–7). The single biggest hole in the text. | 🟥 |
| B2–B4 | **Prone, Helpless, Channeling** — all three appear in the Exposed trigger list (i.e., in the lethality rules); none is defined. Helpless is listed separately from "Cannot Act" in bleed-out, so it isn't merely that. | 🟧 |
| B5 | **Grapple has no rules** — no escape, no contest, no size limit — yet Pressure Hold (a basic cap-5 skill) grapples and starts a Suffocation death clock. See exploit D4. | 🟥 |
| B6–B7 | **Small/Large size categories and "Slowed"** are referenced by 6+ items and never defined. | 🟧 |
| B8 | **"Spaces" (and items' "tiles") are never defined** — no grid geometry, no diagonal rule, no scale; one achievement uses "50 meter radius" as a third unit. | 🟧 |
| B9 | **"Session"** gates Camera Call charges and several tags; real-world session vs broadcast episode never stated. | 🟧 |
| B10 | **Cover and stealth** are referenced (a weapon "ignores cover"; Shock T1 "breaks stealth") with no cover or stealth rules anywhere. | 🟧 |
| B11 | **No healing/downtime rules at all.** "Full resolution usually requires downtime" — downtime undefined; no rest rule; nothing ever restores HP out of combat. Campaign play hits this by session two. | 🟥 |
| B12 | **Poison "incompatibility"** triggers Poison Soup; no compatibility definition exists. | 🟧 |
| B13 | **Exhausted increases Moment costs "by how much"?** — and its text collides the *Exposure* metagame term with the *Exposed* combat state. | 🟧 |
| B14 | **Upgrade Tokens are a "primary currency" with no sink** (every listed cost is Boss Tokens); the Surgeon's Table requires a race change to unlock the facility that does race changes. | 🟧 |
| B15 | **The Enemies chapter contains no construction rules** — no HP/damage/action guidance; a cold GM cannot stat a goblin. (DB) The live GM freehanded boss HP (50/30/15/8) and invented a "Dodge Threshold" d6 mechanic that exists nowhere in the book — direct evidence of the hole. | 🟥 |

### Broken / ambiguous math

| # | Finding | Sev |
|---|---|---|
| C1 | **Clock-boundary scheduling is undefined.** Act at Moment 1 with a 2-cost action → next Moment = −1; no wrap rule, no ordering vs the reset and per-Clock condition ticks. Every fight longer than one Clock hits this. | 🟥 |
| C2 | **Declare-vs-resolve timing for 1-cost actions is never stated** — decides whether moving away dodges, whether same-Moment combatants trade kills, and what an item's "the first melee attack against you misses" means in a system with no misses. (DB) The table's homebrewed Dodge Threshold corroborates the gap. | 🟥 |
| C3 | **Stat-cap arithmetic is garbled** ("upgrade points… over 10 Example: every 5 points = 15 and on") — first Physique bump at 10, 15, or 5-past-10? And it soft-contradicts "All Stats are rated 1–5", which is never scoped to creation. | 🟧 |
| C4 | **Skill-point economy: book (N per trait) vs app (N−1) vs table** — (DB) no character's `skillPointsSpent` reconciles with skills held; nobody is operating the written economy. Multi-stat costing is specified only via one ambiguous example sentence. | 🟧 |
| C5 | **RPM conflates rate with cost.** "Moment Cost is measured by RPM" is uncostable as written; per-round damage multiplication would make a 3-RPM pistol out-damage a greatsword; reload is mandatory with no Moment cost and no magazine sizes anywhere. Any ranged build breaks the table. | 🟥 |
| C6 | **Movement pricing ambiguity** — 7 spaces = 1 or 2 Moments? (and see exploit D1). | 🟧 |
| C8 | **Condition application on hit is undefined** — at what tier does a weapon's condition land? Does a second Bleed hit advance, stack, or nothing? (DB) The boss notes invent "Bleed tier 2 … opens network up," treating tiers as attack-applied — unsupported by any book rule. | 🟥 |

### Degenerate loops / exploits

| # | Finding | Sev |
|---|---|---|
| D1 | **Unlimited 0-cost actions.** Nothing caps actions per Moment: 1–3-space moves cost 0 (infinite free movement); Brace (0-cost, no cooldown) re-declared after every hit; several 0-cost skills and a 0-cost consumable. | 🟥 |
| D2 | **Inventory-interaction reset loop** — interleave any 1-cost action and every item use in a fight is free forever; item Moment costs vs the inventory-interaction cost are two overlapping systems with no bridge rule. | 🟧 |
| D3 | **Burn Tier 1 as a near-free panacea.** Burn T1 stops bleeding/removes chill; T2 stops poison/clears infection. Burn's own escalation rule is missing (an item's "Burn Tier 1 does not escalate" implies one exists), so cauterizing strictly dominates bandages/antitoxins, which only *delay*. (Softened from the reviewer's "no drawback at all": Burn does apply HP damage on application — but trading 1 HP for curing lethal Infection is still strictly dominant.) | 🟥 |
| D4 | **Grapple → Suffocation death clock on anything grabbable** — 2 Moments, no escape rules, no size gate. RAW deletes bosses in 2 Clocks. | 🟥 |
| D5 | **Poison Soup is both a nuke and an antidote** — two T3 poisons = 6 direct HP vs a 5-HP torso skipping all delays; conversely, self-applying a cheap incompatible T1 ends a lethal T3 on demand. Hinges on undefined "incompatible" (B12). | 🟧 |
| D6 | **Stat requirements are a ~17% tax, not a gate.** Forced Actions are "always allowed" and consequences never negate the action (only Whiff, 1-in-6 on the Tool table). A 1-Physique character swings a 5-Physique greatsword at ~83% effectiveness forever. Which FA table a stat shortfall triggers is also unstated. | 🟧 |
| D7 | **Boss-Token→Patron-Token exchange ignores Boss-Token tiers** — 3 Bronze equals 3 Mythic as skill-cap currency; farmable bypass of the audience metagame. | 🟧 |
| D8 | **Camera Call self-targeting** plausibly doubles Patron-Token income timed to Goal completions; currently unreachable only because Charm 20 is unreachable (B1) — two defects cancelling is its own smell. | ⬜ |

### Escalation-table gaps

| # | Finding | Sev |
|---|---|---|
| E1 | **No universal condition-advancement rule** — "every Clock advances in severity" appears only under Bleeding; the general section only covers stacking. Burn and Crushed have no advancement source at all. | 🟥 |
| E2 | Chilled T1 "resolves after 8 Moments without further advancement" — advancement source unstated; it's also the only Moment-denominated condition in a Clock-denominated system. | 🟧 |
| E3 | **Missing tiers:** Crushed stops at 2 (torso text promises "rapid escalation" to nowhere), Burn T3 ("loss of part of limb") is undefined for torso/head, Exhausted and Infected have no tiers or timers. | 🟧 |
| E5 | Shock stacking on a second independent source is unstated (a DB skill assumes escalation; the book doesn't say); Shock-T3 unconsciousness is never mapped to Helpless/Exposed. | 🟧 |

### Item/skill inconsistencies vs core rules

| # | Finding | Sev |
|---|---|---|
| F1 | Items reference a terrain layer (Sludge, Flammable tiles, rough terrain, water) that core rules never define. | 🟧 |
| F2 | Stat-valued ranges ("Range: Reflexes") are an undeclared convention, used by 3+ items. | 🟧 |
| F3 | Fang Cover violates the book's own poison contract (no tier/delay/target/effect). | 🟧 |
| F4 | Store items undercut their own class baselines (Rebar Spear 1 Bleed vs class 2; bow omits class requirements) with no stated rule that items may vary. | ⬜ |
| F5 | **Cooldowns are used by many skills and defined nowhere** (the char-sheet app added a dead `cooldownRemaining` field to cope); interaction with Clock resets unstated. | 🟧 |
| F7 | Controlled Sweep's unlock condition is circular ("attack 2 or more mobs with a single-target attack"). | 🟧 |
| F9 | (DB) Live content already drifts past the book: a skill deals "2 Chill Damage" while the book says Chilled deals no HP damage; boss notes use "turn"/"round" — units that don't exist in the Moments system. | 🟧 |
| F10 | The core action table's "Use a Skill: 1–3" floor was dead on arrival — 10+ authored skills cost 0. | ⬜ |

## Fix-first list (if the book had to run a cold session tomorrow)

1. **Resolution timing & reactions** (C2, A5, C1): when a 1-cost action lands, scheduling
   across Clock resets, what dodge/miss means (adopt the table's own Dodge-Threshold
   homebrew — it's good), and a one-paragraph reaction economy.
2. **Cap free actions** (D1, D2, C6): one 0-cost action per kind per Moment; free movement
   once per Moment; delete the inventory-interaction reset clause.
3. **Publish the universal condition engine** (E1, C8, D3, E3): all conditions advance at
   Clock reset unless delayed; re-application advances one tier; fill the missing tiers;
   give Burn T1 a real cost so cauterizing isn't strictly dominant.
4. **Define advancement** (B1, C3): what a level is, when it's earned, how stats rise past
   5 — or rescale the 10/12/15/20 stat-cap tiers until it exists. (The char-sheet app's
   level-point pool is already the de-facto rule; write it down.)
5. **Fix the ranged/RPM economy and the grapple hole** (C5, B5/D4): firing = 1 Moment buys
   RPM rounds with stated per-round damage; magazine size + reload cost; grapple
   escape/contest rule and a size gate before Pressure Hold deletes a boss.

**Note for the video-game conversion:** this list looks alarming but is actually
*encouraging* — every blocker above is precisely the kind of decision a game programmer
must make explicitly in code anyway (tick order, action validation, condition engine,
progression curve). The book's gaps are the video game's design backlog, not extra debt.
The five characters and months of play prove the core loop is fun even with the gaps
GM-patched — the defects are in the text, not the design.
