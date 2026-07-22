extends SceneTree
## HEADLESS SLICE PLAYTEST DRIVER (KAN-3 bridge, pre-.tscn) — Cosmic Casino broadcast trace.
##
## Run:  godot --headless --path . -s scripts/slice_playtest.gd
##       (or: bash scripts/run_slice_playtest.sh)
##
## WHAT THIS IS
## A deterministic, headless *consumer* of the real sim. It drives a representative
## vertical-slice encounter — the two demo contestants vs the Incinedile tutorial
## boss — entirely through the real GameController (controller/game_controller.gd):
## GameController owns the CombatSim, funnels every command through apply_command(),
## and re-emits every sim event as the `sim_event` signal. This driver connects to
## that signal (proving the presentation wiring the .tscn HUD will use) and renders a
## readable "broadcast log" so the owner can FEEL the PLACEHOLDER (R14) numbers and so
## we can lock the exact data the combat HUD must display.
##
## HARD LINE: DRIVER/CONSUMER ONLY. It never touches simulation/, controller/, data/
## or tests/. If the encounter could not be driven without an engine change it would
## STOP and report — it never fakes the trace. Any command_rejected is surfaced
## loudly and fails the run (exit 2).
##
## DELIBERATE DRIVER CHOICES (all flagged in the trace + the run report), forced by
## the current engine surface, none of them engine edits:
##  * The boss is added with dodge_threshold STRIPPED from its boss_traits — exactly
##    as the engine's own breach/phase tests do (tests/test_incinedile.gd
##    traits_without_dodge()). The dodge d6 (unit-tested elsewhere) would otherwise
##    negate ~half of aimed rounds while the boss is not Exposed, making a scripted
##    breach non-deterministic. It is a driver-side spec choice, not a rules change.
##  * Dario is given Charm 30 so the R6 over-cap formula (Charm-10)/20 yields exactly
##    1 Camera Call stack. The demo loadout DECLARES camera_call_stacks:1 as a
##    "system-testing override", but add_combatant/CombatantState.from_spec has NO
##    path to grant Camera Call stacks directly — stacks derive ONLY from Charm.
##    (ENGINE GAP #1 — see the run report.)
##  * The boss acts on a CONTROLLED cadence (the driver decides when to ai_decide it)
##    rather than every tick — with the placeholder numbers a full-cadence boss TPKs
##    the party long before the network dies (TUNING GAP #4).
##  * SEED 14 is chosen because its first crowd-goal draw is OVERKILL (a completable
##    goal for this arc). The draw is a pure function of the seed.
##
## Determinism: fixed seed, no wall-clock reads, no RNG in the driver.

# --------------------------------------------------------------------- tunables
const SEED: int = 14

## All combat magnitudes below are PLACEHOLDER (R14) — the whole point of the trace
## is to let the owner FEEL them, not to bless them.
const POKE: int = 5          # cosmetic pre-breach chip damage to a visible part
## Each half of the combined breach hit. R15 MERGED FORCE (the R14 TODO, now
## implemented): the linked halves merge BEFORE the robustness gate — IMANI
## (phys 5) Force 6 + 2 = 8 and DARIO (phys 2) Force 6 + 1 = 7 merge to 15 −
## Robustness floor(6/2) = 3 → ONE 12-net hit ≥ 7, clearing the single-hit
## breach threshold. (Pre-merged-force these landed as separate 5- and 4-damage
## hits that summed to 9 only for the threshold.)
const BREACH_HALF: int = 6
const NET_HIT: int = 9       # damage per contestant into the exposed network

## GameController has no class_name (it is the `Game` autoload script) — preload it.
const GameControllerScript := preload("res://controller/game_controller.gd")

const IMANI := "imani"
const DARIO := "dario"
const BOSS := "boss"

## Loadout skill grants — verbatim (normalized key+level) from
## data/demo_loadouts.json (per-loadout skills are combatant STATE now; this
## trace declares plain attacks, so the grants are staging-only state here).
const IMANI_SKILLS := [
	{"key": "strong_strike", "level": 2},
	{"key": "overhead_slam", "level": 1},
	{"key": "brace", "level": 2},
]
const DARIO_SKILLS := [
	{"key": "feint", "level": 3},
	{"key": "pressure_strike", "level": 1},
	{"key": "dance", "level": 2},
]

