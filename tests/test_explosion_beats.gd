extends SimTestBase
## Explosion beats are REAL (owner ruling 2026-07-23, decision #27 — supersedes
## the R11 #18 v1 dormancy): entering an explosion phase the boss telegraphs
## (visible steam, 1 Moment), holds through the escape window (canon 2 Moments
## — moving out of the radius is the counterplay), then the blast knocks out
## every other combatant still inside — Helpless for 2 Clocks, no damage, no
## death — the breach resets, and the machine advances into the next Threshold
## phase. This file drives the full choreography against the seeded Incinedile.


func add_boss(sim: CombatSim, id: String = "boss", overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## The seeded Incinedile trait block minus the dodge threshold — beat tests
## stay pin-exact without consuming the AI d6 stream (test_incinedile pattern).
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


func boss_state(sim: CombatSim, id: String = "boss") -> CombatantState:
	return sim.combatants.get(id)


## Stages the canonical Valve-I entry: h burst-breaches (crushed net 8 >= 7),
## then drives the network 50 -> 35 (crushed net 15; the condition is resisted
## on the immune network, only HP lands). Ends with phase 2 just entered at
## tick 1 — the boss's next ai_decide (tick 2) is the telegraph Moment. Crushed
## (not bleeding) keeps later Clock resets from re-breaching via the T2 path.
func enter_valve_one(sim: CombatSim) -> Array[Dictionary]:
	declare(sim, "h", attack_action("crushed", 10, "boss", "right_hand"))
	advance(sim, 1)
	declare(sim, "h", attack_action("crushed", 17, "boss", "network"))
	return advance(sim, 1)


func stage_sim() -> CombatSim:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	return sim


# ---------------------------------------------------------------- choreography

func test_telegraph_fires_on_the_moment_after_entering_phase_two() -> void:
	var sim: CombatSim = stage_sim()
	var entry_events: Array[Dictionary] = enter_valve_one(sim)
	assert_event(entry_events, "boss_phase_changed", "precondition: the valve really opened")
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = assert_event(events, "ai_decision", "the boss decided")
	assert_eq(String(decision.get("choice", "")), "telegraph", "the beat opens with a telegraph, not a wait")
	var steam: Dictionary = assert_event(events, "explosion_telegraph", "visible steam on the Moment after entry")
	assert_eq(String(steam.get("combatant", "")), "boss", "the telegraph names the boss")
	assert_eq(int(steam.get("phase", 0)), 2, "phase 2 valve")
	assert_eq(int(steam.get("radius", 0)), 5, "seeded phase-2 radius")
	assert_eq(int(steam.get("moments_until_blast", 0)), 3, "telegraph Moment + 2 escape Moments until the blast")


func test_blast_fires_exactly_telegraph_plus_escape_moments_later() -> void:
	var sim: CombatSim = stage_sim()
	enter_valve_one(sim)
	var telegraph_tick: int = sim.clock.tick
	assert_event(ai_decide(sim, "boss"), "explosion_telegraph", "telegraph at tick %d" % telegraph_tick)
	# Escape window: exactly escape_moments (canon 2) holds, each an honest wait.
	for i: int in range(2):
		advance(sim, 1)
		var hold: Array[Dictionary] = ai_decide(sim, "boss")
		var decision: Dictionary = first_event(hold, "ai_decision")
		assert_eq(String(decision.get("choice", "")), "wait", "escape Moment %d: the boss holds" % (i + 1))
		assert_eq(String(decision.get("reason", "")), "explosion_building", "and says why")
		assert_no_event(hold, "explosion_blast", "no early blast")
	advance(sim, 1)
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	var blast: Dictionary = assert_event(blast_events, "explosion_blast", "the blast resolves after the window")
	assert_eq(sim.clock.tick, telegraph_tick + 3, "blast tick = telegraph + 1 + escape_moments")
	assert_eq(int(blast.get("radius", 0)), 5, "blast carries the radius")
	assert_eq(blast.get("position", []), [0, 0], "and the boss's position")


func test_contestant_inside_radius_is_knocked_out_for_two_clocks() -> void:
	var sim: CombatSim = stage_sim()
	# Friendly fire is ON: a mob teammate inside the radius is caught too. A
	# second, already-Helpless human proves the maxi extension (no stacking,
	# no shortening).
	add_human(sim, "down", {"team": "party", "position": [2, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "dog", "name": "dog", "enemy": "roach_dog",
		"team": "enemies", "position": [0, 2],
	}})
	enter_valve_one(sim)
	ai_decide(sim, "boss")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	boss_state(sim, "down").helpless_until_tick = sim.clock.tick + 3  # pre-KO'd, shorter window
	var blast_tick: int = sim.clock.tick
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "explosion_blast", "the blast resolved")
	var knockouts: Dictionary = {}
	for event: Dictionary in events_of(blast_events, "explosion_knockout"):
		knockouts[String(event.get("combatant", ""))] = int(event.get("helpless_until_tick", 0))
	var until: int = blast_tick + 2 * Clock.TICKS_PER_CLOCK
	assert_eq(knockouts.get("h", -1), until, "h is knocked out: Helpless for exactly 2 Clocks")
	assert_eq(knockouts.get("dog", -1), until, "friendly fire: the mob in radius is caught too")
	assert_eq(knockouts.get("down", -1), until, "an already-Helpless victim is extended via maxi, not stacked")
	assert_false(knockouts.has("boss"), "the boss is never caught in its own blast")
	assert_true(boss_state(sim, "h").is_helpless(sim.clock.tick), "h is Helpless at the blast tick")
	assert_false(boss_state(sim).is_helpless(sim.clock.tick), "the boss keeps acting")
	assert_no_event(blast_events, "damage_applied", "knockout only — no damage (owner ruling)")
	assert_no_event(blast_events, "combatant_died", "and no death")
	# Recovery: Helpless through the last tick of the window, acting again after.
	advance(sim, 2 * Clock.TICKS_PER_CLOCK - 1)
	assert_true(boss_state(sim, "h").is_helpless(sim.clock.tick), "still Helpless on the window's last tick")
	assert_rejected(declare(sim, "h", attack_action("crushed", 1, "boss", "left_leg")),
		"helpless", "a knocked-out contestant cannot act")
	advance(sim, 1)
	assert_false(boss_state(sim, "h").is_helpless(sim.clock.tick), "recovered after exactly 2 Clocks")
	assert_event(declare(sim, "h", attack_action("crushed", 1, "boss", "left_leg")),
		"action_declared", "and can act again")


