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
## exactly like a live fight. The party follows a FIXED strategy that plays the kit the
## recent merges shipped — every input is a command a player has through the HUD, and
## every read is public view state (positions, view_schedule's declared-action bars,
## telegraph events, its own buffs):
##  * BREACH — open the hidden network via the designed combined burst (merged force
##    6+6 -> one 12-net hit >= 7); when the partner is unavailable, Imani's solo path-A
##    bleeding-8 strike (force 10 - robustness 3 = 7) re-opens it alone.
##  * FEINT DENIAL (Dario, the skirmisher) — the boss's big actions are cost-2 WINDUPS,
##    visible a full Moment before they resolve. Dario keeps a feint parked on the boss
##    whenever the flag is clear: the boss's next scheduled resolution (cone sweep or
##    dash) collapses into a Forced Action – Tool, wasting its 2 committed Moments. The
##    flag is NOT consumed by the valve's telegraph/blast (those bypass the resolver),
##    so a feint parked before fleeing still denies the first post-valve sweep.
##  * MERGED POUR — on ticks Dario is not feinting, the pair pours the exposed network
##    with a COMBINED strike: one merged robustness gate (15 - 3 = 12 net) instead of
##    two separate gates (5 + 4) — the same R15 mechanic the breach uses.
##  * BRACE (Imani, the anchor) — she cannot dodge the dash (Reflexes 2 vs threshold
##    7), so she keeps her free-action brace guard up whenever she stands in reach:
##    a landed dash nets 1 instead of 3.
##  * SPREAD on the valve — on the steam telegraph Imani pounds one last Moment then
##    runs; Dario runs immediately and OVERSHOOTS past the cone's 10-hex reach
##    (CONE_MIN_TARGETS=2 in the enemy AI: with one contestant out of reach the sweep
##    is denied entirely), rejoining only when the boss is committed to a windup /
##    prone, or his parked feint still covers the next action.
##  * A burning torso still gets treated before the Clock reset escalates it, and a
##    lone survivor still has the bleeding-tier breach path.
##
## It answers with numbers, not vibes: at full boss cadence, do the magnitudes one-shot
## a contestant / TPK the party, and with GOOD play do they produce a winnable,
## no-one-shot fight with margin? It prints:
##  * a PROBE line — the boss's WORST-CASE single hit (dash on a lone contestant, cone on
##    a crowd) against fresh torsos of each physique. This is the clean one-shot metric,
##    independent of party pace: a "died=" true here is a from-full-to-0 one-shot.
##  * a BALANCE line — the machine-greppable outcome of the full-cadence fight, extended
##    (additively — every pre-existing key is unchanged and in place) with the denial
##    telemetry: feints=cast windups_denied=collapsed cones_declared / cones_denied.
##
## Set BALANCE_TRACE=1 in the environment for a per-tick event trace (driver-side
## debugging only — printing never alters the command stream or the rng).
##
## HARD LINE: DRIVER/CONSUMER ONLY — it never touches simulation/, controller/, data/
## or tests/. Determinism: fixed seeds, no wall-clock reads, no RNG in the driver. The
## boss is added with dodge_threshold stripped (the same spec choice the engine's own
## breach/phase tests make) so the boss-side R22 dodge never blurs the party's damage
## measurements. The party-side R22 Dash ladder (dash "dodge" block) stays LIVE — it is
## part of what this instrument measures — and its rolls ride the salted ai_rng, so a
## fixed seed still reproduces the identical fight; the DODGE line reports how often it
## actually fired.

# --------------------------------------------------------------------- tunables
## Fight seed. CI runs the default (14); BALANCE_SEED overrides it for local
## robustness sweeps only — the strategy itself is roll-independent (feint
## denial and the merged pour consume no rng), so a seed changes only the
## boss's weighted-target draws and the Forced-Tool fallout.
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

