class_name PausedClockDriver
extends ClockDriver
## Solo driver (KAN3-S4): paused-on-decision, ATB-wait feel. The clock waits
## while any player-controlled combatant still owes a decision this tick, and
## a Forced Action on a player actor demands an explicit re-decision
## acknowledgement before the next advance — the game never auto-advances
## through drama (S4 AC5).

var player_controlled: Array[String] = []
var _declared: Dictionary = {}          # id -> true once declared/passed this tick
var _needs_redecision: Dictionary = {}  # id -> true after a forced action


func attach(controller: Node) -> void:
	super.attach(controller)
	game.forced_action_triggered.connect(_on_forced_action)


func set_party(ids: Array[String]) -> void:
	player_controlled = ids.duplicate()
	_declared = {}
	_needs_redecision = {}


## Declaring and passing are the same consent: this contestant is done deciding.
func mark_declared(id: String) -> void:
	_declared[id] = true


func mark_passed(id: String) -> void:
	_declared[id] = true


## The player has seen the Forced Action fallout and re-decided.
func acknowledge_redecision(id: String) -> void:
	_needs_redecision.erase(id)


## Slice UX: one END TURN press is the whole party consenting at once — mark every
## player-controlled id declared for this tick (equivalent to mark_declared on each).
func mark_party_declared() -> void:
	for id: String in player_controlled:
		_declared[id] = true


## Slice UX: the player has now SEEN the prior tick's forced-action fallout on the
## refreshed HUD — clear every pending re-decision so the clock is free again
## (bulk acknowledge_redecision for all actors).
func acknowledge_all() -> void:
	_needs_redecision = {}


func can_advance() -> bool:
	if not _needs_redecision.is_empty():
		return false
	for id: String in player_controlled:
		if not _declared.get(id, false):
			return false
	return true


func _before_advance() -> void:
	_declared = {}  # every tick is a fresh decision


func _on_forced_action(event: Dictionary) -> void:
	var actor := String(event.get("actor", ""))
	if player_controlled.has(actor):
		_needs_redecision[actor] = true
