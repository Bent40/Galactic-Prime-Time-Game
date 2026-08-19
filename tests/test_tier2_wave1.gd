extends SimTestBase
## Tier-2 wave 1 (docs/design/tier2-rungs-proposal.md — BLESSED, owner
## 2026-08-18): the data import (all ten ladders -> skills.json ids 51-60 +
## L5 threshold rows ids 93-102) and the three implemented low-machinery
## ladders:
##   S5 perfect_evasion — the FUSED R25 arming (one movement forfeit arms the
##      declared-hex roll AND the save), the OQ2 second roll (a second
##      DISTINCT attack in the same window; same-attack re-roll rejected;
##      zero rng), and the row-68 negate (once per Clock, serialized).
##   S7 vice_grip — grip-neutral (hands OR jaws through ONE skill), the R9
##      hold + the drag override, the row-86 grip wound (implemented as the
##      grip-close Bleed + the standing per-Clock condition advancement; the
##      literal while-held per-reset re-application stays data-flagged), and
##      the S7-d full-jaw-grip suffocation substitution (R9 caps uncut).
##   S10 phantom_grasp — the psionic HOLD on the sustained_channel substrate
##      (OQ1 RULED mundane-psionic): grip at range, R9 movement lock, escape
##      per R9's escape actions with the contest target-Physique-vs-holder-
##      MIND, Exposed while sustaining, the multi-hex drag, break-on-damage,
##      and the mundanity pin (is_magic 0, no magic reading anywhere).
## Plus: serialization only-when-set compat pins, round-trips, determinism.
## All magnitudes PLACEHOLDER (R14).

const TIER2_KEYS: Array[String] = [
	"counterscript", "predators_arc", "earthbreaker", "vivisection",
	"perfect_evasion", "combat_medic", "vice_grip", "the_unseen",
	"the_long_con", "phantom_grasp",
]
const IMPLEMENTED: Dictionary = {
	"perfect_evasion": "fused_evasion",
	"vice_grip": "skill_grapple",
	"phantom_grasp": "sustained_channel",
}


func add_party(sim: CombatSim, id: String, pos: Array, overrides: Dictionary = {}) -> void:
	var spec: Dictionary = {"team": "party", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}
	spec.merge(overrides, true)
	add_human(sim, id, spec)


func add_elite(sim: CombatSim, id: String, pos: Array, extra: Dictionary = {}) -> void:
	var spec: Dictionary = {
		"id": id, "name": id, "category": "Elite", "size": "Large",
		"team": "enemies", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
			{"key": "left_arm", "hp": 50, "lethal": false},
			{"key": "right_arm", "hp": 50, "lethal": false},
			{"key": "left_leg", "hp": 50, "lethal": false},
			{"key": "right_leg", "hp": 50, "lethal": false},
		],
	}
	spec.merge(extra, true)
	sim.apply_command({"type": "add_combatant", "combatant": spec})


## A handless bite-capable layout (the batch-B croc): the jaws-side proof body.
func add_croc(sim: CombatSim, id: String, pos: Array, extra: Dictionary = {}) -> void:
	var spec: Dictionary = {
		"id": id, "name": id, "team": "party", "size": "Medium", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 2, "charm": 1},
		"body_parts": [
			{"key": "head", "hp": 40, "lethal": true, "bite_capable": true},
			{"key": "torso", "hp": 40, "lethal": true},
			{"key": "left_leg", "hp": 30, "lethal": false},
			{"key": "right_leg", "hp": 30, "lethal": false},
		],
	}
	spec.merge(extra, true)
	sim.apply_command({"type": "add_combatant", "combatant": spec})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func apply_cond(sim: CombatSim, target: String, part: String, condition: String, tier: int) -> Array[Dictionary]:
	return sim.apply_command({"type": "apply_condition", "target": target,
		"part": part, "condition": condition, "tier": tier})


func evade_declare(sim: CombatSim, actor: String, to: Array, level: int = 1, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "perfect_evasion", "level": level, "to": to}
	action.merge(extra, true)
	return declare(sim, actor, action)


func vice_declare(sim: CombatSim, actor: String, target: String, level: int = 1, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "vice_grip", "level": level, "target": target}
	action.merge(extra, true)
	return declare(sim, actor, action)


func phantom_declare(sim: CombatSim, actor: String, target: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "phantom_grasp", "level": level,
		"targets": [{"id": target}]})


func phantom_sustain(sim: CombatSim, actor: String, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "phantom_grasp", "level": 1, "sustain": true}
	action.merge(extra, true)
	return declare(sim, actor, action)


# ============================================================ data contract

