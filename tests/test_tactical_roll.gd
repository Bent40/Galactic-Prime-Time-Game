extends SimTestBase
## Tactical Roll — the G1 declared-hex dodge + the AoE-center rule (owner
## 2026-07-23, skills-passover RULINGS; rules-addendum R25). The roll spends the
## actor's MOVEMENT for the Moment (not a Moment, not the free-action slot),
## moves IMMEDIATELY at declare, and "the attack still resolves": single/multi-
## target windups re-check their real pattern against the new hex through the
## existing R2 snapshot machinery, while AREA attacks miss a rolling target
## entirely unless the destination is the area's CENTER — tracked by the
## tick-scoped rolled_this_window marker. R26 (owner 2026-07-25, decision #32)
## made the SEEDED valve blast undodgable, so the AoE-center mechanism tests
## below stage a synthetic DODGABLE area (the seeded phases with the R26 flag
## stripped); the valve-catches-the-roller side lives in test_undodgable.gd.


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
## test_incinedile spec choice) — roll pins never consume the AI d6 stream.
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


## Reflexes-2 target spec: the dash's threshold-7 dodge is IMPOSSIBLE (2 + d4
## max = 6 < 7) so charge outcomes are deterministic and consume no rng.
func cannot_dodge_traits() -> Dictionary:
	return {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}


## The seeded Incinedile phases with the R26 "undodgable" flag STRIPPED from
## every explosion block — the synthetic DODGABLE area: the R25 AoE-center
## machinery must stay live for authored areas WITHOUT the flag (regression),
## even though the seeded valve itself is undodgable now (R26).
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


## Stages the canonical Valve-I entry (test_explosion_beats pattern): h burst-
## breaches, then drives the network 50 -> 35 — phase 2 just entered, the boss's
## next ai_decide is the telegraph Moment.
func enter_valve_one(sim: CombatSim) -> Array[Dictionary]:
	declare(sim, "h", attack_action("crushed", 10, "boss", "right_hand"))
	advance(sim, 1)
	declare(sim, "h", attack_action("crushed", 17, "boss", "network"))
	return advance(sim, 1)


## Drives the valve to the blast Moment: telegraph decide + the two escape-
## window holds, ending ON the blast tick BEFORE the boss's blast decide — the
## caller chooses what the party does with that Moment, then fires ai_decide.
func drive_to_blast_tick(sim: CombatSim) -> void:
	ai_decide(sim, "boss")  # telegraph
	advance(sim, 1)
	ai_decide(sim, "boss")  # hold 1
	advance(sim, 1)
	ai_decide(sim, "boss")  # hold 2
	advance(sim, 1)


func combatant(sim: CombatSim, id: String) -> CombatantState:
	return sim.combatants.get(id)


# ---------------------------------------------------------------- declare economy

func test_roll_moves_immediately_and_spends_only_the_movement() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	var events: Array[Dictionary] = declare(sim, "h", roll_action([1, 1]))
	var rolled: Dictionary = assert_event(events, "tactical_roll", "the roll is a real event")
	assert_eq(rolled.get("from", []), [0, 0], "from the declare hex")
	assert_eq(rolled.get("to", []), [1, 1], "to the declared destination")
	assert_eq(int(rolled.get("spaces", 0)), 2, "two hexes covered")
	assert_eq(int(rolled.get("range", 0)), 2, "L1 roll range 2 (PLACEHOLDER R14)")
	var h: CombatantState = combatant(sim, "h")
	assert_eq(h.position, Vector2i(1, 1), "position updated IMMEDIATELY at declare")
	assert_true(h.moved_this_tick, "the roll consumed the movement allowance")
	assert_true(h.rolled_this_window, "the dodge-window marker is live")
	assert_false(h.free_action_used, "the free-ACTION slot is untouched (G1: only movement)")
	assert_eq(h.next_action_tick, 0, "0 Moments — the scheduled-action economy untouched")


func test_free_move_after_a_roll_is_rejected() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	assert_event(declare(sim, "h", roll_action([1, 0])), "tactical_roll", "the roll lands")
	assert_rejected(sim.apply_command({"type": "move", "actor": "h", "to": [2, 0]}),
		"already_moved", "rolling and free-moving are mutually exclusive this tick")


