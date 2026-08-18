extends SimTestBase
## Content pass batch D — "Casters & Showfolk" (docs/design/skills-r19-ladders-FINAL.md
## #10/#12/#14/#17/#31/#32/#44 + the G6 passover play_to_the_camera):
## poison_ball + frost_ball + fire_ball (the NEW aoe_blast archetype — a
## target-HEX declare, HexGeometry.blast membership over the R2 snapshot,
## _strike_round-grade per-target rows, the R25 roller escape + center
## exception, NOT undodgable per R26, frost typed CRUSH per G8, the poison
## entry gate per target, fire's blast-shaped can ignition), camouflage (the
## NEW stealth_conceal archetype — stealth with the shrunken reveal radius on
## the R20 substrate + the movement break), vibe_control (the NEW
## projection_control archetype — the perception gate via Stealth.sees, FEAR
## push + grudge reduction floor 0, CHARM fixation + reposition + the REAL
## R30 Exposed-from-behind), play_to_the_camera (the NEW hype_surge archetype
## — one Camera-Call stack spent through the existing ledger, the timed
## party-wide doubling window, only-when-set serialization),
## telekinesis (the NEW sustained_channel archetype — root/expose/hold locks,
## per-Moment upkeep on the real scheduling, drag, break-on-damage) and
## juggling (the NEW item_flow archetype — the first combatant-to-combatant
## item transfer, G8's dropped-only enemy disarm). Both designated slip
## candidates LANDED. Pins: rng discipline (blasts/vibe/surge consume no new
## rng), serialization round-trips + only-when-set compat, determinism.
## All magnitudes PLACEHOLDER (R14).


func add_party(sim: CombatSim, id: String, pos: Array, overrides: Dictionary = {}) -> void:
	var spec: Dictionary = {"team": "party", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}
	spec.merge(overrides, true)
	add_human(sim, id, spec)


## An Elite with no dodge_threshold (no dodge stream). Mind defaults to 0
## (sees nothing — vibe-immune by blindness); override via `extra` where a
## test needs a perceiving enemy.
func add_elite(sim: CombatSim, id: String, pos: Array, extra: Dictionary = {}) -> void:
	var spec: Dictionary = {
		"id": id, "name": id, "category": "Elite", "size": "Large",
		"team": "enemies", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
			{"key": "left_arm", "hp": 50, "lethal": false},
			{"key": "right_arm", "hp": 50, "lethal": false},
			{"key": "left_leg", "hp": 50, "lethal": false},
			{"key": "right_leg", "hp": 50, "lethal": false},
		],
	}
	spec.merge(extra, true)
	sim.apply_command({"type": "add_combatant", "combatant": spec})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func apply_cond(sim: CombatSim, target: String, part: String, condition: String, tier: int) -> Array[Dictionary]:
	return sim.apply_command({"type": "apply_condition", "target": target,
		"part": part, "condition": condition, "tier": tier})


func ball_declare(sim: CombatSim, actor: String, key: String, at: Array, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": key, "level": level, "at": at})


func vibe_declare(sim: CombatSim, actor: String, target: String, mode: String, level: int = 1, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "vibe_control", "level": level,
		"mode": mode, "targets": [{"id": target}]}
	action.merge(extra, true)
	return declare(sim, actor, action)


func grip_declare(sim: CombatSim, actor: String, target: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "telekinesis", "level": level,
		"targets": [{"id": target}]})


func sustain_declare(sim: CombatSim, actor: String, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "telekinesis", "level": 1, "sustain": true}
	action.merge(extra, true)
	return declare(sim, actor, action)


func juggle_declare(sim: CombatSim, actor: String, item: String, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "juggling", "level": 1, "item": item}
	action.merge(extra, true)
	return declare(sim, actor, action)


# ================================================================= aoe_blast

func test_blast_membership_roller_escape_and_center_exception() -> void:
	var sim: CombatSim = make_sim(6101)
	add_party(sim, "mage", [4, 0])       # INSIDE the blast — the caster exclusion pin
	add_party(sim, "bystander", [7, 0])  # friendly fire is ON — allies are caught
	add_party(sim, "roller", [6, 1])     # rolls OFF-center — escapes (R25)
	add_party(sim, "center_roller", [5, 1])  # rolls ONTO the center — still hit
	add_elite(sim, "e_in", [5, 0])
	add_elite(sim, "e_escaper", [6, -1])
	add_elite(sim, "e_out", [10, 0])     # outside radius 3 of [6,0]
	var declared: Array[Dictionary] = ball_declare(sim, "mage", "fire_ball", [6, 0])
	var row: Dictionary = assert_event(declared, "action_declared", "the ball declares at a hex")
	assert_true(bool(row.get("windup", false)), "cost 2 = a windup")
	advance(sim)
	# Tick 1 (mid-windup): leaving the area BEFORE the resolution tick escapes (R2).
	move(sim, "e_escaper", [6, -4])
	advance(sim)
	# Tick 2 (the resolution tick): the two rollers spend their movement on
	# declared-hex rolls — one away, one onto the blast's own center.
	declare(sim, "roller", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [7, 2]})
	declare(sim, "center_roller", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [6, 0]})
	var ev: Array[Dictionary] = advance(sim)
	var blast: Dictionary = assert_event(ev, "aoe_blast", "the detonation event")
	var caught: Array = blast.get("caught", [])
	assert_true(caught.has("e_in"), "the enemy in radius is caught")
	assert_true(caught.has("bystander"), "friendly fire ON — the ally is caught")
	assert_true(caught.has("roller"), "the roller's SNAPSHOT hex was caught (the escape is per-round)")
	assert_true(caught.has("center_roller"), "the center-roller's snapshot hex was caught")
	assert_false(caught.has("mage"), "the CASTER is excluded (the valve's exclude-the-source rule)")
	assert_false(caught.has("e_out"), "outside the radius = not a member")
	assert_false(caught.has("e_escaper"), "left the area before the resolution tick = escaped (R2)")
	var missed: Array[Dictionary] = events_of(ev, "blast_missed_roller")
	assert_eq(missed.size(), 1, "exactly one roller escaped")
	if missed.size() == 1:
		assert_eq(String(missed[0].get("combatant", "")), "roller", "the OFF-center roller (R25)")
	var damaged: Dictionary = {}
	for dmg: Dictionary in events_of(ev, "damage_applied"):
		damaged[String(dmg.get("combatant", ""))] = int(dmg.get("amount", 0))
	assert_true(damaged.has("e_in"), "the caught enemy took the burn")
	assert_true(damaged.has("bystander"), "the caught ally took the burn")
	assert_true(damaged.has("center_roller"), "rolling ONTO the center is no escape (the R25 exception)")
	assert_false(damaged.has("roller"), "the off-center roller took nothing")
	assert_false(damaged.has("mage"), "the caster took nothing")
	# L1 burn 1: force 1 + floor(3/2) = 2 vs robustness floor(3/2) = 1 -> 1 HP.
	assert_eq(int(damaged.get("e_in", -1)), 1, "hand-computed L1 burn through the R14 gate")
	assert_eq((sim.combatants["e_in"] as CombatantState).condition_tier("torso", "burn"), 1,
		"Burn T1 rides the landed hit")


