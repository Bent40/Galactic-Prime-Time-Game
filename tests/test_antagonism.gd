extends SimTestBase
## R23 — the Antagonism engine (decision-log #29, owner 2026-07-23).
## Targeting is a weighted-random draw over sorted candidates — SUPERSEDES the
## nearest → lowest-HP → id cascade of R11 #16 for ALL AI tiers:
##   weight = proximity_factor * grudge_factor * hp_factor
## The anchor invariants pinned here ARE the contract:
##   * two equally close targets with no history draw at exactly even odds
##     (weights exactly equal — unit-assertable via targeting_weights);
##   * closer is much likelier (inverse-square at the default bias, exact);
##   * enough grudge overcomes distance;
##   * rng cost: a decide with >= 2 candidates consumes EXACTLY ONE salted
##     ai_rng draw, a single candidate consumes ZERO (twin-RNG proven);
##   * grudge sources: net damage 1:1 (blocked-to-0 = nothing; merged strikes
##     attribute per member by Force share) and Feint mockery (personality-
##     gated: mock_sensitive, default Mind >= 3); decay multiplies at the
##     Clock reset; everything serialized, hash-covered, replay-identical.


func add_enemy(sim: CombatSim, id: String, enemy_key: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": enemy_key,
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


## A durable, harmless AI punching bag: mob tier, one big carapace, physique 1
## (Robustness 0 — attack nets are exact), bite force 1 (blocked by any
## phys-2+ contestant, so replayed decides never mutate the humans).
func add_tanky_mob(sim: CombatSim, id: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"body_parts": [{"key": "carapace", "name": "Carapace", "hp": 40, "lethal": true}],
	}
	spec.merge(overrides, true)
	return add_enemy(sim, id, "roach_dog", spec)


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func feint(sim: CombatSim, actor: String, target: String) -> Array[Dictionary]:
	declare(sim, actor, {
		"kind": "skill", "key": "feint", "level": 1, "attack_range": 1,
		"targets": [{"id": target, "part": "torso"}],
	})
	return advance(sim, 1)


func antagonism_events(events: Array[Dictionary], source: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in events_of(events, "antagonism_changed"):
		if source == "" or String(event.get("source", "")) == source:
			out.append(event)
	return out


func score(sim: CombatSim, holder: String, earner: String) -> float:
	return float((sim.combatants[holder] as CombatantState).antagonism.get(earner, 0.0))


## Twin-RNG replay of pick_weighted_target at the CURRENT ai_rng state: the
## deterministic prediction of what the actor's next decide will target.
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


# ---------------------------------------------------------------- the 50/50 anchor

func test_equal_weights_are_exactly_equal() -> void:
	# The canon anchor is EXACT equality by construction, not a statistic: two
	# equally close fresh targets, default personality -> identical weights.
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [1, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 1]})
	add_tanky_mob(sim, "mob")
	var mob: CombatantState = sim.combatants["mob"]
	var candidates: Array[CombatantState] = sim.ai._opponents(mob)
	assert_eq(candidates.size(), 2, "both contestants are candidates")
	var rows: Array[Dictionary] = sim.ai.targeting_weights(mob, candidates, mob.position)
	var wa: float = float((rows[0] as Dictionary)["weight"])
	var wb: float = float((rows[1] as Dictionary)["weight"])
	assert_true(wa == wb, "equal distance + no history + no bias -> weights EXACTLY equal (%f vs %f)" % [wa, wb])
	assert_eq(wa, 1.0, "adjacent fresh target weighs exactly 1 (1/1^2 * 1 * 1)")


func test_fifty_fifty_anchor_statistical() -> void:
	# Replay the SAME decide across 200 successive rng states: the blocked-to-0
	# bite (force 1 vs phys-3 Robustness 1) never mutates the humans, so every
	# tick re-poses the identical two-candidate 50/50 question one draw further
	# down the salted stream. Both targets must be picked many times.
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [1, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 1]})
	add_tanky_mob(sim, "mob")
	var picks: Dictionary = {"ha": 0, "hb": 0}
	for i: int in range(200):
		var decision: Dictionary = first_event(ai_decide(sim, "mob"), "ai_decision")
		var target := String(decision.get("target", ""))
		picks[target] = int(picks.get(target, 0)) + 1
		advance(sim, 1)
	assert_eq(int(picks["ha"]) + int(picks["hb"]), 200, "every decide picked one of the two")
	assert_true(int(picks["ha"]) >= 60, "ha picked often (%d/200 — 50/50 anchor)" % int(picks["ha"]))
	assert_true(int(picks["hb"]) >= 60, "hb picked often (%d/200 — 50/50 anchor)" % int(picks["hb"]))
	assert_true(score(sim, "mob", "ha") == 0.0 and score(sim, "mob", "hb") == 0.0,
		"the blocked bites built no grudge — the 200 draws stayed unbiased")