func test_roll_after_a_move_is_rejected_movement_spent() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	assert_event(sim.apply_command({"type": "move", "actor": "h", "to": [1, 0]}),
		"moved", "the free move lands first")
	assert_rejected(declare(sim, "h", roll_action([2, 0])),
		"movement_spent", "the movement allowance is already gone")
	assert_false(combatant(sim, "h").rolled_this_window, "a rejected roll sets no marker")


func test_the_bit_and_the_roll_share_a_tick_in_both_orders() -> void:
	# Design call (R25): the roll consumes EXACTLY the movement allowance — the
	# free-action slot (The Bit's cost, R3 anti-spam ruling) is a different slot.
	var bit: Dictionary = {"key": "kazoo", "name": "Tiny Kazoo", "line": "toot"}
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"bit": bit})
	assert_event(declare(sim, "h", roll_action([1, 0])), "tactical_roll", "roll first")
	assert_event(sim.apply_command({"type": "bit", "actor": "h"}),
		"bit_performed", "The Bit is still legal after a roll")
	var sim2: CombatSim = make_sim()
	add_human(sim2, "h", {"bit": bit})
	assert_event(sim2.apply_command({"type": "bit", "actor": "h"}),
		"bit_performed", "bit first")
	assert_event(declare(sim2, "h", roll_action([1, 0])),
		"tactical_roll", "the roll is still legal after The Bit")


func test_roll_resets_with_the_tick_flags() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	declare(sim, "h", roll_action([1, 0]))
	advance(sim, 1)
	var h: CombatantState = combatant(sim, "h")
	assert_false(h.rolled_this_window, "the marker clears at the next tick start (R25 window)")
	assert_false(h.moved_this_tick, "movement allowance back")
	assert_event(declare(sim, "h", roll_action([2, 0])), "tactical_roll", "a fresh tick can roll again")


# ---------------------------------------------------------------- destination gates

func test_invalid_destinations_rejected_without_mutation() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	add_human(sim, "blocker", {"position": [1, 0]})
	assert_rejected(declare(sim, "h", roll_action([0, 0])), "no_move", "rolling in place is no roll")
	assert_rejected(declare(sim, "h", roll_action([3, 0])), "roll_out_of_range", "3 hexes > L1 range 2")
	assert_rejected(declare(sim, "h", roll_action([1, 0])), "hex_occupied", "onto a living body")
	assert_rejected(declare(sim, "h", {"kind": "skill", "key": "tactical_roll", "level": 1}),
		"invalid_destination", "a roll needs a declared hex")
	var h: CombatantState = combatant(sim, "h")
	assert_eq(h.position, Vector2i(0, 0), "rejections moved nobody")
	assert_false(h.moved_this_tick, "no movement spent on a rejection")
	assert_false(h.rolled_this_window, "no marker on a rejection")


func test_roll_gates_mirror_movement() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	add_human(sim, "t", {"position": [1, 0]})
	# Prone (R3 crawl rule + the R22 punish window).
	sim.apply_command({"type": "set_status", "target": "h", "status": "prone", "value": true})
	assert_rejected(declare(sim, "h", roll_action([0, 1])), "prone", "no acrobatics while Prone")
	sim.apply_command({"type": "set_status", "target": "h", "status": "prone", "value": false})
	# Winding up (R2 commit): a cost-2 skill declared, then the roll attempt.
	declare(sim, "h", {"kind": "skill", "key": "strong_strike", "level": 1,
		"targets": [{"id": "t", "part": "torso"}]})
	assert_rejected(declare(sim, "h", roll_action([0, 1])), "winding_up", "committed actors cannot roll")
	advance(sim, 3)  # the cost-2 windup fully resolves before the next gate
	# Grappled (R9 movement lock) — staged directly, like the explosion tests
	# stage helpless_until_tick (no grapple choreography needed for this gate).
	combatant(sim, "h").grappled_by = "t"
	assert_rejected(declare(sim, "h", roll_action([0, 1])), "grappled", "R9: no repositioning in a lock")
	combatant(sim, "h").grappled_by = ""


