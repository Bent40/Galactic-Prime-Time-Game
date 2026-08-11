extends SimTestBase
## Death Spin + dash knock-aside (wave 2b, decision #31 — rules-addendum R11
## #19). The authored 3-beat sequence is REAL: grab (R9 grapple, adjacent
## instant) -> chew (2 crushed to both arms, normal R14 gate per arm) -> spin
## (an honest R14 finisher + the fling down the spin lane). The counterplay
## chain is the design under test: 2 full Moments of warning in which a single
## recorded net-5 hit on the boss (merged combined hits count as ONE) forces
## the release, the R9 escape aborts, the valve outranks (#27 precedent), and
## victim/boss going down aborts. The dash's authored "knock aside" is real
## too: a CONNECTED charge shoves the target off the lane and knocks it prone.
##
## PACING PIN (documented ruling): grab cost 1 -> chew cost 1 -> spin cost 1 —
## the authored moment_cost 3 spans the whole sequence, one beat per Moment.
## DECIDE-ORDER PIN: valve > stand > continuation > cone > GRAB > dash.


func add_boss(sim: CombatSim, id: String = "boss", overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## The seeded Incinedile trait block minus the dodge threshold (test_incinedile
## pattern) — pre-grab party hits stay pin-exact without consuming the AI
## stream. Mid-sequence the boss is Exposed anyway (grappling, R9), so its
## dodge is already off — the strip only matters for the staging hits.
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


## Canonical staging: the victim ADJACENT east of the boss (the grab's punish
## position); an optional ally WEST at distance 2 — outside grab range, inside
## attack reach, and on the opposite side so no single 120-degree arc holds
## two opponents (the cone never preempts the grab under test).
func stage(with_ally: bool = false, victim_traits: Dictionary = {}) -> CombatSim:
	var sim: CombatSim = make_sim()
	var stat_block: Dictionary = {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}
	stat_block.merge(victim_traits, true)
	add_human(sim, "vic", {"team": "party", "position": [1, 0], "traits": stat_block})
	if with_ally:
		add_human(sim, "ally", {"team": "party", "position": [-2, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	return sim


## Drives the grab beat: ai_decide (declares the cost-1 grapple) + the advance
## that resolves it. Returns the combined events.
func grab_beat(sim: CombatSim) -> Array[Dictionary]:
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	events.append_array(advance(sim, 1))
	return events


func spin_state(sim: CombatSim) -> Dictionary:
	return sim.ai.death_spins.get("boss", {})


# ------------------------------------------------------------ the full kill chain

func test_full_three_beat_kill_chain() -> void:
	var sim: CombatSim = stage()
	# BEAT 1 — GRAB. Single adjacent candidate: the decide consumes ZERO rng
	# (the R23 single-candidate rule), the grab is a cost-1 INSTANT (the dodge
	# model does not apply), and the hold lands through the real R9 machinery.
	var rng_before: int = sim.ai.ai_rng.state
	var grab_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_eq(sim.ai.ai_rng.state, rng_before, "a single-candidate grab pick consumes no rng")
	var decision: Dictionary = assert_event(grab_events, "ai_decision", "the boss decided")
	assert_eq(String(decision.get("choice", "")), "grab", "an adjacent lone target -> the grab")
	assert_eq(String(decision.get("ability", "")), "death_spin", "the sequence ability is named")
	assert_eq(String(decision.get("target", "")), "vic", "the adjacent victim is the pick")
	var declared: Dictionary = assert_event(grab_events, "action_declared", "a REAL resolver declare")
	assert_eq(String(declared.get("kind", "")), "grapple", "the grab IS the R9 grapple kind")
	assert_eq(int(declared.get("cost", 0)), 1, "pacing model: grab costs 1 (the moment_cost 3 spans the 3 beats)")
	assert_false(bool(declared.get("windup", false)), "the grab is an instant — no dodge window (R2)")
	assert_rejected(ai_decide(sim, "boss"), "not_ready", "the grab consumed the boss's Moment")
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "grapple_started", "the R9 hold lands")
	var grab: Dictionary = assert_event(resolved, "death_spin_grab", "the sequence opens")
	assert_eq(String(grab.get("part", "")), "right_hand", "the NON-flamethrower hand grabs (data-honest)")
	assert_eq(int(grab.get("release_threshold", 0)), 5, "the authored release-on-5 is announced")
	assert_eq((sim.combatants["vic"] as CombatantState).grappled_by, "boss", "R9 state: victim held")
	assert_eq(boss_state(sim).grappling, "vic", "R9 state: boss holding")
	assert_true(boss_state(sim).exposed_cache, "grappling EXPOSES the boss (R9) — the punish window is real")
	assert_eq(int(spin_state(sim).get("beat", 0)), 1, "beat 1 armed at the grab's RESOLUTION")
	# BEAT 2 — CHEW: 2 crushed to BOTH arms through the normal R14 gate.
	var chew_decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(chew_decision.get("choice", "")), "chew", "beat 2: the committed continuation")
	var chewed: Array[Dictionary] = advance(sim, 1)
	assert_event(chewed, "death_spin_chew", "the chew beat resolves")
	var arm_hits: Dictionary = {}
	for hit: Dictionary in events_of(chewed, "damage_applied"):
		arm_hits[String(hit.get("part", ""))] = int(hit.get("amount", -1))
	# R14 per arm: Force = 2 + floor(boss phys 6/2) = 5 − Robustness floor(3/2)
	# = 1 -> net 4 on each 2-HP arm (disabled, crushed T1 rides the wound).
	assert_eq(arm_hits.get("left_arm", -1), 4, "chew nets 4 on the left arm (R14-gated)")
	assert_eq(arm_hits.get("right_arm", -1), 4, "chew nets 4 on the right arm (R14-gated)")
	assert_eq(events_of(chewed, "part_disabled").size(), 2, "both 2-HP arms are disabled")
	assert_true((sim.combatants["vic"] as CombatantState).conditions.has("left_arm"), "crushed rides the left-arm wound")
	assert_eq(int(spin_state(sim).get("beat", 0)), 2, "beat advanced to 2")
	assert_no_event(chewed, "combatant_died", "the chew is the warning, not the kill")
	# BEAT 3 — SPIN-KILL: an honest R14 finisher + the fling down the lane.
	var spin_decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(spin_decision.get("choice", "")), "spin", "beat 3: the finisher")
	var spun: Array[Dictionary] = advance(sim, 1)
	var torso_hit: Dictionary = assert_event(spun, "damage_applied", "the spin strikes the torso line")
	assert_eq(String(torso_hit.get("part", "")), "torso", "at the victim's torso-line part")
	# R14: Force = 8 + floor(6/2) = 11 − Robustness 1 = 10 — fells the fresh
	# 5-HP torso THROUGH the gate (amount 8 PLACEHOLDER R14, never a bypass).
	assert_eq(int(torso_hit.get("amount", -1)), 10, "spin-kill nets 10 (R14-gated, no bypass)")
	var died: Dictionary = assert_event(spun, "combatant_died", "the spin kills")
	assert_eq(String(died.get("combatant", "")), "vic", "the held victim dies")
	assert_eq(String(died.get("killer", "")), "boss", "takedown attribution v2: the boss authored the kill")
	var kill: Dictionary = assert_event(spun, "death_spin_kill", "the sequence closes")
	assert_eq(kill.get("flung_from", []), [1, 0], "flung from the held hex")
	assert_eq(kill.get("flung_to", []), [4, 0], "hurled 3 hexes down the spin lane (boss->victim ray)")
	assert_eq(int(kill.get("hexes_flung", -1)), 3, "the full authored fling distance")
	assert_eq((sim.combatants["vic"] as CombatantState).position, Vector2i(4, 0), "the body actually flew")
	assert_false(bool(kill.get("prone", false)), "a dead victim is down, not prone")
	assert_true(spin_state(sim).is_empty(), "the sequence is over — state cleared")
	assert_eq(boss_state(sim).grappling, "", "the hold ended with the spin")


func test_spin_survivor_lands_prone_and_fling_stops_at_bodies() -> void:
	# The spin-kill is an honest R14 hit, so defenses genuinely intercept it:
	# a braced victim (guard 6 — the same brace seam that buffers any Crush
	# hit) takes 10 − 6 = 4, and the 5-HP torso SURVIVES at 1. The survivor
	# lands PRONE, and a body on the spin lane (an enemy-team blocker, so it
	# never perturbs the boss's decide) shortens the flight: the victim stops
	# on the hex before it.
	var sim: CombatSim = stage()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "walldog", "name": "walldog", "enemy": "roach_dog",
		"team": "enemies", "position": [3, 0],
	}})
	grab_beat(sim)
	ai_decide(sim, "boss")
	advance(sim, 1)  # chew
	(sim.combatants["vic"] as CombatantState).brace_guard = 6  # staged guard (state, like helpless stubs)
	ai_decide(sim, "boss")
	var spun: Array[Dictionary] = advance(sim, 1)
	assert_event(spun, "brace_absorbed", "the guard intercepts the spin like any Crush hit")
	var torso_hit: Dictionary = assert_event(spun, "damage_applied", "the spin still strikes")
	assert_eq(int(torso_hit.get("amount", -1)), 4, "net 10 − guard 6 = 4 (the honest damage path)")
	assert_no_event(spun, "combatant_died", "the 5-HP torso survives at 1")
	var kill: Dictionary = assert_event(spun, "death_spin_kill", "the finisher beat still closes")
	assert_eq(kill.get("flung_to", []), [2, 0], "the body at (3,0) stops the flight one hex short")
	assert_eq(int(kill.get("hexes_flung", -1)), 1, "one hex flown, not three")
	assert_true(bool(kill.get("prone", false)), "the survivor lands PRONE")
	assert_event(spun, "knocked_prone", "the knockdown is a real event")
	assert_true(bool((sim.combatants["vic"] as CombatantState).statuses.get("prone", false)), "prone state set")
	var ended: Dictionary = assert_event(spun, "grapple_ended", "the hold ends even when the victim lives")
	assert_eq(String(ended.get("reason", "")), "death_spin_finished", "released by the finished spin")
	assert_true(spin_state(sim).is_empty(), "sequence cleared")


