extends SimTestBase
## KAN-4 wave 2e — RUN persistence to disk (closes the run engine's flagged gap
## "SaveManager was not extended"): SaveManager.save_run/load_run + the additive
## GameController.save_run/load_run pair, driven over the canonical authored
## data/demo_run.json exactly like test_run_state.gd (the fight-drive helpers
## are that file's, verbatim — every drive is guarded off live state, so
## identical state always re-issues identical commands; the lockstep property
## every continuation test here leans on).
##
## What these tests pin:
##   * save BETWEEN encounters -> load into a fresh controller -> identical
##     continuation (final run hash equals an UNSAVED control run's), and the
##     restored run log alone still rebuilds a bare RunState (DIRECTION #5 one
##     level up — the full history survives the disk round trip);
##   * save MID-encounter-2 (recruited roster) -> load -> the same command tail
##     lands on identical run AND sim hashes, with every existing view
##     (view_run, view_combatants, view_clock) reading identically right after
##     the load;
##   * corruption honesty: a corrupt file, a combat save, a foreign-version
##     envelope and a missing file each fail SOFT with their typed last_error —
##     the live session's run and sim are untouched, no partial restore;
##   * round-trip stability: save -> load -> save is BYTE-identical (the
##     envelope stamps no wall-clock metadata anywhere — the combat envelope
##     stamps none, run envelopes mirror that — so the WHOLE file is
##     deterministic payload and the comparison excludes nothing);
##   * a save from a run with a DECLINED recruit restores the STORY-honored
##     decline (decision #32): Sasha's may_reoffer decline leaves NO
##     gone-for-run mark — its absence survives the round trip — and
##     encounter 2 stages without her (it carries no recruit_offer).

const DEMO_RUN_PATH := "res://data/demo_run.json"
const MAX_FIGHT_TICKS := 60


# ---------------------------------------------------------------- plumbing
# (the test_run_state.gd drive, verbatim — guarded, lockstep-deterministic)

func _controller() -> Node:
	return (load("res://controller/game_controller.gd") as GDScript).new()


static func demo_run_def() -> Dictionary:
	return (SimTestBase.load_json(DEMO_RUN_PATH) as Dictionary).get("run", {})


func _start_demo_run(gc: Node) -> Array[Dictionary]:
	var def: Dictionary = demo_run_def()
	return gc.start_run(int(def.get("run_seed", 0)), def.get("party", []),
		def.get("encounters", []), load_static_data())


func _declare(gc: Node, actor: String, action: Dictionary) -> Array[Dictionary]:
	return gc.apply_command({"type": "declare_action", "actor": actor, "action": action})


## Encounter 1 (brood_landing): two staged brood strikes for deterministic
## carried damage, then a guarded real fight (declares + live enemy turns).
func _drive_encounter_one(gc: Node) -> void:
	gc.apply_run_command({"type": "begin_encounter"})
	_declare(gc, "roach_dog_1", attack_action("crushed", 4, "imani", "torso"))
	_declare(gc, "roach_dog_2", attack_action("crushed", 3, "sasha", "torso"))
	gc.apply_command({"type": "camera_call", "actor": "dario", "target": "imani"})
	gc.apply_command({"type": "prime", "actor": "dario", "key": "wind_up"})
	gc.apply_command({"type": "set_stance", "actor": "dario", "stance": "guarded"})
	gc.apply_command({"type": "apply_condition", "target": "dario", "part": "torso", "condition": "shock", "tier": 1})
	var pairs: Array = [["imani", "roach_dog_1"], ["dario", "roach_dog_3"], ["sasha", "roach_dog_2"]]
	for _i: int in range(20):
		if bool(gc.combat_status().get("over", false)):
			return
		var tick: int = gc.sim.clock.tick
		for pair: Variant in pairs:
			var attacker: CombatantState = gc.sim.combatants.get(String((pair as Array)[0]))
			var target: CombatantState = gc.sim.combatants.get(String((pair as Array)[1]))
			if attacker == null or target == null or not target.alive:
				continue
			if not attacker.can_act(tick) or tick < attacker.next_action_tick or attacker.windup_pending:
				continue
			if CombatantState.hex_distance(attacker.position, target.position) > 2:
				continue
			_declare(gc, attacker.id, attack_action("crushed", 3, target.id, "carapace", {"attack_range": 2}))
		gc.run_enemy_turn()
		gc.apply_command({"type": "advance_tick"})