# band -> owner-facing display name (owner maps cold/warm/hot/on_fire; hot/on_fire
# read on air as ELECTRIC / ON FIRE). Raw band kept in parens for the HUD contract.
const BAND_DISPLAY := {
	"cold": "COLD OPEN", "warm": "WARMING UP", "hot": "ELECTRIC", "on_fire": "ON FIRE",
}

# ------------------------------------------------------------------- run state
var gc                       # GameController (typed loosely)
var sink: Array = []         # every event delivered over the sim_event SIGNAL
var rejections: int = 0

# broadcast telemetry harvested for the FEEL READOUT
var peak_meter: int = 0
var peak_band: String = "cold"
var breach_tick: int = -1
var rebreaches: int = 0
var kill_tick: int = -1
var kill_cause: String = ""
var goals_completed: int = 0
var goals_offered: Array = []

var _persona := {}
var _patron := {}
var _charm_flag := {}


func _initialize() -> void:
	gc = GameControllerScript.new()
	gc.name = "SlicePlaytestController"
	# Prove the node wiring end-to-end: the controller lives under the scene root and
	# the trace is built from events delivered over its signals, exactly as the HUD
	# scene will consume them.
	root.add_child(gc)
	gc.sim_event.connect(_on_sim_event)
	gc.breach_opened.connect(_on_breach_typed)  # typed-signal wiring proof

	_banner_top()
	gc.start_combat(SEED)

	_add_boss()
	_add_contestant(IMANI, "Imani \"The Door\" Brandt", {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3},
		Vector2i(1, 0), "Hestia (hearth/protection/mercy)", -1,
		"heavy-rescue firefighter — the immovable veteran; when the Door opens, somebody gets carried out",
		{"skills": IMANI_SKILLS})
	# Dario carries his AUTHORED bit (decision log #25) verbatim from
	# demo_loadouts.json — every "bit" command in this arc is his. Imani has NO
	# bit (canonical — zero camera interest); the sim would reject one from her.
	# Both carry their loadout SKILL grants (keys + levels).
	_add_contestant(DARIO, "Dario \"Encore\" Vekic", {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5},
		Vector2i(0, 1), "Enyo (war/carnage)", 30,
		"boardwalk sleight-of-hand hustler — the heel you pay to boo; steals finishers, bows after every kill",
		{"bit": {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."},
		"skills": DARIO_SKILLS})
	sink.clear()  # discard setup events; roster is rendered from the view API below

	_print_roster()
	_print_win_condition()

	# ------------------------------------------------------------------ the fight
	_clock1()
	_clock_boundary()
	_clock2()

	_verdict()
	quit(2 if rejections > 0 else 0)


# =====================================================================  SETUP
func _add_boss() -> void:
	# Strip dodge_threshold from the seeded Incinedile traits (see header). We read
	# the enemy template the same way the tests do — a consumer reading data/*.json.
	var boss_traits: Dictionary = {}
	var enemies: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	for entry: Variant in enemies as Array:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			boss_traits = (e.get("traits", {}) as Dictionary).duplicate(true)
	boss_traits.erase("dodge_threshold")
	boss_traits.erase("dodge_threshold_note")
	gc.apply_command({"type": "add_combatant", "combatant": {
		"id": BOSS, "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": boss_traits,
	}})


func _add_contestant(id: String, cname: String, traits: Dictionary, pos: Vector2i,
		patron: String, charm_override: int, persona: String, extra: Dictionary = {}) -> void:
	# race id 1 in demo_loadouts.json maps to the "human" template key.
	var combatant: Dictionary = {
		"id": id, "name": cname, "race": "human", "team": "party",
		"position": [pos.x, pos.y], "traits": traits, "camera_call_stacks": 1,
	}
	combatant.merge(extra, true)
	gc.apply_command({"type": "add_combatant", "combatant": combatant})
	_persona[id] = persona
	_patron[id] = patron
	_charm_flag[id] = charm_override


# =====================================================================  RENDER
func _on_sim_event(e: Dictionary) -> void:
	sink.append(e)

func _on_breach_typed(_e: Dictionary) -> void:
	pass  # the sim_event stream already carries breach_opened; the typed conn proves wiring


## Apply one command; return only the events it produced (sliced off the signal sink).
func _cmd(c: Dictionary) -> Array:
	var start: int = sink.size()
	gc.apply_command(c)
	return sink.slice(start)


func _stamp(tick: int) -> String:
	return "C%d M%02d" % [int(tick / 10) + 1, 10 - (tick % 10)]


func _boss_alive() -> bool:
	var b = gc.sim.combatants.get(BOSS)
	return b != null and bool(b.alive)

func _boss_breached() -> bool:
	var b = gc.sim.combatants.get(BOSS)
	return b != null and bool(b.breached)


## Renders one beat: a headline, indented callouts for the meaningful events, then
## the live broadcast HUD line.
func _beat(tick: int, headline: String, events: Array) -> void:
	print("  %s | %s" % [_stamp(tick), headline])
	for e: Dictionary in events:
		var line: String = _fmt(e, tick)
		if line != "":
			print("            %s" % line)
	var hud: String = _hud()
	if hud != "":
		print("            -> %s" % hud)


func _hud() -> String:
	var h = gc.sim.hype
	if int(h.meter) > peak_meter:
		peak_meter = int(h.meter)
		peak_band = String(h.band)
	var bd: String = String(BAND_DISPLAY.get(String(h.band), String(h.band)))
	var s: String = "AUDIENCE  hype %d  [%s (%s)]" % [int(h.meter), bd, String(h.band)]
	var goal: Dictionary = h.active_goal
	if not goal.is_empty():
		s += "   GOAL \"%s\" [%s, pays %d, %d clk left]" % [String(goal.get("name", "")),
			String(goal.get("kind", "")), int(goal.get("payout", 0)), int(goal.get("clocks_left", 0))]
	var spot: Dictionary = h.spotlight
	if not spot.is_empty():
		s += "   SPOTLIGHT->%s" % _who(spot.get("target", ""))
	return s


## Formats a single event into a broadcast callout, or "" to suppress structural noise.
func _fmt(e: Dictionary, tick: int) -> String:
	var ty: String = String(e.get("type", ""))
	match ty:
		"command_rejected":
			rejections += 1
			return "[!!] COMMAND REJECTED: %s  %s" % [String(e.get("reason", "?")), JSON.stringify(e)]
		"action_declared":
			if bool(e.get("windup", false)):
				return "[wind-up] %s commits %s (cost %d, resolves tick %d) — EXPOSED while committed" % [
					_who(e.get("actor")), String(e.get("kind", "")), int(e.get("cost", 0)), int(e.get("resolve_tick", 0))]
			return ""  # instant declarations are terse — the resolution line carries them
		"ai_decision":
			if String(e.get("choice", "")) == "wait":
				return "[BOSS AI] holds — \"%s\"" % String(e.get("reason", ""))
			return "[BOSS AI %s] %s -> %s  (target %s)" % [String(e.get("tier", "")),
				String(e.get("choice", "")), String(e.get("ability", "")), _who(e.get("target"))]
		"damage_applied":
			if int(e.get("amount", 0)) <= 0:
				return ""
			return "%s takes %d to %s     [network HP now %s]" % [_who(e.get("combatant")),
				int(e.get("amount", 0)), String(e.get("part", "")), _net_hp()]
		"healed":
			return "  . %s heals %d on %s (%s)" % [_who(e.get("combatant")), int(e.get("amount", 0)),
				String(e.get("part", "")), String(e.get("source", ""))]
		"condition_applied":
			return "  . %s: %s T%d on %s" % [_who(e.get("combatant")), String(e.get("condition", "")),
				int(e.get("tier", 0)), String(e.get("part", ""))]
		"condition_advanced":
			return "  . %s: %s T%d->T%d on %s (%s)" % [_who(e.get("combatant")), String(e.get("condition", "")),
				int(e.get("from_tier", 0)), int(e.get("to_tier", 0)), String(e.get("part", "")), String(e.get("reason", ""))]
		"condition_resolved":
			return "  . %s: %s cleared on %s (%s)" % [_who(e.get("combatant")), String(e.get("condition", "")),
				String(e.get("part", "")), String(e.get("reason", ""))]
		"part_disabled":
			return "  . %s.%s DISABLED" % [_who(e.get("combatant")), String(e.get("part", ""))]
		"part_destroyed":
			return "  . %s.%s DESTROYED" % [_who(e.get("combatant")), String(e.get("part", ""))]
		"moved":
			return "%s repositions -> %s (%d spaces)" % [_who(e.get("actor")), str(e.get("to", [])), int(e.get("spaces", 0))]
		"combined_action_declared":
			var names: Array = []
			for m: Variant in e.get("members", []):
				names.append(_who(m))
			return "[COMBO] %s link up (linked strikes MERGE FORCE into one gate + one hit, R15)" % " + ".join(names)
		"combined_force":
			var actors: Array = []
			for a: Variant in e.get("actors", []):
				actors.append(_who(a))
			return "[MERGED FORCE] %s: force %d vs robustness %d = ONE %d-net hit on %s" % [
				" + ".join(actors), int(e.get("force", 0)), int(e.get("robustness", 0)),
				int(e.get("net", 0)), String(e.get("part", ""))]
		"combo_assist_applied":
			return "  . assist covers %s's requirement (teamwork UNLOCKS the hit)" % _who(e.get("actor"))
		"breach_opened":
			if breach_tick < 0:
				breach_tick = tick
			else:
				rebreaches += 1
			return "*** BREACH DISCOVERED *** the mycelium NETWORK is exposed and attackable  (^)"
		"breach_reset":
			return "[PRESSURE VALVE] the network retreats deeper on %s — breach RESETS (wounds persist)" % String(e.get("part", ""))
		"boss_phase_changed":
			return ">>> BOSS PHASE %d -> %d : \"%s\"" % [int(e.get("from_phase", 0)),
				int(e.get("to_phase", 0)), String(e.get("name", ""))]
		"combatant_died":
			if String(e.get("combatant", "")) == BOSS:
				kill_tick = tick
				kill_cause = String(e.get("cause", ""))
			return "[DOWN] %s IS DESTROYED  (cause: %s)" % [_who(e.get("combatant")), String(e.get("cause", ""))]
		"bleed_out_started":
			return "  . %s bleeding out on %s" % [_who(e.get("combatant")), String(e.get("part", ""))]
		"forced_action_triggered":
			return "[FORCED ACTION %s] %s rolls %d -> %s" % [String(e.get("table", "")),
				_who(e.get("actor")), int(e.get("roll", 0)), String(e.get("consequence", ""))]
		"bit_performed":
			# decision log #25: the event names WHICH authored bit was performed.
			return "[THE BIT] %s performs \"%s\" (mechanically NULL) — +%d spectacle" % [
				_who(e.get("actor")), String(e.get("bit_name", "the bit")),
				int(e.get("spectacle_points", 0))]
		"hype_camera_call_started":
			return "[CAMERA CALL] %s grabs the spotlight on %s (%d stacks left) — swings now DOUBLED" % [
				_who(e.get("actor")), _who(e.get("target")), int(e.get("stacks_remaining", 0))]
		"hype_spotlight_ended":
			return "  . spotlight off %s (%s)" % [_who(e.get("target")), String(e.get("reason", ""))]
		"hype_goal_offered":
			goals_offered.append(String(e.get("name", "")))
			return "[CROWD GOAL] OFFERED: \"%s\" [%s] — pays %d, %d clocks (draw idx %d)" % [
				String(e.get("name", "")), String(e.get("kind", "")), int(e.get("payout", 0)),
				int(e.get("deadline_clocks", 0)), int(e.get("roll", 0))]
		"hype_goal_completed":
			goals_completed += 1
			return "[CROWD GOAL] *** COMPLETE: %s by %s  (+%d spectacle) ***" % [
				String(e.get("goal", "")), _who(e.get("completed_by")), int(e.get("spectacle_points", 0))]
		"hype_goal_expired":
			return "  . crowd goal %s expired" % String(e.get("goal", ""))
		"hype_spike":
			return "[HYPE SPIKE]  +%d  (meter now %d)" % [int(e.get("spectacle_points", 0)), int(e.get("meter", 0))]
		"hype_band_changed":
			var to_b: String = String(e.get("to_band", ""))
			return "[BAND] %s -> %s  [%s]" % [String(e.get("from_band", "")), to_b, String(BAND_DISPLAY.get(to_b, to_b))]
		"tag_progressed":
			return "  . %s tag \"%s\" progress %d/%d" % [_who(e.get("combatant")),
				String(e.get("tag", "")), int(e.get("count", 0)), int(e.get("threshold", 0))]
		"tag_acquired":
			return "[TAG EARNED] %s -> \"%s\"" % [_who(e.get("combatant")), String(e.get("tag", ""))]
		"tag_reinforced":
			return "  . %s reinforces \"%s\" (x%d)" % [_who(e.get("combatant")), String(e.get("tag", "")), int(e.get("count", 0))]
		"shock_changed":
			return "  . %s SHOCK T%d->T%d" % [_who(e.get("combatant")), int(e.get("from_tier", 0)), int(e.get("to_tier", 0))]
	return ""  # structural (clock_moment_changed, exposed_state_changed, action_resolved ok, etc.)


func _who(id: Variant) -> String:
	match String(id):
		IMANI: return "IMANI"
		DARIO: return "DARIO"
		BOSS: return "INCINEDILE"
	return String(id)


func _net_hp() -> String:
	var b = gc.sim.combatants.get(BOSS)
	if b == null:
		return "-"
	var net: Dictionary = b.parts.get("network", {})
	var tier: int = int(b.condition_tier("network", "crushed"))
	var hidden: String = "  (HIDDEN)" if bool(net.get("hidden", false)) else ""
	return "%d/%d, crushed T%d%s" % [int(net.get("hp", 0)), int(net.get("base_max_hp", 0)), tier, hidden]


# =====================================================================  COMMANDS
func _attack(actor: String, part: String, dtype: String, amount: int) -> Dictionary:
	return {"type": "declare_action", "actor": actor, "action": {
		"kind": "attack", "cost": 1, "attack_range": 2,
		"damage": {"type": dtype, "amount": amount},
		"targets": [{"id": BOSS, "part": part}],
	}}


func _combo(part: String) -> Dictionary:
	return {"type": "combined_action", "members": [
		{"actor": IMANI, "action": _attack(IMANI, part, "crushed", BREACH_HALF)["action"]},
		{"actor": DARIO, "action": _attack(DARIO, part, "crushed", BREACH_HALF)["action"]},
	]}


func _adv(tick: int, headline: String) -> void:
	# advance one tick; the returned events are the resolutions that fired ON `tick`.
	_beat(tick, headline, _cmd({"type": "advance_tick"}))


# =====================================================================  ARC
func _clock1() -> void:
	print("")
	print("=".repeat(80))
	print("  CLOCK 1  —  \"the cold open\": gates slam, the caged band screams God Shattering Star")
	print("=".repeat(80))

	# M10 (t0): the boss reads the crowd; the party chips two visible plates (cosmetic).
	_beat(0, "GATES CLOSE. The boss squares up — both contestants stand in the flamethrower cone.",
		_cmd({"type": "ai_decide", "actor": BOSS}))
	_beat(0, "IMANI cracks a leg plate; DARIO chips the other (pre-breach = cosmetic damage).",
		_cmd(_attack(IMANI, "left_leg", "crushed", POKE)) + _cmd(_attack(DARIO, "right_leg", "crushed", POKE)))
	_adv(0, "-- resolve M10 --")

	# M9 (t1): Dario works the crowd under a self-Camera-Call.
	_beat(1, "DARIO calls the camera onto himself, then drops the Bit while the lens is hot.",
		_cmd({"type": "camera_call", "actor": DARIO, "target": DARIO})
		+ _cmd({"type": "bit", "actor": DARIO, "key": "encore_bow"}))
	_adv(1, "-- resolve M9 --")

	# M8 (t2): the Bit escalates (still spotlit -> doubled -> spike).
	_beat(2, "DARIO does the Bit AGAIN — escalating spectacle, still DOUBLED by his own spotlight.",
		_cmd({"type": "bit", "actor": DARIO, "key": "encore_bow"}))
	_adv(2, "-- resolve M8: the FLAMETHROWER lands (the boss's one big retaliation) --")

	# M7 (t3): field medic — treat the burns off before the Clock-reset escalation.
	_beat(3, "The party patches up: IMANI & DARIO treat the burns before the reset can escalate them.",
		_cmd({"type": "treat", "target": IMANI, "part": "torso", "condition": "burn", "mode": "resolve"})
		+ _cmd({"type": "treat", "target": DARIO, "part": "torso", "condition": "burn", "mode": "resolve"}))
	_adv(3, "-- resolve M7 --")

	# M6 (t4): THE DISCOVERY — the linked strikes MERGE FORCE into a 7+ hit -> breach.
	_beat(4, "IMANI + DARIO time a COMBINED strike on the flamethrower arm — the party's designed path in.",
		_cmd(_combo("left_hand")))
	_adv(4, "-- resolve M6: merged force 8+7 = 15 − 3 = one 12-net hit --")

	# M5 (t5): the escalating Bit tops out.
	_beat(5, "DARIO milks the reveal — third Bit of the run.",
		_cmd({"type": "bit", "actor": DARIO, "key": "encore_bow"}))
	_adv(5, "-- resolve M5 --")

	# M4-M2 (t6-t8): downtime — the core sits exposed while the crowd simmers.
	_beat(6, "Commentary break: the exposed core pulses; IMANI keeps a plate under pressure.",
		_cmd(_attack(IMANI, "right_hand", "crushed", POKE)))
	_adv(6, "-- resolve M4 --")
	_beat(7, "The band vamps. The director eyes the reorganization beat.", [])
	_adv(7, "-- resolve M3 --")
	_beat(8, "Contestants reset their footing; the crowd wants a demand.", [])
	_adv(8, "-- resolve M2 --")

	# M1 (t9): nothing declared; the reorganization beat lands on the advance.
	_beat(9, "Floor reorganizes on the next tick.", [])


func _clock_boundary() -> void:
	# Advancing OFF Moment 1 completes the Clock: decay + the first crowd-goal offer.
	_adv(9, "-- CLOCK 1 COMPLETES: reorganization beat (hype decays, a crowd goal is offered) --")


func _clock2() -> void:
	print("")
	print("=".repeat(80))
	print("  CLOCK 2  —  \"the finish\": crack the core, ride the valve, end it on camera")
	print("=".repeat(80))

	# M10 (t10): first blows into the exposed core -> completes OVERKILL, trips the valve.
	_beat(10, "Core's open! DARIO buries a stage knife for the crowd; IMANI follows.",
		_cmd(_attack(DARIO, "network", "crushed", NET_HIT)) + _cmd(_attack(IMANI, "network", "crushed", NET_HIT)))
	_adv(10, "-- resolve M10: network crosses the 35 threshold --")

	# M9 (t11): the boss tries to erupt (now phase 2 = v1 stub); the party re-discovers the breach.
	_beat(11, "The boss should ERUPT here (Pressure Valve I). The AI reaches the explosion phase and idles.",
		_cmd({"type": "ai_decide", "actor": BOSS}))
	if not _boss_breached() and _boss_alive():
		_beat(11, "Core re-hid — IMANI + DARIO COMBINE again to re-open it (Formation locks in).",
			_cmd(_combo("right_hand")))
		_adv(11, "-- resolve M9: re-breach --")

	# M8 onward: grind the exposed core until the puppet drops. The breached-check makes
	# this robust to the exact valve timing; a safety cap guards against a runaway.
	var safety: int = 0
	while _boss_alive() and safety < 8:
		safety += 1
		var tick: int = int(gc.view_clock()["tick"])
		if not _boss_breached():
			_beat(tick, "Core slipped away again — re-open it.", _cmd(_combo("right_hand")))
		else:
			_beat(tick, "Both contestants pour into the mycelium core.",
				_cmd(_attack(DARIO, "network", "crushed", NET_HIT)) + _cmd(_attack(IMANI, "network", "crushed", NET_HIT)))
		_adv(tick, "-- resolve --")


# =====================================================================  FRAMES
func _banner_top() -> void:
	print("")
	print("#".repeat(80))
	print("#  GALACTIC PRIME TIME — HEADLESS SLICE PLAYTEST (broadcast trace)")
	print("#  Cosmic Casino, VIP table: a 'human pop-culture' themed dungeon crawl")
	print("#  driven through GameController.apply_command / sim_event  ·  seed %d" % SEED)
	print("#  ALL numbers below are PLACEHOLDER (R14) — this trace exists to FEEL them.")
	print("#".repeat(80))


func _print_roster() -> void:
	print("")
	print("-".repeat(80))
	print("  TONIGHT'S TABLE  (rendered from GameController.view_combatants())")
	print("-".repeat(80))
	for c: Dictionary in gc.view_combatants():
		var id: String = String(c.get("id", ""))
		var role: String = "BOSS" if id == BOSS else "CONTESTANT"
		print("  [%s] %s  @%s" % [role, String(c.get("name", "")), str(c.get("position", []))])
		if _persona.has(id):
			print("        persona: %s" % _persona[id])
		if _patron.has(id):
			print("        patron god: %s" % _patron[id])
		if int(_charm_flag.get(id, -1)) >= 0:
			print("        [FLAG] Charm %d = driver override to realize the loadout's declared" % int(_charm_flag[id]))
			print("               camera_call_stacks:1 (sim derives stacks from Charm only) — ENGINE GAP #1.")
		var seg: Array = []
		for p: Variant in c.get("parts", []):
			var pd: Dictionary = p
			seg.append("%s %d/%d%s" % [String(pd.get("key", "")), int(pd.get("hp", 0)),
				int(pd.get("max_hp", 0)), ("*" if bool(pd.get("lethal", false)) else "")])
		print("        parts: %s" % ", ".join(seg))
	print("        (* = lethal part)  NB: view_combatants() does NOT expose the hidden/")
	print("        breach state of a part (ENGINE GAP #2) — the network shows as a normal part.")


func _print_win_condition() -> void:
	# The win-condition detail lives on the RAW model, not in view_combatants() (GAP #2).
	var b = gc.sim.combatants.get(BOSS)
	var net: Dictionary = b.parts.get("network", {})
	print("")
	print("  >>> HIDDEN WIN CONDITION <<<")
	print("      The Incinedile is a MYCELIUM PUPPET. Pre-breach damage to any VISIBLE part is")
	print("      cosmetic. The real kill is the hidden NETWORK part (hp %d, lethal, hidden=%s)."
		% [int(net.get("hp", 0)), str(net.get("hidden", false))])
	print("      Discover the breach: bleeding->T2 anywhere, OR one single burst hit >= 7.")
	print("      Only then is the network attackable; destroy it to win.")


func _verdict() -> void:
	var boss_dead: bool = not _boss_alive()
	print("")
	print("=".repeat(80))
	print("  [TV]  BROADCAST VERDICT")
	print("=".repeat(80))
	if boss_dead:
		print("  RESULT: WIN — the network was DESTROYED. The puppet is dead; the table pays out.")
	else:
		print("  RESULT: NO KILL — the boss survived the scripted arc (see the blockers below).")
	var h = gc.sim.hype
	print("  Final audience : hype %d  [%s (%s)]" % [int(h.meter),
		String(BAND_DISPLAY.get(String(h.band), String(h.band))), String(h.band)])

	# MVP = highest lifetime spectacle credited in the hype ledger, AMONG CONTESTANTS.
	# (Attribution v1 credits the victim, so the boss tops the raw ledger — a known
	# HypeEngine limitation, PROVISIONAL R11 #14; we filter to contestants here.)
	var mvp_id: String = ""
	var mvp_pts: int = -1
	for cid: String in [IMANI, DARIO]:
		var pts: int = int(h.ledger.get(cid, 0))
		if pts > mvp_pts:
			mvp_pts = pts
			mvp_id = cid
	print("  MVP (contestant): %s with %d spectacle credited" % [_who(mvp_id), mvp_pts])
	print("  Tags earned:")
	for cid: String in [IMANI, DARIO]:
		var held: Dictionary = gc.sim.tags.held.get(cid, {})
		var prog: Dictionary = gc.sim.tags.progress.get(cid, {})
		var held_keys: Array = held.keys(); held_keys.sort()
		var prog_bits: Array = []
		var pk: Array = prog.keys(); pk.sort()
		for k: Variant in pk:
			if not held.has(k):
				prog_bits.append("%s(%d)" % [String(k), int(prog[k])])
		print("      %-11s EARNED: %s  |  progressing: %s" % [_who(cid),
			(", ".join(held_keys) if not held_keys.is_empty() else "(none)"),
			(", ".join(prog_bits) if not prog_bits.is_empty() else "(none)")])

	# The evidence record (view_verdict projection — what the verdict card quotes).
	print("  Evidence record:")
	for cid: String in [IMANI, DARIO]:
		var lines: Array = []
		for e: Variant in gc.view_verdict(cid).get("evidence", []):
			lines.append((e as Dictionary).get("line", ""))
		print("      %-11s %s" % [_who(cid), ("(no logged deeds)" if lines.is_empty() else "")])
		for line: Variant in lines:
			print("          - %s" % String(line))

	var last_tick: int = kill_tick if kill_tick >= 0 else int(gc.view_clock()["tick"])
	print("")
	print("  ---- FEEL READOUT (the pacing numbers to judge) ----")
	print("      Moments to FIRST breach : %s" % _ms(breach_tick))
	print("      Moments to KILL         : %s" % _ms(kill_tick))
	print("      Kill mechanism          : %s" % (kill_cause if kill_cause != "" else "n/a"))
	print("      Breach re-discoveries   : %d (one per pressure valve)" % rebreaches)
	print("      Peak hype / band        : %d  [%s (%s)]" % [peak_meter,
		String(BAND_DISPLAY.get(peak_band, peak_band)), peak_band])
	print("      Crowd goals offered     : %d  %s" % [goals_offered.size(), str(goals_offered)])
	print("      Crowd goals completed   : %d" % goals_completed)
	print("      Total Moments elapsed   : %d  (%.1f Clocks)" % [last_tick + 1, float(last_tick + 1) / 10.0])

	print("")
	print("  ---- FINDINGS THIS RUN SURFACED (for the HUD spec + the numbers rework) ----")
	if boss_dead and kill_cause.begins_with("crushed"):
		print("      * The network died by CONDITION TIER (%s), not by emptying its HP pool." % kill_cause)
		print("        With the small placeholder hits, crushed reaches a lethal tier (T3 lethal_if_vital)")
		print("        in ~3 same-part hits — long before 50 HP is gone. HP is NOT the TTK driver;")
		print("        condition tier is. The HUD should show boss health as TIER, not just an HP bar.")
	print("      * Condition stacking BYPASSES surface immunity: any visible part driven to")
	print("        crushed/bleeding T4 = death (or T3 lethal_if_vital on a lethal part). The")
	print("        'discoverable win condition' is defeatable without ever breaching. (BALANCE)")
	print("      * The boss ran on a controlled cadence; a full-cadence phase-1 boss would TPK")
	print("        the party before the network dies with these numbers. (TUNING)")
	print("      * view_combatants() exposes no hype meter/band/goal/tags and no part hidden")
	print("        state — the HUD needs a broadcast/boss view projection. (GAPS #2/#3)")

	if rejections > 0:
		print("")
		print("  !! %d COMMAND(S) WERE REJECTED — the scripted arc is not clean (exit 2)." % rejections)
	print("=".repeat(80))


func _ms(tick: int) -> String:
	if tick < 0:
		return "n/a"
	return "%d Moments  (at %s, tick %d)" % [tick + 1, _stamp(tick), tick]
