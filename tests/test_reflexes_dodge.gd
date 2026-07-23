extends SimTestBase
## R22 — the unified Reflexes dodge model (decision-log #28, owner 2026-07-23).
## The threshold asks the DODGER's Reflexes: >= threshold auto-dodges (no rng);
## else the stat's threshold die (default 1d4, per-stat upgradeable and
## serialized) rolls off the salted ai_rng; Reflexes + die max < threshold is
## IMPOSSIBLE (no rng, no event). Both directions run the same check: the
## boss's aimed-round dodge (boss_traits.dodge_threshold, retuned 4 -> 7) and
## the Dash counters ladder (the dash ability's "dodge" block — threshold 7,
## counter_at 9: auto-dodge + 1-hex sidestep at 7+, + counterattack at 9+; the
## sidestep rides ANY successful dash dodge). Prone joins Helpless/Exposed as
## an ineligible window (the slam punish).
##
## RNG-consumption pins use a TWIN RandomNumberGenerator seeded to the live
## stream's state: exactly-one-draw and zero-draw claims are proven against
## the twin, not inferred from event counts.


func add_boss(sim: CombatSim, id: String = "boss", overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func boss_state(sim: CombatSim, id: String = "boss") -> CombatantState:
	return sim.combatants.get(id)


func dodge_events(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in events:
		if ["attack_dodged", "dodge_failed"].has(String(event.get("type", ""))):
			out.append(event)
	return out


# ---------------------------------------------------------------- the unified check

func test_auto_dodge_at_reflexes_threshold_consumes_no_rng() -> void:
	# Boundary pin: threshold 4 == the boss's Reflexes 4 -> auto-dodge.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 4}})
	var state_before: int = sim.ai.ai_rng.state
	declare(sim, "h", attack_action("bleeding", 2, "boss", "right_hand"))
	var resolved: Array[Dictionary] = advance(sim, 1)
	var dodge: Dictionary = assert_event(resolved, "attack_dodged", "Reflexes 4 >= threshold 4 auto-dodges")
	assert_true(bool(dodge.get("auto", false)), "auto flag set")
	assert_eq(int(dodge.get("roll", -1)), 0, "auto-dodge carries roll 0")
	assert_eq(int(dodge.get("reflexes", 0)), 4, "dodger Reflexes emitted")
	assert_eq(int(dodge.get("die", 0)), 4, "default d4 die size emitted")
	assert_eq(int(dodge.get("threshold", 0)), 4, "threshold emitted")
	assert_eq(sim.ai.ai_rng.state, state_before, "an auto-dodge consumes NO rng")
	assert_no_event(resolved, "damage_applied", "the dodged round deals nothing")


func test_rolled_fallback_consumes_exactly_one_draw_both_ways() -> void:
	# Reflexes 4 < threshold 6, 4 + d4 covers it: every aimed round rolls the d4
	# exactly once; 4 + roll >= 6 dodges (2+), a 1 fails. The twin RNG proves the
	# draw count AND the drawn value per round.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 6}})
	var dodged_seen: bool = false
	var failed_seen: bool = false
	for i: int in range(10):
		var pre: int = sim.ai.ai_rng.state
		declare(sim, "h", attack_action("poison", 0, "boss", "right_hand"))
		var resolved: Array[Dictionary] = advance(sim, 1)
		var attempts: Array[Dictionary] = dodge_events(resolved)
		assert_eq(attempts.size(), 1, "round %d: exactly one dodge attempt" % i)
		var attempt: Dictionary = attempts[0]
		var twin := RandomNumberGenerator.new()
		twin.state = pre
		var expected_roll: int = twin.randi_range(1, 4)
		assert_eq(int(attempt.get("roll", -1)), expected_roll, "round %d: the emitted roll IS the stream's next d4" % i)
		assert_eq(sim.ai.ai_rng.state, twin.state, "round %d: exactly ONE draw consumed" % i)
		assert_false(bool(attempt.get("auto", true)), "a rolled fallback is not auto")
		var should_dodge: bool = 4 + expected_roll >= 6
		assert_eq(String(attempt.get("type", "")), "attack_dodged" if should_dodge else "dodge_failed",
			"round %d: Reflexes + roll >= threshold decides, both ways" % i)
		dodged_seen = dodged_seen or should_dodge
		failed_seen = failed_seen or not should_dodge
	assert_true(dodged_seen, "the 10 rounds actually dodged at least once")
	assert_true(failed_seen, "the 10 rounds actually failed at least once")


func test_impossible_dodge_consumes_no_rng_and_never_dodges() -> void:
	# Reflexes 4 + d4 max = 8 < threshold 10: impossible — no rng, no event.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 10}})
	var state_before: int = sim.ai.ai_rng.state
	for i: int in range(4):
		declare(sim, "h", attack_action("bleeding", 2, "boss", "right_hand"))
		var resolved: Array[Dictionary] = advance(sim, 1)
		assert_eq(dodge_events(resolved).size(), 0, "an impossible dodge emits nothing")
		assert_event(resolved, "damage_applied", "the round always lands")
	assert_eq(sim.ai.ai_rng.state, state_before, "an impossible dodge consumes NO rng")


func test_threshold_die_upgrade_granted_serialized_and_used() -> void:
	# Grant a d6 Reflexes threshold die via the add_combatant spec (grant
	# pattern like skills/bit). Threshold 10 vs Reflexes 4: impossible on the
	# default d4 (max 8), possible on the granted d6 (needs the 6).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {
		"boss_traits": {"dodge_threshold": 10},
		"threshold_dice": {"reflexes": 6},
	})
	assert_eq(boss_state(sim).threshold_die("reflexes"), 6, "the granted d6 is on the combatant")
	assert_eq(boss_state(sim).threshold_die("mind"), 4, "ungranted stats keep the default d4")
	var rolled: int = 0
	for i: int in range(8):
		var pre: int = sim.ai.ai_rng.state
		declare(sim, "h", attack_action("poison", 0, "boss", "right_hand"))
		var resolved: Array[Dictionary] = advance(sim, 1)
		var attempts: Array[Dictionary] = dodge_events(resolved)
		assert_eq(attempts.size(), 1, "the d6 makes the ask possible — one attempt per round")
		var attempt: Dictionary = attempts[0]
		assert_eq(int(attempt.get("die", 0)), 6, "the emitted die size is the granted d6")
		var twin := RandomNumberGenerator.new()
		twin.state = pre
		var expected_roll: int = twin.randi_range(1, 6)
		assert_eq(int(attempt.get("roll", -1)), expected_roll, "the roll IS the stream's next d6")
		assert_eq(String(attempt.get("type", "")), "attack_dodged" if 4 + expected_roll >= 10 else "dodge_failed",
			"Reflexes 4 + d6 >= 10 needs the 6, both ways")
		rolled += 1
	assert_eq(rolled, 8, "every round rolled the granted die")
	# Serialization round-trip: the grant survives to_dict/from_dict and is
	# state-hash covered (a tampered die changes the hash).
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical")
	assert_eq((restored.combatants["boss"] as CombatantState).threshold_die("reflexes"), 6,
		"the granted d6 survives the roundtrip")
	var tampered: Dictionary = sim.to_dict()
	((tampered["combatants"] as Dictionary)["boss"] as Dictionary)["threshold_dice"] = {"reflexes": 8}
	assert_ne(CombatSim.from_dict(tampered).state_hash(), sim.state_hash(),
		"threshold_dice is covered by the state hash")