## The between-fights treatment beat (guarded — the decline path has no sasha).
func _treat_carried_wounds(gc: Node) -> void:
	for id: String in ["imani", "sasha"]:
		if gc.sim.combatants.has(id):
			gc.apply_command({"type": "treat", "target": id, "part": "torso", "condition": "crushed", "mode": "resolve"})


## Encounter 2 fight: breach the surface, then put the exposed network down.
func _fight_boss(gc: Node, max_ticks: int) -> void:
	for _i: int in range(max_ticks):
		if bool(gc.combat_status().get("over", false)):
			return
		var boss: CombatantState = gc.sim.combatants.get("boss")
		var imani: CombatantState = gc.sim.combatants.get("imani")
		var tick: int = gc.sim.clock.tick
		if boss != null and boss.alive and imani != null and imani.can_act(tick) \
				and tick >= imani.next_action_tick and not imani.windup_pending:
			if not boss.breached:
				_declare(gc, "imani", attack_action("crushed", 10, "boss", "left_hand", {"attack_range": 2}))
			elif int((boss.parts.get("network", {}) as Dictionary).get("hp", 0)) > 0:
				_declare(gc, "imani", attack_action("crushed", 55, "boss", "network", {"attack_range": 2}))
		gc.run_enemy_turn()
		gc.apply_command({"type": "advance_tick"})


## The accept-path continuation from the between-encounters checkpoint. Shared
## by the live drives and every loaded continuation so they are command-identical.
func _finish_from_between(gc: Node) -> void:
	gc.apply_run_command({"type": "begin_encounter"})
	_treat_carried_wounds(gc)
	_fight_boss(gc, MAX_FIGHT_TICKS)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "end_run"})


## Drives the accept path up to the between-encounters checkpoint (encounter 1
## fought, offer accepted — the recruit is on the roster, no fight live).
func _drive_to_between(gc: Node) -> void:
	_start_demo_run(gc)
	_drive_encounter_one(gc)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	gc.apply_run_command({"type": "accept_recruit"})


## The on-disk path for a slot (the test_dal_saves staging idiom — tests live
## outside controller/, so file PEEKING here is read-only verification; every
## save WRITE still goes through SaveManager).
static func _save_path(save_name: String) -> String:
	return SaveManager.SAVE_DIR + "/" + SaveManager.sanitize_name(save_name) + SaveManager.SAVE_EXT


# --------------------------------------- (1) save/load BETWEEN encounters

func test_save_load_between_encounters_identical_continuation() -> void:
	# Unsaved control run: the hash the loaded continuation must land on.
	var gc_control: Node = _controller()
	_drive_to_between(gc_control)
	_finish_from_between(gc_control)
	assert_eq(String(gc_control.run.outcome), "WIN", "precondition: the control run wins")
	var control_hash: String = gc_control.run.state_hash()
	# Live run saved at the checkpoint (no fight live -> the envelope carries
	# run state only; the next encounter is re-derived from it, like restore_run).
	var gc_live: Node = _controller()
	_drive_to_between(gc_live)
	assert_eq(String(gc_live.run.phase), "between", "precondition: saving between encounters")
	assert_true(gc_live.save_run("runpersist_between"), "save_run succeeds between encounters")
	# Load into a FRESH controller and drive the identical continuation.
	var gc_loaded: Node = _controller()
	assert_true(gc_loaded.load_run("runpersist_between", load_static_data()), "load_run succeeds")
	assert_eq(gc_loaded.run.roster.size(), 3, "the restored roster carries the recruit")
	assert_eq(String(gc_loaded.run.phase), "between", "the restored run is at the between checkpoint")
	_finish_from_between(gc_loaded)
	assert_eq(gc_loaded.run.state_hash(), control_hash,
		"save -> load -> continue lands on the unsaved control run's final hash")
	# The restored run log carries the FULL history (load_game idiom): a bare
	# RunState replaying it alone reproduces the final run state.
	var bare: RunState = RunState.new()
	for cmd: Dictionary in gc_loaded.run_command_log:
		bare.apply_command(cmd)
	assert_eq(bare.state_hash(), control_hash,
		"a bare RunState replay of the loaded-and-continued run log reproduces the run")
	gc_control.free()
	gc_live.free()
	gc_loaded.free()


# --------------------------------------- (2) save/load MID-encounter-2

