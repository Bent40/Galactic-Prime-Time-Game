extends SimTestBase
## R11 #14 takedown attribution v2 (task #13, owner-RULED 2026-07-18):
## "takedown = a kill YOU caused" — a friendly death completes the takedown
## goal ONLY IF a contestant dealt the killing blow (friendly fire counts —
## "it's cinema"); the payout is credited to that killer; enemy deaths still
## complete it. This file drives every attribution edge through real commands:
## direct killing blows, cross-batch condition deaths off seeded wounds,
## non-contestant killers (the v1 over-fire regression), environment deaths,
## merged combined-force killing hits, forced-action collateral kills,
## explosion knockouts (KO only — never a kill), and save/restore determinism
## with pending wound-source bookkeeping.


const TAKEDOWN_GOAL: Dictionary = {
	"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown",
	"params": {}, "payout": 80, "deadline_clocks": 9,
}


func make_goal_sim(goals: Array, sim_seed: int = 1234) -> CombatSim:
	var data: Dictionary = SimTestBase.load_static_data()
	data["crowd_goals"] = goals
	return CombatSim.new(sim_seed, data)


func entries_of(sim: CombatSim, evidence_type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in sim.evidence.ledger:
		if String(entry.get("type", "")) == evidence_type:
			out.append(entry)
	return out


## Advances Clock by Clock (up to `clocks`) collecting every event; stops once
## `victim` dies. Returns everything seen.
func advance_until_death(sim: CombatSim, victim: String, clocks: int) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(clocks):
		seen.append_array(advance(sim, Clock.TICKS_PER_CLOCK))
		if not (sim.combatants[victim] as CombatantState).alive:
			break
	return seen


## A Mob-category enemy with one deterministic lethal bite (single opponent =
## zero ai_rng draws, no dodge block = no dodge — fully pinned).
func add_chomper(sim: CombatSim, id: String = "mob", position: Array = [0, 0]) -> void:
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "category": "Mob", "team": "enemies", "position": position,
		"traits": {"physique": 10, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [{"key": "torso", "hp": 40, "lethal": true}],
		"abilities": [{"key": "chomp", "damage": [{"type": "crushed", "amount": 9}], "range": 1, "moment_cost": 1}],
	}})


# ---------------------------------------------------------------- direct killing blow

func test_direct_kill_names_the_killer_on_the_event() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party"})
	add_human(sim, "m", {"team": "enemies", "position": [1, 0]})
	declare(sim, "h", attack_action("crushed", 5, "m", "torso"))
	var events: Array[Dictionary] = advance(sim, 1)
	var died: Dictionary = assert_event(events, "combatant_died", "the strike killed")
	assert_eq(String(died.get("killer", "")), "h", "combatant_died carries the killing blow's author")
	assert_eq(String(died.get("cause", "")), "vital_part_destroyed", "direct kill cause")
	var entries: Array[Dictionary] = entries_of(sim, "takedown")
	assert_eq(entries.size(), 1, "one takedown entry")
	assert_eq(String(entries[0].get("actor", "")), "h", "credited to the striker")
	var detail: Dictionary = entries[0].get("detail", {})
	assert_eq(String(detail.get("cause", "")), "vital_part_destroyed", "detail carries the death route")
	assert_false(detail.has("friendly_fire"), "an enemy kill is not flagged friendly fire")


# ---------------------------------------------------------------- condition deaths off seeded wounds

