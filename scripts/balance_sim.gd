extends SceneTree
## HEADLESS BALANCE HARNESS (R14 tuning) — full-cadence measurement instrument.
##
## Run:  godot --headless --path . -s scripts/balance_sim.gd
##
## WHAT THIS IS
## The measurement instrument for the R14 combat-numbers tuning pass. Unlike
## scripts/slice_playtest.gd (a *scripted broadcast trace* that throttles the boss
## to a controlled cadence so the arc reads cleanly), this driver stands up the SAME
## real slice encounter — the Incine-Dile tutorial boss + the two demo contestants,
## entirely through the real GameController — and runs the boss at FULL CADENCE: every
## tick the boss is eligible it `ai_decide`s (via GameController.run_enemy_turn()),
## exactly like a live fight. The party follows a FIXED, reasonable strategy: open the
## hidden network via the designed breach (a combined burst hit >= 7), then focus the
## exposed network until it dies — re-breaching after each pressure-valve reset. Since
## the explosion beats went REAL (decision #27) the strategy also plays the intended
## valve counterplay: on the steam telegraph both contestants RUN out of the blast
## radius until the boom, then walk back in; and a burning torso gets treated before
## the Clock reset can escalate it (the boss actually fights past Valve I now).
##
## It answers with numbers, not vibes: at full boss cadence, do the magnitudes one-shot
## a contestant / TPK the party, and after tuning do they produce a winnable, no-one-shot
## fight with margin? It prints:
##  * a PROBE line — the boss's WORST-CASE single hit (dash on a lone contestant, cone on
##    a crowd) against fresh torsos of each physique. This is the clean one-shot metric,
##    independent of party pace: a "died=" true here is a from-full-to-0 one-shot.
##  * a BALANCE line — the machine-greppable outcome of the full-cadence fight.
##
## HARD LINE: DRIVER/CONSUMER ONLY — it never touches simulation/, controller/, data/
## or tests/. Determinism: fixed seeds, no wall-clock reads, no RNG in the driver (the
## boss is added with dodge_threshold stripped — the same spec choice the engine's own
## breach/phase tests make — so the AI d6 never makes a measurement non-deterministic).

# --------------------------------------------------------------------- tunables
const SEED: int = 14
const PROBE_SEED: int = 9
const TICK_CAP: int = 120       # hard stop -> TIMEOUT (a balanced fight ends well before)

## The party's fixed, reasonable attack magnitudes (contestant weapon/skill force).
## BREACH_HALF: each half of the combined burst strike onto a visible plate — the two
## halves MERGE into one hit for the single-hit breach threshold (>= 7). NET_HIT: a
## single crushed strike into the exposed network; sized so the party crosses a
## pressure-valve threshold (network 50->35) and must RE-BREACH — proving the breach
## gate holds — before finishing the core (F2).
const BREACH_HALF: int = 6
const NET_HIT: int = 6

const GameControllerScript := preload("res://controller/game_controller.gd")

const IMANI := "imani"
const DARIO := "dario"
const BOSS := "boss"

# ------------------------------------------------------------------- run state
var gc
var sink: Array = []

# fight metrics
var breach_tick: int = -1
var network_kill_tick: int = -1
var first_down_tick: int = -1
var max_hit_on_contestant: int = 0
var rebreaches: int = 0
var outcome: String = "TIMEOUT"
# valve-beat state + metrics (decision #27)
var fleeing: bool = false        # steam telegraph seen, blast not yet
var blast_at: int = 0            # announced blast tick (telegraph tick + countdown)
var blasts: int = 0
var knockouts: int = 0           # contestants caught by a blast


func _initialize() -> void:
	_probe()          # worst-case single-hit measurement (the one-shot metric)
	_full_cadence()   # the full-cadence fight to a decision
	quit(0)


# =====================================================================  PROBE
## Fresh, isolated micro-scenarios: what is the boss's biggest SINGLE hit on a fresh
## contestant torso (5 HP)? Dash fires against a LONE target; the cone against a crowd.
## A `died` here means the hit took a fresh lethal part from full to 0 — a one-shot.
func _probe() -> void:
	var out: Array = []
	for phys: int in [2, 3, 5]:
		var d: Dictionary = _one_hit("dash", phys, false)
		out.append("dash@phys%d=%d%s" % [phys, int(d["net"]), ("(ONE-SHOT)" if bool(d["died"]) else "")])
	for phys: int in [2, 5]:
		var f: Dictionary = _one_hit("flamethrower", phys, true)
		out.append("cone@phys%d=%d%s" % [phys, int(f["net"]), ("(ONE-SHOT)" if bool(f["died"]) else "")])
	print("PROBE fresh-torso=5  %s" % " ".join(out))


