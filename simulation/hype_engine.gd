class_name HypeEngine
extends RefCounted
## Broadcast spectacle/hype meter v1 (deterministic) — the audience's excitement
## as derived sim state (DIRECTION.md: the slice ships a visible hype meter).
##
## Contract: a pure consumer of the event stream apply_command produces. No RNG,
## no wall-clock — hype is a function of (seed, command log) like everything
## else, serialized in CombatSim.to_dict() and therefore covered by state_hash.
## It emits its own events (hype_spike / hype_band_changed) back into the same
## stream so replays and Stage-2 broadcasts narrate the crowd for free.
##
## Scoring lives on the BROADCAST information plane: contestants never "see"
## hype directly; presentation surfaces it only through announcer/crowd channels.
## All numbers PLACEHOLDER (R14) pending tuning. Attribution v1 credits the
## combatant the event is about (or its actor) — cross-referencing attackers is
## a v2 concern (PROVISIONAL).

## PLACEHOLDER flat spectacle points per event type (R14).
const EVENT_WEIGHTS: Dictionary = {
	"combatant_died": 60,
	"mind_collapsed": 50,
	"breach_opened": 45,
	"bleed_out_started": 40,
	"bleed_out_stabilized": 35,  # the clutch save rates almost like the fall
	"part_destroyed": 30,
	"part_disabled": 18,
	"collateral_hit": 15,        # chaos is content
	"forced_action_triggered": 12,  # comedy beat
	"condition_advanced": 10,
	"grapple_started": 10,
	"reaction_resolved": 8,
}
const DAMAGE_POINTS_PER_HP: int = 4    # PLACEHOLDER (R14)
const SHOCK_POINTS_PER_TIER: int = 8   # PLACEHOLDER (R14)
const DECAY_PER_CLOCK: int = 15        # PLACEHOLDER (R14) — boredom between beats
const SPIKE_THRESHOLD: int = 50        # PLACEHOLDER (R14) — one-ingest gain that reads as a "moment"
## Band floors, checked highest-first (PLACEHOLDER, R14).
const BANDS := [["on_fire", 180], ["hot", 100], ["warm", 40], ["cold", 0]]

var meter: int = 0
var band: String = "cold"
var ledger: Dictionary = {}  # combatant id -> lifetime spectacle points credited


## Scores one command's event batch; returns hype events to append to the same
## batch. Never rescores hype_* events, so re-entry is safe.
func ingest(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var gain: int = 0
	for event: Dictionary in events:
		var etype := String(event.get("type", ""))
		if etype.begins_with("hype_"):
			continue
		var points: int = 0
		match etype:
			"damage_applied":
				points = maxi(0, int(event.get("amount", 0))) * DAMAGE_POINTS_PER_HP
			"shock_changed":
				points = maxi(0, int(event.get("to_tier", 0)) - int(event.get("from_tier", 0))) * SHOCK_POINTS_PER_TIER
			"clock_reset":
				meter = maxi(0, meter - DECAY_PER_CLOCK)
			_:
				points = int(EVENT_WEIGHTS.get(etype, 0))
		if points > 0:
			gain += points
			_credit(event, points)
	if gain > 0:
		meter += gain
		if gain >= SPIKE_THRESHOLD:
			out.append({"type": "hype_spike", "gain": gain, "meter": meter})
	var new_band: String = _band_for(meter)
	if new_band != band:
		out.append({"type": "hype_band_changed", "from_band": band, "to_band": new_band, "meter": meter})
		band = new_band
	return out


func _credit(event: Dictionary, points: int) -> void:
	var id := String(event.get("combatant", String(event.get("actor", ""))))
	if id == "":
		return
	ledger[id] = int(ledger.get(id, 0)) + points


func _band_for(value: int) -> String:
	for entry: Array in BANDS:
		if value >= int(entry[1]):
			return String(entry[0])
	return "cold"


func to_dict() -> Dictionary:
	return {
		"meter": meter,
		"band": band,
		"ledger": ledger.duplicate(true),
	}


static func from_dict(data: Dictionary) -> HypeEngine:
	var engine := HypeEngine.new()
	engine.meter = int(data.get("meter", 0))
	engine.band = String(data.get("band", "cold"))
	engine.ledger = (data.get("ledger", {}) as Dictionary).duplicate(true)
	return engine
