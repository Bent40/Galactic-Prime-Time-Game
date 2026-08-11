extends SimTestBase
## Wave 3a — R15 pack synergy (enemy combos) + the AI stance substrate, the
## last two R11 "still open" engine items (docs/rules-addendum.md R11 tail).
##
## PACK SYNERGY contract pinned here (simulation/enemy_ai.gd _link_pack_strike):
##   * personality-gated (pack_hunter + shared non-empty pack family — the
##     explicit key, authored on roach_dog; elites/bosses are NOT pack hunters);
##   * OPPORTUNISTIC: each pack hunter's own R23 draw picks its victim; only
##     AGREEING draws link (no draw-forcing, ZERO extra rng — twin-proven);
##   * the second decide sees the first's pending declare (clock.queue) and
##     links deterministically: shared combo_id -> the EXISTING R15 merged-force
##     path (one summed Force through one Robustness gate), part agreement
##     adopted from the first;
##   * pairs only in v1 — a third packmate strikes solo (PLACEHOLDER R14 for
##     wider packs);
##   * serialized mid-tick (the combo_id rides the queue), replay-identical.
##
## STANCE substrate pinned here (the readable layer aura_reading needs — the
## SKILL itself rides the content pass): every decide writes a serialized,
## hash-covered ai_stance from the documented table (EnemyAI header), exposed
## additively on view_combatants (AI rows only).
##
## Hand-computed pin used throughout: roach bite Force = amount 1 +
## floor(phys 1 / 2) = 1; human victim Robustness = floor(phys 3 / 2) = 1.
## Solo bite: 1 <= 1 -> BLOCKED (attack_no_wound). Linked pair: 1 + 1 = 2 > 1
## -> ONE merged net-1 hit + the bleeding riders — the pack opens the wound no
## lone roach can.


