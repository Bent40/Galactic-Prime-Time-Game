extends SimTestBase
## KAN-4 — party of 3 (owner-approved concept Q68: player OC + Sasha & Nikita
## recruitment encounters). Proves the engine holds with THREE contestants + the
## boss, all via real commands, with the recruits staged from the new
## data/recruit_loadouts.json (PROVISIONAL premades) exactly the way tests load
## demo data:
##   * a scripted 3-party fight runs mixed ticks with ZERO command rejections
##     and a valid, reproducible state hash;
##   * R15 merged force across THREE linked same-tick strikes — one gate, one
##     net hit, hand-computed from the R14 formula (extends the 2-way idiom in
##     tests/test_combined_force.gd);
##   * R23 antagonism across 3: three ledger entries, the weighted pick over 3
##     candidates costs EXACTLY one ai_rng draw (twin-RNG idiom from
##     tests/test_antagonism.gd), two equidistant fresh candidates weigh exactly
##     equal and the distant one strictly lower (targeting_weights);
##   * R24 feint-read mirror: Sasha (Mind 5) auto-reads an L1 feint STAGED from
##     an enemy actor through the command stream. HONESTY NOTE: no enemy
##     template in data/enemies.json carries a feint ability (pinned in-test),
##     and EnemyAI only ever picks from template abilities — so the AI never
##     feints on its own today; the command stream, however, accepts a declare
##     from an AI-category actor (ActionResolver.declare has no category gate),
##     which is what "staged" means here. The Mind + die vs threshold arithmetic
##     is ALSO pinned directly through EnemyAI.check_feint_read;
##   * mid-fight save/restore with 3 party members + antagonism state replays a
##     lockstep tail to the identical hash;
##   * the explosion blast catches all three parked in radius — 3 knockout
##     events, all Helpless exactly 2 Clocks (decision #27 choreography).

const RECRUITS_PATH: String = "res://data/recruit_loadouts.json"

## Imani/Dario grant rows + bit, VERBATIM from data/demo_loadouts.json (the
## test_loadout_skills / test_bit_authored staging idiom).
const IMANI_SKILLS: Array = [
	{"id": 4, "key": "strong_strike", "level": 2},
	{"id": 23, "key": "overhead_slam", "level": 1, "cap": 6, "cap_note": "R16 skill-trade"},
	{"id": 8, "key": "brace", "level": 2},
]
const DARIO_SKILLS: Array = [
	{"id": 26, "key": "feint", "level": 3, "cap": 6, "cap_note": "R16 skill-trade"},
	{"id": 27, "key": "pressure_strike", "level": 1},
	{"id": 33, "key": "dance", "level": 2},
]
const DARIO_BIT: Dictionary = {"key": "the_bow", "name": "The Bow", "line": "Dario bows mid-combat — the applause is the point."}


# ---------------------------------------------------------------- data plumbing

func recruit_loadout(key: String) -> Dictionary:
	var data: Dictionary = SimTestBase.load_json(RECRUITS_PATH)
	for lo: Variant in data.get("loadouts", []) as Array:
		if String((lo as Dictionary).get("key", "")) == key:
			return lo
	return {}


func race_key_for_id(race_id: int) -> String:
	for entry: Variant in SimTestBase.load_json("res://data/races.json") as Array:
		if int((entry as Dictionary).get("id", -1)) == race_id:
			return String((entry as Dictionary).get("key", ""))
	return ""


## Builds an add_combatant spec off a recruit loadout row — the documented
## mapping (loadout key's first "_"-token == combat id; race id -> races.json
## template key; skills/bit/camera_call_stacks verbatim, from_spec normalizes).
func recruit_spec(loadout_key: String, position: Array) -> Dictionary:
	var lo: Dictionary = recruit_loadout(loadout_key)
	var traits: Dictionary = (lo.get("traits", {}) as Dictionary).duplicate(true)
	traits.erase("_placeholder")
	var spec: Dictionary = {
		"id": loadout_key.get_slice("_", 0),
		"name": String(lo.get("display_name", loadout_key)),
		"race": race_key_for_id(int(lo.get("race", 0))),
		"team": "party",
		"position": position,
		"traits": traits,
		"skills": (lo.get("skills", []) as Array).duplicate(true),
		"camera_call_stacks": int(lo.get("camera_call_stacks", 0)),
	}
	if lo.has("bit"):
		spec["bit"] = (lo.get("bit", {}) as Dictionary).duplicate(true)
	return spec


func add_recruit(sim: CombatSim, loadout_key: String, position: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": recruit_spec(loadout_key, position)})


func add_imani(sim: CombatSim, position: Array = [1, 0]) -> Array[Dictionary]:
	return add_human(sim, "imani", {"team": "party", "position": position,
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3},
		"skills": IMANI_SKILLS.duplicate(true), "camera_call_stacks": 1})