func test_levels_scale_roll_range_per_the_seed_ladder() -> void:
	# R25 ladder: base 2 (PLACEHOLDER R14) + the seed-data space increments
	# (L2 +1, L3 +1, L4 +2) -> 2/3/4/6; the number tables clamp beyond L4.
	assert_eq(int(SkillBook.mechanics("tactical_roll", 1).get("roll_range", 0)), 2, "L1 = 2")
	assert_eq(int(SkillBook.mechanics("tactical_roll", 2).get("roll_range", 0)), 3, "L2 = 3")
	assert_eq(int(SkillBook.mechanics("tactical_roll", 3).get("roll_range", 0)), 4, "L3 = 4")
	assert_eq(int(SkillBook.mechanics("tactical_roll", 4).get("roll_range", 0)), 6, "L4 = 6")
	assert_eq(int(SkillBook.mechanics("tactical_roll", 6).get("roll_range", 0)), 6,
		"L5/L6 rows are data-only (superseded cooldown text) — the table clamps at L4")
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	assert_rejected(declare(sim, "h", roll_action([3, 0], 1)), "roll_out_of_range", "3 hexes beyond L1")
	assert_event(declare(sim, "h", roll_action([3, 0], 2)), "tactical_roll", "L2 reaches 3 hexes")


# ---------------------------------------------------------------- pattern attacks (G1 half 2)

func test_rolling_out_of_a_cone_arc_dodges_rolling_within_does_not() -> void:
	# G1: single/multi-target attacks hit iff the new hex is still within their
	# range/pattern — the wave-2a windup re-checks, fed by the roll's IMMEDIATE
	# position update through the R2 tick-start snapshot. No new seam.
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [2, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 2]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_eq(String(first_event(events, "ai_decision").get("ability", "")), "flamethrower",
		"both in the E arc -> sweep declared")
	advance(sim, 1)
	# Mid-windup: hb rolls OUT of the committed arc; ha rolls but STAYS inside.
	assert_event(declare(sim, "hb", roll_action([-1, 2])), "tactical_roll", "hb rolls out of the arc")
	assert_event(declare(sim, "ha", roll_action([1, 1])), "tactical_roll", "ha rolls within the arc")
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var escaped: Dictionary = assert_event(resolved, "windup_target_escaped", "the roll dodged the sweep")
	assert_eq(String(escaped.get("target", "")), "hb", "hb is the escapee")
	assert_eq(String(escaped.get("reason", "")), "left_area", "through the standard arc re-check")
	var burned: Dictionary = {}
	for hit: Dictionary in events_of(resolved, "damage_applied"):
		burned[String(hit.get("combatant", ""))] = true
	assert_true(burned.has("ha"), "rolling WITHIN the arc still gets hit (G1: pattern rules)")
	assert_false(burned.has("hb"), "the out-of-arc roller takes nothing")


func test_rolling_off_a_dash_lane_dodges_the_charge() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0], "traits": cannot_dodge_traits()})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_eq(String(first_event(events, "ai_decision").get("ability", "")), "dash", "dash declared")
	advance(sim, 1)
	assert_event(declare(sim, "h", roll_action([2, 1])), "tactical_roll", "h rolls off the lane")
	advance(sim, 1)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var invalidated: Dictionary = assert_event(resolved, "action_invalidated", "the roller dodged")
	assert_eq(String(invalidated.get("reason", "")), "left_lane", "through the standard lane re-check")
	assert_no_event(resolved, "damage_applied", "nothing lands")
	assert_no_event(resolved, "dash_charged", "no charge down an abandoned lane")
	assert_eq(combatant(sim, "boss").position, Vector2i(0, 0), "the boss never moved")


