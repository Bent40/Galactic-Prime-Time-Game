extends SimTestBase
## Round 5 — voicebox (BASE skill, data id 34): the authored no-visible-source
## noise R20's hearing marker reserved its LOUD lane for ("the voicebox
## skill's thrown sounds are exactly this substrate"). What these tests pin:
##   * the base-skill contract: KNOWN_KEYS membership + the ruled keyword
##     entry + the thrown_sound spec (cost 0, LOUD 10 verbatim, throw range);
##   * the throw itself: a chosen hex within range, NO LOS gate (sound
##     placement is acoustic — the model's sound already ignores walls), the
##     R3 free-slot economy;
##   * THE HEADLINE (R20's contract): a stealthed thrower stays UNREVEALED
##     while a hearing investigator walks to the THROWN hex — alerted, never
##     located — and the alert state stores the sound's hex, no source id;
##   * the authored-row exemption: a VISIBLE thrower's sound still alerts
##     (nothing is visible AT the sound's hex — the redundancy filter is
##     waived for authored rows only);
##   * discipline: zero rng (twin-state compare), determinism, and the
##     no-new-state serialization pin (voicebox adds no combatant fields).
## The data row's social half (previously-heard requirement, Mind-3
## recognition, the "+1 Strength" fidelity rows) stays DATA — no social
## substrate exists; nothing here fakes one.

func add_enemy(sim: CombatSim, id: String, key: String, pos: Array) -> void:
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "enemy": key, "team": "enemies", "position": pos}})


func stealth(sim: CombatSim, actor: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "stealth", "actor": actor, "set": "hide"})


func throw_sound(sim: CombatSim, actor: String, at: Array, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "voicebox", "level": level, "at": at})


# ------------------------------------------------------------- data contract

func test_base_skill_contract_known_key_keywords_and_spec() -> void:
	# voicebox is a BASE skill (unlike the tier-2 results): KNOWN_KEYS carries
	# it, and its ruled skill_keywords.json entry predates this wave.
	assert_true(SkillBook.is_known("voicebox"), "voicebox joins KNOWN_KEYS (base skill)")
	var keywords: Dictionary = (load_json("res://data/skill_keywords.json") as Dictionary).get("skills", {})
	assert_eq(keywords.get("voicebox", []), ["performance", "sound"],
		"the ruled keyword entry stands (G3 — KNOWN_KEYS membership requires it)")
	for lv: int in range(1, 5):
		var spec: Dictionary = SkillBook.mechanics("voicebox", lv)
		assert_eq(String(spec.get("archetype", "")), "thrown_sound", "the Round-5 archetype (L%d)" % lv)
		assert_eq(int(spec.get("cost", -1)), 0, "cost 0 — the data row's base_moment_cost (L%d)" % lv)
		assert_eq(int(spec.get("loudness", 0)), Stealth.NOISE_LOUD,
			"a mimicked shout = LOUD 10, the R20 table VERBATIM — no new loudness row (L%d)" % lv)
		assert_eq(int(spec.get("throw_range", 0)), 10, "throw range 10 (AUTHORED, PH — L%d)" % lv)
	assert_false(SkillBook.is_self_skill("voicebox"),
		"the throw names a HEX — the HUD asks for an aim (the blast convention)")


func test_throw_gates_shape_range_and_free_slot() -> void:
	var sim: CombatSim = make_sim(7501)
	add_human(sim, "mimic", {"team": "party", "position": [0, 0]})
	add_enemy(sim, "hound", "war_hound", [15, 0])
	assert_rejected(declare(sim, "mimic", {"kind": "skill", "key": "voicebox", "level": 1}),
		"throw_target_required", "a throw names a hex")
	assert_rejected(throw_sound(sim, "mimic", [11, 0]),
		"out_of_range", "eleven hexes is past the throw range 10")
	# The R3/R34 free-action economy: the throw draws on the budget
	# (CombatantState.FREE_ACTIONS_PER_CLOCK per tick since the owner's
	# 2026-08-19 ruling) — bounded per Moment, never spammable.
	assert_event(throw_sound(sim, "mimic", [10, 0]), "action_declared", "a legal throw declares")
	assert_event(throw_sound(sim, "mimic", [9, 0]), "action_declared",
		"a second throw rides the budget's second entry")
	assert_rejected(throw_sound(sim, "mimic", [8, 0]),
		"free_action_used", "the budget is spent — never spammable within a Moment")
	# Out-of-bounds hexes have nowhere for a sound to happen (arena set).
	var sim2: CombatSim = make_sim(7502)
	sim2.apply_command({"type": "set_arena", "arena": {"bounds": {"width": 8, "height": 8}}})
	add_human(sim2, "mimic", {"team": "party", "position": [0, 0]})
	assert_rejected(throw_sound(sim2, "mimic", [9, 0]),
		"out_of_bounds", "the thrown hex must exist in the room")


