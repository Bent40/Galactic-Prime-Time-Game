extends SimTestBase
## Tier-2 wave 4 — the WAVE CLOSER (docs/design/tier2-rungs-proposal.md,
## BLESSED owner 2026-08-18): the last two ladders are encoded, closing the
## implementation wave (all ten a-d; every L5 mastery rung stays threshold
## DATA by the house convention):
##   S8 the_unseen — the stealth_conceal substrate EXTENDED: the headline
##      ANCHOR-LIFT (conceal_mobile: slow movement — 1 hex per Clock [PH] —
##      re-anchors the concealment instead of breaking it; fast movement, a
##      second same-Clock step or ATTACKING breaks), the reveal-radius rows
##      (L1 = 2, <= the parent's L5 radius — threshold row 81), and the S8-d
##      ally cover (one adjacent ally under an anchored, cover_by-linked
##      conceal). Camouflage's anchored behavior stays byte-identical —
##      contrast-pinned. S8-c (gap traversal) + the awareness passive stay
##      DATA ([NEEDS] — R29's graph is run-level; no gap substrate).
##   S9 the_long_con — the con as a SERIALIZED sustained state (never a
##      one-shot debuff): the perception-gated declare, the per-mark
##      next-action-AGAINST-YOU collapse (Tool; the S9-c Body choice at L3+),
##      the banked free 1-hex repositions outside the R3 economy, the S9-b
##      curated die manipulation, the S9-d per-Clock Charm-scaled hype beat,
##      and the AUTHORED end set (struck / lost perception / downed / scene).
## Plus: only-when-set serialization pins, round-trips, twin-RNG discipline,
## determinism. All magnitudes PLACEHOLDER (R14).

func add_party(sim: CombatSim, id: String, pos: Array, overrides: Dictionary = {}) -> void:
	var spec: Dictionary = {"team": "party", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}
	spec.merge(overrides, true)
	add_human(sim, id, spec)


func add_elite(sim: CombatSim, id: String, pos: Array, extra: Dictionary = {}) -> void:
	var spec: Dictionary = {
		"id": id, "name": id, "category": "Elite", "size": "Large",
		"team": "enemies", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 1},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
			{"key": "left_arm", "hp": 50, "lethal": false},
			{"key": "right_arm", "hp": 50, "lethal": false},
		],
	}
	spec.merge(extra, true)
	sim.apply_command({"type": "add_combatant", "combatant": spec})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func unseen_declare(sim: CombatSim, actor: String, level: int = 1, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "the_unseen", "level": level}
	action.merge(extra, true)
	return declare(sim, actor, action)


func con_declare(sim: CombatSim, actor: String, targets: Array, level: int = 1) -> Array[Dictionary]:
	var rows: Array = []
	for t: Variant in targets:
		rows.append(t if t is Dictionary else {"id": String(t)})
	return declare(sim, actor, {"kind": "skill", "key": "the_long_con", "level": level,
		"targets": rows})


# =========================================================== S8 the_unseen

func test_unseen_reveal_radius_beats_the_watcher_camouflage_could_not() -> void:
	# The anchor pin: L1 reveal radius 2 <= the parent's L5 radius (threshold
	# row 81's "-4 Reveal Space" off camouflage's 6). Same geometry, same
	# seed: camouflage L1 (radius 6) collapses in a Mind-5 watcher's sight;
	# the_unseen (radius 2) enters clean at distance 4.
	var watcher: Dictionary = {"traits": {"physique": 3, "reflexes": 3, "mind": 5, "charm": 1}}
	var sim_camo: CombatSim = make_sim(7601)
	add_party(sim_camo, "wraith", [0, 0])
	add_elite(sim_camo, "watcher", [4, 0], watcher)
	declare(sim_camo, "wraith", {"kind": "skill", "key": "camouflage", "level": 1})
	var camo: Array[Dictionary] = advance(sim_camo, 4)
	assert_eq(String(assert_event(camo, "action_invalidated", "camouflage collapses").get("reason", "")),
		"in_enemy_sight", "radius 6 > distance 4 — the parent is seen")
	var sim_un: CombatSim = make_sim(7601)
	add_party(sim_un, "wraith", [0, 0])
	add_elite(sim_un, "watcher", [4, 0], watcher)
	unseen_declare(sim_un, "wraith")
	var entered: Array[Dictionary] = advance(sim_un, 4)
	var entry: Dictionary = assert_event(entered, "stealth_entered", "the_unseen enters clean")
	assert_eq(String(entry.get("via", "")), "the_unseen", "attributed to the skill")
	assert_eq(int(entry.get("reveal_radius", 0)), 2, "L1 radius 2 (PH, <= the parent's L5)")
	var wraith: CombatantState = sim_un.combatants["wraith"]
	assert_true(wraith.stealthed, "hidden at distance 4 > radius 2")
	assert_true(bool(wraith.conceal.get("mobile", false)), "the conceal is MOBILE — the anchor-lift")
	var keys: Array = wraith.conceal.keys()
	keys.sort()
	assert_eq(keys, ["anchor", "mobile", "radius"], "the mobile conceal record shape")