func test_rolling_on_the_resolution_tick_dodges_nothing() -> void:
	# R2 unchanged: resolutions compute against the tick-START snapshot — a roll
	# on the attack's own resolution tick is too late, marker or no marker (the
	# marker only ever speaks to AREA attacks).
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [2, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 2]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
	ai_decide(sim, "boss")
	advance(sim, 2)  # now ON the cone's resolution tick
	assert_event(declare(sim, "hb", roll_action([-1, 2])), "tactical_roll", "hb rolls this very tick")
	assert_true(combatant(sim, "hb").rolled_this_window, "the marker is live")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var burned: Dictionary = {}
	for hit: Dictionary in events_of(resolved, "damage_applied"):
		burned[String(hit.get("combatant", ""))] = true
	assert_true(burned.has("hb"), "same-tick roll dodges no windup (R2 snapshot semantics)")
	assert_no_event(resolved, "windup_target_escaped", "no escape was recorded")


func test_instant_attacks_are_unaffected_by_the_roll_marker() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "roller", {"position": [1, 0]})
	add_human(sim, "atk", {"position": [1, 1]})
	assert_event(declare(sim, "roller", roll_action([2, 1])), "tactical_roll", "the roll lands")
	assert_true(combatant(sim, "roller").rolled_this_window, "marker live")
	# An instant (cost 1) declared at the roller's NEW hex this same tick.
	declare(sim, "atk", attack_action("crushed", 3, "roller", "torso"))
	var resolved: Array[Dictionary] = advance(sim, 1)
	var hit: Dictionary = assert_event(resolved, "damage_applied",
		"the instant lands — the marker never negates single-target attacks (R2)")
	assert_eq(String(hit.get("combatant", "")), "roller", "on the roller")


# ---------------------------------------------------------------- AREA attacks (AoE-center rule)

func test_dodgable_blast_catches_a_non_roller_and_misses_a_roller() -> void:
	# The R25 mechanism on a synthetic DODGABLE area (R26 flag stripped) — the
	# seeded valve itself now catches rollers; see test_undodgable.gd.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_human(sim, "buddy", {"team": "party", "position": [2, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge(),
		"phases": dodgable_valve_phases()})
	enter_valve_one(sim)
	drive_to_blast_tick(sim)
	# ON the blast Moment: h rolls (destination [0, 2] — INSIDE radius 5, NOT
	# the center); buddy just stands there.
	assert_event(declare(sim, "h", roll_action([0, 2])), "tactical_roll", "h rolls as the valve blows")
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "explosion_blast", "the blast resolved")
	var missed: Dictionary = assert_event(blast_events, "blast_missed_roller",
		"the AREA attack misses the rolling target entirely (G1 refinement)")
	assert_eq(String(missed.get("combatant", "")), "h", "the roller is named")
	assert_eq(missed.get("center", []), [0, 0], "against the area's center hex")
	var knockouts: Dictionary = {}
	for event: Dictionary in events_of(blast_events, "explosion_knockout"):
		knockouts[String(event.get("combatant", ""))] = true
	assert_false(knockouts.has("h"), "the roller is NOT knocked out — inside the radius or not")
	assert_true(knockouts.has("buddy"), "the non-roller in radius is caught (the blast kept teeth)")
	assert_false(combatant(sim, "h").is_helpless(sim.clock.tick), "h is still on their feet")
	assert_true(combatant(sim, "buddy").is_helpless(sim.clock.tick), "buddy is down for 2 Clocks")


func test_center_hex_exception_and_its_occupied_boss_hex_impossibility() -> void:
	# G1: the roller IS hit when the destination is the area's CENTER. The blast
	# centers on the boss's own hex and rolling onto an occupied hex is
	# impossible — so via commands a DODGABLE-area roller always escapes (the
	# R25 valve-counter consequence — SUPERSEDED for the seeded valve by R26,
	# hence the stripped-flag phases here). Both halves asserted: the command
	# path rejects the center roll, and the center exception is proven live by
	# staging the unreachable state directly (future area attacks may have open
	# centers).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge(),
		"phases": dodgable_valve_phases()})
	enter_valve_one(sim)
	drive_to_blast_tick(sim)
	assert_rejected(declare(sim, "h", roll_action([0, 0])), "hex_occupied",
		"rolling onto the blast's center is impossible while the boss stands on it")
	# Stage the unreachable state directly (test_explosion_beats precedent):
	# a marker-carrying combatant ON the center hex when the blast resolves.
	var h: CombatantState = combatant(sim, "h")
	h.position = Vector2i(0, 0)
	h.rolled_this_window = true
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "explosion_blast", "the blast resolved")
	assert_no_event(blast_events, "blast_missed_roller", "no miss on the center hex")
	var knockout: Dictionary = assert_event(blast_events, "explosion_knockout",
		"the center-hex roller IS caught — the G1 center exception is live code")
	assert_eq(String(knockout.get("combatant", "")), "h", "and it names the roller")