# ---------------------------------------------------------------- proximity

func test_closer_is_much_likelier_inverse_square() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h_far", {"team": "party", "position": [3, 0]})
	add_human(sim, "h_near", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim, "mob")
	var mob: CombatantState = sim.combatants["mob"]
	var rows: Array[Dictionary] = sim.ai.targeting_weights(mob, sim.ai._opponents(mob), mob.position)
	# Sorted-id order: h_far first. Default proximity_bias 2.0 = inverse-square.
	assert_eq(String((rows[0] as Dictionary)["id"]), "h_far", "rows follow sorted-id candidate order")
	assert_eq(float((rows[0] as Dictionary)["weight"]), 1.0 / 9.0, "distance 3 -> weight 1/3^2 exactly")
	assert_eq(float((rows[1] as Dictionary)["weight"]), 1.0, "distance 1 -> weight 1 exactly")
	# An authored proximity_bias is honored: bias 1.0 relaxes to inverse-linear.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "h_far", {"team": "party", "position": [3, 0]})
	add_human(sim2, "h_near", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim2, "mob", {"personality": {"proximity_bias": 1.0}})
	var mob2: CombatantState = sim2.combatants["mob"]
	var rows2: Array[Dictionary] = sim2.ai.targeting_weights(mob2, sim2.ai._opponents(mob2), mob2.position)
	assert_eq(float((rows2[0] as Dictionary)["weight"]), 1.0 / 3.0, "authored bias 1.0 -> 1/3 exactly")


# ---------------------------------------------------------------- grudge

func test_damage_builds_grudge_equal_to_net_and_blocked_builds_nothing() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim, "mob")
	# Net = force − Robustness = (4 + floor(3/2)) − 0 = 5: grudge is the NET, 1:1.
	declare(sim, "h", attack_action("crushed", 4, "mob", "carapace"))
	var hit: Array[Dictionary] = advance(sim, 1)
	var changed: Dictionary = assert_event(hit, "antagonism_changed", "damage emitted the grudge event")
	assert_eq(String(changed.get("actor", "")), "mob", "the mob is the one remembering")
	assert_eq(String(changed.get("target", "")), "h", "keyed by who earned it")
	assert_eq(float(changed.get("delta", 0.0)), 5.0, "delta = the net damage, 1:1 (PLACEHOLDER R14)")
	assert_eq(float(changed.get("score", 0.0)), 5.0, "new score carried on the event")
	assert_eq(String(changed.get("source", "")), "damage", "source tagged")
	assert_eq(score(sim, "mob", "h"), 5.0, "score landed on the combatant state")
	# Grudge accumulates: another net-3 hit -> 8 total.
	declare(sim, "h", attack_action("crushed", 2, "mob", "carapace"))
	advance(sim, 1)
	assert_eq(score(sim, "mob", "h"), 8.0, "grudge accumulates hit over hit")
	# A hit BLOCKED to 0 builds nothing: phys-8 mob (Robustness 4) vs force 2.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "h", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim2, "brick", {"traits": {"physique": 8, "reflexes": 2, "mind": 0, "charm": 0}})
	declare(sim2, "h", attack_action("crushed", 1, "brick", "carapace"))
	var blocked: Array[Dictionary] = advance(sim2, 1)
	assert_event(blocked, "attack_no_wound", "the hit was blocked by Robustness")
	assert_no_event(blocked, "antagonism_changed", "a blocked hit teaches the mob nothing")
	assert_true((sim2.combatants["brick"] as CombatantState).antagonism.is_empty(), "no score, no key")
	# A non-AI victim never holds a grudge (contestants are not this engine).
	var sim3: CombatSim = make_sim()
	add_human(sim3, "a", {"team": "party", "position": [0, 0]})
	add_human(sim3, "b", {"team": "blue", "position": [1, 0]})
	declare(sim3, "a", attack_action("crushed", 4, "b", "torso"))
	var pvp: Array[Dictionary] = advance(sim3, 1)
	assert_event(pvp, "damage_applied", "the contestant-on-contestant hit landed")
	assert_no_event(pvp, "antagonism_changed", "only AI combatants keep antagonism")
	assert_true((sim3.combatants["b"] as CombatantState).antagonism.is_empty(), "no grudge on a contestant")