# ------------------------------------------------------------ release-on-5

func test_net_five_single_hit_forces_the_release() -> void:
	# Ally amount 7 crushed: Force 7+1 = 8 − boss Robustness 3 = net 5 — the
	# authored threshold exactly. The hit resolves before the same-tick chew
	# (declaration order), so the jaws close on air: grip_lost, no chew, abort.
	var sim: CombatSim = stage(true)
	grab_beat(sim)
	declare(sim, "ally", attack_action("crushed", 7, "boss", "right_leg", {"attack_range": 2}))
	ai_decide(sim, "boss")  # the chew is declared — and will fizzle
	var resolved: Array[Dictionary] = advance(sim, 1)
	var released: Dictionary = assert_event(resolved, "death_spin_released", "net 5 forces the release")
	assert_eq(int(released.get("hit", 0)), 5, "the qualifying single hit is reported")
	assert_eq(int(released.get("threshold", 0)), 5, "against the authored threshold")
	var ended: Dictionary = assert_event(resolved, "grapple_ended", "the hold breaks")
	assert_eq(String(ended.get("reason", "")), "forced_release", "as a forced release")
	assert_event(resolved, "action_invalidated", "the same-tick chew closes on air")
	assert_no_event(resolved, "death_spin_chew", "no chew beat lands")
	assert_no_event(resolved, "forced_action_triggered", "grip_lost is not a Tool collapse (R9 family)")
	assert_eq((sim.combatants["vic"] as CombatantState).grappled_by, "", "the victim is free")
	assert_true(spin_state(sim).is_empty(), "the sequence aborted")
	for hit: Dictionary in events_of(resolved, "damage_applied"):
		assert_ne(String(hit.get("combatant", "")), "vic", "the victim took nothing this Moment")


