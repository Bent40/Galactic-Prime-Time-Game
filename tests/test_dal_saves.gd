extends SimTestBase
## KAN3-S2 — DAL single-ownership + save/load round-trips (hash equality is the
## bar; replay-from-log proves saves are log-derivable per DIRECTION delta 5).


func _game() -> Node:
	return (load("res://controller/game_controller.gd") as GDScript).new()


func test_dal_counts_match_validator() -> void:
	var dal: Dal = Dal.new()
	assert_eq(dal.races().size(), 2, "races")
	assert_eq(dal.enemies().size(), 3, "enemies")
	assert_eq(dal.conditions().size(), 9, "conditions")
	assert_eq(dal.skills().size(), 43, "skills")
	assert_eq(dal.skill_thresholds().size(), 78, "thresholds")
	assert_eq(dal.items().size(), 28, "items")
	assert_eq(dal.tags().size(), 84, "tags")
	assert_eq(dal.modifiers().size(), 27, "modifiers")
	assert_eq(dal.patron_gods().size(), 5, "patron gods")


func test_dal_by_key_lookups() -> void:
	var dal: Dal = Dal.new()
	assert_eq(String(dal.skill("reversion").get("exclusive_to", "")), "nikita", "reversion is Nikita's")
	assert_eq(String(dal.enemy("incinedile").get("category", "")), "Boss", "incinedile lookup")
	assert_true(dal.item("kunai").has("description"), "kunai lookup (dev chat intact)")
	assert_true(dal.by_key("skills", "nope").is_empty(), "unknown key -> {}")


func _play_a_bit(game: Node) -> void:
	game.start_combat(4242)
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "a", "name": "a", "race": "human", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "b", "name": "b", "race": "human", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "declare_action", "actor": "a",
		"action": attack_action("bleeding", 2, "b", "torso")})
	for i: int in range(4):
		game.apply_command({"type": "advance_tick"})


func test_save_load_hash_equality() -> void:
	var game: Node = _game()
	_play_a_bit(game)
	var hash_at_save: String = game.state_hash()
	assert_true(game.save_game("test_s2"), "save succeeds")
	game.apply_command({"type": "advance_tick"})  # drift past the save point
	assert_true(game.load_game("test_s2"), "load succeeds")
	assert_eq(game.state_hash(), hash_at_save, "restored hash equals hash at save time")
	game.free()


func test_replay_from_log_rebuilds_state() -> void:
	var game: Node = _game()
	_play_a_bit(game)
	game.save_game("test_s2_replay")
	var envelope: Dictionary = SaveManager.new().load_game("test_s2_replay")
	# Ignore the snapshot entirely: rebuild from (seed, command_log) alone.
	var rebuilt: CombatSim = CombatSim.new(int(envelope["seed"]), load_static_data())
	for cmd: Variant in envelope["command_log"]:
		rebuilt.apply_command(cmd)
	assert_eq(rebuilt.state_hash(), game.state_hash(), "log-only replay = identical state")
	game.free()


func test_corrupt_save_fails_soft() -> void:
	DirAccess.make_dir_recursive_absolute(SaveManager.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveManager.SAVE_DIR + "/broken" + SaveManager.SAVE_EXT, FileAccess.WRITE)
	file.store_string("{this is not a valid envelope")
	file.close()
	var game: Node = _game()
	_play_a_bit(game)
	var hash_before: String = game.state_hash()
	assert_false(game.load_game("broken"), "corrupt load returns false")
	assert_eq(game.state_hash(), hash_before, "running state untouched by failed load")
	assert_true(game.saves.last_error != "", "error is explained")
	game.free()