func test_save_load_mid_encounter_two_identical_continuation() -> void:
	var gc_live: Node = _controller()
	_drive_to_between(gc_live)
	gc_live.apply_run_command({"type": "begin_encounter"})
	_treat_carried_wounds(gc_live)
	_fight_boss(gc_live, 1)  # one real fight tick in — genuinely mid-encounter
	assert_false(bool(gc_live.combat_status().get("over", false)), "precondition: the fight is NOT over at the save")
	assert_true(gc_live.save_run("runpersist_mid"), "save_run succeeds mid-encounter")
	# The view surface at save time — the loaded session must read identically.
	var view_run_at_save: Dictionary = gc_live.view_run()
	var view_combatants_at_save: Array[Dictionary] = gc_live.view_combatants()
	var view_clock_at_save: Dictionary = gc_live.view_clock()
	# Live continuation to the end of the run.
	_fight_boss(gc_live, MAX_FIGHT_TICKS)
	gc_live.apply_run_command({"type": "end_encounter"})
	gc_live.apply_run_command({"type": "end_run"})
	var live_run_hash: String = gc_live.run.state_hash()
	var live_sim_hash: String = gc_live.sim.state_hash()
	assert_eq(String(gc_live.run.outcome), "WIN", "precondition: the live continuation wins the run")
	# Load into a fresh controller: recruited roster mid-fight, views identical,
	# and the SAME guarded command tail lands on identical hashes.
	var gc_loaded: Node = _controller()
	assert_true(gc_loaded.load_run("runpersist_mid", load_static_data()), "load_run succeeds")
	assert_true(gc_loaded.sim.combatants.has("sasha"), "the recruited member is in the restored mid-fight sim")
	assert_eq(int((gc_loaded.sim.combatants["sasha"] as CombatantState).parts["torso"]["hp"]), 3,
		"her carried encounter-1 wound is in the restored fight")
	assert_eq(gc_loaded.view_run(), view_run_at_save, "view_run reads identically after the load")
	assert_eq(gc_loaded.view_combatants(), view_combatants_at_save, "view_combatants reads identically after the load")
	assert_eq(gc_loaded.view_clock(), view_clock_at_save, "view_clock reads identically after the load")
	_fight_boss(gc_loaded, MAX_FIGHT_TICKS)
	gc_loaded.apply_run_command({"type": "end_encounter"})
	gc_loaded.apply_run_command({"type": "end_run"})
	assert_eq(gc_loaded.run.state_hash(), live_run_hash,
		"mid-encounter-2 save -> load -> same command tail = identical final run hash")
	assert_eq(gc_loaded.sim.state_hash(), live_sim_hash,
		"and the final combat states match hash-for-hash")
	gc_live.free()
	gc_loaded.free()


# --------------------------------------- (3) corruption honesty (typed soft fails)

func test_failed_loads_are_typed_and_leave_the_live_session_untouched() -> void:
	# A live session mid-encounter-2 — the state every failed load must preserve.
	var gc: Node = _controller()
	_drive_to_between(gc)
	gc.apply_run_command({"type": "begin_encounter"})
	_treat_carried_wounds(gc)
	_fight_boss(gc, 1)
	var run_hash_before: String = gc.run.state_hash()
	var sim_hash_before: String = gc.sim.state_hash()
	var run_log_before: int = gc.run_command_log.size()
	# (a) corrupt file staged on disk (the test_dal_saves idiom).
	DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIR)
	var file: FileAccess = FileAccess.open(_save_path("runpersist_broken"), FileAccess.WRITE)
	file.store_string("{this is not a valid envelope")
	file.close()
	assert_false(gc.load_run("runpersist_broken", load_static_data()), "corrupt load returns false")
	assert_eq(gc.saves.last_error, "corrupt run-save envelope", "typed error: corrupt envelope")
	# (b) a COMBAT save is not a run save.
	assert_true(gc.save_game("runpersist_combat_slot"), "precondition: a combat save exists")
	assert_false(gc.load_run("runpersist_combat_slot", load_static_data()), "a combat save fails a run load")
	assert_eq(gc.saves.last_error, "not a run save", "typed error: wrong save kind")
	# (c) foreign version: a well-shaped run envelope from the future.
	var future: FileAccess = FileAccess.open(_save_path("runpersist_future"), FileAccess.WRITE)
	future.store_string(var_to_str({"version": 99, "kind": "run", "run_snapshot": {}}))
	future.close()
	assert_false(gc.load_run("runpersist_future", load_static_data()), "a foreign-version envelope fails")
	assert_eq(gc.saves.last_error, "unsupported run-save version", "typed error: the version gate")
	# (d) missing file.
	assert_false(gc.load_run("runpersist_never_saved", load_static_data()), "a missing save fails")
	assert_eq(gc.saves.last_error, "no such save", "typed error: no such save")
	# No partial restore anywhere: run, sim and log untouched by every failure.
	assert_eq(gc.run.state_hash(), run_hash_before, "the live run is untouched by failed loads")
	assert_eq(gc.sim.state_hash(), sim_hash_before, "the live sim is untouched by failed loads")
	assert_eq(gc.run_command_log.size(), run_log_before, "the live run log is untouched by failed loads")
	assert_eq(String(gc.run.phase), "combat", "the live encounter is still on")
	gc.free()