func test_net_four_does_not_release() -> void:
	# Ally amount 6: Force 6+1 = 7 − 3 = net 4 < 5 — the boss shrugs it off
	# and the chew lands on schedule.
	var sim: CombatSim = stage(true)
	grab_beat(sim)
	declare(sim, "ally", attack_action("crushed", 6, "boss", "right_leg", {"attack_range": 2}))
	ai_decide(sim, "boss")
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_no_event(resolved, "death_spin_released", "net 4 is below the authored threshold")
	assert_event(resolved, "death_spin_chew", "the chew lands on schedule")
	assert_eq(int(spin_state(sim).get("beat", 0)), 2, "the sequence marches on")
	assert_eq((sim.combatants["vic"] as CombatantState).grappled_by, "boss", "the victim is still held")


func test_merged_combined_hit_of_five_counts_as_one_hit() -> void:
	# R15/NQ2 seam: the HELD victim and their partner link up — two amount-3
	# halves (Force 4 each) merge BEFORE the gate into ONE 8 − 3 = 5-net hit,
	# and the release fires off the MERGED hit neither member could have
	# forced alone (each solo: 4 − 3 = 1). A grappled victim can still swing —
	# teamwork is the designed counterplay.
	var sim: CombatSim = stage(true)
	grab_beat(sim)
	sim.apply_command({"type": "combined_action", "members": [
		{"actor": "vic", "action": attack_action("crushed", 3, "boss", "right_leg", {"attack_range": 2})},
		{"actor": "ally", "action": attack_action("crushed", 3, "boss", "right_leg", {"attack_range": 2})},
	]})
	ai_decide(sim, "boss")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var merged: Dictionary = assert_event(resolved, "combined_force", "the halves merged")
	assert_eq(int(merged.get("net", 0)), 5, "one merged 5-net hit")
	var released: Dictionary = assert_event(resolved, "death_spin_released", "the merged hit releases")
	assert_eq(int(released.get("hit", 0)), 5, "counted as ONE hit at its merged net")
	assert_true(spin_state(sim).is_empty(), "sequence aborted by teamwork")
	assert_eq((sim.combatants["vic"] as CombatantState).grappled_by, "", "the victim wrestled free")