## Stand up boss + one (or, for the cone, two) fresh phys-`phys` contestants, let the
## boss decide+resolve once, and return {net, died} for the first contestant's torso.
func _one_hit(_ability: String, phys: int, crowd: bool) -> Dictionary:
	var g = GameControllerScript.new()
	g.name = "Probe"
	root.add_child(g)
	g.start_combat(PROBE_SEED)
	_add_boss_to(g)
	_add_contestant_to(g, "p", {"physique": phys, "reflexes": 3, "mind": 3, "charm": 3}, Vector2i(1, 0))
	if crowd:
		_add_contestant_to(g, "q", {"physique": phys, "reflexes": 3, "mind": 3, "charm": 3}, Vector2i(0, 1))
	var net: int = 0
	var died: bool = false
	var seen: Array = []
	g.sim_event.connect(func(e: Dictionary) -> void: seen.append(e))
	g.run_enemy_turn()
	# resolve enough ticks for a 2-Moment windup (cone) to land
	for _i: int in range(3):
		g.apply_command({"type": "advance_tick"})
	for e: Dictionary in seen:
		if String(e.get("type", "")) == "damage_applied" and String(e.get("combatant", "")) == "p":
			net = maxi(net, int(e.get("amount", 0)))
		if String(e.get("type", "")) == "combatant_died" and String(e.get("combatant", "")) == "p":
			died = true
	g.free()
	return {"net": net, "died": died}


# =====================================================================  FIGHT
func _full_cadence() -> void:
	gc = GameControllerScript.new()
	gc.name = "BalanceHarness"
	root.add_child(gc)
	gc.sim_event.connect(_on_sim_event)
	gc.start_combat(SEED)
	_add_boss_to(gc)
	# Imani "The Door" (heavy physique) and Dario "Encore" (low physique — the one-shot
	# canary: his phys-2 torso has the lowest Robustness on the table).
	_add_contestant_to(gc, IMANI, {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, Vector2i(1, 0))
	_add_contestant_to(gc, DARIO, {"physique": 2, "reflexes": 5, "mind": 2, "charm": 3}, Vector2i(0, 1))
	sink.clear()

	var tick: int = 0
	while tick < TICK_CAP:
		_party_turn()                                  # 1) party: breach, then focus network
		gc.run_enemy_turn()                            # 2) boss: FULL cadence, every eligible tick
		gc.apply_command({"type": "advance_tick"})     # 3) resolve the tick
		var status: Dictionary = gc.combat_status()    # 4) decision?
		if bool(status.get("over", false)):
			outcome = "WIN" if String(status.get("outcome", "")) == "WIN" else "TPK"
			break
		tick = int(gc.view_clock()["tick"])

	_report()


# =====================================================================  SETUP
func _add_boss_to(g) -> void:
	var boss_traits: Dictionary = {}
	var enemies: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	for entry: Variant in enemies as Array:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			boss_traits = (e.get("traits", {}) as Dictionary).duplicate(true)
	boss_traits.erase("dodge_threshold")
	boss_traits.erase("dodge_threshold_note")
	g.apply_command({"type": "add_combatant", "combatant": {
		"id": BOSS, "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": boss_traits,
	}})


func _add_contestant_to(g, id: String, traits: Dictionary, pos: Vector2i) -> void:
	g.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "race": "human", "team": "party",
		"position": [pos.x, pos.y], "traits": traits,
	}})


# =====================================================================  EVENTS
func _on_sim_event(e: Dictionary) -> void:
	sink.append(e)
	var ty: String = String(e.get("type", ""))
	var tk: int = int(e.get("tick", int(gc.view_clock().get("tick", 0))))
	match ty:
		"damage_applied":
			var who: String = String(e.get("combatant", ""))
			if who == IMANI or who == DARIO:
				max_hit_on_contestant = maxi(max_hit_on_contestant, int(e.get("amount", 0)))
		"explosion_telegraph":
			fleeing = true  # the steam is the cue
			blast_at = tk + int(e.get("moments_until_blast", 0))
		"explosion_blast":
			fleeing = false
			blasts += 1
		"explosion_knockout":
			var kid: String = String(e.get("combatant", ""))
			if kid == IMANI or kid == DARIO:
				knockouts += 1
		"breach_opened":
			if breach_tick < 0:
				breach_tick = tk
			else:
				rebreaches += 1
		"combatant_died":
			var cid: String = String(e.get("combatant", ""))
			if cid == BOSS:
				if network_kill_tick < 0:
					network_kill_tick = tk
			elif (cid == IMANI or cid == DARIO) and first_down_tick < 0:
				first_down_tick = tk


