extends SimTestBase
## Evidence ledger (simulation/evidence_engine.gd) — the small set of REAL
## decisions the verdict quotes. Every test drives the sim through real
## commands (fixed seeds) and asserts the ledger records exactly what happened:
## fire on the real signal, NO entry when the signal is absent (a safe bit, a
## festering-wound breach, a party-side death), determinism + serialization,
## and the view_verdict projection (evidence array + endured + intact fields).


## Authored-bit spec fragment (decision log #25): the sim rejects the_bit from
## an actor with no authored bit, so every test actor who PERFORMS one carries this.
const TEST_BIT: Dictionary = {"key": "bow", "name": "The Bow", "line": "a bow, mid-combat"}


func add_incinedile(sim: CombatSim, id: String = "boss") -> Array[Dictionary]:
	# Strip dodge_threshold (same trick as test_incinedile) so breach staging
	# stays pin-exact without consuming the AI d6 stream.
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	var boss_traits: Dictionary = {}
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			boss_traits = (e.get("traits", {}) as Dictionary).duplicate(true)
	boss_traits.erase("dodge_threshold")
	boss_traits.erase("dodge_threshold_note")
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": boss_traits,
	}})


func entries_of(sim: CombatSim, evidence_type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in sim.evidence.ledger:
		if String(entry.get("type", "")) == evidence_type:
			out.append(entry)
	return out


func make_goal_sim(goals: Array, sim_seed: int = 1234) -> CombatSim:
	var data: Dictionary = SimTestBase.load_static_data()
	data["crowd_goals"] = goals
	return CombatSim.new(sim_seed, data)


# ---------------------------------------------------------------- breach_risk

func test_breach_risk_credits_the_breaching_hitter() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_incinedile(sim)
	# Burst breach path (test_incinedile staging): raw 10 -> net 8 >= 7.
	declare(sim, "h", attack_action("bleeding", 10, "boss", "right_hand"))
	var events: Array[Dictionary] = advance(sim, 1)
	assert_event(events, "breach_opened", "precondition: the hit breached")
	var recorded: Dictionary = assert_event(events, "evidence_recorded", "evidence event rides the same batch")
	assert_eq(String(recorded.get("evidence", "")), "breach_risk", "the batch's evidence is the breach")
	var entries: Array[Dictionary] = entries_of(sim, "breach_risk")
	assert_eq(entries.size(), 1, "exactly one breach_risk entry")
	assert_eq(String(entries[0].get("actor", "")), "h", "credited to the contestant whose hit landed")
	assert_eq(String((entries[0].get("detail", {}) as Dictionary).get("boss", "")), "boss", "detail names the breached boss")
	assert_false(bool((entries[0].get("detail", {}) as Dictionary).get("windup", false)),
		"an instant (cost-1) hit is not a windup commitment")
	assert_true(entries[0].has("tick") and entries[0].has("clock") and entries[0].has("moment"),
		"entry carries its full timestamp")


func test_breach_risk_windup_commitment_is_flagged() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_incinedile(sim)
	# A 2-Moment windup: declared T0, resolves T2 — Exposed the whole way (R2).
	declare(sim, "h", attack_action("bleeding", 10, "boss", "right_hand", {"cost": 2}))
	var events: Array[Dictionary] = advance(sim, 3)
	assert_event(events, "breach_opened", "precondition: the windup hit breached")
	var entries: Array[Dictionary] = entries_of(sim, "breach_risk")
	assert_eq(entries.size(), 1, "one breach_risk entry")
	assert_eq(String(entries[0].get("actor", "")), "h", "credited to the windup attacker")
	assert_true(bool((entries[0].get("detail", {}) as Dictionary).get("windup", false)),
		"detail.windup marks the commitment under exposure")


func test_breach_from_festering_wound_records_nothing() -> void:
	# Bleeding applied by the GM/environment festers to T2 at a Clock reset —
	# the breach opens with NO damaging hit in the batch. Nobody's hit opened
	# it, so recording an attacker would be fabrication. Honest answer: no entry.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_incinedile(sim)
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "left_leg", "condition": "bleeding", "tier": 1})
	var breached := false
	for i: int in range(4):
		if has_event(advance(sim, Clock.TICKS_PER_CLOCK), "breach_opened"):
			breached = true
			break
	assert_true(breached, "precondition: the festering wound really breached")
	assert_eq(entries_of(sim, "breach_risk").size(), 0,
		"a breach nobody's hit opened credits nobody — no breach_risk entry")


