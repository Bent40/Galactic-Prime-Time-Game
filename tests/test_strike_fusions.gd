extends SimTestBase
## Tier-2 wave 3 — the strike fusions (docs/design/tier2-rungs-proposal.md
## S2/S3/S4, BLESSED owner 2026-08-18):
##   S2 predators_arc (fused_leap_finisher) — the leap + the ADAPTIVE landing
##      strike (rear-arc + Exposed -> Head with the bypass + cinematic_kill;
##      otherwise the torso Bleed), the ruling-#4 chain seat ("chain_as":
##      counts as Pounce for Slip Through's gate) and the S2-b chain-open
##      (one movement forfeit... no — one landed arc opens Slip Through onto
##      ANY adjacent target via the serialized chain_open_key marker).
##   S3 earthbreaker (state_forked_strike) — one declare forked at resolution
##      (standing -> slam + knock Prone; downed -> the execution payload with
##      the Torso Shock T3), the S3-b FORCE rung (R14 gate, no bypass), the
##      S3-c close (leap plumbing), the S3-d tremor rider (shockwave-shaped,
##      centered on the target, victim + allies excluded), and the alias
##      (counts as Overhead Slam for Shockwave — whose cone still excludes
##      the arc's victim through last_action_target).
##   S4 vivisection (fused_arc_flurry) — the fused many-parts/many-targets
##      flurry with per-row G8 amounts, the PER-HIT tier advance (the all-3
##      gate DROPPED — contrast-pinned against thousand_cuts), and the S4-c
##      Bleed-T2 wounds.
## Plus: chain-alias rejections (cross-alias included), serialization
## only-when-set + round-trip mid-chain-open, determinism, twin-rng (the
## fusions' own paths consume no rng). All magnitudes PLACEHOLDER (R14).


## A non-dodging Elite (Mind 0: no reads; no dodge_threshold: no dodge
## stream). `extra` merges over the spec (size, parts, position, traits).
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


## A small Mob (tremor / shockwave fodder): torso + one leg.
func add_mob(sim: CombatSim, id: String, pos: Array) -> void:
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "category": "Mob", "size": "Medium",
		"team": "enemies", "position": pos,
		"traits": {"physique": 2, "reflexes": 1, "mind": 1, "charm": 1},
		"body_parts": [
			{"key": "torso", "hp": 10, "lethal": true},
			{"key": "left_leg", "hp": 6, "lethal": false},
		],
	}})


func add_party(sim: CombatSim, id: String, pos: Array, physique: int = 3) -> void:
	add_human(sim, id, {"team": "party", "position": pos,
		"traits": {"physique": physique, "reflexes": 3, "mind": 3, "charm": 3}})


func set_prone(sim: CombatSim, id: String) -> void:
	sim.apply_command({"type": "set_status", "target": id, "status": "prone", "value": true})


func apply_cond(sim: CombatSim, target: String, part: String, condition: String, tier: int) -> Array[Dictionary]:
	return sim.apply_command({"type": "apply_condition", "target": target,
		"part": part, "condition": condition, "tier": tier})


func arc_declare(sim: CombatSim, actor: String, target: String, leap_to: Array, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "predators_arc", "level": level,
		"leap_to": leap_to, "targets": [{"id": target, "part": "torso"}]})


func quake_declare(sim: CombatSim, actor: String, target: String, part: String = "torso", level: int = 1, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "earthbreaker", "level": level,
		"targets": [{"id": target, "part": part}]}
	action.merge(extra, true)
	return declare(sim, actor, action)


func shred_declare(sim: CombatSim, actor: String, rows: Array, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "vivisection", "level": level,
		"targets": rows})


# =========================================== S2 predators_arc (the fused leap)

