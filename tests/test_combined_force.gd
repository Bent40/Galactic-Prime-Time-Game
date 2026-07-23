extends SimTestBase
## R15 MERGED FORCE (rules-addendum R15; closes the R14 TODO in
## ActionResolver._strike_round): linked strikes (shared combo_id) that resolve
## on the SAME tick against the SAME target+part merge their Force values BEFORE
## the robustness gate — one merged gate, one merged net-damage hit, surfaced as
## a combined_force event. This is the intended counter to a Robustness no
## single attacker can clear (the F5 fight's designed breach path).
##
## Resolution order (as implemented in ActionResolver):
##   1. resolve_due PRE-SCANS the due entries: strike entries (kind attack/skill,
##      non-empty combo_id, first target) bucket by (combo_id, target, part);
##      buckets of 2+ become merged groups — membership only, no numbers yet.
##   2. Each member's _strike_round runs at its normal position in declaration
##      (seq) order: its OWN dodge check happens exactly where it does today (the
##      salted AI stream order is unchanged, R22), and its ACTUAL Force (halving applied)
##      is contributed only if it connects. Dodged / surface-blocked /
##      fire-healed / non-Physical members drop out of the sum.
##   3. The LAST accounted-for member closes the group: ONE merged application
##      net = max(0, sum(Forces) − Robustness) → one damage_applied +
##      combined_force + ONE record_hit for the breach threshold. When the hit
##      LANDS, EVERY connected member's condition rides the one wound; blocked
##      to 0, the D3 rule holds (no bleed/burn/poison seeds).
##   4. A member that never reaches _strike_round (whiff, invalidated windup,
##      feint collapse, shock stutter) is flushed at the end of the batch — what
##      DID connect still lands as the one merged hit.