func test_prone_blocks_dodging() -> void:
	# R22 adds Prone to the ineligible list (the slam punish window): even an
	# auto-dodge threshold never fires while prone.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 1}})
	sim.apply_command({"type": "set_status", "target": "boss", "status": "prone", "value": true})
	var state_before: int = sim.ai.ai_rng.state
	declare(sim, "h", attack_action("bleeding", 2, "boss", "right_hand"))
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_eq(dodge_events(resolved).size(), 0, "a prone dodger never attempts a dodge")
	assert_event(resolved, "damage_applied", "the hit lands through the punish window")
	assert_eq(sim.ai.ai_rng.state, state_before, "no rng touched while prone")


func test_boss_dodge_at_retuned_threshold_seven() -> void:
	# The seeded Incinedile ships dodge_threshold 7 (R22 retune, PROVISIONAL):
	# boss Reflexes 4 + d4 dodges on a 3+ — the old d6-vs-4 ~50%. Deterministic
	# seed 1234 cases must include BOTH outcomes, each obeying the arithmetic.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim)
	assert_eq(int(boss_state(sim).boss_traits.get("dodge_threshold", 0)), 7,
		"data/enemies.json ships the retuned threshold 7")
	var dodged: int = 0
	var failed: int = 0
	for i: int in range(12):
		declare(sim, "h", attack_action("poison", 0, "boss", "right_hand"))
		var resolved: Array[Dictionary] = advance(sim, 1)
		for attempt: Dictionary in dodge_events(resolved):
			var roll: int = int(attempt.get("roll", 0))
			assert_true(roll >= 1 and roll <= 4, "the d4 fallback rolled (got %d)" % roll)
			if String(attempt.get("type", "")) == "attack_dodged":
				assert_true(4 + roll >= 7, "a dodge cleared the ask (roll %d)" % roll)
				dodged += 1
			else:
				assert_true(4 + roll < 7, "a fail missed the ask (roll %d)" % roll)
				failed += 1
	assert_eq(dodged + failed, 12, "one attempt per aimed round")
	assert_true(dodged >= 1, "seed 1234 rolls at least one dodge (got %d)" % dodged)
	assert_true(failed >= 1, "seed 1234 rolls at least one fail (got %d)" % failed)