func test_arc_rear_exposed_head_kill_end_to_end() -> void:
	var sim: CombatSim = make_sim(9101)
	add_party(sim, "sasha", [0, 0])
	# prey stages facing W (toward sasha) — the rear arc is the E side.
	add_elite(sim, "prey", [3, 0], {"body_parts": [
		{"key": "head", "hp": 5, "lethal": true},
		{"key": "torso", "hp": 50, "lethal": true},
		{"key": "left_leg", "hp": 50, "lethal": false},
		{"key": "right_leg", "hp": 50, "lethal": false},
	]})
	set_prone(sim, "prey")  # Prone -> Exposed: the opening is real
	var declared: Array[Dictionary] = arc_declare(sim, "sasha", "prey", [4, 0])
	assert_true(bool(assert_event(declared, "action_declared", "the arc declares").get("windup", false)),
		"a cost-2 windup, pounce's own economy")
	var ev: Array[Dictionary] = advance(sim, 3)
	var sasha: CombatantState = sim.combatants["sasha"]
	var prey: CombatantState = sim.combatants["prey"]
	var leap: Dictionary = assert_event(ev, "predators_arc_leap", "the leap is its own attributed beat")
	assert_eq(leap.get("to", []), [4, 0], "landed on the declared rear hex")
	assert_eq(sasha.position, Vector2i(4, 0), "movement absorbed into the one declare")
	assert_true(Stealth.is_behind(prey, sasha.position), "precondition: the landing IS the rear arc (R30)")
	var adapt: Dictionary = assert_event(ev, "predators_arc_adapt", "the strike adapts, attributed")
	assert_eq(String(adapt.get("mode", "")), "head_finisher", "Exposed + rear arc -> the Head finisher")
	assert_eq(int(prey.parts["head"]["hp"]), 0, "5 Head Bleed: Force 5+1 − Robustness 1 = 5 (5 → 0)")
	var died: Dictionary = assert_event(ev, "combatant_died", "Head → 0 is the normal lethal path")
	assert_eq(String(died.get("killer", "")), "sasha", "the kill is attributed")
	var cine: Dictionary = assert_event(ev, "cinematic_kill", "the cinematic beat fires off the arc")
	assert_eq(String(cine.get("actor", "")), "sasha", "attributed to the killer")
	assert_eq(String(cine.get("skill_key", "")), "predators_arc", "carrying the sim key")
	assert_eq(int(cine.get("spectacle_points", 0)), 45, "authored payout (PLACEHOLDER R14)")
	assert_true(int(sim.hype.ledger.get("sasha", 0)) >= 45,
		"scored through the existing HypeEngine spectacle_points hook")


func test_arc_front_arc_and_unexposed_fall_back_to_torso() -> void:
	# Front arc, Exposed: the opening is real but the angle is wrong.
	var sim: CombatSim = make_sim(9102)
	add_party(sim, "sasha", [0, 0])
	add_elite(sim, "prey", [3, 0])
	set_prone(sim, "prey")
	arc_declare(sim, "sasha", "prey", [2, 0])
	var ev: Array[Dictionary] = advance(sim, 3)
	var prey: CombatantState = sim.combatants["prey"]
	assert_eq(String(assert_event(ev, "predators_arc_adapt", "adapts").get("mode", "")),
		"torso_bleed", "front arc -> pounce's torso Bleed, not the finisher")
	assert_eq(int(prey.parts["torso"]["hp"]), 44, "6 torso Bleed: Force 6+1 − 1 = 6 (50 → 44)")
	assert_eq(prey.condition_tier("torso", "bleeding"), 1, "the Bleed rides the landed hit")
	assert_eq(int(prey.parts["head"]["hp"]), 50, "the head was never touched")
	assert_no_event(ev, "cinematic_kill", "no kill, no beat")
	# Rear arc, NOT Exposed: the angle is right but there is no opening.
	var sim2: CombatSim = make_sim(9103)
	add_party(sim2, "sasha", [0, 0])
	add_elite(sim2, "prey", [3, 0])
	arc_declare(sim2, "sasha", "prey", [4, 0])
	var ev2: Array[Dictionary] = advance(sim2, 3)
	assert_eq(String(assert_event(ev2, "predators_arc_adapt", "adapts").get("mode", "")),
		"torso_bleed", "rear arc without Exposure -> the torso Bleed")
	assert_eq(int((sim2.combatants["prey"] as CombatantState).parts["head"]["hp"]), 50, "head untouched")


