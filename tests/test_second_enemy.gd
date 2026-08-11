extends SimTestBase
## Wave 3c — the SECOND authored enemy: the War Hound (data/enemies.json
## `war_hound`), ported from the compendium's authored war hounds (§4.6 —
## Sasha's Floor-1 maze pack; the audit roster's "war hound (doubles into
## Sasha/Nikita content)" row). PROVISIONAL content (owner review) — these
## tests pin the PORT, not canon numbers (all PLACEHOLDER, R14).
##
## What is pinned here (sim-level; the 3-encounter demo-run integration lives
## in tests/test_run_state.gd / test_run_persistence.gd):
##   * the data contract: Elite/Medium quadruped (R21 layout), pack personality
##     (pack_hunter + family "war_hound"), the rending_bite numbers, the
##     PROVISIONAL marker, and the corner_the_prey FLAVOR-RECORD note (the
##     §4.6 maze funnel is REAL since wave 4d — the engine reads the
##     personality's `herder: true` gate, never this effect-only entry, which
##     the strike lookup still skips; the herding behavior itself is pinned in
##     tests/test_herding.gd);
##   * real staged combat via ai_decide: the hound HUNTS (closes) then BITES
##     through the standard elite decide path — move/attack choices, stance
##     substrate reads, the elite lowest-HP "limb latch" part pick;
##   * the SIGNATURE, deterministically: a LONE hound's bite is Robustness-
##     BLOCKED by a phys-5 tank (Force 2 NOT > 2), while the R15 pack pair
##     links (zero extra rng — single-candidate draws agree trivially) into
##     ONE merged gate that bites through (Force 4 > 2, net 2) — the first
##     pack link above mob tier (linking is personality-gated, category-free);
##   * personality drives targeting as authored: blood-scent low_hp_bias 3.0
##     (exact weight math), damage-grudge 1:1, and the dim Mind (mock_sensitive
##     false — feints build nothing, like the boss);
##   * PROBE balance bar (in-test, NOT in balance_sim): the hound's max single
##     hit vs a fresh phys-2 contestant torso is < 5 — no one-shots — computed
##     from the DATA so any retuning re-gates, and verified live; the merged
##     pair maximum is probed too (a merged combined hit counts as ONE, NQ2);
##   * determinism + serialization: same (seed, command log) twice -> identical
##     hash; a mid-tick save with a pending pack link restores and resolves
##     identically.