func add_dario(sim: CombatSim, position: Array = [0, 1]) -> Array[Dictionary]:
	return add_human(sim, "dario", {"team": "party", "position": position,
		"traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5},
		"skills": DARIO_SKILLS.duplicate(true), "camera_call_stacks": 1,
		"bit": DARIO_BIT.duplicate(true)})


## The seeded Incinedile trait block minus the dodge threshold (the
## test_combined_force / test_incinedile / slice-driver spec choice).
func traits_without_dodge() -> Dictionary:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var boss_traits: Dictionary = (e.get("traits", {}) as Dictionary).duplicate(true)
			boss_traits.erase("dodge_threshold")
			boss_traits.erase("dodge_threshold_note")
			return boss_traits
	return {}


## A durable, harmless AI punching bag (test_antagonism idiom): mob tier, one
## big carapace, Robustness 0 by template physique — attack nets are exact and
## its blocked bites never mutate the contestants.
func add_tanky_mob(sim: CombatSim, id: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": "roach_dog",
		"team": "enemies", "position": [0, 0],
		"body_parts": [{"key": "carapace", "name": "Carapace", "hp": 100, "lethal": true}],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## Twin-RNG replay of pick_weighted_target at the CURRENT ai_rng state (the
## test_antagonism idiom): the deterministic prediction of the next decide.
func predicted_pick(sim: CombatSim, actor_id: String) -> String:
	var actor: CombatantState = sim.combatants[actor_id]
	var opponents: Array[CombatantState] = sim.ai._opponents(actor)
	if opponents.is_empty():
		return ""
	if opponents.size() == 1:
		return opponents[0].id
	var rows: Array[Dictionary] = sim.ai.targeting_weights(actor, opponents, actor.position)
	var twin := RandomNumberGenerator.new()
	twin.state = sim.ai.ai_rng.state
	var total: float = 0.0
	for row: Dictionary in rows:
		total += float(row["weight"])
	var draw: float = twin.randf() * total
	var cumulative: float = 0.0
	for i: int in range(rows.size()):
		cumulative += float((rows[i] as Dictionary)["weight"])
		if draw < cumulative:
			return String((rows[i] as Dictionary)["id"])
	return String((rows[rows.size() - 1] as Dictionary)["id"])


func score(sim: CombatSim, holder: String, earner: String) -> float:
	return float((sim.combatants[holder] as CombatantState).antagonism.get(earner, 0.0))


# --------------------------------------------- (0) the premade DATA contract

func test_recruit_premades_match_demo_budget_and_use_only_implemented_skills() -> void:
	# Executable pins for the Part-1 design constraints: demo-comparable trait
	# budget (sum 14, 7 Body / 7 Core, max 5), ONLY implemented skills
	# (SkillBook.KNOWN_KEYS — nothing aspirational), key annotations honest
	# against skills.json, ONE authored bit between the two (decision #25
	# variety), camera_call_stacks 1 per the demo pattern, PROVISIONAL marked.
	var data: Dictionary = SimTestBase.load_json(RECRUITS_PATH)
	assert_true(String((data.get("_meta", {}) as Dictionary).get("note", "")).contains("PROVISIONAL"),
		"the file is marked PROVISIONAL for owner review in _meta.note")
	var demo: Dictionary = SimTestBase.load_json("res://data/demo_loadouts.json")
	var demo_sum: int = -1
	for lo: Variant in demo.get("loadouts", []) as Array:
		var t: Dictionary = (lo as Dictionary).get("traits", {})
		var s: int = int(t["physique"]) + int(t["reflexes"]) + int(t["mind"]) + int(t["charm"])
		if demo_sum < 0:
			demo_sum = s
		assert_eq(s, demo_sum, "precondition: the demo pair share one trait budget")
	assert_eq(demo_sum, 14, "precondition: the demo budget is 14 (7 Body / 7 Core)")

	var skills_by_id: Dictionary = {}
	for entry: Variant in SimTestBase.load_json("res://data/skills.json") as Array:
		skills_by_id[int((entry as Dictionary).get("id", -1))] = entry
	var bits: int = 0
	var keys_seen: Array[String] = []
	for lo: Variant in data.get("loadouts", []) as Array:
		var row: Dictionary = lo
		var key := String(row.get("key", "?"))
		keys_seen.append(key)
		var t: Dictionary = row.get("traits", {})
		var body: int = int(t["physique"]) + int(t["reflexes"])
		var core: int = int(t["mind"]) + int(t["charm"])
		assert_eq(body + core, demo_sum, "%s: trait sum matches the demo budget (14)" % key)
		assert_eq(body, 7, "%s: creation-legal 7 Body" % key)
		assert_eq(core, 7, "%s: creation-legal 7 Core" % key)
		for stat: String in ["physique", "reflexes", "mind", "charm"]:
			assert_true(int(t[stat]) >= 1 and int(t[stat]) <= 5, "%s: %s in 1..5" % [key, stat])
		for s: Variant in row.get("skills", []) as Array:
			var srow: Dictionary = s
			var skill_key := String(srow.get("key", ""))
			assert_true(SkillBook.is_known(skill_key),
				"%s: %s is an IMPLEMENTED skill (SkillBook.KNOWN_KEYS)" % [key, skill_key])
			var tpl: Dictionary = skills_by_id.get(int(srow.get("id", -1)), {})
			assert_eq(String(tpl.get("key", "?")), skill_key,
				"%s: skill id %d resolves to the annotated key" % [key, int(srow.get("id", -1))])
		if row.has("bit"):
			bits += 1
		assert_eq(int(row.get("camera_call_stacks", -1)), 1, "%s: camera_call_stacks 1 (demo pattern)" % key)
	keys_seen.sort()
	assert_eq(keys_seen, ["nikita_headliner", "sasha_the_tell"], "both Q68 recruits present")
	assert_eq(bits, 1, "exactly ONE of the two recruits carries an authored bit (decision #25 variety)")
	# The role split the file claims: one Mind-leaning reader (Mind 5 reaches the
	# L1 read threshold outright), one balanced bruiser-support.
	assert_eq(int((recruit_loadout("sasha_the_tell").get("traits", {}) as Dictionary).get("mind", 0)), 5,
		"Sasha is the Mind-leaning recruit (Mind 5 >= the L1 feint read threshold)")
	assert_eq(int((recruit_loadout("nikita_headliner").get("traits", {}) as Dictionary).get("physique", 0)), 4,
		"Nikita is the bruiser-support (Physique 4, +2 Force push)")


# ------------------------------------------ (1) 3-party fight, zero rejections

## Scripted mixed-command trio fight vs the REAL seeded Incinedile (dodge
## intact): skill declares off each contestant's granted kit, a free brace, a
## free move, Dario's authored bit, boss ai_decides — all readiness-guarded the
## way a real driver guards them, so every emitted command is legal. Returns
## the final hash + event counts for the assertions.
func _scripted_trio_fight(sim_seed: int) -> Dictionary:
	var sim: CombatSim = make_sim(sim_seed)
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}})
	add_imani(sim, [1, 0])
	add_dario(sim, [0, 1])
	add_recruit(sim, "sasha_the_tell", [1, -1])
	var rotations: Dictionary = {
		"imani": [
			{"kind": "skill", "key": "strong_strike", "level": 2, "attack_range": 3, "targets": [{"id": "boss", "part": "left_hand"}]},
			{"kind": "skill", "key": "overhead_slam", "level": 1, "attack_range": 3, "targets": [{"id": "boss", "part": "left_hand"}]},
		],
		"dario": [
			{"kind": "skill", "key": "feint", "level": 3, "attack_range": 3, "targets": [{"id": "boss", "part": "right_leg"}]},
			{"kind": "skill", "key": "pressure_strike", "level": 1, "attack_range": 3, "targets": [{"id": "boss", "part": "right_leg"}]},
		],
		"sasha": [
			{"kind": "skill", "key": "feint", "level": 2, "attack_range": 3, "targets": [{"id": "boss", "part": "right_leg"}]},
			{"kind": "skill", "key": "strong_strike", "level": 1, "attack_range": 3, "targets": [{"id": "boss", "part": "right_leg"}]},
		],
	}
	var next_idx: Dictionary = {"imani": 0, "dario": 0, "sasha": 0}
	var events: Array[Dictionary] = []
	for t: int in range(14):
		for id: String in ["imani", "dario", "sasha"]:
			var c: CombatantState = sim.combatants[id]
			var boss: CombatantState = sim.combatants["boss"]
			if not c.can_act(sim.clock.tick) or sim.clock.tick < c.next_action_tick or c.windup_pending:
				continue
			if not boss.alive or CombatantState.hex_distance(c.position, boss.position) > 3:
				continue
			var rot: Array = rotations[id]
			var action: Dictionary = (rot[int(next_idx[id]) % rot.size()] as Dictionary).duplicate(true)
			next_idx[id] = int(next_idx[id]) + 1
			events.append_array(declare(sim, id, action))
		if t == 0:
			events.append_array(_guarded_free_step(sim, "sasha"))
		if t == 1:
			var sasha: CombatantState = sim.combatants["sasha"]
			if sasha.can_act(sim.clock.tick) and not sasha.free_action_used:
				events.append_array(declare(sim, "sasha", {"kind": "skill", "key": "brace", "level": 2}))
		if t == 2:
			var dario: CombatantState = sim.combatants["dario"]
			if dario.can_act(sim.clock.tick) and not dario.free_action_used:
				events.append_array(sim.apply_command({"type": "bit", "actor": "dario"}))
		for aid: String in sim.ai_ready_ids():
			events.append_array(ai_decide(sim, aid))
		events.append_array(advance(sim, 1))
	var rejections: int = events_of(events, "command_rejected").size()
	return {
		"hash": sim.state_hash(),
		"rejections": rejections,
		"rejection_events": events_of(events, "command_rejected"),
		"damage": events_of(events, "damage_applied").size(),
		"decisions": events_of(events, "ai_decision").size(),
		"combatants": sim.combatants.size(),
	}


