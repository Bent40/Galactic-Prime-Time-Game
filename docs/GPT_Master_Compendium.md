# GALACTIC PRIME TIME — Master Datapoint Compendium
**Purpose:** Single consolidated reference of everything established in this project, categorized for use as datapoints in the video game adaptation.
**Source basis:** System doc v0.91 + all project sessions (GDD, boss design, item/modifier design, character audits, story design, app development, tooling).
**Compiled:** 2026-07-14

**Category legend:**
- `[SYSTEM]` — Canonical TTRPG rules (v0.91 document)
- `[STORY]` — Campaign narrative, NPCs, encounters (idea/designed)
- `[DESIGNED]` — Mechanical content designed in sessions, not yet in the core doc
- `[CHARACTER]` — Live party data
- `[GAME]` — Video game adaptation decisions (GDD-level)
- `[EXECUTED]` — Implemented, working logic (character sheet app / tooling)
- `[OPEN]` — Undecided / parked / backlog
- `[PRINCIPLE]` — Design learnings and standing rules

---

## 1. PROJECT OVERVIEW `[SYSTEM]` `[STORY]`

- **Galactic Prime Time (GPT)** — reality-TV-themed TTRPG. Abducted humans (and animals/AI) compete in alien-broadcast dungeon runs. An alien conglomerate ("The Corporation™") films humans to justify colonization to its citizens.
- **Tone influences:** Dungeon Crawler Carl, The Running Man, LitRPG, MMO design. Motto: **Lights. Camera. Action.**
- **Core pillars:** Spectacle over safety. Identity through Tags. Timeline combat (Moments/Clocks). The Audience as an active mechanic.
- **Design rules to respect:** Actions auto-succeed when stat requirements are met — no to-hit rolls. Forced Action (d6 Body/Tool tables) handles dangerous/impaired actions. Safe passive play is structurally discouraged.
- **Two parallel tracks:** (1) active tabletop campaign, (2) planned solo-built video game adaptation (Godot, 2.5D tactical RPG).
- Ben is sole designer; playtesters give feedback but do not contribute to design. System version: **v0.91**.

---

## 2. CORE SYSTEM RULES (v0.91) `[SYSTEM]`

### 2.1 Character Creation
- Race: Human (start). Level: 1.
- Two structural pillars: **Body** (physical, changes more easily) and **Core** (mental/identity, harder to change).
- Four traits, rated 1–5: **Physique** (Body), **Reflexes** (Body), **Mind** (Core), **Charm** (Core).
- At creation: allocate **7 points across Body traits**, **7 points across Core traits**. No trait may exceed 5 at creation.
- Trait scale: 1 = functionally impaired; 2 = below average; 3 = baseline adult human; 4 = exceptional; 5 = rare talent (top percentile).
- Trait meanings:
  - Physique — strength, endurance, durability, applied violence.
  - Reflexes — coordination, reaction speed, precision, spatial control.
  - Mind — mental resilience, magical affinity, processing speed, control under stress.
  - Charm — presentation, framing, social weight, perceived dominance (Charm 5 = "cinematic gravity, the scene favors you").
- **Skill Points:** each trait grants skill points equal to its level (1 point per trait point, tied to that trait).

### 2.2 Stats & Actions
- Actions **auto-succeed** if the stat requirement is met. No to-hit rolls.
- Common action → stat mapping: Sprint/Chase/Swim/Resist Physical (Physique); Climb (Physique+Reflexes); Balance/Sneak (Reflexes); Shadow (Reflexes+Mind); Leap/Vault (Reflexes+Physique); Command (Charm); Persuade (Charm+Mind); Intimidate (Charm+Physique); Track/Navigate/First Aid/Resist Mental (Mind); Bluff/Repair/Rig/Disable Trap (Mind+Reflexes).

### 2.3 Stat Caps (upgrade points, unlocked from 10+ in a stat)
- **Physique:** every 5 points → +1 max HP to a body part.
- **Reflexes:** every 12 points → 1 physical resistance of chosen type (Bleed, Crush, Burn).
- **Mind:** every 15 points → 1 psychic resistance. *(Note: app currently seeds "every 10 Mind = 1 Psychic Resistance"; exact threshold `[OPEN]` — doc says 15.)*
- **Charm:** every 20 points → 1 **Camera Call** stack. Each stack = one use/session. Camera Call: camera focuses a target; Viewership/Follower/Patron gains AND losses from that target are **doubled** until end of that target's current or next action.