# ---------------------------------------------------------------- crowd goals

func test_goal_answered_records_the_completer() -> void:
	var goal: Dictionary = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "deadline_clocks": 3}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "finish_them", "precondition: pinned goal active")
	declare(sim, "a", attack_action("bleeding", 5, "b", "torso"))
	var events: Array[Dictionary] = advance(sim, 3)
	assert_event(events, "hype_goal_completed", "precondition: the kill completed the goal")
	var entries: Array[Dictionary] = entries_of(sim, "goal_answered")
	assert_eq(entries.size(), 1, "one goal_answered entry")
	assert_eq(String(entries[0].get("actor", "")), "a", "credited to the completer (completed_by), not the victim")
	assert_eq(String((entries[0].get("detail", {}) as Dictionary).get("goal", "")), "finish_them", "detail carries the goal id")
	assert_eq(int((entries[0].get("detail", {}) as Dictionary).get("payout", 0)), 80, "detail carries the hype payout")


func test_goal_unanswered_records_party_level_expiry() -> void:
	var goal: Dictionary = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "deadline_clocks": 1}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	advance(sim, Clock.TICKS_PER_CLOCK)      # offer
	var events: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)  # expiry
	assert_event(events, "hype_goal_expired", "precondition: the goal expired un-met")
	var entries: Array[Dictionary] = entries_of(sim, "goal_unanswered")
	assert_eq(entries.size(), 1, "one goal_unanswered entry")
	assert_eq(String(entries[0].get("actor", "")), "", "expiry is party-level evidence (actor \"\")")
	assert_eq(String((entries[0].get("detail", {}) as Dictionary).get("goal", "")), "finish_them", "detail names the dead demand")


# ---------------------------------------------------------------- bit_under_fire

func test_bit_with_bleeding_part_is_evidence() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "bit": TEST_BIT})
	sim.apply_command({"type": "apply_condition", "target": "a", "part": "left_arm", "condition": "bleeding", "tier": 1})
	var events: Array[Dictionary] = sim.apply_command({"type": "bit", "actor": "a"})
	assert_event(events, "bit_performed", "precondition: the bit resolved")
	var entries: Array[Dictionary] = entries_of(sim, "bit_under_fire")
	assert_eq(entries.size(), 1, "a bit while bleeding is evidence")
	assert_eq(String(entries[0].get("actor", "")), "a", "credited to the performer")
	var detail: Dictionary = entries[0].get("detail", {})
	assert_eq(String(detail.get("wounded_part", "")), "left_arm", "detail names the wounded part")
	assert_true(bool(detail.get("bleeding", false)), "and that it was bleeding")


func test_bit_with_adjacent_enemy_is_evidence() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "bit": TEST_BIT})
	add_human(sim, "m", {"team": "enemies", "position": [1, 0]})
	var events: Array[Dictionary] = sim.apply_command({"type": "bit", "actor": "a"})
	assert_event(events, "bit_performed", "precondition: the bit resolved")
	var entries: Array[Dictionary] = entries_of(sim, "bit_under_fire")
	assert_eq(entries.size(), 1, "a bit with a live hostile 1 hex away is evidence")
	assert_eq(String((entries[0].get("detail", {}) as Dictionary).get("enemy_adjacent", "")), "m",
		"detail names the hostile in reach")


func test_safe_bit_is_not_evidence() -> void:
	# Unhurt, and the only hostile is 4 hexes away — a safe bit proves nothing.
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party", "bit": TEST_BIT})
	add_human(sim, "m", {"team": "enemies", "position": [4, 0]})
	var events: Array[Dictionary] = sim.apply_command({"type": "bit", "actor": "a"})
	assert_event(events, "bit_performed", "precondition: the bit resolved")
	assert_eq(entries_of(sim, "bit_under_fire").size(), 0, "an unhurt, unthreatened bit records NOTHING")
	assert_no_event(events, "evidence_recorded", "no evidence event either")


