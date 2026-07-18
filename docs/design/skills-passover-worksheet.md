# Skills Passover Worksheet — R19 Generalization Ladders

**Status:** DRAFT for owner review · **Date:** 2026-07-18 · **Governs:** all 43 seeded skills (`data/skills.json`)
**Rule of record:** `docs/rules-addendum.md` §R19 (Skill level architecture, owner 2026-07-17)

---

## Preamble — what this is and how to use it

### What R19 asks

R19 rules every skill onto a **0–10 track**:

- **0** = untrained (known, unusable) · **1** = the effect works.
- **1–5** = **normal modifiers** — the basic stats scale (damage, range, area, duration).
- **6–10** = each level **changes the basic function to apply to MORE SITUATIONS**, while the
  basic stats keep scaling underneath.

The owner's **canonical Explosion example** is the authoring template for every skill:
> 1–5 damage/range · **6** cluster · **7** sub-damage of a chosen type · **8** originate
> away from the caster · **9** enhance activation range & conditions · **10** psychic/
> radiant-class damage — and 6–10 all keep raising range and damage too.

Read as a lens, those five rungs are: **6 = happens more times / to more targets**,
**7 = add a chooseable secondary channel**, **8 = decouple the effect from your body
(remote / delayed / on behalf of an ally)**, **9 = loosen the requirement & range gates**,
**10 = a rule-transcending capstone unique to the skill's fantasy.** Every ladder below is
tailored to its own skill, not stamped from that shape — but the shape is the compass.

### The ground rule (please hold me to it)

**6–10 must each buy a new SITUATION, not just a bigger number.** "+2 damage" is a level-1–5
thing. A rung that only raises a number is a failed rung — send it back. A good rung answers
"what can this skill now DO that it couldn't at level 5?"

### How to use this worksheet

For each skill you get: its current identity (quoted from data), a **draft 6–10 ladder**
(five proposals), a one-line note on what scales 1–5, and only-where-genuine open questions.

- **Approve** a rung as-is, **edit** the situation it unlocks, or **reject** and I'll redraft.
- Skills are grouped by **primary stat** for navigability. Chain skills, magic, passives, and
  exclusives are tagged inline.
- Every rung is a **proposal you react to** — opinionated on purpose so there's something to
  push against. Faithful to each skill's established fantasy; nothing invented about the
  world, only about how the skill grows.

### PLACEHOLDER (R14)

**Every number here is PLACEHOLDER** pending the R14 numbers rework and the force-vs-robustness
gate. This sitting is about approving the **shape** of each ladder (which situation each rung
unlocks); magnitudes are tuned after R14. Rungs that imply a number are marked `[PH]`.

### Source legend

- `[data L6+]` — the skill already carries level-6+ text in `data/skills.json`; re-read under R19, not invented.
- `[compendium §x]` — design source in `docs/GPT_Master_Compendium.md`; cited, not invented.
- `[fresh]` — drafted from the skill's fantasy; no prior level text existed.

---

# PHYSIQUE skills (14)

## #1 — Controlled Sweep · physique · 1 Moment · cap 5
**Identity.** *"Attack 3 more Mobs as if you performed a single target attack on each of them."*
Req: *"Melee weapon equipped. At least 2 Mobs adjacent."* Range Adjacent · Target Area (all adjacent Mobs).
**Source:** `[fresh]` (compendium §3.4 lists it among XQUEZ/T reviewed skills, no level text).