func test_unseen_slow_movement_reanchors_one_hex_per_clock() -> void:
	# THE HEADLINE MECHANISM: a 1-hex step re-ANCHORS the concealment (once
	# per Clock — "slow" AUTHORED as 1 hex per Clock, PH); the budget re-opens
	# at the reset; a second same-Clock step breaks.
	var sim: CombatSim = make_sim(7602)
	add_party(sim, "wraith", [0, 0])
	add_elite(sim, "blind", [10, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 1}})
	unseen_declare(sim, "wraith")
	assert_event(advance(sim, 4), "stealth_entered", "entry at tick 3")
	var wraith: CombatantState = sim.combatants["wraith"]
	# Step 1 (Clock 0): the anchor follows.
	var step1: Array[Dictionary] = move(sim, "wraith", [1, 0])
	var shifted: Dictionary = assert_event(step1, "conceal_shifted", "slow movement no longer breaks it")
	assert_eq(shifted.get("to", []), [1, 0], "the anchor followed the step")
	assert_no_event(step1, "stealth_broken", "still concealed")
	assert_true(wraith.stealthed, "still hidden")
	assert_eq(wraith.conceal.get("anchor", []), [1, 0], "re-anchored")
	assert_eq(int(wraith.conceal.get("moved_clock", -1)), 0, "the Clock budget is spent")
	# Cross the reset (ticks 4..10) — the budget re-opens in Clock 1.
	advance(sim, 7)
	var step2: Array[Dictionary] = move(sim, "wraith", [2, 0])
	assert_event(step2, "conceal_shifted", "the budget re-opened at the reset")
	assert_true(wraith.stealthed, "still hidden after the second Clock's step")
	assert_eq(int(wraith.conceal.get("moved_clock", -1)), 1, "spent in Clock 1 now")
	# A second step in the SAME Clock is fast — the veil tears.
	advance(sim, 1)
	var step3: Array[Dictionary] = move(sim, "wraith", [3, 0])
	assert_eq(String(assert_event(step3, "stealth_broken", "the same-Clock second step breaks")
		.get("reason", "")), "moved", "reason: moved (faster than the veil)")
	assert_false(wraith.stealthed, "revealed")
	assert_true(wraith.conceal.is_empty(), "the conceal died with the stealth")


func test_unseen_fast_move_breaks_and_attack_breaks_with_base_contrast() -> void:
	var sim: CombatSim = make_sim(7603)
	add_party(sim, "wraith", [0, 0])
	add_elite(sim, "blind", [1, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 1}})
	unseen_declare(sim, "wraith")
	advance(sim, 4)
	# A 2-hex displacement in one command is FAST.
	var dash: Array[Dictionary] = move(sim, "wraith", [2, 0])
	assert_eq(String(assert_event(dash, "stealth_broken", "fast movement breaks").get("reason", "")),
		"moved", "the fast break")
	# Attacking breaks the MOBILE conceal at declare (the rung's own line).
	advance(sim, 1)
	unseen_declare(sim, "wraith")
	advance(sim, 4)
	assert_true((sim.combatants["wraith"] as CombatantState).stealthed, "re-hidden")
	var strike: Array[Dictionary] = declare(sim, "wraith",
		attack_action("crushed", 2, "blind", "torso"))
	assert_eq(String(assert_event(strike, "stealth_broken", "committing to the attack breaks")
		.get("reason", "")), "attacked", "the authored attack break — the_unseen only")
	advance(sim, 1)
	# CONTRAST PIN: base stealth keeps R20's no-break-on-attack line.
	var hide: Array[Dictionary] = sim.apply_command({"type": "stealth", "actor": "wraith", "set": "hide"})
	assert_event(hide, "stealth_entered", "the plain hide (the blind elite sees nothing)")
	var strike2: Array[Dictionary] = declare(sim, "wraith",
		attack_action("crushed", 2, "blind", "torso"))
	assert_no_event(strike2, "stealth_broken", "base stealth: attacking does NOT break (R20 unchanged)")
	advance(sim, 1)
	assert_true((sim.combatants["wraith"] as CombatantState).stealthed,
		"still hidden after the strike resolved — the attack break is per-skill, never global")


