extends SimTestBase
## Criterion 19 (DIRECTION contract), thoroughly:
## - identical (seed, command log) => identical state hash after 100+ mixed
##   commands that exercise the RNG (Forced Actions from unmet requirements
##   and above-weight grapples),
## - snapshot at command 50 -> restore -> replay the tail => the final hash is
##   identical to the uninterrupted run.

const RUN_SEED: int = 424242
const SNAPSHOT_AT: int = 50


## Fixed, deterministic command script (built fresh per run so no Dictionary
## instances are shared between sims). Rejected commands along the way are
## fine — rejections are deterministic and mutate nothing.
func _build_script() -> Array[Dictionary]:
	var cmds: Array[Dictionary] = []
	cmds.append({"type": "add_combatant", "combatant": {
		"id": "a", "name": "Understat", "race": "human", "position": [0, 0],
		"traits": {"physique": 1, "reflexes": 2, "mind": 2, "charm": 2},
	}})
	cmds.append({"type": "add_combatant", "combatant": {
		"id": "b", "name": "Gunner", "race": "human", "position": [1, 0],
		"traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3},
		"items": [{
			"key": "pistol", "item_type": "weapon", "damage_type": "bleeding",
			"damage_amount": 1, "base_moment_cost": 1, "rpm": 2, "magazine": 4,
			"attack_range": 6,
		}],
	}})
	cmds.append({"type": "add_combatant", "combatant": {
		"id": "c", "name": "Training Dummy", "position": [2, 0], "category": "Elite",
		"size": "Medium",
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 200, "lethal": true},
			{"key": "left_arm", "hp": 100, "lethal": false},
			{"key": "right_arm", "hp": 100, "lethal": false},
		],
	}})
	for i: int in range(16):
		if i % 4 == 2:
			# Above-weight grapple: Physique 1 vs 5 -> Forced Action – Body d6.
			cmds.append({"type": "declare_action", "actor": "a", "action": {"kind": "grapple", "target": "b"}})
		else:
			# Unmet stat requirement -> Forced Action – Tool d6 every resolution.
			cmds.append({"type": "declare_action", "actor": "a", "action": {
				"kind": "attack", "cost": 1, "attack_range": 3,
				"damage": {"type": "chilled", "amount": 2},
				"requirements": {"physique": 4},
				"targets": [{"id": "c", "part": "left_arm"}],
			}})
		if i % 4 == 3:
			cmds.append({"type": "declare_action", "actor": "b", "action": {"kind": "grapple_escape"}})
		elif i % 4 == 0 and i > 0:
			cmds.append({"type": "declare_action", "actor": "b", "action": {"kind": "reload", "item": "pistol"}})
		else:
			cmds.append({"type": "declare_action", "actor": "b", "action": {
				"kind": "attack", "item": "pistol", "rounds": 2,
				"targets": [{"id": "c", "part": "torso"}],
			}})
		cmds.append({"type": "move", "actor": "c", "to": [2 + (i % 2), 1]})
		if i % 3 == 0:
			cmds.append({"type": "apply_condition", "target": "c", "part": "right_arm", "condition": "chilled", "tier": 1})
		if i % 5 == 0:
			cmds.append({"type": "treat", "target": "c", "part": "right_arm", "condition": "chilled", "mode": "delay"})
		cmds.append({"type": "advance_tick"})
	while cmds.size() < 100:
		cmds.append({"type": "advance_tick"})
	return cmds


func _run_range(sim: CombatSim, cmds: Array[Dictionary], from_index: int, to_index: int) -> int:
	var forced_rolls: int = 0
	for i: int in range(from_index, to_index):
		var events: Array[Dictionary] = sim.apply_command(cmds[i])
		forced_rolls += events_of(events, "forced_action_triggered").size()
	return forced_rolls


func test_identical_seed_and_log_produce_identical_hash() -> void:
	var cmds1: Array[Dictionary] = _build_script()
	var cmds2: Array[Dictionary] = _build_script()
	assert_true(cmds1.size() >= 100, "the mixed script has at least 100 commands (has %d)" % cmds1.size())

	var sim1: CombatSim = make_sim(RUN_SEED)
	var forced1: int = _run_range(sim1, cmds1, 0, cmds1.size())
	var sim2: CombatSim = make_sim(RUN_SEED)
	var forced2: int = _run_range(sim2, cmds2, 0, cmds2.size())

	assert_true(forced1 >= 4, "the script actually exercised the RNG (forced rolls: %d)" % forced1)
	assert_eq(forced2, forced1, "both runs rolled the same forced actions")
	assert_eq(sim2.state_hash(), sim1.state_hash(), "identical (seed, command log) => identical state hash")

	# Different seed must diverge (the RNG is real, not a constant).
	var sim3: CombatSim = make_sim(RUN_SEED + 1)
	_run_range(sim3, _build_script(), 0, cmds1.size())
	assert_ne(sim3.state_hash(), sim1.state_hash(), "a different seed produces a different history")


func test_snapshot_restore_replay_tail() -> void:
	var cmds: Array[Dictionary] = _build_script()
	assert_true(cmds.size() > SNAPSHOT_AT, "script is longer than the snapshot point")

	# Uninterrupted reference run.
	var sim_full: CombatSim = make_sim(RUN_SEED)
	_run_range(sim_full, cmds, 0, cmds.size())
	var hash_full: String = sim_full.state_hash()

	# Head run, snapshotted mid-stream at command 50.
	var sim_head: CombatSim = make_sim(RUN_SEED)
	_run_range(sim_head, cmds, 0, SNAPSHOT_AT)
	var snapshot: Dictionary = sim_head.to_dict()
	var sim_restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(sim_restored.state_hash(), sim_head.state_hash(), "restore is a faithful roundtrip (incl. RNG state)")

	# Replay the tail on both the original and the restored sim.
	_run_range(sim_head, cmds, SNAPSHOT_AT, cmds.size())
	_run_range(sim_restored, cmds, SNAPSHOT_AT, cmds.size())
	assert_eq(sim_head.state_hash(), hash_full, "continued head run matches the uninterrupted run")
	assert_eq(sim_restored.state_hash(), hash_full, "snapshot -> restore -> replay tail => identical final hash")
