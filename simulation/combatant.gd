class_name CombatantState
extends RefCounted
## Pure-state combatant record (MODEL — no Godot node deps).
##
## Built from a race/enemy seed shape (data/races.json, data/enemies.json) or an
## explicit spec. All mutation happens through CombatSim's command stream; this
## class only holds state plus cheap derived-stat queries (rules-addendum R6).

const SIZE_ORDER: Dictionary = {"Small": 0, "Medium": 1, "Large": 2, "Huge": 3}
const TRAIT_KEYS: Array[String] = ["physique", "reflexes", "mind", "charm"]

var id: String = ""
var display_name: String = ""
var team: String = ""
var category: String = "Contestant"  # Contestant / Mob / Elite / Boss
var size: String = "Medium"
var position: Vector2i = Vector2i.ZERO

## part_key -> {"name": String, "hp": int, "base_max_hp": int, "lethal": bool,
##              "disabled": bool, "destroyed": bool, "hidden": bool}
var parts: Dictionary = {}
## part_key -> {condition_id -> instance}; instance = {"tier": int, "delayed": bool,
##   "reapplied_this_clock": bool, "poison_type": String, "activation_delay": int,
##   "last_attack_advance_tick": int}
var conditions: Dictionary = {}
## Timers: {"kind": "suffocation"|"dissolution"|"death"|"bleed_out",
##   "condition": String, "part": String, "clocks_remaining": int, "delay": int,
##   "paused": bool}
var timers: Array[Dictionary] = []
## Shock high-water mark (R13): momentary-event model — no pool, no in-combat
## decay; reset fresh per combat (field default, like shock itself).
var shock: int = 0
## part_key -> true for every wound that has PRODUCED shock this combat. Re-abusing
## an already-shocked wound elevates the incoming source one tier (R13 per-organ).
var shocked_parts: Dictionary = {}
## Shock T2 (Stutter, R13): set when shock newly reaches T2 — the combatant's next
## resolved scheduled action simply FAILS (no Forced Action roll); cleared there.
var shock_stutter_pending: bool = false

## trait -> {"base": int, "bonus": int, "level_bonus": int}
var stats: Dictionary = {}
var level_points: int = 0
var resistances: Dictionary = {"Physical": 0, "Affliction": 0, "Psychic": 0}
## Player-allocated Reflexes-derived physical resistance: condition_id -> int (R6).
var allocated_physical: Dictionary = {}

var boss_traits: Dictionary = {}
var breached: bool = false
## Enemy ability list (data/enemies.json shape) — consumed by EnemyAI (I-16).
var abilities: Array[Dictionary] = []
## Boss phase table (data/enemies.json "phases") — consumed by EnemyAI (I-16).
var boss_phases: Array[Dictionary] = []

## item_key -> item dict (normalized; ranged items carry "magazine_loaded").
var items: Dictionary = {}

var alive: bool = true
var removed_from_play: bool = false  # dissolution mind-collapse (R5) — never "died"

# Scheduling / per-tick bookkeeping
var next_action_tick: int = 0
var windup_pending: bool = false
var free_action_used: bool = false
var reaction_used: bool = false
var moved_this_tick: bool = false
var inventory_uses: int = 0
var took_scheduled_action_this_clock: bool = false
var damage_taken_this_tick: int = 0
## R15/NQ2 single-hit breach tracking (reset each tick): the largest single hit
## landed this tick, where a combined action's linked strikes (shared combo_id)
## merge into one hit.
var largest_single_hit_this_tick: int = 0
var combo_hits_this_tick: Dictionary = {}  # combo_id -> accumulated damage this tick
var cooldowns: Dictionary = {}  # action key -> tick when available again (R3)

# Status effects / forced-action fallout
var exposed_until_tick: int = 0
var helpless_until_tick: int = 0
var unarmed_until_tick: int = 0
var strained_grip: bool = false
var part_locked_until: Dictionary = {}  # part_key -> tick
var statuses: Dictionary = {}  # "overwhelmed"/"prone"/"slowed"/"incapacitated" -> true
var exposed_cache: bool = false

# Skill-effect state (SkillBook archetypes; ActionResolver owns the transitions).
## self_guard (brace): the next incoming Crush/Burn hit is reduced by this, then
## the guard is consumed (cleared to 0).
var brace_guard: int = 0
## setup_debuff (feint): set on the TARGET; its next resolved scheduled action
## collapses into a Forced Action – Tool, and the flag clears at that resolution.
var feint_forced: bool = false
## self_stance (dance): the actor is in the dance stance. Ends when hit, knocked
## Prone, or the actor commits to an attack / damaging skill.
var dancing: bool = false
## The Charm-effect bonus granted while dancing (per the dance level table).
var dance_charm: int = 0

