extends SimTestBase
## R26 — undodgable attacks: declared, announced, honest (owner 2026-07-25,
## decision #32). The flag is DATA-DRIVEN ("undodgable": true on an ability
## dict or an explosion behavior block, never a hardcoded case) and immune to
## EVERY dodge-shaped escape: the R22 threshold/boss dodge, the dash counters
## ladder, any authored dodge block, AND the R25 AoE-center roller escape — a
## skipped check consumes ZERO rng (twin-RNG proven). Movement is NOT a dodge:
## the R2 windup re-checks (leaving the arc/lane/radius) stay the surviving
## counterplay. Transparency is the rule's other half: the flag rides the
## explosion_telegraph event, view_schedule rows and preview_action per-target
## rows, loudly. First application: the Incinedile valve blasts (phases 2/4/6)
## — SUPERSEDES the R25 valve-counter consequence (a blast-Moment Tactical
## Roll no longer escapes the KO).


func roll_action(to: Array, level: int = 1) -> Dictionary:
	return {"kind": "skill", "key": "tactical_roll", "level": level, "to": to}


func add_enemy(sim: CombatSim, id: String, enemy_key: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": enemy_key,
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## The seeded Incinedile trait block minus the dodge threshold (the
## test_incinedile spec choice) — staged breaches never consume the AI stream.
func traits_without_dodge() -> Dictionary:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var boss_traits: Dictionary = (e.get("traits", {}) as Dictionary).duplicate(true)
			boss_traits.erase("dodge_threshold")
			boss_traits.erase("dodge_threshold_note")
			return boss_traits
	return {}


## The seeded phases with the R26 flag STRIPPED from every explosion block —
## the synthetic DODGABLE area (the mechanism regression's control fixture).
func dodgable_valve_phases() -> Array:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var phases: Array = (e.get("phases", []) as Array).duplicate(true)
			for phase: Variant in phases:
				var behavior: Dictionary = (phase as Dictionary).get("behavior", {})
				if behavior.has("explosion"):
					(behavior.get("explosion") as Dictionary).erase("undodgable")
			return phases
	return []


## The seeded abilities with "undodgable": true set on the dash — a MODIFIED
## SPEC, not the valve: the flag must work on any ability dict (data-driven).
func undodgable_dash_abilities() -> Array:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var abilities: Array = (e.get("abilities", []) as Array).duplicate(true)
			for a: Variant in abilities:
				if String((a as Dictionary).get("key", "")) == "dash":
					(a as Dictionary)["undodgable"] = true
			return abilities
	return []


## Canonical Valve-I entry (test_explosion_beats pattern): h burst-breaches,
## then drives the network 50 -> 35 — phase 2 just entered.
func enter_valve_one(sim: CombatSim) -> Array[Dictionary]:
	declare(sim, "h", attack_action("crushed", 10, "boss", "right_hand"))
	advance(sim, 1)
	declare(sim, "h", attack_action("crushed", 17, "boss", "network"))
	return advance(sim, 1)


func combatant(sim: CombatSim, id: String) -> CombatantState:
	return sim.combatants.get(id)


# ----------------------------------------------------- the valve (first application)

func test_valve_blast_catches_a_blast_moment_roller() -> void:
	# R26 supersedes the R25 valve-counter consequence: the seeded valve is
	# undodgable, so the blast-Moment roll that USED to escape the KO no longer
	# does — the roller is caught like anyone else inside the radius.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	enter_valve_one(sim)
	var telegraph_events: Array[Dictionary] = ai_decide(sim, "boss")
	var telegraph: Dictionary = assert_event(telegraph_events, "explosion_telegraph",
		"the valve telegraphs")
	assert_true(bool(telegraph.get("undodgable", false)),
		"R26 transparency: the telegraph DECLARES the blast undodgable on the windup")
	advance(sim, 1)
	ai_decide(sim, "boss")  # hold 1
	advance(sim, 1)
	ai_decide(sim, "boss")  # hold 2
	advance(sim, 1)
	# ON the blast Moment: h rolls to [0, 2] — inside radius 5, not the center.
	# Pre-R26 this escaped the KO from anywhere in the radius; no longer.
	assert_event(declare(sim, "h", roll_action([0, 2])), "tactical_roll", "h rolls as the valve blows")
	assert_true(combatant(sim, "h").rolled_this_window, "the R25 marker is live")
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	var blast: Dictionary = assert_event(blast_events, "explosion_blast", "the blast resolved")
	assert_true(bool(blast.get("undodgable", false)), "the blast event carries the flag too")
	assert_no_event(blast_events, "blast_missed_roller",
		"the old roller escape is GONE — an undodgable area skips the R25 check")
	var knockout: Dictionary = assert_event(blast_events, "explosion_knockout",
		"the roller is caught — the KO applies")
	assert_eq(String(knockout.get("combatant", "")), "h", "and it names the roller")
	assert_true(combatant(sim, "h").is_helpless(sim.clock.tick), "h is down for 2 Clocks")


func test_synthetic_dodgable_area_still_honors_the_aoe_center_rule() -> void:
	# The mechanism regression: identical staging, but the explosion block's
	# flag stripped — the ONLY delta is the data, and the roller escapes again.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge(),
		"phases": dodgable_valve_phases()})
	enter_valve_one(sim)
	var telegraph: Dictionary = assert_event(ai_decide(sim, "boss"), "explosion_telegraph",
		"the dodgable valve telegraphs")
	assert_false(bool(telegraph.get("undodgable", true)),
		"no flag on the stripped block — the telegraph says so honestly")
	advance(sim, 1)
	ai_decide(sim, "boss")  # hold 1
	advance(sim, 1)
	ai_decide(sim, "boss")  # hold 2
	advance(sim, 1)
	assert_event(declare(sim, "h", roll_action([0, 2])), "tactical_roll", "h rolls on the blast Moment")
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "explosion_blast", "the blast resolved")
	var missed: Dictionary = assert_event(blast_events, "blast_missed_roller",
		"WITHOUT the flag the AoE-center rule is intact — the machinery survived R26")
	assert_eq(String(missed.get("combatant", "")), "h", "the roller escapes the dodgable area")
	assert_no_event(blast_events, "explosion_knockout", "nobody else stood in the radius")
	assert_false(combatant(sim, "h").is_helpless(sim.clock.tick), "h is still on their feet")