func test_rolling_early_gives_no_area_protection() -> void:
	# The R25 window model, honestly: the marker clears at the next tick start,
	# so a roll during the ESCAPE window only helps through position (as any
	# move would) — dodging a DODGABLE blast by marker means rolling ON its
	# Moment (stripped-flag phases: the marker expiry is what this test proves,
	# so the area must be one a live marker COULD have escaped).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge(),
		"phases": dodgable_valve_phases()})
	enter_valve_one(sim)
	ai_decide(sim, "boss")  # telegraph
	advance(sim, 1)
	# Escape-window roll to a hex still INSIDE radius 5.
	assert_event(declare(sim, "h", roll_action([0, 2])), "tactical_roll", "h rolls early")
	ai_decide(sim, "boss")  # hold 1
	advance(sim, 1)
	assert_false(combatant(sim, "h").rolled_this_window, "the marker did not survive the tick")
	ai_decide(sim, "boss")  # hold 2
	advance(sim, 1)
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "explosion_blast", "the blast resolved")
	assert_no_event(blast_events, "blast_missed_roller", "no stale-marker mercy")
	var knockout: Dictionary = assert_event(blast_events, "explosion_knockout",
		"still inside the radius with no live marker -> caught")
	assert_eq(String(knockout.get("combatant", "")), "h", "the early roller is knocked out")


# ---------------------------------------------------------------- serialization + determinism

func test_marker_serialization_roundtrip_mid_window() -> void:
	# Stripped-flag phases: the restored-roller-still-missed assertion needs a
	# DODGABLE area (the undodgable-valve roundtrip lives in test_undodgable.gd).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge(),
		"phases": dodgable_valve_phases()})
	enter_valve_one(sim)
	drive_to_blast_tick(sim)
	declare(sim, "h", roll_action([0, 2]))  # marker live, blast pending
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical mid-window")
	assert_true(combatant(restored, "h").rolled_this_window, "the marker survives save/load")
	assert_eq(combatant(restored, "h").position, Vector2i(0, 2), "at the rolled-to hex")
	# Both sims resolve the pending blast identically: the restored roller is
	# still missed, and the streams stay hash-identical.
	var live_blast: Array[Dictionary] = ai_decide(sim, "boss")
	var restored_blast: Array[Dictionary] = ai_decide(restored, "boss")
	assert_event(live_blast, "blast_missed_roller", "live sim: the roller escapes")
	assert_event(restored_blast, "blast_missed_roller", "restored sim: the roller escapes too")
	assert_eq(restored.state_hash(), sim.state_hash(), "post-blast hashes identical")
	# Pre-R25 save compatibility: a dict without the marker key loads as false.
	var legacy: Dictionary = combatant(sim, "h").to_dict()
	legacy.erase("rolled_this_window")
	assert_false(CombatantState.from_dict(legacy).rolled_this_window,
		"pre-R25 saves default to no live roll")


func test_determinism_with_rolls_in_the_log() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(777)
		add_human(sim, "h", {"team": "party", "position": [1, 0]})
		add_human(sim, "buddy", {"team": "party", "position": [2, 0]})
		add_enemy(sim, "boss", "incinedile", {"boss_traits": traits_without_dodge()})
		enter_valve_one(sim)
		drive_to_blast_tick(sim)
		declare(sim, "h", roll_action([0, 2]))
		declare(sim, "buddy", roll_action([3, 0]))
		ai_decide(sim, "boss")
		advance(sim, 2)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "identical (seed, command log with rolls) -> identical hash")