func add_enemy(sim: CombatSim, id: String, enemy_key: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": enemy_key,
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func add_hound(sim: CombatSim, id: String, pos: Array, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {"position": pos}
	spec.merge(overrides, true)
	return add_enemy(sim, id, "war_hound", spec)


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func part_hp(sim: CombatSim, id: String, part: String) -> int:
	return int(((sim.combatants[id] as CombatantState).parts[part] as Dictionary).get("hp", 0))


static func hound_template() -> Dictionary:
	for entry: Variant in SimTestBase.load_json("res://data/enemies.json") as Array:
		if String((entry as Dictionary).get("key", "")) == "war_hound":
			return entry
	return {}


static func ability_of(template: Dictionary, key: String) -> Dictionary:
	for entry: Variant in template.get("abilities", []) as Array:
		if String((entry as Dictionary).get("key", "")) == key:
			return entry
	return {}


# ---------------------------------------------------------------- data contract

func test_war_hound_data_contract() -> void:
	var t: Dictionary = hound_template()
	assert_false(t.is_empty(), "war_hound exists in data/enemies.json")
	assert_eq(String(t.get("category", "")), "Elite",
		"mid tier of the §2.14 ladder: not a one-blow Mob, no Boss phase machinery")
	assert_eq(String(t.get("size", "")), "Medium", "a hound is Medium")
	assert_true(String(t.get("description", "")).contains("PROVISIONAL"),
		"the WHOLE entry is marked PROVISIONAL for owner review")
	# R21 quadruped layout: lethal head 2 + lethal torso 4 + four 2-HP legs.
	var parts: Array = t.get("body_parts", [])
	assert_eq(parts.size(), 6, "quadruped: head + torso + 4 legs")
	var legs: int = 0
	for entry: Variant in parts:
		var p: Dictionary = entry
		var key := String(p.get("key", ""))
		if key == "head":
			assert_eq(int(p.get("hp", 0)), 2, "head 2 (human-baseline vital)")
			assert_true(bool(p.get("lethal", false)), "head is lethal")
		elif key == "torso":
			assert_eq(int(p.get("hp", 0)), 4, "torso 4 — between the cat 3 and human 5 precedents")
			assert_true(bool(p.get("lethal", false)), "torso is lethal")
		else:
			assert_true(key.contains("leg"), "the other parts are legs (got '%s')" % key)
			assert_eq(int(p.get("hp", 0)), 2, "leg 2 (slender dog legs)")
			assert_false(bool(p.get("lethal", false)), "legs are non-lethal")
			legs += 1
	assert_eq(legs, 4, "four legs — the R21 attrition layout")
	# Stat block sits between the roach (1/2/0/0) and the brood-tender (4/3/1/0).
	var sb: Dictionary = t.get("stat_block", {})
	assert_eq(int(sb.get("physique", -1)), 3, "physique 3")
	assert_eq(int(sb.get("reflexes", -1)), 4, "reflexes 4 — a fast hunter")
	assert_eq(int(sb.get("mind", -1)), 1, "mind 1 — a dim animal")
	assert_eq(int(sb.get("charm", -1)), 0, "charm 0")
	# The authored personality: a pack animal, blood-scented, insult-proof.
	var pers: Dictionary = t.get("personality", {})
	assert_true(bool(pers.get("pack_hunter", false)), "pack_hunter — never a loner")
	assert_eq(String(pers.get("pack", "")), "war_hound", "pack family 'war_hound' (R15)")
	assert_false(bool(pers.get("mock_sensitive", true)), "mock_sensitive false — a dog does not parse insults")
	assert_eq(float(pers.get("low_hp_bias", 0.0)), 3.0, "blood-scent low_hp_bias 3.0 (the brood-tender's lever)")
	assert_true(String(pers.get("note", "")).contains("PLACEHOLDER"), "numbers marked PLACEHOLDER (R14)")
	# The bite: the ONE strike the elite decide path exercises, force math in note.
	var bite: Dictionary = ability_of(t, "rending_bite")
	assert_false(bite.is_empty(), "rending_bite is authored")
	assert_eq(int(bite.get("moment_cost", 0)), 1, "bite cost 1 — a same-tick instant (R15 pairs can merge it)")
	assert_eq(int(bite.get("range", 0)), 1, "bite range 1")
	var damage: Array = bite.get("damage", [])
	assert_eq(damage.size(), 1, "one damage entry")
	assert_eq(String((damage[0] as Dictionary).get("type", "")), "bleeding", "the bite bleeds")
	assert_eq(int((damage[0] as Dictionary).get("amount", 0)), 1, "bleeding 1 — attrition, not burst")
	assert_true(String(bite.get("note", "")).contains("Force = 1 + floor(phys 3/2) = 2"),
		"the bite note shows the R14 force math (incinedile note style)")
	# Wave 4d: the §4.6 maze funnel is REAL — the personality carries the
	# engine-read gate; corner_the_prey stays the effect-only FLAVOR RECORD
	# the strike lookup skips (the herding behavior: tests/test_herding.gd).
	assert_true(bool(pers.get("herder", false)),
		"herder: true — THE engine-read gate for the wave-4d maze funnel (R11 #21)")
	var corner: Dictionary = ability_of(t, "corner_the_prey")
	assert_false(corner.is_empty(), "corner_the_prey carries the authored signature as data")
	assert_false(corner.has("damage"), "effect-only: no damage (the strike lookup skips it — drag_back precedent)")
	assert_false(corner.has("summon"), "effect-only: no summon")
	assert_false(corner.has("heal"), "effect-only: no heal")
	assert_false(String(corner.get("note", "")).contains("DATA-ONLY"),
		"the DATA-ONLY downscope marker is GONE — the signature shipped (wave 4d)")
	assert_true(String(corner.get("note", "")).contains("personality.herder"),
		"the flavor record points at the personality gate the engine reads")
	# The demo run stages it as the mid room, as a PAIR (the pack it is).
	var run_def: Dictionary = (SimTestBase.load_json("res://data/demo_run.json") as Dictionary).get("run", {})
	var encounters: Array = run_def.get("encounters", [])
	assert_eq(encounters.size(), 4, "the demo run is 4 rooms (wave 4b branch map)")
	var kennel: Dictionary = encounters[1]
	assert_eq(String(kennel.get("key", "")), "kennel_gauntlet", "the mid room is the kennel")
	var row: Dictionary = (kennel.get("enemies", []) as Array)[0]
	assert_eq(String(row.get("enemy_key", "")), "war_hound", "the mid room fields the war hound")
	assert_eq(int(row.get("count", 0)), 2, "staged as a PAIR — the R15 pack cap, and never alone")


# ------------------------------------------------- the hunt (ai_decide path)

func test_hound_hunts_then_bites_via_ai_decide() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0]})
	add_hound(sim, "hound", [6, 0])
	# Decide 1: out of step+bite reach — the hound CLOSES (choice move) and the
	# stance substrate reads "hunting". Single candidate -> zero rng draws.
	var pre_rng: int = sim.ai.ai_rng.state
	var first: Array[Dictionary] = ai_decide(sim, "hound")
	var d1: Dictionary = assert_event(first, "ai_decision", "the hound decides")
	assert_eq(String(d1.get("tier", "")), "elite", "war hound decides on the ELITE policy")
	assert_eq(String(d1.get("choice", "")), "move", "distance 6: the free step cannot close to bite range")
	assert_eq(String(sim.ai.stances.get("hound", "")), "hunting", "a closing hound reads hunting")
	assert_eq((sim.combatants["hound"] as CombatantState).position, Vector2i(3, 0),
		"free-move allowance 3 closed 6 -> 3")
	advance(sim, 1)
	# Decide 2: the step closes the gap — move THEN bite in the same decide.
	var second: Array[Dictionary] = ai_decide(sim, "hound")
	var d2: Dictionary = assert_event(second, "ai_decision", "the second decide")
	assert_eq(String(d2.get("choice", "")), "attack", "in reach after the step: the hound bites")
	assert_eq(String(d2.get("ability", "")), "rending_bite", "with its authored bite")
	assert_true(bool(d2.get("moves", false)), "the same decide carries the closing step")
	assert_eq(String(sim.ai.stances.get("hound", "")), "aggressive", "a biting hound reads aggressive")
	assert_event(second, "action_declared", "the bite is a real resolver declare")
	# The elite part pick is the LIMB LATCH: lowest-HP part of a fresh human
	# is the 2-HP left_arm (sorted-key tie rule) — a hound pulls down by the limbs.
	var entry: Dictionary = {}
	for q: Dictionary in sim.clock.queue:
		if String(q["actor"]) == "hound":
			entry = q
	assert_eq(String(((entry["action"] as Dictionary).get("targets", [])[0] as Dictionary).get("part", "")),
		"left_arm", "elite pick latches the lowest-HP limb")
	# Resolution: Force = 1 + floor(3/2) = 2 vs phys-3 Robustness 1 -> net 1 +
	# the bleeding rider. Zero rng consumed anywhere (single candidate, no dodge).
	var resolved: Array[Dictionary] = advance(sim, 1)
	var hit: Dictionary = assert_event(resolved, "damage_applied", "the bite lands")
	assert_eq(int(hit.get("amount", -1)), 1, "net 1 through the R14 gate (hand pin)")
	assert_eq(part_hp(sim, "victim", "left_arm"), 1, "left arm 2 -> 1")
	assert_true((sim.combatants["victim"] as CombatantState).condition_tier("left_arm", "bleeding") >= 1,
		"the bleeding rider landed on the bitten limb")
	assert_eq(sim.ai.ai_rng.state, pre_rng,
		"the whole hunt consumed ZERO ai_rng draws (single candidate, no dodge shapes)")