# ----------------------------------------------------- R22 skips, zero rng (generic)

func test_undodgable_ability_skips_the_dash_ladder_with_zero_rng() -> void:
	# The flag on an ABILITY DICT (modified spec — generic, not valve-only),
	# through the full data path: ability -> _attack_action -> _strike_round.
	# Target Reflexes 4 vs threshold 7 = a genuine roll-needed dodge (4 + d4
	# >= 7 on a 3-4), so the control twin MUST consume rng — proving the
	# undodgable side skipped a live check, not a vacuous one.
	var sim: CombatSim = make_sim(99)
	add_human(sim, "t", {"team": "party", "position": [3, 0],
		"traits": {"physique": 3, "reflexes": 4, "mind": 3, "charm": 3}})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge(),
		"abilities": undodgable_dash_abilities()})
	var rng_before: int = sim.ai.ai_rng.state
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_eq(String(first_event(events, "ai_decision").get("ability", "")), "dash",
		"the modified dash is declared")
	events.append_array(advance(sim, 3))
	assert_no_event(events, "attack_dodged", "no dodge against an undodgable charge")
	assert_no_event(events, "dodge_failed", "and no failed ATTEMPT either — the check never ran")
	assert_no_event(events, "dash_sidestepped", "no ladder rider without a dodge")
	var hit: Dictionary = assert_event(events, "damage_applied", "the charge connects")
	assert_eq(String(hit.get("combatant", "")), "t", "on the would-be dodger")
	assert_eq(sim.ai.ai_rng.state, rng_before,
		"ZERO rng consumed — the skipped R22 check never touched the salted stream")
	# Control twin: identical fight, flag absent -> the R22 roll happens.
	var control: CombatSim = make_sim(99)
	add_human(control, "t", {"team": "party", "position": [3, 0],
		"traits": {"physique": 3, "reflexes": 4, "mind": 3, "charm": 3}})
	add_enemy(control, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	var control_before: int = control.ai.ai_rng.state
	var control_events: Array[Dictionary] = ai_decide(control, "boss")
	control_events.append_array(advance(control, 3))
	assert_true(has_event(control_events, "attack_dodged") or has_event(control_events, "dodge_failed"),
		"control: the same target genuinely rolls the threshold die")
	assert_ne(control.ai.ai_rng.state, control_before,
		"control: the live check consumed the stream — the skip above was real")


func test_undodgable_attack_skips_the_boss_threshold_dodge_with_zero_rng() -> void:
	# The other R22 direction: the boss's own boss_traits.dodge_threshold (7 vs
	# boss Reflexes 4 = roll needed). An undodgable declared action skips it.
	var sim: CombatSim = make_sim(7)
	add_human(sim, "a")
	add_enemy(sim, "boss", "incinedile", {"position": [1, 0]})
	var rng_before: int = sim.ai.ai_rng.state
	var events: Array[Dictionary] = declare(sim, "a",
		attack_action("crushed", 9, "boss", "right_hand", {"undodgable": true}))
	events.append_array(advance(sim, 1))
	assert_no_event(events, "attack_dodged", "the boss cannot dodge an undodgable round")
	assert_no_event(events, "dodge_failed", "no attempt was rolled at all")
	var hit: Dictionary = assert_event(events, "damage_applied", "the round lands")
	assert_eq(String(hit.get("combatant", "")), "boss", "on the boss")
	assert_eq(sim.ai.ai_rng.state, rng_before, "zero rng consumed by the skipped boss dodge")
	# Control twin: same strike without the flag -> the boss dodge check runs.
	var control: CombatSim = make_sim(7)
	add_human(control, "a")
	add_enemy(control, "boss", "incinedile", {"position": [1, 0]})
	var control_before: int = control.ai.ai_rng.state
	var control_events: Array[Dictionary] = declare(control, "a",
		attack_action("crushed", 9, "boss", "right_hand"))
	control_events.append_array(advance(control, 1))
	assert_true(has_event(control_events, "attack_dodged") or has_event(control_events, "dodge_failed"),
		"control: the boss genuinely attempts the dodge")
	assert_ne(control.ai.ai_rng.state, control_before, "control: the attempt consumed the stream")


func test_movement_counterplay_survives_an_undodgable_windup() -> void:
	# R26's own carve-out: movement is NOT a dodge. Leaving the committed lane
	# mid-windup still collapses an UNDODGABLE charge through the untouched R2
	# re-check — the flag kills dodge-shaped escapes only.
	var sim: CombatSim = make_sim()
	add_human(sim, "t", {"team": "party", "position": [3, 0],
		"traits": {"physique": 3, "reflexes": 4, "mind": 3, "charm": 3}})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge(),
		"abilities": undodgable_dash_abilities()})
	assert_eq(String(first_event(ai_decide(sim, "boss"), "ai_decision").get("ability", "")),
		"dash", "the undodgable dash is declared")
	advance(sim, 1)
	assert_event(declare(sim, "t", roll_action([2, 1])), "tactical_roll",
		"t rolls OFF the lane mid-windup — repositioning, not a dodge check")
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var invalidated: Dictionary = assert_event(resolved, "action_invalidated",
		"the windup re-check still fires against an undodgable attack")
	assert_eq(String(invalidated.get("reason", "")), "left_lane", "movement remains the counterplay")
	assert_no_event(resolved, "damage_applied", "nothing lands on the vacated lane")