# Grapple (R9)
var grappling: String = ""
var grappled_by: String = ""

## Bleed-out state (R5): {} or {"condition": String, "part": String}
var bleed_out: Dictionary = {}


static func from_spec(spec: Dictionary, static_data: Dictionary) -> CombatantState:
	var c := CombatantState.new()
	c.id = String(spec.get("id", ""))
	c.display_name = String(spec.get("name", c.id))
	c.team = String(spec.get("team", ""))
	var template: Dictionary = {}
	if spec.has("race"):
		template = _find_template(static_data.get("races", []), String(spec["race"]))
	elif spec.has("enemy"):
		template = _find_template(static_data.get("enemies", []), String(spec["enemy"]))
		c.category = String(template.get("category", "Mob"))
	c.category = String(spec.get("category", c.category))
	c.size = String(spec.get("size", template.get("size", "Medium")))
	var pos: Array = spec.get("position", [0, 0])
	c.position = Vector2i(int(pos[0]), int(pos[1]))

	var trait_spec: Dictionary = spec.get("traits", template.get("stat_block", {}))
	for key: String in TRAIT_KEYS:
		var value: Variant = trait_spec.get(key, 1)
		if value is Dictionary:
			var d: Dictionary = value
			c.stats[key] = {
				"base": int(d.get("base", 1)),
				"bonus": int(d.get("bonus", 0)),
				"level_bonus": int(d.get("level_bonus", 0)),
			}
		else:
			c.stats[key] = {"base": int(value), "bonus": 0, "level_bonus": 0}
	c.level_points = int(spec.get("level_points", 0))

	var res_spec: Dictionary = spec.get("resistances", template.get("resistances", {}))
	for res_key: String in ["Physical", "Affliction", "Psychic"]:
		c.resistances[res_key] = int(res_spec.get(res_key, 0))
	var racial: Dictionary = template.get("racial_traits", {})
	if racial.has("physical_resistance"):
		c.resistances["Physical"] += int(racial["physical_resistance"])
	var alloc: Dictionary = spec.get("allocated_physical_resistance", {})
	for alloc_key: Variant in alloc:
		c.allocated_physical[String(alloc_key)] = int(alloc[alloc_key])

	c.boss_traits = (spec.get("boss_traits", template.get("traits", {})) as Dictionary).duplicate(true)
	for ability_spec: Variant in spec.get("abilities", template.get("abilities", [])) as Array:
		c.abilities.append((ability_spec as Dictionary).duplicate(true))
	for phase_spec: Variant in spec.get("phases", template.get("phases", [])) as Array:
		c.boss_phases.append((phase_spec as Dictionary).duplicate(true))

	var hp_bonus: int = c.hp_bonus_per_part()
	var part_specs: Array = spec.get("body_parts", template.get("body_parts", []))
	for part_spec: Variant in part_specs:
		var p: Dictionary = part_spec
		var key := String(p.get("key", ""))
		var base_max := int(p.get("hp", 1))
		c.parts[key] = {
			"name": String(p.get("name", key)),
			"hp": base_max + hp_bonus,
			"base_max_hp": base_max,
			"lethal": bool(p.get("lethal", false)),
			"disabled": bool(p.get("disabled", false)),
			"destroyed": bool(p.get("destroyed", false)),
			"hidden": bool(p.get("hidden_until_breach", false)),
			# F2 rework: a bleed_immune part has no blood — bleeding never applies
			# and the systemic bleed-out drain skips it (the mycelium network).
			"bleed_immune": bool(p.get("bleed_immune", false)),
		}

	for item_spec: Variant in spec.get("items", []) as Array:
		var item: Dictionary = {}
		if item_spec is String:
			item = _find_template(static_data.get("items", []), String(item_spec)).duplicate(true)
		else:
			item = (item_spec as Dictionary).duplicate(true)
		var item_key := String(item.get("key", ""))
		if item_key == "":
			continue
		if item.has("magazine") and not item.has("magazine_loaded"):
			item["magazine_loaded"] = int(item["magazine"])
		c.items[item_key] = item

	for status_key: String in ["overwhelmed", "prone", "slowed"]:
		if bool(spec.get(status_key, false)):
			c.statuses[status_key] = true
	return c


static func _find_template(entries: Variant, key: String) -> Dictionary:
	for entry: Variant in entries as Array:
		var d: Dictionary = entry
		if String(d.get("key", "")) == key:
			return d
	return {}


func trait_total(trait_key: String) -> int:
	var t: Dictionary = stats.get(trait_key, {})
	return int(t.get("base", 0)) + int(t.get("bonus", 0)) + int(t.get("level_bonus", 0))


## Over-10 stat-cap formulas — adopted verbatim from the char-sheet app (R6).
static func over_cap(total: int, divisor: int) -> int:
	return int(floor(maxi(0, total - 10) / float(divisor)))