# =====================================================================  PARTY
func _party_turn() -> void:
	# Valve counterplay (decision #27): the telegraph announces radius + countdown
	# and the network stays exposed until the blast, so the risk-aware play keeps
	# pounding through the window and leaves exactly two Moments (two free moves)
	# to clear the radius. Knockout is the price of misjudging it.
	if fleeing:
		if int(gc.view_clock()["tick"]) < blast_at - 1:
			for id: String in [IMANI, DARIO]:
				if _ready(id) and _in_reach(id) and _boss_breached():
					gc.apply_command(_attack(id, "network", "crushed", NET_HIT))
			return
		for id: String in [IMANI, DARIO]:
			_run_from_boss(id)
		return
	if not _boss_breached():
		# Designed path in: close distance (free moves), then the COMBINED burst
		# onto the highest-HP visible plate the moment both stand in reach — the
		# two linked halves merge into one hit for the >= 7 single-hit breach.
		# The burst outranks treating: re-opening the core shortens the fight.
		var part: String = _best_visible_part()
		for id: String in [IMANI, DARIO]:
			if _ready(id) and not _in_reach(id):
				_walk_to_boss(id)
		if part != "" and _ready(IMANI) and _ready(DARIO) \
				and _in_reach(IMANI) and _in_reach(DARIO):
			gc.apply_command({"type": "combined_action", "members": [
				{"actor": IMANI, "action": _attack(IMANI, part, "crushed", BREACH_HALF)["action"]},
				{"actor": DARIO, "action": _attack(DARIO, part, "crushed", BREACH_HALF)["action"]},
			]})
			return
		for id: String in [IMANI, DARIO]:
			_contestant_turn(id, part)
		return
	for id: String in [IMANI, DARIO]:
		_contestant_turn(id, "")


## One contestant's tick, in priority order: patch a burning torso, close to
## attack reach (free move, then swing the same tick), then hit per the fixed
## strategy — the exposed network when breached, else the Bleeding-T2 path onto
## a visible plate (path A; also the survivor's route when the partner is down).
func _contestant_turn(id: String, part: String) -> void:
	if not _ready(id):
		return
	if _burning_torso(id):
		gc.apply_command({"type": "treat", "target": id, "part": "torso", "condition": "burn", "mode": "resolve"})
		return
	if not _in_reach(id):
		_walk_to_boss(id)
	if not _in_reach(id):
		return
	if _boss_breached():
		gc.apply_command(_attack(id, "network", "crushed", NET_HIT))
	elif part != "":
		gc.apply_command(_attack(id, part, "bleeding", BREACH_HALF + 2))


func _attack(actor: String, part: String, dtype: String, amount: int) -> Dictionary:
	return {"type": "declare_action", "actor": actor, "action": {
		"kind": "attack", "cost": 1, "attack_range": 2,
		"damage": {"type": dtype, "amount": amount},
		"targets": [{"id": BOSS, "part": part}],
	}}


## Highest-HP visible, attackable, NON-lethal boss plate (never the hidden network,
## never a destroyed part, never the head-gated head) — a stable breach target
## across pressure-valve resets.
func _best_visible_part() -> String:
	var b = gc.sim.combatants.get(BOSS)
	if b == null:
		return ""
	var best: String = ""
	var best_hp: int = -1
	var keys: Array = b.parts.keys()
	keys.sort()
	for k: Variant in keys:
		var key := String(k)
		var p: Dictionary = b.parts[key]
		if bool(p.get("hidden", false)) or bool(p.get("destroyed", false)) or bool(p.get("lethal", false)):
			continue
		if key.contains("head"):
			continue  # head targeting gates on Exposed/Helpless/Overwhelmed
		if int(p.get("hp", 0)) <= 0:
			continue
		if int(p.get("hp", 0)) > best_hp:
			best_hp = int(p.get("hp", 0))
			best = key
	return best


func _burning_torso(id: String) -> bool:
	var c = gc.sim.combatants.get(id)
	return c != null and (c.conditions.get("torso", {}) as Dictionary).has("burn")


func _in_reach(id: String) -> bool:
	var c = gc.sim.combatants.get(id)
	var b = gc.sim.combatants.get(BOSS)
	if c == null or b == null:
		return false
	return CombatantState.hex_distance(c.position, b.position) <= 2  # the party's attack_range