func test_data_contract_ten_ladder_rows() -> void:
	var skills: Array = load_json("res://data/skills.json")
	var thresholds: Array = load_json("res://data/skill_thresholds.json")
	assert_eq(skills.size(), 58, "48 + the 10 BLESSED tier-2 ladders")
	assert_eq(thresholds.size(), 98, "88 + the 10 L5 mastery rungs")
	var by_key: Dictionary = {}
	for s: Variant in skills:
		by_key[String((s as Dictionary).get("key", ""))] = s
	var expected_id: int = 51
	for key: String in TIER2_KEYS:
		assert_true(by_key.has(key), "row exists: " + key)
		if not by_key.has(key):
			expected_id += 1
			continue
		var row: Dictionary = by_key[key]
		assert_eq(int(row.get("id", -1)), expected_id, "%s sits at id %d (ids 51-60 in ladder order)" % [key, expected_id])
		assert_eq(int(row.get("default_cap", -1)), 5, key + ": tier-2 cap 5 (Q3)")
		assert_true(String(row.get("acquisition", "")).length() > 0,
			key + ": acquisition-gated (recipe/offer — never learnable directly)")
		assert_eq((row.get("effects", []) as Array).size(), 3, key + ": L2-4 rows imported (b-d rungs)")
		var l5_found: bool = false
		for t: Variant in thresholds:
			var tr: Dictionary = t
			if int(tr.get("skill_id", -1)) == expected_id and int(tr.get("level", -1)) == 5:
				l5_found = true
		assert_true(l5_found, key + ": the L5 mastery rung landed in skill_thresholds.json")
		expected_id += 1


func test_data_contract_results_match_recipes_and_offers() -> void:
	# Every mutation/offer RESULT key now owns a skills.json row — the
	# "DATA-DECLARED ONLY" interim is closed by this import.
	var skills: Array = load_json("res://data/skills.json")
	var keys: Dictionary = {}
	for s: Variant in skills:
		keys[String((s as Dictionary).get("key", ""))] = true
	var mutations: Dictionary = load_json("res://data/skill_mutations.json")
	for m: Variant in mutations.get("mutations", []) as Array:
		var rk := String(((m as Dictionary).get("result", {}) as Dictionary).get("key", ""))
		assert_true(keys.has(rk), "recipe result has a catalog row: " + rk)
	var offers: Dictionary = load_json("res://data/mod_center_offers.json")
	for o: Variant in offers.get("offers", []) as Array:
		var rk := String(((o as Dictionary).get("result", {}) as Dictionary).get("key", ""))
		assert_true(keys.has(rk), "offer result has a catalog row: " + rk)


func test_implemented_vs_data_only_split_is_honest() -> void:
	# The three low-machinery ladders are ENCODED; the other seven resolve
	# through the honest `strike` fallback until their machinery lands. None
	# are in KNOWN_KEYS (acquisition-gated results are never creation-
	# selectable, and their keyword rulings await the keyword pass).
	for key: String in TIER2_KEYS:
		var spec: Dictionary = SkillBook.mechanics(key, 1)
		if IMPLEMENTED.has(key):
			assert_eq(String(spec.get("archetype", "")), String(IMPLEMENTED[key]),
				key + ": implemented archetype")
		else:
			assert_eq(String(spec.get("archetype", "")), "strike",
				key + ": DATA-ONLY this wave — the honest fallback")
		assert_false(SkillBook.is_known(key),
			key + ": deliberately not in KNOWN_KEYS (acquisition-gated + keyword pass pending)")


func test_phantom_grasp_mundanity_pin() -> void:
	# OQ1 RULED (owner 2026-08-18): mundane-PSIONIC, not magic — no is_magic
	# anywhere on the row, no magic flag anywhere on the spec.
	var skills: Array = load_json("res://data/skills.json")
	for s: Variant in skills:
		var row: Dictionary = s
		if String(row.get("key", "")) == "phantom_grasp":
			assert_eq(int(row.get("is_magic", -1)), 0, "phantom_grasp row: is_magic 0")
	for lv: int in range(1, 5):
		var spec: Dictionary = SkillBook.mechanics("phantom_grasp", lv)
		assert_false(spec.has("is_magic"), "no magic flag on the spec (L%d)" % lv)
		assert_eq(String(spec.get("grip", "")), "psychic", "the grip is psychic, not magic (L%d)" % lv)


# ================================================ S5 perfect_evasion (fused)

