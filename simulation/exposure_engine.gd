class_name ExposureEngine
extends RefCounted
## Exposed-state bookkeeping (rules-addendum R2/R7/R9).
##
## Exposed is a derived state: multi-Moment windup in flight (R2, "Channeling"),
## a timed Exposed status (Stumble/Overcommit fallout, Exhausted body-hit),
## grappling either way (R9), Helpless (R7), or Prone (R7). This helper keeps a
## cached flag on the combatant so flips emit exposed_state_changed exactly once.


static func is_exposed(c: CombatantState, tick: int) -> bool:
	return c.windup_pending \
		or c.exposed_until_tick > tick \
		or c.grappling != "" \
		or c.grappled_by != "" \
		or c.is_helpless(tick) \
		or bool(c.statuses.get("prone", false))


## Recomputes the cache; returns an exposed_state_changed event on a flip.
static func refresh(c: CombatantState, tick: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var now: bool = is_exposed(c, tick)
	if now != c.exposed_cache:
		c.exposed_cache = now
		events.append({
			"type": "exposed_state_changed",
			"combatant": c.id,
			"exposed": now,
		})
	return events


func to_dict() -> Dictionary:
	return {}


static func from_dict(_data: Dictionary) -> ExposureEngine:
	return ExposureEngine.new()