# ------------------------------- the signature: lone-blocked, pack-bites-through

func test_lone_hound_blocked_by_tank_but_the_pack_pair_bites_through() -> void:
	# LONE: Force 2 vs a phys-5 tank's Robustness 2 — NOT >, the gate BLOCKS.
	var tank_traits: Dictionary = {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}
	var sim: CombatSim = make_sim()
	add_human(sim, "tank", {"team": "party", "position": [0, 0], "traits": tank_traits})
	add_hound(sim, "hound", [1, 0])
	ai_decide(sim, "hound")
	var solo: Array[Dictionary] = advance(sim, 1)
	var blocked: Dictionary = assert_event(solo, "attack_no_wound", "the lone bite is Robustness-blocked")
	assert_eq(int(blocked.get("force", 0)), 2, "lone Force 2 (1 + floor(phys 3/2))")
	assert_eq(int(blocked.get("robustness", 0)), 2, "tank Robustness 2 (floor(5/2))")
	assert_eq(part_hp(sim, "tank", "left_arm"), 2, "no wound opened")
	assert_true((sim.combatants["tank"] as CombatantState).conditions.is_empty(),
		"no bleeding either — a blocked hit seeds nothing (R14 D3)")
	# PACK: the pair links (R15) — the first pack link ABOVE mob tier — and the
	# merged Force bites through the same gate. Deterministic by construction:
	# single-candidate draws agree trivially, so linking consumes ZERO rng.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "tank", {"team": "party", "position": [0, 0], "traits": tank_traits})
	add_hound(sim2, "hound_a", [1, 0])
	add_hound(sim2, "hound_b", [0, 1])
	assert_eq((sim2.combatants["hound_a"] as CombatantState).category, "Elite",
		"the linking hunters are ELITES (R15 linking is personality-gated, category-free)")
	var pre_rng: int = sim2.ai.ai_rng.state
	ai_decide(sim2, "hound_a")
	var second: Array[Dictionary] = ai_decide(sim2, "hound_b")
	var synergy: Dictionary = assert_event(second, "pack_synergy", "the pack converges")
	assert_eq(synergy.get("members", []), ["hound_a", "hound_b"], "first declarer, then joiner")
	assert_eq(String(synergy.get("combo_id", "")), "pack:0:0", "deterministic combo id")
	assert_eq(String(synergy.get("part", "")), "left_arm", "the joiner adopts the first's limb latch")
	assert_eq(sim2.ai.ai_rng.state, pre_rng, "single-candidate picks + linking: ZERO rng draws")
	var resolved: Array[Dictionary] = advance(sim2, 1)
	var merged: Dictionary = assert_event(resolved, "combined_force", "the linked bites merge")
	assert_eq(int(merged.get("force", 0)), 4, "summed Force 2 + 2")
	assert_eq(int(merged.get("robustness", 0)), 2, "ONE Robustness gate")
	assert_eq(int(merged.get("net", 0)), 2, "net 2 — the pack opens what no lone hound can")
	assert_eq(merged.get("actors", []), ["hound_a", "hound_b"], "both members connected")
	assert_eq(part_hp(sim2, "tank", "left_arm"), 0, "the latched arm is pulled down (2 -> 0)")
	assert_event(resolved, "part_disabled", "a non-lethal limb at 0 disables — no one-shot kill path")
	assert_true((sim2.combatants["tank"] as CombatantState).condition_tier("left_arm", "bleeding") >= 1,
		"the merged wound bleeds")


