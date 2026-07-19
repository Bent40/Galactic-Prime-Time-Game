extends SimTestBase
## Slice tag engine v1 (simulation/tag_engine.gd, I-13) — the 10 detectable slice
## tags, their detectors, the HypeEngine resonance hook, The Bit's mechanical
## nullity, the 3 new crowd goals, determinism and serialization.
##
## Detector fire/no-fire is tested by feeding hand-crafted event batches to
## sim.tags.ingest (the same style as the hype engine's spectacle-hook tests) so
## each predicate + the same-batch attacker attribution is exercised precisely;
## a handful of end-to-end tests prove the sim actually emits those events and
## that the engine is wired. There is NO RNG in the tag engine (unlike hype's
## goal draw): tag state is a pure function of the ordered event log, so the
## determinism teeth are the log-order + serialization tests.


func add_boss(sim: CombatSim, id: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "race": "human", "category": "Boss",
		"position": [4, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3},
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


## tag_progressed / tag_acquired / tag_reinforced events for one tag key.
func tag_events(events: Array[Dictionary], tag_key: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in events:
		var t := String(e.get("type", ""))
		if (t == "tag_progressed" or t == "tag_acquired" or t == "tag_reinforced") \
				and String(e.get("tag", "")) == tag_key:
			out.append(e)
	return out


func progress_of(sim: CombatSim, id: String, key: String) -> int:
	return int((sim.tags.progress.get(id, {}) as Dictionary).get(key, 0))


# ---------------------------------------------------------------- infra

func test_loadouts_start_tagless() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	assert_true(sim.tags.held.is_empty(), "no tags held before anything happens on camera")
	assert_true(sim.tags.progress.is_empty(), "no progress accrued yet")
	assert_false(sim.tags.holds("a", "gorefest"), "holds() is false for an untagged contestant")


func test_effect_table_loaded() -> void:
	var sim: CombatSim = make_sim()
	assert_eq(sim.tags.by_key.size(), 10, "all 10 slice tag effect rows are wired")
	for key: String in ["reckless", "gorefest", "blooper_reel", "scene_stealer", "the_bit",
			"fan_favorite", "survivor", "craft_services", "formation", "3am_energy"]:
		assert_true(sim.tags.by_key.has(key), "effect row present for %s" % key)


func test_tag_events_are_not_rescanned() -> void:
	# Re-entry guard: feeding the engine its own tag_* outputs progresses nothing
	# (mirrors the hype engine's own-event guard).
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var echo: Array[Dictionary] = sim.tags.ingest([
		{"type": "tag_acquired", "combatant": "a", "tag": "gorefest"},
		{"type": "tag_progressed", "combatant": "a", "tag": "reckless", "count": 1, "threshold": 3},
	])
	assert_true(echo.is_empty(), "tag_* events are skipped on ingest")
	assert_eq(progress_of(sim, "a", "gorefest"), 0, "no phantom progress from re-ingested tag events")


func test_non_contestant_holds_nothing() -> void:
	# RULED item 7: the boss generates detectable beats but holds NO tags.
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_boss(sim, "boss")
	# Boss suffers forced actions and lands exposed strikes — nothing sticks.
	var out: Array[Dictionary] = sim.tags.ingest([
		{"type": "forced_action_triggered", "actor": "boss", "table": "Body", "roll": 1, "consequence": "flail"},
		{"type": "forced_action_triggered", "actor": "boss", "table": "Body", "roll": 1, "consequence": "flail"},
		{"type": "forced_action_triggered", "actor": "boss", "table": "Body", "roll": 1, "consequence": "flail"},
	])
	assert_true(tag_events(out, "blooper_reel").is_empty(), "a non-contestant earns no tag")
	assert_false(sim.tags.progress.has("boss"), "the boss has no progress ledger at all")


# ---------------------------------------------------------------- detectors

func test_reckless_detects_exposed_attack() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "c", {"position": [2, 0]})
	# Exposed → an ok attack with rounds>0 is a Reckless beat.
	var hit: Array[Dictionary] = sim.tags.ingest([
		{"type": "exposed_state_changed", "combatant": "a", "exposed": true},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 1},
	])
	assert_eq(int(tag_events(hit, "reckless")[0].get("count", 0)), 1, "an exposed strike progresses Reckless")
	# A contestant who never went Exposed lands the same strike — no beat.
	var safe: Array[Dictionary] = sim.tags.ingest([
		{"type": "action_resolved", "actor": "c", "kind": "attack", "result": "ok", "rounds": 1},
	])
	assert_true(tag_events(safe, "reckless").is_empty(), "an un-Exposed strike is not Reckless")
	# A whiffed / zero-round attack while Exposed is not a beat either.
	var whiff: Array[Dictionary] = sim.tags.ingest([
		{"type": "exposed_state_changed", "combatant": "a", "exposed": true},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 0},
	])
	assert_eq(progress_of(sim, "a", "reckless"), 1, "a rounds=0 strike does not add a Reckless beat")