**Draft 6–10 ladder:**
- **6 — catches Elites, not just Mobs.** An Elite in reach can now be swept (counts as the whole sweep's instances). New situation: sweep is no longer a Mob-only tool.
- **7 — spreads your weapon's on-hit condition.** Each swept target also takes the weapon's Bleed/Crush rider `[PH]` on a random exposed limb, not just the base hit. New: the whirlwind spreads conditions.
- **8 — sweep a ring you're not standing in.** Originate the arc around a chosen space within reach (one step out), so you can hit a cluster you're beside rather than inside. New: decoupled origin.
- **9 — drops the "2 Mobs adjacent" floor to 1 and becomes reactive.** May be declared when 2+ enemies enter your reach. New: proactive/reactive, not just anti-swarm.
- **10 — arena beat.** Every enemy in reach struck once and knocked back 1 space `[PH]`; a Camera-Call-tier wave-clear spike. Signature.

**1–5 note:** scales the number of extra Mobs hit (3→6 across the L2–L4 rows).
**Open Qs:** Friendly fire is ON (rulings batch 2026-07-17) — does the L10 arena beat exclude allies, or is catching them part of the spectacle risk?

## #4 — Strong Strike · physique · 2 Moment · cap 5
**Identity.** *"Wind up a strike of overwhelming force. On hit: +1 damage of weapon type. While performing: Exposed."* Req: *"Melee weapon equipped."* Target Single. (No L2–4 rows authored.)
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — cleave-through.** On a kill or part-disable, the wind-up isn't wasted — it carries into the enemy directly behind. New: the haymaker no longer dead-ends.
- **7 — load a stagger.** Choose a secondary rider on the blow: Crush→Shock T1, or trigger the weapon's affix, on the same part. New: it staggers, not only damages.
- **8 — bank the charge / release as a reaction.** Hold the wind-up across a Moment and unleash when the target commits, so you're not Exposed the whole time. New: a trap instead of a telegraph.
- **9 — reach & thrown weapons.** The "melee/adjacent" gate loosens; the wind-up threatens a space, not just a body. New: usable at range.
- **10 — guaranteed breach hit.** Counts as a single hit for the 7+ breach threshold regardless of raw number `[PH]` — the designed answer to Surface-Immunity bosses (Incineradile, §3.1). Signature.

**1–5 note:** scales the bonus weapon-type damage on hit (and, if desired, shortens the Exposed window).
**Open Qs:** Should L10's "counts as a breach hit" bypass the R14 force-vs-robustness gate, or only guarantee the 7+ threshold check? (Interacts with the R15 combined-actions breach path.)

## #5 — Counter-Surge · physique / mind · 1 Moment · cap 5
**Identity.** *"Strike immediately, reducing their action's remaining cost by 1. If the action collapses, they roll Forced Action — Body."* Req: *"Adjacent enemy must be currently executing a 2+ Moment cost action."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — interrupt 1-Moment actions too.** The "2+ Moment" gate widens to any declared action. New: interrupt more things.
- **7 — leaves a mark on collapse.** On collapse, also apply Shock T1 (the mind synergy — you rattled them) or your weapon's rider. New: interrupt + condition.
- **8 — intercept-counter for an ally.** Counter an action targeting an adjacent ally, not only yourself. New: protect the team (R15).
- **9 — counter casters & ranged wind-ups.** Fires at Near range and against visible ranged/cast wind-ups, not just melee. New: interrupt spellcasters/shooters.
- **10 — full reversal.** The collapsed action's Moment cost is refunded to YOU as tempo (or turned back on them) `[PH]`. Signature.

**1–5 note:** scales the remaining-cost reduction (−1 → −4 across L2–L4).
**Open Qs:** none.

## #7 — Pressure Hold · physique / reflexes · 2 Moment · cap 5
**Identity.** *"Grapple target. While held: they cannot reposition, you are Exposed, and so are they."* Req: *"Adjacent target. Both hands free or weapon allows grappling."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — hold two, or pin the weapon-arm.** Grapple two adjacent targets, or lock one limb of a single target. New: multi-control.
- **7 — the squeeze deals.** While held, apply Suffocation or Crush-over-time to a chosen part `[PH]` (subject to the R9 boss immunity). New: the hold damages, not only controls.
- **8 — hand off / throw.** Pass the grappled target to an assisting ally (R15), or hurl them into another for Crush. New: grapple as a team tool / projectile.
- **9 — hold above your weight class.** The Physique gate loosens; initiate on Elite-scale targets the base skill couldn't hold. New: grapple bigger things.
- **10 — body-slam finisher.** End the hold to deal Crush to Head/Torso and knock Prone (Exposed); a Cinematic-Kill candidate `[PH]`. Signature.

**1–5 note:** scales drag-while-holding distance (the L2–L4 movement rows) and hold strength/duration.
**Open Qs:** R9 rejects Suffocation-by-grapple vs a boss — does the L7 squeeze inherit that immunity, or can a high-level hold bypass it?

## #8 — Brace · physique · 0 Moment · cap 5
**Identity.** *"Reduce the next Crush or Burn damage received by 1."* Req: *"Must be able to react — not Helpless, not mid-action."* Self.
**Source:** `[compendium §3.3]` — XQUEZ/T Tank Kit: *"Existing Brace reduces Crush/Burn by 1 — could get a robot-specific upgraded variant"*; Intercept & Iron Stance drafts live here. **This ladder proposes Brace as the home for the tank identity.**

**Draft 6–10 ladder:**
- **6 — universal guard.** Brace against all damage types (add Bleed and the incoming condition tier), not just Crush/Burn. New: one flinch covers the whole hit.
- **7 — defense that pays back.** Reflect 1 to a melee attacker `[PH]`, or convert prevented damage into a Camera-Call/hype tick (spectacle tank). New: guard with a payoff.
- **8 — INTERCEPT (folds in §3.3 draft).** Brace on behalf of an adjacent ally — take/reduce a hit aimed at them. New: guard the team, the core tank move.
- **9 — IRON STANCE (folds in §3.3 draft).** Declare a standing brace: until you move, reduced-type hits against you and adjacent allies are reduced. New: an aura, not a one-shot react.
- **10 — immovable object.** Negate one incoming hit entirely, once per Clock `[PH]`. Signature.

**1–5 note:** scales the flat reduction (−1 → −4 across L2–L4).
**Open Qs:** Should Intercept/Iron Stance (§3.3, "finalization pending") live as Brace's high rungs — this ladder's proposal — or stay separate skills?

## #20 — Pounce · physique · 2 Moment · cap 5 · CHAIN opener
**Identity.** *"Leap up to 3 spaces and slash downward onto the target's torso for 2 Bleed. The leap costs 0 movement… CHAIN: Opens into Slip Through at -1 Moment cost."* Req: *"Physique 3, Reflexes 2. Light Small Weapon (Claws or Knife type)."* (Sasha's opener.)
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — hits a pair.** The landing strike may split across two adjacent bodies, or catch a second enemy in the landing space. New: opener against a duo.
- **7 — pin instead of cut.** Convert the torso Bleed into a light grapple/Exposed (claws hooked in). New: opener that controls.
- **8 — aerial ambush.** Pounce off a wall or an ally boost (R15) for a vertical origin — dive onto Head-legal Exposed targets. New: uses verticality.
- **9 — pounce from anywhere.** The leap ignores difficult terrain and gaps and extends range; can open from cover/stealth. New: opener from bad ground.
- **10 — combo enabler.** A landing that auto-Exposes the target or discounts the whole Pounce→Slip→Decapitate chain `[PH]`. Signature.

**1–5 note:** scales Bleed and leap distance (L2–L4 rows).
**Open Qs:** Do L6/L7 (two targets, pin) break Slip Through's "same target" chain requirement? (See Cross-cutting #4.)

## #22 — Decapitate · physique / reflexes · 3 Moment · cap 5 · CHAIN finisher
**Identity.** *"Deals 3 Bleed to the Head… If the Head reaches 0 HP, it is a Cinematic Kill — gain 1 Viewer spike automatically."* Req chain: *"Pounce Lv 5, Slip Through Lv 3… Must be positioned behind target. Target must be Exposed."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — momentum carries.** A head-kill grants a free reposition or a second Cinematic-Kill attempt on an adjacent Exposed Mob `[PH]`. New: chain-kills.
- **7 — pick the kill.** Choose Crush (behead-by-force) vs Bleed to match weapon; survivors who witness take Shock (morale). New: kill type + spectacle.
- **8 — ranged execution.** Executable from a thrown claw/blade at 1–2 spaces; the opening no longer requires melee-behind. New: kill at reach.
- **9 — finisher off any opening.** Fires off any Exposed/Helpless/Overwhelmed state, not only Slip Through's. New: unshackled from the strict chain.
- **10 — highlight-reel kill.** Instant-kill on any lethal part of a non-boss Exposed target, max Viewer spike `[PH]`. Signature.

**1–5 note:** scales Head Bleed damage (L2–L4 rows).
**Open Qs:** none.

## #23 — Overhead Slam · physique · 2 Moment · cap 5 · CHAIN opener
**Identity.** *"Deals 3 Crush to target body part. If the target is standing, they are knocked Prone (Exposed)… CHAIN: Opens into Shockwave at -1 Moment cost."* Req: *"Physique 4. Heavy Large Weapon equipped."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — cracks the ground.** Impact splashes 1 Crush to a second adjacent target. New: opener with splash.
- **7 — bury & pin.** Option to apply a Pin/Exposed (them or their weapon-arm) instead of pure damage. New: control option.
- **8 — leaping slam.** Close 1–2 spaces into the slam (absorbs movement) so it opens from range. New: gap-closer opener.
- **9 — any heavy object.** Works with improvised heavy objects, not just equipped Large weapons; bonus on Prone targets. New: environmental heavy-hitter.
- **10 — fault-line.** Guarantees the Shockwave chain; knockback becomes a wide stagger `[PH]`. Signature.

**1–5 note:** scales Crush damage (L2–L4 rows).
**Open Qs:** none.

## #24 — Shockwave · physique · 2 Moment · cap 5 · CHAIN link
**Identity.** *"3-space cone… All targets take 1 Crush to their legs and are knocked back 1 space. Mobs caught must roll Forced Action — Body… CHAIN: Opens into Execution at -1 Moment cost."* Req: *"Overhead Slam Lv 3. Must follow Overhead Slam immediately."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — full ring.** The cone becomes 360° — everyone around you, not just forward. New: surrounded-answer.
- **7 — reshapes the field.** Leave difficult terrain/rubble in the cone, or apply Chill/Burn if standing on such a surface. New: terrain effect.
- **8 — remote tremor.** Send the wave outward from a chosen point within reach (a delayed quake), not just from you. New: remote AoE.
- **9 — staggers Elites, collision Crush.** Forced Action now lands on Elites, not only Mobs; knockback into walls/hazards adds collision damage. New: control up the enemy ladder.
- **10 — earthquake.** Knocks the whole cone Prone (Exposed) and sets up Execution on all of them `[PH]`. Signature.

**1–5 note:** scales Crush and knockback distance (L2–L4 rows).
**Open Qs:** none.

## #25 — Execution · physique · 3 Moment · cap 5 · CHAIN finisher
**Identity.** *"Deal 4 Crush to Head or Torso… On Torso: apply Shock Tier 3 (Faint). On Head: if damage reduces Head to 0 HP, instant death."* Req: *"Must follow Shockwave immediately. Must be adjacent to a Prone or Helpless target."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — double finisher.** Execute two downed adjacent targets at once. New: multi-execute.
- **7 — kill that shapes the room.** On-kill payload: a fear wave (Shock/morale to nearby enemies) or a spectacle-scaled Viewer spike. New: choose the aftermath.
- **8 — ranged coup de grâce.** Executable at reach (spear/thrown) on a Prone target 1–2 spaces away. New: ranged finisher.
- **9 — broader kill windows.** Can execute the merely Exhausted/Grappled/Overwhelmed, not only Prone/Helpless. New: more setups qualify.
- **10 — unstoppable.** Cannot be interrupted once declared; ignores robustness on a non-boss `[PH]`. Signature.

**1–5 note:** scales the Crush damage (+2/+4/+6 across L2–L4).
**Open Qs:** none.

## #30 — Swim · physique · 0 Moment · cap 5 · PASSIVE
**Identity.** *"+1 space of movement when swimming. Lung capacity extends the Suffocation timer by 1 Clock before it begins."* Req: *"Must be in water."*
**Source:** `[compendium §3.4]` — *"Swim — racial, needed numbers, should scale aggressively for a sea lion."* (Filipe.)

**Draft 6–10 ladder (a passive that generalizes environments — see Cross-cutting #1):**
- **6 — submerged combat.** No penalty to actions/attacks underwater; at home where others flounder. New: fight, not just travel, in water.
- **7 — drown your prey.** Drag/grapple a target underwater and impose Suffocation on them while you stay immune (the sea-lion predator). New: water as a weapon.
- **8 — generalize "water".** The affinity extends to any low-buoyancy medium — flooded rooms, mud, fluid hazards, low-G. New: more media read as water.
- **9 — tow an ally.** Grant the movement/breath bonus to an adjacent towed ally (rescue-swim); near-total Suffocation immunity. New: team utility.
- **10 — amphibious apex.** Effectively unlimited breath and an in-water burst dash usable as a Pounce-equivalent `[PH]`. Signature racial capstone.

**1–5 note:** scales swim movement speed (+1 per L2–L4) and the Suffocation grace window.
**Open Qs:** Compendium calls Swim "racial" — is it animal/sea-lion-locked (R16 animal-background bias), or a general skill any contestant can raise?

## #39 — Heroic Punch · physique · 1 Moment · cap 5
**Identity.** *"Deals 2 Crush. If targeting the Head while the target is Exposed, add Shock Tier 1. **Level 6: Deals 3 Bleed. The hit generates a cosmetic crowd effect — a visible POW graphic… Gain 1 Viewer spike on a Head hit.**"* Req: *"Unarmed. Both hands free."* (Mario-flagged, §5.)
**Source:** `[data L6+]` (existing L6 text re-read under R19) + `[compendium §5]`.

**Draft 6–10 ladder:**
- **6 — `[data L6+]` it becomes a signature.** Gains a Bleed channel (3 Bleed `[PH]`) and its first true spectacle payload — POW graphic + Viewer spike on Head hits. Keep as the "becomes iconic" rung.
- **7 — pick the rider.** Shock (rattle) vs knockback (send them into a wall/ally for collision). New: situational punch.
- **8 — Superhero Landing.** A dash-punch closing 1–2 spaces; can strike airborne/elevated targets. New: gap-closer.
- **9 — the knockout.** May target the Head without Exposure on Mobs; works while carrying/one-handed. New: reliable KO tool.
- **10 — the money shot.** On a downed/Exposed target, a Cinematic-Kill with max crowd spike — the "nobody becomes somebody" beat `[PH]`. Signature.

**1–5 note:** scales Crush (+1/+2/+3 across L2–L4).
**Open Qs:** Heroic Punch is Mario-exclusive (§5) — do exclusive skills get the full 6–10 ladder or a bespoke capstone? (Cross-cutting #7.)

## #43 — Slice n' Dice · physique · 2 Moment · cap 5
**Identity.** *"Against a single target: deal 2 Bleed to each limb (4 total)… Or 3 Bleed to Torso… **Level 6+: If both hits land on already-Bleeding body parts, advance each Bleed by 1 tier.**"* Req: *"Physique 2, Reflexes 3. Natural claws or equipped light blades in both hands."* (Sasha's.)
**Source:** `[data L6+]` (existing L6 re-read) + `[compendium §3.4]` (*"costed properly… claw flavor leaned into"*).

**Draft 6–10 ladder:**
- **6 — `[data L6+]` bleed-stacker.** Landing on already-Bleeding parts advances each +1 tier — condition-stacking becomes the identity. Keep.
- **7 — cross-apply.** Add the weapon's affix condition, or split one strike into a Shock-inducing slash to an Exposed Head. New: not only Bleed.
- **8 — widen the arc.** Three targets, or a 180° wrap — the flurry becomes a crowd-clearer. New: multi-target.
- **9 — flexible flurry.** Usable with any paired light implements (improvised); reposition between strikes (dance-in/out). New: mobility + flexibility.
- **10 — "cleaning this is a bother".** Guaranteed multi-part Bleed T2 on a single Exposed target — a bleed-to-death setup + Viewer spike `[PH]`. Signature.

**1–5 note:** scales Bleed on torso/limbs (L2–L4 rows).
**Open Qs:** none.

## #45 — Reversion · physique · 2 Moment · cap 5 · [EXCLUSIVE: Nikita]
**Identity.** *"FULL physical reversion to the 1945 soldier — young in body and mind; statline swaps to WAR NIKITA… Ends at combat end or after 1 Clock: returns to OLD (aged again), gains Exhausted T2, no memory of the interval."* Prime: *"the song — a 2-Moment prep everyone hears."* `[numbers PLACEHOLDER R14]`
**Source:** `[compendium §4.5]` + description note (owner 2026-07-17: *"FULL reversion: he becomes YOUNG again — body and mind"*). **This is an authored NPC skill — R16: NPC stats fit the character, ignoring creation budgets.**

**Draft 6–10 ladder (framed as encounter/narrative escalation, not a player-raised track — see Cross-cutting #7):**
- **6 — he won't stay down.** Reversion holds beyond 1 Clock or re-triggers mid-fight — the escalation beat. New: persistence as the fight heats up.
- **7 — War Nikita's signature.** Gains a war action (suppressing fire / bayonet rush) Old Nikita can't use. New: unique moveset tier.
- **8 — the song is a weapon.** The prime itself becomes a field effect — all who hear it are touched (morale; "the whole arena goes still"). New: the prime affects the room.
- **9 — the tragedy tightens.** Triggers on more stimuli (any lethal damage, combat pattern-match, Sasha's presence) — harder to keep him Old. New: broader activation.
- **10 — full reversion.** The owner's 2026-07-17 ruling: truly young again, body and mind, statline at peak — the boss apex; resolving him means reaching Old, never out-damaging War `[PH]`.

**1–5 note:** scales duration and/or War Nikita statline potency `[PH]` — but as an authored NPC skill, "levels" likely mean encounter difficulty the owner sets per appearance, not player investment.
**Open Qs:** Does an NPC-exclusive skill use the player 0–10 ladder at all, or is its "level" just per-encounter difficulty scaling? (Reversion reads as narrative escalation.)

---

# REFLEXES skills (12)

## #2 — Quick Step · reflexes · 0 Moment · cap 5
**Identity.** *"Ignore difficult terrain movement penalty for this moment."* Req: *"Must have movement remaining."* Self.
**Source:** `[compendium §3.4]` — differentiated from Acrobatics (*"Quick Step = terrain"* vs Acrobatics = vertical/precision).

**Draft 6–10 ladder:**
- **6 — shrug movement debuffs.** Ignore not just terrain but movement-impairing conditions briefly (Chilled leg, light Exhausted drag) for the step. New: escape control effects.
- **7 — clear the path for the team.** The step leaves a cleared trail an ally can follow at no penalty (R15). New: mobility as support.
- **8 — evasive reposition.** Usable as a reaction to being targeted (a mini-dodge), not only proactively. New: defensive use.
- **9 — run through hazards.** Ignore hazard terrain (fire-wall edge, poison floor, ice) for the pass, and cross gaps. New: cross dangerous ground.
- **10 — flow state.** For one Moment, movement costs 0 regardless of distance and can't be reacted to `[PH]`. Signature.

**1–5 note:** scales the duration of the ignore-terrain effect (L2–L4 rows).
**Open Qs:** none.

## #9 — Tactical Roll · reflexes · 0 Moment · cap 5
**Identity.** *"When an attack is performed on you, immediately move 1 space from your current position."* Req: *"Must not be Prone, Helpless… **Cooldown: 1 Clock.**"* (Description: "Bullet time".)
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — dodge more than melee.** Dodge any incoming effect you can perceive (ranged shot, AoE edge), not only direct attacks. New: dodge attack types.
- **7 — dodge into offense.** End in a counter-ready stance — your next attack this Clock gains position/Exposed-from-behind on the dodged enemy. New: dodge sets up a hit.
- **8 — shove-save an ally.** Roll an adjacent ally out of the way instead of yourself. New: protect the team.
- **9 — dodge from bad states.** Works while Prone or with a leg disabled (the base forbids it); escape AoE zones wholesale. New: dodge when it matters most.
- **10 — bullet time.** Dodge every attack targeting you this tick `[PH]`. Signature (matches the flavor).

**1–5 note:** scales dodge distance and reduces the (legacy) cooldown (L2–L4 rows).
**Open Qs:** §2.4/R3 removed cooldowns system-wide, but this skill still lists "Cooldown: 1 Clock." Confirm the replacement gate (prime? once-per-Clock?) — flagged for data cleanup, not re-derived.

## #21 — Slip Through · reflexes · 2 Moment · cap 5 · CHAIN link
**Identity.** *"Dash between the legs of the creature you just struck. Deal 1 Bleed to each of their legs. Reposition behind the target. Target becomes Exposed…"* Req: *"Pounce Lv 3… Target must be larger than you (Elite or Boss scale minimum)."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — same-size targets.** The size gate loosens; usable against Mobs, not only larger creatures. New: broader targeting.
- **7 — hamstring on the way through.** Apply Crush/Chill to a leg to slow, or trip to Prone. New: leaves a control effect.
- **8 — slip through anything.** Traverse a gap/obstacle/ally line, not only under a creature (Nightlurking-adjacent). New: environmental slip.
- **9 — standalone repositioner.** Initiate without Pounce from any adjacency; reposition further. New: breaks the strict chain.
- **10 — untouchable.** Pass through a whole cluster, Exposing each, ending anywhere behind the line, uninterruptible `[PH]`. Signature.

**1–5 note:** scales the per-leg Bleed damage (L2–L4 rows).
**Open Qs:** none (chain-integrity captured in Cross-cutting #4).

## #26 — Feint · reflexes / charm · 1 Moment · cap 5 · CHAIN opener
**Identity.** *"The target's next action becomes a Forced Action — Tool. Reposition up to 1 space… Deals no damage. CHAIN: Opens into Pressure Strike…"* Req: *"Reflexes 3, Charm 2."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — sell it wide.** Feint two adjacent targets at once. New: multi-target debuff.
- **7 — pick the fumble.** Choose Forced Action Tool (fumble) vs Body (stumble/Exposed) to match the setup. New: pick the failure mode.
- **8 — ranged bait.** Feint at Near range via a shout/gesture (charm-driven), no longer melee-adjacent. New: bait from distance.
- **9 — bait more states.** Works on targets mid-action (bait an interrupt) and on the wary (Mind-resistance loosens). New: more enemies fooled.
- **10 — total misdirection.** Spoof the target's whole next-Clock plan (they act as if you're where you aren't) `[PH]`. Signature.

**1–5 note:** scales reposition distance and the Forced-Action die manipulation (L2–L4 "+1 Die, you choose result").
**Open Qs:** none.

## #27 — Pressure Strike · reflexes / physique · 2 Moment · cap 5 · CHAIN link
**Identity.** *"Strike the target's exposed limb for 2 Bleed. Move up to 2 spaces… If the target is still suffering Forced Action consequences from Feint, add Shock Tier 1… CHAIN: Opens into Thousand Cuts…"* Req: *"Feint Lv 3. Must follow Feint immediately…"*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — hit two.** Strike two limbs, or two targets caught by the same Feint. New: multi-hit follow-up.
- **7 — pick the payload.** Convert the Bleed into a Crush/disable on a chosen limb (take the arm), or add Shock unconditionally. New: choose the effect.
- **8 — opportunist.** Fires off any opening (an ally's Feint, an enemy's Forced Action from another source), not only your own Feint. New: capitalize on team setups (R15).
- **9 — reach & non-Exposed.** Fires at reach and against non-Exposed limbs at reduced effect. New: broader targeting.
- **10 — tempo swing.** Refunds a Moment and keeps the chain open into Thousand Cuts for free `[PH]`. Signature.

**1–5 note:** scales Bleed and reposition distance (L2–L4 rows).
**Open Qs:** none.

## #28 — Thousand Cuts · reflexes · 3 Moment · cap 5 · CHAIN finisher
**Identity.** *"Choose 3 body parts — deal 1 Bleed to each… If all 3 hits land on body parts that already had active Bleed conditions, advance each Bleed by 1 tier."* Req: *"Feint Lv 5, Pressure Strike Lv 3. Must follow Pressure Strike…"* (No L2–4 rows authored.)
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — five cuts / two targets.** Widen the flurry to more parts or across two targets. New: more coverage.
- **7 — venom coat.** A poison rider so the many small wounds become entry conditions for Poison. New: sets up affliction.
- **8 — cut-storm at range.** A thrown fan of blades at Near, or executable off a Slip-Through reposition. New: ranged flurry.
- **9 — unshackled.** Standalone (no Feint→Pressure chain required); can target Exposed Head parts among the three. New: freed finisher.
- **10 — death by a thousand cuts.** Guarantees at least T2 Bleed on every struck part — an unignorable bleed-out clock + max Viewer spike `[PH]`. Signature.

**1–5 note:** `effects[]` is **empty** — the 1–5 scaling is unauthored (cut count? Bleed per cut? reposition?).
**Open Qs:** What scales 1–5 before the ladder begins? (Empty `effects[]` — needs authoring.)

## #32 — Juggling · reflexes · 0 Moment · cap 5
**Identity.** *"Pass or catch any item within range in 0 Moments — absorbed into an existing action. Can be used to disarm…"* Req: *"Item must be within 5 spaces…"*
**Source:** `[compendium §3.4]` — *"Juggling (item passing as combat action)."*

**Draft 6–10 ladder:**
- **6 — mass item-flow.** Juggle multiple items / pass to multiple allies in one action (redistribute the party's kit). New: redistribute at scale.
- **7 — weaponize the throw.** A passed heavy/sharp item deals its damage in flight (improvised projectile); a caught enemy weapon is instantly usable. New: offense from item-flow.
- **8 — intercept mid-air.** Catch-and-return a projectile or thrown item in flight, not just handle held items. New: intercept things airborne.
- **9 — disarm up the ladder.** Disarm larger/braced grips the base can't, and catch across obstacles. New: harder disarms.
- **10 — the show-stopper.** Keep several items/objects in continuous flow — feeding allies and pelting enemies each Moment for a crowd spike `[PH]`. Signature spectacle.

**1–5 note:** scales range of the pass/catch (L2–L4 rows).
**Open Qs:** none.

## #33 — Dance · reflexes · 0 Moment · cap 5
**Identity.** *"While Dancing, all movement actions generate +1 Charm effect — crowd reactions, social rolls, and Charm-gated skills treat your Charm as 1 higher. Dancing ends if you are hit, knocked Prone, or declare an attack."*
**Source:** `[compendium §3.4/§5]` — *"XQUEZ/T — Dance (+1 Charm on movement while dancing)."*

**Draft 6–10 ladder (a spectacle/support skill that generalizes outward):**
- **6 — buff the troupe.** The dance lifts adjacent allies' Charm/hype too, not just you. New: party spectacle.
- **7 — choose the beat.** Taunt (draw camera/aggro like Vibe Control) or Inspire (an ally gets a die/tempo). New: dance does mechanical work.
- **8 — dance and fight.** The effect persists a beat after you stop or attack, instead of cancelling instantly. New: no longer mutually exclusive with combat.
- **9 — robust under pressure.** Can dance while Grappled/Prone (defiant performance); resists cancel from a single hit. New: survives adversity.
- **10 — showstopper.** A Camera-Call-tier crowd moment: mass hype spike, enemies distracted, patrons bid `[PH]`. Signature.

**1–5 note:** scales the Charm bonus while dancing (+1 per L2–L4).
**Open Qs:** Reflexes skill, Charm payoff — under R18 (Charm = presentability), does the crowd payoff scale on Reflexes (the moves) or Charm (the look)? (Cross-cutting #6.)

## #37 — Acrobatic Save · reflexes · 0 Moment · cap 5 · PASSIVE
**Identity.** *"When you would roll Forced Action - Body, Roll +1 Die and choose the result."* Req: *"Must not be Helpless or Prone. **Cooldown: 1 Clock.**"* (Description: "Not even close, baby!")
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — any fumble.** Applies to Forced Action Tool as well as Body. New: broader save.
- **7 — the save is spectacle.** A saved Forced Action can become a stylish reposition / Viewer spike ("not even close!"). New: turn a near-miss into hype.
- **8 — catch an ally.** Spend the save for an adjacent ally's Forced Action (R15). New: team save.
- **9 — never say die.** Works while Prone/Helpless (the base forbids it). New: save in the worst states.
- **10 — plot armor.** Once per encounter, auto-pass a Forced Action that would end the fight `[PH]`. Signature (matches the unlock: *"survive a consequence that should have ended the fight"*).

**1–5 note:** scales the number of extra dice you choose from (L2–L4 rows).
**Open Qs:** Same cooldown-vs-R3 flag as Tactical Roll — confirm the gate model. (Data cleanup.)

## #41 — Lockpicking · reflexes · 2 Moment · cap 5
**Identity.** *"Simple locks (padlocks, basic latches) succeed automatically. Forced Action — Tool on failure. Each attempt takes 2 Moments…"* Req: *"Reflexes 3. A lock must be present. Requires a thin tool…"*
**Source:** `[compendium §3.4]` — *"Lockpicking: reworked from passive to active with Moment cost; 'simple locks' scoped with a scale."*

**Draft 6–10 ladder:**
- **6 — top of the scale.** Pick Complex/Advanced locks the base and L2–4 (Moderate) can't touch. New: harder locks.
- **7 — trap interaction.** Read/disarm trapped locks (the fumble becomes a defuse), or jam a lock behind you. New: traps.
- **8 — no kit needed.** Pick with improvised/bare tools (bump/shim), and reach slightly into a mechanism. New: pick without a pick.
- **9 — under pressure.** Pick while moving / under fire without the interrupt Forced Action; open magical/keycard analogues. New: pick in combat.
- **10 — master key.** Any non-narrative mechanism opens in 0 Moments, silently `[PH]`. Signature.

**1–5 note:** scales speed (−Moment) and lock complexity reached (Simple → Moderate, per L2–L4).
**Open Qs:** none.

## #42 — Acrobatics · reflexes · 0 Moment · cap 5 · PASSIVE
**Identity.** *"Rough terrain does not reduce movement speed. Jumping and climbing Movement +1. Balancing… never requires a Forced Action… **Level 6+: Can change direction mid-leap. Vertical movement costs the same as horizontal movement.**"*
**Source:** `[data L6+]` (existing L6 re-read) + `[compendium §3.4]` (*"Acrobatics = vertical/precision"*).

**Draft 6–10 ladder:**
- **6 — `[data L6+]` full 3D traversal.** Change direction mid-leap; vertical movement costs the same as horizontal. Keep as "movement generalizes to all axes."
- **7 — enemies as terrain.** Acrobatic movement can pass through enemy spaces (vault over/off), optionally Exposing them (kick-off). New: use enemies as footing.
- **8 — any surface.** Wall-run / ceiling-cling for a Moment; origin decouples from the floor. New: leave the ground.
- **9 — stays upright.** Near-immune to knockback/Prone/trip; ignores fall damage within reason. New: resist control effects.
- **10 — free-runner.** For one Clock, no terrain, gap, height, or hazard impedes movement at all `[PH]`. Signature.

**1–5 note:** scales acrobatic movement and safe-fall distance (L2–L4 rows).
**Open Qs:** none.

## #44 — Camouflage · reflexes / mind · 3 Moment · cap 5
**Identity.** *"Hides the player, and can only be revealed if at 6 spaces or close. Breaks if character moves."* Req: *"Look like or be concealed in the environment around you."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — mobile stealth.** Move slowly and stay hidden — breaks only on fast movement/attack, not any movement. New: hide while moving.
- **7 — stealth into strike.** A strike from camouflage gains an ambush rider (Exposed/Overwhelmed → Head-legal, bonus damage). New: the assassin payoff.
- **8 — hide the team / decoy.** Conceal an adjacent ally, or plant an afterimage/decoy where you were. New: team + deception stealth.
- **9 — hide anywhere.** Hold camouflage without matching cover (adaptive/active camo); resist non-visual detection. New: no environment needed.
- **10 — ghost.** Effectively invisible until you act, even at adjacency, once per scene `[PH]`. Signature.

**1–5 note:** scales the reveal distance downward (harder to spot; L2–L4 "-reveal space").
**Open Qs:** The base effect/unlock text is garbled (*"Have an Not spot you"*). Confirm the intended base rule (line-of-sight break? spot roll?) before finalizing the ladder. (Data cleanup, not re-derived.)

---

# MIND skills (15)

## #3 — Seal The Wound · mind · 1 Moment · cap 5
**Identity.** *"Delay Bleeding OR Infection for 1 Clock. Cannot resolve the condition fully."* Req: *"Bleeding OR Infection is active on self or adjacent target."*
**Source:** `[fresh]` (compendium §5 confirms Filipe as the only dedicated healer/condition manager).

**Draft 6–10 ladder (healing is deliberately scarce, Q29 — this generalizes CONDITION coverage, not HP):**
- **6 — broader triage.** Delay any bleeding-family condition, including Crush-bleed and Poison entry. New: more conditions treated.
- **7 — a real, gated cure.** Fully resolve one tier (not just delay) at a cost — kept scarce per Q29. New: the first true cure, deliberately gated.
- **8 — ranged triage.** Treat an ally at Near range (thrown salve / shouted guidance), not only self/adjacent. New: reach the wounded.
- **9 — field medic.** Treat multiple conditions on one target, or one condition on two adjacent allies, in a cast. New: multi-target.
- **10 — stabilize the dying.** Halt a lethal bleed-out/poison clock for a full Clock on a downed ally `[PH]` — the last-stand save. Signature healer capstone.

**1–5 note:** scales the delay duration (+Clocks, L2–L4 rows).
**Open Qs:** Q29 says no item regenerates HP and healing is deliberately scarce — does Seal The Wound stay strictly condition-delay (never HP), and is the L7 "resolve a tier" within the scarcity intent? (Cross-cutting #8.)

## #6 — Read The Pattern · mind · 1 Moment · cap 5
**Identity.** *"Choose one enemy. Until the next Clock reset, learn their next scheduled action."* Req: *"Target must be within 3 spaces and visible."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — read the room.** Read two enemies, or a whole Mob pack's shared intent, at once. New: mass read.
- **7 — read becomes a team buff.** Share the read: allies you tell gain position/first-strike vs the revealed action (R15 info-sharing). New: actionable for the party.
- **8 — remote read.** Read a target out of line of sight (through walls, by pattern) beyond the 3-space gate. New: read the unseen.
- **9 — read boss tells.** Reveal a boss's discoverable win-condition telegraphs, not just scheduled actions — the anti-damage-race tool (ties to "bosses need discoverable win conditions"). New: read mechanics, not just moves.
- **10 — precognition.** See the enemy's full next Clock and pre-empt one action with a guaranteed interrupt window `[PH]`. Signature.

**1–5 note:** scales how many upcoming actions you foresee (+1/+2/+3 across L2–L4).
**Open Qs:** none. (The L9 boss-tell read is a strong lever — flag for boss-design consistency.)

## #10 — Poison Ball · mind · 2 Moment · cap 5 · MAGIC
**Identity.** *"On impact, all targets in a 3-space radius are exposed to Tier 1 Poison (Hemotoxin). Requires an entry condition on each target to activate."* Req: *"Mind 3."* Range 20.
**Source:** `[fresh]` (this is the elemental line R19's Explosion example most directly resembles).

**Draft 6–10 ladder (maps the Explosion template onto poison):**
- **6 — cluster.** Splits into 2–3 bomblets covering separate spaces (the Explosion L6). New: multi-blast.
- **7 — pick the toxin.** Choose Neuro/Hemo/Myo/Pneumo/Cyto at cast to match the target's weakness (the Explosion "sub-damage of chosen type"). New: pick the poison.
- **8 — remote/deferred origin.** Originate from a chosen point, or lob it as a delayed mine, not from your hand (the Explosion L8). New: decoupled origin.
- **9 — supplies its own entry condition.** No longer needs a pre-existing wound to activate (the Explosion "activation conditions" rung). New: works on the unwounded.
- **10 — radiant-tier toxin.** A Cytotoxic bloom that bypasses standard resistance tiers or deals direct HP `[PH]`. Signature.

**1–5 note:** scales blast radius and range (L2–L4 rows).
**Open Qs:** none. (L9 entry-condition removal is a big balance lever — flag.)

## #11 — Poison Wall · mind · 2 Moment · cap 5 · MAGIC
**Identity.** *"Wall of toxic vapor 5 spaces long… Any creature that passes through or starts their Moment inside takes Tier 1 Poison (Pneumotoxin). Persists for 1 Clock."* Req: *"Mind 3. Poison Ball Lv 3."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — shape control.** Two segments or an enclosing box (trap someone in). New: enclose.
- **7 — pick & propagate.** Choose the toxin (as Poison Ball L7) and add spread so contact seeds Poison to adjacent parts. New: pick + spread.
- **8 — dynamic placement.** Place anywhere in range, delay its rise, or make it drift forward each Clock. New: mobile/remote wall.
- **9 — durable, selective.** Persists longer, applies without entry conditions, and can be made ally-safe. New: reliable, friend-or-foe.
- **10 — toxic storm.** Merges with other clouds and advances Poison tiers each Clock inside (Confluence-lite) `[PH]`. Signature.

**1–5 note:** scales wall length/area (L2–L4 rows).
**Open Qs:** none.

## #12 — Frost Ball · mind · 2 Moment · cap 5 · MAGIC
**Identity.** *"Applies Chilled Tier 1 to all targets in a 2-space radius. Deals 2 Chill Damage."* Req: *"Mind 2."* Range 20.
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — cluster.** Shatters into secondary frost shards hitting nearby parts/targets. New: multi-hit.
- **7 — pick a control rider.** Slow (movement penalty), Brittle (next Crush +damage), or Chill a specific limb to disable. New: choose the control.
- **8 — freeze the field.** Freeze a surface/space into slick/difficult terrain, not just bodies. New: remote terrain control.
- **9 — sticky control.** Chill advances toward disable faster and resists the "self-clears after 8 Moments"; hits Burn-immune enemies for tempo. New: control that holds.
- **10 — flash-freeze.** Chill T2/T3 to a chosen part on impact (near-instant disable), or freeze a target solid for a Clock `[PH]`. Signature.

**1–5 note:** scales Chill damage and area (L2–L4 rows).
**Open Qs:** none.

## #13 — Frost Wall · mind · 2 Moment · cap 5 · MAGIC
**Identity.** *"Barrier of solid ice… Blocks movement and projectiles… Wall has 3 HP… Burn damage… deals twice as much."* Req: *"Mind 3."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — fort up.** Raise two walls or an enclosure. New: multi-segment cover.
- **7 — the wall bites.** Colliders take Chill T2 or shards; spiked variant deals Bleed. New: offensive barrier.
- **8 — offensive placement.** Place at range, or raise it under a target to launch/trap them; shape to terrain. New: dynamic/aggressive use.
- **9 — hardened & selective.** Resists Burn (removes the ×2 weakness), lasts longer, allies can pass through. New: reliable, friend-safe.
- **10 — glacier.** A large, moving, near-indestructible wall that pushes enemies (a mobile siege piece) `[PH]`. Signature.

**1–5 note:** scales wall HP/durability (L2–L4 rows).
**Open Qs:** none.

## #14 — Fire Ball · mind · 2 Moment · cap 5 · MAGIC
**Identity.** *"Blazing projectile that detonates on impact. All targets in a 3-space radius take 1 Burn damage and Burn Tier 1… Flammable objects in range ignite."* Req: *"Mind 2."* Range 20.
**Source:** `[fresh]` — **but this is the in-game sibling of R19's canonical Explosion; the ladder below reads the owner's own example onto it.**

**Draft 6–10 ladder (the Explosion example, applied to its obvious vehicle):**
- **6 — cluster.** Splits into multiple detonations across the radius (owner's L6). New: multi-blast.
- **7 — sub-damage of a chosen type.** Add a chosen secondary channel — shrapnel Bleed, or a chemical/poison burn — under the Burn (owner's L7). New: pick a rider.
- **8 — originate away from the caster.** A delayed rune, an arc lobbed over cover, a proxied detonation (owner's L8). New: remote origin.
- **9 — enhance activation range & conditions.** Longer throw, detonate-on-command, ignite even non-flammable targets (owner's L9). New: loosened gates.
- **10 — radiant/psychic-class fire.** Holy/plasma fire that bypasses fire-resistance and standard tiers (owner's L10) `[PH]`. Signature.

**1–5 note:** scales Burn damage and radius (L2–L4 rows).
**Open Qs:** Is the R19 "Explosion" a distinct future skill, or is **Fire Ball** the intended vehicle for that canonical example? The ladder above assumes Fire Ball inherits it — confirm, or keep Explosion separate.

## #15 — Fire Wall · mind · 3 Moment · cap 5 · MAGIC
**Identity.** *"Roaring curtain of fire… Any creature passing through takes Burn Tier 1… starting their Moment inside takes Burn Tier 2… Cannot be destroyed — only outlasted. Persists for 1 Clock."* Req: *"Mind 3."*
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — shape control.** Enclose or split the curtain (ring of fire). New: shape it.
- **7 — pick a field rider.** Smoke (blocks sight), Ember (spreads to flammables), or Scorch (leaves burning terrain behind). New: choose the field effect.
- **8 — mobile denial.** Place at range, or make it advance each Clock (a wildfire that herds). New: dynamic wall.
- **9 — durable & selective.** Burns longer, ignites the immune, can be made ally-safe. New: reliable denial.
- **10 — inferno.** Merges with fire sources, advances Burn tiers each Clock inside, radiant-fire option `[PH]`. Signature.

**1–5 note:** scales wall length/area (L2–L4 rows).
**Open Qs:** none.

## #16 — Elemental Confluence · mind · 3 Moment · cap 5 · MAGIC · CONSUME-capstone
**Identity.** *"Zone of shifting elemental chaos lasting 2 Clocks. At the start of each Clock choose one effect… Toxic Surge / Deep Freeze / Immolation."* Req: *"Mind 4. Poison Ball Lv 5, Frost Ball Lv 5, Fire Ball Lv 5 — all three are consumed on unlock."*
**Source:** `[fresh]` (already a consume/mutate capstone per §2.4).

**Draft 6–10 ladder (generalizes the ult itself):**
- **6 — layered chaos.** Choose two elements per Clock, not one. New: combined surges.
- **7 — a new element.** Add a fourth mode — Storm (lightning/psychic) or a chosen hybrid toxin. New: expand the menu.
- **8 — controllable ult.** The zone becomes mobile (you steer it), or cast it centered anywhere in range and stay outside safely. New: steer/decouple.
- **9 — scales up / friend-safe.** Advances despite boss resistances; can spare allies. New: works on tougher enemies, protects the team.
- **10 — cataclysm.** All modes fire simultaneously each Clock, radiant-tier — an arena-defining spectacle `[PH]`. Signature ult apex.

**1–5 note:** scales zone radius and range (L2–L4 rows).
**Open Qs:** As a consume-capstone, does Confluence even reach cap 10 via Patron Tokens, or is it authored at a fixed power on unlock? (Cross-cutting #5.)

## #17 — Telekinesis · mind · 1 Moment · cap 5 · MAGIC
**Identity.** *"Mentally grip one target… move the target up to 2 spaces per Moment… You are Exposed while sustaining. You cannot move while sustaining… **Level 6+: You may move 1 space per Moment while sustaining.**"* Req: *"Mind 3."*
**Source:** `[data L6+]` (existing L6 re-read under R19).

**Draft 6–10 ladder:**
- **6 — `[data L6+]` mobility while channeling.** Move 1 space/Moment while sustaining — the grip stops rooting you. Keep.
- **7 — crush & hurl.** Constrict a held target (Crush over time), or hurl held objects as weapons for their damage. New: TK as offense.
- **8 — many hands.** Grip multiple objects/targets, or a target just out of line of sight. New: multi-grip / remote.
- **9 — lift heavier.** Grip the heavy/braced/larger the Mind gate forbade; hold creatures that would resist. New: raise the weight class.
- **10 — telekinetic storm.** Levitate and hurl the battlefield's loose mass, or pin a boss for a breach window `[PH]`. Signature.

**1–5 note:** scales range (+3/+6/+9 across L2–L4).
**Open Qs:** none.

## #18 — Telepathy · mind / charm · 0 Moment · cap 5 · MAGIC
**Identity.** *"Establish a silent mental link… Read surface thoughts… Targets with Mind 4+ notice the intrusion… **Level 6+: Implant a single thought or image per Clock. Target believes it originated from themselves unless they have Mind 4.**"* Req: *"Mind 3, Charm 2. Target must have a Mind score."* (No L2–4 rows authored.)
**Source:** `[data L6+]` (existing L6 re-read).

**Draft 6–10 ladder:**
- **6 — `[data L6+]` read → write.** Implant a single thought/image per Clock, believed self-originated (below Mind 4). Keep.
- **7 — influence action.** Implant a compulsion/hesitation with mechanical bite (a soft Forced Action), or feed a false Read-the-Pattern to an ally. New: shape behavior.
- **8 — network.** Link multiple minds / a party channel, or reach a target you can't see. New: many minds.
- **9 — pierce the strong-willed.** Affects Mind 4+ targets (overcome the notice threshold). New: works on the mindful.
- **10 — domination-lite.** A lasting suggestion that shapes a target's next Clock — near the Dissolution / mind-collapse line `[PH]`. Signature (heavy — see Cross-cutting #2/#7).

**1–5 note:** `effects[]` is **empty** — 1–5 scaling unauthored (range? number of thoughts? fidelity?).
**Open Qs:** What scales 1–5? · L10 verges on Dissolution/mind-collapse (R5) — is that the intended top, or a boundary telepathy must not cross?

## #19 — Mind Burst · mind · 2 Moment · cap 5 · MAGIC
**Identity.** *"Flood a target's mind with overwhelming psychic noise. Target immediately takes Shock Tier 2 — their current action fails. If already Shocked, escalate by 1 tier… May target the Head regardless of Exposure."* Req: *"Mind 4. Telepathy Lv 3."* Target: Single (Head only).
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — cluster.** Burst two minds, or a small cluster (psychic AoE). New: multi-stun.
- **7 — pick the payload.** Shock vs seeding Dissolution (a mental-suffocation tick, per R5 gravity) vs confusion. New: choose the mental effect.
- **8 — remote stun.** Fire out of line of sight or down an implanted Telepathy link. New: no sightline needed.
- **9 — overcome resistance.** Beats psychic-resistance/Mind gates the base can't. New: works on resistant minds.
- **10 — mind-shatter.** A full Dissolution-class strike or Shock T4 (Helpless) on a non-boss `[PH]`. Signature (touches R5 mind-collapse).

**1–5 note:** scales range (+5/+10/+15 across L2–L4).
**Open Qs:** L10 touches R5 mind-collapse (permanent loss + puppet of the collapser) — is player-inflicted mind-collapse allowed on enemies, and gated how? (Cross-cutting #7.)

## #29 — Aura Reading · mind · 0 Moment · cap 5 · PASSIVE
**Identity.** *"Sense the target's current dominant emotional state — fear, aggression, calm, desperation… Does not reveal intent or planned actions, only feeling."* Req: *"Target must be visible or adjacent."*
**Source:** `[compendium §3.4]` — *"Filipe — Aura Reading (passive telepathy-lite, needed cost + sharper effect)."*

**Draft 6–10 ladder:**
- **6 — read the room.** Sense multiple targets / the crowd's mood at once. New: mass read.
- **7 — actionable read.** Reveal intent tier (aggressive → imminent attack), edging toward Read The Pattern; warn allies. New: feeling becomes a warning.
- **8 — remote sense.** Feel presences out of sight (through walls) — an ambush early-warning. New: sense the unseen.
- **9 — pierce deception.** Read guarded/masked emotions (Mind-gated concealment); detect lies/feints. New: see through masks.
- **10 — empathic mastery.** Full emotional map of the encounter; predict morale breaks and Dissolution vulnerabilities `[PH]`. Signature.

**1–5 note:** scales sensing range (L2–L4 rows).
**Open Qs:** How does Aura Reading (feeling) stay distinct from Read The Pattern (actions) and Telepathy (thoughts) as all three generalize upward? (Cross-cutting #3.)

## #38 — Full Potential · mind · 1 Moment · cap 5
**Identity.** *"Improvise, repair, or jury-rig a simple item using available materials. The result is functional but fragile — it works once or holds for 1 Clock…"* Req: *"Appropriate materials present. Mind 2."* (Mario-flagged, §5.)
**Source:** `[fresh]`.

**Draft 6–10 ladder:**
- **6 — better crafting.** Craft Quality-tier items; repair equipped gear mid-combat. New: higher-tier output.
- **7 — combat gadgets.** Rig traps/one-shot devices (pipe bomb, snare). New: improvisation as offense/control.
- **8 — craft for the team.** Build for/with allies (hand off the rig; assist another's action, R15); use scavenged battlefield parts. New: team crafting.
- **9 — craft anywhere.** The "materials present" gate loosens (minimal materials); works under fire without the fragility penalty. New: improvise in worse conditions.
- **10 — masterwork.** A durable, multi-use device, or an on-the-fly modifier/affix application (ties to §3.2) `[PH]`. Signature.

**1–5 note:** scales durability/uses and item tier craftable (Crude → Basic, per L2–L4).
**Open Qs:** none. (L10 touching the affix/modifier economy — flag for consistency.)

## #40 — Nightlurking · mind · 0 Moment · cap 5 · PASSIVE
**Identity.** *"Passively: always aware of the nearest exit, gap, vent, or navigable opening in any room entered. Can fit through spaces too small for a human without rolling a Forced Action…"*
**Source:** `[compendium §3.4]` — the one skill with **explicit compendium level rungs**: *"L3+: detects concealed entrances within Near. L6+: full-speed movement through detected gaps, no Moment penalty."* (Sasha's.)

**Draft 6–10 ladder (built on §3.4's own L6, extended):**
- **6 — `[compendium §3.4]` full-speed squeeze.** Full-speed movement through detected gaps, no Moment penalty. Keep (owner's own rung).
- **7 — traversal into ambush.** Emerging from a gap can set an ambush — Expose/Overwhelm a target (synergy with Camouflage/Pounce). New: traversal becomes offense.
- **8 — team navigation.** Sense routes for the whole party; guide an ally through a gap with you. New: shared shortcuts.
- **9 — broader traversal.** Fit through larger/complex obstructions (not only cat-sized); detect exits through walls/floors. New: bigger gaps.
- **10 — escape artist.** Always an exit; a once-per-scene instant relocation to a known opening (a get-out-of-death button) `[PH]`. Signature.

**1–5 note:** scales awareness range (+5/+10/+15 across L2–L4); per §3.4, L3 also adds concealed-entrance detection within Near.
**Open Qs:** §3.4 scopes Nightlurking as **Mind + Reflexes**; the data seeds it **Mind-only**. Confirm the stat(s) before finalizing the ladder's gates. (Compendium/data drift — flag.)

---

# CHARM skills (2)

## #31 — Vibe Control · charm · 1 Moment · cap 5
**Identity.** *"Project one of two emotional states… FEAR: Target moves 1 space away… less likely to prioritize targeting you… CHARM: Target becomes fixated on you… Exposed from behind. Effect ends immediately when the target is hit."* Req: *"Charm 3. Target must be able to perceive you."*
**Source:** `[compendium §3.4]` — *"Vibe Control (split Fear/Charm modes)"* (already implemented as the two modes). R18: Charm = presentability, the camera-facing pull.

**Draft 6–10 ladder:**
- **6 — command presence.** Project onto multiple targets / a Mob group at once. New: mass vibe.
- **7 — a third mode.** AWE (freeze/hesitate — a soft Shock) or RALLY (buff allies' morale/hype). New: more emotional levers.
- **8 — broadcast.** Project at Far range, or through the camera/crowd (a broadcast taunt), not only line-of-sight adjacency. New: remote presence.
- **9 — sway the strong-willed.** Overcome Mind-gated resistance and higher-will Elites; CHARM mode survives a hit. New: works on tougher targets.
- **10 — crowd-work apex.** A Camera-Call-tier mass fixate/rout that swings the room and spikes Viewers/patron bids `[PH]`. Signature (R18 presentability → audience economy).

**1–5 note:** scales range and "resist penetration" (overcoming the target's will) — L2–L4 rows.
**Open Qs:** Under R18, Vibe Control is presentability-driven but its effect is behavioral influence — is that owner-consistent, or should the influence scale on Mind while Charm governs the camera payoff? (Cross-cutting #6.)

## #34 — Voicebox · charm · 0 Moment · cap 5 · PASSIVE
**Identity.** *"Mimic any sound or humanoid voice previously heard. At base level, mimicry is convincing at a distance or in low-information contexts. Targets with Mind 3 may recognize the mimicry on interaction."* Req: *"Must have previously heard the sound or voice being mimicked."*
**Source:** `[compendium §3.4/§5]` — *"XQUEZ/T — Voicebox."*

**Draft 6–10 ladder:**
- **6 — less input needed.** Mimic from brief exposure (a few words heard) and hold a convincing conversation, not just a snippet. New: mimic more from less.
- **7 — weaponized mimicry.** A mimicked command/alarm triggers enemy behavior (false orders, lure, feign a boss cue). New: mimicry as control.
- **8 — throw the voice.** Ventriloquism to a location, splitting enemy attention. New: displaced source.
- **9 — fool the wary / wider palette.** Fool Mind 3+ listeners (overcome the detection gate); mimic non-vocal/mechanical sounds. New: harder marks, more sounds.
- **10 — perfect impersonation.** A flawless full-voice/identity mimicry even attentive minds accept — an infiltration skeleton key `[PH]`. Signature.

**1–5 note:** scales mimicry fidelity ("strength" — harder to detect; L2–L4 rows).
**Open Qs:** none.

---

# Cross-cutting decisions

These are the system-wide questions this passover surfaces. They shape many ladders at once,
so they're worth deciding before the per-skill rungs are locked.

1. **Passives and the 6–10 ladder.** Six skills are passive (Aura Reading, Swim, Voicebox,
   Acrobatic Save, Nightlurking, Acrobatics). Do passives generalize the same way — each rung a
   new situation the passive now covers — or should some high rungs become *active/declared*
   abilities (e.g., Nightlurking's L10 relocation, Acrobatic Save's L10 auto-pass)? Decide the
   passive-ladder convention once.

2. **Magic skills and the L10 psychic/radiant tier.** R19's Explosion L10 unlocks
   psychic/radiant-class damage. Is that top tier reserved for magic (`is_magic`) skills,
   available to *any* skill's capstone, or specific to the elemental line (Poison/Frost/Fire
   Ball, Confluence)? And does reaching L10 require a source-gate (Patron-Token cap-raise +
   Wizard's Tower) like base magic acquisition, or is it a pure level-up?

3. **The R16 background-skill trade vs the 6–10 band.** Backgrounds grant 4 skills; any may be
   given up for **+1 cap on another** (cap 5 → up to 10 via Patron Tokens, §2.4). Does trading a
   skill let a *starting* skill begin already reaching into 6+ (a contestant enters the show with
   a generalized ability), or is 6+ strictly earned in-run? This sets whether creation can buy
   into "new situations" or only into headroom.

4. **Chain skills and generalization.** Three chains — Pounce→Slip Through→Decapitate,
   Overhead Slam→Shockwave→Execution, Feint→Pressure Strike→Thousand Cuts — enforce
   "same target / must follow immediately." Several ladders propose loosening those gates at
   L9 ("unshackled") or broadening a link's targets at L6–7. When an opener generalizes, do the
   chain's strict requirements loosen in lockstep, or stay fixed so the chain's identity
   survives? Decide whether "unshackle the chain" is a legitimate high rung.

5. **Consume/mutate capstones (§2.4).** Elemental Confluence already *consumes* three L5 skills
   to exist. For consume/mutate skills, does the 6–10 ladder stack on top, or are they authored
   as fixed capstones outside the ladder? Related: is cap 10 always reached via Patron Tokens
   (§2.4), or can some skills be authored pre-maxed?

6. **Audience-facing skills and R18 Charm.** Dance (Reflexes) and Vibe Control (Charm) pay out
   in crowd/hype, and several capstones route into the Camera-Call / Viewer-spike economy.
   Under R18 (Charm = *presentability*, not influence/warmth), which stat scales the audience
   payoff — and should a shared "spectacle rung" (Camera-Call-tier crowd moment) be the standard
   L10 for every audience-facing skill?

7. **NPC-exclusive & character-locked skills.** Reversion is Nikita-exclusive; Heroic Punch and
   Full Potential are Mario-locked (§5). R16 says NPC stats fit the character, ignoring creation
   budgets. Do exclusive skills use the player 0–10 ladder at all, or is their "level" just
   per-encounter difficulty the owner authors? (Reversion especially reads as narrative
   escalation, not a raised track.) And does player-inflicted **mind-collapse** (Mind Burst /
   Telepathy L10, touching R5) belong to players at all?

8. **Healing economy and generalization (Q29).** HP recovery is deliberately scarce; items only
   delay/treat conditions, none regenerate HP. Seal The Wound's ladder proposes a gated "resolve
   one tier" rung (L7) and a "stabilize the dying" capstone (L10). Confirm the boundary: may any
   skill's 6–10 ladder introduce true HP restoration or full cures, or is that permanently
   off-limits so scarcity holds?

9. **PLACEHOLDER numbers and sequencing (R14).** Every magnitude here is placeholder pending the
   R14 numbers rework and the force-vs-robustness gate. Proposal: this sitting approves the
   **shape** of each ladder (which situation each rung unlocks); magnitudes are tuned after R14.
   Confirm that sequencing.

10. **Data hygiene surfaced by the passover** (clean as ladders are entered — do not silently
    carry forward): legacy **cooldowns** removed system-wide still sit on Tactical Roll &
    Acrobatic Save (vs §2.4/R3); **empty `effects[]`** (no authored 1–5 scaling) on Thousand
    Cuts & Telepathy; **garbled base text** on Camouflage (*"Have an Not spot you"*);
    **stat drift** on Nightlurking (compendium Mind+Reflexes vs data Mind-only). These want owner
    rulings or a cleanup pass, not re-derivation.