func test_unseen_creeping_into_the_radius_is_still_seen() -> void:
	# The re-anchor falls through to the sight sweep: a slow step INTO the
	# capped reveal radius is a slow step into being seen.
	var sim: CombatSim = make_sim(7604)
	add_party(sim, "wraith", [0, 0])
	add_elite(sim, "watcher", [4, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 5, "charm": 1}})
	unseen_declare(sim, "wraith")
	advance(sim, 4)
	# Step to distance 3: legal (radius 2), re-anchors.
	assert_event(move(sim, "wraith", [1, 0]), "conceal_shifted", "distance 3 > radius 2 — still veiled")
	advance(sim, 7)  # the next Clock's budget
	var creep: Array[Dictionary] = move(sim, "wraith", [2, 0])
	assert_event(creep, "conceal_shifted", "the step itself was slow — the anchor followed")
	var broken: Dictionary = assert_event(creep, "stealth_broken",
		"...but distance 2 <= radius 2 puts the wraith in the watcher's capped sight")
	assert_eq(String(broken.get("reason", "")), "seen", "seen, not moved")
	assert_eq(String(broken.get("observer", "")), "watcher", "by the watcher")


func test_unseen_ally_cover_l4() -> void:
	var blind: Dictionary = {"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 1}}
	var sim: CombatSim = make_sim(7605)
	add_party(sim, "wraith", [0, 0])
	add_party(sim, "scout", [0, 1])
	add_elite(sim, "blind", [10, 0], blind)
	# The L1 ask is locked; a non-adjacent ally rejects.
	assert_rejected(unseen_declare(sim, "wraith", 1, {"ally": "scout"}),
		"ally_conceal_locked", "S8-d is the L4 rung")
	move(sim, "scout", [0, 3])
	assert_rejected(unseen_declare(sim, "wraith", 4, {"ally": "scout"}),
		"ally_not_adjacent", "the cover reaches exactly one hex")
	advance(sim, 1)
	move(sim, "scout", [0, 1])
	# The L4 cover: one declare, both concealed at resolution.
	unseen_declare(sim, "wraith", 4, {"ally": "scout"})
	var entered: Array[Dictionary] = advance(sim, 4)
	assert_eq(events_of(entered, "stealth_entered").size(), 2, "both enter under one windup")
	var wraith: CombatantState = sim.combatants["wraith"]
	var scout: CombatantState = sim.combatants["scout"]
	assert_true(wraith.stealthed and scout.stealthed, "holder + ally hidden")
	assert_eq(String(scout.conceal.get("cover_by", "")), "wraith", "the cover link")
	assert_eq(int(scout.conceal.get("radius", 0)), 1, "the ally rides the L4 radius (PH)")
	assert_false(scout.conceal.has("mobile"), "the ally's cover is ANCHORED — only the holder moves veiled")
	# The ally's own movement breaks the ally only.
	var step: Array[Dictionary] = move(sim, "scout", [1, 1])
	assert_eq(String(assert_event(step, "stealth_broken", "the covered ally moved").get("reason", "")),
		"moved", "the anchored rule")
	assert_true(wraith.stealthed, "the holder's own veil is untouched")
	# And the cover dies with the holder's stealth (the link pass).
	var sim2: CombatSim = make_sim(7606)
	add_party(sim2, "wraith", [0, 0])
	add_party(sim2, "scout", [0, 1])
	add_elite(sim2, "blind", [10, 0], blind)
	unseen_declare(sim2, "wraith", 4, {"ally": "scout"})
	advance(sim2, 4)
	var reveal: Array[Dictionary] = sim2.apply_command({"type": "stealth", "actor": "wraith", "set": "reveal"})
	var reasons: Array[String] = []
	for broken: Dictionary in events_of(reveal, "stealth_broken"):
		reasons.append(String(broken.get("reason", "")))
	assert_true(reasons.has("revealed_self"), "the holder dropped the veil")
	assert_true(reasons.has("cover_lost"), "the ally's cover died with it — same batch (the link pass)")
	assert_false((sim2.combatants["scout"] as CombatantState).stealthed, "the ally is out")


func test_unseen_spec_anchors_and_camouflage_untouched() -> void:
	for lv: int in range(1, 5):
		var spec: Dictionary = SkillBook.mechanics("the_unseen", lv)
		assert_eq(String(spec.get("archetype", "")), "stealth_conceal", "the substrate (L%d)" % lv)
		assert_eq(int(spec.get("reveal_radius", 0)), [2, 1, 1, 1][lv - 1],
			"radius rows shrink to the floor 1 — radius 0 is the L5 vanish, threshold data (L%d)" % lv)
		assert_true(bool(spec.get("conceal_mobile", false)), "mobile at every level (L%d)" % lv)
		assert_eq(int(spec.get("awareness_range", 0)), [20, 25, 25, 30][lv - 1],
			"awareness rows CARRIED as data (>= nightlurking Lv3's 20; nothing consumes them yet) (L%d)" % lv)
		assert_eq(bool(spec.get("ally_conceal", false)), lv >= 4, "S8-d is the L4 rung (L%d)" % lv)
		# The parent's spec is untouched — the anchored family contrast pin.
		var camo: Dictionary = SkillBook.mechanics("camouflage", lv)
		assert_eq(int(camo.get("reveal_radius", 0)), [6, 5, 4, 3][lv - 1], "camouflage radius rows stand")
		assert_false(camo.has("conceal_mobile"), "camouflage is not mobile")
		assert_false(camo.has("ally_conceal"), "camouflage covers nobody else")
	assert_false(SkillBook.is_known("the_unseen"), "not in KNOWN_KEYS (acquisition-gated)")


func test_camouflage_conceal_record_and_break_byte_identical_to_batch_d() -> void:
	# The legacy pin the anchor-lift promised: an existing conceal stays
	# anchored — record shape {anchor, radius} exactly, ANY displacement
	# breaks, no mobile machinery anywhere near it.
	var sim: CombatSim = make_sim(7607)
	add_party(sim, "sneak", [0, 0])
	add_elite(sim, "blind", [10, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 1}})
	declare(sim, "sneak", {"kind": "skill", "key": "camouflage", "level": 1})
	advance(sim, 4)
	var sneak: CombatantState = sim.combatants["sneak"]
	assert_true(sneak.stealthed, "camouflaged")
	var keys: Array = sneak.conceal.keys()
	keys.sort()
	assert_eq(keys, ["anchor", "radius"], "the batch-D record shape — byte-identical, no new keys")
	var step: Array[Dictionary] = move(sim, "sneak", [1, 0])
	assert_eq(String(assert_event(step, "stealth_broken", "one hex off the anchor").get("reason", "")),
		"moved", "camouflage still breaks on ANY displacement")
	assert_no_event(step, "conceal_shifted", "no anchor ever follows a non-mobile conceal")