# --------------------------------------------- personality drives the targeting

func test_personality_blood_scent_grudge_and_dim_mind() -> void:
	# Blood-scent (low_hp_bias 3.0): equidistant prey, one wounded — the exact
	# R23 weight math, unit-asserted via targeting_weights.
	var sim: CombatSim = make_sim()
	add_human(sim, "fresh", {"team": "party", "position": [2, 0]})
	add_human(sim, "bleeder", {"team": "party", "position": [-2, 0]})
	add_hound(sim, "hound", [0, 0])
	((sim.combatants["bleeder"] as CombatantState).parts["torso"] as Dictionary)["hp"] = 1
	var hound: CombatantState = sim.combatants["hound"]
	var rows: Array[Dictionary] = sim.ai.targeting_weights(hound, sim.ai._opponents(hound), hound.position)
	var w_bleeder: float = 0.0
	var w_fresh: float = 0.0
	for row: Dictionary in rows:
		if String(row["id"]) == "bleeder":
			w_bleeder = float(row["weight"])
		else:
			w_fresh = float(row["weight"])
	assert_eq(w_fresh, 0.25, "fresh prey at distance 2: 1/2^2, hp_factor 1")
	# bleeder total hp 13/17: weight = (1/4) * (1 + 3.0 * (1 - 13/17)) exactly.
	assert_eq(w_bleeder, 0.25 * (1.0 + 3.0 * (1.0 - 13.0 / 17.0)),
		"the wounded prey weighs by the authored blood-scent bias — exact R23 math")
	assert_true(w_bleeder > w_fresh, "the pack pulls down the wounded first")
	# Damage-grudge 1:1: a striker earns antagonism equal to the net hit.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "striker", {"team": "party", "position": [1, 0]})
	add_hound(sim2, "hound", [0, 0])
	declare(sim2, "striker", attack_action("crushed", 2, "hound", "torso"))
	var events: Array[Dictionary] = advance(sim2, 1)
	var grudge: Dictionary = assert_event(events, "antagonism_changed", "damage builds grudge")
	assert_eq(String(grudge.get("source", "")), "damage", "source: damage")
	assert_eq(float(grudge.get("delta", 0.0)), 2.0, "net 2 (Force 3 - Robustness 1) -> grudge 2.0 (1:1)")
	assert_eq(float((sim2.combatants["hound"] as CombatantState).antagonism.get("striker", 0.0)), 2.0,
		"a struck hound rounds on its striker")
	# Dim Mind: mock_sensitive false — a feint lands (the L2 read threshold 6 is
	# impossible for Mind 1 + d4) but builds NOTHING; the ledger stays empty.
	var sim3: CombatSim = make_sim()
	add_human(sim3, "trick", {"team": "party", "position": [1, 0]})
	add_hound(sim3, "hound", [0, 0])
	assert_false((sim3.combatants["hound"] as CombatantState).personality_mock_sensitive(),
		"authored mock_sensitive false")
	declare(sim3, "trick", {
		"kind": "skill", "key": "feint", "level": 2, "attack_range": 1,
		"targets": [{"id": "hound", "part": "torso"}],
	})
	var mocked: Array[Dictionary] = advance(sim3, 1)
	assert_event(mocked, "feint_applied", "the feint itself lands (the dog cannot read it)")
	assert_no_event(mocked, "antagonism_changed", "no grudge from words — a dog does not parse insults")
	assert_true((sim3.combatants["hound"] as CombatantState).antagonism.is_empty(), "the ledger stays empty")