# ------------------------------------------------------------ the other aborts

func test_r9_escape_aborts_the_sequence() -> void:
	# Physique 6 victim: R9 quick escape (1 Moment, physique >= grappler's).
	# It resolves before the same-tick chew — hold gone, sequence aborted.
	var sim: CombatSim = stage(false, {"physique": 6})
	grab_beat(sim)
	declare(sim, "vic", {"kind": "grapple_escape"})
	ai_decide(sim, "boss")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var escaped: Dictionary = assert_event(resolved, "grapple_ended", "the R9 escape lands")
	assert_eq(String(escaped.get("reason", "")), "escaped", "as a real escape")
	var aborted: Dictionary = assert_event(resolved, "death_spin_aborted", "the sequence aborts")
	assert_eq(String(aborted.get("reason", "")), "grapple_ended", "because the hold broke")
	assert_no_event(resolved, "death_spin_chew", "no chew on a freed victim")
	assert_true(spin_state(sim).is_empty(), "state cleared")
	# The slow path is intended texture: physique < 6 pays 2 Moments — the spin
	# lands first. The party's release-on-5 is that victim's real counterplay.


func test_valve_entry_aborts_the_spin() -> void:
	# The explosion valve OUTRANKS the spin (#27 precedent): the network
	# crossing the phase-2 threshold mid-sequence releases the victim — the
	# boss vents instead of spinning. Staged sub-threshold: breach + drive the
	# network to 36 FIRST, then a net-4 chip (below release-on-5) tips it.
	# The breach hit aims at the LEG on purpose: a net-8 hit on the 8-HP right
	# hand would disable the boss's only grab hand and kill the grab itself
	# (the emergent counterplay test_explosion_beats pins).
	var sim: CombatSim = stage(true)
	declare(sim, "ally", attack_action("crushed", 10, "boss", "right_leg", {"attack_range": 2}))
	advance(sim, 1)  # net 8 single hit >= 7 — breach opens
	assert_true(boss_state(sim).breached, "staging: breached")
	declare(sim, "ally", attack_action("crushed", 16, "boss", "network", {"attack_range": 2}))
	advance(sim, 1)  # net 14: network 50 -> 36, still Threshold 1
	assert_eq(sim.ai.current_phase("boss"), 1, "staging: still in Threshold 1")
	grab_beat(sim)
	assert_eq(int(spin_state(sim).get("beat", 0)), 1, "the grab landed mid-Threshold")
	declare(sim, "ally", attack_action("crushed", 6, "boss", "network", {"attack_range": 2}))
	ai_decide(sim, "boss")  # chew declared
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_no_event(resolved, "death_spin_released", "the net-4 chip never touched the release rule")
	assert_event(resolved, "boss_phase_changed", "the valve opened")
	var aborted: Dictionary = assert_event(resolved, "death_spin_aborted", "the spin aborts honestly")
	assert_eq(String(aborted.get("reason", "")), "explosion_valve", "because the valve outranks (#27)")
	assert_eq((sim.combatants["vic"] as CombatantState).grappled_by, "", "the victim goes free")
	assert_no_event(resolved, "death_spin_kill", "no spin-kill ever fires")
	assert_event(ai_decide(sim, "boss"), "explosion_telegraph", "the boss vents next Moment instead")