func test_arc_chain_alias_slip_through_accepts_shockwave_does_not() -> void:
	var sim: CombatSim = make_sim(9104)
	add_party(sim, "sasha", [0, 0])
	add_elite(sim, "prey", [3, 0])
	# Before anything: slip_through rejects (no chain at all).
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": "prey"}]}), "prime_unmet", "slip_through without an opener rejects")
	arc_declare(sim, "sasha", "prey", [2, 0])
	advance(sim, 3)
	var sasha: CombatantState = sim.combatants["sasha"]
	assert_eq(sasha.last_action_key, "predators_arc", "the REAL key is recorded — the alias never lies")
	# Cross-alias control: the arc counts as Pounce, never as Overhead Slam.
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "shockwave", "level": 1,
		"area_shape": {"kind": "cone", "toward": [1, 0]}}), "prime_unmet",
		"shockwave does NOT accept Predator's Arc (the seat is per-pair, ruling #4)")
	# The blessed seat: Slip Through accepts the arc as Pounce (same target).
	var slipped: Array[Dictionary] = declare(sim, "sasha", {"kind": "skill", "key": "slip_through",
		"level": 1, "targets": [{"id": "prey"}]})
	assert_event(slipped, "action_declared", "Slip Through chains off the arc — the L1 chain seat")
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "slip_through_reposition", "and resolves as the real slip")
	assert_true((sim.combatants["prey"] as CombatantState).exposed_cache, "Exposed rider intact")
	# A plain unrelated action clears the chain (the last_action_key rule).
	var sim2: CombatSim = make_sim(9105)
	add_party(sim2, "sasha", [0, 0])
	add_elite(sim2, "prey", [1, 0])
	declare(sim2, "sasha", attack_action("crushed", 2, "prey", "torso"))
	advance(sim2)
	assert_rejected(declare(sim2, "sasha", {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": "prey"}]}), "prime_unmet", "a plain attack is no opener")


func test_arc_l2_chain_opens_slip_onto_a_second_target() -> void:
	var sim: CombatSim = make_sim(9106)
	add_party(sim, "sasha", [0, 0])
	add_elite(sim, "prey", [3, 0])
	add_elite(sim, "prey2", [2, 1])  # adjacent to the [2,0] landing
	arc_declare(sim, "sasha", "prey", [2, 0], 2)
	var ev: Array[Dictionary] = advance(sim, 3)
	var sasha: CombatantState = sim.combatants["sasha"]
	assert_event(ev, "predators_arc_chain_open", "the L2 chain-open is an attributed beat")
	assert_eq(sasha.chain_open_key, "predators_arc", "the marker is live")
	assert_true((sasha.to_dict() as Dictionary).has("chain_open_key"),
		"serialized while live (only-when-set)")
	# The takedown feeds the next takedown: Slip Through onto the ADJACENT
	# second target — the same-target half is waived by the open.
	var slipped: Array[Dictionary] = declare(sim, "sasha", {"kind": "skill", "key": "slip_through",
		"level": 1, "targets": [{"id": "prey2"}]})
	assert_event(slipped, "action_declared", "Slip Through opens onto the second target (S2-b)")
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "slip_through_reposition", "and resolves against it")
	assert_true((sim.combatants["prey2"] as CombatantState).exposed_cache, "second target Exposed")
	assert_eq(sasha.chain_open_key, "", "the open is consumed — a different action resolved")
	assert_false((sasha.to_dict() as Dictionary).has("chain_open_key"), "and the key is gone again")
	# Contrast: at L1 the chain stays same-target only.
	var sim2: CombatSim = make_sim(9107)
	add_party(sim2, "sasha", [0, 0])
	add_elite(sim2, "prey", [3, 0])
	add_elite(sim2, "prey2", [2, 1])
	arc_declare(sim2, "sasha", "prey", [2, 0], 1)
	var ev3: Array[Dictionary] = advance(sim2, 3)
	assert_no_event(ev3, "predators_arc_chain_open", "no chain-open below L2")
	assert_rejected(declare(sim2, "sasha", {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": "prey2"}]}), "prime_unmet", "L1 keeps the same-target gate")


func test_arc_declare_gates_are_pounce_shaped() -> void:
	var sim: CombatSim = make_sim(9108)
	add_party(sim, "sasha", [0, 0])
	add_elite(sim, "prey", [7, 0])  # inside the leap envelope (6+1) — the leap gates fire, not plain reach
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "predators_arc", "level": 1,
		"targets": [{"id": "prey", "part": "left_leg"}]}), "torso_only",
		"the declared row is pounce's torso — the head half is a RESOLUTION adaptation")
	assert_rejected(arc_declare(sim, "sasha", "prey", [8, 0]), "leap_out_of_range",
		"8 hexes beats the L1 leap 6 (PLACEHOLDER R14)")
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "predators_arc", "level": 1,
		"targets": [{"id": "prey", "part": "torso"}]}), "leap_required",
		"a distant declare must name its landing")


# ========================================= S3 earthbreaker (the forked strike)

func test_earthbreaker_standing_fork_slams_and_prones() -> void:
	var sim: CombatSim = make_sim(9201)
	add_party(sim, "bruiser", [0, 0])
	add_elite(sim, "foe", [1, 0])
	var declared: Array[Dictionary] = quake_declare(sim, "bruiser", "foe")
	assert_event(declared, "action_declared", "the arc declares (cost-2 windup)")
	assert_true((sim.combatants["bruiser"] as CombatantState).exposed_cache,
		"Exposed during the wind-up (S3-a, the committed_strike rider)")
	var ev: Array[Dictionary] = advance(sim, 3)
	var foe: CombatantState = sim.combatants["foe"]
	assert_eq(String(assert_event(ev, "earthbreaker_fork", "the fork is attributed").get("mode", "")),
		"slam", "a standing target takes the slam face")
	assert_eq(int(foe.parts["torso"]["hp"]), 43, "7 Crush: Force 7+1 − Robustness 1 = 7 (50 → 43)")
	assert_eq(foe.condition_tier("torso", "crushed"), 1, "the landed Crush seeds Crushed T1 (R4)")
	assert_event(ev, "knocked_prone", "and knocks the standing target Prone")
	assert_true(bool(foe.statuses.get("prone", false)), "Prone (Exposed) — the opening for the next arc")
	assert_eq(foe.shock, 0, "no execution rider on the slam face")


