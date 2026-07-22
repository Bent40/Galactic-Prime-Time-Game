extends SimTestBase
## HUD v2 Phase 2 — the READ-ONLY preview probes (spectator contract):
## ActionResolver.preview_action / GameController.preview_action +
## Clock.scheduled_entries / GameController.view_schedule.
##
## The bar these tests hold:
##   1. PURITY — a preview mutates nothing and consumes NO rng: state_hash is
##      identical before/after, two calls return identical dicts, and a lockstep
##      twin sim (one calling previews between every command) stays
##      hash-identical through declares AND resolves (a consumed dodge d6 would
##      diverge the live dodge outcomes and split the hashes).
##   2. TRUTH — for a deterministic no-dodge strike the previewed net EQUALS the
##      damage_applied amount at resolve; a robustness-blocked poke previews
##      net 0 / blocked and seeds no bleed at resolve (R14 D3).
##   3. prime_unmet surfaces the same reason declare would reject on.
##   4. view_schedule rows carry the declared/resolve ticks + windup flag and
##      disappear once the entry resolves; combo members carry their combo_id.
##   5. A merged combo preview sums connected Forces and matches the real
##      combined_force event in a twin sim.

const SEED := 21


func _make_controller() -> Node:
	var script: GDScript = load("res://controller/game_controller.gd")
	return script.new()


## Boss-shaped single-part target (mirrors test_combined_force's fixture).
func _target_spec(id: String, physique: int, extra: Dictionary = {}) -> Dictionary:
	var spec: Dictionary = {
		"id": id, "name": id, "category": "Boss", "size": "Large",
		"position": [1, 0],
		"traits": {"physique": physique, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [{"key": "hide", "hp": 60, "lethal": true}],
	}
	spec.merge(extra, true)
	return spec


func _strong_strike(target_id: String, part: String) -> Dictionary:
	return {
		"kind": "skill", "key": "strong_strike", "level": 1,
		"attack_range": 1, "targets": [{"id": target_id, "part": part}],
	}


# ------------------------------------------------------------------ 1. purity

func test_preview_is_pure_and_repeatable() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "a", {"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	# dodge_threshold present: a preview that ROLLED the d6 would consume the AI
	# stream — the hash itself can't see rng cursors, so purity is re-proven via
	# the lockstep twin below; here we prove no STATE mutation + determinism.
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 4,
		{"boss_traits": {"dodge_threshold": 4}})})
	var before: String = sim.state_hash()
	var action: Dictionary = _strong_strike("t", "hide")
	var p1: Dictionary = sim.resolver.preview_action(sim.combatants["a"], action)
	var p2: Dictionary = sim.resolver.preview_action(sim.combatants["a"], action)
	assert_eq(CombatSim.canonical_serialize(p1), CombatSim.canonical_serialize(p2),
		"two identical previews return identical dicts")
	assert_eq(sim.state_hash(), before, "preview mutates NOTHING (state_hash unchanged)")
	assert_true(bool(p1.get("windup", false)), "strong_strike (cost 2) previews as a windup")
	assert_eq(int(p1.get("cost", 0)), 2, "effective Moment cost from the SkillBook spec")
	var row: Dictionary = (p1.get("per_target", []) as Array)[0]
	assert_true(bool(row.get("dodge_possible", false)), "eligible dodge reported as uncertainty")
	assert_eq(int(row.get("dodge_threshold", 0)), 4, "threshold read off boss_traits, never rolled")


func test_lockstep_previews_never_split_the_hash() -> void:
	# Twin sims, identical command streams; sim A additionally calls previews
	# around every command. The target CAN dodge, so its resolutions consume the
	# AI d6 — if a preview consumed even one roll, the dodge outcomes (and so
	# the hashes) would diverge.
	var a: CombatSim = make_sim(SEED)
	var b: CombatSim = make_sim(SEED)
	for sim: CombatSim in [a, b]:
		add_human(sim, "p", {"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
		sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 4,
			{"boss_traits": {"dodge_threshold": 4}})})
	var commands: Array = [
		{"type": "declare_action", "actor": "p", "action": _strong_strike("t", "hide")},
		{"type": "advance_tick"},
		{"type": "advance_tick"},
		{"type": "advance_tick"},  # windup resolves here (declared T0 -> due T2)
		{"type": "declare_action", "actor": "p", "action": attack_action("crushed", 2, "t", "hide")},
		{"type": "advance_tick"},  # instant resolves (another dodge d6 consumed)
	]
	var probe: Dictionary = _strong_strike("t", "hide")
	for cmd: Variant in commands:
		a.resolver.preview_action(a.combatants["p"], probe)  # extra previews on A only
		a.apply_command(cmd)
		a.resolver.preview_action(a.combatants["p"], probe)
		b.apply_command(cmd)
		assert_eq(a.state_hash(), b.state_hash(),
			"lockstep hash after %s" % String((cmd as Dictionary).get("type", "")))