func test_merged_strike_attributes_grudge_per_member_by_force_share() -> void:
	# R15 merged hit: ONE net wound, but R23 attributes the grudge per member
	# proportionally to the Force each contributed. Phys-4 mob (Robustness 2):
	# Imani-shaped force 6 + Dario-shaped force 4 = 10 -> net 8; shares 4.8 / 3.2.
	var sim: CombatSim = make_sim()
	add_human(sim, "ia", {"team": "party", "position": [1, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "db", {"team": "party", "position": [0, 1],
		"traits": {"physique": 5, "reflexes": 3, "mind": 3, "charm": 3}})
	add_tanky_mob(sim, "mob", {"traits": {"physique": 4, "reflexes": 2, "mind": 0, "charm": 0}})
	sim.apply_command({"type": "combined_action", "members": [
		{"actor": "ia", "action": attack_action("crushed", 5, "mob", "carapace")},
		{"actor": "db", "action": attack_action("crushed", 2, "mob", "carapace")},
	]})
	var resolved: Array[Dictionary] = advance(sim, 1)
	var merged: Dictionary = assert_event(resolved, "combined_force", "the linked strikes merged")
	assert_eq(int(merged.get("net", 0)), 8, "merged net: (6 + 4) − Robustness 2 = 8")
	var grudges: Array[Dictionary] = antagonism_events(resolved, "damage")
	assert_eq(grudges.size(), 2, "each contributing member earned its own grudge event")
	assert_eq(score(sim, "mob", "ia"), 8.0 * 6.0 / 10.0, "ia's share = net * (its force 6 / 10)")
	assert_eq(score(sim, "mob", "db"), 8.0 * 4.0 / 10.0, "db's share = net * (its force 4 / 10)")
	assert_eq(score(sim, "mob", "ia") + score(sim, "mob", "db"), 8.0,
		"the shares sum exactly to the one merged net hit")


func test_grudge_overcomes_distance() -> void:
	# `near` sits OFF the straight lane to `far` so the greedy free-move plan
	# toward the antagonist is never body-blocked by the alternative target.
	var sim: CombatSim = make_sim()
	add_human(sim, "far", {"team": "party", "position": [4, 0]})
	add_human(sim, "near", {"team": "party", "position": [0, 1]})
	# 100 HP so the two net-20 grudge-building hits never kill it.
	add_tanky_mob(sim, "mob", {"body_parts": [{"key": "carapace", "name": "Carapace", "hp": 100, "lethal": true}]})
	var mob: CombatantState = sim.combatants["mob"]
	# Fresh: the far target is 1/16 as likely (inverse-square) — distance rules,
	# and at this known rng state (seed 1234's salted stream: first randf
	# 0.9984) the fresh decide provably goes for the NEAR one.
	var rows: Array[Dictionary] = sim.ai.targeting_weights(mob, sim.ai._opponents(mob), mob.position)
	assert_eq(float((rows[0] as Dictionary)["weight"]), 1.0 / 16.0, "fresh far weight 1/16")
	assert_eq(predicted_pick(sim, "mob"), "near", "no history -> the draw stays with proximity")
	var fresh: Dictionary = first_event(ai_decide(sim, "mob"), "ai_decision")
	assert_eq(String(fresh.get("target", "")), "near", "the fresh mob bites the adjacent target")
	advance(sim, 1)
	# The far contestant bashes its head in: net 20 twice -> grudge 40. The far
	# weight becomes (1 + 40)/16 = 2.5625 — it now OUTWEIGHS the adjacent 1.0.
	for i: int in range(2):
		declare(sim, "far", attack_action("crushed", 19, "mob", "carapace", {"attack_range": 4}))
		advance(sim, 1)
	assert_eq(score(sim, "mob", "far"), 40.0, "two net-20 hits -> grudge 40")
	rows = sim.ai.targeting_weights(mob, sim.ai._opponents(mob), mob.position)
	var w_far: float = float((rows[0] as Dictionary)["weight"])
	var w_near: float = float((rows[1] as Dictionary)["weight"])
	assert_eq(w_far, (1.0 + 40.0) / 16.0, "far weight = grudge_factor / distance^2 exactly")
	assert_true(w_far > w_near, "enough grudge OVERCOMES distance (%f > %f)" % [w_far, w_near])
	# And the decide at this known rng state (second draw of the stream: 0.113 <
	# far's 41/57 share) actually goes for the far one — predicted by the twin
	# replay, then confirmed against the real decision.
	var expected: String = predicted_pick(sim, "mob")
	assert_eq(expected, "far", "at the live state the draw lands on the grudge")
	var decision: Dictionary = first_event(ai_decide(sim, "mob"), "ai_decision")
	assert_eq(String(decision.get("target", "")), "far", "the mob goes for its antagonist")
	assert_true(bool(decision.get("moves", false)),
		"and MOVES toward it despite an adjacent alternative (the nearest fallback is gone)")


# ---------------------------------------------------------------- mockery (Feint)

func test_feint_mockery_is_personality_gated() -> void:
	# A mock-SENSITIVE mob takes the insult: authored flag, default mock_grudge 2.
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim, "mob", {"personality": {"mock_sensitive": true}})
	var mocked: Array[Dictionary] = feint(sim, "trick", "mob")
	assert_event(mocked, "feint_applied", "the feint resolved")
	var changed: Dictionary = assert_event(mocked, "antagonism_changed", "mockery built grudge")
	assert_eq(String(changed.get("source", "")), "mockery", "source tagged mockery")
	assert_eq(float(changed.get("delta", 0.0)), 2.0, "default mock_grudge 2.0")
	assert_eq(score(sim, "mob", "trick"), 2.0, "the insult landed on the state")
	# An authored mock_grudge overrides the default.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "trick", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim2, "mob", {"personality": {"mock_sensitive": true, "mock_grudge": 5.0}})
	feint(sim2, "trick", "mob")
	assert_eq(score(sim2, "mob", "trick"), 5.0, "authored mock_grudge honored")
	# mock_sensitive DEFAULTS from Mind >= 3 when unauthored (the intelligence gate).
	var sim3: CombatSim = make_sim()
	add_human(sim3, "trick", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim3, "clever", {"traits": {"physique": 1, "reflexes": 2, "mind": 3, "charm": 0}})
	assert_true((sim3.combatants["clever"] as CombatantState).personality_mock_sensitive(),
		"Mind 3 with no authored personality derives mock-sensitive")
	feint(sim3, "trick", "clever")
	assert_eq(score(sim3, "clever", "trick"), 2.0, "the clever mob gets the insult")


func test_incinedile_is_too_dim_for_mockery() -> void:
	# Mind 1, authored mock_sensitive false — the boss gains NOTHING from a
	# Feint (it remembers pain, not words).
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "boss", "incinedile")
	var boss: CombatantState = sim.combatants["boss"]
	assert_false(boss.personality_mock_sensitive(), "authored mock_sensitive false (Mind 1)")
	assert_eq(boss.personality_decay(), 1.0, "and decay 1.0 — it remembers pain")
	var mocked: Array[Dictionary] = feint(sim, "trick", "boss")
	assert_event(mocked, "feint_applied", "the feint itself still lands (feint_forced)")
	assert_no_event(mocked, "antagonism_changed", "no grudge from words")
	assert_true(boss.antagonism.is_empty(), "the boss's ledger stays empty")