func test_gorefest_batch_credits_the_attacker() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	# part_destroyed on b, closed by a's action_resolved in the same batch → a.
	var one: Array[Dictionary] = sim.tags.ingest([
		{"type": "part_destroyed", "combatant": "b", "part": "left_arm"},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 1},
	])
	var ev: Array[Dictionary] = tag_events(one, "gorefest")
	assert_eq(String(ev[0].get("combatant", "")), "a", "Gorefest is credited to the batch attacker, not the victim")
	assert_eq(int(ev[0].get("count", 0)), 1, "first Gorefest beat")
	# Bleeding advanced to T2 by an attack → beat 2 → acquired (threshold 2).
	var two: Array[Dictionary] = sim.tags.ingest([
		{"type": "condition_advanced", "combatant": "b", "part": "torso", "condition": "bleeding", "from_tier": 1, "to_tier": 2},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 1},
	])
	assert_eq(String(tag_events(two, "gorefest")[0].get("type", "")), "tag_acquired", "second beat acquires Gorefest")
	assert_true(sim.tags.holds("a", "gorefest"), "a now holds Gorefest")


func test_gorefest_no_closer_stays_uncredited() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	# A victim-attributed part_destroyed with NO action_resolved after it (e.g.
	# clock-driven bleed-out death) credits nobody — correct: nobody did it.
	var out: Array[Dictionary] = sim.tags.ingest([
		{"type": "part_destroyed", "combatant": "b", "part": "left_arm"},
	])
	assert_true(tag_events(out, "gorefest").is_empty(), "no closer → uncredited")
	# Wrong condition / wrong tier do not count.
	var wrong: Array[Dictionary] = sim.tags.ingest([
		{"type": "condition_advanced", "combatant": "b", "part": "torso", "condition": "bleeding", "from_tier": 0, "to_tier": 1},
		{"type": "condition_advanced", "combatant": "b", "part": "torso", "condition": "burn", "from_tier": 2, "to_tier": 3},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 1},
	])
	assert_true(tag_events(wrong, "gorefest").is_empty(), "bleeding T1 and non-bleeding advances are not Gorefest")


func test_blooper_reel_detects_forced_actions() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var out: Array[Dictionary] = sim.tags.ingest([
		{"type": "forced_action_triggered", "actor": "a", "table": "Body", "roll": 2, "consequence": "stumble"},
		{"type": "forced_action_triggered", "actor": "a", "table": "Tool", "roll": 3, "consequence": "drop"},
		{"type": "forced_action_triggered", "actor": "a", "table": "Body", "roll": 6, "consequence": "whiff"},
	])
	var ev: Array[Dictionary] = tag_events(out, "blooper_reel")
	assert_eq(ev.size(), 3, "each Forced Action is a comedy beat")
	assert_eq(String(ev[2].get("type", "")), "tag_acquired", "3 pratfalls acquire Blooper Reel")