# ---------------------------------------------------------------- spotlight_gamble

func test_camera_call_while_hurt_is_a_gamble() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "s", {"team": "party", "camera_call_stacks": 1})
	add_human(sim, "b", {"team": "party", "position": [1, 0]})
	sim.apply_command({"type": "apply_condition", "target": "s", "part": "torso", "condition": "bleeding", "tier": 1})
	var events: Array[Dictionary] = sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"})
	assert_event(events, "hype_camera_call_started", "precondition: the call started")
	var entries: Array[Dictionary] = entries_of(sim, "spotlight_gamble")
	assert_eq(entries.size(), 1, "calling the spotlight while hurt is evidence")
	assert_eq(String(entries[0].get("actor", "")), "s", "credited to the caller")
	assert_eq(String((entries[0].get("detail", {}) as Dictionary).get("wounded_part", "")), "torso",
		"detail names the caller's wound")


func test_camera_call_while_unhurt_records_nothing() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "s", {"team": "party", "camera_call_stacks": 1})
	add_human(sim, "b", {"team": "party", "position": [1, 0]})
	var events: Array[Dictionary] = sim.apply_command({"type": "camera_call", "actor": "s", "target": "b"})
	assert_event(events, "hype_camera_call_started", "precondition: the call started")
	assert_eq(entries_of(sim, "spotlight_gamble").size(), 0, "an unhurt call is not evidence of anything")


# ---------------------------------------------------------------- stabilized

func test_stabilized_is_party_level_and_names_the_saved() -> void:
	# KAN-2 acceptance staging: torso bled to 0 by condition -> bleed-out; a
	# treat(delay) on the causing condition stabilizes. The treat command names
	# no treater, so the entry is honestly party-level.
	var sim: CombatSim = make_sim()
	add_human(sim, "b1", {"team": "party"})
	sim.apply_command({"type": "apply_condition", "target": "b1", "part": "torso", "condition": "bleeding", "tier": 1})
	advance(sim, Clock.TICKS_PER_CLOCK)
	var reset2: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_event(reset2, "bleed_out_started", "precondition: bleed-out started")
	var treat_events: Array[Dictionary] = sim.apply_command({"type": "treat", "target": "b1", "part": "torso", "condition": "bleeding", "mode": "delay"})
	assert_event(treat_events, "bleed_out_stabilized", "precondition: stabilized")
	var entries: Array[Dictionary] = entries_of(sim, "stabilized")
	assert_eq(entries.size(), 1, "the clutch save is evidence")
	assert_eq(String(entries[0].get("actor", "")), "", "party-level: the treat command names no treater")
	assert_eq(String((entries[0].get("detail", {}) as Dictionary).get("saved", "")), "b1", "detail names who was saved")


# ---------------------------------------------------------------- takedown

func test_takedown_credits_the_killer_of_an_enemy() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party"})
	add_human(sim, "m", {"team": "enemies", "position": [1, 0]})
	declare(sim, "h", attack_action("crushed", 5, "m", "torso"))
	var events: Array[Dictionary] = advance(sim, 1)
	assert_event(events, "combatant_died", "precondition: the enemy died")
	var entries: Array[Dictionary] = entries_of(sim, "takedown")
	assert_eq(entries.size(), 1, "an enemy kill with a credited contestant is evidence")
	assert_eq(String(entries[0].get("actor", "")), "h", "credited to the killer")
	assert_eq(String((entries[0].get("detail", {}) as Dictionary).get("victim", "")), "m", "detail names the victim")


func test_party_death_is_not_a_takedown() -> void:
	# A contestant killing a PARTY member (friendly fire) is not a takedown.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party"})
	add_human(sim, "p", {"team": "party", "position": [1, 0]})
	declare(sim, "h", attack_action("crushed", 5, "p", "torso"))
	var events: Array[Dictionary] = advance(sim, 1)
	assert_event(events, "combatant_died", "precondition: the party member died")
	assert_eq(entries_of(sim, "takedown").size(), 0, "a party-side death is never a takedown entry")


# ---------------------------------------------------------------- determinism + serialization