# ----------------------------------------------------- transparency (schedule + preview)

func test_flag_rides_view_schedule_and_preview_rows() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(21, load_static_data())
	for id: String in ["a", "b"]:
		game.apply_command({"type": "add_combatant", "combatant": {
			"id": id, "name": id, "race": "human", "team": "party", "position": [0, 0],
			"traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "t", "name": "t", "race": "human", "team": "enemies", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 8, "mind": 3, "charm": 3}}})
	var flagged: Dictionary = attack_action("crushed", 3, "t", "torso",
		{"cost": 2, "undodgable": true, "dodge": {"threshold": 7}})
	var plain: Dictionary = attack_action("crushed", 3, "t", "torso",
		{"cost": 2, "dodge": {"threshold": 7}})
	# PREVIEW first (read-only — the schedule below proves the same dicts pend).
	var flagged_row: Dictionary = (game.preview_action("a", flagged).get("per_target", []) as Array)[0]
	assert_true(bool(flagged_row.get("undodgable", false)), "preview row carries the flag")
	assert_false(bool(flagged_row.get("dodge_possible", true)),
		"dodge_possible collapses to false — Reflexes 8 auto-dodge or not")
	assert_eq(String(flagged_row.get("dodge_outcome", "")), "undodgable",
		"the outcome class says WHY, not just 'ineligible'")
	var plain_row: Dictionary = (game.preview_action("a", plain).get("per_target", []) as Array)[0]
	assert_false(bool(plain_row.get("undodgable", true)), "an unflagged action previews undodgable false")
	assert_eq(String(plain_row.get("dodge_outcome", "")), "auto_dodge",
		"control: the same dodger reads auto_dodge without the flag (R22 intact)")
	assert_true(bool(plain_row.get("dodge_possible", false)), "and dodge_possible true")
	# SCHEDULE: both windups pend; only the flagged row carries the key.
	game.apply_command({"type": "declare_action", "actor": "a", "action": flagged})
	game.apply_command({"type": "declare_action", "actor": "b", "action": plain})
	var by_actor: Dictionary = {}
	for rd: Variant in game.view_schedule():
		by_actor[String((rd as Dictionary).get("actor", ""))] = rd
	assert_true(bool((by_actor.get("a", {}) as Dictionary).get("undodgable", false)),
		"the declared-action row DECLARES the flag (R26 transparency)")
	assert_false((by_actor.get("b", {}) as Dictionary).has("undodgable"),
		"additive: an unflagged declare's row is byte-identical to before R26")
	game.free()


# ----------------------------------------------------- serialization + determinism

func test_hash_roundtrip_through_an_undodgable_blast_fight() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	enter_valve_one(sim)
	ai_decide(sim, "boss")  # telegraph
	advance(sim, 1)
	ai_decide(sim, "boss")  # hold 1
	advance(sim, 1)
	ai_decide(sim, "boss")  # hold 2
	advance(sim, 1)
	declare(sim, "h", roll_action([0, 2]))  # marker live, undodgable blast pending
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical mid-window")
	assert_true(combatant(restored, "h").rolled_this_window,
		"the R25 marker still serializes (R26 added no state — the flag lives in data)")
	var live_blast: Array[Dictionary] = ai_decide(sim, "boss")
	var restored_blast: Array[Dictionary] = ai_decide(restored, "boss")
	for blast_events: Array[Dictionary] in [live_blast, restored_blast]:
		assert_no_event(blast_events, "blast_missed_roller", "no roller escape on either side")
		assert_eq(String(assert_event(blast_events, "explosion_knockout",
			"the undodgable KO applies on both sides").get("combatant", "")), "h", "to the roller")
	assert_eq(restored.state_hash(), sim.state_hash(), "post-blast hashes identical")


func test_determinism_two_runs_through_the_undodgable_valve() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(777)
		add_human(sim, "h", {"team": "party", "position": [1, 0]})
		add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
		enter_valve_one(sim)
		ai_decide(sim, "boss")  # telegraph
		advance(sim, 1)
		ai_decide(sim, "boss")  # hold 1
		advance(sim, 1)
		ai_decide(sim, "boss")  # hold 2
		advance(sim, 1)
		declare(sim, "h", roll_action([0, 2]))
		ai_decide(sim, "boss")  # the undodgable blast catches the roller
		advance(sim, 2)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1],
		"identical (seed, command log) through an undodgable blast -> identical hash")
