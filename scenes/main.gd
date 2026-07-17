extends Control
## Boot scene (KAN3-S1/S3). Presentation only: talks to the Game autoload, never
## to simulation/ classes. Stages a small demo fight so a launched project shows
## the field renderer live; `--shot` (user arg) saves a screenshot and quits
## (the S3 evidence path, run under xvfb in containers).


func _ready() -> void:
	var received: Array[Dictionary] = []
	Game.sim_event.connect(func(event: Dictionary) -> void: received.append(event))
	_stage_demo_fight()
	$Title.text = "GALACTIC PRIME TIME"
	var status: String = "engine online — %d events, state %s…" % [
		received.size(), Game.state_hash().substr(0, 12)]
	$Status.text = status
	print("[boot] ", status)
	if OS.get_cmdline_user_args().has("--shot"):
		_save_screenshot()


func _stage_demo_fight() -> void:
	Game.start_combat(1234)
	for spec: Dictionary in [
		{"id": "hero", "name": "Hero", "race": "human", "position": [2, 2],
			"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}},
		{"id": "nikita", "name": "Nikita", "race": "human", "position": [3, 3],
			"traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 2}},
		{"id": "stray", "name": "Stray", "race": "animal", "position": [1, 3],
			"traits": {"physique": 2, "reflexes": 4, "mind": 2, "charm": 3}},
		{"id": "roach", "name": "Roach", "race": "human", "position": [5, 2],
			"traits": {"physique": 4, "reflexes": 2, "mind": 1, "charm": 1}},
	]:
		Game.apply_command({"type": "add_combatant", "combatant": spec})
	Game.apply_command({"type": "declare_action", "actor": "hero", "action": {
		"kind": "attack", "cost": 1, "attack_range": 6,
		"damage": {"type": "bleeding", "amount": 2},
		"targets": [{"id": "roach", "part": "torso"}]}})
	for i: int in range(3):
		Game.apply_command({"type": "advance_tick"})


func _save_screenshot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	var dir: String = "res://docs/stories/notes/KAN3-S3"
	DirAccess.make_dir_recursive_absolute(dir)
	var err: Error = image.save_png(dir + "/boot-field.png")
	print("[shot] saved=", err == OK)
	get_tree().quit(0 if err == OK else 1)