func test_fused_arming_one_forfeit_arms_both() -> void:
	var sim: CombatSim = make_sim(7101)
	add_party(sim, "ace", [0, 0])
	add_party(sim, "runner", [0, 3])
	add_elite(sim, "foe", [1, 0])
	apply_cond(sim, "ace", "torso", "bleeding", 2)  # Forced Body on every action
	# The enemy commits a windup at ace's CURRENT hex...
	declare(sim, "foe", attack_action("crushed", 3, "ace", "torso", {"cost": 2}))
	# ...and ONE fused declare both rolls away AND arms the save.
	var armed: Array[Dictionary] = evade_declare(sim, "ace", [-2, 0])
	var pe: Dictionary = assert_event(armed, "perfect_evasion", "the fused arming event")
	assert_eq(pe.get("to", []), [-2, 0], "the roll half moved at declare")
	assert_eq(int(pe.get("dice", 0)), 5, "L1 save dice = 5 (>= the Save's L5, PH)")
	assert_eq(int(pe.get("range", 0)), 8, "L1 roll range = 8 (>= the Roll's L5, PH)")
	assert_false(bool(pe.get("negate_armed", true)), "no negate below L4")
	var ace: CombatantState = sim.combatants["ace"]
	assert_eq(ace.position, Vector2i(-2, 0), "the body moved")
	assert_true(ace.rolled_this_window, "the roll marker is live (AoE-center rule feeds off it)")
	assert_eq(int(ace.forced_save.get("dice", 0)), 5, "the save half is armed")
	assert_true(ace.evasion.is_empty(), "no second-roll window record below L3 (only-when-set)")
	assert_false(ace.free_action_used, "the free-action slot is untouched — movement only")
	# ONE forfeit: movement is genuinely spent, and no re-arm this Moment.
	assert_rejected(move(sim, "ace", [-1, 0]), "already_moved", "the movement is forfeit")
	assert_rejected(evade_declare(sim, "ace", [-3, 0]), "already_armed", "no double-arming")
	move(sim, "runner", [0, 2])
	assert_rejected(evade_declare(sim, "runner", [0, 1]), "movement_spent",
		"movement spent first = the forfeit cannot be paid")
	# The save half fires on ace's next Body roll (their own attack this tick).
	declare(sim, "ace", attack_action("crushed", 1, "foe", "torso", {"attack_range": 8}))
	var tick1: Array[Dictionary] = advance(sim)
	var save: Dictionary = assert_event(tick1, "acrobatic_save", "the armed save fires on the Body roll")
	assert_eq((save.get("rolls", []) as Array).size(), 6, "original + 5 extra dice, every die emitted")
	assert_true(ace.forced_save.is_empty(), "the arming is consumed per roll")
	# The roll half dodges: the enemy windup re-check finds the hex empty.
	var tick2: Array[Dictionary] = advance(sim)
	for dmg: Dictionary in events_of(tick2, "damage_applied"):
		assert_ne(String(dmg.get("combatant", "")), "ace", "the windup missed the rolled-away hex")


func test_oq2_second_roll_only_a_second_distinct_attack() -> void:
	var sim: CombatSim = make_sim(7102)
	add_party(sim, "ace", [0, 0])
	add_elite(sim, "ea", [2, 0])
	add_elite(sim, "eb", [0, 2])
	# Attack A is inbound when the first roll declares — the roll answers it.
	declare(sim, "ea", attack_action("crushed", 3, "ace", "torso", {"cost": 2, "attack_range": 4}))
	var first: Array[Dictionary] = evade_declare(sim, "ace", [1, 0], 3)
	assert_event(first, "perfect_evasion", "the L3 fused arming")
	var ace: CombatantState = sim.combatants["ace"]
	assert_false(ace.evasion.is_empty(), "the L3 window record is live")
	assert_eq((ace.evasion.get("answered", []) as Array).size(), 1, "attack A recorded as answered")
	# Below L3 the shape is locked; same-attack re-rolls reject; an attacker
	# with nothing pending is no second attack.
	assert_rejected(evade_declare(sim, "ace", [0, 1], 1, {"second_roll": true, "against": "ea"}),
		"second_roll_locked", "S5-c is the L3 rung")
	assert_rejected(evade_declare(sim, "ace", [0, 1], 3, {"second_roll": true, "against": "ea"}),
		"same_attack", "the first roll already answered attack A — no re-roll against it")
	assert_rejected(evade_declare(sim, "ace", [0, 1], 3, {"second_roll": true, "against": "eb"}),
		"no_second_attack", "eb has nothing resolving against the roller")
	# A SECOND DISTINCT attack arrives — the same forfeit covers a second roll.
	declare(sim, "eb", attack_action("crushed", 3, "ace", "torso", {"cost": 2, "attack_range": 4}))
	var second: Array[Dictionary] = evade_declare(sim, "ace", [0, 1], 3, {"second_roll": true, "against": "eb"})
	var sr: Dictionary = assert_event(second, "perfect_evasion_second_roll", "the OQ2 second roll fires")
	assert_eq(String(sr.get("against", "")), "eb", "against the named second attack")
	assert_eq(ace.position, Vector2i(0, 1), "the second dodge moved")
	assert_false(ace.free_action_used, "still no slot touched — the one forfeit pays for both")
	# Once per window, and never a third.
	declare(sim, "ea", attack_action("crushed", 3, "ace", "torso", {"cost": 3, "attack_range": 6}))
	assert_rejected(evade_declare(sim, "ace", [1, 1], 3, {"second_roll": true, "against": "ea"}),
		"second_roll_used", "two dodges from one forfeit — never three")
	# And no window record = no second roll (fresh actor, next window).
	advance(sim)
	assert_true(ace.evasion.is_empty(), "the window record clears with the tick flags")
	assert_rejected(evade_declare(sim, "ace", [1, 1], 3, {"second_roll": true, "against": "ea"}),
		"no_first_roll", "the second roll never outlives its window")