## Drives a mixed evidence-earning sequence: a takedown, a wounded bit, a
## windup breach, and idle Clocks (goal traffic).
func _earn_some_evidence(sim: CombatSim) -> void:
	# h performs a wounded bit below — h carries an authored bit (decision #25).
	add_human(sim, "h", {"team": "party", "position": [1, 0], "bit": TEST_BIT})
	add_human(sim, "m", {"team": "enemies", "position": [2, 0]})
	add_incinedile(sim)
	declare(sim, "h", attack_action("crushed", 5, "m", "torso"))
	advance(sim, 1)
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "left_arm", "condition": "bleeding", "tier": 1})
	sim.apply_command({"type": "bit", "actor": "h"})
	declare(sim, "h", attack_action("bleeding", 10, "boss", "right_hand", {"cost": 2}))
	advance(sim, 3)
	sim.apply_command({"type": "treat", "target": "h", "part": "left_arm", "condition": "bleeding", "mode": "resolve"})
	advance(sim, Clock.TICKS_PER_CLOCK)


func test_determinism_same_log_same_ledger() -> void:
	var sim1: CombatSim = make_sim(4242)
	var sim2: CombatSim = make_sim(4242)
	_earn_some_evidence(sim1)
	_earn_some_evidence(sim2)
	assert_eq(sim1.evidence.to_dict(), sim2.evidence.to_dict(), "same log -> identical evidence ledger")
	assert_eq(sim1.state_hash(), sim2.state_hash(), "state_hash covers the ledger and stays replay-stable")
	assert_true(sim1.evidence.ledger.size() >= 3, "precondition: the run actually earned evidence (%d)" % sim1.evidence.ledger.size())


func test_ledger_serialization_roundtrip() -> void:
	var sim: CombatSim = make_sim(4242)
	_earn_some_evidence(sim)
	assert_false(sim.evidence.ledger.is_empty(), "precondition: there is evidence to preserve")
	var resumed: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(resumed.evidence.to_dict(), sim.evidence.to_dict(), "ledger survives to_dict/from_dict")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hash identical after round-trip")
	# Resumed timeline stays in lockstep — new evidence lands identically.
	for s: CombatSim in [sim, resumed]:
		s.apply_command({"type": "apply_condition", "target": "h", "part": "torso", "condition": "bleeding", "tier": 1})
		s.apply_command({"type": "bit", "actor": "h"})
		advance(s, Clock.TICKS_PER_CLOCK)
	assert_eq(resumed.evidence.to_dict(), sim.evidence.to_dict(), "resumed run tracks the uninterrupted run")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hashes stay identical after resume")


func test_windup_mirror_survives_a_mid_windup_save() -> void:
	# Save taken BETWEEN declare and resolution: the resumed sim must still flag
	# the breach as a windup commitment (the mirror is serialized state).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_incinedile(sim)
	declare(sim, "h", attack_action("bleeding", 10, "boss", "right_hand", {"cost": 2}))
	var resumed: CombatSim = CombatSim.from_dict(sim.to_dict())
	var events: Array[Dictionary] = []
	for i: int in range(3):
		events.append_array(resumed.apply_command({"type": "advance_tick"}))
	assert_event(events, "breach_opened", "precondition: the resumed windup landed and breached")
	var entries: Array[Dictionary] = []
	for entry: Dictionary in resumed.evidence.ledger:
		if String(entry.get("type", "")) == "breach_risk":
			entries.append(entry)
	assert_eq(entries.size(), 1, "the resumed sim recorded the breach")
	assert_true(bool((entries[0].get("detail", {}) as Dictionary).get("windup", false)),
		"the serialized windup mirror carried the commitment across the save")


func test_ledger_is_chronological() -> void:
	var sim: CombatSim = make_sim(4242)
	_earn_some_evidence(sim)
	var last_tick: int = -1
	for entry: Dictionary in sim.evidence.ledger:
		assert_true(int(entry.get("tick", -1)) >= last_tick,
			"ledger ticks never go backwards (%d after %d)" % [int(entry.get("tick", -1)), last_tick])
		last_tick = int(entry.get("tick", -1))


# ---------------------------------------------------------------- view_verdict