# ------------------------------------------------------------------ 2. truth

func test_preview_matches_resolved_damage() -> void:
	# No dodge -> fully deterministic. Force = 6 + floor(5/2) = 8; Robustness =
	# floor(4/2) = 2; net 6. The resolved damage_applied must equal the preview.
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "a", {"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 4)})
	var action: Dictionary = _strong_strike("t", "hide")
	var p: Dictionary = sim.resolver.preview_action(sim.combatants["a"], action)
	var row: Dictionary = (p.get("per_target", []) as Array)[0]
	assert_eq(int(row.get("force", 0)), 8, "Force = amount 6 + floor(phys 5 / 2)")
	assert_eq(int(row.get("robustness", 0)), 2, "Robustness = floor(phys 4 / 2)")
	assert_eq(int(row.get("net", -1)), 6, "previewed net")
	assert_true(bool(row.get("landed", false)), "previews as a landed wound")
	assert_eq(String(row.get("blocked_reason", "x")), "", "nothing blocks it")
	assert_false(bool(row.get("dodge_possible", true)), "no dodge_threshold -> no uncertainty")
	declare(sim, "a", action)
	advance(sim, 2)  # declared T0, due T2 — still winding up
	var events: Array[Dictionary] = advance(sim)  # tick 2: the windup resolves
	var dmg: Dictionary = assert_event(events, "damage_applied", "the windup resolves into real damage")
	assert_eq(int(dmg.get("amount", -1)), int(row.get("net", -2)),
		"PREVIEW == REALITY: resolved amount equals previewed net")
	assert_event(events, "condition_applied", "crushed rides the landed wound (previewed)")
	assert_eq((row.get("conditions", []) as Array), ["crushed"], "preview listed the riding condition")


func test_blocked_poke_previews_zero_and_seeds_no_bleed() -> void:
	# Force = 1 + floor(2/2) = 2 vs Robustness floor(10/2) = 5 -> blocked. The
	# preview must say net 0 / robustness-blocked / NO riding bleed, and the
	# resolve must agree (attack_no_wound, no bleeding condition).
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "a", {"traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 10)})
	var action: Dictionary = attack_action("bleeding", 1, "t", "hide")
	var p: Dictionary = sim.resolver.preview_action(sim.combatants["a"], action)
	var row: Dictionary = (p.get("per_target", []) as Array)[0]
	assert_eq(int(row.get("net", -1)), 0, "blocked poke previews net 0")
	assert_false(bool(row.get("landed", true)), "does not land")
	assert_eq(String(row.get("blocked_reason", "")), "robustness", "blocked by robustness")
	assert_true((row.get("conditions", ["x"]) as Array).is_empty(),
		"R14 D3: no wound -> bleed does NOT ride (previewed)")
	declare(sim, "a", action)
	var events: Array[Dictionary] = advance(sim)
	var dmg: Dictionary = assert_event(events, "damage_applied", "the poke still applies (at 0)")
	assert_eq(int(dmg.get("amount", -1)), 0, "resolved amount 0 — matches the preview")
	assert_event(events, "attack_no_wound", "the D3 no-wound gate fired")
	assert_no_event(events, "condition_applied", "no bleed seeded on resolve")


# ------------------------------------------------------------------ 3. primes

func test_preview_surfaces_prime_unmet() -> void:
	var sim: CombatSim = make_sim(SEED)
	add_human(sim, "a")
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 4)})
	var gated: Dictionary = attack_action("crushed", 2, "t", "hide",
		{"prime": {"type": "stance", "stance": "defensive"}})
	var before: String = sim.state_hash()
	var p: Dictionary = sim.resolver.preview_action(sim.combatants["a"], gated)
	assert_eq(String(p.get("prime_unmet", "")), "stance:defensive",
		"the unmet STANCE prime surfaces in the preview")
	assert_eq(sim.state_hash(), before, "prime probing mutates nothing")
	sim.apply_command({"type": "set_stance", "actor": "a", "stance": "defensive"})
	var p2: Dictionary = sim.resolver.preview_action(sim.combatants["a"], gated)
	assert_eq(String(p2.get("prime_unmet", "x")), "", "held stance -> prime satisfied")


# ------------------------------------------------------------- 4. view_schedule

