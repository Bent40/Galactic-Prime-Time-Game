extends Control
## Launch scene (KAN-6) — boots the PLAYABLE demo slice: stands up the Incine-Dile
## encounter on the Game controller and shows the combat HUD. F5 / Play drops you
## straight into the fight; every HUD button issues a real command through the
## GameController. Presentation only — talks to the sim through the Game
## (GameController) autoload, never simulation/ classes. `--shot` saves a
## screenshot and quits (headless/CI evidence, run under xvfb).

const HUD_SCENE := preload("res://ui/hud/combat_hud.tscn")
const SEED := 14

## The solo paused-clock driver, kept in a scene var so it isn't freed (it is a
## RefCounted — dropping the last reference would release it). It drives BOTH
## sides of the tick: the party declares via the HUD, END TURN runs the enemy
## turn (boss ai_decide) and feeds the advance through advance_moment().
var _driver: PausedClockDriver


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	_stage_slice()
	_attach_driver()
	var hud: Control = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind(Game)
	if OS.get_cmdline_user_args().has("--shot"):
		_shot()


## The demo-slice roster: the Incine-Dile boss + the two demo contestants, FRESH
## (Clock 1 / full HP / no hype) so the player drives the whole fight from the
## action bar — declare attacks, Camera Call, The Bit, MOVE, END TURN.
func _stage_slice() -> void:
	Game.start_combat(SEED)
	Game.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0]}})
	_add_contestant("imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0])
	# Charm 30 on Dario grants his Camera Call stack — stacks derive from Charm
	# over-cap only, so this realizes the demo loadout's declared stack (F1 gap).
	_add_contestant("dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 30}, [0, 1])


## Attach the solo paused-clock driver AFTER the roster is staged and register it
## on the controller, so END TURN (advance_moment) routes through the slice gate
## and the driver runs the boss's turn each Moment. Party = the two contestants;
## the boss is AI-driven by run_enemy_turn.
func _attach_driver() -> void:
	_driver = PausedClockDriver.new()
	_driver.attach(Game)
	_driver.set_party(["imani", "dario"] as Array[String])
	Game.set_clock_driver(_driver)


func _add_contestant(id: String, cname: String, traits: Dictionary, pos: Array) -> void:
	Game.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits}})


func _shot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("res://hud_launch.png")
	get_tree().quit()