func test_oq2_second_roll_twin_rng_discipline() -> void:
	# Twin sims, same seed: twin B additionally performs the OQ2 second roll.
	# The next Forced Body draw must be the SAME stream value in both — the
	# second roll consumes ZERO rng (pure movement).
	var twin_a: CombatSim = make_sim(7103)
	var twin_b: CombatSim = make_sim(7103)
	for twin: CombatSim in [twin_a, twin_b]:
		add_party(twin, "ace", [0, 0])
		add_party(twin, "weakling", [5, 0], {"traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3}})
		add_elite(twin, "ea", [2, 0])
		add_elite(twin, "eb", [6, 0])
		declare(twin, "ea", attack_action("crushed", 3, "ace", "torso", {"cost": 2, "attack_range": 4}))
		evade_declare(twin, "ace", [1, 0], 3)
		declare(twin, "eb", attack_action("crushed", 3, "ace", "torso", {"cost": 2, "attack_range": 8}))
	evade_declare(twin_b, "ace", [0, 1], 3, {"second_roll": true, "against": "eb"})
	# The stream probe: an above-weight grapple's Forced Body (physique 2 < 3).
	for twin: CombatSim in [twin_a, twin_b]:
		declare(twin, "weakling", {"kind": "grapple", "target": "eb"})
	var roll_a: int = int(assert_event(advance(twin_a), "forced_action_triggered", "twin A probe").get("roll", -1))
	var roll_b: int = int(assert_event(advance(twin_b), "forced_action_triggered", "twin B probe").get("roll", -2))
	assert_eq(roll_a, roll_b, "identical stream draw — the second roll consumed zero rng")


func test_row68_negate_once_per_clock() -> void:
	var sim: CombatSim = make_sim(7104)
	add_party(sim, "ace", [0, 0])
	add_elite(sim, "foe", [5, 0])
	apply_cond(sim, "ace", "torso", "bleeding", 2)  # Forced Body on every action
	# Bank delays so the bleeding stays T2 across the Clock reset (the test
	# spans two Clocks; the wound must not advance to part death).
	sim.apply_command({"type": "treat", "target": "ace", "part": "torso", "condition": "bleeding", "mode": "delay"})
	sim.apply_command({"type": "treat", "target": "ace", "part": "torso", "condition": "bleeding", "mode": "delay"})
	var ace: CombatantState = sim.combatants["ace"]
	# Tick 0: the L4 arming carries the negate — the Body roll is VETOED.
	var armed: Array[Dictionary] = evade_declare(sim, "ace", [0, 1], 4)
	assert_true(bool(assert_event(armed, "perfect_evasion", "L4 arming").get("negate_armed", false)),
		"the negate rides the L4 arming")
	declare(sim, "ace", attack_action("crushed", 1, "foe", "left_arm", {"attack_range": 8}))
	var tick0: Array[Dictionary] = advance(sim)
	var negated: Dictionary = assert_event(tick0, "forced_body_negated", "the row-68 negate fires")
	assert_eq(int(negated.get("clock_index", -1)), 0, "in Clock 0")
	assert_no_event(tick0, "forced_action_triggered", "the Forced Action was vetoed outright")
	assert_no_event(tick0, "acrobatic_save", "no softening happened — the veto IS the save's use")
	assert_eq(ace.negate_used_clock, 0, "the per-Clock gate is spent")
	assert_true(ace.forced_save.is_empty(), "the arming is consumed")
	# Same Clock, re-armed: the SECOND negate is refused — the save falls
	# back to softening (dice), until the reset.
	evade_declare(sim, "ace", [0, 0], 4)
	declare(sim, "ace", attack_action("crushed", 1, "foe", "left_arm", {"attack_range": 8}))
	var tick1: Array[Dictionary] = advance(sim)
	assert_no_event(tick1, "forced_body_negated", "second negate rejected until the Clock reset")
	var softened: Dictionary = assert_event(tick1, "acrobatic_save", "the save still softens")
	assert_eq((softened.get("rolls", []) as Array).size(), 9, "original + 8 extra dice at L4 (PH)")
	assert_event(tick1, "forced_action_triggered", "a consequence applies this time")
	# Cross the Clock reset; the gate re-opens.
	advance(sim, 8)  # ticks 2..9 complete Clock 0
	evade_declare(sim, "ace", [0, 1], 4)
	declare(sim, "ace", attack_action("crushed", 1, "foe", "left_arm", {"attack_range": 8}))
	var tick10: Array[Dictionary] = advance(sim)
	var again: Dictionary = assert_event(tick10, "forced_body_negated", "the negate re-opens after the reset")
	assert_eq(int(again.get("clock_index", -1)), 1, "in Clock 1")
	assert_eq(ace.negate_used_clock, 1, "the gate tracks the new Clock")


# ===================================================== S7 vice_grip (S7-a/b/d)

func test_vice_grip_hands_and_jaws_one_skill() -> void:
	var sim: CombatSim = make_sim(7201)
	add_party(sim, "holder", [0, 0])
	add_elite(sim, "victim", [1, 0])
	add_croc(sim, "croc", [4, 0])
	add_elite(sim, "victim2", [5, 0])
	# The hands-actor grips through vice_grip (cost 1 — the R9 initiate).
	var d1: Array[Dictionary] = vice_declare(sim, "holder", "victim")
	assert_eq(int(assert_event(d1, "action_declared", "hands-side declare").get("cost", -1)), 1,
		"the ladder header's 1-Moment initiate")
	var ev1: Array[Dictionary] = advance(sim)
	var g1: Dictionary = assert_event(ev1, "grapple_started", "the hands grip lands")
	assert_eq(String(g1.get("skill", "")), "vice_grip", "attributed to the ONE skill")
	# The jaws-actor grips through the SAME skill (handless layout).
	var d2: Array[Dictionary] = vice_declare(sim, "croc", "victim2")
	assert_event(d2, "action_declared", "jaws-side declare — same key, no hands anywhere")
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "grapple_started", "the jaws grip lands")
	var holder: CombatantState = sim.combatants["holder"]
	var victim: CombatantState = sim.combatants["victim"]
	assert_eq(holder.grappling, "victim", "the R9 hold link")
	assert_eq(victim.grappled_by, "holder", "the mirror")
	assert_true(holder.exposed_cache, "holder Exposed (R9)")
	assert_true(victim.exposed_cache, "victim Exposed (R9)")
	assert_rejected(move(sim, "victim", [2, 0]), "grappled", "no reposition while held")
	assert_rejected(move(sim, "holder", [0, 1]), "grappled", "the holder is locked too")
	# A body with neither anatomy has no grip at all.
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "stump", "name": "stump", "team": "party", "position": [8, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 4, "lethal": true},
			{"key": "torso", "hp": 6, "lethal": true},
		]}})
	add_elite(sim, "victim3", [9, 0])
	assert_rejected(vice_declare(sim, "stump", "victim3"), "no_grip",
		"grip-neutral still needs SOME anatomy — hands or jaws")


