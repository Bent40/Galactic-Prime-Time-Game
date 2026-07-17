class_name ClockDriver
extends RefCounted
## Clock-driver SWAP CONTRACT (KAN3-S4; DIRECTION §fields/clock-drivers).
##
## The sim NEVER self-advances (R0): a driver is the ONLY source of
## `advance_tick` commands, fed through GameController.apply_command like any
## other command. Implementations plug in without any sim or controller change:
##   - PausedClockDriver (solo, ATB-wait)          — this story
##   - declare-window driver (co-op, 5s default per Q71)  — Stage 1.5
##   - wall-clock driver (spectated broadcasts)    — Stage 2
## Contract: attach(controller) once; call try_advance() from the presentation
## loop; the driver decides WHEN a tick is fed, never WHAT happens inside it.

var game: Node


func attach(controller: Node) -> void:
	game = controller


## Override: is the driver willing to advance right now?
func can_advance() -> bool:
	return false


## Feeds exactly one advance_tick when allowed. Returns whether it advanced.
func try_advance() -> bool:
	if game == null or game.sim == null or not can_advance():
		return false
	_before_advance()
	game.apply_command({"type": "advance_tick"})
	return true


## Override hook: per-tick bookkeeping (reset declare state, etc.).
func _before_advance() -> void:
	pass