func test_poison_ball_entry_gate_and_type_flow() -> void:
	var sim: CombatSim = make_sim(6102)
	add_party(sim, "mage", [0, 0])
	add_elite(sim, "e_wounded", [4, 0])
	add_elite(sim, "e_clean", [5, 0])
	apply_cond(sim, "e_wounded", "torso", "bleeding", 1)
	ball_declare(sim, "mage", "poison_ball", [4, 0])
	var ev: Array[Dictionary] = advance(sim, 3)
	assert_event(ev, "aoe_blast", "the toxic orb detonates")
	# The WOUNDED target takes Tier-1 Poison — and the authored hemo type flows.
	var wounded: CombatantState = sim.combatants["e_wounded"]
	assert_eq(wounded.condition_tier("torso", "poison"), 1, "wounded target: the toxin seeds")
	assert_eq(String(wounded.condition_instance("torso", "poison").get("poison_type", "")), "hemo",
		"poison_type flows into the instance (fixed hemo below the L6 choose rung)")
	# The UNWOUNDED target resists per the condition system's OWN rule.
	var clean: CombatantState = sim.combatants["e_clean"]
	assert_eq(clean.condition_tier("torso", "poison"), 0, "unwounded target: no toxin")
	var ignored: Dictionary = {}
	for ig: Dictionary in events_of(ev, "condition_ignored"):
		if String(ig.get("combatant", "")) == "e_clean":
			ignored = ig
	assert_eq(String(ignored.get("reason", "")), "no_entry_condition",
		"the honest per-target entry-gate outcome")
	# Both still took the impact splatter (PLACEHOLDER R14) — the gate is the
	# toxin's, not the orb's.
	for dmg: Dictionary in events_of(ev, "damage_applied"):
		assert_eq(int(dmg.get("amount", -1)), 1, "the L1 splatter (Affliction path, res 0)")


func test_frost_ball_types_as_crush_per_g8() -> void:
	var sim: CombatSim = make_sim(6103)
	add_party(sim, "mage", [0, 0])
	add_party(sim, "tank", [4, 0])
	add_elite(sim, "foe", [9, 0])
	var tank: CombatantState = sim.combatants["tank"]
	var hp_before: int = int(tank.parts["torso"]["hp"])
	# The tank braces (Crush/Burn guard 2) — if the frost impact is really
	# typed CRUSH (G8), the brace eats it.
	declare(sim, "tank", {"kind": "skill", "key": "brace", "level": 2})
	ball_declare(sim, "mage", "frost_ball", [4, 0])
	var ev: Array[Dictionary] = advance(sim, 3)
	var absorbed: Dictionary = assert_event(ev, "brace_absorbed",
		"the brace consumed the impact — the damage IS Crush-typed (G8, pinned)")
	assert_eq(String(absorbed.get("condition", "")), "crushed", "typed crushed exactly")
	# L1 impact 2: force 2+1=3 vs robustness 1 -> 2, brace 2 -> 0.
	assert_eq(int(absorbed.get("damage_before", -1)), 2, "hand-computed pre-brace crush")
	assert_eq(int(absorbed.get("damage_after", -1)), 0, "the flinch ate the whole impact")
	assert_eq(int(tank.parts["torso"]["hp"]), hp_before, "no HP lost through the brace")
	assert_eq(tank.condition_tier("torso", "crushed"), 1,
		"the LANDED crush impact seeds Crushed T1 — R4's coupling, the engine's own rule (documented)")
	assert_eq(tank.condition_tier("torso", "chilled"), 1, "the authored Chilled T1 rider")
	assert_no_event(ev, "healed", "chilled itself deals and heals nothing")