func test_contestant_who_escapes_the_radius_is_not_caught() -> void:
	var sim: CombatSim = stage_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "dog", "name": "dog", "enemy": "roach_dog",
		"team": "enemies", "position": [0, 2],
	}})
	enter_valve_one(sim)
	# The intended counterplay: two free moves during the telegraph + window
	# carry h from distance 1 to 7 — outside the radius-5 blast.
	ai_decide(sim, "boss")
	assert_event(sim.apply_command({"type": "move", "actor": "h", "to": [4, 0]}), "moved", "first escape move")
	advance(sim, 1)
	ai_decide(sim, "boss")
	assert_event(sim.apply_command({"type": "move", "actor": "h", "to": [7, 0]}), "moved", "second escape move")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "explosion_blast", "the blast resolved")
	var caught: Array[String] = []
	for event: Dictionary in events_of(blast_events, "explosion_knockout"):
		caught.append(String(event.get("combatant", "")))
	assert_true(caught.has("dog"), "the mob that stayed inside is caught (the blast had teeth)")
	assert_false(caught.has("h"), "the contestant who ran is NOT caught")
	assert_false(boss_state(sim, "h").is_helpless(sim.clock.tick), "h is still on their feet")


func test_retreat_rides_the_blast_and_wounds_persist() -> void:
	var sim: CombatSim = stage_sim()
	var entry_events: Array[Dictionary] = enter_valve_one(sim)
	assert_no_event(entry_events, "breach_reset", "phase entry does NOT retreat (#27)")
	assert_true(boss_state(sim).breached, "the breach stays open through the beat")
	ai_decide(sim, "boss")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "breach_reset", "the retreat rides the blast")
	assert_false(boss_state(sim).breached, "breach closed")
	assert_true(bool(boss_state(sim).parts["network"]["hidden"]), "the network re-hid")
	assert_eq(int(boss_state(sim).parts["network"]["hp"]), 35, "network HP carries over — wounds persist")
	assert_true(boss_state(sim).conditions.has("right_hand"), "the crushed wound persists across the valve")


func test_boss_phase_advances_and_the_boss_attacks_next_moment() -> void:
	var sim: CombatSim = stage_sim()
	enter_valve_one(sim)
	ai_decide(sim, "boss")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	var changed: Dictionary = assert_event(blast_events, "boss_phase_changed", "the machine advances off the valve")
	assert_eq(int(changed.get("from_phase", 0)), 2, "left the valve")
	assert_eq(int(changed.get("to_phase", 0)), 3, "into Threshold 2")
	assert_eq(String(changed.get("name", "")), "Threshold 2", "seeded phase name")
	assert_eq(sim.ai.current_phase("boss"), 3, "AI state agrees")
	# Same tick: the blast was the boss's Moment — no second act.
	assert_rejected(ai_decide(sim, "boss"), "not_ready", "the fight resumes NEXT Moment, not this one")
	advance(sim, 1)
	var next_events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = assert_event(next_events, "ai_decision", "the boss acts again")
	assert_eq(String(decision.get("choice", "")), "attack", "normal fight behavior resumed")
	assert_eq(String(decision.get("ability", "")), "dash", "one target in reach -> the line charge")