## Free-move a contestant up to 3 hexes AWAY from the boss (escape window).
func _run_from_boss(id: String) -> void:
	_issue_walk(id, false, 0)


## Free-move a contestant up to 3 hexes TOWARD the boss, stopping at attack reach.
func _walk_to_boss(id: String) -> void:
	_issue_walk(id, true, 2)


func _issue_walk(id: String, toward: bool, stop_range: int) -> void:
	var c = gc.sim.combatants.get(id)
	var b = gc.sim.combatants.get(BOSS)
	if c == null or b == null or not _can_move(c):
		return
	var to: Variant = _walk_target(c, b.position, toward, stop_range)
	if to != null:
		gc.apply_command({"type": "move", "actor": id, "to": [(to as Vector2i).x, (to as Vector2i).y]})


## Mirrors ActionResolver.move's free-move gates so the driver never spends a
## command on a guaranteed rejection.
func _can_move(c) -> bool:
	return c.alive and not c.removed_from_play and not c.is_helpless(gc.sim.clock.tick) \
		and not c.moved_this_tick and not c.free_action_used and not c.windup_pending \
		and c.grappled_by == "" and c.grappling == ""


## Greedy 3-step hex walk toward/away from `anchor` in fixed neighbor order,
## skipping occupied hexes (mirrors EnemyAI's deterministic movement plan).
## When no strictly-improving step exists, one equal-distance sidestep routes
## around a body blocking the lane (never revisiting a hex). Returns null when
## the plan makes no net progress.
func _walk_target(c, anchor: Vector2i, toward: bool, stop_range: int) -> Variant:
	var neighbors: Array = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
	]
	var occupied: Dictionary = {}
	var ids: Array = gc.sim.combatants.keys()
	ids.sort()
	for oid: Variant in ids:
		var other = gc.sim.combatants[oid]
		if String(oid) != c.id and other.alive and not other.removed_from_play:
			occupied[other.position] = true
	var pos: Vector2i = c.position
	var visited: Dictionary = {c.position: true}
	for step: int in range(3):
		var current_d: int = CombatantState.hex_distance(pos, anchor)
		if toward and current_d <= stop_range:
			break
		var best: Variant = null
		var best_d: int = current_d
		var side: Variant = null
		for n: Variant in neighbors:
			var candidate: Vector2i = pos + (n as Vector2i)
			if occupied.has(candidate) or visited.has(candidate):
				continue
			var d: int = CombatantState.hex_distance(candidate, anchor)
			if (toward and d < best_d) or (not toward and d > best_d):
				best = candidate
				best_d = d
			elif d == current_d and side == null:
				side = candidate
		if best == null:
			best = side
		if best == null:
			break
		visited[best] = true
		pos = best
	var start_d: int = CombatantState.hex_distance(c.position, anchor)
	var end_d: int = CombatantState.hex_distance(pos, anchor)
	if pos == c.position or (toward and end_d >= start_d) or (not toward and end_d <= start_d):
		return null
	return pos


func _ready(id: String) -> bool:
	var c = gc.sim.combatants.get(id)
	if c == null:
		return false
	return c.alive and not c.removed_from_play and not c.is_helpless(gc.sim.clock.tick) \
		and gc.sim.clock.tick >= c.next_action_tick and not c.windup_pending


func _boss_breached() -> bool:
	var b = gc.sim.combatants.get(BOSS)
	return b != null and bool(b.breached)


func _torso_hp(id: String) -> int:
	var c = gc.sim.combatants.get(id)
	if c == null:
		return -1
	return int((c.parts.get("torso", {}) as Dictionary).get("hp", -1))


# =====================================================================  REPORT
func _report() -> void:
	var nb = func(x: int) -> String: return "-" if x < 0 else str(x)
	print("BALANCE outcome=%s ticks_to_breach=%s ticks_to_network_kill=%s first_contestant_down_tick=%s max_single_hit_on_contestant=%d imani_torso_end=%d dario_torso_end=%d rebreaches=%d blasts=%d knockouts=%d network_hp_end=%d" % [
		outcome, nb.call(breach_tick), nb.call(network_kill_tick), nb.call(first_down_tick),
		max_hit_on_contestant, _torso_hp(IMANI), _torso_hp(DARIO), rebreaches, blasts, knockouts,
		_network_hp()])


func _network_hp() -> int:
	var b = gc.sim.combatants.get(BOSS)
	if b == null:
		return -1
	return int((b.parts.get("network", {}) as Dictionary).get("hp", -1))