func add_enemy(sim: CombatSim, id: String, enemy_key: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": enemy_key,
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func add_roach(sim: CombatSim, id: String, pos: Array, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {"position": pos}
	spec.merge(overrides, true)
	return add_enemy(sim, id, "roach_dog", spec)


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func torso_hp(sim: CombatSim, id: String) -> int:
	return int(((sim.combatants[id] as CombatantState).parts["torso"] as Dictionary).get("hp", 0))


## The pending scheduled entry declared by `actor_id`, {} when none.
func queue_entry_for(sim: CombatSim, actor_id: String) -> Dictionary:
	for entry: Dictionary in sim.clock.queue:
		if String(entry["actor"]) == actor_id:
			return entry
	return {}


# ------------------------------------------------------------- the linked pair

func test_agreeing_pack_hunters_link_into_one_merged_gated_hit() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim, "roach_a", [1, 0])
	add_roach(sim, "roach_b", [0, 1])
	assert_true((sim.combatants["roach_a"] as CombatantState).personality_pack_hunter(),
		"the authored roach template is a pack hunter")
	assert_eq((sim.combatants["roach_a"] as CombatantState).personality_pack(), "roach",
		"the authored pack family is 'roach' (the explicit personality key)")
	# First decide: a plain solo declare — no partner pending yet, no event.
	var first: Array[Dictionary] = ai_decide(sim, "roach_a")
	assert_event(first, "action_declared", "the first roach declares its bite")
	assert_no_event(first, "pack_synergy", "nothing to link to yet")
	# Second decide: the single-candidate pick AGREES -> the strikes link.
	var second: Array[Dictionary] = ai_decide(sim, "roach_b")
	assert_event(second, "action_declared", "the second roach declares too")
	var synergy: Dictionary = assert_event(second, "pack_synergy", "the pack converged")
	assert_eq(synergy.get("members", []), ["roach_a", "roach_b"], "members: first declarer, then joiner")
	assert_eq(String(synergy.get("target", "")), "victim", "the agreed victim")
	assert_eq(String(synergy.get("part", "")), "torso", "the agreed part (the first's pick)")
	assert_eq(String(synergy.get("combo_id", "")), "pack:0:0",
		"deterministic combo id: pack:<tick>:<seq of the first entry>")
	# Both PENDING entries carry the shared combo_id (mid-tick linkage is state).
	var entry_a: Dictionary = queue_entry_for(sim, "roach_a")
	var entry_b: Dictionary = queue_entry_for(sim, "roach_b")
	assert_eq(String((entry_a["action"] as Dictionary).get("combo_id", "")), "pack:0:0", "first entry tagged")
	assert_eq(String((entry_b["action"] as Dictionary).get("combo_id", "")), "pack:0:0", "second entry tagged")
	# Resolution: ONE merged hit through the existing R15 path. Hand pin:
	# Force 1 + 1 = 2 vs Robustness floor(3/2) = 1 -> net 1 (a solo bite is
	# BLOCKED at 1 <= 1 — the pack opens the wound no lone roach can).
	var resolved: Array[Dictionary] = advance(sim, 1)
	var merged: Dictionary = assert_event(resolved, "combined_force", "the linked bites merged")
	assert_eq(String(merged.get("combo_id", "")), "pack:0:0", "merged under the pack combo")
	assert_eq(int(merged.get("force", 0)), 2, "summed Force 1 + 1")
	assert_eq(int(merged.get("robustness", 0)), 1, "ONE Robustness gate")
	assert_eq(int(merged.get("net", 0)), 1, "net 1 through the gate")
	assert_eq(merged.get("actors", []), ["roach_a", "roach_b"], "both members connected")
	assert_no_event(resolved, "attack_no_wound", "the merged hit was NOT blocked")
	assert_eq(torso_hp(sim, "victim"), 4, "torso 5 -> 4: exactly the one merged net hit")
	assert_true((sim.combatants["victim"] as CombatantState).condition_tier("torso", "bleeding") >= 1,
		"the bleeding rider landed on the merged wound")


func test_disagreeing_draws_do_not_link() -> void:
	# Staged grudge makes each roach's own weighted draw overwhelmingly favor a
	# DIFFERENT victim (weight ~1001 vs ~1/16 at the fixed seed) — the synergy
	# is opportunistic, never scripted: disagreeing draws strike solo.
	var sim: CombatSim = make_sim()
	add_human(sim, "va", {"team": "party", "position": [1, 0]})
	add_human(sim, "vb", {"team": "party", "position": [6, 0]})
	add_roach(sim, "roach_a", [0, 0])
	add_roach(sim, "roach_b", [5, 0])
	(sim.combatants["roach_a"] as CombatantState).antagonism["va"] = 1000.0
	(sim.combatants["roach_b"] as CombatantState).antagonism["vb"] = 1000.0
	var first: Array[Dictionary] = ai_decide(sim, "roach_a")
	assert_eq(String(first_event(first, "ai_decision").get("target", "")), "va",
		"roach_a's own draw lands on its antagonist")
	var second: Array[Dictionary] = ai_decide(sim, "roach_b")
	assert_eq(String(first_event(second, "ai_decision").get("target", "")), "vb",
		"roach_b's own draw lands on ITS antagonist — the draws disagree")
	assert_no_event(second, "pack_synergy", "disagreeing draws never link")
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_no_event(resolved, "combined_force", "two solo strikes, no merge")
	assert_eq(events_of(resolved, "attack_no_wound").size(), 2,
		"both solo bites blocked at the gate (Force 1 vs Robustness 1) — hand pin")


func test_pair_cap_third_roach_strikes_solo() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim, "roach_a", [1, 0])
	add_roach(sim, "roach_b", [0, 1])
	add_roach(sim, "roach_c", [-1, 1])
	ai_decide(sim, "roach_a")
	var second: Array[Dictionary] = ai_decide(sim, "roach_b")
	assert_event(second, "pack_synergy", "the first two link")
	var third: Array[Dictionary] = ai_decide(sim, "roach_c")
	assert_no_event(third, "pack_synergy",
		"pairs only (v1 cap): both pending entries already carry a combo_id")
	assert_false((queue_entry_for(sim, "roach_c")["action"] as Dictionary).has("combo_id"),
		"the third strike is a plain solo declare")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var merged: Dictionary = assert_event(resolved, "combined_force", "the pair still merges")
	assert_eq(int(merged.get("net", 0)), 1, "pair net 1 (hand pin)")
	var blocked: Dictionary = assert_event(resolved, "attack_no_wound",
		"the third roach's solo bite is blocked at the gate")
	assert_eq(String(blocked.get("combatant", "")), "victim", "blocked on the victim")
	assert_eq(torso_hp(sim, "victim"), 4, "only the merged hit landed: 5 -> 4")