# =========================================================== S9 the_long_con

func test_con_declare_gates_and_serialized_state() -> void:
	var sim: CombatSim = make_sim(7701)
	add_party(sim, "grifter", [0, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 4}})
	add_elite(sim, "brute", [3, 0])
	add_elite(sim, "brute2", [3, 1])
	add_elite(sim, "brute3", [2, 2])
	add_elite(sim, "blind", [1, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 1}})
	assert_rejected(con_declare(sim, "grifter", []), "bad_target_count", "a con needs a mark")
	assert_rejected(con_declare(sim, "grifter", ["brute", "brute2", "brute3"]),
		"bad_target_count", "L1 projects at up to 2 (the blessed 1-2)")
	assert_rejected(con_declare(sim, "grifter", ["brute", "brute"]), "duplicate_target",
		"one entry per mark")
	assert_rejected(con_declare(sim, "grifter", ["blind"]), "target_cannot_perceive",
		"a Mind-0 mark cannot see the false read — the perception gate (R30 cone)")
	assert_rejected(con_declare(sim, "grifter", [{"id": "brute", "result": "body"}]),
		"result_choice_locked", "S9-c is the L3 rung")
	var declared: Array[Dictionary] = con_declare(sim, "grifter", ["brute", "brute2"])
	assert_event(declared, "action_declared", "the legal con declares (cost 1)")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var con_event: Dictionary = assert_event(resolved, "con_declared", "the con lands")
	assert_eq(con_event.get("targets", []), ["brute", "brute2"], "both marks named")
	var grifter: CombatantState = sim.combatants["grifter"]
	assert_eq(grifter.con.get("targets", {}), {"brute": "tool", "brute2": "tool"},
		"the SERIALIZED con state — per-mark tables, Tool by default")
	assert_eq(String((sim.combatants["brute"] as CombatantState).conned_by), "grifter", "the mirror")
	assert_rejected(con_declare(sim, "grifter", ["brute3"]), "con_active", "one con at a time")
	assert_rejected(con_declare(sim, "brute3", ["brute"]), "target_not_enemy",
		"the con projects at hostiles (the vibe_control gate)")