# ------------------------------------- the headline: alerted, never located

func test_stealthed_thrower_alerts_investigator_to_thrown_hex_unrevealed() -> void:
	# THE R20 CONTRACT PIN: the hidden mimic throws a shout far from itself;
	# the hearing investigator walks to the THROWN hex; the mimic is never
	# revealed. The LOUD alert row is finally reachable FROM stealth.
	var sim: CombatSim = make_sim(7503)
	add_enemy(sim, "hound", "war_hound", [0, 0])  # Mind 1: sight 2; herder -> investigates
	add_human(sim, "mimic", {"team": "party", "position": [0, 6]})
	assert_event(stealth(sim, "mimic"), "stealth_entered", "distance 6 > sight 2 — the hide is legal")
	advance(sim, 1)
	var declared: Array[Dictionary] = throw_sound(sim, "mimic", [6, 0])
	assert_event(declared, "action_declared", "the throw declares (cost 0)")
	var resolution: Array[Dictionary] = advance(sim, 1)
	var thrown: Dictionary = assert_event(resolution, "sound_thrown", "the authored noise happens")
	assert_eq(thrown.get("position", []), [6, 0], "at the THROWN hex — not the thrower's")
	assert_eq(int(thrown.get("loudness", 0)), Stealth.NOISE_LOUD, "LOUD 10 — the reserved row")
	var heard: Dictionary = assert_event(resolution, "noise_heard", "the hound hears it (distance 6 <= 10)")
	assert_eq(String(heard.get("combatant", "")), "hound", "the hound is the hearer")
	assert_eq(String(heard.get("source", "")), "mimic", "the broadcast names the thrower (omniscient cameras)")
	assert_event(resolution, "alerted", "unalerted -> ALERTED transition")
	var mimic: CombatantState = sim.combatants["mimic"]
	var hound: CombatantState = sim.combatants["hound"]
	assert_true(mimic.stealthed, "throwing a sound does NOT break stealth — the whole point")
	assert_eq(hound.alerted.get("sound", []), [6, 0],
		"the alert stores WHERE THE SOUND WAS — the thrown hex, never the thrower's")
	var alert_keys: Array = hound.alerted.keys()
	alert_keys.sort()
	assert_eq(alert_keys, ["sound", "tick"], "no source id in the state — alerted, not located (R20)")
	# The investigator WALKS TO THE THROWN HEX (the scapegoat payoff): the
	# hound has no visible target (the mimic is hidden), so its turn is the
	# alert investigation — a step toward [6, 0], AWAY from the mimic.
	var d_sound_before: int = CombatantState.hex_distance(hound.position, Vector2i(6, 0))
	var d_mimic_before: int = CombatantState.hex_distance(hound.position, mimic.position)
	var turn: Array[Dictionary] = sim.apply_command({"type": "ai_decide", "actor": "hound"})
	var decision: Dictionary = assert_event(turn, "ai_decision", "the hound acts on the alert")
	assert_true(bool(decision.get("moves", false)), "the investigator moves")
	assert_true(CombatantState.hex_distance(hound.position, Vector2i(6, 0)) < d_sound_before,
		"toward the hex the sound happened on")
	assert_true(CombatantState.hex_distance(hound.position, mimic.position) >= d_mimic_before,
		"never toward the hidden thrower")
	assert_true(mimic.stealthed, "the walk re-opened no cone onto the mimic — still unrevealed")


func test_visible_thrower_sound_still_alerts_the_authored_exemption() -> void:
	# The authored-row exemption: a VISIBLE thrower's sound is NOT redundant
	# with detection — nothing is visible AT the sound's hex (the scapegoat
	# play works in the open). Contrast pin: the same thrower's own FOOTSTEPS
	# stay filtered (the round-3b redundancy discipline, unchanged).
	var sim: CombatSim = make_sim(7504)
	add_enemy(sim, "hound", "war_hound", [0, 0])
	add_human(sim, "mimic", {"team": "party", "position": [0, 2]})  # sight 2: SEEN
	var step: Array[Dictionary] = sim.apply_command({"type": "move", "actor": "mimic", "to": [0, 3]})
	assert_no_event(step, "noise_heard", "a visible mover's footsteps stay redundant (round 3b)")
	advance(sim, 1)
	throw_sound(sim, "mimic", [8, 0])
	var resolution: Array[Dictionary] = advance(sim, 1)
	assert_event(resolution, "sound_thrown", "the visible thrower still throws")
	var heard: Dictionary = assert_event(resolution, "noise_heard",
		"the AUTHORED row is consumed — the filter is waived for no-visible-source noises")
	assert_eq(String(heard.get("combatant", "")), "hound", "the hound alerts")
	assert_eq((sim.combatants["hound"] as CombatantState).alerted.get("sound", []), [8, 0],
		"toward the thrown hex — misdirection works in the open")