## A guarded free 1-hex move to any unoccupied adjacent hex (deterministic
## fixed scan order) — the mixed-command move without ever risking a rejection.
func _guarded_free_step(sim: CombatSim, id: String) -> Array[Dictionary]:
	var c: CombatantState = sim.combatants[id]
	if not c.can_act(sim.clock.tick) or c.free_action_used or c.moved_this_tick \
			or c.windup_pending or c.grappled_by != "" or c.grappling != "":
		return []
	var occupied: Dictionary = {}
	var ids: Array = sim.combatants.keys()
	ids.sort()
	for oid: Variant in ids:
		var o: CombatantState = sim.combatants[oid]
		if o.alive and not o.removed_from_play:
			occupied[o.position] = true
	for delta: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
		var dest: Vector2i = c.position + delta
		if not occupied.has(dest):
			return sim.apply_command({"type": "move", "actor": id, "to": [dest.x, dest.y]})
	return []


func test_three_party_fight_runs_clean_with_zero_rejections_and_valid_hash() -> void:
	var run: Dictionary = _scripted_trio_fight(1234)
	assert_eq(int(run["rejections"]), 0,
		"14 mixed ticks of trio + boss produce ZERO command rejections: %s" % str(run["rejection_events"]))
	assert_true(int(run["damage"]) > 0, "the fight is real — damage actually landed (%d hits)" % int(run["damage"]))
	assert_true(int(run["decisions"]) > 0, "the boss actually fought (%d ai decisions)" % int(run["decisions"]))
	assert_eq(int(run["combatants"]), 4, "3 contestants + the boss on the table")
	var h := String(run["hash"])
	assert_eq(h.length(), 64, "state hash is a full sha256 hex digest")
	assert_true(h.is_valid_hex_number(false), "state hash is valid hex")
	# Pure function of (seed, ordered command log): the identical script replays
	# to the identical hash.
	assert_eq(String(_scripted_trio_fight(1234)["hash"]), h,
		"same seed + same command script = same final state hash")