func test_scene_stealer_consumes_hype_outputs() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var out: Array[Dictionary] = sim.tags.ingest([
		{"type": "hype_goal_completed", "goal": "finish_them", "combatant": "a", "spectacle_points": 80},
		{"type": "hype_camera_call_started", "actor": "a", "target": "b", "stacks_remaining": 0},
	])
	assert_eq(String(tag_events(out, "scene_stealer")[1].get("type", "")), "tag_acquired",
		"completing a goal + starting a camera call acquires Scene Stealer")
	# Other hype output does not feed it.
	add_human(sim, "z", {"position": [3, 0]})
	var noise: Array[Dictionary] = sim.tags.ingest([
		{"type": "hype_goal_expired", "goal": "finish_them"},
		{"type": "hype_band_changed", "from_band": "warm", "to_band": "hot"},
	])
	assert_true(tag_events(noise, "scene_stealer").is_empty(), "unrelated hype events are not Scene Stealer")


func test_fan_favorite_counts_dramatic_beats() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	# Five dramatic beats whose subject is a → acquired (threshold 5).
	var out: Array[Dictionary] = sim.tags.ingest([
		{"type": "bleed_out_started", "combatant": "a", "part": "torso", "condition": "bleeding"},
		{"type": "bleed_out_stabilized", "combatant": "a"},
		{"type": "part_disabled", "combatant": "a", "part": "left_arm"},
		{"type": "part_destroyed", "combatant": "a", "part": "left_leg"},
		{"type": "part_disabled", "combatant": "a", "part": "right_arm"},
	])
	assert_eq(String(tag_events(out, "fan_favorite")[4].get("type", "")), "tag_acquired",
		"the camera keeps finding a → Fan Favorite")


func test_survivor_needs_to_stay_alive() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "d", {"position": [2, 0]})
	# Own jeopardy while ALIVE → beats.
	var alive: Array[Dictionary] = sim.tags.ingest([
		{"type": "bleed_out_started", "combatant": "a", "part": "torso", "condition": "bleeding"},
		{"type": "bleed_out_stabilized", "combatant": "a"},
	])
	assert_eq(String(tag_events(alive, "survivor")[1].get("type", "")), "tag_acquired", "the clutch save acquires Survivor")
	# A dead combatant does not survive — no credit.
	sim.combatants["d"].alive = false
	var dead: Array[Dictionary] = sim.tags.ingest([
		{"type": "shock_changed", "combatant": "d", "from_tier": 0, "to_tier": 4},
		{"type": "part_destroyed", "combatant": "d", "part": "torso"},
	])
	assert_true(tag_events(dead, "survivor").is_empty(), "the dead don't earn Survivor")
	assert_eq(progress_of(sim, "d", "survivor"), 0, "no Survivor credit for the fallen")


func test_survivor_ignores_low_shock() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var out: Array[Dictionary] = sim.tags.ingest([
		{"type": "shock_changed", "combatant": "a", "from_tier": 0, "to_tier": 2},
	])
	assert_true(tag_events(out, "survivor").is_empty(), "shock below T3 is not a Survivor beat")


func test_craft_services_protective_and_support() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var out: Array[Dictionary] = sim.tags.ingest([
		{"type": "reaction_resolved", "actor": "a", "cost": 1, "key": "brace"},
		{"type": "inventory_used", "actor": "a", "free": true, "interaction": "handoff"},
		{"type": "attack_blocked", "combatant": "a", "part": "torso", "reason": "surface_immunity"},
	])
	assert_eq(String(tag_events(out, "craft_services")[2].get("type", "")), "tag_acquired",
		"a block, a handoff and an intercept acquire Craft Services")
	# A non-protective reaction / a plain item use are not support beats.
	add_human(sim, "e", {"position": [2, 0]})
	var noise: Array[Dictionary] = sim.tags.ingest([
		{"type": "reaction_resolved", "actor": "e", "cost": 1, "key": "counter_swing"},
		{"type": "inventory_used", "actor": "e", "free": true, "interaction": "use"},
	])
	assert_true(tag_events(noise, "craft_services").is_empty(), "an offensive reaction / plain use is not Craft Services")