## Spread stance: the cone sweep needs >= 2 targets within its 10-hex reach
## (enemy_ai CONE_MIN_TARGETS) — Dario holds at 11+ during a valve retreat so a
## post-blast sweep has at most one contestant to find and is never chosen.
const SPREAD_DISTANCE: int = 11

## Loadout skill grants — verbatim (normalized key+level) from
## data/demo_loadouts.json, the same grants slice_playtest stages. The strategy
## only ever declares GRANTED keys at GRANTED levels (player-honest inputs).
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
# R22 dash-ladder telemetry: how often the counterplay actually fired this run.
var dash_declared: int = 0
var dash_dodges: int = 0
var dodge_fails: int = 0
var sidesteps: int = 0
var counters: int = 0
# Feint-denial strategy state + telemetry. feint_pending mirrors what the caster
# knows from public events: feint_applied set it, the attributed feint_fallout
# (the ONLY consumption path — telegraph/blast bypass the resolver) clears it.
var feint_pending: bool = false
var spread_mode: bool = false    # Dario holding outside cone reach after a telegraph
var feints_cast: int = 0
var windups_denied: int = 0
var cones_declared: int = 0
var cones_denied: int = 0
var dashes_denied: int = 0
var trace_on: bool = false


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
## Probe targets carry Reflexes 2: under R22 the dash's 7-threshold dodge is then
## IMPOSSIBLE by construction (2 + d4 max = 6 < 7), so the probe measures the worst-case
## HIT — never a seed-lucky dodge (the ladder has its own tests + the DODGE line).
func _one_hit(_ability: String, phys: int, crowd: bool) -> Dictionary:
	var g = GameControllerScript.new()
	g.name = "Probe"
	root.add_child(g)
	g.start_combat(PROBE_SEED)
	_add_boss_to(g)
	_add_contestant_to(g, "p", {"physique": phys, "reflexes": 2, "mind": 3, "charm": 3}, Vector2i(1, 0))
	if crowd:
		_add_contestant_to(g, "q", {"physique": phys, "reflexes": 2, "mind": 3, "charm": 3}, Vector2i(0, 1))
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
	trace_on = OS.get_environment("BALANCE_TRACE") == "1"
	var fight_seed: int = SEED
	var seed_override: String = OS.get_environment("BALANCE_SEED")
	if seed_override.is_valid_int():
		fight_seed = int(seed_override)
	gc = GameControllerScript.new()
	gc.name = "BalanceHarness"
	root.add_child(gc)
	gc.sim_event.connect(_on_sim_event)
	gc.start_combat(fight_seed)
	_add_boss_to(gc)
	# Imani "The Door" (heavy physique) and Dario "Encore" (low physique — the one-shot
	# canary: his phys-2 torso has the lowest Robustness on the table). Both carry
	# their demo-loadout skill grants; the strategy declares only granted keys.
	_add_contestant_to(gc, IMANI, {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}, Vector2i(1, 0), IMANI_SKILLS)
	_add_contestant_to(gc, DARIO, {"physique": 2, "reflexes": 5, "mind": 2, "charm": 3}, Vector2i(0, 1), DARIO_SKILLS)
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


func _add_contestant_to(g, id: String, traits: Dictionary, pos: Vector2i, skills: Array = []) -> void:
	var spec: Dictionary = {
		"id": id, "name": id, "race": "human", "team": "party",
		"position": [pos.x, pos.y], "traits": traits,
	}
	if not skills.is_empty():
		spec["skills"] = skills
	g.apply_command({"type": "add_combatant", "combatant": spec})