func test_earthbreaker_downed_fork_executes() -> void:
	var sim: CombatSim = make_sim(9202)
	add_party(sim, "bruiser", [0, 0])
	add_elite(sim, "foe", [1, 0])
	set_prone(sim, "foe")
	quake_declare(sim, "bruiser", "foe")
	var ev: Array[Dictionary] = advance(sim, 3)
	var foe: CombatantState = sim.combatants["foe"]
	assert_eq(String(assert_event(ev, "earthbreaker_fork", "forks").get("mode", "")),
		"execution", "an already-downed target takes the execution payload")
	assert_eq(int(foe.parts["torso"]["hp"]), 42, "8 Crush: Force 8+1 − 1 = 8 (50 → 42)")
	assert_event(ev, "earthbreaker_shock", "the Torso execution rider is attributed")
	assert_eq(foe.shock, 3, "Torso → Shock T3 (Faint) — execution's authored core")
	assert_no_event(ev, "knocked_prone", "already down — nothing to knock")
	# The Head face: the lethal path, and deliberately NO cinematic beat.
	var sim2: CombatSim = make_sim(9203)
	add_party(sim2, "bruiser", [0, 0])
	add_elite(sim2, "foe", [1, 0], {"body_parts": [
		{"key": "head", "hp": 8, "lethal": true},
		{"key": "torso", "hp": 50, "lethal": true},
		{"key": "left_leg", "hp": 50, "lethal": false},
	]})
	set_prone(sim2, "foe")
	quake_declare(sim2, "bruiser", "foe", "head")
	var ev2: Array[Dictionary] = advance(sim2, 3)
	var died: Dictionary = assert_event(ev2, "combatant_died", "Head → 0 on the downed fork")
	assert_eq(String(died.get("killer", "")), "bruiser", "attributed")
	assert_no_event(ev2, "cinematic_kill", "the cinematic beat stays decapitate's / the arc's")