func test_non_pack_hunters_never_link() -> void:
	# Elite + pack mob on the SAME victim: the elite is not a pack hunter (the
	# authored little_brother_roach personality has no pack keys) — no link.
	var whip_only: Array = [{
		"key": "whip", "name": "Whip", "moment_cost": 1, "range": 7,
		"damage": [{"type": "bleeding", "amount": 2}],
	}]
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0]})
	add_enemy(sim, "elite", "little_brother_roach", {"position": [3, 0], "abilities": whip_only})
	add_roach(sim, "roach", [1, 0])
	assert_false((sim.combatants["elite"] as CombatantState).personality_pack_hunter(),
		"the elite brood-tender is NOT a pack hunter")
	ai_decide(sim, "elite")
	var second: Array[Dictionary] = ai_decide(sim, "roach")
	assert_no_event(second, "pack_synergy", "a pack roach never links to a non-pack elite")
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_no_event(resolved, "combined_force", "no merge — both resolved solo")
	# A plain mob WITHOUT the pack personality never links either — both orders.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim2, "plain", [1, 0], {"personality": {}})  # spec override strips the pack keys
	add_roach(sim2, "pack", [0, 1])
	ai_decide(sim2, "plain")
	var linked2: Array[Dictionary] = ai_decide(sim2, "pack")
	assert_no_event(linked2, "pack_synergy", "a pack roach never links to a personality-less mob")
	var sim3: CombatSim = make_sim()
	add_human(sim3, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim3, "pack", [1, 0])
	add_roach(sim3, "plain", [0, 1], {"personality": {}})
	ai_decide(sim3, "pack")
	var linked3: Array[Dictionary] = ai_decide(sim3, "plain")
	assert_no_event(linked3, "pack_synergy", "a personality-less mob never initiates a link")


func test_part_agreement_the_joiner_adopts_the_first_part() -> void:
	# The FIRST declarer's bite is biased to the left arm (part_bias); the
	# joiner's own solo pick would be the torso-line. Linking must adopt the
	# FIRST's part — merging requires one gate at one target+part (the
	# player-side combined_action contract).
	var biased_bite: Array = [{
		"key": "bite", "name": "Bite", "moment_cost": 1, "range": 1,
		"damage": [{"type": "bleeding", "amount": 1, "part_bias": "left_arm"}],
	}]
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim, "roach_a", [1, 0], {"abilities": biased_bite})
	add_roach(sim, "roach_b", [0, 1])
	var first: Array[Dictionary] = ai_decide(sim, "roach_a")
	assert_event(first, "action_declared", "the biased roach declares at the left arm")
	var second: Array[Dictionary] = ai_decide(sim, "roach_b")
	var synergy: Dictionary = assert_event(second, "pack_synergy", "the pack links")
	assert_eq(String(synergy.get("part", "")), "left_arm",
		"the joiner ADOPTED the first's part, overriding its own torso-line pick")
	var entry_b: Dictionary = queue_entry_for(sim, "roach_b")
	assert_eq(String(((entry_b["action"] as Dictionary).get("targets", [])[0] as Dictionary).get("part", "")),
		"left_arm", "the joiner's scheduled strike targets the agreed part")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var merged: Dictionary = assert_event(resolved, "combined_force", "merged at the agreed part")
	assert_eq(String(merged.get("part", "")), "left_arm", "ONE gate at ONE target+part")
	assert_eq(int(merged.get("net", 0)), 1, "Force 2 vs Robustness 1 -> net 1 (hand pin)")
	assert_eq(int(((sim.combatants["victim"] as CombatantState).parts["left_arm"] as Dictionary).get("hp", 0)),
		1, "left arm 2 -> 1: the merged hit landed where agreed")