func test_vice_grip_drag_override_ladder() -> void:
	var sim: CombatSim = make_sim(7202)
	add_party(sim, "holder", [0, 0])
	add_elite(sim, "victim", [1, 0])
	vice_declare(sim, "holder", "victim")
	advance(sim)
	# L1 drag 4 (>= the Hold's L5 drag — PH): five spaces reject, four walk.
	assert_rejected(vice_declare(sim, "holder", "victim", 1, {"drag_to": [-5, 0]}),
		"drag_out_of_range", "L1 drags up to 4 (PH)")
	var declared: Array[Dictionary] = vice_declare(sim, "holder", "victim", 1, {"drag_to": [-4, 0]})
	assert_event(declared, "action_declared", "the drag declares (cost normalized to 1)")
	var ev: Array[Dictionary] = advance(sim)
	var dragged: Dictionary = assert_event(ev, "grapple_dragged", "the pair walks — the R11.7 override")
	assert_eq(int(dragged.get("spaces", 0)), 4, "four hexes at L1")
	assert_eq((sim.combatants["holder"] as CombatantState).position, Vector2i(-4, 0), "holder walked")
	assert_eq((sim.combatants["victim"] as CombatantState).position, Vector2i(-3, 0), "victim pulled behind")
	# L4 (row 12's 5): the drag limit rises to 5. (Dragged AWAY from the
	# victim's hex — a body blocks a drag straight back through it.)
	var d5: Array[Dictionary] = vice_declare(sim, "holder", "victim", 4, {"drag_to": [-4, 5]})
	assert_event(d5, "action_declared", "L4 five-space drag declares")
	var ev5: Array[Dictionary] = advance(sim)
	assert_eq(int(assert_event(ev5, "grapple_dragged", "L4 drag").get("spaces", 0)), 5, "row 12's 5 (PH)")


func test_vice_grip_row86_grip_wound_and_standing_advance() -> void:
	var sim: CombatSim = make_sim(7203)
	add_party(sim, "holder", [0, 0])
	# A soft victim (physique 1 -> robustness 0) so the 1-Bleed wound lands.
	add_elite(sim, "victim", [1, 0], {"traits": {"physique": 1, "reflexes": 1, "mind": 0, "charm": 1}})
	var victim: CombatantState = sim.combatants["victim"]
	# L1 carries no wound rider; L2+ closes the grip with the row-86 Bleed.
	assert_eq(int(SkillBook.mechanics("vice_grip", 1).get("grip_bleed", -1)), 0, "no rider at L1")
	vice_declare(sim, "holder", "victim", 2)
	var ev: Array[Dictionary] = advance(sim)
	var rider: Dictionary = assert_event(ev, "grip_bleed_rider", "the grip itself wounds (L2, row 86)")
	assert_eq(int(rider.get("amount", 0)), 1, "1 Bleed (PH)")
	var part: String = String(rider.get("part", ""))
	assert_eq(victim.condition_tier(part, "bleeding"), 1, "a REAL Bleeding wound on the held part")
	# The standing per-Clock machinery carries the wound forward: at the Clock
	# reset the Bleeding advances (advances_on_clock_reset) — the ongoing
	# per-Clock harm of row 86, via today's condition engine. HONESTY FLAG:
	# the literal "1 Bleed re-applied at each reset WHILE HELD" needs the
	# Clock-reset rider (combat_sim's sweep — outside this story's footprint);
	# that half stays data-flagged on the skills.json row.
	var reset_ev: Array[Dictionary] = advance(sim, 9)  # through the Clock reset
	assert_event(reset_ev, "clock_reset", "the Clock turned")
	assert_eq(victim.condition_tier(part, "bleeding"), 2,
		"the standing advancement worsened the grip wound at the reset")