func test_victim_death_mid_sequence_aborts_beat_three() -> void:
	# Friendly fire kills the held victim in the chew's own batch (declaration
	# order: the ally's blow resolves first) — the chew closes on air and the
	# sweep aborts the sequence: beat 3 never comes.
	var sim: CombatSim = stage(true)
	grab_beat(sim)
	declare(sim, "ally", attack_action("crushed", 9, "vic", "torso", {"attack_range": 4}))
	ai_decide(sim, "boss")  # chew declared at the still-living victim
	var resolved: Array[Dictionary] = advance(sim, 1)
	var died: Dictionary = assert_event(resolved, "combatant_died", "the ally's blow kills the victim")
	assert_eq(String(died.get("combatant", "")), "vic", "the held victim")
	assert_event(resolved, "action_invalidated", "the chew closes on a corpse-free grip (grip_lost)")
	assert_no_event(resolved, "death_spin_chew", "no chew beat")
	var aborted: Dictionary = assert_event(resolved, "death_spin_aborted", "the sequence aborts")
	assert_eq(String(aborted.get("reason", "")), "victim_out", "because the victim died")
	assert_true(spin_state(sim).is_empty(), "no beat 3 pending anywhere")
	assert_eq(boss_state(sim).grappling, "", "the hold released with the death")


func test_boss_knocked_prone_aborts_the_sequence() -> void:
	var sim: CombatSim = stage()
	grab_beat(sim)
	var events: Array[Dictionary] = sim.apply_command({"type": "set_status", "target": "boss", "status": "prone", "value": true})
	var aborted: Dictionary = assert_event(events, "death_spin_aborted", "grounding the boss breaks the hold")
	assert_eq(String(aborted.get("reason", "")), "boss_downed", "the boss went down")
	assert_event(events, "grapple_ended", "the victim slips the loosened grip")
	assert_eq((sim.combatants["vic"] as CombatantState).grappled_by, "", "free")
	assert_true(spin_state(sim).is_empty(), "state cleared")
	assert_eq(String(first_event(ai_decide(sim, "boss"), "ai_decision").get("choice", "")), "stand",
		"the grounded boss rights itself — the sequence is gone, not resumed")


# ------------------------------------------------------------ the grab hand gate