func test_con_fires_only_on_actions_against_the_holder() -> void:
	var sim: CombatSim = make_sim(7702)
	add_party(sim, "grifter", [0, 0])
	add_party(sim, "decoy", [0, 3])
	add_elite(sim, "brute", [3, 0])
	con_declare(sim, "grifter", ["brute"])
	advance(sim, 1)
	# The mark swings at the DECOY (still inside its cone with the grifter —
	# facing SW keeps W in the front arc): the con does NOT fire.
	declare(sim, "brute", attack_action("crushed", 2, "decoy", "torso", {"attack_range": 4}))
	var other: Array[Dictionary] = advance(sim, 1)
	assert_no_event(other, "con_fired", "an action at someone else is not 'against you'")
	var grifter: CombatantState = sim.combatants["grifter"]
	assert_false(grifter.con.is_empty(), "the con still holds")
	# The mark's next action AGAINST the holder collapses.
	declare(sim, "brute", attack_action("crushed", 5, "grifter", "torso", {"attack_range": 4}))
	var fired: Array[Dictionary] = advance(sim, 1)
	var invalidated: Dictionary = assert_event(fired, "action_invalidated", "the attack dies")
	assert_eq(String(invalidated.get("reason", "")), "conned", "reason: conned")
	assert_event(fired, "con_fired", "the firing beat")
	var forced: Dictionary = assert_event(fired, "forced_action_triggered", "the inflicted fumble")
	assert_eq(String(forced.get("table", "")), "tool", "Forced Action — TOOL (Feint's fumble, ambient)")
	assert_eq(String(forced.get("reason", "")), "conned", "attributed to the con")
	for dmg: Dictionary in events_of(fired, "damage_applied"):
		assert_ne(String(dmg.get("combatant", "")), "grifter", "the collapsed strike never landed")
	assert_event(fired, "con_step_banked", "each firing banks the free reposition")
	assert_event(fired, "con_ended", "the last mark firing plays the con out")
	assert_true(grifter.con.is_empty(), "the con completed")
	assert_eq(String((sim.combatants["brute"] as CombatantState).conned_by), "", "the mark is free")
	assert_eq(grifter.con_steps, 1, "one banked step")


func test_con_step_is_outside_the_movement_economy() -> void:
	var sim: CombatSim = make_sim(7703)
	add_party(sim, "grifter", [0, 0])
	add_elite(sim, "brute", [3, 0])
	con_declare(sim, "grifter", ["brute"])
	advance(sim, 1)
	declare(sim, "brute", attack_action("crushed", 3, "grifter", "torso", {"attack_range": 4}))
	advance(sim, 1)
	var grifter: CombatantState = sim.combatants["grifter"]
	assert_eq(grifter.con_steps, 1, "precondition: one banked step")
	# Credit-first: the 1-hex move spends the CREDIT — slot and allowance
	# untouched — and the ordinary free move is still available after it.
	var step: Array[Dictionary] = move(sim, "grifter", [0, 1])
	var moved: Dictionary = assert_event(step, "moved", "the banked step walks")
	assert_true(bool(moved.get("con_step", false)), "flagged as the con step")
	assert_eq(grifter.con_steps, 0, "the credit is spent")
	assert_false(grifter.free_action_used, "no free slot consumed — outside the R3 economy")
	assert_false(grifter.moved_this_tick, "no movement allowance consumed either")
	var free_move: Array[Dictionary] = move(sim, "grifter", [0, 3])
	var free_moved: Dictionary = assert_event(free_move, "moved", "the ordinary free move still stands")
	assert_false(bool(free_moved.get("con_step", false)), "the normal path, credit exhausted")
	assert_rejected(move(sim, "grifter", [0, 4]), "already_moved",
		"and the normal economy binds again — no credit, no third move")