func test_throw_ignores_walls_and_the_hearer_gates_hold() -> void:
	# No LOS gate on the throw — the mimicked sound is PLACED across a wall
	# the thrower cannot see past (sound placement is acoustic, not
	# ballistic; the aoe_blast family's no_line_of_sight reject deliberately
	# does not apply). The sound's own wall-blindness (a hearer hears through
	# walls) is round 3b's pinned rule, inherited unchanged. Hearer gates
	# hold: the thrower's own teammate never alerts.
	var sim: CombatSim = make_sim(7505)
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 15, "height": 15},
		"walls": [[3, 0]]}})
	add_enemy(sim, "hound", "war_hound", [7, 0])  # the 15x15 rect centers: q,r in [-7, 8)
	add_human(sim, "mimic", {"team": "party", "position": [0, 0]})
	add_human(sim, "buddy", {"team": "party", "position": [0, 1]})
	assert_true(sim.combatants.has("hound"), "precondition: the hound staged in bounds")
	assert_event(stealth(sim, "mimic"), "stealth_entered", "distance 7 > sight 2 — the hide is legal")
	advance(sim, 1)
	assert_event(throw_sound(sim, "mimic", [4, 0]), "action_declared",
		"the throw line crosses the wall at [3,0] — no LOS gate, deliberately")
	var resolution: Array[Dictionary] = advance(sim, 1)
	var heard: Dictionary = assert_event(resolution, "noise_heard",
		"the hound hears the sound placed behind the thrower's wall (distance 3 <= 10)")
	assert_eq(String(heard.get("combatant", "")), "hound", "the hound is the hearer")
	assert_true((sim.combatants["buddy"] as CombatantState).alerted.is_empty(),
		"a party member never alerts — AI-only substrate, and your own side's noise alarms nobody")
	assert_true((sim.combatants["mimic"] as CombatantState).stealthed, "still hidden")


# --------------------------------------------------- discipline: rng + hashes

func test_twin_rng_throw_and_alert_consume_zero_rng() -> void:
	# Twin sims, same seed: twin B additionally throws a sound and alerts the
	# hound. The next Forced Body draw must be the SAME stream value in both —
	# the throw, the noise sweep and the alert consume ZERO rng.
	var twin_a: CombatSim = make_sim(7506)
	var twin_b: CombatSim = make_sim(7506)
	for twin: CombatSim in [twin_a, twin_b]:
		add_enemy(twin, "hound", "war_hound", [0, 0])
		add_human(twin, "mimic", {"team": "party", "position": [0, 6]})
		add_human(twin, "weakling", {"team": "party", "position": [1, 0],
			"traits": {"physique": 1, "reflexes": 3, "mind": 3, "charm": 3}})
		stealth(twin, "mimic")
		advance(twin, 1)
	throw_sound(twin_b, "mimic", [6, 0])
	advance(twin_b, 1)
	assert_false((twin_b.combatants["hound"] as CombatantState).alerted.is_empty(),
		"precondition: twin B's hound really alerted")
	# The stream probe: an above-weight grapple's Forced Body (physique 1 < 2).
	for twin: CombatSim in [twin_a, twin_b]:
		declare(twin, "weakling", {"kind": "grapple", "target": "hound"})
	var roll_a: int = int(assert_event(advance(twin_a, 1), "forced_action_triggered", "twin A probe").get("roll", -1))
	var roll_b: int = int(assert_event(advance(twin_b, 1), "forced_action_triggered", "twin B probe").get("roll", -2))
	assert_eq(roll_a, roll_b, "identical stream draw — the throw consumed zero rng")


func test_no_new_state_and_determinism() -> void:
	# voicebox adds NO combatant fields — the alert it causes rides the
	# round-3b `alerted` state unchanged. A throw-free fight's serialization
	# carries nothing new by construction; here: the same throw-heavy command
	# log lands the same hash twice, and a mid-alert round-trip is faithful.
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(7507)
		add_enemy(sim, "hound", "war_hound", [0, 0])
		add_human(sim, "mimic", {"team": "party", "position": [0, 6]})
		stealth(sim, "mimic")
		advance(sim, 1)
		throw_sound(sim, "mimic", [6, 0])
		advance(sim, 2)
		throw_sound(sim, "mimic", [2, 0])
		advance(sim, 3)
		hashes.append(sim.state_hash())
		if run == 0:
			var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
			assert_eq(restored.state_hash(), sim.state_hash(), "mid-alert round-trip is hash-faithful")
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash through the throws")