func test_disabled_grab_hand_blocks_the_grab() -> void:
	# The flamethrower is the LEFT hand (data-honest ruling): the grab needs
	# the RIGHT hand. Disabled right hand = no grab — the AI never decides it
	# (it falls through to the dash) and a hand-built command is rejected.
	var sim: CombatSim = stage()
	boss_state(sim).parts["right_hand"]["disabled"] = true
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("ability", "")), "dash",
		"no functional grab hand -> the boss falls back to the dash")
	assert_ne(String(decision.get("choice", "")), "grab", "the AI never decides a handless grab")
	# Command surface: the explicit death-spin grapple rejects outright.
	var sim2: CombatSim = stage()
	boss_state(sim2).parts["right_hand"]["disabled"] = true
	assert_rejected(declare(sim2, "boss", {
		"kind": "grapple", "target": "vic", "cost": 1,
		"death_spin": true, "grab_part": "right_hand",
	}), "grab_hand_disabled", "a dead grab hand cannot hold a victim")
	# The plain R9 grapple (no death_spin marker) still passes on the OTHER
	# hand — the gate is death-spin-specific, not a new generic R9 rule.
	assert_event(declare(sim2, "boss", {"kind": "grapple", "target": "vic", "cost": 1}),
		"action_declared", "generic R9 grapples keep the any-free-hand rule")


# ------------------------------------------------------------ dash knock-aside

## The dash action exactly as EnemyAI builds it (manual declare so the staging
## controls positions without the decide policy in the way).
func dash_action(target_id: String, lane_to: Vector2i) -> Dictionary:
	var lane: Array = []
	for hex: Vector2i in HexGeometry.line_extended(Vector2i(0, 0), lane_to, 6):
		lane.append([hex.x, hex.y])
	return {
		"kind": "attack", "key": "dash", "cost": 2,
		"damage": {"type": "crushed", "amount": 2},
		"attack_range": 6,
		"targets": [{"id": target_id, "part": "torso"}],
		"dodge": {"threshold": 7, "counter_at": 9},
		"knock_aside": true,
		"area_shape": {"kind": "line", "lane": lane},
	}


func test_connected_dash_knocks_aside_off_lane_and_prone() -> void:
	# Reflexes 2: the dodge is impossible (R22) — the charge CONNECTS. The
	# target is shoved to the first free fixed-order neighbor OFF the lane
	# ((4,0)/(2,0) are lane hexes; (4,-1) = (3,0)+NE is the first-fit) and
	# knocked prone. The 2a charge rule is untouched: the boss still stands
	# adjacent-before the SNAPSHOT hex, now adjacent to an empty hex.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_boss(sim)
	declare(sim, "boss", dash_action("h", Vector2i(3, 0)))
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "damage_applied", "the charge connected")
	var knocked: Dictionary = assert_event(resolved, "knocked_aside", "the authored knock-aside is real")
	assert_eq(String(knocked.get("by", "")), "boss", "attributed to the dasher")
	assert_eq(knocked.get("from", []), [3, 0], "from the struck hex")
	assert_eq(knocked.get("to", []), [4, -1], "to the first free fixed-order neighbor OFF the lane")
	assert_true(bool(knocked.get("displaced", false)), "a real displacement")
	assert_eq((sim.combatants["h"] as CombatantState).position, Vector2i(4, -1), "position moved")
	assert_event(resolved, "knocked_prone", "and knocked PRONE (the 'aside' cost)")
	assert_true(bool((sim.combatants["h"] as CombatantState).statuses.get("prone", false)), "prone set")
	assert_eq(boss_state(sim).position, Vector2i(2, 0), "the 2a stop rule unchanged — adjacent-before the snapshot hex")


func test_knock_aside_with_no_free_neighbor_is_prone_only() -> void:
	# Every off-lane neighbor of (3,0) is a body ((4,0)/(2,0) are lane hexes;
	# the boss itself ends on (2,0)): no displacement, still prone.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_boss(sim)
	for blocker: Array in [[4, -1], [3, -1], [2, 1], [3, 1]]:
		sim.apply_command({"type": "add_combatant", "combatant": {
			"id": "dog_%d_%d" % [int(blocker[0]), int(blocker[1])], "name": "dog",
			"enemy": "roach_dog", "team": "enemies", "position": blocker,
		}})
	declare(sim, "boss", dash_action("h", Vector2i(3, 0)))
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	var knocked: Dictionary = assert_event(resolved, "knocked_aside", "the knock-aside still triggers")
	assert_false(bool(knocked.get("displaced", true)), "nowhere to shove — no displacement")
	assert_eq(knocked.get("to", []), [3, 0], "the target holds its hex")
	assert_eq((sim.combatants["h"] as CombatantState).position, Vector2i(3, 0), "position unchanged")
	assert_true(bool((sim.combatants["h"] as CombatantState).statuses.get("prone", false)),
		"still knocked prone — the 'aside' cost always lands")