func _target_spec(id: String, physique: int, extra: Dictionary = {}) -> Dictionary:
	var spec: Dictionary = {
		"id": id, "name": id, "category": "Boss", "size": "Large",
		"position": [1, 0],
		"traits": {"physique": physique, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [{"key": "hide", "hp": 60, "lethal": true}],
	}
	spec.merge(extra, true)
	return spec


## (a) Two linked strikes merge Force and beat a Robustness NEITHER could alone:
## solo Force 5 vs Robustness 5 is blocked to 0 (5 > 5 false), but the merged
## 5 + 5 = 10 > 5 lands net 5 as ONE damage application.
func test_merged_force_beats_robustness_neither_could_alone() -> void:
	# Solo control: each phys-4 attacker's amount-3 strike (Force 3 + 2 = 5)
	# against a phys-10 target (Robustness 5) is blocked to 0.
	var solo: CombatSim = make_sim(11)
	add_human(solo, "p1", {"position": [0, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	solo.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 10)})
	declare(solo, "p1", attack_action("crushed", 3, "t", "hide"))
	var solo_events: Array[Dictionary] = advance(solo)
	var solo_dmg: Dictionary = assert_event(solo_events, "damage_applied", "solo strike still applies (at 0)")
	assert_eq(int(solo_dmg.get("amount", -1)), 0, "solo: Force 5 ≤ Robustness 5 — blocked to 0")
	assert_event(solo_events, "attack_no_wound", "solo blocked hit opens no wound")

	# Merged: the same two strikes linked → Force 5 + 5 = 10 > 5 → net 5, ONE hit.
	var sim: CombatSim = make_sim(11)
	add_human(sim, "p1", {"position": [0, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "p2", {"position": [2, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 10)})
	sim.apply_command({"type": "combined_action", "members": [
		{"actor": "p1", "action": attack_action("crushed", 3, "t", "hide")},
		{"actor": "p2", "action": attack_action("crushed", 3, "t", "hide")},
	]})
	var events: Array[Dictionary] = advance(sim)
	assert_eq(events_of(events, "damage_applied").size(), 1, "ONE merged damage application")
	var cf: Dictionary = assert_event(events, "combined_force", "the merged gate is surfaced")
	assert_eq(int(cf.get("force", -1)), 10, "merged Force (3+2) + (3+2) = 10")
	assert_eq(int(cf.get("robustness", -1)), 5, "one merged gate: Robustness floor(10/2) = 5")
	assert_eq(int(cf.get("net", -1)), 5, "net = max(0, 10 − 5) = 5")
	assert_eq(int(first_event(events, "damage_applied").get("amount", -1)), 5, "the one hit carries the merged net")
	assert_eq(int((sim.combatants["t"] as CombatantState).parts["hide"]["hp"]), 55, "60 − 5 = 55")


## (b) A blocked merge (sum ≤ Robustness) deals 0 and seeds NO bleeding (D3).
func test_blocked_merge_deals_zero_and_seeds_no_bleed() -> void:
	var sim: CombatSim = make_sim(22)
	add_human(sim, "p1", {"position": [0, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "p2", {"position": [2, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 20)})
	sim.apply_command({"type": "combined_action", "members": [
		{"actor": "p1", "action": attack_action("bleeding", 3, "t", "hide")},
		{"actor": "p2", "action": attack_action("bleeding", 3, "t", "hide")},
	]})
	var events: Array[Dictionary] = advance(sim)
	var cf: Dictionary = assert_event(events, "combined_force", "the merged gate still evaluates")
	assert_eq(int(cf.get("force", -1)), 10, "merged Force (3+2) + (3+2) = 10")
	assert_eq(int(cf.get("net", -1)), 0, "net = max(0, 10 − 10) = 0 — blocked")
	assert_eq(int(first_event(events, "damage_applied").get("amount", -1)), 0, "the merged hit deals 0")
	assert_eq(events_of(events, "attack_no_wound").size(), 2, "each member's bleed is refused a wound (D3)")
	assert_no_event(events, "condition_applied", "a hit blocked to 0 seeds NO bleeding")
	var t: CombatantState = sim.combatants["t"]
	assert_eq(t.condition_tier("hide", "bleeding"), 0, "no bleeding tier on the target")
	# phys 20 grants +2 max HP per part (over-10 bonus), so full = 60 + 2 = 62.
	assert_eq(int(t.parts["hide"]["hp"]), 62, "no HP lost (full 62)")


## (c) A landed merge applies BOTH members' conditions — a crushing and a
## bleeding component both ride the ONE wound.
func test_landed_merge_applies_both_members_conditions() -> void:
	var sim: CombatSim = make_sim(33)
	add_human(sim, "p1", {"position": [0, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "p2", {"position": [2, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 6)})
	sim.apply_command({"type": "combined_action", "members": [
		{"actor": "p1", "action": attack_action("crushed", 4, "t", "hide")},
		{"actor": "p2", "action": attack_action("bleeding", 4, "t", "hide")},
	]})
	var events: Array[Dictionary] = advance(sim)
	var cf: Dictionary = assert_event(events, "combined_force", "merged gate")
	assert_eq(int(cf.get("net", -1)), 9, "net = (4+2) + (4+2) − 3 = 9")
	assert_eq(events_of(events, "damage_applied").size(), 1, "ONE wound")
	var t: CombatantState = sim.combatants["t"]
	assert_eq(t.condition_tier("hide", "crushed"), 1, "p1's crushed T1 rides the wound")
	assert_eq(t.condition_tier("hide", "bleeding"), 1, "p2's bleeding T1 rides the same wound")


## (d) A dodged member's Force drops OUT of the merged sum. Each member runs
## its own R22 dodge check inside its own _strike_round (the AI stream is
## consumed in the same order as un-merged play). Threshold 6 vs the target's
## Reflexes 3: the 1d4 fallback dodges on a 3+ (~50%). Seed 4: p1 (Force
## 4+2 = 6) is DODGED (roll 4), p2 (Force 5+2 = 7) connects (roll 2) → merged
## hit is p2-only: net = 7 − 3 = 4 (a both-connect run would net 6 + 7 − 3 = 10).
func test_dodged_members_force_drops_out() -> void:
	var sim: CombatSim = CombatSim.new(4, load_static_data())
	add_human(sim, "p1", {"position": [0, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "p2", {"position": [2, 0], "traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("d", 6, {"boss_traits": {"dodge_threshold": 6}})})
	sim.apply_command({"type": "combined_action", "members": [
		{"actor": "p1", "action": attack_action("crushed", 4, "d", "hide")},
		{"actor": "p2", "action": attack_action("crushed", 5, "d", "hide")},
	]})
	var events: Array[Dictionary] = advance(sim)
	assert_eq(events_of(events, "attack_dodged").size(), 1, "exactly one member is dodged (seed 4)")
	var cf: Dictionary = assert_event(events, "combined_force", "the reduced merge still applies")
	assert_eq(cf.get("actors", []), ["p2"], "only the connecting member contributes")
	assert_eq(int(cf.get("force", -1)), 7, "p1's dodged Force 6 dropped out — sum is p2's 7 alone")
	assert_eq(int(cf.get("net", -1)), 4, "net = 7 − 3 = 4 (not the both-connect 10)")
	assert_eq(events_of(events, "damage_applied").size(), 1, "one merged application")
	assert_eq(int(first_event(events, "damage_applied").get("amount", -1)), 4, "the reduced merged net lands")


## (e) Solo strikes are COMPLETELY unchanged — same numbers the R14 model
## produced before this change (the exact pre-fix slice arithmetic: Imani's
## strong-strike-shaped 6 nets 5; Dario's pressure-strike-shaped 2 is blocked
## to 0 and seeds no bleed).
func test_solo_strikes_unchanged() -> void:
	var sim: CombatSim = make_sim(44)
	add_human(sim, "imani", {"position": [0, 0], "traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	add_human(sim, "dario", {"position": [2, 0], "traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}})
	sim.apply_command({"type": "add_combatant", "combatant": _target_spec("t", 6)})
	declare(sim, "imani", attack_action("crushed", 6, "t", "hide"))
	var e1: Array[Dictionary] = advance(sim)
	assert_no_event(e1, "combined_force", "no combo_id — the solo path never merges")
	assert_eq(int(first_event(e1, "damage_applied").get("amount", -1)), 5, "solo: Force 6+2 = 8 − Robustness 3 = 5 (unchanged)")
	declare(sim, "dario", attack_action("bleeding", 2, "t", "hide"))
	var e2: Array[Dictionary] = advance(sim)
	assert_eq(int(first_event(e2, "damage_applied").get("amount", -1)), 0, "solo: Force 2+1 = 3 ≤ Robustness 3 — blocked (unchanged)")
	assert_event(e2, "attack_no_wound", "blocked solo bleed still seeds nothing (D3, unchanged)")
	assert_eq((sim.combatants["t"] as CombatantState).condition_tier("hide", "bleeding"), 0, "no bleed")


## (f) THE ACCEPTANCE — the real F5 slice staged exactly as the HUD stages it:
## the Incinedile + Imani + Dario, their REAL skills via kind:"skill", one
## combined_action ("party_combo") of Imani's strong_strike + Dario's
## pressure_strike on the flamethrower arm. Merged: Imani Force 6 + floor(5/2)
## = 8, Dario Force 2 + floor(2/2) = 3 → 11 − Robustness 3 = net 8 ≥ 7 →
## BREACH. The human path exists again. (dodge_threshold stripped exactly as
## the engine's own breach tests do — tests/test_incinedile.gd.)
func test_acceptance_real_slice_combined_skills_open_the_breach() -> void:
	var sim: CombatSim = make_sim(14)
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": _traits_without_dodge(),
	}})
	add_human(sim, "imani", {"team": "party", "position": [1, 0],
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	add_human(sim, "dario", {"team": "party", "position": [0, 1],
		"traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}})
	var combo: Array[Dictionary] = sim.apply_command({"type": "combined_action", "combo_id": "party_combo", "members": [
		{"actor": "imani", "action": {"kind": "skill", "key": "strong_strike", "level": 1,
			"attack_range": 2, "targets": [{"id": "boss", "part": "left_hand"}]}},
		{"actor": "dario", "action": {"kind": "skill", "key": "pressure_strike", "level": 1,
			"attack_range": 2, "targets": [{"id": "boss", "part": "left_hand"}]}},
	]})
	assert_event(combo, "combined_action_declared", "the linked declaration set is accepted")
	assert_eq(events_of(combo, "action_declared").size(), 2, "both members pay their own cost-2 windup")
	# Both skills are cost-2 windups: declared at tick 0, they resolve on tick 2.
	var events: Array[Dictionary] = advance(sim, 3)
	var cf: Dictionary = assert_event(events, "combined_force", "the merged gate fires on the resolve tick")
	assert_eq(String(cf.get("combo_id", "")), "party_combo", "the caller-named combo id links the strikes")
	assert_eq(int(cf.get("force", -1)), 11, "Imani (6+2) + Dario (2+1) = 11")
	assert_eq(int(cf.get("robustness", -1)), 3, "Incinedile Robustness floor(6/2) = 3")
	assert_eq(int(cf.get("net", -1)), 8, "net = 11 − 3 = 8 ≥ 7")
	assert_event(events, "breach_opened", "the merged hit opens the breach — the human path exists")
	var boss: CombatantState = sim.combatants["boss"]
	assert_true(boss.breached, "boss breached")
	assert_false(bool(boss.parts["network"].get("hidden", true)), "the mycelium network is exposed")
	# The one wound carries both components' conditions (crushed + bleeding T1).
	assert_eq(boss.condition_tier("left_hand", "crushed"), 1, "Imani's crushed rides the wound")
	assert_eq(boss.condition_tier("left_hand", "bleeding"), 1, "Dario's bleeding rides the wound")


## (g) Determinism round-trip: same (seed, command log) ⇒ same hash, and a
## snapshot taken MID-WINDUP (merged group not yet resolved — the transient
## merge table must never leak into serialized state) resumes to the same hash.
func test_merged_force_determinism_roundtrip() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = _staged_slice_sim()
		advance(sim, 3)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same seed + same command log = same state hash")

	# Snapshot after the combo is DECLARED but before it resolves (tick 1 of 3).
	var live: CombatSim = _staged_slice_sim()
	advance(live, 1)
	var resumed: CombatSim = CombatSim.from_dict(live.to_dict())
	var live_events: Array[Dictionary] = advance(live, 2)
	var resumed_events: Array[Dictionary] = advance(resumed, 2)
	assert_eq(resumed.state_hash(), live.state_hash(), "snapshot → restore → replay tail = same hash")
	var live_cf: Dictionary = first_event(live_events, "combined_force")
	var resumed_cf: Dictionary = first_event(resumed_events, "combined_force")
	assert_eq(int(resumed_cf.get("net", -1)), int(live_cf.get("net", -2)), "the resumed merge lands the same net")
	assert_true(bool((resumed.combatants["boss"] as CombatantState).breached), "the resumed run still breaches")


func _staged_slice_sim() -> CombatSim:
	var sim: CombatSim = make_sim(777)
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "Incinedile", "enemy": "incinedile",
		"team": "enemies", "position": [0, 0], "boss_traits": _traits_without_dodge(),
	}})
	add_human(sim, "imani", {"team": "party", "position": [1, 0],
		"traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}})
	add_human(sim, "dario", {"team": "party", "position": [0, 1],
		"traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5}})
	sim.apply_command({"type": "combined_action", "combo_id": "party_combo", "members": [
		{"actor": "imani", "action": {"kind": "skill", "key": "strong_strike", "level": 1,
			"attack_range": 2, "targets": [{"id": "boss", "part": "left_hand"}]}},
		{"actor": "dario", "action": {"kind": "skill", "key": "pressure_strike", "level": 1,
			"attack_range": 2, "targets": [{"id": "boss", "part": "left_hand"}]}},
	]})
	return sim


## The seeded Incinedile trait block minus the dodge threshold (the same spec
## choice tests/test_incinedile.gd and the slice drivers make).
func _traits_without_dodge() -> Dictionary:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var boss_traits: Dictionary = (e.get("traits", {}) as Dictionary).duplicate(true)
			boss_traits.erase("dodge_threshold")
			boss_traits.erase("dodge_threshold_note")
			return boss_traits
	return {}