func test_fire_ball_ignites_a_trash_can() -> void:
	var sim: CombatSim = make_sim(6104)
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 31, "height": 31},
		"objects": [{"key": "trash_can", "position": [3, 0]}],
	}})
	add_party(sim, "mage", [0, 0])
	add_elite(sim, "foe", [2, 0])
	# L4 fire_ball (amount 4) at the can's hex: the blast washes the can.
	ball_declare(sim, "mage", "fire_ball", [3, 0], 4)
	var ev: Array[Dictionary] = advance(sim, 3)
	var burned: Dictionary = assert_event(ev, "trash_can_burned", "the can takes the burn touch")
	assert_eq(int(burned.get("added", 0)), 4, "the blast's own amount accumulates")
	assert_eq(int(burned.get("burn", 0)), 4, "4 < 5 — no pop yet (accumulate-or-pop)")
	assert_no_event(ev, "trash_can_exploded", "below the canon threshold")
	# Second ball: 4 + 4 = 8 >= 5 — the can explodes, canon blast included.
	ball_declare(sim, "mage", "fire_ball", [3, 0], 4)
	var ev2: Array[Dictionary] = advance(sim, 3)
	var popped: Dictionary = assert_event(ev2, "trash_can_exploded", "the accumulated can pops")
	assert_eq(int(popped.get("damage", 0)), Arena.TRASH_CAN_BLAST_BURN, "the canon 2-burn blast")
	assert_eq(sim.arena.object_index_at(Vector2i(3, 0)), -1, "the exploded can is removed")
	# The can's own blast burned the adjacent foe too (environment, no killer).
	var env_burns: int = 0
	for dmg: Dictionary in events_of(ev2, "damage_applied"):
		if String(dmg.get("combatant", "")) == "foe":
			env_burns += 1
	assert_true(env_burns >= 2, "the foe took the ball AND the can's blast")


func test_blast_consumes_no_rng_twin_streams() -> void:
	# Twin sims, same seed: twin B casts a full fire_ball into two elites; twin
	# A waits. The NEXT Forced-Action roll must draw the SAME stream value —
	# an aoe_blast against non-boss targets consumes ZERO rng.
	var twin_a: CombatSim = make_sim(6105)
	var twin_b: CombatSim = make_sim(6105)
	for twin: CombatSim in [twin_a, twin_b]:
		add_party(twin, "mage", [0, 0])
		add_elite(twin, "e1", [4, 0])
		add_elite(twin, "e2", [5, 0])
		apply_cond(twin, "mage", "torso", "bleeding", 2)  # Forced Body on actions
	ball_declare(twin_b, "mage", "fire_ball", [4, 0])
	advance(twin_b, 3)
	advance(twin_a, 3)
	declare(twin_a, "mage", attack_action("crushed", 1, "e1", "torso", {"attack_range": 4}))
	declare(twin_b, "mage", attack_action("crushed", 1, "e1", "torso", {"attack_range": 4}))
	var roll_a: Dictionary = assert_event(advance(twin_a), "forced_action_triggered", "twin A rolls")
	var roll_b: Dictionary = assert_event(advance(twin_b), "forced_action_triggered", "twin B rolls")
	assert_eq(int(roll_b.get("roll", -1)), int(roll_a.get("roll", -2)),
		"the blast consumed ZERO rng — the streams stay aligned")
	# (The bleeding-T2 caster's fire_ball itself rolled nothing either: the
	# condition-driven Forced Body seam lives in the strike path, and the
	# custom aoe_blast resolver follows the batch-C custom-resolver shape —
	# the aligned streams above prove it, not just assert it.)


func test_blast_los_gate_with_walls() -> void:
	var sim: CombatSim = make_sim(6106)
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 31, "height": 31},
		"walls": [[2, 0]],
	}})
	add_party(sim, "mage", [0, 0])
	add_elite(sim, "foe", [8, 0])
	assert_rejected(ball_declare(sim, "mage", "fire_ball", [4, 0]), "no_line_of_sight",
		"the thrown ball needs line of sight below the L8 remote-origin rung")
	assert_rejected(ball_declare(sim, "mage", "fire_ball", [0, 25]), "out_of_range",
		"the authored range gates the throw")
	var ok: Array[Dictionary] = ball_declare(sim, "mage", "fire_ball", [0, 4])
	assert_event(ok, "action_declared", "an unobstructed hex declares fine")


# ================================================================ camouflage

func test_camouflage_conceals_with_shrunken_reveal_radius() -> void:
	var sim: CombatSim = make_sim(6111)
	add_party(sim, "sneak", [0, 0])
	add_elite(sim, "watcher", [7, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 5, "charm": 3}})
	# Baseline: plain R20 stealth is impossible in the watcher's sight (2x5=10).
	assert_rejected(sim.apply_command({"type": "stealth", "actor": "sneak"}), "in_enemy_sight",
		"the plain hide fails in plain sight — the baseline the modifier changes")
	var declared: Array[Dictionary] = declare(sim, "sneak", {"kind": "skill", "key": "camouflage", "level": 1})
	var row: Dictionary = assert_event(declared, "action_declared", "the 3-Moment concealment declares")
	assert_true(bool(row.get("windup", false)), "cost 3 = a windup")
	var ev: Array[Dictionary] = advance(sim, 4)
	var entered: Dictionary = assert_event(ev, "stealth_entered", "camouflage enters REAL stealth")
	assert_eq(String(entered.get("via", "")), "camouflage", "via the modifier")
	assert_eq(int(entered.get("reveal_radius", 0)), 6, "L1 reveal radius pinned (the authored ~6)")
	var sneak: CombatantState = sim.combatants["sneak"]
	assert_true(sneak.stealthed, "stealthed on the R20 substrate")
	assert_eq(sneak.conceal_radius(), 6, "the override radius is live")
	# The watcher at 7 sees nothing (7 > 6); closing to 6 reveals — "revealed
	# only within N spaces", the shrunken-radius pin.
	var closed: Array[Dictionary] = move(sim, "watcher", [6, 0])
	var broken: Dictionary = assert_event(closed, "stealth_broken", "within 6 = seen")
	assert_eq(String(broken.get("reason", "")), "seen", "the sight break")
	assert_eq(String(broken.get("observer", "")), "watcher", "naming the observer")
	assert_true(sneak.conceal.is_empty(), "the modifier dies with the stealth")