func test_formation_credits_every_contestant_member() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	add_boss(sim, "boss")
	# One combined action naming two contestants and the boss.
	var out: Array[Dictionary] = sim.tags.ingest([
		{"type": "combined_action_declared", "combo_id": "combo:1:1", "members": ["a", "b", "boss"]},
	])
	assert_eq(tag_events(out, "formation").size(), 2, "both contestant members are credited; the boss is not")
	# Second combined action → both contestants acquire (threshold 2).
	var out2: Array[Dictionary] = sim.tags.ingest([
		{"type": "combined_action_declared", "combo_id": "combo:2:1", "members": ["a", "b"]},
	])
	assert_eq(tag_events(out2, "formation").size(), 2, "each contestant earns a second beat")
	assert_true(sim.tags.holds("a", "formation") and sim.tags.holds("b", "formation"), "both hold Formation")
	assert_false(sim.tags.progress.has("boss"), "the boss never entered a Formation ledger")


func test_3am_energy_movement_streak() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	assert_true(sim.tags.ingest([{"type": "moved", "actor": "a", "spaces": 2}]).is_empty(),
		"2 spaces is under the streak_spaces=4 window")
	var hit: Array[Dictionary] = sim.tags.ingest([{"type": "moved", "actor": "a", "spaces": 2}])
	assert_eq(int(tag_events(hit, "3am_energy")[0].get("count", 0)), 1, "reaching 4 accumulated spaces credits one streak Clock")
	assert_true(sim.tags.ingest([{"type": "moved", "actor": "a", "spaces": 5}]).is_empty(),
		"the same Clock only credits the streak once")
	# A new Clock resets the accumulation; a fresh streak is the second beat.
	sim.tags.ingest([{"type": "clock_reset"}])
	var again: Array[Dictionary] = sim.tags.ingest([{"type": "moved", "actor": "a", "spaces": 4}])
	assert_eq(String(tag_events(again, "3am_energy")[0].get("type", "")), "tag_acquired",
		"a streak on a second Clock acquires 3am Energy")


# ---------------------------------------------------------------- The Bit (mechanical nullity)

## Everything about the sim EXCEPT the two broadcast-plane engines. If a command
## leaves this fingerprint unchanged it touched no combat state.
func combat_fingerprint(sim: CombatSim) -> String:
	var d: Dictionary = sim.to_dict()
	d.erase("hype")
	d.erase("tags")
	return CombatSim.canonical_serialize(d)


func test_the_bit_is_mechanically_null() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	add_boss(sim, "boss")
	# Put real combat state on the board: b is bleeding, a mid-fight.
	sim.apply_command({"type": "apply_condition", "target": "b", "part": "torso", "condition": "bleeding", "tier": 2})
	advance(sim, 1)
	var before_state: String = combat_fingerprint(sim)
	var before_meter: int = sim.hype.meter
	# Perform the bit.
	var events: Array[Dictionary] = sim.apply_command({"type": "bit", "actor": "a", "key": "bow"})
	var bit: Dictionary = assert_event(events, "bit_performed", "the bit resolves")
	# 1) It is mechanically null: NOTHING outside hype/tags changed.
	assert_eq(combat_fingerprint(sim), before_state,
		"the bit changed NO combat state (combatants, clock, rng, ai, snapshot all identical)")
	# 2) The ONLY payout is spectacle.
	assert_true(int(bit.get("spectacle_points", 0)) > 0, "the bit pays spectacle")
	assert_true(sim.hype.meter > before_meter, "spectacle raised the hype meter")
	assert_eq(progress_of(sim, "a", "the_bit"), 1, "and it counts toward The Bit")


func test_the_bit_rejects_non_contestant_and_dead() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_boss(sim, "boss")
	assert_rejected(sim.apply_command({"type": "bit", "actor": "zz"}), "unknown_actor", "unknown actor")
	assert_rejected(sim.apply_command({"type": "bit", "actor": "boss"}), "not_a_contestant", "the boss cannot do a bit")
	sim.combatants["a"].alive = false
	assert_rejected(sim.apply_command({"type": "bit", "actor": "a"}), "actor_dead", "a corpse cannot perform")