func test_view_schedule_windup_lifecycle() -> void:
	var game: Node = _make_controller()
	game.start_combat(SEED, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "a", "name": "a", "race": "human", "position": [0, 0],
		"traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 4)})
	assert_true((game.view_schedule() as Array).is_empty(), "empty before any declaration")
	game.apply_command({"type": "declare_action", "actor": "a", "action": _strong_strike("t", "hide")})
	var rows: Array = game.view_schedule()
	assert_eq(rows.size(), 1, "one pending entry after the windup declare")
	var row: Dictionary = rows[0]
	assert_eq(String(row.get("actor", "")), "a", "actor id")
	assert_eq(String(row.get("kind", "")), "skill", "kind from the action dict")
	assert_eq(String(row.get("key", "")), "strong_strike", "key from the action dict")
	assert_eq(int(row.get("declared_tick", -1)), 0, "declared at tick 0")
	assert_eq(int(row.get("resolve_tick", -1)), 2, "cost-2 windup resolves at tick 2")
	assert_true(bool(row.get("windup", false)), "flagged as a windup")
	assert_false(row.has("combo_id"), "no combo_id on a solo declare")
	game.apply_command({"type": "advance_tick"})
	game.apply_command({"type": "advance_tick"})
	assert_eq((game.view_schedule() as Array).size(), 1, "still pending while the windup holds")
	game.apply_command({"type": "advance_tick"})  # due at tick 2 -> resolves now
	assert_true((game.view_schedule() as Array).is_empty(), "gone after resolution")
	game.free()


func test_view_schedule_combo_members_carry_combo_id() -> void:
	var game: Node = _make_controller()
	game.start_combat(SEED, load_static_data())
	for id: String in ["p1", "p2"]:
		game.apply_command({"type": "add_combatant", "combatant": {
			"id": id, "name": id, "race": "human", "position": [0, 0],
			"traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 10)})
	game.apply_command({"type": "combined_action", "combo_id": "party_combo", "members": [
		{"actor": "p1", "action": _strong_strike("t", "hide")},
		{"actor": "p2", "action": _strong_strike("t", "hide")},
	]})
	var rows: Array = game.view_schedule()
	assert_eq(rows.size(), 2, "both linked members pend")
	for rd: Variant in rows:
		assert_eq(String((rd as Dictionary).get("combo_id", "")), "party_combo",
			"each member row carries the combo_id")
	game.free()


# ------------------------------------------------------------ 5. merged preview

func test_merged_combo_preview_matches_combined_force() -> void:
	# Fixture from test_combined_force: two phys-4 amount-3 strikes vs phys-10.
	# Solo Force 5 each (blocked alone); merged 10 > Robustness 5 -> net 5.
	var a: CombatSim = make_sim(11)
	var b: CombatSim = make_sim(11)
	for sim: CombatSim in [a, b]:
		add_human(sim, "p1", {"position": [0, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
		add_human(sim, "p2", {"position": [2, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
		sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 10)})
	var combo_request: Dictionary = {"combo_members": [
		{"actor_id": "p1", "action": attack_action("crushed", 3, "t", "hide")},
		{"actor_id": "p2", "action": attack_action("crushed", 3, "t", "hide")},
	]}
	var p: Dictionary = a.resolver.preview_action(a.combatants["p1"], combo_request)
	var merged: Dictionary = p.get("merged", {})
	assert_eq(int(merged.get("force", 0)), 10, "merged Force = 5 + 5")
	assert_eq(int(merged.get("robustness", 0)), 5, "one merged Robustness gate")
	assert_eq(int(merged.get("net", 0)), 5, "merged net")
	assert_eq((p.get("per_target", []) as Array).size(), 2, "one preview row per member")
	# Reality, in the twin: the same members linked for real.
	var members: Array = [
		{"actor": "p1", "action": attack_action("crushed", 3, "t", "hide")},
		{"actor": "p2", "action": attack_action("crushed", 3, "t", "hide")},
	]
	b.apply_command({"type": "combined_action", "members": members})
	var events: Array[Dictionary] = advance(b)
	var cf: Dictionary = assert_event(events, "combined_force", "the real merged gate fired")
	assert_eq(int(cf.get("force", -1)), int(merged.get("force", -2)), "preview force == real force")
	assert_eq(int(cf.get("robustness", -1)), int(merged.get("robustness", -2)), "preview robustness == real")
	assert_eq(int(cf.get("net", -1)), int(merged.get("net", -2)), "preview net == real net")
	# And the previewing sim, given the SAME commands, lands on the SAME hash.
	a.apply_command({"type": "combined_action", "members": members})
	advance(a)
	assert_eq(a.state_hash(), b.state_hash(), "preview left no trace — twin hashes agree")