# ------------------------------------------------------------- rng discipline

func test_linking_consumes_zero_extra_draws_twin_rng_proof() -> void:
	# Two candidates each (one draw per decide, R23 rule) + grudges staging both
	# draws onto the SAME victim: the linked decide consumes EXACTLY the one
	# targeting draw an unlinked decide would — linking itself draws nothing.
	var sim: CombatSim = make_sim()
	add_human(sim, "va", {"team": "party", "position": [0, 0]})
	add_human(sim, "vb", {"team": "party", "position": [10, 0]})
	add_roach(sim, "roach_a", [1, 0])
	add_roach(sim, "roach_b", [0, 1])
	(sim.combatants["roach_a"] as CombatantState).antagonism["va"] = 1000.0
	(sim.combatants["roach_b"] as CombatantState).antagonism["va"] = 1000.0
	var pre: int = sim.ai.ai_rng.state
	var first: Array[Dictionary] = ai_decide(sim, "roach_a")
	assert_eq(String(first_event(first, "ai_decision").get("target", "")), "va", "draw one lands on va")
	var twin := RandomNumberGenerator.new()
	twin.state = pre
	twin.randf()
	assert_eq(sim.ai.ai_rng.state, twin.state, "first decide: exactly ONE draw (the R23 pick)")
	var second: Array[Dictionary] = ai_decide(sim, "roach_b")
	assert_event(second, "pack_synergy", "the agreeing draws linked")
	twin.randf()
	assert_eq(sim.ai.ai_rng.state, twin.state,
		"the LINKED decide consumed exactly one draw too — linking adds ZERO rng")
	# Single-candidate pack: zero draws total, and the link still happens.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim2, "roach_a", [1, 0])
	add_roach(sim2, "roach_b", [0, 1])
	var pre2: int = sim2.ai.ai_rng.state
	ai_decide(sim2, "roach_a")
	var linked2: Array[Dictionary] = ai_decide(sim2, "roach_b")
	assert_event(linked2, "pack_synergy", "single-candidate picks agree trivially and link")
	assert_eq(sim2.ai.ai_rng.state, pre2, "single-candidate decides + linking: ZERO draws")


# --------------------------------------------- serialization + determinism

func test_serialization_mid_tick_with_a_pending_link() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim, "roach_a", [1, 0])
	add_roach(sim, "roach_b", [0, 1])
	ai_decide(sim, "roach_a")
	assert_event(ai_decide(sim, "roach_b"), "pack_synergy", "linked, both strikes PENDING")
	# Snapshot with the link mid-tick: the combo_id rides the queue serialization.
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical mid-tick")
	var live: Array[Dictionary] = advance(sim, 1)
	var replayed: Array[Dictionary] = advance(restored, 1)
	var merged_live: Dictionary = assert_event(live, "combined_force", "the live sim merges")
	var merged_replay: Dictionary = assert_event(replayed, "combined_force", "the restored sim merges too")
	assert_eq(merged_replay, merged_live, "identical merged resolution after the roundtrip")
	assert_eq(restored.state_hash(), sim.state_hash(), "post-resolution hashes identical")
	assert_eq(torso_hp(restored, "victim"), 4, "the restored victim carries the same merged wound")