func test_earthbreaker_alias_shockwave_accepts_and_excludes_the_victim() -> void:
	var sim: CombatSim = make_sim(9204)
	add_party(sim, "bruiser", [0, 0])
	add_elite(sim, "foe", [1, 0])
	add_mob(sim, "m1", [2, 0])
	quake_declare(sim, "bruiser", "foe")
	advance(sim, 3)
	# Cross-alias control first: Earthbreaker is not Pounce.
	assert_rejected(declare(sim, "bruiser", {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": "foe"}]}), "prime_unmet", "slip_through does NOT accept Earthbreaker")
	var foe_torso_before: int = int((sim.combatants["foe"] as CombatantState).parts["torso"]["hp"])
	var chained: Array[Dictionary] = declare(sim, "bruiser", {"kind": "skill", "key": "shockwave",
		"level": 1, "area_shape": {"kind": "cone", "toward": [1, 0]}})
	assert_event(chained, "action_declared", "Shockwave chains off Earthbreaker — the L1 chain seat")
	var ev: Array[Dictionary] = advance(sim)
	var damage_rows: Array[Dictionary] = events_of(ev, "damage_applied")
	assert_eq(damage_rows.size(), 1, "one wave round — the slam victim is EXCLUDED from the cone")
	assert_eq(String(damage_rows[0].get("combatant", "")), "m1", "the mob takes the wave")
	assert_event(ev, "knocked_back", "with the 1-hex knockback")
	assert_event(ev, "forced_action_triggered", "and the Mob Forced Body")
	assert_eq(int((sim.combatants["foe"] as CombatantState).parts["torso"]["hp"]), foe_torso_before,
		"the downed victim stays where the finisher needs them — untouched by the wave")


func test_earthbreaker_l2_is_force_through_the_r14_gate_not_bypass() -> void:
	# A high-robustness target: physique 8 -> Robustness 4. Force must beat
	# the WHOLE gate — nothing is bypassed (row 42 re-expressed, default #2).
	var sim: CombatSim = make_sim(9205)
	add_party(sim, "bruiser", [0, 0])
	add_elite(sim, "tank", [1, 0], {"traits": {"physique": 8, "reflexes": 3, "mind": 0, "charm": 1}})
	quake_declare(sim, "bruiser", "tank", "torso", 2)
	advance(sim, 3)
	assert_eq(int((sim.combatants["tank"] as CombatantState).parts["torso"]["hp"]), 42,
		"L2 slam: Force 11+1 − Robustness 4 = 8 — the full gate applied (50 → 42)")
	var sim2: CombatSim = make_sim(9206)
	add_party(sim2, "bruiser", [0, 0])
	add_elite(sim2, "tank", [1, 0], {"traits": {"physique": 8, "reflexes": 3, "mind": 0, "charm": 1}})
	quake_declare(sim2, "bruiser", "tank", "torso", 1)
	advance(sim2, 3)
	assert_eq(int((sim2.combatants["tank"] as CombatantState).parts["torso"]["hp"]), 46,
		"L1 contrast: Force 7+1 − 4 = 4 — the rung added FORCE, the gate never moved")
	for lv: int in range(1, 5):
		var spec: Dictionary = SkillBook.mechanics("earthbreaker", lv)
		assert_false(spec.has("resistance_bypass") or spec.has("ignores_resistance"),
			"no resistance-bypass vocabulary anywhere on the spec (L%d)" % lv)


func test_earthbreaker_l3_close_absorbs_the_approach() -> void:
	var sim: CombatSim = make_sim(9207)
	add_party(sim, "bruiser", [0, 0])
	add_elite(sim, "foe", [3, 0])
	# The gates: no close below L3; a distant declare without one is honest.
	assert_rejected(quake_declare(sim, "bruiser", "foe", "torso", 1, {"close_to": [2, 0]}),
		"close_not_available", "the close is the L3 rung")
	assert_rejected(quake_declare(sim, "bruiser", "foe", "torso", 3), "out_of_range",
		"no close_to declared = reach stays 1")
	assert_rejected(quake_declare(sim, "bruiser", "foe", "torso", 3, {"close_to": [1, 0]}),
		"landing_not_adjacent", "the close must END the arc in reach")
	quake_declare(sim, "bruiser", "foe", "torso", 3, {"close_to": [2, 0]})
	var ev: Array[Dictionary] = advance(sim, 3)
	assert_eq(assert_event(ev, "earthbreaker_close", "the absorbed approach is attributed").get("to", []),
		[2, 0], "closed onto the declared hex")
	assert_eq((sim.combatants["bruiser"] as CombatantState).position, Vector2i(2, 0), "movement absorbed")
	assert_eq(int((sim.combatants["foe"] as CombatantState).parts["torso"]["hp"]), 39,
		"and the L3 slam lands from it: Force 11+1 − 1 = 11 (50 → 39)")


func test_earthbreaker_l4_tremor_rider() -> void:
	var sim: CombatSim = make_sim(9208)
	add_party(sim, "bruiser", [0, 0])
	add_party(sim, "buddy", [1, 1])  # ally INSIDE the radius — never caught
	add_elite(sim, "foe", [1, 0])
	add_mob(sim, "m1", [2, 0])       # 1 hex from the victim — caught
	add_mob(sim, "m2", [5, 0])       # 4 hexes — outside the radius-3 pulse
	set_prone(sim, "foe")
	quake_declare(sim, "bruiser", "foe", "torso", 4)
	var ev: Array[Dictionary] = advance(sim, 3)
	var tremor: Dictionary = assert_event(ev, "earthbreaker_tremor", "the free tremor fires (S3-d)")
	assert_eq(String(tremor.get("actor", "")), "bruiser", "attributed to the arc's actor")
	assert_eq(String(tremor.get("center", "")), "foe", "centered on the target — the row's words")
	assert_eq(tremor.get("targets", []), ["m1"], "victim excluded, ally excluded, m2 out of radius")
	var m1: CombatantState = sim.combatants["m1"]
	assert_eq(int(m1.parts["left_leg"]["hp"]), 5, "the ground answer: Force 1+1 − 1 = 1 on the leg line")
	var knock: Dictionary = assert_event(ev, "knocked_back", "the connected pulse shoves")
	assert_eq(String(knock.get("by", "")), "foe", "away from the CENTER, not the actor")
	assert_eq(knock.get("to", []), [3, 0], "one hex outward")
	assert_event(ev, "forced_action_triggered", "Mob Forced Body — the existing rng stream")
	assert_eq(int((sim.combatants["buddy"] as CombatantState).parts["torso"]["hp"]),
		int((sim.combatants["buddy"] as CombatantState).max_hp("torso")), "the ally is never caught")
	assert_eq(int((sim.combatants["m2"] as CombatantState).parts["left_leg"]["hp"]), 6, "out of radius")
	# The victim took ONLY the execution payload — the pulse never re-hits it.
	assert_eq(int((sim.combatants["foe"] as CombatantState).parts["torso"]["hp"]), 38,
		"exec 12+1−1 = 12 (50 → 38) and nothing more")
	# Below L4 there is no tremor.
	var sim2: CombatSim = make_sim(9209)
	add_party(sim2, "bruiser", [0, 0])
	add_elite(sim2, "foe", [1, 0])
	add_mob(sim2, "m1", [2, 0])
	quake_declare(sim2, "bruiser", "foe")
	assert_no_event(advance(sim2, 3), "earthbreaker_tremor", "the tremor is the L4 rung")


# ========================================== S4 vivisection (the fused flurry)

func test_vivisection_flurry_across_two_targets_g8_amounts() -> void:
	var sim: CombatSim = make_sim(9301)
	add_party(sim, "slicer", [0, 0])
	add_elite(sim, "foe1", [1, 0])
	add_elite(sim, "foe2", [0, 1])
	shred_declare(sim, "slicer", [
		{"id": "foe1", "part": "left_arm"}, {"id": "foe1", "part": "left_leg"},
		{"id": "foe2", "part": "torso"},
	])
	var ev: Array[Dictionary] = advance(sim, 4)
	var foe1: CombatantState = sim.combatants["foe1"]
	var foe2: CombatantState = sim.combatants["foe2"]
	assert_eq(events_of(ev, "damage_applied").size(), 3, "one cut per declared row")
	assert_eq(int(foe1.parts["left_arm"]["hp"]), 46, "limb row: Force 4+1 − 1 = 4 (G8 limb value)")
	assert_eq(int(foe1.parts["left_leg"]["hp"]), 46, "limb rows share the limb value")
	assert_eq(int(foe2.parts["torso"]["hp"]), 46,
		"a torso row on a flurry SPANNING targets takes the pair value 4 (G8 inherited)")
	assert_eq(foe1.condition_tier("left_arm", "bleeding"), 1, "every cut bleeds")
	assert_eq(foe2.condition_tier("torso", "bleeding"), 1, "on every body")
	# Single-target contrast: the torso keeps its full single-target value.
	var sim2: CombatSim = make_sim(9302)
	add_party(sim2, "slicer", [0, 0])
	add_elite(sim2, "foe1", [1, 0])
	shred_declare(sim2, "slicer", [
		{"id": "foe1", "part": "torso"}, {"id": "foe1", "part": "left_arm"},
		{"id": "foe1", "part": "right_arm"},
	])
	advance(sim2, 4)
	assert_eq(int((sim2.combatants["foe1"] as CombatantState).parts["torso"]["hp"]), 44,
		"single-target torso row: Force 6+1 − 1 = 6 (G8 torso value)")


func test_vivisection_per_hit_tier_advance_no_all3_gate() -> void:
	# ONE pre-bleeding part out of three — thousand_cuts' all-3 gate would
	# pay nothing here; the fusion advances that one part per its own hit.
	var sim: CombatSim = make_sim(9303)
	add_party(sim, "slicer", [0, 0])
	add_elite(sim, "foe1", [1, 0])
	apply_cond(sim, "foe1", "left_arm", "bleeding", 1)
	shred_declare(sim, "slicer", [
		{"id": "foe1", "part": "left_arm"}, {"id": "foe1", "part": "left_leg"},
		{"id": "foe1", "part": "torso"},
	])
	var ev: Array[Dictionary] = advance(sim, 4)
	var foe1: CombatantState = sim.combatants["foe1"]
	var advances: Array[Dictionary] = events_of(ev, "vivisection_tier_advance")
	assert_eq(advances.size(), 1, "exactly the pre-bleeding part advanced — per hit, no all-3 gate")
	assert_eq(String(advances[0].get("part", "")), "left_arm", "the right part")
	assert_eq(foe1.condition_tier("left_arm", "bleeding"), 3,
		"T1 → T2 (R4 reapply) → T3 (the fused rider, the thousand_cuts ladder made per-hit)")
	assert_eq(foe1.condition_tier("left_leg", "bleeding"), 1, "fresh parts just bleed at L1")
	assert_eq(foe1.condition_tier("torso", "bleeding"), 1, "fresh parts just bleed at L1")
	# The CONTRAST pin, run for real: the same one-of-three staging through
	# thousand_cuts pays nothing (its authored payoff needs ALL 3 pre-bleeding).
	var sim2: CombatSim = make_sim(9304)
	add_party(sim2, "duelist", [0, 0])
	add_elite(sim2, "mark", [1, 0], {"size": "Medium"})
	apply_cond(sim2, "mark", "left_arm", "bleeding", 1)
	declare(sim2, "duelist", {"kind": "skill", "key": "feint", "level": 1,
		"attack_range": 1, "targets": [{"id": "mark", "part": "torso"}]})
	advance(sim2)
	declare(sim2, "duelist", {"kind": "skill", "key": "pressure_strike", "level": 1,
		"attack_range": 1, "targets": [{"id": "mark", "part": "left_leg"}]})
	advance(sim2, 3)
	declare(sim2, "duelist", {"kind": "skill", "key": "thousand_cuts", "level": 1,
		"targets": [{"id": "mark", "part": "left_arm"}, {"id": "mark", "part": "torso"},
			{"id": "mark", "part": "right_arm"}]})
	var ev2: Array[Dictionary] = advance(sim2, 3)
	assert_no_event(ev2, "thousand_cuts_tier_advance", "thousand_cuts keeps its all-3 gate")
	assert_eq((sim2.combatants["mark"] as CombatantState).condition_tier("left_arm", "bleeding"), 2,
		"its one pre-bled part gets only the R4 reapply (T2) — the fusion's T3 is the dropped gate")


func test_vivisection_l3_wounds_apply_bleed_t2() -> void:
	var sim: CombatSim = make_sim(9305)
	add_party(sim, "slicer", [0, 0])
	add_elite(sim, "foe1", [1, 0])
	apply_cond(sim, "foe1", "right_arm", "bleeding", 1)
	shred_declare(sim, "slicer", [
		{"id": "foe1", "part": "left_arm"}, {"id": "foe1", "part": "torso"},
		{"id": "foe1", "part": "right_arm"},
	], 3)
	advance(sim, 4)
	var foe1: CombatantState = sim.combatants["foe1"]
	assert_eq(int(foe1.parts["left_arm"]["hp"]), 45, "L3 limb rise: Force 5+1 − 1 = 5 (row 80's +1)")
	assert_eq(int(foe1.parts["torso"]["hp"]), 42, "L3 torso rise: Force 8+1 − 1 = 8 (row 80's +2)")
	assert_eq(foe1.condition_tier("left_arm", "bleeding"), 2, "a FRESH wound applies Bleed T2 instead")
	assert_eq(foe1.condition_tier("torso", "bleeding"), 2, "on every fresh part")
	assert_eq(foe1.condition_tier("right_arm", "bleeding"), 3,
		"a pre-bleeding part rides the reapply + per-hit rider ladder (T1 → T3), not the T2 floor")


func test_vivisection_declare_gates() -> void:
	var sim: CombatSim = make_sim(9306)
	add_party(sim, "slicer", [0, 0])
	add_elite(sim, "foe1", [1, 0])
	add_elite(sim, "foe2", [0, 1])
	add_elite(sim, "foe3", [-1, 0])
	add_elite(sim, "far", [5, 0])
	assert_rejected(shred_declare(sim, "slicer", [
		{"id": "foe1", "part": "left_arm"}, {"id": "foe1", "part": "torso"}]),
		"parts_out_of_band", "two rows are below the flurry's band (3..4 at L1)")
	assert_rejected(shred_declare(sim, "slicer", [
		{"id": "foe1", "part": "left_arm"}, {"id": "foe1", "part": "right_arm"},
		{"id": "foe1", "part": "left_leg"}, {"id": "foe1", "part": "right_leg"},
		{"id": "foe1", "part": "torso"}]),
		"parts_out_of_band", "five rows beat the L1 cap (parts_max 4)")
	assert_rejected(shred_declare(sim, "slicer", [
		{"id": "foe1", "part": "torso"}, {"id": "foe1", "part": "torso"},
		{"id": "foe1", "part": "left_arm"}]),
		"distinct_parts_required", "duplicate (target, part) rows are not distinct wounds")
	assert_rejected(shred_declare(sim, "slicer", [
		{"id": "foe1", "part": "torso"}, {"id": "foe2", "part": "torso"},
		{"id": "foe3", "part": "torso"}]),
		"too_many_targets", "three targets need the L2 wrap (targets_max 2 at L1)")
	assert_event(shred_declare(sim, "slicer", [
		{"id": "foe1", "part": "torso"}, {"id": "foe2", "part": "torso"},
		{"id": "foe3", "part": "torso"}], 2), "action_declared",
		"the L2 180-degree wrap takes three adjacent targets")
	var sim2: CombatSim = make_sim(9307)
	add_party(sim2, "slicer", [0, 0])
	add_elite(sim2, "foe1", [1, 0])
	add_elite(sim2, "far", [5, 0])
	assert_rejected(shred_declare(sim2, "slicer", [
		{"id": "foe1", "part": "left_arm"}, {"id": "foe1", "part": "torso"},
		{"id": "far", "part": "torso"}]),
		"out_of_range", "every row must be in reach — adjacency is the arc")
	assert_rejected(shred_declare(sim2, "slicer", [
		{"id": "foe1", "part": "head"}, {"id": "foe1", "part": "torso"},
		{"id": "foe1", "part": "left_arm"}]),
		"head_not_targetable", "no bypass on the flurry — the head gate holds")


# ============================================ serialization & determinism

func test_fusions_serialize_only_when_set() -> void:
	# The compat pin: a fusion-free fight carries none of the wave's new keys.
	var sim: CombatSim = make_sim(9401)
	add_party(sim, "a", [0, 0])
	add_elite(sim, "e", [1, 0])
	declare(sim, "a", attack_action("crushed", 2, "e", "torso"))
	advance(sim)
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		var c: Dictionary = dict["combatants"][id]
		assert_false(c.has("chain_open_key"), "no 'chain_open_key' on a fusion-free combatant (%s)" % id)


func test_fusions_round_trip_mid_chain_open() -> void:
	var live: CombatSim = make_sim(9402)
	add_party(live, "sasha", [0, 0])
	add_elite(live, "prey", [3, 0])
	add_elite(live, "prey2", [2, 1])
	arc_declare(live, "sasha", "prey", [2, 0], 2)
	advance(live, 3)
	assert_eq((live.combatants["sasha"] as CombatantState).chain_open_key, "predators_arc",
		"precondition: the open is live")
	var restored: CombatSim = CombatSim.from_dict(live.to_dict())
	assert_eq(restored.state_hash(), live.state_hash(), "hash survives the mid-open round-trip")
	assert_eq((restored.combatants["sasha"] as CombatantState).chain_open_key, "predators_arc",
		"the marker round-trips")
	# Both timelines take the opened slip onto the SECOND target identically.
	for sim: CombatSim in [live, restored]:
		assert_event(declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1,
			"targets": [{"id": "prey2"}]}), "action_declared",
			"the restored open still waives the same-target gate")
		advance(sim)
	assert_eq(restored.state_hash(), live.state_hash(), "restore -> replay tail = same hash")


func test_fusions_determinism_same_log_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(9403)
		add_party(sim, "sasha", [0, 0])
		add_party(sim, "bruiser", [0, 6])
		add_party(sim, "slicer", [0, 12])
		add_elite(sim, "prey", [3, 0], {"body_parts": [
			{"key": "head", "hp": 5, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
			{"key": "left_leg", "hp": 50, "lethal": false},
			{"key": "right_leg", "hp": 50, "lethal": false},
		]})
		add_elite(sim, "prey2", [4, 1])
		add_elite(sim, "foe", [1, 6])
		add_mob(sim, "m1", [2, 6])
		add_elite(sim, "vic", [1, 12])
		set_prone(sim, "prey")
		set_prone(sim, "foe")
		arc_declare(sim, "sasha", "prey", [4, 0], 2)          # rear-arc head kill + chain open
		quake_declare(sim, "bruiser", "foe", "torso", 4)      # execution + tremor (m1 Forced Body)
		shred_declare(sim, "slicer", [
			{"id": "vic", "part": "left_arm"}, {"id": "vic", "part": "left_leg"},
			{"id": "vic", "part": "torso"}], 3)               # T2 wounds
		advance(sim, 4)
		declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1,
			"targets": [{"id": "prey2"}]})                    # through the open
		advance(sim, 2)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash across the whole wave")