func test_con_s9b_dice_curation_and_s9c_body_choice() -> void:
	# S9-b: extra dice on the inflicted roll, curated deterministically to the
	# severity-WORST for the victim (every die emitted). S9-c: the Body choice
	# per mark at L3+ — the parameterized collapse table.
	var sim: CombatSim = make_sim(7704)
	add_party(sim, "grifter", [0, 0])
	add_elite(sim, "brute", [3, 0])
	add_elite(sim, "brute2", [3, 1])
	con_declare(sim, "grifter", [{"id": "brute", "result": "tool"}, {"id": "brute2", "result": "body"}], 3)
	advance(sim, 1)
	declare(sim, "brute", attack_action("crushed", 2, "grifter", "torso", {"attack_range": 4}))
	var tool_fired: Array[Dictionary] = advance(sim, 1)
	var tool_dice: Dictionary = assert_event(tool_fired, "con_dice", "L3 draws an extra die (con_dice 1)")
	var tool_rolls: Array = tool_dice.get("rolls", [])
	assert_eq(tool_rolls.size(), 2, "base + 1 extra, every die emitted")
	var expected: int = int(tool_rolls[0])
	for r: Variant in tool_rolls:
		if ForcedAction.tool_severity({"consequence": ForcedAction.TOOL_TABLE[int(r) - 1]}) \
				> ForcedAction.tool_severity({"consequence": ForcedAction.TOOL_TABLE[expected - 1]}):
			expected = int(r)
	assert_eq(int(tool_dice.get("kept", -1)), expected,
		"the kept die is the TOOL-severity worst for the victim (tie keeps the earliest)")
	var tool_forced: Dictionary = assert_event(tool_fired, "forced_action_triggered", "the tool fumble")
	assert_eq(String(tool_forced.get("consequence", "")), ForcedAction.TOOL_TABLE[expected - 1],
		"the applied consequence IS the curated die")
	# The second mark stored the BODY choice.
	declare(sim, "brute2", attack_action("crushed", 2, "grifter", "torso", {"attack_range": 4}))
	var body_fired: Array[Dictionary] = advance(sim, 1)
	var body_forced: Dictionary = assert_event(body_fired, "forced_action_triggered", "the stumble")
	assert_eq(String(body_forced.get("table", "")), "body", "S9-c: the Body table per the stored choice")
	assert_event(body_fired, "con_ended", "both marks played out")


func test_con_authored_ends_struck_perception_mark_gone() -> void:
	# End 1 — the holder STRIKES: the con drops at the declare seam.
	var sim: CombatSim = make_sim(7705)
	add_party(sim, "grifter", [0, 0])
	add_elite(sim, "brute", [3, 0])
	con_declare(sim, "grifter", ["brute"])
	advance(sim, 1)
	var strike: Array[Dictionary] = declare(sim, "grifter",
		attack_action("crushed", 2, "brute", "torso", {"attack_range": 4}))
	var ended: Dictionary = assert_event(strike, "con_ended", "breaking it by striking")
	assert_eq(String(ended.get("reason", "")), "struck", "the authored end")
	assert_eq(String((sim.combatants["brute"] as CombatantState).conned_by), "", "the mark is free")
	# End 2 — the mark stops PERCEIVING the holder (its own declare turns its
	# cone away; the sweep reads Stealth.sees mark->holder every command).
	var sim2: CombatSim = make_sim(7706)
	add_party(sim2, "grifter", [0, 0])
	add_party(sim2, "decoy", [7, 0])  # farther than the grifter: the brute stages facing W
	add_elite(sim2, "brute", [3, 0])
	con_declare(sim2, "grifter", ["brute"])
	advance(sim2, 1)
	assert_false((sim2.combatants["grifter"] as CombatantState).con.is_empty(), "precondition: con live")
	var away: Array[Dictionary] = declare(sim2, "brute",
		attack_action("crushed", 2, "decoy", "torso", {"attack_range": 4}))
	var dropped: Dictionary = assert_event(away, "con_dropped", "facing E dropped the W holder from the cone")
	assert_eq(String(dropped.get("reason", "")), "lost_perception", "the authored perception end")
	assert_event(away, "con_ended", "no marks left")
	# End 3 — the mark goes down: a teammate's kill sweeps it out.
	var sim3: CombatSim = make_sim(7707)
	add_party(sim3, "grifter", [0, 0])
	add_party(sim3, "hitter", [2, 0])
	add_elite(sim3, "mook", [3, 0], {"size": "Medium",
		"traits": {"physique": 1, "reflexes": 1, "mind": 3, "charm": 1},
		"body_parts": [{"key": "torso", "hp": 1, "lethal": true}]})
	con_declare(sim3, "grifter", ["mook"])
	advance(sim3, 1)
	declare(sim3, "hitter", attack_action("crushed", 8, "mook", "torso", {"attack_range": 1}))
	var kill: Array[Dictionary] = advance(sim3, 1)
	assert_event(kill, "combatant_died", "the mook falls")
	assert_eq(String(assert_event(kill, "con_dropped", "the sweep clears the dead mark")
		.get("reason", "")), "mark_gone", "the downed-mark end")
	assert_true((sim3.combatants["grifter"] as CombatantState).con.is_empty(), "the con is over")