# =====================================================================  EVENTS
func _on_sim_event(e: Dictionary) -> void:
	sink.append(e)
	var ty: String = String(e.get("type", ""))
	var tk: int = int(e.get("tick", int(gc.view_clock().get("tick", 0))))
	if trace_on:
		print("  t%d %s" % [tk, JSON.stringify(e)])
	match ty:
		"damage_applied":
			var who: String = String(e.get("combatant", ""))
			if who == IMANI or who == DARIO:
				max_hit_on_contestant = maxi(max_hit_on_contestant, int(e.get("amount", 0)))
		"ai_decision":
			if String(e.get("ability", "")) == "dash":
				dash_declared += 1
			elif String(e.get("ability", "")) == "flamethrower":
				cones_declared += 1
		"feint_applied":
			if String(e.get("target", "")) == BOSS:
				feint_pending = true
				feints_cast += 1
		"feint_fallout":
			if String(e.get("victim", "")) == BOSS:
				feint_pending = false
				windups_denied += 1
				var denied_key: String = String(e.get("key", ""))
				if denied_key == "flamethrower":
					cones_denied += 1
				elif denied_key == "dash":
					dashes_denied += 1
		"attack_dodged":
			dash_dodges += 1
		"dodge_failed":
			dodge_fails += 1
		"dash_sidestepped":
			sidesteps += 1
		"dash_countered":
			counters += 1
		"explosion_telegraph":
			fleeing = true  # the steam is the cue
			spread_mode = true  # Dario overshoots past cone reach until re-engage
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
## One party tick of the fixed strategy. Inputs are all player-surface commands;
## reads are all public view state (view_schedule / view_clock / the party's own
## buffs / event-derived flags). Priority order:
##   1. valve beat live -> the valve choreography (pound one last Moment, run,
##      Dario overshoots into the spread stance),
##   2. Imani keeps her free-action brace guard up while she stands in reach,
##   3. Dario re-parks the feint whenever the boss's collapse flag is clear,
##   4. both free + in reach -> the COMBINED merged-force strike (breach the
##      plate pre-breach, pour the network after),
##   5. otherwise each plays their role turn (anchor / skirmisher).
func _party_turn() -> void:
	var tick: int = int(gc.view_clock()["tick"])
	if fleeing:
		_valve_turn(tick)
		return
	_maybe_brace()
	if not spread_mode and not feint_pending and _ready(DARIO) and _dist(DARIO) <= 1:
		_cast_feint()
		_anchor_turn()
		return
	if not spread_mode and _ready(IMANI) and _ready(DARIO) \
			and _in_reach(IMANI) and _in_reach(DARIO):
		var part: String = "network" if _boss_breached() else _best_visible_part()
		var amount: int = NET_HIT if _boss_breached() else BREACH_HALF
		if part != "":
			gc.apply_command({"type": "combined_action", "members": [
				{"actor": IMANI, "action": _attack(IMANI, part, "crushed", amount)["action"]},
				{"actor": DARIO, "action": _attack(DARIO, part, "crushed", amount)["action"]},
			]})
			return
	_anchor_turn()
	_skirmisher_turn()


## Valve beat (decision #27): the telegraph announces radius + countdown and the
## network stays exposed until the blast. Imani pounds while two clear Moments
## remain, then runs. Dario parks one last feint if the flag is clear (the flag
## survives the beat — telegraph/blast bypass the resolver) and runs IMMEDIATELY,
## overshooting past the cone's reach so the first post-blast decide sees only
## one contestant in sweep range (spread stance).
func _valve_turn(tick: int) -> void:
	if not feint_pending and _ready(DARIO) and _dist(DARIO) <= 1 and _boss_alive():
		_cast_feint()  # scheduled cost-1; the free-move run below still fits this tick
	if tick < blast_at - 1 and _ready(IMANI) and _in_reach(IMANI) and _boss_breached():
		gc.apply_command(_attack(IMANI, "network", "crushed", NET_HIT))
	else:
		_run_from_boss(IMANI)
	if _dist(DARIO) < SPREAD_DISTANCE:
		_run_from_boss(DARIO)