# ------------------------------------------------------ PROBE: no one-shots

func test_probe_max_single_hit_vs_fresh_phys2_torso_under_5() -> void:
	# The balance bar, computed from the DATA (any retuning re-gates here):
	# max Force over the hound's damage abilities, vs a fresh phys-2 contestant
	# torso (Robustness floor(2/2) = 1, no armor). NQ2: a merged combined hit
	# counts as ONE hit, so the R15 pair maximum is probed too.
	var t: Dictionary = hound_template()
	var phys: int = int((t.get("stat_block", {}) as Dictionary).get("physique", 0))
	var max_force: int = 0
	for entry: Variant in t.get("abilities", []) as Array:
		for d: Variant in (entry as Dictionary).get("damage", []) as Array:
			max_force = maxi(max_force, int((d as Dictionary).get("amount", 0)) + floori(phys / 2.0))
	assert_true(max_force > 0, "the hound has at least one damage ability")
	var fresh_phys2_robustness: int = 1
	assert_true(max_force - fresh_phys2_robustness < 5,
		"max SINGLE hit vs a fresh phys-2 torso is %d — under the no-one-shot bar (5)" % (max_force - fresh_phys2_robustness))
	assert_true(2 * max_force - fresh_phys2_robustness < 5,
		"even the merged PAIR hit (one hit per NQ2) is %d — under the bar" % (2 * max_force - fresh_phys2_robustness))
	# Live verification of the same numbers through the real resolver.
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0],
		"traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3}})
	add_hound(sim, "hound", [1, 0])
	declare(sim, "hound", attack_action("bleeding", 1, "victim", "torso"))
	var resolved: Array[Dictionary] = advance(sim, 1)
	var hit: Dictionary = assert_event(resolved, "damage_applied", "the strongest bite lands")
	assert_eq(int(hit.get("amount", -1)), max_force - fresh_phys2_robustness, "live net matches the data math")
	assert_eq(part_hp(sim, "victim", "torso"), 5 - (max_force - fresh_phys2_robustness),
		"the fresh torso survives with room to spare")
	assert_true((sim.combatants["victim"] as CombatantState).alive, "no one-shot")