# --------------------------------------------------- (2) 3-way merged force

func test_three_way_merged_force_one_gate_one_hit_hand_computed() -> void:
	# R15 with THREE linked strikes (extends test_combined_force's 2-way (f)
	# acceptance). Hand-computed from the R14 formula (Force = amount +
	# floor(atk_physique / 2); Robustness = floor(tgt_physique / 2) + armor +
	# flat_res; net = max(0, sum(Forces) − Robustness)):
	#   Imani  strong_strike L1: 6 + floor(5/2) = 8
	#   Dario  pressure_strike L1: 2 + floor(2/2) = 3
	#   Nikita strong_strike L2 (granted level; recruit file): 6 + floor(4/2) = 8
	#   sum 19 vs Incinedile Robustness floor(6/2) = 3 -> ONE net-16 hit >= 7: BREACH.
	var sim: CombatSim = make_sim(14)
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": traits_without_dodge(),
	}})
	add_imani(sim, [1, 0])
	add_dario(sim, [0, 1])
	add_recruit(sim, "nikita_headliner", [1, -1])
	var nikita: CombatantState = sim.combatants["nikita"]
	assert_eq(nikita.skill_level("strong_strike"), 2, "Nikita's granted level came off the recruit file")
	# F4 (ladder pass): pressure_strike gates on its declare-time CHAIN prime —
	# Dario's own feint on the boss resolves first (L3: threshold 7 vs boss
	# Mind 1 + d4 max 5 — read impossible, zero rng; Mind 1 is below the
	# mock-sensitive gate, so no grudge enters the hand-computed shares).
	declare(sim, "dario", {"kind": "skill", "key": "feint", "level": 3, "attack_range": 1,
		"targets": [{"id": "boss", "part": "right_leg"}]})
	advance(sim, 1)
	var combo: Array[Dictionary] = sim.apply_command({"type": "combined_action", "combo_id": "trio_combo", "members": [
		{"actor": "imani", "action": {"kind": "skill", "key": "strong_strike", "level": 1,
			"attack_range": 2, "targets": [{"id": "boss", "part": "left_hand"}]}},
		{"actor": "dario", "action": {"kind": "skill", "key": "pressure_strike", "level": 1,
			"attack_range": 2, "targets": [{"id": "boss", "part": "left_hand"}]}},
		{"actor": "nikita", "action": {"kind": "skill", "key": "strong_strike", "level": nikita.skill_level("strong_strike"),
			"attack_range": 2, "targets": [{"id": "boss", "part": "left_hand"}]}},
	]})
	assert_event(combo, "combined_action_declared", "the 3-member linked declaration is accepted")
	assert_eq(events_of(combo, "action_declared").size(), 3, "all three pay their own cost-2 windup")
	var events: Array[Dictionary] = advance(sim, 3)
	var cf: Dictionary = assert_event(events, "combined_force", "the merged gate fires once on the resolve tick")
	assert_eq(String(cf.get("combo_id", "")), "trio_combo", "the caller-named combo id links all three")
	assert_eq(cf.get("actors", []), ["imani", "dario", "nikita"], "all three members connected, in declaration order")
	assert_eq(int(cf.get("force", -1)), 19, "Force sums across all THREE: 8 + 3 + 8 = 19")
	assert_eq(int(cf.get("robustness", -1)), 3, "one merged gate: Robustness floor(6/2) = 3")
	assert_eq(int(cf.get("net", -1)), 16, "net = max(0, 19 − 3) = 16")
	assert_eq(events_of(events, "damage_applied").size(), 1, "ONE merged damage application, not three")
	assert_eq(int(first_event(events, "damage_applied").get("amount", -1)), 16, "the one hit carries the merged net")
	assert_eq(events_of(events, "combined_force").size(), 1, "exactly one merged gate evaluation")
	assert_event(events, "breach_opened", "net 16 >= 7 single-hit burst — the trio opens the breach")
	var boss: CombatantState = sim.combatants["boss"]
	assert_true(boss.breached, "boss breached")
	assert_eq(int(boss.parts["left_hand"]["hp"]), 14, "left hand 30 − 16 = 14 (one wound)")
	# Every connected member's condition rides the ONE wound.
	assert_true(boss.condition_tier("left_hand", "crushed") >= 1, "the crushed components ride the wound")
	assert_eq(boss.condition_tier("left_hand", "bleeding"), 1, "Dario's bleeding rides the same wound")
	# R23: the one merged hit attributes grudge per member by Force share —
	# three ledger entries from one wound, summing exactly to the net.
	assert_eq(score(sim, "boss", "imani"), 16.0 * 8.0 / 19.0, "Imani's share = net * (8/19)")
	assert_eq(score(sim, "boss", "dario"), 16.0 * 3.0 / 19.0, "Dario's share = net * (3/19)")
	assert_eq(score(sim, "boss", "nikita"), 16.0 * 8.0 / 19.0, "Nikita's share = net * (8/19)")
	assert_eq(score(sim, "boss", "imani") + score(sim, "boss", "dario") + score(sim, "boss", "nikita"), 16.0,
		"the three shares sum exactly to the one merged net hit")


