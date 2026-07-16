class_name Clock
extends RefCounted
## Absolute-tick timeline + scheduled-action priority queue (rules-addendum R0/R1).
##
## Internally the sim runs a monotonic absolute tick counter starting at 0.
## "Moment" is presentation only: moment = 10 - (tick % 10), so ticks 0..9
## display as Moments 10..1. A Clock is one lap of 10 ticks; the Clock reset
## fires after the tick displaying Moment 1 (tick % 10 == 9) completes.

const TICKS_PER_CLOCK: int = 10

var tick: int = 0
## Monotonic declaration counter — deterministic tie-break for same-tick entries.
var next_seq: int = 0
## Scheduled entries: {"tick": int, "seq": int, "actor": String, "action": Dictionary,
## "window": int} — window > 0 marks a multi-Moment windup (declare/resolve gap, R2).
var queue: Array[Dictionary] = []


func moment() -> int:
	return TICKS_PER_CLOCK - (tick % TICKS_PER_CLOCK)


## True while the CURRENT tick is the one displaying Moment 1 — completing it
## fires the Clock reset (R0/R1 order of operations, step 3).
func completes_clock() -> bool:
	return tick % TICKS_PER_CLOCK == TICKS_PER_CLOCK - 1


func advance() -> void:
	tick += 1


func schedule(actor_id: String, action: Dictionary, resolve_tick: int, window: int) -> Dictionary:
	var entry: Dictionary = {
		"tick": resolve_tick,
		"seq": next_seq,
		"actor": actor_id,
		"action": action,
		"window": window,
	}
	next_seq += 1
	queue.append(entry)
	return entry


## Removes and returns all entries due at `at_tick`, ordered by declaration seq.
func take_due(at_tick: int) -> Array[Dictionary]:
	var due: Array[Dictionary] = []
	var rest: Array[Dictionary] = []
	for entry: Dictionary in queue:
		if int(entry["tick"]) <= at_tick:
			due.append(entry)
		else:
			rest.append(entry)
	queue = rest
	due.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["seq"]) < int(b["seq"]))
	return due


func cancel_for(actor_id: String) -> int:
	var kept: Array[Dictionary] = []
	var cancelled: int = 0
	for entry: Dictionary in queue:
		if String(entry["actor"]) == actor_id:
			cancelled += 1
		else:
			kept.append(entry)
	queue = kept
	return cancelled


func has_windup_for(actor_id: String) -> bool:
	for entry: Dictionary in queue:
		if String(entry["actor"]) == actor_id and int(entry["window"]) > 0:
			return true
	return false


func to_dict() -> Dictionary:
	return {
		"tick": tick,
		"next_seq": next_seq,
		"queue": queue.duplicate(true),
	}


static func from_dict(data: Dictionary) -> Clock:
	var clock := Clock.new()
	clock.tick = int(data.get("tick", 0))
	clock.next_seq = int(data.get("next_seq", 0))
	var raw_queue: Array = data.get("queue", [])
	for entry: Variant in raw_queue:
		clock.queue.append((entry as Dictionary).duplicate(true))
	return clock
