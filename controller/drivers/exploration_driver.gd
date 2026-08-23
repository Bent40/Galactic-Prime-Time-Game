class_name ExplorationClockDriver
extends ClockDriver
## FREE-FORM EXPLORATION driver (R34 TIME AMENDMENT + R35 — the KAN-6 half the
## sim story left open and flagged: "nothing issues the exploration time step or
## the pause / inventory-UI control that must stop it").
##
## THE RULING THIS IMPLEMENTS, in the owner's own terms:
##   * Exploration is "the clock RUNS, but there is no turn order and nothing
##     costs Moments" — NOT "the clock is stopped". So something has to make
##     time pass out of combat, at a real-time cadence, and that something is a
##     driver: the sim never reads a wall clock, and state stays a pure function
##     of (seed, ordered command log) precisely because the CADENCE lives out
##     here while the STEP is a logged command.
##   * The step is `advance_tick` — the ONE real tick path (never a parallel
##     exploration clock). Out of combat that same tick IS the patrol beat, so
##     mobs walk their authored routes off it and can make contact with a
##     motionless party.
##   * PAUSE IS NOT SIM STATE and deliberately has none. Pausing is exactly
##     this driver declining to issue time steps. Same mechanism for R35's
##     Pokemon clause: while an inventory / item-use surface is open the driver
##     MUST stop issuing `advance_tick`, so a burn cannot tick while you rummage.
##
## Presentation calls tick_realtime(delta) every frame; everything else is this
## driver's own bookkeeping. It reads the phase through GameController's
## read-only `view_phase()` projection — never `sim.phase` — so it stays on the
## same public contract the HUD uses.
##
## COEXISTENCE with PausedClockDriver: the two never both fire. This one only
## advances while `view_phase().exploring` is true; the paused driver only
## advances on END TURN, which the HUD replaces with ENTER while exploring. The
## controller's registered `clock_driver` stays the combat one — this driver is
## held by the presentation layer that pumps it.

## Real seconds per exploration time step. PLACEHOLDER (R14): a tick is ~0.5
## FICTIONAL seconds (R0/R1), and this is how fast fiction runs while the party
## walks. Slow enough to read the board, fast enough that standing still is not
## free — "the crowd is bored by safety" (R35) needs the meter to actually move.
const SECONDS_PER_TICK: float = 1.25

## Driver-side pause. Not mirrored into the sim, ever (see the header).
var paused: bool = false

## Named UI surfaces that suspend time while open — R35's inventory clause is
## the ruled one. A set (name -> true) rather than a bool so two overlapping
## surfaces cannot un-pause each other on close.
var blockers: Dictionary = {}

var _accum: float = 0.0
## Ticks this driver has issued — evidence for the capture drivers and tests
## that the beat is real (and how it can be asserted without a wall clock).
var steps_issued: int = 0


## Toggles the manual pause and returns the new state.
func toggle_pause() -> bool:
	paused = not paused
	if paused:
		_accum = 0.0
	return paused


## Opens/closes a named time-suspending surface (R35: "stop issuing advance_tick
## while an inventory / item-use UI is open").
func set_blocker(name: String, active: bool) -> void:
	if active:
		blockers[name] = true
		_accum = 0.0
	else:
		blockers.erase(name)


func blocked() -> bool:
	return paused or not blockers.is_empty()


## Why time is not moving right now, for the HUD's own readout ("" = it is).
func hold_reason() -> String:
	if paused:
		return "PAUSED"
	if not blockers.is_empty():
		var names: Array = blockers.keys()
		names.sort()
		return String(names[0]).to_upper() + " OPEN"
	return ""


## True only while the sim is genuinely in free-form exploration and nothing is
## holding time. Reads the public projection, never sim internals.
func can_advance() -> bool:
	if game == null or game.sim == null or blocked():
		return false
	return bool((game.view_phase() as Dictionary).get("exploring", false))


## ONE exploration time step. Deliberately does NOT call run_enemy_turn: the
## Moment-ORDER family (`ai_decide` included) is rejected out of combat by
## ruling, so asking for it would only spray `clock_stopped` rejections into
## the command log. The patrol beat rides the tick itself.
func try_advance() -> bool:
	if not can_advance():
		return false
	game.apply_command({"type": "advance_tick"})
	steps_issued += 1
	return true


## The presentation loop's one call. Accumulates real time and spends it in
## whole steps; a long frame hitch pays out at most MAX_CATCHUP_STEPS so a
## stalled window can never dump twenty ticks (and twenty patrol beats) into
## the log at once. Returns how many steps were issued this frame.
const MAX_CATCHUP_STEPS: int = 2


func tick_realtime(delta: float) -> int:
	if not can_advance():
		_accum = 0.0
		return 0
	_accum += maxf(0.0, delta)
	var issued := 0
	while _accum >= SECONDS_PER_TICK and issued < MAX_CATCHUP_STEPS:
		_accum -= SECONDS_PER_TICK
		if not try_advance():
			break   # contact just started the fight — stop mid-budget
		issued += 1
	if issued >= MAX_CATCHUP_STEPS:
		_accum = 0.0
	return issued
