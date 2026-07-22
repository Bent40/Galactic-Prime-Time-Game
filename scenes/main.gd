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

## Guards the one-shot combat → verdict transition (combat_ended could in principle
## re-signal; the scene change must happen exactly once).
var _transitioned := false


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	_stage_slice()
	_attach_driver()
	# When the fight resolves (win/loss detected after a tick, driven by END TURN),
	# the run loop moves to the Verdict card. Game is an autoload that persists across
	# change_scene_to_file, so the final sim state is still there for view_verdict to
	# read — no serialization needed. In the --shot path the fight has not advanced,
	# so combat_ended has not fired and this stays dormant.
	Game.combat_ended.connect(_on_combat_ended)
	var hud: Control = HUD_SCENE.instantiate()
	add_child(hud)
	hud.bind(Game)
	if OS.get_cmdline_user_args().has("--shot"):
		_shot()


## Combat is over — hand off to the Verdict card. The verdict scene self-binds to
## the Game autoload in its own _ready and reads the persisted final state.
func _on_combat_ended(_event: Dictionary) -> void:
	if _transitioned:
		return
	_transitioned = true
	get_tree().change_scene_to_file("res://ui/screens/verdict_card.tscn")


## The demo-slice roster: the Incine-Dile boss + the two demo contestants, FRESH
## (Clock 1 / full HP / no hype) so the player drives the whole fight from the
## action bar — declare attacks, Camera Call, The Bit, MOVE, END TURN.
func _stage_slice() -> void:
	Game.start_combat(SEED)
	Game.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incine-Dile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0]}})
	_add_contestant("imani", "Imani", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, [1, 0])
	# Traits per demo_loadouts.json (Dario charm 5, R18). Camera Call stacks are
	# GRANTED via the spec's camera_call_stacks (both loadouts declare 1) — the
	# old Charm-30 over-cap hack is gone (F1 fixed). Dario carries his AUTHORED
	# bit (decision log #25) verbatim from the loadout; Imani has NONE (canonical
	# — zero interest in the camera), so the sim rejects the_bit from her.
	_add_contestant("dario", "Dario", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}, [0, 1],
		{"bit": {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."}})


## Attach the solo paused-clock driver AFTER the roster is staged and register it
## on the controller, so END TURN (advance_moment) routes through the slice gate
## and the driver runs the boss's turn each Moment. Party = the two contestants;
## the boss is AI-driven by run_enemy_turn.
func _attach_driver() -> void:
	_driver = PausedClockDriver.new()
	_driver.attach(Game)
	_driver.set_party(["imani", "dario"] as Array[String])
	Game.set_clock_driver(_driver)


func _add_contestant(id: String, cname: String, traits: Dictionary, pos: Array, extra: Dictionary = {}) -> void:
	var combatant: Dictionary = {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": pos, "traits": traits, "camera_call_stacks": 1}
	combatant.merge(extra, true)
	Game.apply_command({"type": "add_combatant", "combatant": combatant})


func _shot() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("res://hud_launch.png")
	get_tree().quit()