func test_enemy_bleed_out_from_your_wound_is_your_takedown() -> void:
	# v1 recorded NOTHING for a clock-driven death (no closer in the batch);
	# v2's wound-source bookkeeping names the seeder as the killer.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party"})
	add_human(sim, "m", {"team": "enemies", "position": [1, 0]})
	declare(sim, "h", attack_action("bleeding", 1, "m", "torso"))
	var seeded: Array[Dictionary] = advance(sim, 1)
	assert_event(seeded, "condition_applied", "precondition: the wound seeded")
	assert_true((sim.combatants["m"] as CombatantState).alive, "precondition: the poke did not kill outright")
	var events: Array[Dictionary] = advance_until_death(sim, "m", 8)
	var died: Dictionary = assert_event(events, "combatant_died", "the seeded wound eventually killed")
	assert_eq(String(died.get("killer", "")), "h", "the cross-batch condition death names the wound's seeder")
	assert_true(String(died.get("cause", "")) != "", "and carries a real cause")
	var entries: Array[Dictionary] = entries_of(sim, "takedown")
	assert_eq(entries.size(), 1, "the bleed-out is a takedown entry (v2 — v1 dropped it)")
	assert_eq(String(entries[0].get("actor", "")), "h", "credited to the seeder")
	assert_false((entries[0].get("detail", {}) as Dictionary).has("friendly_fire"), "enemy victim — no friendly-fire flag")


func test_friendly_bleed_out_completes_goal_and_credits_the_seeder() -> void:
	# The ruled sentence end-to-end, cross-batch: a FRIENDLY death completes the
	# takedown goal because a contestant dealt the killing blow (the seeded
	# wound), the payout is credited to that killer, and the evidence surfaces
	# the friendly fire distinctly.
	var sim: CombatSim = make_goal_sim([TAKEDOWN_GOAL])
	add_human(sim, "h", {"team": "party"})
	add_human(sim, "p", {"team": "party", "position": [1, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "finish_them", "precondition: pinned goal active")
	declare(sim, "h", attack_action("bleeding", 1, "p", "torso"))
	advance(sim, 1)
	var events: Array[Dictionary] = advance_until_death(sim, "p", 6)
	var died: Dictionary = assert_event(events, "combatant_died", "the friendly bled out")
	assert_eq(String(died.get("killer", "")), "h", "killer = the wound's seeder")
	var done: Dictionary = assert_event(events, "hype_goal_completed",
		"a friendly death WITH a contestant killing blow completes the takedown goal (R11 #14 v2)")
	assert_eq(String(done.get("completed_by", "")), "h", "the completer is the killer, not the victim")
	assert_eq(int(sim.hype.ledger.get("h", 0)), int(done.get("spectacle_points", -1)),
		"the payout ledger row goes to the killer (his only credit this run)")
	var entries: Array[Dictionary] = entries_of(sim, "takedown")
	assert_eq(entries.size(), 1, "one takedown entry")
	assert_eq(String(entries[0].get("actor", "")), "h", "credited to the killer")
	assert_true(bool((entries[0].get("detail", {}) as Dictionary).get("friendly_fire", false)),
		"friendly fire is surfaced distinctly")


# ---------------------------------------------------------------- non-contestant killer (the v1 over-fire)

func test_friendly_death_by_enemy_completes_nothing() -> void:
	# THE tracked v1 gap: the goal used to over-fire on ANY combatant_died. A
	# mob killing a contestant is a friendly death with NO contestant killing
	# blow — no goal completion, no takedown evidence.
	var sim: CombatSim = make_goal_sim([TAKEDOWN_GOAL])
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_chomper(sim)
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "finish_them", "precondition: pinned goal active")
	sim.apply_command({"type": "ai_decide", "actor": "mob"})
	var events: Array[Dictionary] = advance(sim, 1)
	var died: Dictionary = assert_event(events, "combatant_died", "the mob killed the contestant")
	assert_eq(String(died.get("combatant", "")), "h", "the victim is the contestant")
	assert_eq(String(died.get("killer", "")), "mob", "the killer is honestly named — and is no contestant")
	assert_no_event(events, "hype_goal_completed",
		"a friendly death without a contestant killing blow completes NOTHING (v1 over-fired here)")
	assert_false(sim.hype.active_goal.is_empty(), "the crowd's demand is still open")
	assert_eq(entries_of(sim, "takedown").size(), 0, "and it is nobody's takedown evidence")


func test_environment_wound_death_credits_nobody() -> void:
	# An authorless (GM/environment) wound festering a FRIENDLY out: killer "",
	# no goal completion, no evidence — never guessed.
	var sim: CombatSim = make_goal_sim([TAKEDOWN_GOAL])
	add_human(sim, "h", {"team": "party"})
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "torso", "condition": "crushed", "tier": 1})
	var events: Array[Dictionary] = advance_until_death(sim, "h", 8)
	var died: Dictionary = assert_event(events, "combatant_died", "the environment wound killed")
	assert_eq(String(died.get("killer", "")), "", "no author — killer stays empty, never guessed")
	assert_no_event(events, "hype_goal_completed", "an authorless friendly death completes nothing")
	assert_eq(entries_of(sim, "takedown").size(), 0, "and records no takedown evidence")


