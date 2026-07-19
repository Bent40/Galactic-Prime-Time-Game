# Skills R19 Generalization Ladders — FINAL (framework-applied)

**Status:** FINAL ladder SHAPES (approved-shape canonical spec) · **Date:** 2026-07-19
**Supersedes:** `docs/design/skills-passover-worksheet.md` (DRAFT, 2026-07-18) for the 6–10 shapes.
**Rule of record:** `docs/rules-addendum.md` §R19 · **Numbers:** every magnitude PLACEHOLDER pending §R14.
**Framework of record:** `docs/gdd/decision-log.md` #14 — *R19 skill framework, ALL 10 DEFAULTS ACCEPTED (owner, 2026-07-18).*

---

## Preamble — what this is and how it was derived

The owner ran the skills passover and **accepted all 10 framework defaults** (decision-log #14).
This document drives the 43 draft ladders to **FINAL** against that framework: every rung the
framework now settles is resolved in place, and only the residual per-skill questions the
framework genuinely does not settle are carried forward (there are **three**).

- **Shapes are approved; magnitudes are PLACEHOLDER (default #9 / §R14).** This spec locks *which
  new SITUATION each of rungs 6–10 unlocks*. Every number — damage, range, area, duration, tier —
  is tuned after the §R14 numbers rework and the force-vs-robustness gate. Numbers that would
  imply a magnitude are marked `[PH]`.
- **The 6–10 ground rule holds:** each of 6–10 buys a **new situation**, not a bigger number
  (numbers keep scaling underneath from 1–5). The R19 **Explosion** template is the compass
  (6 = more targets/instances · 7 = a chooseable secondary channel · 8 = decouple the effect from
  your body · 9 = loosen the requirement/range gates · 10 = the skill's capstone), tailored per
  skill, never stamped.

### The 10 accepted defaults, as applied here

1. **Passives generalize AS passives** — each rung a new always-on situation; a high rung adds an
   **active toggle only where it genuinely fits** (Swim L10 dash, Acrobatic Save L10 clutch,
   Nightlurking L10 relocation, Acrobatics L10 free-run window).
2. **The rule-transcending L10 (psychic/radiant-class) is MAGIC-ONLY and source-gated.** Only the
   10 `is_magic` skills may reach it, and only via a source-gate (cap-raise Patron Token +
   Wizard's Tower, as base magic is acquired). **Non-magic skills get a mundane L10** = the top of
   their mundane generalization. Every non-magic draft L10 that bypassed resistance/robustness was
   demoted (see notes).
3. **The R16 four-skill background trade does NOT push a starting skill into the 6+ band.** All
   6–10 rungs are **in-run progression content**; creation buys headroom (cap), never a
   pre-generalized starting ability.
4. **Chain gates stay FIXED by default**; a chain's "same target / must follow immediately" gate
   loosens **only at the specific authored rungs named below** — never automatically as a side
   effect of an opener generalizing.
5. **Consume/mutate capstones sit OUTSIDE the 6–10 ladder** (a separate axis). Elemental Confluence
   is authored as a fixed-power capstone; any growth is **Patron-Token-gated at cap-10, always**.
6. **Performance/audience skills: CHARM scales the crowd payoff, and a shared "spectacle rung"
   (a Camera-Call-tier capstone) is the STANDARD L10.** Applied to Dance, Vibe Control, Heroic
   Punch, Juggling.
7. **Locked/NPC skills use the 0–10 player ladder only if a player could ever acquire them.**
   Player-playable but character-locked skills (Heroic Punch, Full Potential) keep the full
   ladder; the genuinely NPC-exclusive transformation (Reversion) is marked **fixed / NPC-only**
   (its "levels" are per-encounter difficulty the owner authors, not a player track).
   **Player-inflicted mind-collapse is gated per R5.**
8. **No ladder introduces true HP restoration or a full cure.** HP recovery stays scarce;
   healing-adjacent rungs (Seal The Wound) **manage/delay conditions only** — never restore HP,
   never fully cure a lethal state.
9. **Shapes now, magnitudes after §R14.** Every number PLACEHOLDER.
10. **Data hygiene is fixed at IMPLEMENTATION, not here.** Each item is NOTED inline as
    `Data-hygiene (#10)` and collected in the notes section so none is lost.

Reading key for tags: **[MAGIC]** · **[PASSIVE]** · **[CHAIN: opener/link/finisher]** ·
**[spectacle L10]** (default #6) · **[NPC-only]** · **[character-locked]**.

---

# PHYSIQUE skills (14)

### #1 — Controlled Sweep · physique · 1 Moment · cap 5
**Identity.** Attack several extra adjacent Mobs as one single-target attack each; melee + 2 Mobs adjacent.
**FINAL 6–10:**
- **6 — catches Elites.** An Elite in reach can be swept (counts as the whole sweep's instances) — no longer a Mob-only tool.
- **7 — spreads the weapon's on-hit rider.** Each swept target also takes the weapon's Bleed/Crush condition `[PH]` on a random exposed limb — the whirlwind spreads conditions, not just the base hit.
- **8 — sweep a ring you're not standing in.** Originate the arc around a chosen space within reach (one step out) — hit a cluster you're beside, not only one you're inside.
- **9 — proactive/reactive.** The "2 Mobs adjacent" floor drops to 1 and it may be declared as a reaction when 2+ enemies enter your reach — an anti-swarm trap, not just an on-turn clear.
- **10 (mundane) — arena beat.** Every enemy in reach struck once and knocked back 1 space `[PH]`; a wide mundane wave-clear. **Friendly fire is ON (ruled 2026-07-17): allies in reach are caught** — part of the spectacle risk, not excluded.
**1–5 scales:** number of extra Mobs hit (3→6, L2–L4).
**Residual:** none.

### #4 — Strong Strike · physique · 2 Moment · cap 5
**Identity.** Wind up an overwhelming melee blow; +damage on hit, Exposed while performing.
**FINAL 6–10:**
- **6 — cleave-through.** On a kill or part-disable the wind-up carries into the enemy directly behind — the haymaker no longer dead-ends.
- **7 — load a stagger.** Choose a secondary rider: Crush→Shock T1, or trigger the weapon's affix, on the same part — it staggers, not only damages.
- **8 — bank & release as a reaction.** Hold the wind-up across a Moment and unleash when the target commits, so you aren't Exposed the whole time — a trap instead of a telegraph.
- **9 — threatens a space (reach/thrown).** The melee/adjacent gate loosens; the wind-up threatens a space, not just a body.
- **10 (mundane) — reliable breach.** Its force **reliably counts toward the 7+ single-hit breach threshold** `[PH]` — the designed mundane answer to Surface-Immunity bosses (Incineradile, §3.1). It runs through the §R14 force-vs-robustness gate like everything; it does **not** bypass robustness (that would be rule-transcending — forbidden to a non-magic skill, default #2).
**1–5 scales:** bonus weapon-type damage on hit; optionally shortens the Exposed window. **Data-hygiene (#10):** `effects[]` empty — L2–L4 rows unauthored; author at implementation.
**Residual:** none. *(The draft's "bypass the force gate?" question is settled NO by default #2; the exact breach-threshold interaction is an §R14 tuning detail, default #9.)*

### #5 — Counter-Surge · physique / mind · 1 Moment · cap 5
**Identity.** Strike a mid-action adjacent enemy, cutting their remaining cost; on collapse they roll Forced Action — Body.
**FINAL 6–10:**
- **6 — interrupt anything declared.** The "2+ Moment" gate widens to any declared action.
- **7 — mark on collapse.** On collapse also apply Shock T1 (the mind synergy) or the weapon's rider — interrupt + condition.
- **8 — intercept for an ally.** Counter an action targeting an adjacent ally, not only yourself (R15).
- **9 — counter casters & shooters.** Fires at Near range against visible ranged/cast wind-ups, not just melee.
- **10 (mundane) — full reversal.** The collapsed action's Moment cost is refunded to YOU as tempo (or turned back on them) `[PH]` — a clean mundane tempo swing.
**1–5 scales:** remaining-cost reduction (−1→−4, L2–L4).
**Residual:** none.

### #7 — Pressure Hold · physique / reflexes · 2 Moment · cap 5
**Identity.** Grapple a target; while held neither can reposition and both are Exposed.
**FINAL 6–10:**
- **6 — control two, or pin a limb.** Grapple two adjacent targets, or lock one limb of a single target.
- **7 — the squeeze deals.** While held, apply Suffocation or Crush-over-time to a chosen part `[PH]`. **Inherits R9: bosses and anything ≥2 sizes larger are immune to grapple-Suffocation** — a high-level hold does NOT bypass it (boss wins are discovered, not choked; also forbidden as rule-transcendence, default #2).
- **8 — hand off / throw.** Pass the grappled target to an assisting ally (R15), or hurl them into another for Crush.
- **9 — hold above your weight class.** The Physique gate loosens; initiate on Elite-scale targets the base couldn't hold (still bounded by R9's size cap for Suffocation).
- **10 (mundane) — body-slam finisher.** End the hold for Crush to Head/Torso + knock Prone (Exposed); a Cinematic-Kill candidate `[PH]`.
**1–5 scales:** drag-while-holding distance (L2–L4) and hold strength.
**Residual:** none. *(R9 boss/size immunity settles the draft's "does L7 bypass?" — it does not.)*

### #8 — Brace · physique · 0 Moment · cap 5
**Identity.** React to reduce incoming Crush/Burn; the tank identity's home.
**FINAL 6–10:**
- **6 — universal guard.** Brace against all damage types (add Bleed and the incoming condition tier), not just Crush/Burn — one flinch covers the whole hit.
- **7 — guard with a payoff.** Reflect 1 to a melee attacker `[PH]`, or convert prevented damage into a hype tick (spectacle tank).
- **8 — INTERCEPT (merged-in).** Brace on behalf of an adjacent ally — take/reduce a hit aimed at them. This rung is the **separate `Intercept` skill folding into Brace** (see R1).
- **9 — IRON STANCE (merged-in).** A standing brace-aura: until you move, reduced-type hits against you and adjacent allies are reduced. This rung is the **separate `Iron Stance` skill folding into Brace** (see R1).
- **10 (mundane) — immovable object.** Negate one incoming hit entirely, once per Clock `[PH]` — a perfect mundane guard (no radiant/psychic transcendence).
**1–5 scales:** flat reduction (−1→−4, L2–L4).
**R1 RULED (owner 2026-07-18):** **Intercept and Iron Stance are SEPARATE lower-tier skills** on their own, with an **upgrade/merge path that folds them into Brace's high rungs** (own Brace + Intercept + Iron Stance → consolidate). Author all three; the L8/L9 above are the merged forms, not Brace-native rungs.

### #20 — Pounce · physique · 2 Moment · cap 5 · [CHAIN: opener]
**Identity.** Leap up to 3 spaces, slash the torso for Bleed; opens into Slip Through. Sasha's opener.
**FINAL 6–10:**
- **6 — hits a pair.** The landing strike may split across two adjacent bodies, or catch a second enemy in the landing space. **Chain gate stays fixed (default #4):** when chaining into Slip Through, the chain follows the **primary struck target** — this rung does NOT loosen Slip Through's same-target requirement.
- **7 — pin instead of cut.** Convert the torso Bleed into a light grapple/Exposed (claws hooked). Chain still follows the primary target.
- **8 — aerial ambush.** Pounce off a wall or an ally boost (R15) for a vertical origin — dive onto Head-legal Exposed targets.
- **9 — pounce from bad ground.** Ignores difficult terrain/gaps, extends range, can open from cover/stealth.
- **10 (mundane) — combo enabler.** A landing that auto-Exposes the target and discounts the Pounce→Slip→Decapitate chain `[PH]`.
**1–5 scales:** Bleed and leap distance (L2–L4).
**Residual:** none. *(Default #4 settles the draft's "do L6/L7 break the same-target chain?" — they do not.)*

> **#21 Slip Through** is the reflexes-primary link between Pounce and Decapitate — its full ladder is in the **REFLEXES** section (grouped by primary stat, per the worksheet).

### #22 — Decapitate · physique / reflexes · 3 Moment · cap 5 · [CHAIN: finisher]
**Identity.** Slash the Head from behind for Bleed; Head to 0 = Cinematic Kill + Viewer spike.
**FINAL 6–10:**
- **6 — momentum carries.** A head-kill grants a free reposition or a second Cinematic-Kill attempt on an adjacent Exposed Mob `[PH]`.
- **7 — pick the kill.** Choose Crush (behead-by-force) vs Bleed to match weapon; witnesses take Shock (morale).
- **8 — ranged execution.** Executable from a thrown claw/blade at 1–2 spaces; no longer requires melee-behind.
- **9 — AUTHORED chain-release (default #4).** Fires off **any** Exposed/Helpless/Overwhelmed opening, not only Slip Through's. *Below L9 the chain stays fixed: must follow Slip Through, positioned behind, target Exposed.*
- **10 (mundane) — highlight-reel kill.** Behead any lethal part of a **non-boss** Exposed target for a max Viewer spike `[PH]` — mundane lethality (the Cinematic-Kill fantasy), not an HP-bypass.
**1–5 scales:** Head Bleed damage (L2–L4).
**Residual:** none.

### #23 — Overhead Slam · physique · 2 Moment · cap 5 · [CHAIN: opener]
**Identity.** Heavy Crush to a part; standing targets knocked Prone; opens into Shockwave.
**FINAL 6–10:**
- **6 — cracks the ground.** Impact splashes 1 Crush to a second adjacent target.
- **7 — bury & pin.** Apply Pin/Exposed (them or their weapon-arm) instead of pure damage.
- **8 — leaping slam.** Close 1–2 spaces into the slam (absorbs movement) — opens from range. *(Positioning gate; chain sequence unchanged.)*
- **9 — any heavy object.** Works with improvised heavy objects, not just equipped Large weapons; bonus vs Prone.
- **10 (mundane) — fault-line.** Guarantees the Shockwave chain; knockback becomes a wide stagger `[PH]`.
**1–5 scales:** Crush damage (L2–L4).
**Residual:** none.

### #24 — Shockwave · physique · 2 Moment · cap 5 · [CHAIN: link]
**Identity.** 3-space cone Crush + knockback; Mobs roll Forced Action — Body; must follow Overhead Slam.
**FINAL 6–10:**
- **6 — full ring.** The cone becomes 360° — the surrounded-answer.
- **7 — reshapes the field.** Leave difficult terrain/rubble, or apply Chill/Burn if standing on such a surface.
- **8 — remote tremor.** Send the wave from a chosen point within reach. *(Origin decouples; still follows the Slam in sequence — chain gate fixed, default #4.)*
- **9 — control up the ladder.** Forced Action lands on Elites, not only Mobs; knockback into walls/hazards adds collision Crush.
- **10 (mundane) — earthquake.** Knocks the whole cone Prone (Exposed) and sets up Execution on all of them `[PH]`.
**1–5 scales:** Crush and knockback distance (L2–L4).
**Residual:** none.

### #25 — Execution · physique · 3 Moment · cap 5 · [CHAIN: finisher]
**Identity.** Heavy Crush to Head/Torso of a Prone/Helpless target; Torso→Shock T3, Head→instant death; must follow Shockwave.
**FINAL 6–10:**
- **6 — double finisher.** Execute two downed adjacent targets at once.
- **7 — kill that shapes the room.** On-kill payload: a fear wave (Shock/morale) or a hype spike.
- **8 — ranged coup de grâce.** Executable at reach (spear/thrown) on a Prone target 1–2 spaces away.
- **9 — broader kill windows.** May execute the Exhausted/Grappled/Overwhelmed, not only Prone/Helpless. *(Loosens the downed-STATE requirement only; **"must follow Shockwave" stays fixed** — the finisher remains chain-locked, default #4.)*
- **10 (mundane, DEMOTED per #2) — unstoppable.** Cannot be interrupted once declared `[PH]`. **The draft's "ignores robustness on a non-boss" is REMOVED** — bypassing robustness is rule-transcending and forbidden to a non-magic skill.
**1–5 scales:** Crush damage (+2/+4/+6, L2–L4).
**Residual:** none.

### #30 — Swim · physique · 0 Moment · cap 5 · [PASSIVE]
**Identity.** +swim movement; extends the Suffocation grace timer; applies automatically in water.
**FINAL 6–10 (generalizes environments AS a passive; L10 adds an active toggle, default #1):**
- **6 — submerged combat.** No penalty to actions/attacks underwater — at home where others flounder.
- **7 — drown your prey.** Drag/grapple a target underwater and impose Suffocation while you stay immune (bounded by R9's grapple-Suffocation size/boss cap).
- **8 — generalize "water".** The affinity extends to any low-buoyancy medium — flooded rooms, mud, fluid hazards, low-G.
- **9 — tow an ally.** Grant the movement/breath bonus to an adjacent towed ally (rescue-swim); near-total Suffocation immunity.
- **10 (mundane, passive + active toggle) — amphibious apex.** Effectively unlimited breath (passive) plus a declared in-water burst dash usable as a Pounce-equivalent (the toggle) `[PH]`.
**1–5 scales:** swim movement (+1/L2–L4) and the Suffocation grace window.
**Residual:** none. *(Compendium's "racial" is settled by R16: background-offer bias toward animals, **not** an animal hard-lock — any contestant granted it can raise it.)*

### #39 — Heroic Punch · physique · 1 Moment · cap 5 · [character-locked: Mario] · [spectacle L10]
**Identity.** Committed unarmed Crush; Head-on-Exposed adds Shock; L6 (data) adds a Bleed channel + POW graphic + Viewer spike.
**FINAL 6–10:**
- **6 — `[data L6]` it becomes a signature.** Gains a Bleed channel `[PH]` and its first true spectacle payload — POW graphic + Viewer spike on Head hits.
- **7 — pick the rider.** Shock (rattle) vs knockback (send them into a wall/ally for collision Crush).
- **8 — Superhero Landing.** A dash-punch closing 1–2 spaces; can strike airborne/elevated targets.
- **9 — the knockout.** May target the Head without Exposure on Mobs; works while carrying/one-handed.
- **10 — SPECTACLE CAPSTONE (default #6).** On a downed/Exposed target, a **Camera-Call-tier Cinematic Kill** — the "nobody becomes somebody" money shot; **CHARM scales the crowd payoff** `[PH]`.
**1–5 scales:** Crush (+1/+2/+3, L2–L4).
**Residual:** none. *(Default #7: a player controlling Mario raises the full 0–10 ladder — character-locked availability, not NPC-only. Content lock pending the `exclusive_to` field, per R12.)*

### #43 — Slice n' Dice · physique · 2 Moment · cap 5
**Identity.** Rapid crossing claw/blade arc for multi-limb Bleed; L6 (data) advances Bleed on already-Bleeding parts. Sasha's.
**FINAL 6–10:**
- **6 — `[data L6]` bleed-stacker.** Landing on already-Bleeding parts advances each +1 tier — condition-stacking becomes the identity.
- **7 — cross-apply.** Add the weapon's affix condition, or split one strike into a Shock-inducing slash to an Exposed Head.
- **8 — widen the arc.** Three targets or a 180° wrap — a crowd-clearer.
- **9 — flexible flurry.** Usable with any paired light implements (improvised); reposition between strikes.
- **10 (mundane) — "cleaning this is a bother."** Guaranteed multi-part Bleed T2 on a single Exposed target — a bleed-to-death setup + Viewer spike `[PH]`.
**1–5 scales:** Bleed on torso/limbs (L2–L4).
**Residual:** none.

### #45 — Reversion · physique · 2 Moment · cap 5 · [NPC-only — exclusive: Nikita]
**Identity.** Full body-and-mind reversion to WAR NIKITA (owner 2026-07-17); prime is "the song"; ends → Old Nikita + Exhausted T2.
**Disposition (default #7): NPC-only — NOT a player 0–10 ladder.** Reversion is an authored boss/recruited-NPC
transformation (R16: NPC stats fit the character). It does not use the player track; its "levels" are
**per-encounter escalation the owner authors per appearance**. The five escalation tiers below are
**encounter-difficulty beats**, not player-purchasable rungs:
- **E1 — he won't stay down.** Reversion holds beyond 1 Clock / re-triggers mid-fight.
- **E2 — War Nikita's signature.** Gains a war action (suppressing fire / bayonet rush) Old Nikita lacks.
- **E3 — the song is a weapon.** The prime itself becomes a field effect — all who hear it are touched (morale).
- **E4 — the tragedy tightens.** Triggers on more stimuli (any lethal damage, pattern-match, Sasha's presence).
- **E5 — full reversion.** Truly young again, body and mind, statline at peak — the boss apex; resolving him means reaching **Old**, never out-damaging War `[PH]`.
**Data-hygiene (#10):** `range` field empty, `[numbers PLACEHOLDER R14]`, no `unlock_requirements` — expected for NPC-only; wire per the encounter, not the player-skill schema.
**Residual:** none. *(Default #7 settles the draft's "player ladder or per-encounter difficulty?" — per-encounter, NPC-only.)*

---

# REFLEXES skills (12)

### #2 — Quick Step · reflexes · 0 Moment · cap 5
**Identity.** Ignore difficult-terrain movement penalty for the Moment.
**FINAL 6–10:**
- **6 — shrug movement debuffs.** Ignore movement-impairing conditions briefly (Chilled leg, light Exhausted drag) for the step, not just terrain.
- **7 — clear the path.** The step leaves a cleared trail an ally can follow at no penalty (R15).
- **8 — evasive reposition.** Usable as a reaction to being targeted (a mini-dodge), not only proactively.
- **9 — run through hazards.** Ignore hazard terrain (fire-wall edge, poison floor, ice) for the pass; cross gaps.
- **10 (mundane) — flow state.** For one Moment, movement costs 0 regardless of distance and can't be reacted to `[PH]`.
**1–5 scales:** duration of the ignore-terrain effect (L2–L4).
**Residual:** none.

### #9 — Tactical Roll · reflexes · 0 Moment · cap 5
**Identity.** On being attacked, immediately move 1 space. "Bullet time."
**FINAL 6–10:**
- **6 — dodge more than melee.** Dodge any incoming effect you can perceive (ranged shot, AoE edge), not only direct attacks.
- **7 — dodge into offense.** End counter-ready — your next attack this Clock gains position/Exposed-from-behind on the dodged enemy.
- **8 — shove-save an ally.** Roll an adjacent ally out of the way instead of yourself.
- **9 — dodge from bad states.** Works while Prone or with a leg disabled; escape AoE zones wholesale.
- **10 (mundane) — bullet time.** Dodge every attack targeting you this tick `[PH]` — mundane, matches the flavor.
**1–5 scales:** dodge distance. **Data-hygiene (#10):** legacy "Cooldown: 1 Clock" + L3/L4 "−2 Moment cooldown" contradict §R3 (no cooldowns). Re-express as a **prime** (once-per-Clock or a prep-gate) at implementation — do not carry the cooldown text forward.
**Residual:** none.

### #21 — Slip Through · reflexes · 2 Moment · cap 5 · [CHAIN: link]
**Identity.** Dash between a struck creature's legs for leg-Bleed, reposition behind, target Exposed; must follow Pounce; target must be larger.
**FINAL 6–10:**
- **6 — same-size targets.** The size gate loosens; usable against Mobs, not only larger creatures. *(Targeting gate, not the chain sequence.)*
- **7 — hamstring on the way through.** Apply Crush/Chill to a leg to slow, or trip to Prone.
- **8 — slip through anything.** Traverse a gap/obstacle/ally line, not only under a creature.
- **9 — AUTHORED chain-release (default #4).** May initiate **standalone from any adjacency without a preceding Pounce**; reposition further. *Below L9 the chain stays fixed: must follow Pounce on the same target.*
- **10 (mundane) — untouchable.** Pass through a whole cluster, Exposing each, ending anywhere behind the line, uninterruptible `[PH]`.
**1–5 scales:** per-leg Bleed (L2–L4).
**Residual:** none.

### #26 — Feint · reflexes / charm · 1 Moment · cap 5 · [CHAIN: opener]
**Identity.** Force the target's next action into Forced Action — Tool; reposition; no damage; opens into Pressure Strike.
**FINAL 6–10:**
- **6 — sell it wide.** Feint two adjacent targets at once.
- **7 — pick the fumble.** Choose Forced Action Tool (fumble) vs Body (stumble/Exposed).
- **8 — ranged bait.** Feint at Near range via a shout/gesture (charm-driven), not only adjacent. *(Positioning; chain sequence unchanged.)*
- **9 — bait more states.** Works on targets mid-action (bait an interrupt) and on the wary (Mind-resistance loosens).
- **10 (mundane) — total misdirection.** Spoof the target's whole next-Clock plan (they act as if you're where you aren't) `[PH]`.
**1–5 scales:** reposition distance and Forced-Action die manipulation (L2–L4).
**Residual:** none.

### #27 — Pressure Strike · reflexes / physique · 2 Moment · cap 5 · [CHAIN: link]
**Identity.** Strike an exposed limb for Bleed, reposition; if the target still suffers Feint's Forced Action, add Shock; must follow Feint.
**FINAL 6–10:**
- **6 — hit two.** Strike two limbs, or two targets caught by the same Feint.
- **7 — pick the payload.** Convert Bleed into a Crush/disable on a chosen limb, or add Shock unconditionally.
- **8 — AUTHORED chain-release (default #4).** Fires off **any** Forced-Action/opening — **an ally's Feint counts (R15)**, an enemy's Forced Action from another source counts — not only your own Feint. *Below L8 the chain stays fixed: must follow your own Feint.*
- **9 — reach & non-Exposed.** Fires at reach and against non-Exposed limbs at reduced effect.
- **10 (mundane) — tempo swing.** Refunds a Moment and keeps the chain open into Thousand Cuts for free `[PH]`.
**1–5 scales:** Bleed and reposition distance (L2–L4).
**Residual:** none.

### #28 — Thousand Cuts · reflexes · 3 Moment · cap 5 · [CHAIN: finisher]
**Identity.** Choose 3 body parts, 1 Bleed each; all-3-on-Bleeding advances each tier; must follow Pressure Strike.
**FINAL 6–10:**
- **6 — five cuts / two targets.** Widen the flurry to more parts or across two targets.
- **7 — venom coat.** A poison rider so the many small wounds become entry conditions for Poison.
- **8 — cut-storm at range.** A thrown fan of blades at Near, or executable off a Slip-Through reposition.
- **9 — AUTHORED chain-release (default #4).** Usable **standalone without the Feint→Pressure Strike chain**; may include Exposed Head parts among the three. *Below L9 the chain stays fixed: must follow Pressure Strike.*
- **10 (mundane) — death by a thousand cuts.** Guarantees at least T2 Bleed on every struck part — an unignorable bleed-out clock + Viewer spike `[PH]`.
**1–5 scales:** **Data-hygiene (#10):** `effects[]` empty — the 1–5 scaling is unauthored (cut count? Bleed/cut? reposition?). Author at implementation.
**Residual:** none. *(The draft's "what scales 1–5?" is an authoring/data item, not a design residual — default #10.)*

### #32 — Juggling · reflexes · 0 Moment · cap 5 · [spectacle L10]
**Identity.** Pass/catch any item within range in 0 Moments (absorbed into an action); can disarm.
**FINAL 6–10:**
- **6 — mass item-flow.** Juggle multiple items / pass to multiple allies in one action (redistribute the party's kit).
- **7 — weaponize the throw.** A passed heavy/sharp item deals its damage in flight; a caught enemy weapon is instantly usable.
- **8 — intercept mid-air.** Catch-and-return a projectile or thrown item in flight.
- **9 — disarm up the ladder.** Disarm larger/braced grips the base can't; catch across obstacles.
- **10 — SPECTACLE CAPSTONE (default #6).** Keep several items in continuous flow — feeding allies and pelting enemies each Moment — a **Camera-Call-tier juggling act**; **CHARM scales the crowd payoff** `[PH]`.
**1–5 scales:** range of the pass/catch (L2–L4).
**Residual:** none.

### #33 — Dance · reflexes · 0 Moment · cap 5 · [spectacle L10]
**Identity.** While Dancing, movement generates +1 Charm effect (crowd/social/Charm-gated skills); ends on hit/Prone/attack.
**FINAL 6–10 (spectacle/support that generalizes outward):**
- **6 — buff the troupe.** The dance lifts adjacent allies' Charm/hype too.
- **7 — choose the beat.** Taunt (draw camera/aggro, Vibe-Control-like) or Inspire (an ally gets a die/tempo).
- **8 — dance and fight.** The effect persists a beat after you stop or attack, instead of cancelling instantly.
- **9 — robust under pressure.** Can dance while Grappled/Prone (defiant performance); resists cancel from a single hit.
- **10 — SPECTACLE CAPSTONE (default #6).** A **Camera-Call-tier crowd moment** — mass hype spike, enemies distracted, patrons bid `[PH]`.
**1–5 scales:** the Charm bonus while dancing (+1/L2–L4).
**Residual:** none. *(Default #6 settles the Reflexes-vs-Charm question: **Reflexes gates the dance's execution/robustness; CHARM scales the crowd payoff.**)*

### #37 — Acrobatic Save · reflexes · 0 Moment · cap 5 · [PASSIVE]
**Identity.** On a Forced Action — Body, roll +1 die and choose the result. "Not even close, baby!"
**FINAL 6–10 (passive generalizes; L10 adds an active toggle, default #1):**
- **6 — any fumble.** Applies to Forced Action Tool as well as Body.
- **7 — the save is spectacle.** A saved Forced Action becomes a stylish reposition / Viewer spike.
- **8 — catch an ally.** Spend the save for an adjacent ally's Forced Action (R15).
- **9 — never say die.** Works while Prone/Helpless (the base forbids it).
- **10 (mundane, passive + active toggle) — clutch save.** Once per encounter, **declare** an auto-pass on a Forced Action that would end the fight `[PH]` — a skill-based clutch (matches the unlock "survive a consequence that should have ended the fight"), not a rule-transcending effect.
**1–5 scales:** number of extra dice you choose from (L2–L4). **Data-hygiene (#10):** legacy "Cooldown: 1 Clock" contradicts §R3 — re-express as a prime / once-per-Clock (once-per-encounter for L10) at implementation.
**Residual:** none.

### #41 — Lockpicking · reflexes · 2 Moment · cap 5
**Identity.** Simple locks auto-succeed; Forced Action — Tool on failure; 2 Moments per attempt.
**FINAL 6–10:**
- **6 — top of the scale.** Pick Complex/Advanced locks the L2–L4 (Moderate) tier can't touch.
- **7 — trap interaction.** Read/disarm trapped locks (the fumble becomes a defuse), or jam a lock behind you.
- **8 — no kit needed.** Pick with improvised/bare tools (bump/shim); reach slightly into a mechanism.
- **9 — under pressure.** Pick while moving / under fire without the interrupt Forced Action; open magical/keycard analogues.
- **10 (mundane) — master key.** Any non-narrative mechanism opens in 0 Moments, silently `[PH]`.
**1–5 scales:** speed (−Moment) and lock complexity reached (Simple→Moderate, L2–L4).
**Residual:** none.

### #42 — Acrobatics · reflexes · 0 Moment · cap 5 · [PASSIVE]
**Identity.** Rough terrain doesn't slow you; +jump/climb; balancing never forces; L6 (data) full 3D traversal.
**FINAL 6–10 (passive generalizes to all axes; L10 adds a declared window, default #1):**
- **6 — `[data L6]` full 3D traversal.** Change direction mid-leap; vertical movement costs the same as horizontal.
- **7 — enemies as terrain.** Acrobatic movement passes through enemy spaces (vault over/off), optionally Exposing them.
- **8 — any surface.** Wall-run / ceiling-cling for a Moment; origin decouples from the floor.
- **9 — stays upright.** Near-immune to knockback/Prone/trip; ignores fall damage within reason.
- **10 (mundane, passive + declared window) — free-runner.** Declare a Clock in which no terrain, gap, height, or hazard impedes movement at all `[PH]`.
**1–5 scales:** acrobatic movement and safe-fall distance (L2–L4).
**Residual:** none.

### #44 — Camouflage · reflexes / mind · 3 Moment · cap 5
**Identity.** Conceal the player (revealed only within ~6 spaces); breaks on movement.
**FINAL 6–10:**
- **6 — mobile stealth.** Move slowly and stay hidden — breaks only on fast movement/attack.
- **7 — stealth into strike.** A strike from camouflage gains an ambush rider (Exposed/Overwhelmed → Head-legal, bonus damage).
- **8 — hide the team / decoy.** Conceal an adjacent ally, or plant an afterimage/decoy where you were.
- **9 — hide anywhere.** Hold camouflage without matching cover (adaptive camo); resist non-visual detection.
- **10 (mundane) — ghost.** Effectively invisible until you act, even at adjacency, once per scene `[PH]` — mundane stealth, no radiant/psychic tier.
**1–5 scales:** the reveal distance downward (harder to spot; L2–L4). **Data-hygiene (#10):** base effect/unlock text is garbled ("Have an Not spot you"); confirm the intended base rule (line-of-sight break? spot roll?) at implementation.
**Residual:** none.

---

# MIND skills (15)

### #3 — Seal The Wound · mind · 1 Moment · cap 5
**Identity.** Delay Bleeding OR Infection for 1 Clock; cannot resolve fully. Filipe's condition-manager.
**FINAL 6–10 (default #8 — condition management/delay ONLY; never HP, never a full cure):**
- **6 — broader triage.** Delay any bleeding-family condition, including Crush-bleed and Poison entry.
- **7 — arrest, don't cure.** Hold a condition **frozen (no advancement) for a duration** rather than only delaying its next tick — deeper *management*, still not a cure and never HP.
- **8 — ranged triage.** Treat an ally at Near range (thrown salve / shouted guidance), not only self/adjacent.
- **9 — field medic.** Manage multiple conditions on one target, or one condition on two adjacent allies, in a cast.
- **10 (mundane) — stabilize the dying.** **Delay** the lethal condition on a downed ally for a full Clock — per R5 this returns them **0-HP-stabilized** (alive, not dying this Clock). **No HP is restored; the lethal state is held, not cured** (default #8).
**1–5 scales:** delay duration (+Clocks, L2–L4).
**Residual:** none. *(Default #8 settles the healing-scarcity question: no skill introduces HP restoration or a full cure; Seal The Wound stays strictly condition-delay/management. The draft's "resolve one tier" cure rung is REMOVED.)*

### #6 — Read The Pattern · mind · 1 Moment · cap 5
**Identity.** Learn one visible enemy's next scheduled action until the Clock reset (within 3 spaces).
**FINAL 6–10:**
- **6 — read the room.** Read two enemies, or a Mob pack's shared intent, at once.
- **7 — read becomes a team buff.** Share the read: allies you tell gain position/first-strike vs the revealed action (R15).
- **8 — remote read.** Read a target out of line of sight (through walls, by pattern) beyond the 3-space gate.
- **9 — read boss tells.** Reveal a boss's discoverable **win-condition telegraphs**, not just scheduled actions — the anti-damage-race tool.
- **10 (mundane) — precognition.** See the enemy's full next Clock and pre-empt one action with a guaranteed interrupt window `[PH]`.
**1–5 scales:** how many upcoming actions you foresee (+1/+2/+3, L2–L4).
**Residual:** none. *(Note for boss design: L9 boss-tell read must stay consistent with authored boss win-conditions — a cross-reference flag, not a blocking question.)*

### #10 — Poison Ball · mind · 2 Moment · cap 5 · [MAGIC]
**Identity.** AoE Tier-1 Poison on impact; requires an entry condition per target. Range 20. The Explosion template's poison sibling.
**FINAL 6–10 (Explosion template onto poison):**
- **6 — cluster.** Splits into 2–3 bomblets across separate spaces.
- **7 — pick the toxin.** Choose Neuro/Hemo/Myo/Pneumo/Cyto at cast to match the target's weakness.
- **8 — remote/deferred origin.** Originate from a chosen point, or lob a delayed mine — not from your hand.
- **9 — supplies its own entry condition.** No longer needs a pre-existing wound to activate — works on the unwounded.
- **10 — RULE-TRANSCENDING (magic-only, source-gated · default #2).** A **radiant-tier / Cytotoxic bloom that bypasses standard resistance tiers** `[PH]`. Reached only via a cap-raise Patron Token + Wizard's Tower.
**1–5 scales:** blast radius and range (L2–L4).
**Residual:** none. *(Note: L9 entry-condition removal is a strong balance lever — flag for the §R14 pass.)*

### #11 — Poison Wall · mind · 2 Moment · cap 5 · [MAGIC]
**Identity.** Toxic-vapor wall; passing/starting inside = Tier-1 Poison; persists 1 Clock. Req Poison Ball Lv 3.
**FINAL 6–10:**
- **6 — shape control.** Two segments or an enclosing box (trap someone in).
- **7 — pick & propagate.** Choose the toxin (as Poison Ball L7) and add spread so contact seeds Poison to adjacent parts.
- **8 — dynamic placement.** Place anywhere in range, delay its rise, or make it drift forward each Clock.
- **9 — durable, selective.** Persists longer, applies without entry conditions, and can be made ally-safe.
- **10 — RULE-TRANSCENDING (magic-only, source-gated · #2).** A **radiant/psychic-class toxic storm** that merges with other clouds and advances Poison tiers each Clock inside, bypassing standard resistance `[PH]`.
**1–5 scales:** wall length/area (L2–L4).
**Residual:** none.

### #12 — Frost Ball · mind · 2 Moment · cap 5 · [MAGIC]
**Identity.** AoE Chilled T1 + Chill damage (2-space radius). Range 20.
**FINAL 6–10:**
- **6 — cluster.** Shatters into secondary frost shards hitting nearby parts/targets.
- **7 — pick a control rider.** Slow, Brittle (next Crush +damage), or Chill a specific limb to disable.
- **8 — freeze the field.** Freeze a surface/space into slick/difficult terrain, not just bodies.
- **9 — sticky control.** Chill advances toward disable faster and resists the self-clear; hits Burn-immune enemies for tempo.
- **10 — RULE-TRANSCENDING (magic-only, source-gated · #2).** **Absolute-zero flash-freeze** — freeze a target solid for a Clock, or Chill T2/T3 to a part, **bypassing standard resistance tiers** `[PH]`.
**1–5 scales:** Chill damage and area (L2–L4).
**Residual:** none.

### #13 — Frost Wall · mind · 2 Moment · cap 5 · [MAGIC]
**Identity.** Solid-ice barrier; blocks movement/projectiles; wall HP; Burn deals double.
**FINAL 6–10:**
- **6 — fort up.** Raise two walls or an enclosure.
- **7 — the wall bites.** Colliders take Chill T2 or shards; a spiked variant deals Bleed.
- **8 — offensive placement.** Place at range, raise it under a target to launch/trap them, shape to terrain.
- **9 — hardened & selective.** Resists Burn (removes the ×2 weakness), lasts longer, allies pass through.
- **10 — RULE-TRANSCENDING (magic-only, source-gated · #2).** A **glacier** — large, moving, near-indestructible, pushing enemies as a mobile siege piece, ignoring the Burn weakness entirely `[PH]`.
**1–5 scales:** wall HP/durability (L2–L4). **Data-hygiene (#10):** effect text garbled ("Burn damage destroys deals twice as much") and length mismatch (target says 5, text says 6 spaces); clean at implementation.
**Residual:** none.

### #14 — Fire Ball · mind · 2 Moment · cap 5 · [MAGIC]
**Identity.** Blazing projectile, AoE Burn + Burn T1, ignites flammables. Range 20. (R19's "Explosion" was an ILLUSTRATIVE example only — no such skill exists; this ladder is Fire Ball's own fire-native generalization.)
**FINAL 6–10 (fire-native generalization):**
- **6 — cluster.** Splits into multiple detonations across the radius (owner's L6).
- **7 — sub-damage of a chosen type.** Add a chosen secondary channel — shrapnel Bleed or chemical burn — under the Burn (owner's L7).
- **8 — originate away from the caster.** A delayed rune, an arc lobbed over cover, a proxied detonation (owner's L8).
- **9 — enhance activation range & conditions.** Longer throw, detonate-on-command, ignite even non-flammable targets (owner's L9).
- **10 — RULE-TRANSCENDING (magic-only, source-gated · #2, owner's L10).** **Radiant/psychic-class fire that bypasses fire-resistance and standard tiers** `[PH]`.
**1–5 scales:** Burn damage and radius (L2–L4).
**R2 RULED (owner 2026-07-18):** R19's "Explosion" was a **made-up illustrative example, not a concrete skill** — there is no Explosion skill. Fire Ball's ladder above stands on its own; the R19 example is just teaching scaffolding.

### #15 — Fire Wall · mind · 3 Moment · cap 5 · [MAGIC]
**Identity.** Curtain of fire; passing = Burn T1, starting inside = Burn T2; can't be destroyed, only outlasted; 1 Clock.
**FINAL 6–10:**
- **6 — shape control.** Enclose or split the curtain (ring of fire).
- **7 — pick a field rider.** Smoke (blocks sight), Ember (spreads to flammables), or Scorch (burning terrain left behind).
- **8 — mobile denial.** Place at range, or make it advance each Clock (a wildfire that herds).
- **9 — durable & selective.** Burns longer, ignites the immune, can be made ally-safe.
- **10 — RULE-TRANSCENDING (magic-only, source-gated · #2).** **Radiant-fire inferno** — merges with fire sources and advances Burn tiers each Clock inside, bypassing fire-resistance `[PH]`.
**1–5 scales:** wall length/area (L2–L4).
**Residual:** none.

### #16 — Elemental Confluence · mind · 3 Moment · cap 5 · [MAGIC · CONSUME-capstone]
**Identity.** Zone of shifting elemental chaos (2 Clocks); pick Toxic Surge / Deep Freeze / Immolation each Clock. Consumes Poison/Frost/Fire Ball Lv 5 on unlock.
**Disposition (default #5): OFF-LADDER.** Confluence is a **consume/mutate capstone on a separate axis**, not a
6–10 generalization track. It is authored at a **fixed power on unlock** (the three-mode zone). Any further
growth is **Patron-Token-gated at cap-10, always** (§2.4) — there is no earned 6–9 band. If the owner wants
post-unlock growth, it is authored as discrete Patron-Token cap-raises (e.g. *layered chaos* — two modes per
Clock; *a fourth mode* — Storm/hybrid; *steerable zone*; *friend-safe*; *cataclysm* — all modes at once), each
a **separate purchased tier**, not a level-up rung.
**1–5 scales:** zone radius and range (L2–L4).
**Residual:** none. *(Default #5 settles the draft's "does it reach cap 10 via Patron Tokens or authored fixed?" — authored fixed on unlock; cap-10 always Patron-Token-gated, off the 6–10 ladder.)*

### #17 — Telekinesis · mind · 1 Moment · cap 5 · [MAGIC]
**Identity.** Mentally grip/move one target; Exposed and rooted while sustaining; L6 (data) move 1 space/Moment while sustaining.
**FINAL 6–10:**
- **6 — `[data L6]` mobility while channeling.** Move 1 space/Moment while sustaining — the grip stops rooting you.
- **7 — crush & hurl.** Constrict a held target (Crush over time), or hurl held objects as weapons for their damage.
- **8 — many hands.** Grip multiple objects/targets, or a target just out of line of sight.
- **9 — lift heavier.** Grip the heavy/braced/larger the Mind gate forbade; hold creatures that would resist.
- **10 — RULE-TRANSCENDING (magic-only, source-gated · #2).** **Telekinetic storm** — levitate and hurl the battlefield's loose mass, or **pin a boss for a breach window, overriding physical robustness by psychic force** `[PH]`.
**1–5 scales:** range (+3/+6/+9, L2–L4).
**Residual:** none.

### #18 — Telepathy · mind / charm · 0 Moment · cap 5 · [MAGIC]
**Identity.** Silent mental link; read surface thoughts (Mind 4+ notice); L6 (data) implant a thought/image believed self-originated (below Mind 4).
**FINAL 6–10:**
- **6 — `[data L6]` read → write.** Implant a single thought/image per Clock, believed self-originated (below Mind 4).
- **7 — influence action.** Implant a compulsion/hesitation with mechanical bite (a soft Forced Action), or feed a false Read-the-Pattern to an ally.
- **8 — network.** Link multiple minds / a party channel, or reach a target you can't see.
- **9 — pierce the strong-willed.** Affects Mind 4+ targets (overcome the notice threshold).
- **10 — RULE-TRANSCENDING (magic-only, source-gated · #2) — domination-lite.** A lasting suggestion that shapes a target's next Clock, verging on the Dissolution / **mind-collapse** line `[PH]`. **Player-inflicted mind-collapse is gated per R5** (permanent removal + puppet asset; **non-boss only**; source-gated). See Residual R3.
**1–5 scales:** **Data-hygiene (#10):** `effects[]` empty — 1–5 scaling unauthored (range? number of thoughts? fidelity?). Author at implementation.
**R3 (Telepathy) — OPEN, owner leaning cut/repurpose (2026-07-18):** the owner questions whether Telepathy fits the game at all, because the **player CHAT function already covers mind-to-mind communication** — telepathy-as-comms is redundant. OPTIONS: **(a) CUT** it; **(b) REPURPOSE** away from player-comms toward what chat can't do — reading an **enemy/NPC's hidden intent** (a recon read of a boss's next move / win-condition) or offensive mind-intrusion. *Recommend (b).* DEPENDENCY: Mind Burst's "Req Telepathy Lv 3" prereq must be re-anchored if Telepathy is cut. Awaiting owner call.

### #19 — Mind Burst · mind · 2 Moment · cap 5 · [MAGIC]
**Identity.** Flood a mind with psychic noise → Shock T2 (action fails); escalates if already Shocked; may target the Head regardless of Exposure. Req Telepathy Lv 3.
**FINAL 6–10:**
- **6 — cluster.** Burst two minds, or a small cluster (psychic AoE).
- **7 — pick the payload.** Shock vs seeding Dissolution (a mental-suffocation tick, per R5 gravity) vs confusion.
- **8 — remote stun.** Fire out of line of sight or down an implanted Telepathy link.
- **9 — overcome resistance.** Beats psychic-resistance/Mind gates the base can't.
- **10 — RULE-TRANSCENDING (magic-only, source-gated · #2) — mind-shatter.** A full **Dissolution-class** strike (or Shock T4 / Helpless) on a **non-boss** `[PH]`. **Player-inflicted mind-collapse gated per R5** (permanent removal + puppet asset; source-gated). See Residual R3.
**1–5 scales:** range (+5/+10/+15, L2–L4).
**R3 (Mind Burst) RULED (owner 2026-07-18):** the mind-collapse STAYS but is **really-high-tier magic ONLY** — L10, magic-only, source/patron-gated, non-boss, per R5. Confirmed as the design intent.

### #29 — Aura Reading · mind · 0 Moment · cap 5 · [PASSIVE]
**Identity.** Sense a visible/adjacent target's dominant emotional state; reveals feeling, never intent or actions. Filipe's.
**FINAL 6–10 (stays in its lane — FEELING only; never actions [Read the Pattern] or thoughts [Telepathy]):**
- **6 — read the room.** Sense multiple targets / the crowd's mood at once.
- **7 — actionable read.** Reveal an intent **tier** derived from affect (aggression → imminent, desperation → reckless) and warn allies — a *feeling-based* early warning, explicitly NOT the scheduled action Read the Pattern gives.
- **8 — remote sense.** Feel presences out of sight (through walls) — ambush early-warning.
- **9 — pierce deception.** Read guarded/masked emotions (Mind-gated concealment); sense lies/feints as emotional dissonance.
- **10 (mundane, stays passive) — empathic mastery.** A full emotional map of the encounter; predict morale breaks and Dissolution vulnerabilities `[PH]`.
**1–5 scales:** sensing range (L2–L4).
**Residual:** none. *(Resolved by lane authoring — Aura = affect, Read the Pattern = actions, Telepathy = thoughts; the three never converge as they generalize.)*

### #38 — Full Potential · mind · 1 Moment · cap 5 · [character-locked: Mario]
**Identity.** Improvise/repair/jury-rig a simple item; functional but fragile (one use or 1 Clock).
**FINAL 6–10:**
- **6 — better crafting.** Craft Quality-tier items; repair equipped gear mid-combat.
- **7 — combat gadgets.** Rig traps/one-shot devices (pipe bomb, snare) — improvisation as offense/control.
- **8 — craft for the team.** Build for/with allies (hand off the rig; assist another's action, R15); use scavenged battlefield parts.
- **9 — craft anywhere.** The "materials present" gate loosens; works under fire without the fragility penalty.
- **10 (mundane) — masterwork.** A durable, multi-use device, or an on-the-fly modifier/affix application (ties to §3.2) `[PH]`.
**1–5 scales:** durability/uses and item tier craftable (Crude→Basic, L2–L4).
**Residual:** none. *(Default #7: player-playable, full ladder; content lock pending the `exclusive_to` field. Note: L10 touching the affix/modifier economy — flag for consistency with R12 modifier tiers.)*

### #40 — Nightlurking · mind · 0 Moment · cap 5 · [PASSIVE]
**Identity.** Always aware of the nearest exit/gap/vent; fit through cat-sized gaps without a Forced Action. The one skill with explicit compendium rungs. Sasha's.
**FINAL 6–10 (built on §3.4's own L6; passive generalizes, L10 adds an active toggle · #1):**
- **6 — `[compendium §3.4]` full-speed squeeze.** Full-speed movement through detected gaps, no Moment penalty.
- **7 — traversal into ambush.** Emerging from a gap can Expose/Overwhelm a target (synergy with Camouflage/Pounce).
- **8 — team navigation.** Sense routes for the whole party; guide an ally through a gap with you.
- **9 — broader traversal.** Fit through larger/complex obstructions (not only cat-sized); detect exits through walls/floors.
- **10 (mundane, passive + active toggle) — escape artist.** Always an exit; a **declared** once-per-scene instant relocation to a known opening (a get-out-of-death button) `[PH]`.
**1–5 scales:** awareness range (+5/+10/+15, L2–L4); per §3.4, L3 adds concealed-entrance detection within Near. **Data-hygiene (#10):** compendium scopes this **Mind + Reflexes**; data seeds **Mind-only** — confirm the stat(s) at implementation before wiring gates.
**Residual:** none.

---

# CHARM skills (2)

### #31 — Vibe Control · charm · 1 Moment · cap 5 · [spectacle L10]
**Identity.** Project FEAR (push + de-prioritize) or CHARM (fixate + Exposed-from-behind) at a target that can perceive you. R18: Charm = presentability.
**FINAL 6–10:**
- **6 — command presence.** Project onto multiple targets / a Mob group at once.
- **7 — a third mode.** AWE (freeze/hesitate — a soft Shock) or RALLY (buff allies' morale/hype).
- **8 — broadcast.** Project at Far range, or through the camera/crowd (a broadcast taunt), not only line-of-sight adjacency.
- **9 — sway the strong-willed.** Overcome Mind-gated resistance and higher-will Elites; CHARM mode survives a hit.
- **10 — SPECTACLE CAPSTONE (default #6).** A **Camera-Call-tier mass fixate/rout** that swings the room and spikes Viewers/patron bids `[PH]` — **CHARM scales the crowd payoff** (R18 presentability → audience economy).
**1–5 scales:** range and "resist penetration" (overcoming the target's will) — L2–L4.
**Residual:** none. *(Default #6 settles the R18 question: the behavioral influence is the skill's own mechanic, gated by its resist-penetration stat; **CHARM scales the crowd/camera payoff.**)*

### #34 — Voicebox · charm · 0 Moment · cap 5 · [PASSIVE]
**Identity.** Mimic any previously-heard sound/voice; convincing at a distance; Mind-3 targets may detect on interaction.
**FINAL 6–10 (stays passive/on-demand — deception, NOT a crowd-spectacle skill, so no spectacle L10):**
- **6 — less input needed.** Mimic from brief exposure and hold a convincing conversation, not just a snippet.
- **7 — weaponized mimicry.** A mimicked command/alarm triggers enemy behavior (false orders, lure, feign a boss cue).
- **8 — throw the voice.** Ventriloquism to a location, splitting enemy attention.
- **9 — fool the wary / wider palette.** Fool Mind 3+ listeners (overcome the detection gate); mimic non-vocal/mechanical sounds.
- **10 (mundane) — perfect impersonation.** A flawless full-voice/identity mimicry even attentive minds accept — an infiltration skeleton key `[PH]`.
**1–5 scales:** mimicry fidelity ("strength" — harder to detect; L2–L4).
**Residual:** none. *(Voicebox is deception/infiltration, not audience-facing — deliberately NOT given the #6 spectacle L10.)*

---

# Framework application notes

Where a default forced a change from the DRAFT worksheet, and the running data-hygiene list.

## Default #2 — magic-only rule-transcending L10 (the biggest structural change)
- **9 magic ladders carry the rule-transcending / source-gated magic L10** (the only carriers allowed):
  Poison Ball, Poison Wall, Frost Ball, Frost Wall, Fire Ball, Fire Wall, Telekinesis, Telepathy,
  Mind Burst. Each L10 now reads explicitly as radiant/psychic-class **and** is **source-gated**
  (cap-raise Patron Token + Wizard's Tower). Elemental Confluence is the 10th magic skill but is
  handled by #5 (off-ladder consume-capstone), not a rule-transcending L10.
- **1 non-magic ladder DEMOTED:** **Execution** L10 lost "ignores robustness on a non-boss" (now
  "cannot be interrupted once declared" — mundane).
- **1 non-magic clarification:** **Strong Strike** L10 does **not** bypass the §R14 force-vs-robustness
  gate (its "reliable 7+ breach" runs through the gate like everything). All other non-magic L10s
  were already mundane (bullet-time, perfect guard, ghost stealth, master key, free-runner,
  behead-the-exposed, etc.) and were confirmed, not changed.

## Default #6 — spectacle rung as the standard L10 for audience-facing skills
- **4 ladders given the shared Camera-Call/spectacle L10:** **Dance, Vibe Control, Heroic Punch,
  Juggling.** CHARM scales the crowd payoff in each (R18). Dance's Reflexes-vs-Charm and Vibe
  Control's R18 residuals are both resolved by this default.
- Deliberately **not** given the spectacle L10: combat skills whose L10 merely spikes Viewers as a
  by-product (Controlled Sweep, Slice n' Dice, Decapitate, Execution, Thousand Cuts) keep a mundane
  combat capstone; **Voicebox** keeps its deception capstone (its fantasy is infiltration, not crowd-work).

## Default #4 — chain gates fixed by default; four authored release rungs named
- **Authored chain-release rungs (the only places a chain's "must follow / same target" gate loosens):**
  **Slip Through L9** (standalone from any adjacency), **Decapitate L9** (any Exposed/Helpless/Overwhelmed
  opening), **Pressure Strike L8** (any Forced-Action opening incl. an ally's Feint, R15),
  **Thousand Cuts L9** (standalone, no Feint→Pressure chain).
- **Gates held fixed:** Pounce's L6/L7 multi-target/pin do **not** loosen Slip Through's same-target gate
  (kills the Pounce residual); Shockwave stays must-follow-Overhead-Slam (L8 changes origin only);
  **Execution stays chain-locked to Shockwave** (L9 broadens the qualifying downed-state only). All 9
  chain skills were touched by this discipline.

## Default #5 — consume/mutate capstone off-ladder
- **Elemental Confluence** rewritten from a 6–10 track to an **off-ladder fixed capstone**; any growth is
  discrete Patron-Token cap-raises at cap-10, not level-up rungs.

## Default #7 — locked/NPC skills
- **Reversion → NPC-only / fixed:** no player 0–10 ladder; five per-encounter escalation beats the owner
  authors per appearance.
- **Heroic Punch, Full Potential → full player ladder** (character-locked availability, not NPC-only).
- **Player-inflicted mind-collapse** (Mind Burst L10, Telepathy L10) gated per R5 (non-boss, permanent
  removal + puppet asset, source-gated) — but see Residual R3 for the product-intent confirmation.

## Default #8 — no HP restoration / no full cure
- **Seal The Wound**: draft L7 "resolve one tier (a real cure)" **removed**; reframed to condition-arrest
  (freeze advancement) — management only. L10 "stabilize the dying" kept as a **delay** that returns the
  ally 0-HP-stabilized per R5 (no HP restored). No other ladder proposed healing.

## Default #1 — passive convention
- Six passives generalize AS passives; four take an **active toggle only at the top** where it fits:
  **Swim L10** (in-water dash), **Acrobatic Save L10** (declared clutch), **Nightlurking L10** (declared
  relocation), **Acrobatics L10** (declared free-run Clock). **Aura Reading** and **Voicebox** stay fully
  passive/on-demand — no toggle needed.

## Defaults #3 & #9 — global, no per-skill change
- #3: all 6–10 rungs are in-run progression; creation's four-skill trade buys **cap headroom only**,
  never a pre-generalized starting ability. #9: every magnitude is PLACEHOLDER pending §R14.

## Default #10 — data-hygiene items to fix at IMPLEMENTATION (do not lose)
1. **Tactical Roll** (#9) — legacy "Cooldown: 1 Clock" + L3/L4 "−2 Moment cooldown" vs §R3 no-cooldowns → re-express as a prime / once-per-Clock.
2. **Acrobatic Save** (#37) — legacy "Cooldown: 1 Clock" vs §R3 → re-express as a prime (once-per-encounter for the L10 clutch).
3. **Thousand Cuts** (#28) — `effects[]` empty; 1–5 scaling unauthored → author.
4. **Telepathy** (#18) — `effects[]` empty; 1–5 scaling unauthored → author.
5. **Strong Strike** (#4) — `effects[]` empty; no L2–L4 rows → author.
6. **Camouflage** (#44) — garbled base/unlock text ("Have an Not spot you") → confirm the intended base rule.
7. **Nightlurking** (#40) — stat drift: compendium **Mind + Reflexes** vs data **Mind-only** → confirm stat(s).
8. **Frost Wall** (#13) — garbled effect text ("Burn damage destroys deals twice as much") + length mismatch (target 5 vs text 6 spaces) → clean.
9. **Reversion** (#45) — empty `range`, `[numbers PLACEHOLDER]`, no `unlock_requirements` → wire per encounter (NPC-only), not the player-skill schema.

## Design-consistency flags (cross-references, not blocking questions)
- **Read The Pattern L9** (boss win-condition tells) must stay consistent with authored boss discoverable
  win-conditions.
- **Poison Ball L9** (self-supplied entry condition) is a strong balance lever — treat in the §R14 pass.
- **Full Potential L10** (on-the-fly affix/modifier) must stay consistent with the R12 modifier-tier economy.

---

# Residual owner questions (the small set the framework did NOT settle)

The 10 accepted defaults resolved the great majority of the worksheet's ~20 per-skill open questions
and all 10 cross-cutting questions. **All three residuals RULED by the owner 2026-07-18** — one new sub-question opened (Telepathy's fit):

- **R1 — Brace (#8): RULED — SPLIT then merge.** Intercept and Iron Stance are **separate lower-tier
  skills**, with an upgrade/merge path that folds them into Brace's high rungs. Author all three.

- **R2 — Fire Ball (#14): RULED — no Explosion skill.** R19's "Explosion" was a made-up illustrative
  example, "not concrete in any way" — Fire Ball's ladder stands on its own as fire's native generalization.

- **R3 — Mind Burst (#19): RULED — mind-collapse = really-high-tier magic only** (L10, magic-only,
  source-gated, non-boss, per R5). Confirmed. **Telepathy (#18): NEW OPEN question** — owner is unsure
  Telepathy fits the game at all, since the **player chat function already covers mind-to-mind comms**.
  Leaning cut or repurpose (recommend: repurpose to reading enemy/NPC hidden intent, which chat can't do).
  Re-anchor Mind Burst's "Req Telepathy Lv 3" prereq if Telepathy is cut.

*(Everything else — passives, chains, the elemental line, spectacle skills, Reversion, Seal The Wound,
Swim's racial question, Dance's stat question, all cooldown/empty-effects/garbled-text items — is
resolved above or routed to the implementation data-hygiene pass.)*