func hp_bonus_per_part() -> int:
	return over_cap(trait_total("physique"), 5)


func derived_stats() -> Dictionary:
	return {
		"hp_bonus_per_part": hp_bonus_per_part(),
		"physical_resistance_allocatable": over_cap(trait_total("reflexes"), 12),
		"psychic_resistance": over_cap(trait_total("mind"), 15),
		"camera_call_stacks": over_cap(trait_total("charm"), 20),
	}


func max_hp(part_key: String) -> int:
	var part: Dictionary = parts.get(part_key, {})
	return int(part.get("base_max_hp", 0)) + hp_bonus_per_part()


func condition_instance(part_key: String, condition_id: String) -> Dictionary:
	var on_part: Dictionary = conditions.get(part_key, {})
	return on_part.get(condition_id, {})


func condition_tier(part_key: String, condition_id: String) -> int:
	return int(condition_instance(part_key, condition_id).get("tier", 0))


func highest_tier_anywhere(condition_id: String) -> int:
	var highest: int = 0
	for part_key: Variant in conditions:
		highest = maxi(highest, condition_tier(String(part_key), condition_id))
	return highest


func part_usable(part_key: String, tick: int) -> bool:
	var part: Dictionary = parts.get(part_key, {})
	if part.is_empty() or bool(part["disabled"]) or bool(part["destroyed"]) or int(part["hp"]) <= 0:
		return false
	if int(part_locked_until.get(part_key, 0)) > tick:
		return false
	return true


## Hands = parts whose key contains "arm" or "hand" (human arms, enemy hands).
func usable_hands(tick: int) -> int:
	var count: int = 0
	var keys: Array = parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		if (key.contains("arm") or key.contains("hand")) and part_usable(key, tick):
			count += 1
	return count


## Deterministic "acting part" for an action: first usable hand, else first part.
func acting_part(tick: int) -> String:
	var keys: Array = parts.keys()
	keys.sort()
	for part_key: Variant in keys:
		var key := String(part_key)
		if (key.contains("arm") or key.contains("hand")) and part_usable(key, tick):
			return key
	if keys.is_empty():
		return ""
	return String(keys[0])


func is_helpless(tick: int) -> bool:
	return not bleed_out.is_empty() \
		or helpless_until_tick > tick \
		or statuses.get("incapacitated", false)


func can_act(tick: int) -> bool:
	return alive and not removed_from_play and not is_helpless(tick)


func size_rank() -> int:
	return int(SIZE_ORDER.get(size, 1))


## The Charm-effect bonus from the dance stance (self_stance) — 0 when not
## dancing. Charm-gated / spectacle consumers add this to the Charm read.
func dance_charm_bonus() -> int:
	return dance_charm if dancing else 0


## Axial hex distance — 1 space = 1 hex (R10/B8).
static func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var dq: int = a.x - b.x
	var dr: int = a.y - b.y
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2.0)


func reset_tick_flags() -> void:
	free_action_used = false
	reaction_used = false
	moved_this_tick = false
	damage_taken_this_tick = 0
	largest_single_hit_this_tick = 0
	combo_hits_this_tick.clear()


## Records a landed hit for single-hit breach checks (R15/NQ2). A combined
## action's linked strikes (same combo_id) accumulate into ONE merged hit — the
## party's designed path to a 7+ single-hit breach no lone attacker can clear.
func record_hit(combo_id: String, amount: int) -> void:
	if amount <= 0:
		return
	var hit: int = amount
	if combo_id != "":
		hit = int(combo_hits_this_tick.get(combo_id, 0)) + amount
		combo_hits_this_tick[combo_id] = hit
	largest_single_hit_this_tick = maxi(largest_single_hit_this_tick, hit)


func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"team": team,
		"category": category,
		"size": size,
		"position": [position.x, position.y],
		"parts": parts.duplicate(true),
		"conditions": conditions.duplicate(true),
		"timers": timers.duplicate(true),
		"shock": shock,
		"shocked_parts": shocked_parts.duplicate(true),
		"shock_stutter_pending": shock_stutter_pending,
		"stats": stats.duplicate(true),
		"level_points": level_points,
		"resistances": resistances.duplicate(true),
		"allocated_physical": allocated_physical.duplicate(true),
		"boss_traits": boss_traits.duplicate(true),
		"breached": breached,
		"abilities": abilities.duplicate(true),
		"boss_phases": boss_phases.duplicate(true),
		"items": items.duplicate(true),
		"alive": alive,
		"removed_from_play": removed_from_play,
		"next_action_tick": next_action_tick,
		"windup_pending": windup_pending,
		"free_action_used": free_action_used,
		"reaction_used": reaction_used,
		"moved_this_tick": moved_this_tick,
		"inventory_uses": inventory_uses,
		"took_scheduled_action_this_clock": took_scheduled_action_this_clock,
		"damage_taken_this_tick": damage_taken_this_tick,
		"largest_single_hit_this_tick": largest_single_hit_this_tick,
		"combo_hits_this_tick": combo_hits_this_tick.duplicate(true),
		"cooldowns": cooldowns.duplicate(true),
		"exposed_until_tick": exposed_until_tick,
		"helpless_until_tick": helpless_until_tick,
		"unarmed_until_tick": unarmed_until_tick,
		"strained_grip": strained_grip,
		"part_locked_until": part_locked_until.duplicate(true),
		"statuses": statuses.duplicate(true),
		"exposed_cache": exposed_cache,
		"brace_guard": brace_guard,
		"feint_forced": feint_forced,
		"dancing": dancing,
		"dance_charm": dance_charm,
		"grappling": grappling,
		"grappled_by": grappled_by,
		"bleed_out": bleed_out.duplicate(true),
	}