### 2.4 Skills
- Skills are the main way of executing actions. Attributed to one or more stats; raised with skill points of those stats.
- Start at **level 0** (revealed, no effect) — lets players see possibilities without investment.
- Each level improves reliability, duration, scope, or control.
- **Thresholds:** every level from 5 up. Reaching a threshold **Upgrades** (adds effects) or **Mutates** (changes purpose completely) the skill.
- **Cap:** every skill starts capped at 5. Raised with **Patron Tokens** (+1 max level per token) up to **10**. Cap 5 = useful; cap 6 = build-defining; level 10 = game changer.
- **Acquisition:** most skills unlock by doing (revealed at level 0 on fulfilling obtaining requirements). Magic and similar require an external source: appropriate-tier Loot Boxes, Achievements, or Lounge modules (e.g., Wizard's Tower). Example: setting a target on fire from a distance (Molotov) may award Fireball as an Achievement.
- **Consuming skills:** skills can combine/consume other skills to upgrade or mutate. Consumed skills permanently alter the upgraded skill; unrecoverable unless stated. Never automatic — requires conditions AND player consent.
- Multi-stat skill example (Drill 5/6): upgradeable only with skill points from **both** stats.
- **Cooldowns:** removed from the system entirely (app decision; earlier drafts had them). `[EXECUTED]`

### 2.5 Health — Body Parts & HP
- Localized health. Body part HP: **Head 2 (lethal), Torso 5 (lethal), Arm 2 each (non-lethal), Leg 3 each (non-lethal)**.
- HP = structural integrity; 0 HP = the part fails.
- **Death:** immediately when Head or Torso reaches 0. Limb damage alone can't kill.
- **Bleed out:** if death occurs while Bleeding/Crushed/Poisoned/Infected/Exhausted and torso/head still have HP → 1-Clock bleed-out period. Delaying the cause of death keeps them alive; healing the death condition restores them. While bleeding out: helpless, cannot act, any damage instantly kills.
- **Disabled parts (non-lethal at 0 HP):**
  - Arm: drops held items, no two-handed actions, using it = Forced Action with severe consequences.
  - Leg: movement = Forced Action, target becomes Exposed, sprinting/evasion extremely dangerous.
  - Further damage to disabled parts doesn't reduce HP — escalates conditions or causes permanent loss/detachment (detachment applies Bleeding).
- **Targeting:** Head untargetable by default; only if target is Exposed, Helpless, or Overwhelmed (ambush/execution/extreme speed disparity). Torso/arms/legs always targetable unless fiction prevents.
- **Damage resolution:** choose valid body part → reduce HP (usually 1) → apply damage type effects.

### 2.6 Damage Types & Conditions
- **Bleeding:** HP on hit + Bleeding condition; untreated → poison/infection risk; advances each Clock. T1 open wound; T2 Forced Action–Body + Shock T1; T3 part dies (lethal on torso/head), all actions Forced Action–Body; T4 death.
- **Crushed:** HP on hit. T1 Break (Forced Action–Body); T2 Shatter (Forced Action–Body). Limbs: disables. Torso: internal trauma, rapid escalation. Head: instantly lethal if targetable.
- **Suffocation:** torso only, ignores limb HP, **2-Clock death timer**; timer completes = death.
- **Chilled:** specific part, no HP damage. T1 resolves after 8 Moments without advancement; T2 Forced Action–Body; T3 part disabled (head: usually fatal/incapacitating).
- **Exhausted:** whole body; increases action Moment cost; Exposure occurs on body hits.
- **Infected:** whole body; prevents healing; accelerates other conditions; possible special effects; lethal if untreated.
- **Burn:** specific part, HP damage. T1 stops bleeding, removes chill; T2 stops poison, clears infection, Forced Action–Body; T3 loss of part of limb + Shock T3.
- **Poison:** no immediate HP damage. Entry conditions: open wound, orifice, injection/bite, helpless target. Activation delay (usually 2 Clocks). Always targets specific parts. Tiers: T1 Disruptive (no lethal clock), T2 Crippling (disables, introduces clocks), T3 Catastrophic (lethal clock, must be delayed/cured). Types: Neurotoxin, Hemotoxin, Myotoxin, Pneumotoxin, Cytotoxin. **Spread:** on advancement, spreads to an adjacent part at reduced intensity, sharing the advancement clock (Arm/Leg → Torso; Torso → Head or Limbs). **Poison Soup:** incompatible poisons on same part → all effects end, direct HP damage = combined tiers, toxicity dissipates.
- Conditions stack freely; multiple lethal timers can resolve simultaneously.
- **Condition states:** Active / Delayed / Resolved. In-combat treatment usually delays (bandages→Bleeding, antitoxin→Poison, clean air→Suffocation). Full resolution needs downtime/advanced tools/special abilities. In-combat HP recovery is extremely rare and explicit.

### 2.7 Shock (pain response, 4 tiers)
- T1 **Shout** — cry out, draws attention, breaks stealth.
- T2 **Stutter** — freeze; current action fails.
- T3 **Faint** — collapse, unconscious 1 Clock, drop held item.
- T4 **Helpless** — Exposed for the rest of combat.
- Applies at specified tier; "elevation" = take latest shock +1 tier.

### 2.8 Dissolution `[SYSTEM]` + session extensions `[DESIGNED]`
- Condition targeting the **Mind**; functions like Suffocation but mental. **2-Clock death timer on the Mind**; completion = Mind collapses, KO.
- Each Clock in the triggering condition advances timer by 1. Removing the cause **pauses** (does not reset).
- Cannot be applied by standard attacks — requires explicit source (environmental, creature, etc.).
- A Dissolution "death" isn't necessarily story removal: brainwashing, mind-crushing, zombification, etc.
- **Session extension — Demonic Nobility Dissolution encounter (Medium route):**
  - Categorical distinction: normal demons = fallen/comprehensible humans; **demonic nobility corrupts through existence alone** (Dissolution + emotion amplification), not action. The demonic brand grants immunity specifically to noble-class presence.
  - Noble presence triggers Dissolution (Mind-based suffocation clock). Each player hears a **personal song** targeting their core emotional drive.
  - **Embrace the song → die**, become a mindless ghoul serving the demon (ghoul persists in story).
  - **Escape the room → survive** with a permanent scar: one emotion amplified near demons.
  - **Feeding window:** demon distracted while eating = narrow escape opportunity.

### 2.9 Resistances
- Flat reductions per type (specific like Bleed, or generic like Physical). 2 Bleed resist = −2 Bleed damage, floor 0.
- **Affliction resistance** (Chill, Poison, Infection) and **Psychic resistance** (Dissolution) work by tiers — each tier gives immunity to all in its tier and below.
- Classification: Physical = Bleed/Crush/Burn; Affliction = Chill/Poison/Infection; Psychic = Dissolution.
- Session decision: enemy mental resistance is **flat**, and exceeding thresholds by a significant margin grants a bonus (e.g., Viewer spike / secondary effect). `[DESIGNED]`
- Affliction resistance sourcing — deliberately parked. `[OPEN]`

### 2.10 Combat — Clocks & Moments
- Shared **Clock** of Moments (typically **10**), counting **down**; at 0 it resets and starts anew.
- Actions cost Moments; multiple characters may act on the same Moment; actions overlap, never interrupt.
- **Initiative:** player party chooses which side acts first (unless surprised). Chosen side acts on starting Moment. No fixed order.
- **Ambush/surprise:** ambusher enters at normal starting Moment; surprised side enters later — minor surprise Moment 8, full ambush Moment 5. Surprised characters can't act before entry Moment.
- **Scheduling:** on your Moment, declare action; next action = Current Moment − Action's Moment Cost. Ties resolve in any order fitting the fiction.
- **Baseline Moment costs:** Move = 1 per 4 spaces (1–3 spaces cost 0). Weapon attack 1–3 (weapon-dependent). Skill 1–3 (skill-dependent). Inventory interaction: 0 first time, 1 per successive interaction; resets after a ≥1-Moment different action.
- **Multi-Moment actions:** cost >1 = sustained effort → **Exposed** for the duration unless protected; no other actions until resolution; if invalidated first, collapses into **Forced Action – Tool**. Multi-Moment actions resolve before Forced Action consequences.

### 2.11 Forced Actions (d6, two tables)
- Any action taken while unsafe/impaired. Always allowed. Resolves normally; consequences apply immediately after (or next Moment).
- **Body table:** 1 Tear Something (1 damage to relevant part; escalates at 0 HP); 2 Lock-Up (part unusable 3 Moments); 3 Condition Surge (advance an active condition 1 clock, prioritizing the responsible one; else Shock T1); 4 Drop item in involved limb; 5 Shock Spike (+1 Shock tier); 6 Stumble (Exposed until next Moment).
- **Tool table:** 1 Whiff; 2 Overcommit (Exposed); 3 Collateral (ally/object/environment); 4 Slip (unarmed until next Moment); 5 Strained Grip (+1 Moment cost next tool action); 6 Overextension (next scheduled action delayed +1 Moment).
- Unfulfilled weapon/skill requirements → action still usable but roll Forced Action – Unexpected Circumstances.

### 2.12 Exposed (lethal state)
- Allows Head targeting and other lethal targeting.
- Caused by: Stumbled, Proned, Helpless, Channeling, exposing abilities.

### 2.13 Weapons
- Requirements must be met or Forced Action applies. Reloading always takes 2 hands and is mandatory unless auto-reload. Ranged Moment cost measured in **RPM (Rounds Per Moment)**.
- Base weapon classes:
  - **Light Small** (daggers/shortswords/knives/tools): 1 Physique, 1 hand, range 1, cost 1, 2 Bleed.
  - **Light Large** (rapiers/whips/spears/light polearms): 3 Physique, 1 adjacent empty radius, 2 hands, range 2 line, cost 1, 2 Bleed.
  - **Heavy Small** (maces/hammers/axes/clubs): 2 Physique, 1 hand, range 1, cost 1, 2 Bleed/Crush.
  - **Heavy Large** (greatswords/mauls/halberds): 5 Physique, 1 adjacent empty radius, 2 hands, range 2 line/arc, cost 1–2, 3 Bleed/Crush.
  - **Light Ranged** (pistols/hand crossbows/slings/bows): 2 Reflexes, 1–2 hands, steady ground, ammo, reloading; range 5+, single target, 1 RPM, 1 Bleed.
  - **Heavy Ranged** (rifles/shotguns/cannons/large bows/heavy crossbows): 4 Reflexes, 2 hands, steady ground, ammo, reloading; range 5+ line/cone/area/dome/single; cost varies; 4 Bleed/Crush.
- Example flavor item: **Spark-volver** (1 hand, 5 Physique, Sunglasses, Tags Flashy + Catchphrase; Range 10, 3 RPM, 2 Burn + 1 Crush, Guided/ignores cover).

### 2.14 Enemies
- Categories: **Mobs** (die in one meaningful blow, never alone), **Elites**, **Bosses**, **Super Bosses**.
- Boss variants: Neighbourhood → District → City. Super Boss variants: Precinct → Country → Stage (stage boss not expected to be beaten).
- Most bosses' win condition = reaching the position where a killing hit is even possible, not the hit itself.
- Enemies win by creating problems faster than the party can manage.
- **Reorganization** only at narrative beats (round end, leadership loss, phase change, condition shift); never mid-action. May split/merge groups, change tactics, alter formations.
- Bosses respond to catastrophic player effects via phase changes, accelerated pressure, auto-repositioning, sacrificing resources.

### 2.15 The Lounge
- Party's corporate-controlled modular base; unlocks after Tutorial Boss.
- Rules: no entry during combat; all Loot Boxes must be opened inside; opening opens ALL held boxes simultaneously; a guide is available; overstaying → ejection + 24h re-entry lock; fully monitored 24/7; higher levels = more surveillance.
- Currencies: **Upgrade Tokens** (bosses, bartering, crowd donations, Directives, rare loot boxes); **Boss Tokens** (tiered Bronze/Silver/Gold/Legendary/Mythic/Godly, unlock modules).
- **5 major sections + submodules:**
  1. Living Facilities — Dormitories (auto), Restrooms (auto), Kitchen (1 Bronze), Farm (1 Silver — animals, food, mounts).
  2. Factory — Forging Station (1 Bronze — blacksmith/carpenter/fletcher/bower), Goldsmith (2 Bronze — jewelry/trinkets), Melding Station (1 Silver — merge 2 same-type equipment into 1), Advanced Fabricator (1 Silver — gunpowder/electricity tech), Enchantment Altar (2 Bronze — extract/apply modifiers), Wizard's Tower (3 Bronze — create modifiers & magical relics).
  3. Modification Center — Skill Gemstone (1 Bronze — disassemble/consume/merge skills), Tattoo Artist (1 Gold — permanent buff tattoos), Surgeon's Table (2 Silver + race change — biological body mod), Augmentation Hub (2 Silver + race change — mechanical body mod).
  4. Garage — Bike Shop (3 Silver), Car Shop (3 Silver), Armory (3 Gold — armored vehicles).
  5. Universal Travel — door of descent; fixed, no submodules.

### 2.16 Exposure (audience economy)
- **Viewers** — active watchers; correlate with reward potential and session chaos; conversion pool for Followers.
- **Followers** — clicked "Follow"; notified when player is active; affect TV rating, potential allies/enemies, Directive volume.
- **Patrons** — paying audience members; can set paid Goals (direct story intervention + rewards).
- **Patron Tokens:** earned by gaining a new Patron via a Goal, or completing a Directive. Spent to raise a skill cap beyond 5 (+1 max level per token, ceiling 10).
- **Exchange:** 3 Boss Tokens → 1 Patron Token, one-way only.

### 2.17 Tags
- Public identity as the Show sees you. Influence loot bias, crowd response, narrative framing, mechanical triggers.
- Gained via: table consensus ("it's their thing"), hidden condition fulfillment, Goals/Directives, corporate narrative shaping. Player-proposed tags must appear on TVTropes.org (⚠ video game flag: internalize this dependency `[GAME]`).
- Lifecycle: acquired → Reinforced (play into it, stack gear/skills, potentially permanent) → Faded (neglected) → Lost → reacquirable.
- **Full tag list (v0.91):** Documentary, Playa, Absolute Cinema, Edgy, Anime, LEEROY JENKINS, Scrub, Stinker, Pinky Promise, Unkillable, Oops, Vengeful, Menace, Animal Planet, Fan Favorite, Corporate Asset, Tragic, Bolivian Army Ending, Chunky Salsa Rule, Coconut Superpowers, Protagonist, Antagonist, Anti-Hero, Incorrigible, No Cure For Evil, Munchkin, Little Dead Rising Hood, Mascot, Butcher, Survivor, Spy, Liability, Method Actor, Understudy, Typecast, Prima Donna, Scene Stealer, The Monologue, Fourth Wall, Box Office Bomb, Director's Cut, Certified Fresh, SAG Dispute, Direct to DVD, Callback, Nepotism Hire, One Star Review, Student Film, Craft Services, Resting Loser Face, Applause Machine, Unlikely Menace, Adorable Threat, Waddled Into Frame, The Bit, Bark Bark Bark, Sea World Reject, Flipper Mode, Crowd's Baby, Nine Lives, Knock It Off The Table, Feral Consultant, Witnessed, Murder Mittens, Dead Drop, Vet Visit, Territory Marked, 3am Energy, Indoor Cat, Birdwatcher, Main Vocalist, Visual, Maknae, Rap Line, Formation, Comeback Stage, Internal Dispute, Solo Debut, Parasocial, All-Kill, Disbandment Arc, Fan Service, Blue Screen, Legacy Code, Corrupted File, Unpatched, 404, Out of Memory, Safe Mode, Null Pointer, Overclock, Peer Review, Technical Difficulties, Off Script, Crossover Event, Genre Shift, Background Character, The Recast, Blooper Reel, Post-Credits Scene.
  - Notable clusters: animal-flavored tags (Sea World Reject → Crowd's Baby block, fitting Filipe/Sasha), K-pop tags (Main Vocalist → Fan Service block, fitting XQUEZ/T), and robot/software tags (Blue Screen → Post-Credits Scene block, fitting XQUEZ/T's glitching).

### 2.18 Narrative Tokens
- Allow players to interfere with the script. Earned via crowd donations, corporate rewards, rare monster drops.
- One token = a significant narrative shift within a scene; scope by DM discretion.
- Hard limits: cannot bring back the dead, change how someone feels about you, instantly kill, or request more tokens. Alter events, never override core rules.
- ⚠ Video game flag: "DM discretion" mechanic needs a complete rebuild or cut for digital. `[GAME]` `[OPEN]`

### 2.19 Directives (Corporate Quests)
- Issued by The Corporation/subsidiaries. Optional, risky, no guaranteed benefits.
- Types — Direct Action: Eliminate Target, Protect Target, Find Target, Act Before the Clock. Manipulation/Info: Convince Target, Extract Information, Expose Truth, Control the Narrative. Performance/Spectacle: Play Role, Subvert Expectations, Generate Drama. Pressure/Timing: Delay Outcome, Escalate Conflict. Risk/Sacrifice: Be the Distraction.
- Rewards distributed via the Achievement system. Completing a Directive awards a **Patron Token**.

### 2.20 Goals (Crowd Challenges)
- Issued by the audience for rewards + crowd favor.
- Types — Spectacle: Finish Fast, Overkill, Environmental Kill, Multi-Target Hit, No Safety Play. Performance: Play into a Tag/Trope, Act Reckless, Act Tragic, Act Stylish, Say the Line/Do the Bit. Risk: While Exposed, With a Disabled Limb, Without Healing, Solo Action. Subversion: Spare the Enemy, Let Them Escape, Betray Expectations.
- Rewards via the Achievement system. A Goal that converts a viewer into a Patron awards a **Patron Token**.

### 2.21 Achievements
- GM's method of recognizing player effort. Categories: Scenario Completion, Quest Completion, Class usage, Race usage, Directives, Goals.
- Loot box tiers: **Bronze** (cheap bulk utility — torches, rope), **Silver** (tools/armor/limited magic — e.g., Sword of Wind), **Gold** (game-changers — e.g., Big Brain: instantly Mind Crush all Mobs in 50m), **Legendary** (campaign-carrying — e.g., Autofighter robosuit), **Mythic** (meta-breaking, extremely rare), **Godly** (defying fate, almost never given). Tiers can very rarely be upgraded.
- Reward categories: Buffs (+1 stat, effect increases, resistances, narrative effects — permanent or temporary), Unlocks (loot types, Directives, Tags/Tropes, Goals, opportunities), Items (weapons, tools, armor, furniture, skill tomes), Abilities (class/race/unique abilities, body parts).
- Example achievements: "Bloody Hell!" (cosmetic +50% blood), "Kung fu fighting!" (Silver Scenario box), "Smile and wave" (Bronze Race box).

---

## 3. DESIGNED CONTENT FROM SESSIONS `[DESIGNED]`

### 3.1 The Incineradile — Tutorial/Neighborhood Boss (Citadel)
- **Cinematic intro:** gates close, everything freezes, "Party X vs. Boss" announcement, spotlight on a band above the arena in a giant cage, band plays, spotlight out, music continues, unfreeze. Boss music: *God Shattering Star* (Fire Emblem).
- **Concept:** apparent giant reptile with a flamethrower; actually a **mycelium puppet** — a network inside controls the body, reattaches limbs, and vents pressure by exploding.
- **Surface Immunity:** all damage pre-breach = zero HP loss, cosmetic only. Party must discover this themselves.
- **Breach Path A:** reach **Bleed Tier 2** on any body part — the wound exposes the mycelium network.
- **Breach Path B:** deal **7+ damage in a single hit** to one part — brute-force punch-through; network takes damage at that location.
- **Crush 2** on any body part disables it; disabling the Left Hand permanently removes the Flamethrower.
- **Fire Heals:** all fire damage and Burn received heals the boss; burning trash cans feed it.
- **Trash cans:** explode at Burn 5 — 3-space radius, 2 Burn; environmental hazard and boss liability.
- **Single HP bar** (total 50).
- **Phase 1 — Ignition (HP 50→36):** Flamethrower (10-hex cone, 2 Burn); Dash (straight-line charge, knocks targets aside, 3 Crush to Torso on contact); Death Spin (3 Moments: M1 Grab — 5 damage to the hand releases; M2 Chew — 2 Crush both arms; M3 spin-and-kill).
- **Phase 2 — Pressure Valve I:** explosion, 5-space radius, 2-Moment escape window, instant KO inside radius, visible steam telegraph 1 Moment before. Network retreats deeper — breach threshold resets.
- **Phase 3 — Frenzy (HP 35→19):** all P1 abilities; flamethrower pops trash cans instantly on contact; Dash bounces off walls up to 2 bounces; Death Spin grab range +1 hex.
- **Phase 4 — Pressure Valve II:** explosion, 7-space radius, 2-Moment window, instant KO; network fully exposed after — damage open without breach conditions.
- **Reflexes counters** to (likely Dash): Reflexes 7 auto-dodge + move 1 space; Reflexes 9 auto-dodge + counterattack; lower: roll 4+ to dodge.
- **Arena:** 41×60 hex layout.
- Design intent: boss punishes inaction (flamethrower/dash pressure); early struggle is intentional so later growth feels earned.

### 3.2 Weapon Tiers & Modifier System
- **Weapon quality tiers with modifier slots:**
  | Tier | Name | Prefix slots | Suffix slots |
  |---|---|---|---|
  | 1 | Crude | 0 | 0 |
  | 2 | Basic | 1 | 0 |
  | 3 | Quality | 1 | 1 |
  | 4 | Superior | 2 | 1 |
  | 5 | Exceptional | 2 | 2 |
- **Modifier tier gating by weapon tier:** Basic → Lesser only; Quality → up to Normal; Superior → up to Higher; Exceptional → up to Legendary. Progression = access, not just slots.
- **Modifier tiers (planned):** Lesser, Normal (Modifiers), Higher, Legendary, Mythic, Godly. Only Lesser designed so far.
- **Lesser modifier candidates (working list):** Poisoned (T1 Poison on hit), Serrated (+1 Bleed), Weighted (+1 Crush), Spiked (secondary 1 Bleed on Crush hits), Hollow Point (ignores 1 armor), Chilling (Chilled T1 on hit), Explosive Tip (crit → 1-space blast), Barbed (removal deals +1 Bleed). Flagged for replacement: **Padded** (too conditional), **Reinforced** (too strong for Lesser) → candidates **Wrapped, Balanced, Sure-grip**. Notes: **Draining** should be capped once per Clock/target (condition-fishing abuse); **Balanced + Sharpened II** nearly eliminates multi-Moment attack cost (consider incompatibility); **Volatile** synergizes strongly with Sasha — consider reserving for higher tier.
- **Extraction rules (Enchantment Altar):** Lesser/Normal — extractable, chance to destroy the modifier (better odds with Lounge upgrades/skills). Higher+ — extractable but weapon drops one tier. Legendary+ — extraction destroys the weapon.
- **Fantasy Item Coupons:** each player receives a coupon to self-design a **Basic-tier weapon** + a separate coupon for **one Lesser modifier** (e.g., poison halberd, spiked heavy helmet). Each player picks their own for character fantasy. **Distribution not completed.** `[OPEN]`

### 3.3 XQUEZ/T Tank Kit (drafts)
- Problem: player frequently skips Moments, wants tank role; system has no baked-in tank identity (no taunt/intercept/DR).
- **Intercept (draft):** when an adjacent ally would be hit, take the hit instead. Physique-based, 0 Moment cost.
- **Iron Stance (draft):** declare at start of a Moment; don't move; all attacks targeting allies in adjacent spaces target you instead. Physique 5 requirement (fits XQUEZ/T exactly).
- Existing **Brace** reduces Crush/Burn by 1 — could get a robot-specific upgraded variant.
- Fictional fit: glitching robot with Physique 5 absorbing punishment is on-brand. Boss design (wide flamethrower cone) makes body-blocking cinematic and meaningful. Finalization pending. `[OPEN]`

### 3.4 Sasha's Skill Revisions
- **Nightlurking** (Mind+Reflexes, passive, cost 0, cap 5): always aware of nearest exit/gap/vent/opening; fits through cat-plausible spaces without Forced Action. L3+: detects concealed entrances within Near. L6+: full-speed movement through detected gaps, no Moment penalty. Unlock: find/use an exit no other party member noticed.
- **Lockpicking:** reworked from passive to active with Moment cost; "simple locks" scoped with a scale.
- **Acrobatics:** passive; clarified what "-1 requirements" applies to; differentiated from Quick Step (Acrobatics = vertical/precision, Quick Step = terrain).
- **Slice n' Dice:** costed properly (3 Bleed dual strike either 2 Moments or meaningful restrictions); claw flavor leaned into.
- Other reviewed party skills (earlier session): Filipe — Aura Reading (passive telepathy-lite, needed cost + sharper effect), Swim (racial, needed numbers, should scale aggressively for a sea lion), Vibe Control (split Fear/Charm modes), Juggling (item passing as combat action). XQUEZ/T — Dance (+1 Charm on movement while dancing), Voicebox, Controlled Sweep, Feint.

### 3.5 Dissolution Songs (per character, Medium route noble encounter)
- **Mario (Sea Lion, healer)** — *"Every Living Breathing Moment"* (Grant Steller): targets his dream of feeling like a hero.
- **Sasha (Cat)** — *"Dark is the Night"* (changed from *"Dream Sweet in Sea Major"*): tied to Nikita; she hears **his** fear, not hers. Inherited trauma.
- **XQUEZ/T (AI)** — *"Human"* (Daft Punk): the split-second awareness it is one AI, not seven people.
- **Filipe (Sea Lion)** — TBD: song of godhood/superiority targeting cynical pride. `[OPEN]`

---

## 4. CAMPAIGN STORY `[STORY]`

### 4.1 Structure
- **Current state:** Tutorial phase (same as playtest, fights hardened; GM currently favoring non-lethal body-part targeting as mercy; considering boosting all body-part HP or easier HP acquisition since it's hard to hurt without killing). Party has cleared most rooms, heading to the boss room (Incineradile) → Lounge unlock → real dungeon begins.
- **Floor structure:**
  - Tutorial (current)
  - **Floor 1** — green forest; three labeled routes begin (Easy/Medium/Hard). Players pick **one route per campaign**; others resolve offscreen.
  - **Floor 2** — great desert, **70 years later**.
  - **Floor 3** — grand capital, **100 years after Floor 2**; the capital then attaches to the Lounge as a persistent location.
  - **Floors 4–6** — continent merge phase (players consolidated into shared floors as competition narrows); Nikita appears here.
- Floor scaling concept: each floor grows in geographic size (city → country → continent and beyond).

### 4.2 Easy Route
- **F1:** man in the forest near a grand staircase → dungeon descent with him → he claims a treasure, a **mask**, and becomes possessed → players find prophecy note/mural instructing them to chain him to the wall → dungeon collapses on exit → back at Lounge.
- **F2:** same stairs, dungeon in ruins; the man is still chained, alive via the mask, unpossessed but ravaged by time (extremely old). A demon blocks the exit; defeat it; free the man.
- **F3:** the man is now **"Nullrot,"** simultaneously spreading and curing a disease in the capital; players choose to fight or help him.

### 4.3 Medium Route
- **F1:** haunted house; NPCs try to burn it with a girl inside. Killing the NPCs → the girl (a demon) asks to be fed; grants a **demonic brand** + faction points. (Brand = immunity to noble-class presence/Dissolution.)
- **F2:** the girl is now a **demonic queen**; players assassinate a rival demon who helped humans and wants to overthrow her. (This is the Demonic Noble / Dissolution-songs encounter context.)
- **F3:** the surviving NPC party leader runs a **human farm** in the capital; a demon wants a specific human sacrifice to cure his demonic nature; players sacrifice one or kill him.

### 4.4 Hard Route
- **F1:** a moving city atop giant stairs, guarded mindlessly by a **Loong Kin**; persuade it the city is abandoned and its citizens crystalized.
- **F2:** the Loong is in the desert, hunted by demons; escort it to a village where it finds purpose.
- **F3:** the Loong hides in the capital preventing disease spread; demons hunt it as a cure for their nature; help it develop the cure and protect it.

### 4.5 Nikita (NPC — Sasha's former owner)
- Named after Nikita Bogoslovsky, composer of *"Dark is the Night"* (1943, lyrics Vladimir Agatov, performed by Mark Bernes in *Two Soldiers*; Soviet authorities disapproved yet it became a wartime symbol — "contraband grief").
- **Backstory:** WWII-era Jewish refugee from occupied Poland; his wife was captured and killed during the war; he survived and was conscripted into the Red Army; developed dissociative blackout episodes during combat that he normalized as routine.
- **The song** is his comfort mechanism AND the activation trigger: when he sings it to calm down, his reversion skill activates.
- **Reversion skill (what kept him alive):** snaps him to his 1945 peak state — physically restored, tactically sharp, but his mind resets to match; he doesn't know the war ended.
- **Two states:** **Old Nikita** — frail, lucid, remorseful, can be talked to, knows Sasha's name. **War Nikita** — combat-hardened, wartime logic, everyone is comrade or enemy, the dungeon reads as the Eastern Front; Sasha is just a cat (or worse, processed through a wartime lens). He oscillates between states across encounters; triggers include stress, damage, the song, combat pattern-matches. Encounters with him are about identifying which Nikita you face — fighting War Nikita is dangerous; reaching Old Nikita may be the only true path.
- **The nurse & the scarf:** a nurse used her scarf to calm him during episodes; War Nikita killed her; Old Nikita now carries the scarf believing it is a promise to return it to her.
- **Campaign placement:** seen in Sasha's F1 demon vision; appears in person during Floors 4–6 continent merge.
- **Potential adaptation:** standalone short story of Nikita and Sasha (inherited trauma, misread love). Craft guidance: historical context as atmosphere, not explanation; give Nikita's wife full individual personhood before any historical framing. `[OPEN]`

### 4.6 Sasha's Floor 1 Demon Encounter (designed sequence)
- Black room; distant hound howls; she relives her stray days being chased.
- **Maze mechanic:** she picks where to run; the demon keeps cornering her, funneling her to one specific door — **Nikita's house**.
- **Choice:**
  - **Fight the dogs:** they run straight past her; looking back, the house is gone — she sees **Nikita's wife** being hunted by hounds, Polish spoken overhead, Nikita far off yelling her name, unable to reach her. Scene flashes to his room: Nikita with his gun at his side, singing the song to himself. This is the reveal — the fear is **his**, not hers. Recognition = clarity = the Dissolution escape window.
  - **Enter the house (flee):** the demon starts winning through familiar logic (safety over strength — the same choice that put her with Nikita); she must deduce it's his fear alone, without the visual revelation — harder, lonelier, survivable if sharp.
- The hounds recontextualize as war dogs. The Polish detail implies Eastern Front circumstances without stating them.
- Mechanical spine: Dissolution amplifies *an* emotion, not necessarily *yours*.

---

## 5. LIVE PARTY DATA `[CHARACTER]` (snapshot at Level 6, 6 unspent trait points each)

| | Physique | Reflexes | Mind | Charm |
|---|---|---|---|---|
| **Filipe** (Sea Lion) | 3 | 4 | 3 | 4 |
| **XQUEZ/T** (AI robot) | 5 | 2 | 3 | 4 |
| **Mario** (Human) | 4 | 3 | 2 | 5 |
| **Sasha** (Cat) | 3 | 4 | 4 | 3 |

- **HP (Head/Torso):** Filipe 2/5, XQUEZ/T 2/5, Mario 2/5, **Sasha 2/3 (squishiest torso)**.
- **Filipe** — healer/support. Frost Ball 3, Seal The Wound 2 (only dedicated healer/condition manager). Scalpel (bleed), Stun Net (1 use, leg disable). Skills incl. Aura Reading, Swim, Vibe Control, Juggling.
- **XQUEZ/T** — 7 K-pop personalities, bugged/glitching. Physique 5, **no weapons** (bare hands). Controlled Sweep 1, Feint 1, Dance, Voicebox. Player skips Moments; moving to active tank role (Intercept/Iron Stance).
- **Mario** — brawler. Heroic Punch 4, Acrobatic Save 4, Read The Pattern 2. 25 arrows, Gauntlets, Unbleed suit; crossbow acquired incidentally. (Note: Mario-exclusive skills Full Potential + Heroic Punch flagged for schema-level character lock.)
- **Sasha** — primary damage dealer. Slice n' Dice 6, Nightlurking 5, Pounce 1. Steel claws (+1 Bleed). Significant backstory tied to Nikita.
- Planned equipment upgrade: all four get Basic-tier weapons + fantasy item coupons (1 Lesser modifier each) — pending. `[OPEN]`
- *(Note: memories list "Mario (Sea Lion) — healer" and "Mario Marcus (Human) — brawler"; character-sheet data names the sea lion healer Filipe. Treat Filipe = sea lion healer, Mario = human brawler as canonical from sheet data; reconcile naming if needed.)*

---

## 6. VIDEO GAME ADAPTATION (GDD v0.1 decisions) `[GAME]`

### 6.1 Core identity
- **Genre:** 2.5D tactical RPG, PC primary. **Engine: Godot.** Full remappable input (controller + KB/M).
- **Tone:** dark corporate satire, LitRPG spectacle, "nobody becoming somebody." Core player fantasy: an underdog nobody trying to become somebody to survive; the four sub-fantasies (survivor / rising star / tactical genius / spectacle machine) emerge from playstyle and skill choices.
- **References:** Salt & Sanctuary, Dark Souls (exploration/atmosphere/death weight), Heroes of Might & Magic, Songs of Conquest (combat architecture), Darkest Dungeon (depth).
- **Target length:** 40+ hour campaign. **Endgame:** New Game Plus with escalating difficulty.
- **Complexity target:** Deep (Darkest Dungeon/XCOM depth) — deep systems, not deep content volume.
- **Development:** solo build by Ben (professional full-stack developer); collaborators for assets and music.

### 6.2 Architecture decisions
- **Two-mode structure:** overworld exploration (real/semi-real time, handcrafted, one-way zone locks à la Salt & Sanctuary) + discrete tactical combat arenas with the Clock. HoMM/Songs of Conquest mode-switch model.
- **Clock combat ports nearly 1:1:** Moments = discrete turns with visible countdown; simultaneous action = declared-order resolution within a Moment.
- **Noise/absorption mechanic:** noisy combat attracts nearby encounters — after a Clock runs out, other area encounters can be absorbed into the fight. Solves grinding automatically; makes stealth/social mechanically relevant; spectacle-over-safety in the exploration layer. Audience clock and absorption clock can be the same system, differently flavored.
- **Death:** checkpoint rewind — full world state reset on death (old-school load); **character + Lounge upgrades persist** between sessions.
- **Party:** fully custom party; player controls a party; non-PC party members can permanently die.
- **Exposure as core loop:** Viewers = hype momentum via a rolling performance curve; Followers = stabilized reward floor. Viewer spikes from achievement hunts, encounter difficulty clears, clear times.
- **Overworld = state machine** tracking noise levels, encounter positions, clock states; combat = self-contained scene with its own Clock; results feed back on exit. Skills/tags/conditions as data resources; Clock as a service; Exposure as an economy service with event hooks.

### 6.3 Translation debts (flagged)
- Forced Action must be fully deterministic tables — no fiction-reading.
- Narrative Tokens need a complete rebuild or a cut.
- All "GM discretion" language must be eliminated.
- Exposure needs a concrete economy loop (partially resolved above).
- TVTropes.org tag-sourcing dependency must be internalized.
- Lounge downtime is a spectacle dead-zone — make surveillance bite; the Lounge should be dangerous in a different way.
- Copyright: mechanics are safe; avoid lifting Dungeon Crawler Carl characters/prose/world details verbatim.

### 6.4 GDD open questions `[OPEN]`
- Narrative delivery method (voiced vs. text mix).
- Party size cap.
- Checkpoint density.
- New Game Plus modifier specifics.

---

## 7. EXECUTED LOGIC — Character Sheet Web App `[EXECUTED]`

### 7.1 Stack & structure
- **Client:** React + Vite (`/client`). **Server:** Express + MongoDB/Mongoose (`/server`). **Auth:** JWT in localStorage, separate admin token. One document per player in `characters` collection.
- Repo: `Bent40/Galactic-Prime-Time`, branch `option2`. Dev via VSCode + Claude Code. **`CLAUDE.md` written to project root** to persist context across Claude Code sessions; standing rule: always commit after completing Claude Code tasks.
- Structure: `/client/src/components/{admin,character,shared}`, `/pages/{AdminPanel,CharacterSheet}.jsx`, `constants.js` (DEFAULT_STATE, trait lists, item tiers, uid(), dmgClass()), `api.js`; `/server/{models,routes,utils}`, `skillUtils.js` (enrichSkills, normalizeSkills, normalizeTraits).

### 7.2 Confirmed data model decisions
- **Traits (consolidated):** `traits: { physique|reflexes|mind|charm: { base, bonus, levelBonus } }`; `traitTotal(t) = base + bonus + levelBonus`.
- **Skills (reference model — snapshot model considered and rejected):** character instance stores only `{ id, templateId, level, capacity, traitCosts }`; display fields joined from `SkillTemplate` at runtime via `enrichSkills()`; `normalizeSkills()` strips template fields before save.
- **Level points:** single unified pool `levelPoints: { pool: 0 }` (NOT split by pillar). Admin grants via `POST /api/admin/players/:userId/levelup`; player spends via `investLevel(t)` (decrements pool, increments `traits[t].levelBonus`). **Level is read-only on the player sheet** — admin-only.
- **Skill points:** per trait = `traitTotal(t) − 1`, min 0 (first point in any trait earns nothing). Available = `max(0, traitTotal(t) − 1 − skillPointsSpent[t])`. **Multi-stat skills cost 1 point from EACH listed stat.** `traitCosts` array tracks spends for refund on level-down.
- **Stat cap auto-bonuses (implemented):** Physique every 5 pts over 10 → +1 max HP to a part; Reflexes every 12 → 1 physical resistance (Bleed/Crush/Burn, player-allocated); Mind → psychic resistance tier (app: every 10; doc: every 15 — threshold `[OPEN]`); Charm every 20 → 1 Camera Call stack.
- **Tags:** moved from hardcoded array to DB-backed collection (`name`, `effect`, `conditions`); full admin CRUD + seed script.
- **Cooldowns:** removed from the system entirely (schema and design).

### 7.3 Bugs found & fixed (audit history)
- `levelPoints` had two incompatible shapes (`{body, core}` default vs. `.pool` reads/writes) — admin grants and player spends never interacted. → unified pool.
- Skill point budget wrongly derived from `traitLevelBonus` only (ignored base + bonus); investing a level point double-granted a skill point. → formula corrected to traitTotal-based.
- Multi-stat leveling spent greedily from one trait via `findSpendTrait` — corrected to one point from each listed stat.
- Malformed DB data: `Counter-Surge` had `stats: ["physique, mind"]` as one string → treated as no requirement, leveled free.
- `adjustBonus` pool refund had no ceiling — could exceed original max.
- Double-save race: `applyUpdate` in SkillsTab fired debounced autosave AND immediate `apiFetch`.
- Earlier structural gaps addressed: no `shock` field, no `statCapBonuses`, freetext conditions (no type enforcement for automated clocks), no character-lock on exclusive skills (Full Potential/Heroic Punch), `state: Mixed` untyped blob → preference for typed Mongoose sub-schemas.

### 7.4 Remaining critical issue `[OPEN]`
- **Skill enrichment render bug:** `enrichSkills()` stores the joined template on `sk._tpl`, but the render reads fields directly off `sk` — templateId-based skills display blank. **Fix:** merge template fields directly onto the skill object, preserving instance fields via spread. Plan: regrant all existing skills via the library picker (no legacy migration needed).

---

## 8. TOOLING — Session Recorder / Achievement Pipeline `[EXECUTED]`

- **Goal:** record sessions, transcribe, and auto-suggest achievements/skill unlocks against pre-defined criteria — fully local, zero API cost.
- **Hardware:** Ben's machine — 5070 Ti GPU, 64GB RAM. Per-player clip mics (~$15 each) → multichannel USB interface (chosen over spatial/direction-based speaker recognition for accuracy and simplicity; ~$60–80 total for 4 players).
- **Stack:** WhisperX (large-v3, faster-whisper backend, GPU float16), PyAudio (per-channel capture), Ollama + Mistral 7B (criteria matching), Tkinter or simple web UI (GM notifier).
- **Pipeline:** 4 live channels → 60s rolling buffer per channel → WhisperX per-buffer (~3s on GPU) → tag lines with player name → shared session transcript → every N lines: summarize + criteria check → flag achievements/unlocks to GM screen → full transcript saved continuously. Near-real-time (~3–5s latency).
- **Config:** `players.json` (channel→player map: Mario/Filipe/Sasha/XQUEZ-T), `criteria.json` (id, type: skill_unlock|achievement, tier, natural-language prompt, player scope). Example criteria: Controlled Sweep unlock (hit 2+ mobs with a single-target attack in one Moment), Kung Fu Fighting (silver — unarmed KO), Pressure Hold unlock (grab held 3+ Moments).
- **Folder layout:** `gpt_session/{config, audio/session_DATE, transcripts, pipeline.py, criteria_checker.py, notifier.py}`.
- Diarization note: skip live diarization; per-channel mics make it unnecessary; overnight diarized transcript optional.
- **Potential next steps** `[OPEN]`: GM-facing notifier UI polish, or an audio device mapping utility.

---

## 9. CONSOLIDATED OPEN ITEMS / BACKLOG `[OPEN]`

1. **Filipe's Dissolution song** — godhood/superiority theme targeting cynical pride.
2. **XQUEZ/T tank skills** — finalize Intercept / Iron Stance / equivalents.
3. **Fantasy item coupons** — distribute Basic weapons + 1 Lesser modifier each; finalize Lesser list (replace Padded/Reinforced; decide Wrapped/Balanced/Sure-grip; cap Draining).
4. **Affliction resistance sourcing** — deliberately parked.
5. **Psychic Resistance threshold** — doc says every 15 Mind, app seeds every 10; finalize.
6. **Skill enrichment render bug** — merge `_tpl` fields onto skill object; regrant via library picker.
7. **Tutorial HP tuning** — boost body-part HP bars vs. make HP acquisition easier.
8. **Normal/Higher/Legendary/Mythic/Godly modifier lists** — only Lesser exists.
9. **Nikita in Floors 4–6** — build the continent-merge encounters (Old/War oscillation, scarf, Sasha recognition asymmetry).
10. **GDD open questions** — narrative delivery, party size cap, checkpoint density, NG+ modifiers.
11. **Video game translation debts** — deterministic Forced Actions, Narrative Token rebuild/cut, remove GM-discretion language, internalize TVTropes dependency, Lounge downtime pacing.
12. **Standalone short story** — Nikita & Sasha (inherited trauma, misread love).
13. **Session recorder** — notifier UI or audio device mapping utility.
14. **Standing active priorities** — expand/sharpen skill list, build item/equipment list (uses, damage values), improve character sheet layout. (Note: "add cooldowns" from the original brief was superseded — cooldowns were removed.)

---

## 10. DESIGN PRINCIPLES & LEARNINGS `[PRINCIPLE]`

**Campaign design:**
- Players need to struggle early to feel meaningful growth later — boss difficulty is intentional.
- Demonic nobility vs. normal demons is categorical: normal demons are fallen/comprehensible humans; nobility corrupts through existence alone (Dissolution + emotion amplification). The demonic brand grants immunity specifically to noble presence.
- Dissolution is a Mind-targeting 2-Clock death timer, distinct from Suffocation; it amplifies *an* emotion, not necessarily the victim's own.
- Historical/cultural context in narrative = atmosphere, not explanation; secondary characters need full individual personhood before contextual framing.
- Session pacing: every session completes at least one objective and introduces one new one.
- Make skipping a Moment actively dangerous — arenas shouldn't let anyone coast (bake it into boss design, not player-targeting).

**Game/adaptation design:**
- Grinding contradicts spectacle-over-safety — audience pressure must make boring play expensive (Viewer decay, expiring Directives, noise absorption).
- The engineer trap: elegant systems with no game in them; encounter design carries the fun.
- Deep systems over deep content volume for solo scope.
- Level design is the biggest challenge in a souls-inspired handcrafted world — systems are already tight enough.
- Modifier progression should gate *access* (better modifier tiers), not just add slots.
- Extraction needs friction scaled by tier so weapon identity matters.

**App/architecture:**
- Prefer typed Mongoose sub-schemas over unstructured `Mixed` blobs.
- Think architecture through collaboratively before touching code.
- Reference model (templateId + runtime enrichment) confirmed; snapshot model rejected.
- Always commit after Claude Code tasks (per CLAUDE.md).

**Workflow:**
- Iterate on design in conversation before implementation; Claude's dev-session role = auditing, bug identification, drafting precise Claude Code prompts, backlog tracking.
- Plain, immediately usable output by default; formatted documents only when explicitly requested.
- Structured multi-question polling to reach decisions efficiently.
- Claude Code (VSCode) for implementation; Claude.ai for architecture, design, creative work. Image generation: ChatGPT from plain-text panel scripts.

---

## 11. WORLDBUILDING QUICK-REFERENCE `[SYSTEM]` `[STORY]`

- Camera Call: doubles Viewership/Follower/Patron gains AND losses on a target until end of that target's current or next action.
- Boss Tokens → Patron Tokens: 3:1, one-way.
- Patron Tokens: from Goals (new Patron) or Directives; spent on skill caps.
- The Lounge is fully surveilled; upgrades increase surveillance. Loot boxes open only inside, all at once.
- The Corporation frames the show as proof colonization is "beneficial — nay, necessary."
- Refusing to join the show: "we can't guarantee what will happen to you afterwards."
- No respawns.