# ------------------------------------------------- (3) antagonism across 3

func test_boss_damage_from_all_three_builds_three_ledger_entries_one_draw() -> void:
	# Three solo hits, one from each contestant, all exact (Robustness 0 mob):
	# grudge = net = amount + floor(physique/2), 1:1 — THREE ledger entries.
	var sim: CombatSim = make_sim()
	add_imani(sim, [1, 0])
	add_dario(sim, [0, 1])
	add_recruit(sim, "sasha_the_tell", [1, -1])
	add_tanky_mob(sim, "mob")
	declare(sim, "imani", attack_action("crushed", 4, "mob", "carapace"))
	declare(sim, "dario", attack_action("crushed", 2, "mob", "carapace"))
	declare(sim, "sasha", attack_action("crushed", 3, "mob", "carapace"))
	var resolved: Array[Dictionary] = advance(sim, 1)
	var grudges: Array[Dictionary] = []
	for event: Dictionary in events_of(resolved, "antagonism_changed"):
		if String(event.get("source", "")) == "damage":
			grudges.append(event)
	assert_eq(grudges.size(), 3, "damage from all three built three grudge events")
	var mob: CombatantState = sim.combatants["mob"]
	assert_eq(mob.antagonism.size(), 3, "the ledger holds exactly three entries")
	assert_eq(score(sim, "mob", "imani"), 6.0, "Imani: net (4 + 2) − 0 = 6, 1:1")
	assert_eq(score(sim, "mob", "dario"), 3.0, "Dario: net (2 + 1) − 0 = 3, 1:1")
	assert_eq(score(sim, "mob", "sasha"), 4.0, "Sasha: net (3 + 1) − 0 = 4, 1:1")
	# The weighted pick over the 3 candidates consumes EXACTLY one salted
	# ai_rng draw (twin-RNG proof, test_antagonism idiom) — grudges loaded.
	var pre: int = sim.ai.ai_rng.state
	var decision: Dictionary = first_event(ai_decide(sim, "mob"), "ai_decision")
	assert_true(["imani", "dario", "sasha"].has(String(decision.get("target", ""))), "the pick is one of the three")
	var twin := RandomNumberGenerator.new()
	twin.state = pre
	twin.randf()
	assert_eq(sim.ai.ai_rng.state, twin.state, "three candidates -> exactly ONE draw consumed")