func test_camouflage_ladder_shrinks_and_movement_breaks() -> void:
	var sim: CombatSim = make_sim(6112)
	add_party(sim, "sneak", [0, 0])
	add_elite(sim, "watcher", [4, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 5, "charm": 3}})
	# L4 radius 3: entering at distance 4 in the watcher's plain sight works.
	declare(sim, "sneak", {"kind": "skill", "key": "camouflage", "level": 4})
	var ev: Array[Dictionary] = advance(sim, 4)
	assert_eq(int(assert_event(ev, "stealth_entered", "L4 entry").get("reveal_radius", 0)), 3,
		"the L2-4 rows shrink the radius (pinned at L4 = 3)")
	# The sneak MOVES — camouflage breaks on movement, whoever is watching.
	var moved: Array[Dictionary] = move(sim, "sneak", [0, 1])
	var broken: Dictionary = assert_event(moved, "stealth_broken", "movement breaks the weave")
	assert_eq(String(broken.get("reason", "")), "moved", "the movement break, by name")
	var sneak: CombatantState = sim.combatants["sneak"]
	assert_false(sneak.stealthed, "stealth gone")
	assert_true(sneak.conceal.is_empty(), "modifier gone")
	# A watcher INSIDE the shrunk radius makes the windup collapse honestly.
	advance(sim)
	move(sim, "watcher", [3, 1])
	declare(sim, "sneak", {"kind": "skill", "key": "camouflage", "level": 4})
	var failed: Array[Dictionary] = advance(sim, 4)
	var invalid: Dictionary = assert_event(failed, "action_invalidated", "caught mid-crouch")
	assert_eq(String(invalid.get("reason", "")), "in_enemy_sight", "the honest reason")
	assert_event(failed, "forced_action_triggered", "the standard windup collapse (Tool)")
	assert_false(sneak.stealthed, "no stealth entered")


# ============================================================== vibe_control