# ---------------------------------------------------------------- the Dash ladder

func test_dash_vs_reflexes_seven_auto_dodges_and_sidesteps() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "dodger", {"team": "party", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 7, "mind": 3, "charm": 3}})
	add_boss(sim)
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_eq(String(first_event(events, "ai_decision").get("ability", "")), "dash", "lone target -> dash")
	var state_before: int = sim.ai.ai_rng.state
	var resolved: Array[Dictionary] = advance(sim, 3)  # cost-2 windup: declared t0, resolves t2
	var dodge: Dictionary = assert_event(resolved, "attack_dodged", "Reflexes 7 >= threshold 7 auto-dodges the dash")
	assert_true(bool(dodge.get("auto", false)), "auto dodge")
	assert_eq(int(dodge.get("threshold", 0)), 7, "the dash's authored dodge threshold (data-driven)")
	assert_eq(sim.ai.ai_rng.state, state_before, "the auto-dodge consumed no rng")
	var sidestep: Dictionary = assert_event(resolved, "dash_sidestepped", "the sidestep rides the dodge")
	assert_eq(sidestep.get("from", []), [1, 0], "from the pre-dodge hex")
	assert_eq(sidestep.get("to", []), [2, 0], "first free HEX_NEIGHBORS hex that increases distance")
	var dodger: CombatantState = sim.combatants["dodger"]
	assert_eq([dodger.position.x, dodger.position.y], [2, 0], "position actually changed by 1 hex")
	assert_eq(CombatantState.hex_distance(dodger.position, boss_state(sim).position), 2,
		"distance from the dasher increased (1 -> 2)")
	assert_no_event(resolved, "dash_countered", "Reflexes 7 < 9: no counterattack")
	assert_no_event(resolved, "damage_applied", "the dodge negates the dash entirely")
	assert_no_event(resolved, "condition_applied", "no crushed rider on a dodged dash")


func test_dash_vs_reflexes_nine_counters_the_dasher() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "dodger", {"team": "party", "position": [1, 0],
		"traits": {"physique": 8, "reflexes": 9, "mind": 3, "charm": 3}})
	add_boss(sim)
	var state_before: int = sim.ai.ai_rng.state
	ai_decide(sim, "boss")
	var resolved: Array[Dictionary] = advance(sim, 3)
	assert_event(resolved, "attack_dodged", "Reflexes 9 auto-dodges")
	assert_event(resolved, "dash_sidestepped", "the sidestep rides ANY successful dash dodge")
	var counter: Dictionary = assert_event(resolved, "dash_countered", "Reflexes >= 9 counterattacks")
	assert_eq(String(counter.get("combatant", "")), "dodger", "the dodger counters")
	assert_eq(String(counter.get("target", "")), "boss", "back at the dasher")
	assert_eq(String(counter.get("part", "")), "left_hand", "torso-line part on the boss (no torso -> first body plate)")
	assert_eq(String(counter.get("damage_type", "")), "crushed", "v1 basic unarmed strike is crushed")
	assert_eq(int(counter.get("amount", 0)), 1, "basic unarmed strike amount 1")
	# R14 gate applies: Force = 1 + floor(phys 8 / 2) = 5 > Robustness floor(6/2)
	# = 3 -> net 2 lands on the boss and seeds crushed T1.
	var damage: Dictionary = assert_event(resolved, "damage_applied", "the counter lands a real hit")
	assert_eq(String(damage.get("combatant", "")), "boss", "on the dasher")
	assert_eq(String(damage.get("part", "")), "left_hand", "at the countered part")
	assert_eq(int(damage.get("amount", -1)), 2, "Force 5 − Robustness 3 = 2 (R14-gated)")
	assert_eq(int(boss_state(sim).parts["left_hand"]["hp"]), 28, "boss HP actually taken (30 -> 28)")
	assert_eq(boss_state(sim).condition_tier("left_hand", "crushed"), 1, "crushed T1 rides the landed counter")
	# The counter is the dodge's own rider: the boss never dodges it (v1,
	# deterministic) — and the whole exchange consumed zero rng.
	for attempt: Dictionary in dodge_events(resolved):
		assert_ne(String(attempt.get("combatant", "")), "boss", "the counter is not itself dodgeable (v1)")
	assert_eq(sim.ai.ai_rng.state, state_before, "auto-dodge + counter: zero rng consumed")