func test_targeting_weights_two_equidistant_equal_one_distant_lower() -> void:
	# Fresh sim, NO grudge: two contestants adjacent (distance 1), the recruit
	# parked at distance 3 — OFF the adjacents' lanes (the test_antagonism
	# body-block staging note), so a draw that lands on her yields an
	# attack-with-step decision that still carries the target id.
	# targeting_weights (sorted-id candidate order) must give the two close
	# candidates EXACTLY equal weight and the distant one strictly lower
	# (inverse-square: 1/9 exactly).
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [1, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 1]})
	add_recruit(sim, "sasha_the_tell", [-3, 0])
	add_tanky_mob(sim, "mob")
	var mob: CombatantState = sim.combatants["mob"]
	var candidates: Array[CombatantState] = sim.ai._opponents(mob)
	assert_eq(candidates.size(), 3, "all three contestants are candidates")
	var rows: Array[Dictionary] = sim.ai.targeting_weights(mob, candidates, mob.position)
	assert_eq(String((rows[0] as Dictionary)["id"]), "ha", "rows follow sorted-id candidate order")
	assert_eq(String((rows[1] as Dictionary)["id"]), "hb", "rows follow sorted-id candidate order")
	assert_eq(String((rows[2] as Dictionary)["id"]), "sasha", "rows follow sorted-id candidate order")
	var wa: float = float((rows[0] as Dictionary)["weight"])
	var wb: float = float((rows[1] as Dictionary)["weight"])
	var wc: float = float((rows[2] as Dictionary)["weight"])
	assert_true(wa == wb, "two equidistant fresh candidates weigh EXACTLY equal (%f vs %f)" % [wa, wb])
	assert_eq(wa, 1.0, "adjacent fresh target weighs exactly 1 (1/1^2 * 1 * 1)")
	assert_eq(wc, 1.0 / 9.0, "distance 3 -> weight 1/3^2 exactly")
	assert_true(wc < wa, "the distant candidate weighs strictly lower (%f < %f)" % [wc, wa])
	# One decide over the 3 candidates: exactly ONE draw, and the drawn target
	# matches the twin-replay prediction.
	var pre: int = sim.ai.ai_rng.state
	var expected: String = predicted_pick(sim, "mob")
	var decision: Dictionary = first_event(ai_decide(sim, "mob"), "ai_decision")
	assert_eq(String(decision.get("target", "")), expected, "the real draw matches the twin replay")
	var twin := RandomNumberGenerator.new()
	twin.state = pre
	twin.randf()
	assert_eq(sim.ai.ai_rng.state, twin.state, "the 3-candidate weighted pick is exactly ONE draw")


# --------------------------------------------------- (4) feint-read mirror

func test_no_enemy_template_carries_a_feint_today() -> void:
	# HONESTY PIN for the mirror test below: current data has NO enemy feint —
	# no template ability is keyed "feint" or carries a read_threshold, and
	# EnemyAI only picks from template abilities, so the AI never feints on its
	# own. The mirror test therefore STAGES the enemy feint through the command
	# stream (declare has no category gate) — which is exactly what it proves.
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	assert_true(enemies.size() > 0, "enemies.json loaded")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		for a: Variant in e.get("abilities", []) as Array:
			var ability: Dictionary = a
			assert_ne(String(ability.get("key", "")), "feint",
				"%s: no enemy template ability is a feint" % String(e.get("key", "")))
			assert_false(ability.has("read_threshold"),
				"%s/%s: no enemy ability carries a read threshold" % [String(e.get("key", "")), String(ability.get("key", ""))])


func test_sasha_auto_reads_a_staged_enemy_feint_r24() -> void:
	# The R24 mirror of test_feint_read, defender-side: Sasha's Mind 5 equals
	# the L1 read threshold (4 + 1 = 5) -> AUTO-read, no rng, nothing arms on
	# her, the staged feint is WASTED. The feinter is an AI-category actor
	# driven through the command stream (see the honesty pin above).
	assert_eq(int(SkillBook.mechanics("feint", 1).get("read_threshold", 0)), 5,
		"the L1 feint spec carries read threshold 4 + level = 5 (PLACEHOLDER R14)")
	var sim: CombatSim = make_sim()
	add_recruit(sim, "sasha_the_tell", [1, 0])
	add_tanky_mob(sim, "mob")
	var sasha: CombatantState = sim.combatants["sasha"]
	assert_eq(sasha.trait_total("mind"), 5, "Sasha's Mind 5 came off the recruit file")
	var state_before: int = sim.ai.ai_rng.state
	var declared: Array[Dictionary] = declare(sim, "mob", {
		"kind": "skill", "key": "feint", "level": 1, "attack_range": 1,
		"targets": [{"id": "sasha", "part": "torso"}],
	})
	assert_event(declared, "action_declared", "the staged enemy feint declares cleanly (no category gate)")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var read: Dictionary = assert_event(resolved, "feint_read", "Mind 5 >= threshold 5 auto-reads the enemy feint")
	assert_eq(String(read.get("reader", "")), "sasha", "the recruit is the reader")
	assert_eq(String(read.get("feinter", "")), "mob", "the enemy is the feinter")
	assert_true(bool(read.get("auto", false)), "auto flag set — no roll needed")
	assert_eq(int(read.get("roll", -1)), 0, "auto-read carries roll 0")
	assert_eq(int(read.get("mind", 0)), 5, "reader Mind emitted")
	assert_eq(int(read.get("threshold", 0)), 5, "threshold emitted")
	assert_no_event(resolved, "feint_applied", "a read feint never applies")
	assert_false(sasha.feint_forced, "nothing armed on the reader")
	assert_eq(sasha.feint_by, "", "no attribution armed either")
	assert_eq(sim.ai.ai_rng.state, state_before, "an auto-read consumes NO rng")
	assert_no_event(resolved, "antagonism_changed", "contestants keep no grudge ledger (R23 gate unchanged)")
	assert_true(sasha.antagonism.is_empty(), "Sasha's ledger stays empty")