func test_the_bit_spectacle_escalates_and_acquires() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var rider: Dictionary = sim.tags.by_key["the_bit"]["rider"]
	var base: int = int(rider["base_spectacle"])
	var bonus: int = int(rider["bonus_per_prior"])
	var payouts: Array[int] = []
	var last: Array[Dictionary] = []
	for i: int in range(3):
		last = sim.apply_command({"type": "bit", "actor": "a"})
		payouts.append(int(first_event(last, "bit_performed").get("spectacle_points", -1)))
	assert_eq(payouts[0], base, "first bit pays base")
	assert_eq(payouts[1], base + bonus, "second bit escalates by one step")
	assert_eq(payouts[2], base + 2 * bonus, "third bit escalates again")
	assert_event(last, "tag_acquired", "the third performance acquires The Bit")
	assert_true(sim.tags.holds("a", "the_bit"), "a now holds The Bit")


func test_the_bit_end_to_end_null_in_rich_state() -> void:
	# A stronger nullity check: two identical sims; one performs a bit between the
	# same commands. Their COMBAT state (everything but hype/tags) stays identical.
	var plain: CombatSim = make_sim(909)
	var bitten: CombatSim = make_sim(909)
	for sim: CombatSim in [plain, bitten]:
		add_human(sim, "a")
		add_human(sim, "b", {"position": [1, 0]})
		declare(sim, "a", attack_action("bleeding", 3, "b", "torso"))
		advance(sim, 2)
	bitten.apply_command({"type": "bit", "actor": "a"})
	for sim: CombatSim in [plain, bitten]:
		advance(sim, 3)
	assert_eq(combat_fingerprint(bitten), combat_fingerprint(plain),
		"a bit anywhere in the log leaves combat state bit-for-bit identical")
	assert_true(bitten.hype.meter > plain.hype.meter, "only the broadcast plane diverged")


# ---------------------------------------------------------------- resonance hook

func test_resonance_amplifies_event_points() -> void:
	var plain: CombatSim = make_sim()
	var tagged: CombatSim = make_sim()
	for sim: CombatSim in [plain, tagged]:
		add_human(sim, "a")
		add_human(sim, "b", {"position": [1, 0]})
	# Grant the attacker Gorefest on the tagged sim only.
	tagged.tags.held["a"] = {"gorefest": true}
	var batch: Array[Dictionary] = [
		{"type": "part_destroyed", "combatant": "b", "part": "left_arm"},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 1},
	]
	plain.hype.ingest(batch.duplicate(true))
	tagged.hype.ingest(batch.duplicate(true))
	assert_true(plain.hype.meter > 0, "precondition: the untagged part_destroyed scored")
	assert_eq(tagged.hype.meter, roundi(plain.hype.meter * 1.5),
		"Gorefest resonates the attacker's spectacle x1.5 (150%%): %d vs %d" % [tagged.hype.meter, plain.hype.meter])


func test_resonance_amplifies_goal_payout() -> void:
	var goal: Dictionary = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "deadline_clocks": 3}
	var p: CombatSim = make_sim()
	var t: CombatSim = make_sim()
	for sim: CombatSim in [p, t]:
		add_human(sim, "a")
		add_human(sim, "b", {"position": [1, 0]})
		sim.hype.active_goal = {"id": "finish_them", "name": "FINISH THEM!", "kind": "takedown", "params": {}, "payout": 80, "clocks_left": 3}
	t.tags.held["a"] = {"scene_stealer": true}
	# The killer (a) completes the takedown; the completing event is b's death.
	var batch: Array[Dictionary] = [
		{"type": "combatant_died", "combatant": "b"},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 1},
	]
	var pd: Dictionary = first_event(p.hype.ingest(batch.duplicate(true)), "hype_goal_completed")
	var td: Dictionary = first_event(t.hype.ingest(batch.duplicate(true)), "hype_goal_completed")
	assert_eq(int(pd.get("spectacle_points", 0)), 80, "untagged payout is the table value")
	assert_eq(int(td.get("spectacle_points", 0)), roundi(80 * 1.25),
		"Scene Stealer resonates the completer's goal payout x1.25")


func test_resonance_is_identity_without_held_tag() -> void:
	# Progress toward a tag must NOT resonate — only a HELD tag does.
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	sim.tags.progress["a"] = {"gorefest": 1}  # progressing, not yet held
	var batch: Array[Dictionary] = [
		{"type": "part_destroyed", "combatant": "b", "part": "left_arm"},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 1},
	]
	var meter_before: int = sim.hype.meter
	sim.hype.ingest(batch)
	assert_eq(sim.hype.meter - meter_before, HypeEngine.EVENT_WEIGHTS["part_destroyed"],
		"an un-held (merely-progressing) tag does not amplify")