func test_vice_grip_s7d_full_jaw_grip_suffocation() -> void:
	var sim: CombatSim = make_sim(7204)
	# The L4 croc: the vice_grip grant is what unlocks the jaw-grip
	# substitution (roster-path grant — from_spec accepts any key).
	add_croc(sim, "croc", [0, 0], {"skills": [{"key": "vice_grip", "level": 4}]})
	add_elite(sim, "prey", [1, 0], {"size": "Medium",
		"traits": {"physique": 1, "reflexes": 1, "mind": 0, "charm": 1}})
	add_croc(sim, "croc2", [4, 0])
	add_elite(sim, "prey2", [5, 0], {"size": "Medium",
		"traits": {"physique": 1, "reflexes": 1, "mind": 0, "charm": 1}})
	vice_declare(sim, "croc", "prey", 4)
	vice_declare(sim, "croc2", "prey2")
	advance(sim)
	assert_eq((sim.combatants["croc"] as CombatantState).grappling, "prey", "the L4 hold is live")
	# The ungranted jaws-holder keeps the unchanged R9 both-hands gate.
	assert_rejected(declare(sim, "croc2", {"kind": "grapple_suffocate", "target": "prey2"}),
		"needs_both_hands", "no grant = no substitution (death_grip_jaws never unlocked this)")
	# The L4 full jaw grip substitutes for both hands (S7-d).
	var d: Array[Dictionary] = declare(sim, "croc", {"kind": "grapple_suffocate", "target": "prey"})
	assert_event(d, "action_declared", "the full-jaw-grip suffocation declares at Vice Grip L4")
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "action_resolved", "the squeeze resolves")
	var prey: CombatantState = sim.combatants["prey"]
	var timed: bool = false
	for timer: Dictionary in prey.timers:
		if String(timer.get("condition", "")) == "suffocation":
			timed = true
	assert_true(timed, "the Suffocation timer starts")
	# R9 caps uncut: a Boss is immune to the phantom and the physical alike.
	add_croc(sim, "croc3", [8, 0], {"skills": [{"key": "vice_grip", "level": 4}]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "boss", "category": "Boss", "size": "Medium", "team": "enemies",
		"position": [9, 0], "traits": {"physique": 1, "reflexes": 1, "mind": 1, "charm": 1},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
		]}})
	vice_declare(sim, "croc3", "boss", 4)
	advance(sim)
	assert_rejected(declare(sim, "croc3", {"kind": "grapple_suffocate", "target": "boss"}),
		"boss_immune_to_grapple_suffocation", "R9 uncut — boss wins are discovered, not choked")


# ============================================== S10 phantom_grasp (the hold)

func test_phantom_grip_at_range_locks_and_exposes() -> void:
	var sim: CombatSim = make_sim(7301)
	add_party(sim, "psy", [0, 0], {"traits": {"physique": 2, "reflexes": 3, "mind": 8, "charm": 3}})
	add_elite(sim, "held", [15, 0])
	# Range 15: beyond telekinesis' L1 grip (10), inside the phantom's 22 (PH).
	assert_rejected(declare(sim, "psy", {"kind": "skill", "key": "telekinesis", "level": 1,
		"targets": [{"id": "held"}]}), "out_of_range", "the parent could not reach this")
	var d: Array[Dictionary] = phantom_declare(sim, "psy", "held")
	assert_event(d, "action_declared", "the phantom grip declares at 15 hexes")
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "telekinesis_grip", "the hold lands (the shared channel substrate)")
	var psy: CombatantState = sim.combatants["psy"]
	var held: CombatantState = sim.combatants["held"]
	assert_eq(String(psy.channeling.get("grip", "")), "psychic", "the channel is marked a HOLD")
	assert_eq(held.held_by, "psy", "the held-by mirror")
	assert_true(psy.exposed_cache, "Exposed while sustaining (kept from the parent)")
	assert_rejected(move(sim, "held", [16, 0]), "held", "R9's movement lock, at range")
	assert_rejected(move(sim, "psy", [1, 0]), "channeling", "the holder is rooted")
	# The mundane telekinesis channel carries NO grip key (only-when-set pin).
	var sim2: CombatSim = make_sim(7302)
	add_party(sim2, "tk", [0, 0])
	add_elite(sim2, "t", [3, 0])
	declare(sim2, "tk", {"kind": "skill", "key": "telekinesis", "level": 1, "targets": [{"id": "t"}]})
	advance(sim2)
	assert_false((sim2.combatants["tk"] as CombatantState).channeling.has("grip"),
		"telekinesis' channel record is byte-identical to batch D — no grip key")
	assert_rejected(declare(sim2, "t", {"kind": "grapple_escape"}), "not_grappled",
		"a plain lift is NOT a hold — no R9 escape against telekinesis (legacy pin)")