func test_hp_gate_stays_quiet_mid_beat_then_reengages() -> void:
	var sim: CombatSim = stage_sim()
	enter_valve_one(sim)
	ai_decide(sim, "boss")
	# The network is still exposed mid-beat; a greedy party can keep pounding it
	# below the NEXT valve's threshold — but the hp gate must stay quiet while
	# the beat owns the phase.
	declare(sim, "h", attack_action("crushed", 20, "boss", "network"))
	var mid_beat: Array[Dictionary] = advance(sim, 1)
	assert_true(int(boss_state(sim).parts["network"]["hp"]) <= 18, "precondition: below the valve-II threshold")
	assert_no_event(mid_beat, "boss_phase_changed", "the hp gate stays quiet while the beat runs")
	ai_decide(sim, "boss")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	# The blast advances 2 -> 3; the reengaged hp gate immediately fires 3 -> 4.
	var hops: Array[String] = []
	for event: Dictionary in events_of(blast_events, "boss_phase_changed"):
		hops.append("%d->%d" % [int(event.get("from_phase", 0)), int(event.get("to_phase", 0))])
	assert_eq(hops, ["2->3", "3->4"], "post-blast the hp gate reengages straight into Valve II")
	advance(sim, 1)
	var steam: Dictionary = assert_event(ai_decide(sim, "boss"), "explosion_telegraph", "Valve II telegraphs")
	assert_eq(int(steam.get("phase", 0)), 4, "phase-4 beat")
	assert_eq(int(steam.get("radius", 0)), 7, "seeded phase-4 radius")


# ---------------------------------------------------------------- serialization

func test_mid_telegraph_save_restores_the_countdown() -> void:
	var sim: CombatSim = stage_sim()
	enter_valve_one(sim)
	ai_decide(sim, "boss")  # telegraph fired — save MID-beat
	var snapshot: Dictionary = sim.to_dict()
	var mid_hash: String = sim.state_hash()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), mid_hash, "roundtrip hash identical mid-telegraph")
	# Lockstep: both sims replay the identical tail through the blast.
	var tail: Array[Dictionary] = [
		{"type": "advance_tick"}, {"type": "ai_decide", "actor": "boss"},
		{"type": "advance_tick"}, {"type": "ai_decide", "actor": "boss"},
		{"type": "advance_tick"}, {"type": "ai_decide", "actor": "boss"},
		{"type": "advance_tick"},
	]
	var tail_original: Array[Dictionary] = []
	var tail_restored: Array[Dictionary] = []
	for cmd: Dictionary in tail:
		tail_original.append_array(sim.apply_command(cmd))
		tail_restored.append_array(restored.apply_command(cmd))
	assert_event(tail_original, "explosion_blast", "the tail really blasted")
	assert_event(tail_restored, "explosion_blast", "the restored tail blasted too")
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash — mid-beat restore is exact")
	# Mutation teeth: a tampered telegraph_tick must change the hash.
	var beats: Dictionary = (snapshot["ai"] as Dictionary).get("explosion_beats", {})
	assert_true(beats.has("boss"), "the mid-beat snapshot serialized the beat")
	(beats["boss"] as Dictionary)["telegraph_tick"] = int((beats["boss"] as Dictionary)["telegraph_tick"]) + 7
	assert_ne(CombatSim.from_dict(snapshot).state_hash(), mid_hash,
		"explosion_beats is covered by the state hash")


# ---------------------------------------------------------------- regression

func test_no_more_phase_not_implemented_waits() -> void:
	var sim: CombatSim = stage_sim()
	var events: Array[Dictionary] = enter_valve_one(sim)
	for i: int in range(5):
		events.append_array(ai_decide(sim, "boss"))
		events.append_array(advance(sim, 1))
	for event: Dictionary in events_of(events, "ai_decision"):
		assert_ne(String(event.get("reason", "")), "phase_not_implemented",
			"the v1 dormancy is retired — the boss never idles the fight away (#27)")
	assert_event(events, "explosion_blast", "the valve actually fired")
	var attacked: bool = false
	for event: Dictionary in events_of(events, "ai_decision"):
		if String(event.get("choice", "")) == "attack":
			attacked = true
	assert_true(attacked, "the boss fights on after the valve")