func test_dash_vs_imani_reflexes_two_always_connects() -> void:
	# R22 recorded consequence: Reflexes 2 + d4 max = 6 < 7 — Imani CANNOT dodge
	# the Dash until a die/stat upgrade. Intended texture, not a bug.
	var sim: CombatSim = make_sim()
	add_human(sim, "imani", {"team": "party", "position": [1, 0],
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	add_boss(sim)
	var state_before: int = sim.ai.ai_rng.state
	ai_decide(sim, "boss")
	var resolved: Array[Dictionary] = advance(sim, 3)
	assert_eq(dodge_events(resolved).size(), 0, "no dodge attempt — the ask is impossible")
	var damage: Dictionary = assert_event(resolved, "damage_applied", "the dash always connects on Imani")
	assert_eq(String(damage.get("combatant", "")), "imani", "on Imani")
	assert_eq(int(damage.get("amount", -1)), 3, "dash Force 5 − Robustness floor(5/2) = 3")
	assert_no_event(resolved, "dash_sidestepped", "no dodge, no sidestep")
	assert_eq(sim.ai.ai_rng.state, state_before, "an impossible dodge consumes NO rng")


func test_dash_windup_is_visible_before_it_resolves() -> void:
	# R22: moment_cost 1 -> 2 — the dash telegraphs through the same windup /
	# schedule machinery the HUD's declared-action bars and view_schedule read.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_boss(sim)
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var declared: Dictionary = assert_event(events, "action_declared", "the dash declares")
	assert_eq(int(declared.get("cost", 0)), 2, "cost 2")
	assert_true(bool(declared.get("windup", false)), "flagged as a windup")
	assert_eq(int(declared.get("resolve_tick", -1)), 2, "declared tick 0 -> resolves tick 2")
	var pending: Array[Dictionary] = sim.clock.scheduled_entries()
	assert_eq(pending.size(), 1, "one pending schedule entry — the telegraph is visible")
	assert_eq(String((pending[0] as Dictionary).get("actor", "")), "boss", "the boss's entry")
	assert_eq(int((pending[0] as Dictionary).get("tick", -1)), 2, "due at tick 2")
	assert_true(boss_state(sim).windup_pending, "the boss is committed (windup_pending)")
	assert_eq(sim.ai_ready_ids(), [], "a winding-up boss is not ready")
	assert_no_event(advance(sim, 2), "damage_applied", "nothing lands during the two-Moment warning")
	assert_event(advance(sim, 1), "damage_applied", "the dash resolves after the telegraph window")


# ---------------------------------------------------------------- determinism

## Deterministic driver: Dario-shaped contestant (Reflexes 5 — rolled dash
## dodges) pounds an aimed part (boss dodge rolls) while a far contestant
## suppresses the cone (in-cone crowd < 2 keeps the boss dashing).
func _drive_fight(sim: CombatSim, ticks: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for t: int in range(ticks):
		var dario: CombatantState = sim.combatants.get("dario")
		if dario != null and dario.can_act(sim.clock.tick) \
				and sim.clock.tick >= dario.next_action_tick and not dario.windup_pending:
			events.append_array(declare(sim, "dario", attack_action("crushed", 2, "boss", "right_hand")))
		for id: String in sim.ai_ready_ids():
			events.append_array(ai_decide(sim, id))
		events.append_array(advance(sim, 1))
	return events


func _staged_fight(sim_seed: int) -> CombatSim:
	var sim: CombatSim = make_sim(sim_seed)
	add_human(sim, "dario", {"team": "party", "position": [1, 0],
		"traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}})
	add_human(sim, "far", {"team": "party", "position": [12, 0],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_boss(sim)
	return sim


func test_determinism_and_save_restore_with_dodges_in_the_log() -> void:
	# Same seed + same commands -> identical hash, twice from scratch.
	var full_a: CombatSim = _staged_fight(4242)
	var full_b: CombatSim = _staged_fight(4242)
	var log_a: Array[Dictionary] = _drive_fight(full_a, 14)
	_drive_fight(full_b, 14)
	assert_eq(full_a.state_hash(), full_b.state_hash(), "same (seed, command log) -> same hash")
	var attempts: int = dodge_events(log_a).size()
	assert_true(attempts >= 2, "the script actually put dodges in the log (%d)" % attempts)
	# Save/restore MID-FIGHT (dodges already consumed, more to come): the
	# restored sim must replay the identical tail to the identical hash.
	var head: CombatSim = _staged_fight(4242)
	_drive_fight(head, 7)
	var restored: CombatSim = CombatSim.from_dict(head.to_dict())
	assert_eq(restored.state_hash(), head.state_hash(), "roundtrip hash identical mid-fight")
	_drive_fight(head, 7)
	_drive_fight(restored, 7)
	assert_eq(head.state_hash(), full_a.state_hash(), "continued head run matches the uninterrupted run")
	assert_eq(restored.state_hash(), full_a.state_hash(), "snapshot -> restore -> tail = identical hash")