func test_vibe_fear_pushes_and_calms_floor_zero() -> void:
	var sim: CombatSim = make_sim(6121)
	add_party(sim, "star", [0, 0])
	add_elite(sim, "foe", [2, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	add_elite(sim, "calm_foe", [0, 2], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	# Build a real grudge first: net damage 3 -> antagonism 3.0 (R23, 1:1).
	declare(sim, "star", attack_action("crushed", 3, "foe", "torso", {"attack_range": 2}))
	advance(sim)
	var foe: CombatantState = sim.combatants["foe"]
	assert_eq(float(foe.antagonism.get("star", 0.0)), 3.0, "precondition: grudge 3.0")
	var declared: Array[Dictionary] = vibe_declare(sim, "star", "foe", "fear")
	assert_event(declared, "action_declared", "FEAR declares on the perceiving foe")
	var ev: Array[Dictionary] = advance(sim)
	assert_eq(String(assert_event(ev, "vibe_projected", "the projection").get("mode", "")), "fear", "mode fear")
	var pushed: Dictionary = assert_event(ev, "knocked_back", "the 1-hex push")
	assert_eq(pushed.get("to", []), [3, 0], "pushed directly away")
	assert_true(bool(pushed.get("displaced", false)), "really displaced")
	var calm: Dictionary = assert_event(ev, "antagonism_changed", "the de-prioritization")
	assert_eq(float(calm.get("delta", 0.0)), -2.0, "the grudge REDUCTION (negative delta)")
	assert_eq(float(calm.get("score", -1.0)), 1.0, "3.0 - 2.0 = 1.0")
	assert_eq(String(calm.get("source", "")), "fear", "attributed to the fear")
	# Second fear: 1.0 - 2.0 floors at 0 (pinned).
	advance(sim)
	vibe_declare(sim, "star", "foe", "fear")
	var ev2: Array[Dictionary] = advance(sim)
	assert_eq(float(assert_event(ev2, "antagonism_changed", "the floored calm").get("score", -1.0)), 0.0,
		"floor 0 — a calmed mind holds no negative grudge")
	# A zero-grudge target still gets pushed but emits NO grudge change (no-op floor).
	advance(sim)
	vibe_declare(sim, "star", "calm_foe", "fear")
	var ev3: Array[Dictionary] = advance(sim)
	assert_event(ev3, "knocked_back", "the push still lands")
	assert_no_event(ev3, "antagonism_changed", "nothing to reduce = nothing emitted")


func test_vibe_charm_fixates_repositions_and_exposes_from_behind() -> void:
	var sim: CombatSim = make_sim(6122)
	add_party(sim, "star", [0, 0])
	add_party(sim, "assassin", [5, 0])
	add_elite(sim, "foe", [2, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	var declared: Array[Dictionary] = vibe_declare(sim, "star", "foe", "charm", 1,
		{"reposition_to": [0, 1]})
	assert_event(declared, "action_declared", "CHARM declares")
	var ev: Array[Dictionary] = advance(sim)
	var fixate: Dictionary = assert_event(ev, "antagonism_changed", "the fixation grudge")
	assert_eq(float(fixate.get("delta", 0.0)), 2.0, "the INCREASE toward the actor")
	assert_eq(String(fixate.get("source", "")), "fixation", "attributed to the fixation")
	var repo: Dictionary = assert_event(ev, "vibe_reposition", "the actor circles while they're fixed")
	assert_eq(repo.get("to", []), [0, 1], "the declared 1-hex reposition")
	var star: CombatantState = sim.combatants["star"]
	assert_eq(star.position, Vector2i(0, 1), "the actor really moved")
	var foe: CombatantState = sim.combatants["foe"]
	var fixed: Dictionary = assert_event(ev, "vibe_fixated", "the can't-look-away facing snap")
	assert_eq(int(fixed.get("facing", -1)), 3, "faces the actor's FINAL hex (W — hand-computed)")
	assert_eq(foe.facing, 3, "the involuntary authored facing landed")
	assert_event(ev, "vibe_exposed", "the Exposed window opens")
	assert_true(foe.exposed_cache, "the target is Exposed")
	# The "from behind" half is the REAL R30 gate: the assassin at [3,0] sits
	# in the fixated target's rear arc (facing W -> rear = E side).
	var assassin: CombatantState = sim.combatants["assassin"]
	assert_true(Stealth.is_behind(foe, assassin.position),
		"Exposed-from-behind reads the REAL is_behind primitive (decision #33)")
	assert_false(Stealth.is_behind(foe, star.position),
		"the actor themself is exactly where the fixation looks")


func test_vibe_rejects_the_imperceiving() -> void:
	var sim: CombatSim = make_sim(6123)
	add_party(sim, "decoy", [4, 0])
	add_elite(sim, "cone_blind", [2, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	add_party(sim, "star", [0, 0])
	add_elite(sim, "mind_blind", [0, 2])  # Mind 0 -> sight 0: perceives nothing
	# cone_blind staged BEFORE star: it faces the decoy east — star is in its
	# REAR arc, and an observer sees nothing over its shoulder (R30).
	assert_rejected(vibe_declare(sim, "star", "cone_blind", "fear"), "target_cannot_perceive",
		"cone-blocked: you cannot strike a pose at a turned back")
	assert_rejected(vibe_declare(sim, "star", "mind_blind", "fear"), "target_cannot_perceive",
		"a Mind-0 creature perceives nothing (2xMind sight = 0)")
	assert_rejected(vibe_declare(sim, "star", "cone_blind", "awe"), "unknown_vibe_mode",
		"only the two authored modes exist below the L7 third-mode rung")


# ======================================================== play_to_the_camera

func test_surge_spends_stack_amplifies_and_expires() -> void:
	var sim: CombatSim = make_sim(6131)
	add_party(sim, "face", [0, 5], {"camera_call_stacks": 1})
	add_party(sim, "striker", [0, 0])
	add_party(sim, "dummy1", [1, 0])
	add_party(sim, "dummy2", [0, 1])
	add_elite(sim, "foe", [8, 0])
	var meter_before: int = sim.hype.meter
	assert_eq(meter_before, 0, "clean meter to hand-compute against")
	# Surge + a same-Moment party beat: the striker's friendly-fire hit on
	# dummy1 (it's cinema) is attributed to dummy1 — a party member — and
	# doubles inside the window.
	var declared: Array[Dictionary] = declare(sim, "face",
		{"kind": "skill", "key": "play_to_the_camera", "level": 1})
	assert_event(declared, "action_declared", "the surge declares (stack prime met)")
	declare(sim, "striker", attack_action("crushed", 3, "dummy1", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	var started: Dictionary = assert_event(ev, "hype_surge_started", "the window opens")
	assert_eq(int(started.get("stacks_remaining", -1)), 0, "the ONE stack is spent")
	assert_eq(int(started.get("until_tick", -1)), 1, "L1: until the actor's next Moment")
	assert_eq(int(sim.hype.camera_calls_used.get("face", 0)), 1,
		"spent through the EXISTING camera_calls_used ledger")
	# Hand-computed: net 3 damage x 4 pts/HP = 12, surged x2 = 24 (subject
	# attribution — dummy1 is on the surge team; every other batch event
	# carries weight 0).
	assert_eq(int(sim.hype.ledger.get("dummy1", 0)), 24, "the party gain doubled (hand-computed)")
	assert_eq(sim.hype.meter, 24, "the meter took exactly the doubled gain")
	# A second stack cannot be spent (remaining 0 -> the STACK prime rejects).
	assert_rejected(declare(sim, "face", {"kind": "skill", "key": "play_to_the_camera", "level": 1}),
		"prime_unmet", "no stacks left — the spend is real")
	# Next Moment: the same hit on dummy2 scores UNdoubled — the window expired
	# on the actor's next Moment.
	declare(sim, "striker", attack_action("crushed", 3, "dummy2", "torso"))
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "hype_surge_ended", "the expiry is an event")
	assert_eq(int(sim.hype.ledger.get("dummy2", 0)), 12, "post-window gain UNdoubled (hand-computed)")
	assert_true((sim.hype.surge as Dictionary).is_empty(), "the window is gone")


func test_surge_duration_row_and_one_at_a_time() -> void:
	var sim: CombatSim = make_sim(6132)
	add_party(sim, "face", [0, 5], {"camera_call_stacks": 1})
	add_party(sim, "face2", [1, 5], {"camera_call_stacks": 1})
	add_party(sim, "striker", [0, 0])
	add_party(sim, "dummy", [1, 0])
	add_elite(sim, "foe", [8, 0])
	# L2: +1 Moment of surge duration (the batch-B imported row).
	declare(sim, "face", {"kind": "skill", "key": "play_to_the_camera", "level": 2})
	var ev: Array[Dictionary] = advance(sim)
	assert_eq(int(assert_event(ev, "hype_surge_started", "L2 window").get("until_tick", -1)), 2,
		"L2 lengthens the window one Moment")
	# One surge at a time (the spotlight precedent): a second declare rejects.
	assert_rejected(declare(sim, "face2", {"kind": "skill", "key": "play_to_the_camera", "level": 1}),
		"surge_active", "one window at a time")
	# The NEXT Moment's party beat still doubles under the L2 window.
	declare(sim, "striker", attack_action("crushed", 3, "dummy", "torso"))
	advance(sim)
	assert_eq(int(sim.hype.ledger.get("dummy", 0)), 24, "tick-1 gain still doubled at L2")


func test_surge_serializes_mid_window() -> void:
	var live: CombatSim = make_sim(6133)
	add_party(live, "face", [0, 5], {"camera_call_stacks": 1})
	add_party(live, "striker", [0, 0])
	add_party(live, "dummy", [1, 0])
	add_elite(live, "foe", [8, 0])
	declare(live, "face", {"kind": "skill", "key": "play_to_the_camera", "level": 3})
	advance(live)
	assert_false((live.hype.surge as Dictionary).is_empty(), "window live")
	var restored: CombatSim = CombatSim.from_dict(live.to_dict())
	assert_eq(restored.state_hash(), live.state_hash(), "hash survives the mid-window round-trip")
	assert_eq(int((restored.hype.surge as Dictionary).get("until_tick", -1)),
		int((live.hype.surge as Dictionary).get("until_tick", -2)), "the window round-trips")
	# Both timelines continue identically: the amplified beat, then expiry.
	for sim: CombatSim in [live, restored]:
		declare(sim, "striker", attack_action("crushed", 3, "dummy", "torso"))
		advance(sim)
	assert_eq(int(restored.hype.ledger.get("dummy", 0)), int(live.hype.ledger.get("dummy", 0)),
		"identical amplified scoring on both timelines")
	assert_eq(restored.state_hash(), live.state_hash(), "restore -> replay = same hash")


# =============================================================== telekinesis

func test_telekinesis_grip_locks_root_expose_and_drag() -> void:
	var sim: CombatSim = make_sim(6141)
	add_party(sim, "tk", [0, 0])
	add_elite(sim, "held", [3, 0])
	var declared: Array[Dictionary] = grip_declare(sim, "tk", "held")
	assert_event(declared, "action_declared", "the grip declares (visible, in range)")
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "telekinesis_grip", "the grip lands")
	var tk: CombatantState = sim.combatants["tk"]
	var held: CombatantState = sim.combatants["held"]
	assert_eq(String(tk.channeling.get("target", "")), "held", "the channel record")
	assert_eq(held.held_by, "tk", "the held-by mirror")
	assert_true(tk.exposed_cache, "the sustainer is Exposed (the R9-grapple mirror)")
	assert_rejected(move(sim, "held", [4, 0]), "held", "the target cannot take movement actions")
	assert_rejected(move(sim, "tk", [1, 0]), "channeling", "the sustainer is rooted")
	assert_rejected(declare(sim, "tk", {"kind": "skill", "key": "tactical_roll", "level": 1, "to": [1, 0]}),
		"channeling", "no roll while rooted either")
	# The sustain pays the Moment and drags the target one hex.
	var s_ev: Array[Dictionary] = sustain_declare(sim, "tk", {"drag_to": [4, 0]})
	assert_event(s_ev, "action_declared", "the sustain is a real cost-1 declare")
	var r_ev: Array[Dictionary] = advance(sim)
	assert_event(r_ev, "telekinesis_sustained", "the upkeep resolved")
	var dragged: Dictionary = assert_event(r_ev, "telekinesis_dragged", "the 1-hex forced drag")
	assert_eq(dragged.get("to", []), [4, 0], "to the declared hex")
	assert_eq(held.position, Vector2i(4, 0), "the body moved")
	assert_eq(held.facing, 3, "forced movement never re-faces (R30 — staged facing kept)")
	# A FREE declare coexists with the concentration; a SCHEDULED one abandons.
	var brace_ev: Array[Dictionary] = declare(sim, "tk", {"kind": "skill", "key": "brace", "level": 1})
	assert_event(brace_ev, "action_declared", "a free action coexists with the sustain")
	assert_false(tk.channeling.is_empty(), "the grip survived the free declare")
	var attack_ev: Array[Dictionary] = declare(sim, "tk", attack_action("crushed", 1, "held", "torso", {"attack_range": 4}))
	var released: Dictionary = assert_event(attack_ev, "telekinesis_released",
		"a scheduled declare abandons the grip first")
	assert_eq(String(released.get("reason", "")), "abandoned", "by name")
	assert_true(tk.channeling.is_empty(), "channel gone")
	assert_eq(held.held_by, "", "mirror gone")


func test_telekinesis_upkeep_lapse_and_break_on_damage() -> void:
	var sim: CombatSim = make_sim(6142)
	add_party(sim, "tk", [0, 0])
	add_elite(sim, "held", [3, 0])
	grip_declare(sim, "tk", "held")
	advance(sim)
	var tk: CombatantState = sim.combatants["tk"]
	var held: CombatantState = sim.combatants["held"]
	# Tick 1: the tk declares NOTHING — the unpaid Moment lapses the grip at
	# the tick's end (the target was honestly held through it).
	assert_rejected(move(sim, "held", [4, 0]), "held", "still held during the unpaid Moment")
	var lapse_ev: Array[Dictionary] = advance(sim)
	var lapsed: Dictionary = assert_event(lapse_ev, "telekinesis_released", "the upkeep lapse")
	assert_eq(String(lapsed.get("reason", "")), "sustain_lapsed", "by name")
	assert_eq(held.held_by, "", "free again")
	# Re-grip; then the sustainer takes damage — the grip breaks ("ends on
	# actor damage").
	grip_declare(sim, "tk", "held")
	advance(sim)
	assert_false(tk.channeling.is_empty(), "re-gripped")
	sustain_declare(sim, "tk")
	declare(sim, "held", attack_action("crushed", 3, "tk", "torso", {"attack_range": 3}))
	var hit_ev: Array[Dictionary] = advance(sim)
	assert_event(hit_ev, "telekinesis_sustained", "the sustain itself resolved this tick")
	var broken: Dictionary = assert_event(hit_ev, "telekinesis_released", "then the damage broke it")
	assert_eq(String(broken.get("reason", "")), "damaged", "break-on-damage, by name")
	assert_true(tk.channeling.is_empty(), "channel gone")
	# The free voluntary release: re-grip, then release costs nothing.
	grip_declare(sim, "tk", "held")
	advance(sim)
	var free_before: bool = tk.free_action_used
	var rel_ev: Array[Dictionary] = declare(sim, "tk", {"kind": "skill", "key": "telekinesis", "release": true})
	assert_eq(String(assert_event(rel_ev, "telekinesis_released", "voluntary release").get("reason", "")),
		"released", "by name")
	assert_eq(tk.free_action_used, free_before, "abandoning a state is not an act — no slot spent")


func test_telekinesis_gates_and_range_snap() -> void:
	var sim: CombatSim = make_sim(6143)
	add_party(sim, "decoy", [-2, 0])
	add_elite(sim, "west_e", [-4, 0])
	add_party(sim, "tk", [0, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 5, "charm": 3}})
	add_elite(sim, "east_e", [2, 0])
	add_elite(sim, "far_e", [11, 0])
	# tk staged facing its nearest opponent WEST — the eastern elite sits in
	# the rear arc: "must be visible" is the R20 cone for the caster too.
	assert_rejected(grip_declare(sim, "tk", "east_e"), "target_not_visible",
		"cone-blocked: no grip over the shoulder")
	assert_rejected(grip_declare(sim, "tk", "far_e"), "out_of_range", "L1 grip range 10")
	assert_rejected(grip_declare(sim, "tk", "tk"), "cannot_target_self", "never self")
	# Face the west elite (in the front arc) and grip at range; then DRAG the
	# target past the grip range — the NEXT sustain snaps honestly.
	add_elite(sim, "held", [-10, 0])
	assert_event(grip_declare(sim, "tk", "held"), "action_declared", "range-10 grip declares")
	advance(sim)
	sustain_declare(sim, "tk", {"drag_to": [-11, 0]})
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "telekinesis_dragged", "dragged out to 11")
	sustain_declare(sim, "tk")
	var snap_ev: Array[Dictionary] = advance(sim)
	var snapped: Dictionary = assert_event(snap_ev, "telekinesis_released", "the grip snaps")
	assert_eq(String(snapped.get("reason", "")), "target_left_range", "by name")
	assert_event(snap_ev, "action_invalidated", "the sustain found nothing to hold")


func test_telekinesis_round_trips_mid_sustain() -> void:
	var live: CombatSim = make_sim(6144)
	add_party(live, "tk", [0, 0])
	add_elite(live, "held", [3, 0])
	grip_declare(live, "tk", "held")
	advance(live)
	sustain_declare(live, "tk")
	advance(live)
	var restored: CombatSim = CombatSim.from_dict(live.to_dict())
	assert_eq(restored.state_hash(), live.state_hash(), "hash survives the mid-sustain round-trip")
	var r_tk: CombatantState = restored.combatants["tk"]
	assert_eq(String(r_tk.channeling.get("target", "")), "held", "the channel round-trips")
	assert_eq((restored.combatants["held"] as CombatantState).held_by, "tk", "the mirror round-trips")
	# Both timelines lapse identically (nothing sustains the next Moment).
	var live_tail: Array[Dictionary] = advance(live)
	var rest_tail: Array[Dictionary] = advance(restored)
	assert_event(live_tail, "telekinesis_released", "live: the lapse")
	assert_event(rest_tail, "telekinesis_released", "restored: identically")
	assert_eq(restored.state_hash(), live.state_hash(), "restore -> replay tail = same hash")


# ================================================================== juggling

func test_juggling_transfers_both_ways_with_range_gate() -> void:
	var sim: CombatSim = make_sim(6151)
	add_party(sim, "jug", [0, 0], {"items": [
		{"key": "knife", "damage_type": "bleeding", "damage_amount": 2, "attack_range": 1}]})
	add_party(sim, "ally", [3, 0])
	add_party(sim, "far_ally", [8, 0])
	add_elite(sim, "foe", [0, 6])
	var jug: CombatantState = sim.combatants["jug"]
	var ally: CombatantState = sim.combatants["ally"]
	assert_rejected(juggle_declare(sim, "jug", "knife", {"to": "far_ally"}), "out_of_range",
		"L1 pass range is the G8-reconciled 5")
	assert_rejected(juggle_declare(sim, "jug", "knife", {"to": "jug"}), "flow_needs_two_ends",
		"a flow needs two distinct ends")
	assert_rejected(juggle_declare(sim, "jug", "knife", {"from": "ally", "to": "far_ally"}),
		"actor_not_in_flow", "the juggler is always one end (L6 mass-flow stays data)")
	# PASS: jug -> ally, a 0-Moment free-slot action.
	var declared: Array[Dictionary] = juggle_declare(sim, "jug", "knife", {"to": "ally"})
	assert_eq(int(assert_event(declared, "action_declared", "the pass declares").get("cost", -1)), 0,
		"0 Moments — the free slot is the price")
	assert_true(jug.free_action_used, "the free slot is spent")
	var ev: Array[Dictionary] = advance(sim)
	var passed: Dictionary = assert_event(ev, "item_passed", "the item moves")
	assert_eq(String(passed.get("from", "")), "jug", "from the juggler")
	assert_eq(String(passed.get("to", "")), "ally", "to the ally")
	assert_false(bool(passed.get("disarm", true)), "a pass is not a disarm")
	assert_false(jug.items.has("knife"), "gone from the passer")
	assert_true(ally.items.has("knife"), "in the catcher's hands")
	assert_eq(int((ally.items["knife"] as Dictionary).get("damage_amount", 0)), 2,
		"the whole item dict moved (state preserved)")
	# CATCH back the next Moment: ally -> jug (the "from" flow).
	juggle_declare(sim, "jug", "knife", {"from": "ally"})
	advance(sim)
	assert_true(jug.items.has("knife"), "caught back")
	assert_false(ally.items.has("knife"), "and gone from the ally")


func test_juggling_disarm_only_dropped_per_g8() -> void:
	var sim: CombatSim = make_sim(6152)
	add_party(sim, "jug", [0, 0])
	add_elite(sim, "foe", [2, 0], {"items": [
		{"key": "club", "damage_type": "crushed", "damage_amount": 3}]})
	var foe: CombatantState = sim.combatants["foe"]
	assert_rejected(juggle_declare(sim, "jug", "club", {"from": "foe"}), "item_wielded",
		"a WIELDED enemy item cannot be taken (G8 — the L7 payoff stays data)")
	# The club is knocked loose (the Forced-Tool drop state) — now it flows.
	(foe.items["club"] as Dictionary)["dropped"] = true
	var declared: Array[Dictionary] = juggle_declare(sim, "jug", "club", {"from": "foe"})
	assert_event(declared, "action_declared", "a dropped item is fair game")
	var ev: Array[Dictionary] = advance(sim)
	var passed: Dictionary = assert_event(ev, "item_passed", "the disarm flow")
	assert_true(bool(passed.get("disarm", false)), "flagged as a disarm")
	var jug: CombatantState = sim.combatants["jug"]
	assert_true(jug.items.has("club"), "snatched")
	assert_false(bool((jug.items["club"] as Dictionary).get("dropped", true)),
		"a caught item is IN HAND, whatever the floor said")
	assert_false(foe.items.has("club"), "gone from the enemy")
	# already_carrying: give the foe another club and try to catch it too.
	advance(sim)
	foe.items["club"] = {"key": "club", "dropped": true}
	assert_rejected(juggle_declare(sim, "jug", "club", {"from": "foe"}), "already_carrying",
		"one dict per key — an honest reject, not a silent merge")
	# And the juggler's own DROPPED item is pickup's job, not a flow.
	(jug.items["club"] as Dictionary)["dropped"] = true
	add_party(sim, "ally", [1, 0])
	assert_rejected(juggle_declare(sim, "jug", "club", {"to": "ally"}), "item_dropped",
		"a dropped own item is on the ground — pick it up first")


# ==================================================== serialization & honesty

func test_batch_d_fields_serialize_only_when_set() -> void:
	# The compat pin: a batch-D-free fight carries none of the new keys.
	var sim: CombatSim = make_sim(6161)
	add_party(sim, "a", [0, 0])
	add_elite(sim, "e", [1, 0])
	declare(sim, "a", attack_action("crushed", 2, "e", "torso"))
	advance(sim)
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		var c: Dictionary = dict["combatants"][id]
		assert_false(c.has("conceal"), "no 'conceal' key on a camo-free combatant (%s)" % id)
		assert_false(c.has("channeling"), "no 'channeling' key on a channel-free combatant (%s)" % id)
		assert_false(c.has("held_by"), "no 'held_by' key on an unheld combatant (%s)" % id)
	assert_false((dict.get("hype", {}) as Dictionary).has("surge"),
		"no 'surge' key on a surge-free session")


func test_batch_d_determinism_same_log_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(6162)
		add_party(sim, "mage", [0, 0])
		add_party(sim, "face", [0, 5], {"camera_call_stacks": 1})
		add_party(sim, "star", [2, 0])
		add_party(sim, "tk", [1, -1])
		add_party(sim, "jug", [0, 1], {"items": [{"key": "knife", "damage_type": "bleeding", "damage_amount": 2}]})
		add_elite(sim, "e1", [4, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
		add_elite(sim, "e2", [5, 0])
		apply_cond(sim, "e1", "torso", "bleeding", 1)
		declare(sim, "face", {"kind": "skill", "key": "play_to_the_camera", "level": 2})
		ball_declare(sim, "mage", "poison_ball", [4, 0])
		grip_declare(sim, "tk", "e2", 1)
		juggle_declare(sim, "jug", "knife", {"to": "mage"})
		advance(sim)
		vibe_declare(sim, "star", "e1", "fear")
		sustain_declare(sim, "tk", {"drag_to": [6, 0]})
		advance(sim, 11)  # the ball windup + the surge expiry + a Clock reset
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash across the whole batch")