## ANCHOR (Imani, physique 5): patch a burning torso, close to attack reach
## (free move, then swing the same tick), then hit — the exposed network when
## breached, else the solo path-A re-breach: her bleeding-8 strike is a 7-net
## single hit (force 8+2 − robustness 3), exactly the burst threshold.
func _anchor_turn() -> void:
	if not _ready(IMANI):
		return
	if _burning_torso(IMANI):
		gc.apply_command({"type": "treat", "target": IMANI, "part": "torso", "condition": "burn", "mode": "resolve"})
		return
	if not _in_reach(IMANI):
		_walk_to_range(IMANI, 2)
	if not _in_reach(IMANI):
		return
	if _boss_breached():
		gc.apply_command(_attack(IMANI, "network", "crushed", NET_HIT))
	else:
		var part: String = _best_visible_part()
		if part != "":
			gc.apply_command(_attack(IMANI, part, "bleeding", BREACH_HALF + 2))


## SKIRMISHER (Dario, reflexes 5): in spread stance he holds outside the cone's
## reach until the boss is committed (windup pending / prone) or his parked
## feint still covers its next action, then rejoins. Engaged, he keeps feint
## coverage up from adjacency, pours the network otherwise, and as a lone
## survivor seeds the Bleeding-T2 breach path (the only solo route his physique
## can open).
func _skirmisher_turn() -> void:
	if not _ready(DARIO):
		return
	if spread_mode:
		if feint_pending or _boss_windup_pending() or _boss_prone():
			spread_mode = false
		elif _dist(DARIO) < SPREAD_DISTANCE:
			_run_from_boss(DARIO)
			return
		else:
			return
	if _burning_torso(DARIO):
		gc.apply_command({"type": "treat", "target": DARIO, "part": "torso", "condition": "burn", "mode": "resolve"})
		return
	if _dist(DARIO) > 1:
		_walk_to_range(DARIO, 1)
	if not feint_pending and _dist(DARIO) <= 1 and _boss_alive():
		_cast_feint()
		return
	if _boss_breached() and _dist(DARIO) <= 2:
		gc.apply_command(_attack(DARIO, "network", "crushed", NET_HIT))
		return
	if not _boss_breached() and not _alive(IMANI) and _dist(DARIO) <= 2:
		var part: String = _best_visible_part()
		if part != "":
			gc.apply_command(_attack(DARIO, part, "bleeding", BREACH_HALF + 2))


## Imani's free-slot upkeep: brace (cost 0, guard = level 2) whenever she stands
## in reach with no guard up and the slot unspent. She cannot dodge the dash
## (Reflexes 2 + d4 max < 7 — impossible by design), so the guard is her whole
## defensive layer: a landed dash nets 1 instead of 3, a cone nets 0.
func _maybe_brace() -> void:
	var c = gc.sim.combatants.get(IMANI)
	if c == null or not c.alive or c.removed_from_play or c.is_helpless(gc.sim.clock.tick):
		return
	if c.free_action_used or int(c.brace_guard) > 0 or not _in_reach(IMANI):
		return
	gc.apply_command({"type": "declare_action", "actor": IMANI, "action": {
		"kind": "skill", "key": "brace", "level": _skill_level(IMANI, "brace"),
	}})


## Dario's feint (granted level, adjacency self-enforced to the skill's range 1):
## the boss's next scheduled resolution collapses into Forced Action – Tool.
func _cast_feint() -> void:
	gc.apply_command({"type": "declare_action", "actor": DARIO, "action": {
		"kind": "skill", "key": "feint", "level": _skill_level(DARIO, "feint"),
		"targets": [{"id": BOSS, "part": "torso"}],
	}})


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


## Free-move a contestant up to 3 hexes TOWARD the boss, stopping at `stop_range`
## (2 = the party's attack reach; 1 = feint adjacency for the skirmisher).
func _walk_to_range(id: String, stop_range: int) -> void:
	_issue_walk(id, true, stop_range)


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


func _boss_alive() -> bool:
	var b = gc.sim.combatants.get(BOSS)
	return b != null and bool(b.alive) and not b.removed_from_play