func test_view_verdict_evidence_projection() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, load_static_data())
	# This staged "imani" performs a wounded bit below, so the spec grants her an
	# authored bit (decision #25) — a TEST fixture choice, not the canon loadout
	# (canonically Imani has NO bit; Dario does).
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "imani", "name": "Imani \"The Door\"", "race": "human", "team": "party",
		"position": [1, 0], "traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3},
		"bit": TEST_BIT}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "m", "name": "Grunt", "race": "human", "team": "enemies", "position": [2, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	# Real deeds through the command funnel: a takedown + a wounded bit.
	game.apply_command({"type": "declare_action", "actor": "imani",
		"action": attack_action("crushed", 5, "m", "torso")})
	game.apply_command({"type": "advance_tick"})
	game.apply_command({"type": "apply_condition", "target": "imani", "part": "left_arm", "condition": "bleeding", "tier": 1})
	game.apply_command({"type": "bit", "actor": "imani"})

	var v: Dictionary = game.view_verdict("imani")
	# New fields present and well-formed.
	var evidence: Array = v.get("evidence", [])
	assert_eq(evidence.size(), 2, "both real deeds project (takedown + bit_under_fire)")
	var last_tick: int = -1
	for e: Variant in evidence:
		var entry: Dictionary = e
		assert_true(String(entry.get("line", "")).length() > 0, "every entry carries a composed line")
		var actor := String(entry.get("actor", ""))
		assert_true(actor == "imani" or actor == "", "only own + party-level entries project")
		assert_true(int(entry.get("tick", -1)) >= last_tick, "evidence stays chronological")
		last_tick = int(entry.get("tick", -1))
	assert_eq(String((evidence[0] as Dictionary).get("type", "")), "takedown", "first deed is the kill")
	assert_eq(String((evidence[1] as Dictionary).get("type", "")), "bit_under_fire", "second is the wounded bit")
	var endured: Dictionary = v.get("endured", {})
	assert_true(bool(endured.get("survived", false)), "endured reflects survival")
	assert_eq(int(endured.get("parts_lost", -1)), 0, "no parts lost in this run")
	# Existing fields unchanged (the HUD/tests depend on them).
	for key: String in ["contestant", "outcome", "hype_earned", "peak_band", "epithet",
			"patron_standing", "crowd_verdict", "boss", "slice_win", "tagline"]:
		assert_true(v.has(key), "existing verdict field '%s' still present" % key)
	assert_eq(String(v.get("outcome", "")), "SURVIVED", "outcome unchanged by the evidence upgrade")

	# endured picks up a destroyed part (harness poke, like the other view tests).
	game.sim.combatants["imani"].parts["left_arm"]["destroyed"] = true
	var endured2: Dictionary = game.view_verdict("imani").get("endured", {})
	assert_eq(int(endured2.get("parts_lost", 0)), 1, "a destroyed part counts as endured")
	assert_eq((endured2.get("parts", []) as Array), ["left_arm"], "and is named")
	assert_true(String(endured2.get("line", "")).length() > 0, "surviving with losses composes a line")
	game.free()


func test_view_verdict_includes_party_level_entries() -> void:
	var goal: Dictionary = {"id": "overkill", "name": "OVERKILL!", "kind": "overkill", "params": {"threshold": 99}, "payout": 60, "deadline_clocks": 1}
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	var data: Dictionary = SimTestBase.load_static_data()
	data["crowd_goals"] = [goal]
	game.start_combat(7, data)
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "imani", "name": "Imani", "race": "human", "team": "party",
		"position": [1, 0], "traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}}})
	for i: int in range(2 * Clock.TICKS_PER_CLOCK):
		game.apply_command({"type": "advance_tick"})
	var evidence: Array = game.view_verdict("imani").get("evidence", [])
	assert_eq(evidence.size(), 1, "the expired goal projects for the contestant")
	var entry: Dictionary = evidence[0]
	assert_eq(String(entry.get("type", "")), "goal_unanswered", "as party-level goal_unanswered")
	assert_eq(String(entry.get("actor", "")), "", "actor stays party-level")
	assert_true(String(entry.get("line", "")).contains("OVERKILL!"), "the line quotes the dead demand")
	game.free()