# ---------------------------------------------------------------- rng discipline

func test_decide_rng_cost_one_draw_multi_zero_single() -> void:
	# >= 2 candidates: EXACTLY one randf, twin-proven (attack-in-reach shape).
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [1, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 1]})
	add_tanky_mob(sim, "mob")
	var pre: int = sim.ai.ai_rng.state
	ai_decide(sim, "mob")
	var twin := RandomNumberGenerator.new()
	twin.state = pre
	twin.randf()
	assert_eq(sim.ai.ai_rng.state, twin.state, "two candidates -> exactly ONE draw consumed")
	# >= 2 candidates out of reach (move decision): STILL exactly one draw —
	# the same pick feeds both the strike check and the move goal.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "ha", {"team": "party", "position": [5, 0]})
	add_human(sim2, "hb", {"team": "party", "position": [6, 0]})
	add_tanky_mob(sim2, "mob")
	var pre2: int = sim2.ai.ai_rng.state
	var decision2: Dictionary = first_event(ai_decide(sim2, "mob"), "ai_decision")
	assert_eq(String(decision2.get("choice", "")), "move", "out of reach -> close toward the pick")
	var twin2 := RandomNumberGenerator.new()
	twin2.state = pre2
	twin2.randf()
	assert_eq(sim2.ai.ai_rng.state, twin2.state, "a move-toward-the-pick decide is still ONE draw")
	# Single candidate: ZERO draws.
	var sim3: CombatSim = make_sim()
	add_human(sim3, "h", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim3, "mob")
	var pre3: int = sim3.ai.ai_rng.state
	var decision3: Dictionary = first_event(ai_decide(sim3, "mob"), "ai_decision")
	assert_eq(String(decision3.get("choice", "")), "attack", "the lone target is attacked")
	assert_eq(sim3.ai.ai_rng.state, pre3, "a single-candidate decide consumes NO rng")
	# Grapple lock: two contestants on the board but the lock leaves ONE
	# candidate -> zero draws.
	var sim4: CombatSim = make_sim()
	add_human(sim4, "grappler", {"team": "party", "position": [1, 0],
		"traits": {"physique": 9, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim4, "other", {"team": "party", "position": [0, 1]})
	add_tanky_mob(sim4, "mob")
	declare(sim4, "grappler", {"kind": "grapple", "target": "mob"})
	advance(sim4, 1)
	var pre4: int = sim4.ai.ai_rng.state
	var decision4: Dictionary = first_event(ai_decide(sim4, "mob"), "ai_decision")
	assert_eq(String(decision4.get("target", "")), "grappler", "the grapple lock holds (R9)")
	assert_eq(sim4.ai.ai_rng.state, pre4, "the locked single candidate consumes NO rng")
	# A no-targeting decision (the elite's opening summon) consumes ZERO.
	var sim5: CombatSim = make_sim()
	add_human(sim5, "ha", {"team": "party", "position": [2, 0]})
	add_human(sim5, "hb", {"team": "party", "position": [0, 2]})
	add_enemy(sim5, "elite", "little_brother_roach")
	var pre5: int = sim5.ai.ai_rng.state
	var decision5: Dictionary = first_event(ai_decide(sim5, "elite"), "ai_decision")
	assert_eq(String(decision5.get("choice", "")), "summon", "the brood-tender summons first")
	assert_eq(sim5.ai.ai_rng.state, pre5, "a summon decision consumes NO rng")


# ---------------------------------------------------------------- decay

func test_decay_multiplies_at_the_clock_boundary() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim, "fickle", {"personality": {"decay": 0.5}})
	declare(sim, "h", attack_action("crushed", 5, "fickle", "carapace"))
	advance(sim, 1)
	assert_eq(score(sim, "fickle", "h"), 6.0, "net 6 grudge on the board (tick 0)")
	# Ticks 1..9 complete Clock 1: the reset halves the score once.
	var boundary: Array[Dictionary] = advance(sim, 9)
	assert_event(boundary, "clock_reset", "the Clock completed")
	var decayed: Dictionary = {}
	for event: Dictionary in antagonism_events(boundary, "decay"):
		if String(event.get("actor", "")) == "fickle":
			decayed = event
	assert_false(decayed.is_empty(), "ONE summary decay event for the actor (documented policy)")
	assert_eq(float(decayed.get("factor", 0.0)), 0.5, "the personality decay factor is reported")
	assert_eq(float((decayed.get("scores", {}) as Dictionary).get("h", 0.0)), 3.0, "the summary carries the new map")
	assert_eq(score(sim, "fickle", "h"), 3.0, "6 * 0.5 = 3 after one Clock")
	var second: Array[Dictionary] = advance(sim, 10)
	assert_event(second, "clock_reset", "second Clock completed")
	assert_eq(score(sim, "fickle", "h"), 1.5, "3 * 0.5 = 1.5 after the second Clock")
	# Default decay 1.0 (incinedile — remembers pain): no decay, NO summary event.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "h", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim2, "grudgeful")
	declare(sim2, "h", attack_action("crushed", 5, "grudgeful", "carapace"))
	advance(sim2, 1)
	var boundary2: Array[Dictionary] = advance(sim2, 9)
	assert_event(boundary2, "clock_reset", "the Clock completed")
	assert_eq(antagonism_events(boundary2, "decay").size(), 0, "decay 1.0 emits nothing")
	assert_eq(score(sim2, "grudgeful", "h"), 6.0, "the grudge survives the reset intact")


# ---------------------------------------------------------------- serialization + determinism

func test_serialization_roundtrip_mid_fight_with_scores() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "far", {"team": "party", "position": [4, 0]})
	add_human(sim, "near", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim, "mob", {"personality": {"mock_sensitive": true, "decay": 0.5}})
	declare(sim, "far", attack_action("crushed", 6, "mob", "carapace", {"attack_range": 4}))
	advance(sim, 1)
	feint(sim, "near", "mob")
	ai_decide(sim, "mob")  # consume a live draw so ai_rng.state is mid-stream
	advance(sim, 1)
	assert_true(score(sim, "mob", "far") > 0.0 and score(sim, "mob", "near") > 0.0,
		"both grudge sources live in the snapshot")
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical mid-fight")
	assert_eq(float((restored.combatants["mob"] as CombatantState).antagonism.get("far", 0.0)),
		score(sim, "mob", "far"), "scores survive the roundtrip")
	assert_eq((restored.combatants["mob"] as CombatantState).personality_decay(), 0.5,
		"the personality block survives the roundtrip")
	# Lockstep tail: the restored sim replays the identical weighted draws.
	for i: int in range(6):
		ai_decide(sim, "mob")
		ai_decide(restored, "mob")
		advance(sim, 1)
		advance(restored, 1)
	assert_eq(restored.state_hash(), sim.state_hash(), "lockstep tails end on the same hash")
	# Mutation teeth: tampered antagonism/personality must change the hash.
	var tampered: Dictionary = sim.to_dict()
	(((tampered["combatants"] as Dictionary)["mob"] as Dictionary))["antagonism"] = {"far": 999.0}
	assert_ne(CombatSim.from_dict(tampered).state_hash(), sim.state_hash(),
		"antagonism is covered by the state hash")
	var tampered2: Dictionary = sim.to_dict()
	(((tampered2["combatants"] as Dictionary)["mob"] as Dictionary))["personality"] = {"decay": 0.25}
	assert_ne(CombatSim.from_dict(tampered2).state_hash(), sim.state_hash(),
		"personality is covered by the state hash")