func test_determinism_same_seed_same_log_same_hash() -> void:
	var hash_a: String = _pack_skirmish_hash(777)
	var hash_b: String = _pack_skirmish_hash(777)
	assert_eq(hash_a, hash_b, "same (seed, command log) twice -> identical final hash")
	assert_ne(_pack_skirmish_hash(778), hash_a, "a different seed diverges")


## A fixed pack skirmish: three pack roaches (pair cap exercised), two victims
## (real weighted draws), the ai_ready_ids driver loop — 12 ticks, no driver rng.
func _pack_skirmish_hash(sim_seed: int) -> String:
	var sim: CombatSim = make_sim(sim_seed)
	add_human(sim, "va", {"team": "party", "position": [1, 0]})
	add_human(sim, "vb", {"team": "party", "position": [0, 1]})
	add_roach(sim, "r1", [2, 0])
	add_roach(sim, "r2", [-1, 1])
	add_roach(sim, "r3", [1, -1])
	for tick: int in range(12):
		for id: String in sim.ai_ready_ids():
			ai_decide(sim, id)
		advance(sim, 1)
	return sim.state_hash()


# ------------------------------------------------------------- stance substrate

func test_stance_table_maps_every_decide_choice() -> void:
	# The documented table (EnemyAI header) — asserted choice by choice.
	var expected: Dictionary = {
		"attack": "aggressive", "grab": "aggressive", "chew": "aggressive", "spin": "aggressive",
		"move": "hunting",
		"heal": "defensive", "wait": "defensive", "stand": "defensive",
		"summon": "building", "telegraph": "building", "blast": "building",
	}
	for choice: String in expected:
		assert_eq(EnemyAI.stance_for_decision({"choice": choice}), String(expected[choice]),
			"choice '%s' maps to its documented stance" % choice)
	# The ONE documented exception: the mid-beat wait still reads "building".
	assert_eq(EnemyAI.stance_for_decision({"choice": "wait", "reason": "explosion_building"}),
		"building", "the venting boss is still charging its blast")
	assert_eq(EnemyAI.stance_for_decision({"choice": "wait", "reason": "no_targets"}),
		"defensive", "ordinary waits stay defensive")
	# Unknown/future choices default to the wait bucket until mapped.
	assert_eq(EnemyAI.stance_for_decision({"choice": "somersault"}), "defensive",
		"unmapped choice -> documented 'defensive' default")