func test_sasha_mind_die_arithmetic_through_check_feint_read() -> void:
	# The full R24 ladder pinned DIRECTLY through EnemyAI.check_feint_read on
	# the recruit (belt-and-braces for the staged path above):
	#   threshold 5 (L1): Mind 5 >= 5           -> auto, zero rng;
	#   threshold 7 (L3): 5 < 7, 5 + d4 = 9 >= 7 -> rolled, EXACTLY one draw,
	#                     read == (5 + roll >= 7), twin-predicted roll;
	#   threshold 10:     5 + 4 < 10             -> impossible, {} and zero rng.
	var sim: CombatSim = make_sim()
	add_recruit(sim, "sasha_the_tell", [1, 0])
	add_tanky_mob(sim, "mob")
	var sasha: CombatantState = sim.combatants["sasha"]
	assert_eq(sasha.threshold_die("mind"), 4, "no authored die grant — the default d4")
	# Auto tier.
	var pre_auto: int = sim.ai.ai_rng.state
	var auto_read: Dictionary = sim.ai.check_feint_read(sasha, 5)
	assert_true(bool(auto_read.get("read", false)), "Mind 5 vs threshold 5 auto-reads")
	assert_true(bool(auto_read.get("auto", false)), "auto flag set")
	assert_eq(sim.ai.ai_rng.state, pre_auto, "auto tier: zero rng")
	# Rolled tier (L3 threshold 7) — twin-proven single draw and value.
	var pre_roll: int = sim.ai.ai_rng.state
	var twin := RandomNumberGenerator.new()
	twin.state = pre_roll
	var expected_roll: int = twin.randi_range(1, 4)
	var rolled: Dictionary = sim.ai.check_feint_read(sasha, 7)
	assert_eq(sim.ai.ai_rng.state, twin.state, "rolled tier: EXACTLY one d4 draw")
	assert_eq(int(rolled.get("roll", -1)), expected_roll, "the emitted roll IS the stream's next d4")
	assert_eq(bool(rolled.get("read", false)), 5 + expected_roll >= 7, "read == (Mind 5 + roll >= 7)")
	assert_false(bool(rolled.get("auto", true)), "a rolled read is not auto")
	# Impossible tier.
	var pre_imp: int = sim.ai.ai_rng.state
	var impossible: Dictionary = sim.ai.check_feint_read(sasha, 10)
	assert_true(impossible.is_empty(), "Mind 5 + d4 max 9 < 10 — impossible returns {}")
	assert_eq(sim.ai.ai_rng.state, pre_imp, "impossible tier: zero rng")


# ------------------------------------------------------ (5) serialization

func test_serialization_three_party_midfight_with_antagonism_replays_identically() -> void:
	# Mid-fight snapshot with THREE party members and a 3-entry antagonism
	# ledger (damage grudges from all three + the mob's own live draws), then
	# restore -> identical hash, lockstep tail -> identical hash.
	var sim: CombatSim = make_sim(4242)
	add_imani(sim, [1, 0])
	add_dario(sim, [0, 1])
	add_recruit(sim, "sasha_the_tell", [1, -1])
	add_tanky_mob(sim, "mob", {"personality": {"mock_sensitive": true, "decay": 0.5}})
	declare(sim, "imani", attack_action("crushed", 4, "mob", "carapace"))
	declare(sim, "dario", attack_action("crushed", 2, "mob", "carapace"))
	declare(sim, "sasha", attack_action("crushed", 3, "mob", "carapace"))
	advance(sim, 1)
	ai_decide(sim, "mob")  # consume a live weighted draw so ai_rng is mid-stream
	advance(sim, 1)
	var mob: CombatantState = sim.combatants["mob"]
	assert_eq(mob.antagonism.size(), 3, "precondition: all three party members are on the ledger")
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical mid-fight")
	for id: String in ["imani", "dario", "sasha"]:
		assert_eq(float((restored.combatants["mob"] as CombatantState).antagonism.get(id, -1.0)),
			score(sim, "mob", id), "%s's grudge survives the roundtrip" % id)
	# Lockstep tail: identical commands into both sims — declares, live weighted
	# decides, Clock-boundary decay (0.5) — must end on the identical hash.
	for i: int in range(8):
		for target: CombatSim in [sim, restored]:
			declare(target, "imani", attack_action("crushed", 1, "mob", "carapace"))
			ai_decide(target, "mob")
			advance(target, 1)
	assert_eq(restored.state_hash(), sim.state_hash(), "lockstep tails end on the same hash")
	assert_true((restored.combatants["mob"] as CombatantState).antagonism.size() >= 1,
		"the replayed tail kept a live ledger (decay 0.5 ran on both)")