func test_con_s9d_hype_beat_charm_scaled_l4_only() -> void:
	# S9-d: while an L4+ con holds, each Clock reset pays a Charm-scaled
	# performance beat through the generic spectacle ingest. Below L4: silence.
	var sim: CombatSim = make_sim(7708)
	add_party(sim, "grifter", [0, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 4}})
	add_elite(sim, "brute", [3, 0])
	con_declare(sim, "grifter", ["brute"], 4)
	var held: Array[Dictionary] = advance(sim, 10)  # through the Clock reset
	assert_event(held, "clock_reset", "the Clock turned with the con held")
	var beat: Dictionary = assert_event(held, "con_performance", "the con-duration hype beat")
	assert_eq(int(beat.get("spectacle_points", 0)), 4,
		"base 1 x max(1, Charm 4) — small, Charm-scaled (R18 presence; PH)")
	assert_true((sim.combatants["grifter"] as CombatantState).con.is_empty() == false,
		"the con still holds — the beat never consumes it")
	# The L1 contrast: no beat.
	var sim2: CombatSim = make_sim(7709)
	add_party(sim2, "grifter", [0, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 4}})
	add_elite(sim2, "brute", [3, 0])
	con_declare(sim2, "grifter", ["brute"], 1)
	assert_no_event(advance(sim2, 10), "con_performance", "S9-d is the L4 rung")


func test_con_ai_mark_fires_through_ai_decide() -> void:
	# The AI path composes: a real enemy's ai_decide declares its attack at
	# the holder through the same resolver, and the resolution collapses.
	var sim: CombatSim = make_sim(7710)
	add_party(sim, "grifter", [0, 0])
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "hound", "name": "hound", "enemy": "war_hound", "team": "enemies", "position": [1, 0]}})
	con_declare(sim, "grifter", ["hound"])  # sight 2, adjacent: the hound perceives
	advance(sim, 1)
	assert_eq(String((sim.combatants["hound"] as CombatantState).conned_by), "grifter", "the hound is marked")
	sim.apply_command({"type": "ai_decide", "actor": "hound"})
	var fired: Array[Dictionary] = advance(sim, 3)
	var con_fired: Dictionary = assert_event(fired, "con_fired", "the hound's own attack fired the con")
	assert_eq(String(con_fired.get("victim", "")), "hound", "the mark is the victim")
	for dmg: Dictionary in events_of(fired, "damage_applied"):
		assert_ne(String(dmg.get("combatant", "")), "grifter", "the grifter was never touched")
	assert_eq((sim.combatants["grifter"] as CombatantState).con_steps, 1, "the step banked")


# ================================================ serialization & discipline

func test_wave4_fields_serialize_only_when_set() -> void:
	var sim: CombatSim = make_sim(7801)
	add_party(sim, "a", [0, 0])
	add_elite(sim, "e", [1, 0])
	declare(sim, "a", attack_action("crushed", 2, "e", "torso"))
	advance(sim, 1)
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		var c: Dictionary = dict["combatants"][id]
		assert_false(c.has("con"), "no 'con' key on a con-free combatant (%s)" % id)
		assert_false(c.has("conned_by"), "no 'conned_by' key when never marked (%s)" % id)
		assert_false(c.has("con_steps"), "no 'con_steps' key when never banked (%s)" % id)