func test_stances_write_at_decide_time_from_real_decisions() -> void:
	# attack -> aggressive (adjacent victim).
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim, "roach", [1, 0])
	assert_false(sim.ai.stances.has("roach"), "no stance before the first decide")
	ai_decide(sim, "roach")
	assert_eq(String(sim.ai.stances.get("roach", "")), "aggressive", "a biting roach reads aggressive")
	# move -> hunting (victim out of step+bite reach).
	var sim2: CombatSim = make_sim()
	add_human(sim2, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim2, "roach", [5, 0])
	assert_eq(String(first_event(ai_decide(sim2, "roach"), "ai_decision").get("choice", "")),
		"move", "distance 5: the step cannot close to bite range")
	assert_eq(String(sim2.ai.stances.get("roach", "")), "hunting", "a closing roach reads hunting")
	# wait -> defensive (no opponents on the board).
	var sim3: CombatSim = make_sim()
	add_roach(sim3, "roach", [0, 0])
	assert_eq(String(first_event(ai_decide(sim3, "roach"), "ai_decision").get("choice", "")),
		"wait", "no targets -> wait")
	assert_eq(String(sim3.ai.stances.get("roach", "")), "defensive", "an idle roach reads defensive")
	# summon -> building (the brood-tender's opening move, no staging needed).
	var sim4: CombatSim = make_sim()
	add_enemy(sim4, "elite", "little_brother_roach", {"position": [0, 0]})
	assert_eq(String(first_event(ai_decide(sim4, "elite"), "ai_decision").get("choice", "")),
		"summon", "the elite wakes its eggs first")
	assert_eq(String(sim4.ai.stances.get("elite", "")), "building", "a summoning elite reads building")
	# heal -> defensive (wounded elite, heal-only ability list).
	var heal_only: Array = [{
		"key": "seal_wound", "name": "Seal Wound", "moment_cost": 2,
		"heal": {"amount": 1, "target": "self"},
	}]
	var sim5: CombatSim = make_sim()
	add_human(sim5, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim5, "elite", "little_brother_roach", {"position": [0, 0], "abilities": heal_only})
	declare(sim5, "h", attack_action("crushed", 9, "elite", "torso"))
	advance(sim5, 1)  # force 10 - Robustness 2 = 8: torso 15 -> 7, below half
	assert_eq(String(first_event(ai_decide(sim5, "elite"), "ai_decision").get("choice", "")),
		"heal", "a badly wounded elite heals")
	assert_eq(String(sim5.ai.stances.get("elite", "")), "defensive", "a healing elite reads defensive")
	# stand -> defensive (a knocked-down boss rights itself).
	var sim6: CombatSim = make_sim()
	add_human(sim6, "h", {"team": "party", "position": [1, 0]})
	add_enemy(sim6, "boss", "incinedile", {"position": [0, 0]})
	sim6.apply_command({"type": "set_status", "target": "boss", "status": "prone", "value": true})
	assert_eq(String(first_event(ai_decide(sim6, "boss"), "ai_decision").get("choice", "")),
		"stand", "a prone boss stands first")
	assert_eq(String(sim6.ai.stances.get("boss", "")), "defensive", "a standing-up boss reads defensive")
	# (telegraph/blast -> building is covered by the table unit test above —
	# driving the valve beat live is test_explosion_beats.gd territory.)


func test_stance_survives_roundtrip_and_is_hash_covered() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "victim", {"team": "party", "position": [0, 0]})
	add_roach(sim, "roach", [1, 0])
	ai_decide(sim, "roach")
	advance(sim, 1)
	assert_eq(String(sim.ai.stances.get("roach", "")), "aggressive", "stance on the live sim")
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(String(restored.ai.stances.get("roach", "")), "aggressive", "stance survives the roundtrip")
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical")
	# Mutation teeth: a tampered stance must change the hash.
	var tampered: Dictionary = sim.to_dict()
	((tampered["ai"] as Dictionary)["stances"] as Dictionary)["roach"] = "defensive"
	assert_ne(CombatSim.from_dict(tampered).state_hash(), sim.state_hash(),
		"ai_stance is covered by the state hash")
	# Pre-wave-3a saves lack "stances": restores empty (view reads "unknown").
	var legacy: Dictionary = sim.to_dict()
	(legacy["ai"] as Dictionary).erase("stances")
	assert_true(CombatSim.from_dict(legacy).ai.stances.is_empty(),
		"a pre-3a save restores with no stances, matching a fresh sim")


func test_view_combatants_exposes_ai_stance_additively() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "hero", "name": "Hero", "race": "human", "team": "party", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "roach", "name": "Roach", "enemy": "roach_dog", "team": "enemies",
		"position": [1, 0]}})
	var rows: Dictionary = {}
	for cv: Variant in game.view_combatants():
		rows[String((cv as Dictionary).get("id", ""))] = cv
	assert_eq(String((rows["roach"] as Dictionary).get("ai_stance", "")), "unknown",
		"an AI row reads 'unknown' before its first decide")
	assert_eq(String((rows["hero"] as Dictionary).get("ai_stance", "?")), "",
		"a contestant row carries the empty stance — the substrate is AI-only")
	game.apply_command({"type": "ai_decide", "actor": "roach"})
	rows = {}
	for cv: Variant in game.view_combatants():
		rows[String((cv as Dictionary).get("id", ""))] = cv
	assert_eq(String((rows["roach"] as Dictionary).get("ai_stance", "")), "aggressive",
		"after the decide the AI row exposes the live stance read")
	game.free()