static func from_dict(data: Dictionary) -> CombatantState:
	var c := CombatantState.new()
	c.id = String(data.get("id", ""))
	c.display_name = String(data.get("display_name", ""))
	c.team = String(data.get("team", ""))
	c.category = String(data.get("category", "Contestant"))
	c.size = String(data.get("size", "Medium"))
	var pos: Array = data.get("position", [0, 0])
	c.position = Vector2i(int(pos[0]), int(pos[1]))
	c.parts = (data.get("parts", {}) as Dictionary).duplicate(true)
	c.conditions = (data.get("conditions", {}) as Dictionary).duplicate(true)
	for timer: Variant in data.get("timers", []) as Array:
		c.timers.append((timer as Dictionary).duplicate(true))
	c.shock = int(data.get("shock", 0))
	c.shocked_parts = (data.get("shocked_parts", {}) as Dictionary).duplicate(true)
	c.shock_stutter_pending = bool(data.get("shock_stutter_pending", false))
	c.stats = (data.get("stats", {}) as Dictionary).duplicate(true)
	c.level_points = int(data.get("level_points", 0))
	c.resistances = (data.get("resistances", {}) as Dictionary).duplicate(true)
	c.allocated_physical = (data.get("allocated_physical", {}) as Dictionary).duplicate(true)
	c.boss_traits = (data.get("boss_traits", {}) as Dictionary).duplicate(true)
	c.breached = bool(data.get("breached", false))
	for ability: Variant in data.get("abilities", []) as Array:
		c.abilities.append((ability as Dictionary).duplicate(true))
	for phase: Variant in data.get("boss_phases", []) as Array:
		c.boss_phases.append((phase as Dictionary).duplicate(true))
	c.items = (data.get("items", {}) as Dictionary).duplicate(true)
	c.alive = bool(data.get("alive", true))
	c.removed_from_play = bool(data.get("removed_from_play", false))
	c.next_action_tick = int(data.get("next_action_tick", 0))
	c.windup_pending = bool(data.get("windup_pending", false))
	c.free_action_used = bool(data.get("free_action_used", false))
	c.reaction_used = bool(data.get("reaction_used", false))
	c.moved_this_tick = bool(data.get("moved_this_tick", false))
	c.inventory_uses = int(data.get("inventory_uses", 0))
	c.took_scheduled_action_this_clock = bool(data.get("took_scheduled_action_this_clock", false))
	c.damage_taken_this_tick = int(data.get("damage_taken_this_tick", 0))
	c.largest_single_hit_this_tick = int(data.get("largest_single_hit_this_tick", 0))
	c.combo_hits_this_tick = (data.get("combo_hits_this_tick", {}) as Dictionary).duplicate(true)
	c.cooldowns = (data.get("cooldowns", {}) as Dictionary).duplicate(true)
	c.exposed_until_tick = int(data.get("exposed_until_tick", 0))
	c.helpless_until_tick = int(data.get("helpless_until_tick", 0))
	c.unarmed_until_tick = int(data.get("unarmed_until_tick", 0))
	c.strained_grip = bool(data.get("strained_grip", false))
	c.part_locked_until = (data.get("part_locked_until", {}) as Dictionary).duplicate(true)
	c.statuses = (data.get("statuses", {}) as Dictionary).duplicate(true)
	c.exposed_cache = bool(data.get("exposed_cache", false))
	c.brace_guard = int(data.get("brace_guard", 0))
	c.feint_forced = bool(data.get("feint_forced", false))
	c.dancing = bool(data.get("dancing", false))
	c.dance_charm = int(data.get("dance_charm", 0))
	c.grappling = String(data.get("grappling", ""))
	c.grappled_by = String(data.get("grappled_by", ""))
	c.bleed_out = (data.get("bleed_out", {}) as Dictionary).duplicate(true)
	return c
