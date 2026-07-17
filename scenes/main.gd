extends Control
## Boot scene (KAN3-S1). Presentation only: talks to the Game autoload, never to
## simulation/ classes. Runs a tiny smoke exchange so a launched project proves
## the controller wiring live, then shows status.


func _ready() -> void:
	var received: Array[Dictionary] = []
	Game.sim_event.connect(func(event: Dictionary) -> void: received.append(event))
	Game.start_combat(1234)
	Game.apply_command({"type": "add_combatant", "combatant": {
		"id": "boot_check", "name": "Boot Check", "race": "human", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
	}})
	Game.apply_command({"type": "advance_tick"})
	var status: String = "engine online — %d events, state %s…" % [
		received.size(), Game.state_hash().substr(0, 12)]
	$Title.text = "GALACTIC PRIME TIME"
	$Status.text = status
	print("[boot] ", status)