# ---------------------------------------------------------------- new crowd goals

func make_goal_sim(goals: Array, sim_seed: int = 1234) -> CombatSim:
	var data: Dictionary = SimTestBase.load_static_data()
	data["crowd_goals"] = goals
	return CombatSim.new(sim_seed, data)


func test_goal_pratfall_completes_on_forced_action() -> void:
	var goal: Dictionary = {"id": "pratfall", "name": "Pratfall!", "kind": "forced_action", "params": {}, "payout": 35, "deadline_clocks": 3}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "pratfall", "pinned goal is active")
	var done: Dictionary = first_event(sim.hype.ingest([
		{"type": "forced_action_triggered", "actor": "a", "table": "Body", "roll": 4, "consequence": "stumble"},
	]), "hype_goal_completed")
	assert_eq(int(done.get("spectacle_points", -1)), 35, "any Forced Action completes Pratfall!")
	assert_true(sim.hype.active_goal.is_empty(), "goal cleared")


func test_goal_body_block_completes_on_protective_reaction() -> void:
	var goal: Dictionary = {"id": "body_block", "name": "Body Block!", "kind": "body_block",
		"params": {"reaction_keys": ["brace", "body_block"]}, "payout": 45, "deadline_clocks": 2}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	advance(sim, Clock.TICKS_PER_CLOCK)
	# A non-protective reaction does not complete it.
	assert_no_event(sim.hype.ingest([{"type": "reaction_resolved", "actor": "a", "cost": 1, "key": "riposte"}]),
		"hype_goal_completed", "a non-protective reaction is not a body block")
	assert_false(sim.hype.active_goal.is_empty(), "goal still active")
	var done: Dictionary = first_event(sim.hype.ingest([
		{"type": "reaction_resolved", "actor": "a", "cost": 1, "key": "brace"},
	]), "hype_goal_completed")
	assert_eq(int(done.get("spectacle_points", -1)), 45, "a brace completes Body Block!")


func test_goal_zoomies_accumulates_movement() -> void:
	var goal: Dictionary = {"id": "zoomies", "name": "Zoomies!", "kind": "move_spaces",
		"params": {"spaces": 6, "within_clocks": 1}, "payout": 40, "deadline_clocks": 1}
	var sim: CombatSim = make_goal_sim([goal])
	add_human(sim, "a")
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_eq(String(sim.hype.active_goal.get("id", "")), "zoomies", "pinned goal is active")
	assert_no_event(sim.hype.ingest([{"type": "moved", "actor": "a", "spaces": 3}]),
		"hype_goal_completed", "3 spaces is under the 6-space target")
	assert_eq(int(sim.hype.active_goal.get("progress", 0)), 3, "movement accumulates on the goal")
	var done: Dictionary = first_event(sim.hype.ingest([{"type": "moved", "actor": "a", "spaces": 4}]),
		"hype_goal_completed")
	assert_eq(int(done.get("spectacle_points", -1)), 40, "crossing 6 accumulated spaces completes Zoomies!")


# ---------------------------------------------------------------- end-to-end wiring

func test_reckless_end_to_end_real_windup() -> void:
	# The sim actually emits an exposed action_resolved and the tag engine sees it.
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	var declared: Array[Dictionary] = declare(sim, "a", attack_action("bleeding", 1, "b", "torso", {"cost": 2}))
	assert_event(declared, "exposed_state_changed", "the 2-Moment windup exposes the attacker")
	var events: Array[Dictionary] = advance(sim, 3)
	assert_event(events, "action_resolved", "the windup lands")
	assert_false(tag_events(events, "reckless").is_empty(), "landing it while Exposed is a real Reckless beat")
	assert_eq(progress_of(sim, "a", "reckless"), 1, "credited to the attacker end-to-end")