func _alive(id: String) -> bool:
	var c = gc.sim.combatants.get(id)
	return c != null and bool(c.alive) and not c.removed_from_play


func _dist(id: String) -> int:
	var c = gc.sim.combatants.get(id)
	var b = gc.sim.combatants.get(BOSS)
	if c == null or b == null:
		return 9999
	return CombatantState.hex_distance(c.position, b.position)


## The boss's prone state — public knowledge (the knocked_prone / stood_up
## events broadcast it; the HUD renders it).
func _boss_prone() -> bool:
	var b = gc.sim.combatants.get(BOSS)
	return b != null and bool(b.statuses.get("prone", false))


## Does the boss have a committed multi-Moment windup pending? Read off the
## SAME view_schedule projection the HUD's declared-action bars render — the
## player-visible telegraph the R22 dash rework shipped.
func _boss_windup_pending() -> bool:
	for row: Dictionary in gc.view_schedule():
		if String(row.get("actor", "")) == BOSS and bool(row.get("windup", false)):
			return true
	return false


## Granted level for a loadout skill (the strategy only declares granted keys).
func _skill_level(id: String, key: String) -> int:
	var c = gc.sim.combatants.get(id)
	if c == null:
		return 1
	for s: Dictionary in c.skills:
		if String(s.get("key", "")) == key:
			return int(s.get("level", 1))
	return 1


func _torso_hp(id: String) -> int:
	var c = gc.sim.combatants.get(id)
	if c == null:
		return -1
	return int((c.parts.get("torso", {}) as Dictionary).get("hp", -1))


# =====================================================================  REPORT
func _report() -> void:
	var nb = func(x: int) -> String: return "-" if x < 0 else str(x)
	print("BALANCE outcome=%s ticks_to_breach=%s ticks_to_network_kill=%s first_contestant_down_tick=%s max_single_hit_on_contestant=%d imani_torso_end=%d dario_torso_end=%d rebreaches=%d blasts=%d knockouts=%d network_hp_end=%d feints=%d windups_denied=%d cones_declared=%d cones_denied=%d" % [
		outcome, nb.call(breach_tick), nb.call(network_kill_tick), nb.call(first_down_tick),
		max_hit_on_contestant, _torso_hp(IMANI), _torso_hp(DARIO), rebreaches, blasts, knockouts,
		_network_hp(), feints_cast, windups_denied, cones_declared, cones_denied])
	# R22 dash-ladder telemetry (honest instrument line — under feint denial +
	# the spread stance the boss rarely gets a dash to the strike round, so the
	# ladder may not fire at all; a 0-dodge line is a finding, not a failure.
	# dash_denied counts dashes the parked feint collapsed before they landed).
	print("DODGE dash_declared=%d dodged=%d failed=%d sidesteps=%d counters=%d dash_denied=%d" % [
		dash_declared, dash_dodges, dodge_fails, sidesteps, counters, dashes_denied])
	# R23 antagonism telemetry: final grudge scores per AI actor, read off the
	# view API's new additive "antagonism" key (who the boss hates, and how much
	# — the cone/blast paths deal collateral without drawing, but the grudge
	# ledger still records every net hit the party landed on it).
	var grudge_bits: Array = []
	for cv: Variant in gc.view_combatants():
		var c: Dictionary = cv
		var scores: Dictionary = c.get("antagonism", {})
		if String(c.get("team", "")) != "enemies":
			continue
		var keys: Array = scores.keys()
		keys.sort()
		var pairs: Array = []
		for k: Variant in keys:
			pairs.append("%s:%.1f" % [String(k), float(scores[k])])
		grudge_bits.append("%s={%s}" % [String(c.get("id", "")), ",".join(pairs)])
	print("ANTAGONISM %s" % " ".join(grudge_bits))


func _network_hp() -> int:
	var b = gc.sim.combatants.get(BOSS)
	if b == null:
		return -1
	return int((b.parts.get("network", {}) as Dictionary).get("hp", -1))