func test_dodged_dash_never_knocks_aside() -> void:
	# Reflexes 7 auto-dodges: the R22 sidestep fires INSTEAD — knock-aside and
	# the sidestep are mutually exclusive by construction.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0],
		"traits": {"physique": 3, "reflexes": 7, "mind": 3, "charm": 3}})
	add_boss(sim)
	declare(sim, "boss", dash_action("h", Vector2i(3, 0)))
	advance(sim, 2)
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_event(resolved, "attack_dodged", "the dodge negates the charge")
	assert_event(resolved, "dash_sidestepped", "the dodger takes the VOLUNTARY off-lane step")
	assert_no_event(resolved, "knocked_aside", "a dodged dash never knocks aside")
	assert_no_event(resolved, "knocked_prone", "and never knocks prone")
	assert_false(bool((sim.combatants["h"] as CombatantState).statuses.get("prone", false)), "on their feet")


# ------------------------------------------------------------ decide-order pins

func test_decide_order_cone_beats_grab() -> void:
	# Two opponents inside one 120-degree arc AND one of them adjacent: the
	# crowd sweep stays priority 1 — the grab never preempts the cone.
	var sim: CombatSim = make_sim()
	add_human(sim, "near", {"team": "party", "position": [1, 0]})
	add_human(sim, "far", {"team": "party", "position": [0, 2]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("ability", "")), "flamethrower", "cone > grab: the sweep wins the crowd")
	assert_eq(String(decision.get("choice", "")), "attack", "not a grab")


func test_decide_order_grab_beats_dash_and_two_candidates_cost_one_draw() -> void:
	# Two ADJACENT candidates on opposite sides (no shared arc — the cone is
	# denied): the grab outranks the dash, and the victim pick is the R23
	# weighted draw over the ADJACENT candidates — equidistant fresh targets =
	# the 50/50 anchor, EXACTLY ONE ai_rng draw, twin-predicted.
	var sim: CombatSim = make_sim()
	add_human(sim, "east", {"team": "party", "position": [1, 0]})
	add_human(sim, "west", {"team": "party", "position": [-1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	var boss: CombatantState = boss_state(sim)
	var candidates: Array[CombatantState] = [
		sim.combatants["east"] as CombatantState, sim.combatants["west"] as CombatantState,
	]
	var rows: Array[Dictionary] = sim.ai.targeting_weights(boss, candidates, boss.position)
	assert_eq(float((rows[0] as Dictionary)["weight"]), float((rows[1] as Dictionary)["weight"]),
		"equidistant fresh candidates weigh the same (the 50/50 anchor)")
	var twin := RandomNumberGenerator.new()
	twin.state = sim.ai.ai_rng.state
	var total: float = float((rows[0] as Dictionary)["weight"]) + float((rows[1] as Dictionary)["weight"])
	var expected: String = "east" if twin.randf() * total < float((rows[0] as Dictionary)["weight"]) else "west"
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("choice", "")), "grab", "grab > dash for adjacent targets")
	assert_eq(String(decision.get("ability", "")), "death_spin", "the sequence ability")
	assert_eq(String(decision.get("target", "")), expected, "the victim is the weighted draw")
	assert_eq(sim.ai.ai_rng.state, twin.state, "a two-candidate grab pick consumes EXACTLY one draw")


func test_dash_still_chosen_for_a_non_adjacent_target() -> void:
	# The grab has no step-then-grab: a lone target at distance 3 is dash prey,
	# exactly as before wave 2b.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_boss(sim)
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("ability", "")), "dash", "out of grab range -> the line charge")