func test_formation_end_to_end_real_combo() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "b", {"position": [2, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "c", {"position": [1, 0]})
	var combo: Array[Dictionary] = sim.apply_command({"type": "combined_action", "members": [
		{"actor": "a", "action": attack_action("crushed", 3, "c", "torso")},
		{"actor": "b", "action": attack_action("crushed", 3, "c", "torso")},
	]})
	assert_event(combo, "combined_action_declared", "the combo is declared")
	assert_eq(tag_events(combo, "formation").size(), 2, "both partners earn a Formation beat from the real combo")


func test_the_bit_end_to_end_scores_via_hype_hook() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	var before: int = sim.hype.meter
	var events: Array[Dictionary] = sim.apply_command({"type": "bit", "actor": "a"})
	assert_event(events, "bit_performed", "bit resolved")
	assert_true(sim.hype.meter > before, "the generic spectacle_points hook scored the bit, zero hype changes")
	assert_true(int(sim.hype.ledger.get("a", 0)) > 0, "the bit's spectacle is credited to the performer")


# ---------------------------------------------------------------- determinism + serialization

## Drives a mixed camera-earning sequence: exposed strike (Reckless), a combined
## action (Formation), bits (The Bit), and idle Clocks.
func _earn_some_tags(sim: CombatSim) -> void:
	add_human(sim, "a", {"traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "b", {"position": [2, 0], "traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "c", {"position": [1, 0]})
	sim.apply_command({"type": "combined_action", "members": [
		{"actor": "a", "action": attack_action("crushed", 3, "c", "torso")},
		{"actor": "b", "action": attack_action("crushed", 3, "c", "torso")},
	]})
	advance(sim, 2)
	sim.apply_command({"type": "bit", "actor": "a"})
	sim.apply_command({"type": "bit", "actor": "b"})
	declare(sim, "a", attack_action("bleeding", 1, "c", "torso", {"cost": 2}))
	advance(sim, 3)


func test_determinism_same_log_same_tag_state() -> void:
	var sim1: CombatSim = make_sim(4242)
	var sim2: CombatSim = make_sim(4242)
	_earn_some_tags(sim1)
	_earn_some_tags(sim2)
	assert_eq(sim1.tags.to_dict(), sim2.tags.to_dict(), "same log -> identical tag state")
	assert_eq(sim1.state_hash(), sim2.state_hash(), "state_hash covers tags and stays replay-stable")
	assert_false(sim1.tags.progress.is_empty(), "precondition: the run actually earned tag progress")


func test_serialization_roundtrip_midprogress() -> void:
	var sim: CombatSim = make_sim(4242)
	_earn_some_tags(sim)
	assert_false(sim.tags.progress.is_empty(), "precondition: there is tag state to preserve")
	var resumed: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(resumed.tags.to_dict(), sim.tags.to_dict(), "tag state survives to_dict/from_dict")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hash identical after round-trip")
	# Resumed timeline stays in lockstep, resonance + escalation and all.
	sim.apply_command({"type": "bit", "actor": "a"})
	resumed.apply_command({"type": "bit", "actor": "a"})
	advance(sim, Clock.TICKS_PER_CLOCK)
	advance(resumed, Clock.TICKS_PER_CLOCK)
	assert_eq(resumed.tags.to_dict(), sim.tags.to_dict(), "resumed run tracks the uninterrupted run")
	assert_eq(resumed.state_hash(), sim.state_hash(), "hashes stay identical after resume")


func test_held_tag_survives_roundtrip_and_still_resonates() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a")
	add_human(sim, "b", {"position": [1, 0]})
	sim.tags.held["a"] = {"gorefest": true}
	var resumed: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_true(resumed.tags.holds("a", "gorefest"), "held tag restored")
	# Resonance still fires post-restore (hype.tags re-wired).
	var batch: Array[Dictionary] = [
		{"type": "part_destroyed", "combatant": "b", "part": "left_arm"},
		{"type": "action_resolved", "actor": "a", "kind": "attack", "result": "ok", "rounds": 1},
	]
	resumed.hype.ingest(batch)
	assert_eq(resumed.hype.meter, roundi(HypeEngine.EVENT_WEIGHTS["part_destroyed"] * 1.5),
		"the restored held tag still resonates (hype.tags re-wired in from_dict)")