func test_determinism_same_seed_same_log_same_hash() -> void:
	var hash_a: String = _scripted_skirmish_hash(4242)
	var hash_b: String = _scripted_skirmish_hash(4242)
	assert_eq(hash_a, hash_b, "same (seed, command log) twice -> identical final hash")
	assert_ne(_scripted_skirmish_hash(4243), hash_a, "a different seed diverges (draws are live)")


## A fixed skirmish with every R23 surface in the log: damage grudge, mockery,
## decay, weighted multi-candidate draws, movement — 15 ticks, no driver rng.
func _scripted_skirmish_hash(sim_seed: int) -> String:
	var sim: CombatSim = make_sim(sim_seed)
	add_human(sim, "far", {"team": "party", "position": [4, 0]})
	add_human(sim, "near", {"team": "party", "position": [1, 0]})
	add_tanky_mob(sim, "mob", {"personality": {"mock_sensitive": true, "decay": 0.5}})
	add_tanky_mob(sim, "mob2", {"position": [0, -1]})
	for tick: int in range(15):
		if tick == 0:
			declare(sim, "far", attack_action("crushed", 6, "mob", "carapace", {"attack_range": 4}))
		elif tick == 1:
			declare(sim, "near", {
				"kind": "skill", "key": "feint", "level": 1, "attack_range": 1,
				"targets": [{"id": "mob", "part": "carapace"}],
			})
		elif tick == 3:
			declare(sim, "far", attack_action("crushed", 3, "mob2", "carapace", {"attack_range": 5}))
		for id: String in sim.ai_ready_ids():
			ai_decide(sim, id)
		advance(sim, 1)
	return sim.state_hash()