# ------------------------------------------------------- (6) explosion blast

func test_explosion_blast_catches_all_three_in_radius() -> void:
	# Decision #27 choreography with a FULL party of three parked inside the
	# phase-2 radius (5): the blast knocks out ALL THREE — three
	# explosion_knockout events, each Helpless for exactly 2 Clocks, no damage,
	# no death — and the boss is never caught in its own blast.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": traits_without_dodge(),
	}})
	add_imani(sim, [1, 0])
	add_dario(sim, [0, 1])
	add_recruit(sim, "sasha_the_tell", [1, -1])
	# Valve-I entry (the enter_valve_one staging, driven by Imani's Physique 5):
	# right hand: Force 10 + 2 = 12 − Robustness 3 = net 9 >= 7 -> BREACH;
	# network: Force 16 + 2 = 18 − 3 = net 15 -> 50 -> 35 -> phase 2 valve opens.
	declare(sim, "imani", attack_action("crushed", 10, "boss", "right_hand"))
	advance(sim, 1)
	declare(sim, "imani", attack_action("crushed", 16, "boss", "network"))
	var entry: Array[Dictionary] = advance(sim, 1)
	assert_event(entry, "boss_phase_changed", "precondition: the valve really opened")
	assert_eq(int((sim.combatants["boss"] as CombatantState).parts["network"]["hp"]), 35,
		"network driven exactly to the phase-2 threshold")
	# Telegraph, two escape Moments (nobody runs — all three stay parked at
	# distance 1, well inside radius 5), then the blast.
	var steam: Dictionary = assert_event(ai_decide(sim, "boss"), "explosion_telegraph", "the valve telegraphs")
	assert_eq(int(steam.get("radius", 0)), 5, "seeded phase-2 radius")
	assert_eq(int(steam.get("moments_until_blast", 0)), 3, "telegraph + 2 escape Moments")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	var blast_tick: int = sim.clock.tick
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "explosion_blast", "the blast resolved after the window")
	var knockouts: Dictionary = {}
	for event: Dictionary in events_of(blast_events, "explosion_knockout"):
		knockouts[String(event.get("combatant", ""))] = int(event.get("helpless_until_tick", 0))
	assert_eq(knockouts.size(), 3, "THREE knockout events — the blast caught the whole party")
	var until: int = blast_tick + 2 * Clock.TICKS_PER_CLOCK
	for id: String in ["imani", "dario", "sasha"]:
		assert_eq(int(knockouts.get(id, -1)), until, "%s is Helpless for exactly 2 Clocks" % id)
		assert_true((sim.combatants[id] as CombatantState).is_helpless(sim.clock.tick),
			"%s is Helpless at the blast tick" % id)
	assert_false(knockouts.has("boss"), "the boss is never caught in its own blast")
	assert_false((sim.combatants["boss"] as CombatantState).is_helpless(sim.clock.tick), "the boss keeps acting")
	assert_no_event(blast_events, "damage_applied", "knockout only — no damage (owner ruling)")
	assert_no_event(blast_events, "combatant_died", "and no death")
	# Exactly 2 Clocks: Helpless through the window's last tick, all three
	# acting again the tick after.
	advance(sim, 2 * Clock.TICKS_PER_CLOCK - 1)
	for id: String in ["imani", "dario", "sasha"]:
		assert_true((sim.combatants[id] as CombatantState).is_helpless(sim.clock.tick),
			"%s still Helpless on the window's last tick" % id)
	assert_rejected(declare(sim, "sasha", attack_action("crushed", 1, "boss", "left_leg")),
		"helpless", "a knocked-out recruit cannot act")
	advance(sim, 1)
	for id: String in ["imani", "dario", "sasha"]:
		assert_false((sim.combatants[id] as CombatantState).is_helpless(sim.clock.tick),
			"%s recovered after exactly 2 Clocks" % id)
	assert_event(declare(sim, "sasha", attack_action("crushed", 1, "boss", "left_leg")),
		"action_declared", "and the recruit can act again")