func test_environment_enemy_death_still_completes_the_goal() -> void:
	# "Enemy deaths still complete it" — even authorless ones. But with no
	# contestant author there is no personal credit: no takedown evidence.
	var sim: CombatSim = make_goal_sim([TAKEDOWN_GOAL])
	add_human(sim, "h", {"team": "party", "position": [3, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "m", "name": "m", "category": "Mob", "team": "enemies", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [{"key": "torso", "hp": 5, "lethal": true}],
	}})
	sim.apply_command({"type": "apply_condition", "target": "m", "part": "torso", "condition": "crushed", "tier": 1})
	var events: Array[Dictionary] = advance_until_death(sim, "m", 8)
	var died: Dictionary = assert_event(events, "combatant_died", "the enemy died to the environment wound")
	assert_eq(String(died.get("killer", "")), "", "authorless death")
	assert_event(events, "hype_goal_completed", "an enemy death still completes the takedown goal")
	assert_eq(entries_of(sim, "takedown").size(), 0, "but nobody earns takedown evidence for it")


# ---------------------------------------------------------------- merged killing hit

func test_merged_killing_hit_credits_the_closing_hitter() -> void:
	# The merged hit is ONE blow; the ruling's singular "that killer" + the
	# breach_risk closing-hitter convention give SINGLE credit to the last
	# member whose strike actually connected (declaration order: p2).
	var sim: CombatSim = make_sim(11)
	add_human(sim, "p1", {"team": "party", "position": [0, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "p2", {"team": "party", "position": [2, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "t", "name": "t", "category": "Mob", "team": "enemies", "size": "Large", "position": [1, 0],
		"traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [{"key": "hide", "hp": 5, "lethal": true}],
	}})
	sim.apply_command({"type": "combined_action", "members": [
		{"actor": "p1", "action": attack_action("crushed", 3, "t", "hide")},
		{"actor": "p2", "action": attack_action("crushed", 3, "t", "hide")},
	]})
	var events: Array[Dictionary] = advance(sim, 1)
	var cf: Dictionary = assert_event(events, "combined_force", "the merged hit landed")
	assert_eq(cf.get("actors", []), ["p1", "p2"], "both members connected")
	var died: Dictionary = assert_event(events, "combatant_died", "the merged hit killed")
	assert_eq(String(died.get("killer", "")), "p2", "the closing (last-connected) hitter authored the blow")
	var entries: Array[Dictionary] = entries_of(sim, "takedown")
	assert_eq(entries.size(), 1, "ONE takedown entry — single credit, not per member")
	assert_eq(String(entries[0].get("actor", "")), "p2", "credited to the closing hitter")


# ---------------------------------------------------------------- forced-action collateral kill

func test_forced_collateral_kill_credits_the_flailing_actor() -> void:
	# The victim of a Tool-3 Collateral is killed by the ACTOR whose forced
	# action misfired — the wild swing is still their blow (friendly fire
	# counts, Q69). The d6 is real sim RNG, so hunt a seed whose unmet-
	# requirements Tool roll comes up 3 (deterministic per seed).
	var found: bool = false
	for sim_seed: int in range(1, 61):
		var sim: CombatSim = make_goal_sim([TAKEDOWN_GOAL], sim_seed)
		add_human(sim, "a", {"team": "party", "position": [0, 0]})
		sim.apply_command({"type": "add_combatant", "combatant": {
			"id": "frail", "name": "frail", "team": "party", "position": [1, 0],
			"traits": {"physique": 1, "reflexes": 1, "mind": 1, "charm": 1},
			"body_parts": [{"key": "torso", "hp": 1, "lethal": true}],
		}})
		add_human(sim, "m", {"team": "enemies", "position": [1, -1]})
		advance(sim, Clock.TICKS_PER_CLOCK)
		declare(sim, "a", attack_action("crushed", 3, "m", "torso", {"requirements": {"physique": 99}}))
		var events: Array[Dictionary] = advance(sim, 1)
		var forced: Dictionary = first_event(events, "forced_action_triggered")
		assert_eq(String(forced.get("reason", "")), "unmet_requirements", "seed %d: the Tool table rolled" % sim_seed)
		if String(forced.get("consequence", "")) != "collateral":
			continue
		found = true
		var hit: Dictionary = assert_event(events, "collateral_hit", "the collateral connected")
		assert_eq(String(hit.get("victim", "")), "frail", "nearest bystander (not actor, not intended target)")
		var died: Dictionary = assert_event(events, "combatant_died", "and killed the 1-hp bystander")
		assert_eq(String(died.get("combatant", "")), "frail", "the bystander died")
		assert_eq(String(died.get("killer", "")), "a", "the flailing actor authored the killing blow")
		assert_event(events, "hype_goal_completed", "a contestant's killing blow completes the goal — friendly fire counts")
		var entries: Array[Dictionary] = entries_of(sim, "takedown")
		assert_eq(entries.size(), 1, "one takedown entry")
		assert_eq(String(entries[0].get("actor", "")), "a", "credited to the actor whose swing went wide")
		assert_true(bool((entries[0].get("detail", {}) as Dictionary).get("friendly_fire", false)), "flagged friendly fire")
		break
	assert_true(found, "a collateral roll (Tool 3) was found within the seed range")


# ---------------------------------------------------------------- self-kill (literal reading, unit level)

func test_self_kill_attributes_to_the_victim_literal_reading() -> void:
	# The ruled text does not carve out self-kills: the victim of their own
	# forced action IS "a contestant [who] dealt the killing blow". Engine
	# routes exist (tear_something on a spent lethal acting part; any forced
	# self-damage during bleed-out) but need deep staging, so the consumer
	# policy is pinned at ingest level: killer == victim still completes the
	# goal, still credits the (dead) killer, and the evidence flags it.
	var sim: CombatSim = make_goal_sim([TAKEDOWN_GOAL])
	add_human(sim, "h", {"team": "party"})
	sim.hype.active_goal = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "clocks_left": 3}
	var batch: Array[Dictionary] = [
		{"type": "combatant_died", "combatant": "h", "cause": "damage_during_bleed_out", "killer": "h"},
	]
	var hype_out: Array[Dictionary] = sim.hype.ingest(batch)
	var done: Dictionary = assert_event(hype_out, "hype_goal_completed", "a contestant's killing blow — even their own — completes the goal (literal text)")
	assert_eq(String(done.get("completed_by", "")), "h", "credited to that killer (the victim)")
	var evidence_out: Array[Dictionary] = sim.evidence.ingest(batch)
	assert_event(evidence_out, "evidence_recorded", "the self-kill is recorded")
	var entries: Array[Dictionary] = entries_of(sim, "takedown")
	assert_eq(entries.size(), 1, "one takedown entry")
	assert_eq(String(entries[0].get("actor", "")), "h", "actor == victim (own killing blow)")
	assert_true(bool((entries[0].get("detail", {}) as Dictionary).get("friendly_fire", false)), "self counts as friendly fire")


func test_legacy_event_without_killer_falls_back_to_batch_credit() -> void:
	# Pre-v2 saves resume with unsourced wounds; their death events carry no
	# killer. The I-13 credited_actor batch scan stays as the honest fallback.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party"})
	add_human(sim, "m", {"team": "enemies", "position": [1, 0]})
	var batch: Array[Dictionary] = [
		{"type": "damage_applied", "combatant": "m", "part": "torso", "amount": 5, "source": "weapon"},
		{"type": "combatant_died", "combatant": "m", "cause": "vital_part_destroyed"},
		{"type": "action_resolved", "actor": "h", "kind": "attack", "result": "ok", "rounds": 1},
	]
	sim.evidence.ingest(batch)
	var entries: Array[Dictionary] = entries_of(sim, "takedown")
	assert_eq(entries.size(), 1, "the legacy batch still records the takedown")
	assert_eq(String(entries[0].get("actor", "")), "h", "credited via the batch scan fallback")


# ---------------------------------------------------------------- explosion KO is never a kill

func test_explosion_blast_knockouts_never_generate_takedowns() -> void:
	# Decision #27: the blast KOs (Helpless 2 Clocks) — no damage, no death.
	# Assert the whole beat produces no combatant_died and no takedown.
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	var boss_traits: Dictionary = {}
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			boss_traits = (e.get("traits", {}) as Dictionary).duplicate(true)
	boss_traits.erase("dodge_threshold")
	boss_traits.erase("dodge_threshold_note")
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_human(sim, "bystander", {"team": "party", "position": [2, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": boss_traits,
	}})
	var seen: Array[Dictionary] = []
	# Valve-I entry (test_explosion_beats staging): burst breach, then drive the
	# network into phase 2 — the explosion beat.
	declare(sim, "h", attack_action("crushed", 10, "boss", "right_hand"))
	seen.append_array(advance(sim, 1))
	declare(sim, "h", attack_action("crushed", 17, "boss", "network"))
	seen.append_array(advance(sim, 1))
	assert_event(seen, "boss_phase_changed", "precondition: the valve opened")
	# Telegraph, two escape Moments, blast.
	seen.append_array(sim.apply_command({"type": "ai_decide", "actor": "boss"}))
	for i: int in range(2):
		seen.append_array(advance(sim, 1))
		seen.append_array(sim.apply_command({"type": "ai_decide", "actor": "boss"}))
	seen.append_array(advance(sim, 1))
	var blast_events: Array[Dictionary] = sim.apply_command({"type": "ai_decide", "actor": "boss"})
	seen.append_array(blast_events)
	assert_event(blast_events, "explosion_blast", "the blast resolved")
	assert_true(events_of(blast_events, "explosion_knockout").size() >= 1, "contestants in radius were knocked out")
	assert_no_event(seen, "combatant_died", "the whole beat kills NOBODY — knockouts only")
	assert_eq(entries_of(sim, "takedown").size(), 0, "and generates no takedown evidence")
	for id: String in ["h", "bystander"]:
		assert_true((sim.combatants[id] as CombatantState).alive, "%s is alive (KO, not dead)" % id)


# ---------------------------------------------------------------- determinism + serialization

func test_save_restore_mid_bleed_out_preserves_attribution() -> void:
	# Save taken with PENDING wound-source bookkeeping in flight (a seeded
	# bleeding instance, a live bleed_out + grace timer, all carrying their
	# author): identical hash at the save point, and the resumed timeline must
	# reach the identical eventual attribution.
	var sim: CombatSim = make_goal_sim([TAKEDOWN_GOAL], 4242)
	add_human(sim, "h", {"team": "party"})
	add_human(sim, "p", {"team": "party", "position": [1, 0]})
	declare(sim, "h", attack_action("bleeding", 1, "p", "torso"))
	advance(sim, 1)
	var pre_death: Array[Dictionary] = []
	for i: int in range(6):
		pre_death.append_array(advance(sim, Clock.TICKS_PER_CLOCK))
		if not (first_event(pre_death, "bleed_out_started")).is_empty():
			break
	assert_event(pre_death, "bleed_out_started", "precondition: the bleed-out grace is running at the save point")
	assert_true((sim.combatants["p"] as CombatantState).alive, "precondition: the victim is still alive mid-fight")
	var p: CombatantState = sim.combatants["p"]
	assert_eq(String(p.bleed_out.get("source", "")), "h", "pending bleed_out carries its author")
	assert_eq(String(((p.conditions.get("torso", {}) as Dictionary).get("bleeding", {}) as Dictionary).get("source", "")), "h",
		"the condition instance carries its author")
	var resumed: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(resumed.state_hash(), sim.state_hash(), "identical hash with pending wound-source bookkeeping")
	var rp: CombatantState = resumed.combatants["p"]
	assert_eq(String(rp.bleed_out.get("source", "")), "h", "the author survives the round-trip")
	# Both timelines finish identically: same killer, same evidence, same hash.
	var live_events: Array[Dictionary] = advance_until_death(sim, "p", 4)
	var resumed_events: Array[Dictionary] = advance_until_death(resumed, "p", 4)
	var live_died: Dictionary = assert_event(live_events, "combatant_died", "live timeline: the victim died")
	var resumed_died: Dictionary = assert_event(resumed_events, "combatant_died", "resumed timeline: the victim died")
	assert_eq(String(live_died.get("killer", "")), "h", "live attribution names the seeder")
	assert_eq(String(resumed_died.get("killer", "")), String(live_died.get("killer", "")), "identical eventual attribution")
	assert_eq(resumed.evidence.to_dict(), sim.evidence.to_dict(), "identical evidence ledgers")
	assert_eq(resumed.hype.to_dict(), sim.hype.to_dict(), "identical hype state (goal completion + payout credit)")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hashes stay identical after the death")


func test_two_runs_same_log_same_attribution() -> void:
	# Pure replay determinism over the new bookkeeping: two sims, same seed,
	# same commands — byte-identical evidence and state.
	var sims: Array = [make_goal_sim([TAKEDOWN_GOAL], 7), make_goal_sim([TAKEDOWN_GOAL], 7)]
	for s: CombatSim in sims:
		add_human(s, "h", {"team": "party"})
		add_human(s, "p", {"team": "party", "position": [1, 0]})
		add_human(s, "m", {"team": "enemies", "position": [0, 1]})
		declare(s, "h", attack_action("bleeding", 1, "p", "torso"))
		advance(s, 1)
		declare(s, "h", attack_action("crushed", 5, "m", "torso"))
		advance(s, 1)
		advance(s, Clock.TICKS_PER_CLOCK * 5)
	assert_eq((sims[0] as CombatSim).evidence.to_dict(), (sims[1] as CombatSim).evidence.to_dict(),
		"same log -> identical takedown ledger")
	assert_eq((sims[0] as CombatSim).state_hash(), (sims[1] as CombatSim).state_hash(),
		"state hash (wound sources included) stays replay-stable")
	assert_true(entries_of(sims[0], "takedown").size() >= 2,
		"precondition: the run earned both takedowns (direct + bleed-out)")


# ---------------------------------------------------------------- payout ledger alignment

func test_goal_payout_ledger_row_goes_to_the_killer() -> void:
	# Decision #15's recorded boundary, closed by task #13: the payout row goes
	# to the killer; the victim keeps only their own drama's base points.
	var sim: CombatSim = make_goal_sim([TAKEDOWN_GOAL])
	add_human(sim, "h", {"team": "party"})
	add_human(sim, "m", {"team": "enemies", "position": [1, 0]})
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "finish_them", "precondition: pinned goal active")
	declare(sim, "h", attack_action("crushed", 5, "m", "torso"))
	var events: Array[Dictionary] = advance(sim, 1)
	var done: Dictionary = assert_event(events, "hype_goal_completed", "the kill completed the goal")
	assert_eq(String(done.get("completed_by", "")), "h", "completed by the killer")
	assert_eq(int(sim.hype.ledger.get("h", 0)), int(done.get("spectacle_points", -1)),
		"the killer's ledger row is exactly the payout")
	assert_true(int(sim.hype.ledger.get("m", 0)) > 0, "the victim still keeps their own drama's base points")