func test_every_threshold_phase_reaches_death_spin_and_upgrades_stay_data_only() -> void:
	# death_spin sits in the behavior list of Threshold 1/3/5 — each phase can
	# genuinely reach the grab. The authored phase upgrades ("death spin grab
	# range +1", "death spin costs 2 moments") stay DATA-ONLY until wave 2d:
	# the grab range is flat 1 and the grab beat costs 1 in EVERY phase.
	for phase: int in [1, 3, 5]:
		var sim: CombatSim = stage()
		sim.ai.boss_phase["boss"] = phase
		var events: Array[Dictionary] = ai_decide(sim, "boss")
		var decision: Dictionary = first_event(events, "ai_decision")
		assert_eq(String(decision.get("choice", "")), "grab",
			"Threshold phase %d reaches the grab" % phase)
		var declared: Dictionary = assert_event(events, "action_declared", "declared in phase %d" % phase)
		assert_eq(int(declared.get("cost", 0)), 1,
			"phase %d: the grab beat still costs 1 ('costs 2 moments' upgrade is data-only, wave 2d)" % phase)
		# Range stays flat 1: a distance-2 target is never grabbed in any phase.
		var sim2: CombatSim = make_sim()
		add_human(sim2, "vic", {"team": "party", "position": [2, 0],
			"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
		add_boss(sim2, "boss", {"boss_traits": traits_without_dodge()})
		sim2.ai.boss_phase["boss"] = phase
		var far_decision: Dictionary = first_event(ai_decide(sim2, "boss"), "ai_decision")
		assert_ne(String(far_decision.get("choice", "")), "grab",
			"phase %d: distance 2 is out of grab range ('range +1' upgrade is data-only, wave 2d)" % phase)


# ------------------------------------------------------------ serialization + determinism

func test_mid_sequence_save_restores_the_exact_continuation() -> void:
	var sim: CombatSim = stage()
	grab_beat(sim)
	ai_decide(sim, "boss")
	advance(sim, 1)  # chew resolved — save MID-sequence at beat 2
	assert_eq(int(spin_state(sim).get("beat", 0)), 2, "precondition: mid-sequence")
	var snapshot: Dictionary = sim.to_dict()
	var mid_hash: String = sim.state_hash()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), mid_hash, "roundtrip hash identical mid-sequence")
	assert_eq(int((restored.ai.death_spins.get("boss", {}) as Dictionary).get("beat", 0)), 2,
		"the beat survives the roundtrip")
	# Lockstep: both sims play the identical tail — the spin kills in both.
	var tail: Array[Dictionary] = [
		{"type": "ai_decide", "actor": "boss"}, {"type": "advance_tick"},
	]
	var tail_original: Array[Dictionary] = []
	var tail_restored: Array[Dictionary] = []
	for cmd: Dictionary in tail:
		tail_original.append_array(sim.apply_command(cmd))
		tail_restored.append_array(restored.apply_command(cmd))
	assert_event(tail_original, "death_spin_kill", "the original tail spun")
	assert_event(tail_restored, "death_spin_kill", "the restored tail spun identically")
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash")
	# Mutation teeth: a tampered beat must change the hash.
	var tampered: Dictionary = sim.to_dict()
	var spins: Dictionary = (tampered["ai"] as Dictionary).get("death_spins", {})
	(tampered["ai"] as Dictionary)["death_spins"] = spins  # (empty post-kill — tamper by inserting)
	spins["boss"] = {"beat": 1, "victim": "vic", "part": "right_hand", "started_tick": 0}
	assert_ne(CombatSim.from_dict(tampered).state_hash(), sim.state_hash(),
		"death_spins is covered by the state hash")


func test_same_seed_same_log_twice_is_the_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = stage(true)
		grab_beat(sim)
		declare(sim, "ally", attack_action("crushed", 6, "boss", "right_leg", {"attack_range": 2}))
		ai_decide(sim, "boss")
		advance(sim, 1)  # chew through the net-4 chip
		ai_decide(sim, "boss")
		advance(sim, 1)  # spin-kill
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) -> same hash through a full sequence")