func test_phantom_escape_contest_physique_vs_mind_both_outcomes() -> void:
	# OQ1 RULED: the escape contest is target Physique vs the HOLDER'S MIND.
	# Outcome 1 — strong target (Physique 8 >= Mind 8): the quick 1-Moment escape.
	var sim: CombatSim = make_sim(7303)
	add_party(sim, "psy", [0, 0], {"traits": {"physique": 2, "reflexes": 3, "mind": 8, "charm": 3}})
	add_elite(sim, "strong", [8, 0], {"traits": {"physique": 8, "reflexes": 3, "mind": 0, "charm": 1}})
	phantom_declare(sim, "psy", "strong")
	advance(sim)
	var esc_quick: Array[Dictionary] = declare(sim, "strong", {"kind": "grapple_escape"})
	assert_eq(int(assert_event(esc_quick, "action_declared", "the quick escape").get("cost", -1)), 1,
		"Physique >= holder MIND -> 1 Moment (the R9 contest, holder stat swapped)")
	phantom_sustain(sim, "psy")
	var ev_q: Array[Dictionary] = advance(sim)
	assert_event(ev_q, "hold_escaped", "the escape breaks the phantom hold")
	assert_eq(String(assert_event(ev_q, "telekinesis_released", "released").get("reason", "")),
		"escaped", "through the one release seam")
	assert_eq((sim.combatants["strong"] as CombatantState).held_by, "", "free again")
	assert_true((sim.combatants["psy"] as CombatantState).channeling.is_empty(), "channel gone")
	# Outcome 2 — weak target (Physique 3 < Mind 8): the slow 2-Moment escape,
	# resolving only if the holder keeps paying the sustain.
	var sim2: CombatSim = make_sim(7304)
	add_party(sim2, "psy", [0, 0], {"traits": {"physique": 2, "reflexes": 3, "mind": 8, "charm": 3}})
	add_elite(sim2, "weak", [8, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 1}})
	phantom_declare(sim2, "psy", "weak")
	advance(sim2)
	phantom_sustain(sim2, "psy")
	var esc_slow: Array[Dictionary] = declare(sim2, "weak", {"kind": "grapple_escape"})
	assert_eq(int(assert_event(esc_slow, "action_declared", "the slow escape").get("cost", -1)), 2,
		"Physique < holder MIND -> 2 Moments")
	advance(sim2)
	phantom_sustain(sim2, "psy")
	advance(sim2)
	phantom_sustain(sim2, "psy")
	var ev_s: Array[Dictionary] = advance(sim2)
	assert_event(ev_s, "hold_escaped", "the paid 2-Moment escape lands")
	assert_eq((sim2.combatants["weak"] as CombatantState).held_by, "", "free")
	# The parameterization itself, pinned.
	assert_eq(ActionResolver.escape_holder_stat("psychic"), "mind", "psychic grip contests MIND")
	assert_eq(ActionResolver.escape_holder_stat("hands"), "physique", "mundane grips contest Physique")
	assert_eq(ActionResolver.escape_holder_stat("any"), "physique", "vice_grip included")


func test_phantom_drag_and_break_on_damage() -> void:
	var sim: CombatSim = make_sim(7305)
	add_party(sim, "psy", [0, 0], {"traits": {"physique": 2, "reflexes": 3, "mind": 8, "charm": 3}})
	add_elite(sim, "held", [10, 0])
	add_elite(sim, "goon", [-1, 0])
	phantom_declare(sim, "psy", "held")
	advance(sim)
	# L1 drag 2 (PH — the trained hold outpulls the parent's 1)...
	assert_rejected(phantom_sustain(sim, "psy", {"drag_to": [7, 0]}), "drag_out_of_range",
		"three hexes is past the L1 limit")
	phantom_sustain(sim, "psy", {"drag_to": [8, 0]})
	var ev: Array[Dictionary] = advance(sim)
	var dragged: Dictionary = assert_event(ev, "telekinesis_dragged", "the two-hex drag walks")
	assert_eq(dragged.get("to", []), [8, 0], "to the declared hex")
	assert_eq((sim.combatants["held"] as CombatantState).position, Vector2i(8, 0), "the body moved 2")
	# ...while the parent keeps its authored single hex (behavior pin).
	var sim2: CombatSim = make_sim(7306)
	add_party(sim2, "tk", [0, 0])
	add_elite(sim2, "t", [3, 0])
	declare(sim2, "tk", {"kind": "skill", "key": "telekinesis", "level": 1, "targets": [{"id": "t"}]})
	advance(sim2)
	assert_rejected(declare(sim2, "tk", {"kind": "skill", "key": "telekinesis", "level": 1,
		"sustain": true, "drag_to": [5, 0]}), "drag_out_of_range", "telekinesis still drags 1")
	# Break on damage: the goon hits the sustainer — the hold snaps (sweep).
	phantom_sustain(sim, "psy")
	declare(sim, "goon", attack_action("crushed", 3, "psy", "torso"))
	var hit_ev: Array[Dictionary] = advance(sim)
	assert_eq(String(assert_event(hit_ev, "telekinesis_released", "the break").get("reason", "")),
		"damaged", "break-on-damage, kept from the parent")