# --------------------------------------- (4) round-trip stability (byte-identical)

func test_save_load_save_round_trip_is_byte_identical() -> void:
	# The envelope stamps NO wall-clock metadata (mirror of the combat envelope),
	# so the WHOLE file is deterministic payload: save -> load -> save must be
	# byte-identical, both between encounters and mid-fight.
	var gc: Node = _controller()
	_drive_to_between(gc)
	assert_true(gc.save_run("runpersist_rt_a"), "first between-encounters save")
	var gc_b: Node = _controller()
	assert_true(gc_b.load_run("runpersist_rt_a", load_static_data()), "round-trip load")
	assert_true(gc_b.save_run("runpersist_rt_b"), "re-save after the load")
	assert_eq(FileAccess.get_file_as_string(_save_path("runpersist_rt_b")),
		FileAccess.get_file_as_string(_save_path("runpersist_rt_a")),
		"between-encounters save -> load -> save is byte-identical")
	# Mid-encounter round trip (exercises the CombatSim block too).
	gc_b.apply_run_command({"type": "begin_encounter"})
	_treat_carried_wounds(gc_b)
	_fight_boss(gc_b, 1)
	assert_true(gc_b.save_run("runpersist_rt_mid_a"), "first mid-encounter save")
	var gc_c: Node = _controller()
	assert_true(gc_c.load_run("runpersist_rt_mid_a", load_static_data()), "mid-encounter round-trip load")
	assert_true(gc_c.save_run("runpersist_rt_mid_b"), "mid-encounter re-save")
	assert_eq(FileAccess.get_file_as_string(_save_path("runpersist_rt_mid_b")),
		FileAccess.get_file_as_string(_save_path("runpersist_rt_mid_a")),
		"mid-encounter save -> load -> save is byte-identical")
	gc.free()
	gc_b.free()
	gc_c.free()


# --------------------------------------- (5) the DECLINED-recruit state persists

func test_declined_recruit_state_survives_the_disk_round_trip() -> void:
	var gc: Node = _controller()
	_start_demo_run(gc)
	_drive_encounter_one(gc)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	gc.apply_run_command({"type": "decline_recruit"})
	assert_true(gc.save_run("runpersist_declined"), "save after the decline")
	var gc_loaded: Node = _controller()
	assert_true(gc_loaded.load_run("runpersist_declined", load_static_data()), "load the declined-state save")
	assert_eq(gc_loaded.run.roster.size(), 2, "the restored roster stays the founding pair")
	# Sasha's authored on_decline is may_reoffer (decision #32 story-driven
	# declines): the decline leaves NO gone-for-run mark, and what must survive
	# the round trip is that ABSENCE — a later encounter's recruit_offer could
	# re-offer her (the demo run's encounter 2 simply carries none; the re-offer
	# beats themselves are pinned in test_run_state.gd's synthetic runs).
	assert_true(gc_loaded.run.declined.is_empty(),
		"a may_reoffer decline leaves no gone-mark, load or no load (#32)")
	var reoffer: Array[Dictionary] = gc_loaded.apply_run_command(
		{"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	assert_eq(String(first_event(reoffer, "run_command_rejected").get("reason", "")), "no_such_offer",
		"no beat is open between encounters — only a later encounter's recruit_offer re-offers")
	gc_loaded.apply_run_command({"type": "begin_encounter"})
	assert_false(gc_loaded.sim.combatants.has("sasha"), "encounter 2 stages WITHOUT the declined recruit")
	gc.free()
	gc_loaded.free()