func test_fusions_twin_rng_no_new_draws() -> void:
	# Twin sims, same seed: twin B additionally resolves a full rear-arc head
	# kill AND a vivisection flurry — adaptive fork, cinematic beat, per-hit
	# tier riders are all rng-free (no Mobs, no dodges, no collapses). The
	# next Forced Body draw must be the SAME stream value in both twins.
	var twin_a: CombatSim = make_sim(9404)
	var twin_b: CombatSim = make_sim(9404)
	for twin: CombatSim in [twin_a, twin_b]:
		add_party(twin, "sasha", [0, 0])
		add_party(twin, "weakling", [7, 0], 2)  # physique 2 — the grapple probe's underdog
		add_elite(twin, "prey", [3, 0], {"body_parts": [
			{"key": "head", "hp": 5, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
			{"key": "left_leg", "hp": 50, "lethal": false},
		]})
		add_elite(twin, "vic", [4, 1])
		add_elite(twin, "eb", [8, 0])
		set_prone(twin, "prey")
	arc_declare(twin_b, "sasha", "prey", [4, 0])
	for twin: CombatSim in [twin_a, twin_b]:
		advance(twin, 3)
	shred_declare(twin_b, "sasha", [
		{"id": "vic", "part": "left_arm"}, {"id": "vic", "part": "left_leg"},
		{"id": "vic", "part": "torso"}])
	for twin: CombatSim in [twin_a, twin_b]:
		advance(twin, 4)
	# The stream probe: an above-weight grapple's Forced Body (physique 2 < 3).
	for twin: CombatSim in [twin_a, twin_b]:
		declare(twin, "weakling", {"kind": "grapple", "target": "eb"})
	var roll_a: int = int(assert_event(advance(twin_a), "forced_action_triggered", "twin A probe").get("roll", -1))
	var roll_b: int = int(assert_event(advance(twin_b), "forced_action_triggered", "twin B probe").get("roll", -2))
	assert_eq(roll_a, roll_b, "identical stream draw — the fusions consumed zero rng")


func test_fusions_stay_out_of_known_keys_with_real_archetypes() -> void:
	var expected: Dictionary = {
		"predators_arc": "fused_leap_finisher",
		"earthbreaker": "state_forked_strike",
		"vivisection": "fused_arc_flurry",
	}
	for key: String in expected:
		assert_false(SkillBook.is_known(key),
			key + ": deliberately not in KNOWN_KEYS (acquisition-gated + keyword pass pending)")
		for lv: int in range(1, 5):
			assert_eq(String(SkillBook.mechanics(key, lv).get("archetype", "")), String(expected[key]),
				"%s L%d carries its real archetype" % [key, lv])
	# The chain seats, pinned at the spec level (ruling #4, authored at L1).
	assert_eq(String(SkillBook.mechanics("predators_arc", 1).get("chain_as", "")), "pounce",
		"Predator's Arc counts as Pounce")
	assert_eq(String(SkillBook.mechanics("earthbreaker", 1).get("chain_as", "")), "overhead_slam",
		"Earthbreaker counts as Overhead Slam")
	assert_eq(String(SkillBook.mechanics("vivisection", 1).get("chain_as", "")), "",
		"Vivisection carries no chain seat — its header authors none")