func test_wave4_round_trip_mid_everything() -> void:
	var live: CombatSim = make_sim(7802)
	add_party(live, "wraith", [0, 0])
	add_party(live, "grifter", [10, 0])
	add_elite(live, "brute1", [13, 0])
	add_elite(live, "brute2", [13, 1])
	unseen_declare(live, "wraith")
	con_declare(live, "grifter", ["brute1", "brute2"], 2)
	declare(live, "brute1", attack_action("crushed", 3, "grifter", "torso", {"attack_range": 4}))
	var batch: Array[Dictionary] = advance(live, 4)
	assert_event(batch, "con_fired", "brute1's attack fired (one mark consumed)")
	assert_event(batch, "stealth_entered", "the wraith entered at tick 3")
	move(live, "wraith", [1, 0])  # mobile conceal mid-shift (moved_clock set)
	var grifter_live: CombatantState = live.combatants["grifter"]
	assert_eq(grifter_live.con.get("targets", {}), {"brute2": "tool"}, "one mark left, con still live")
	assert_eq(grifter_live.con_steps, 1, "one banked step pre-round-trip")
	var restored: CombatSim = CombatSim.from_dict(live.to_dict())
	assert_eq(restored.state_hash(), live.state_hash(), "hash survives the mid-wave round-trip")
	var grifter_r: CombatantState = restored.combatants["grifter"]
	assert_eq(grifter_r.con.get("targets", {}), {"brute2": "tool"}, "the con round-trips")
	assert_eq(int(grifter_r.con.get("dice", -1)), 1, "with its stamped dice")
	assert_eq(grifter_r.con_steps, 1, "the banked step round-trips")
	assert_eq(String((restored.combatants["brute2"] as CombatantState).conned_by), "grifter", "the mirror too")
	var wraith_r: CombatantState = restored.combatants["wraith"]
	assert_true(bool(wraith_r.conceal.get("mobile", false)), "the mobile conceal round-trips")
	assert_eq(int(wraith_r.conceal.get("moved_clock", -1)), 0, "with its spent Clock budget")
	# Both timelines continue identically.
	advance(live, 2)
	advance(restored, 2)
	assert_eq(restored.state_hash(), live.state_hash(), "restore -> replay tail = same hash")


func test_wave4_twin_rng_holding_the_states_consumes_zero_rng() -> void:
	# Twin sims, same seed: twin B additionally enters the_unseen, slow-steps,
	# and declares + HOLDS an L4 con across a Clock reset (the hype beat
	# included). No firing — declaring, sweeping, shifting and performing must
	# consume ZERO rng: the next Forced Body draw matches twin A's exactly.
	var twin_a: CombatSim = make_sim(7803)
	var twin_b: CombatSim = make_sim(7803)
	for twin: CombatSim in [twin_a, twin_b]:
		add_party(twin, "wraith", [0, 0])
		add_party(twin, "grifter", [10, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 4}})
		add_party(twin, "weakling", [12, 0], {"traits": {"physique": 1, "reflexes": 3, "mind": 3, "charm": 3}})
		add_elite(twin, "brute", [13, 0])  # stages facing its nearest opponent: W — the grifter stays in-cone
	unseen_declare(twin_b, "wraith")
	con_declare(twin_b, "grifter", ["brute"], 4)
	for twin: CombatSim in [twin_a, twin_b]:
		advance(twin, 4)
	move(twin_b, "wraith", [1, 0])
	for twin: CombatSim in [twin_a, twin_b]:
		advance(twin, 6)  # through the Clock reset (twin B pays the hype beat)
	assert_false((twin_b.combatants["grifter"] as CombatantState).con.is_empty(),
		"precondition: twin B held the con through the reset")
	# The stream probe: an above-weight grapple's Forced Body (physique 1 < 3).
	for twin: CombatSim in [twin_a, twin_b]:
		declare(twin, "weakling", {"kind": "grapple", "target": "brute"})
	var roll_a: int = int(assert_event(advance(twin_a, 1), "forced_action_triggered", "twin A probe").get("roll", -1))
	var roll_b: int = int(assert_event(advance(twin_b, 1), "forced_action_triggered", "twin B probe").get("roll", -2))
	assert_eq(roll_a, roll_b, "identical stream draw — holding the wave's states is rng-free")


func test_wave4_determinism_same_log_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(7804)
		add_party(sim, "wraith", [0, 0])
		add_party(sim, "grifter", [10, 0], {"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 4}})
		add_elite(sim, "brute1", [13, 0])
		add_elite(sim, "brute2", [13, 1])
		unseen_declare(sim, "wraith")
		con_declare(sim, "grifter", [{"id": "brute1", "result": "body"}, {"id": "brute2"}], 4)
		declare(sim, "brute1", attack_action("crushed", 3, "grifter", "torso", {"attack_range": 4}))
		advance(sim, 4)
		move(sim, "wraith", [1, 0])
		move(sim, "grifter", [10, 1])  # the banked con step
		declare(sim, "brute2", attack_action("crushed", 3, "grifter", "torso", {"attack_range": 5}))
		advance(sim, 8)  # the second firing + the Clock reset
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash across the whole wave")