# ------------------------------------------- determinism + serialization

func test_hound_determinism_and_mid_link_serialization() -> void:
	# Same (seed, command log) twice -> identical final hash; a different seed
	# diverges. The skirmish drives real ai_ready_ids decides — no driver rng.
	assert_eq(_hound_skirmish_hash(4242), _hound_skirmish_hash(4242),
		"same seed + same log -> identical hash")
	assert_ne(_hound_skirmish_hash(4243), _hound_skirmish_hash(4242), "a different seed diverges")
	# Mid-tick save with a PENDING pack link: the combo_id rides the queue.
	var sim: CombatSim = make_sim()
	add_human(sim, "tank", {"team": "party", "position": [0, 0],
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	add_hound(sim, "hound_a", [1, 0])
	add_hound(sim, "hound_b", [0, 1])
	ai_decide(sim, "hound_a")
	assert_event(ai_decide(sim, "hound_b"), "pack_synergy", "linked, both bites PENDING")
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "mid-link roundtrip hash identical")
	var live: Array[Dictionary] = advance(sim, 1)
	var replayed: Array[Dictionary] = advance(restored, 1)
	var merged_live: Dictionary = assert_event(live, "combined_force", "the live pair merges")
	var merged_replay: Dictionary = assert_event(replayed, "combined_force", "the restored pair merges too")
	assert_eq(merged_replay, merged_live, "identical merged resolution after the roundtrip")
	assert_eq(restored.state_hash(), sim.state_hash(), "post-resolution hashes identical")


## A fixed kennel skirmish: two hounds, two contestants (one tanky, one soft —
## real weighted draws + the block/link texture), 12 ticks of the standard
## ai_ready_ids driver loop.
func _hound_skirmish_hash(sim_seed: int) -> String:
	var sim: CombatSim = make_sim(sim_seed)
	add_human(sim, "tank", {"team": "party", "position": [1, 0],
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	add_human(sim, "soft", {"team": "party", "position": [0, 1],
		"traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}})
	add_hound(sim, "h1", [3, 0])
	add_hound(sim, "h2", [2, -2])
	for _tick: int in range(12):
		for id: String in sim.ai_ready_ids():
			ai_decide(sim, id)
		advance(sim, 1)
	return sim.state_hash()