# ================================================ serialization & determinism

func test_wave1_state_round_trips_mid_everything() -> void:
	var live: CombatSim = make_sim(7401)
	add_party(live, "ace", [0, 0])
	add_party(live, "psy", [0, 5], {"traits": {"physique": 2, "reflexes": 3, "mind": 8, "charm": 3}})
	add_elite(live, "ea", [2, 0])
	add_elite(live, "held", [8, 5])
	apply_cond(live, "ace", "torso", "bleeding", 2)
	phantom_declare(live, "psy", "held")
	advance(live)
	# Arm the L4 fused evasion and spend the negate; leave the L3 window live.
	declare(live, "ea", attack_action("crushed", 3, "ace", "torso", {"cost": 2, "attack_range": 4}))
	evade_declare(live, "ace", [1, 0], 4)
	declare(live, "ace", attack_action("crushed", 1, "ea", "torso", {"attack_range": 3}))
	phantom_sustain(live, "psy")
	advance(live)
	evade_declare(live, "ace", [0, 0], 4)
	var ace_live: CombatantState = live.combatants["ace"]
	assert_eq(ace_live.negate_used_clock, 0, "the negate marker is live pre-round-trip")
	assert_false(ace_live.evasion.is_empty(), "the window record is live pre-round-trip")
	var restored: CombatSim = CombatSim.from_dict(live.to_dict())
	assert_eq(restored.state_hash(), live.state_hash(), "hash survives the mid-window round-trip")
	var ace_r: CombatantState = restored.combatants["ace"]
	assert_eq(ace_r.negate_used_clock, 0, "negate_used_clock round-trips")
	assert_false(ace_r.evasion.is_empty(), "the evasion window round-trips")
	assert_eq(int(ace_r.forced_save.get("dice", 0)), 8, "the armed fused save round-trips")
	assert_true(bool(ace_r.forced_save.get("negate", false)), "with its negate flag")
	assert_eq(String((restored.combatants["psy"] as CombatantState).channeling.get("grip", "")),
		"psychic", "the hold's grip value round-trips")
	# Both timelines continue identically.
	var live_tail: Array[Dictionary] = advance(live, 2)
	var rest_tail: Array[Dictionary] = advance(restored, 2)
	assert_eq(live_tail.size(), rest_tail.size(), "identical continuation")
	assert_eq(restored.state_hash(), live.state_hash(), "restore -> replay tail = same hash")


func test_wave1_fields_serialize_only_when_set() -> void:
	# The compat pin: a wave-free fight carries none of the new keys.
	var sim: CombatSim = make_sim(7402)
	add_party(sim, "a", [0, 0])
	add_elite(sim, "e", [1, 0])
	declare(sim, "a", attack_action("crushed", 2, "e", "torso"))
	advance(sim)
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		var c: Dictionary = dict["combatants"][id]
		assert_false(c.has("evasion"), "no 'evasion' key on an evasion-free combatant (%s)" % id)
		assert_false(c.has("negate_used_clock"), "no 'negate_used_clock' key when never used (%s)" % id)


func test_wave1_determinism_same_log_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(7403)
		add_party(sim, "ace", [0, 0])
		add_party(sim, "holder", [0, 4])
		add_party(sim, "psy", [0, 8], {"traits": {"physique": 2, "reflexes": 3, "mind": 8, "charm": 3}})
		add_elite(sim, "ea", [2, 0])
		add_elite(sim, "victim", [1, 4], {"traits": {"physique": 1, "reflexes": 1, "mind": 0, "charm": 1}})
		add_elite(sim, "held", [8, 8])
		apply_cond(sim, "ace", "torso", "bleeding", 2)
		declare(sim, "ea", attack_action("crushed", 3, "ace", "torso", {"cost": 2, "attack_range": 4}))
		evade_declare(sim, "ace", [1, 0], 4)
		declare(sim, "ace", attack_action("crushed", 1, "ea", "torso", {"attack_range": 3}))
		vice_declare(sim, "holder", "victim", 2)
		phantom_declare(sim, "psy", "held")
		advance(sim)
		phantom_sustain(sim, "psy", {"drag_to": [6, 8]})
		declare(sim, "held", {"kind": "grapple_escape"})
		vice_declare(sim, "holder", "victim", 2, {"drag_to": [-2, 4]})
		advance(sim, 12)  # through the Clock reset (standing bleed advances)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash across the whole wave")
