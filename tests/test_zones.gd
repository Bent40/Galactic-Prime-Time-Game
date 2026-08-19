extends SimTestBase
## KAN-5 remainder K1 — the zones/fields substrate (simulation/zones.gd): the
## runtime area-effect store the wall skills (poison/frost/fire) and
## elemental_confluence drive NEXT story.
##
## Under test:
##  * the OPT-IN model: no command surface, internal create_zone/remove_zone/
##    damage_zone API, and the compat pin (a sim that never created a zone
##    serializes with NO "zones" key — the exact legacy top-level shape; the
##    CI harnesses stage no zone and byte-diff clean).
##  * lifecycle triggers through REAL commands: on_enter (walk in via move),
##    on_occupy_clock (stand in it across a Clock reset), on_pass (dash lane
##    through — the one traversal the machinery exposes), duration expiry,
##    spawn-baseline honesty (materializing in a zone is not entering).
##  * blocking: a blocks_movement zone blocks EXACTLY like a wall (move
##    rejection, dash lane declare gate, bounced-lane truncation, staging),
##    and LOS occludes when flagged (Arena.blocks_lane -> Stealth.has_los).
##  * frost-wall hp via the internal API only + removal at 0.
##  * attribution: a condition seeded by a zone carries the OWNER as its
##    wound source — the burn/bleed death in your wall credits YOU
##    (takedown-v2 flows end to end).
##  * effect vocabulary: typed damage (R14 reduction path), conditions (incl.
##    shock), the advance op (confluence's Toxic Surge shape).
##  * strict create-time validation; determinism + serialization round-trips
##    (including the persisted id counter after every zone expired).


func entries_of(sim: CombatSim, evidence_type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Dictionary in sim.evidence.ledger:
		if String(entry.get("type", "")) == evidence_type:
			out.append(entry)
	return out


func advance_until_death(sim: CombatSim, victim: String, clocks: int) -> Array[Dictionary]:
	var seen: Array[Dictionary] = []
	for i: int in range(clocks):
		seen.append_array(advance(sim, Clock.TICKS_PER_CLOCK))
		if not (sim.combatants[victim] as CombatantState).alive:
			break
	return seen


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func set_arena(sim: CombatSim, walls: Array = []) -> Array[Dictionary]:
	return sim.apply_command({"type": "set_arena",
		"arena": {"bounds": {"width": 21, "height": 21}, "walls": walls}})


## A hand-declared straight dash (the test_arena pattern): kind attack +
## line area_shape — any actor may declare it; the lane is the geometry.
func dash_action(target_id: String, lane: Array) -> Dictionary:
	return {
		"kind": "attack", "key": "dash", "cost": 2,
		"damage": {"type": "crushed", "amount": 1}, "attack_range": 8,
		"targets": [{"id": target_id, "part": "torso"}],
		"area_shape": {"kind": "line", "lane": lane},
	}


# ---------------------------------------------------------------- legacy pin

func test_no_zone_fight_serializes_with_the_legacy_shape() -> void:
	# The compat pin: a sim that never created a zone carries NO "zones" key —
	# the exact pre-zone top-level shape, so its canonical serialization (and
	# state_hash) is byte-identical to the pre-change engine. The CI harnesses
	# create no zone and byte-diff clean on the same principle.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_human(sim, "m", {"team": "enemies", "position": [2, 0]})
	declare(sim, "h", attack_action("crushed", 2, "m", "torso"))
	advance(sim, Clock.TICKS_PER_CLOCK)
	move(sim, "h", [0, 1])
	advance(sim, 1)
	var keys: Array = sim.to_dict().keys()
	keys.sort()
	assert_eq(keys, ["ai", "clock", "combatants", "evidence", "hype", "rng_seed",
		"rng_state", "static_data", "tags", "tick_snapshot"],
		"no-zone to_dict = the exact legacy key set (no 'zones')")
	assert_true(sim.zones == null, "no store is ever allocated without create_zone")
	# And a zone-carrying sim declares itself.
	var sim2: CombatSim = make_sim()
	add_human(sim2, "h", {"team": "party"})
	sim2.create_zone({"key": "test_zone", "hexes": [[3, 3]]})
	assert_true(sim2.to_dict().has("zones"), "a created zone serializes under 'zones'")


# ---------------------------------------------------------------- lifecycle: on_enter

func test_on_enter_fires_on_walking_in_via_real_move() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "walker", {"team": "party", "position": [0, 0]})
	var created: Array[Dictionary] = sim.create_zone({
		"key": "poison_wall", "owner": "caster", "hexes": [[2, 0], [3, 0]],
		"effects": {"on_enter": {"conditions": [
			{"condition": "bleeding", "tier": 1, "part": "torso"},
		]}},
	})
	var made: Dictionary = assert_event(created, "zone_created", "the zone stood up")
	assert_eq(int(made.get("zone", 0)), 1, "ids run off the deterministic counter, from 1")
	assert_eq(made.get("hexes", []), [[2, 0], [3, 0]], "hexes stored sorted")
	# Walk in: the free move lands the walker in the zone -> on_enter.
	var entered: Array[Dictionary] = move(sim, "walker", [2, 0])
	var fx: Dictionary = assert_event(entered, "zone_effect_applied", "entering fired the zone")
	assert_eq(String(fx.get("trigger", "")), "on_enter", "the on_enter trigger")
	assert_eq(String(fx.get("combatant", "")), "walker", "on the mover")
	assert_eq(String(fx.get("owner", "")), "caster", "attributed to the zone's author")
	var applied: Dictionary = assert_event(entered, "condition_applied", "the authored condition landed")
	assert_eq(String(applied.get("condition", "")), "bleeding", "the authored condition id")
	var walker: CombatantState = sim.combatants["walker"]
	assert_eq(String(((walker.conditions.get("torso", {}) as Dictionary).get("bleeding", {}) as Dictionary).get("source", "")),
		"caster", "the wound instance carries the OWNER as its source")
	# Moving hex-to-hex WITHIN the zone never re-enters.
	advance(sim, 1)
	var inside: Array[Dictionary] = move(sim, "walker", [3, 0])
	assert_no_event(inside, "zone_effect_applied", "an in-zone step is not an entry")
	# Leaving fires nothing; re-entering fires again.
	advance(sim, 1)
	var left: Array[Dictionary] = move(sim, "walker", [5, 0])
	assert_no_event(left, "zone_effect_applied", "leaving is silent")
	advance(sim, 1)
	var back: Array[Dictionary] = move(sim, "walker", [3, 0])
	assert_event(back, "zone_effect_applied", "walking back in enters again")


func test_spawning_inside_a_zone_is_not_entering() -> void:
	# The documented baseline rule: materializing (staging/summon) in a zone
	# fires no on_enter — the occupant is the next Clock's on_occupy business.
	var sim: CombatSim = make_sim()
	sim.create_zone({
		"key": "fire_wall", "owner": "", "hexes": [[1, 1]],
		"effects": {"on_enter": {"conditions": [{"condition": "burn", "tier": 1}]}},
	})
	var added: Array[Dictionary] = add_human(sim, "dropin", {"team": "party", "position": [1, 1]})
	assert_event(added, "combatant_added", "the spawn landed")
	assert_no_event(added, "zone_effect_applied", "spawning in the zone is not entering")
	# The next command's sweep does not back-fire either (the baseline took it).
	var idle: Array[Dictionary] = advance(sim, 1)
	assert_no_event(idle, "zone_effect_applied", "and no deferred entry fires later")


# ---------------------------------------------------------------- lifecycle: on_occupy_clock + expiry

func test_on_occupy_clock_bites_at_the_reset_then_duration_expires() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "stander", {"team": "party", "position": [1, 1]})
	add_human(sim, "bystander", {"team": "party", "position": [5, 5]})
	sim.create_zone({
		"key": "fire_wall", "owner": "caster", "hexes": [[1, 1]],
		"duration_clocks": 1,
		"effects": {"on_occupy_clock": {"damage": {"type": "burn", "amount": 2}}},
	})
	var hp_before: int = int((sim.combatants["stander"] as CombatantState).parts["torso"]["hp"])
	var events: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_event(events, "clock_reset", "precondition: a Clock completed")
	var fx: Dictionary = assert_event(events, "zone_effect_applied", "the occupant was bitten")
	assert_eq(String(fx.get("trigger", "")), "on_occupy_clock", "at the Clock boundary")
	assert_eq(String(fx.get("combatant", "")), "stander", "the occupant only")
	var dmg: Dictionary = assert_event(events, "damage_applied", "typed damage through the central sink")
	assert_eq(String(dmg.get("combatant", "")), "stander", "on the occupant")
	assert_eq(int(dmg.get("amount", 0)), 2, "full amount (no Physical resistance on the spec)")
	assert_eq(String(dmg.get("source", "")), "environment", "environment source kind")
	assert_eq(int((sim.combatants["stander"] as CombatantState).parts["torso"]["hp"]), hp_before - 2,
		"the hp actually moved")
	# One bite: the bystander outside was never touched.
	for row: Dictionary in events_of(events, "zone_effect_applied"):
		assert_ne(String(row.get("combatant", "")), "bystander", "outside the hexes = outside the zone")
	# duration_clocks 1: the SAME reset expires it — after the bite (order pinned).
	var expired: Dictionary = assert_event(events, "zone_expired", "the 1-Clock wall died at its reset")
	assert_eq(String(expired.get("reason", "")), "duration", "by duration")
	assert_true(events.find(fx) < events.find(expired), "the wall bites BEFORE it dissolves")
	assert_true(sim.zones.is_empty(), "the store is empty again")
	# The next Clock bites nobody.
	var after: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_no_event(after, "zone_effect_applied", "an expired zone is gone")


func test_multi_clock_duration_counts_down() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [9, 9]})
	sim.create_zone({"key": "frost_wall", "hexes": [[0, 0]], "duration_clocks": 2})
	var first: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_no_event(first, "zone_expired", "a 2-Clock zone survives its first reset")
	assert_eq(int((sim.zones.zones[0] as Dictionary).get("duration_clocks", -1)), 1,
		"the remaining count serialized down to 1")
	var second: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	var expired: Dictionary = assert_event(second, "zone_expired", "and dies at the second")
	assert_eq(String(expired.get("reason", "")), "duration", "by duration")


# ---------------------------------------------------------------- lifecycle: on_pass

func test_on_pass_fires_for_a_dash_lane_through() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "runner", {"team": "party", "position": [0, 0]})
	add_human(sim, "vic", {"team": "enemies", "position": [4, 0]})
	sim.create_zone({
		"key": "fire_wall", "owner": "caster", "hexes": [[1, 0], [2, 0]],
		"effects": {
			"on_pass": {"conditions": [{"condition": "burn", "tier": 1, "part": "torso"}]},
			"on_enter": {"conditions": [{"condition": "bleeding", "tier": 1, "part": "torso"}]},
		},
	})
	declare(sim, "runner", dash_action("vic", [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]]))
	advance(sim, 2)
	var events: Array[Dictionary] = advance(sim, 1)
	var charged: Dictionary = assert_event(events, "dash_charged", "the charge resolved")
	assert_eq(charged.get("to", []), [3, 0], "stopping adjacent-before the target — outside the zone")
	var passes: Array[Dictionary] = events_of(events, "zone_effect_applied")
	assert_eq(passes.size(), 1, "ONE on_pass per zone per dash — two crossed hexes dedupe")
	assert_eq(String(passes[0].get("trigger", "")), "on_pass", "the pass trigger (not enter — it ran through)")
	assert_eq(String(passes[0].get("combatant", "")), "runner", "on the dasher")
	var runner_conditions: Array[String] = []
	for row: Dictionary in events_of(events, "condition_applied"):
		if String(row.get("combatant", "")) == "runner":
			runner_conditions.append(String(row.get("condition", "")))
	assert_eq(runner_conditions, ["burn"], "the on_pass payload (burn) landed on the dasher — and only it")
	var runner: CombatantState = sim.combatants["runner"]
	assert_eq(String(((runner.conditions.get("torso", {}) as Dictionary).get("burn", {}) as Dictionary).get("source", "")),
		"caster", "the pass wound carries the owner as source")


func test_dash_ending_inside_the_zone_is_an_entry_not_a_pass() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "runner", {"team": "party", "position": [0, 0]})
	add_human(sim, "vic", {"team": "enemies", "position": [3, 0]})
	sim.create_zone({
		"key": "fire_wall", "owner": "caster", "hexes": [[2, 0]],
		"effects": {
			"on_pass": {"conditions": [{"condition": "burn", "tier": 1}]},
			"on_enter": {"conditions": [{"condition": "bleeding", "tier": 1}]},
		},
	})
	declare(sim, "runner", dash_action("vic", [[0, 0], [1, 0], [2, 0], [3, 0]]))
	advance(sim, 2)
	var events: Array[Dictionary] = advance(sim, 1)
	var charged: Dictionary = assert_event(events, "dash_charged", "the charge resolved")
	assert_eq(charged.get("to", []), [2, 0], "the charge ENDS on the zone hex")
	var rows: Array[Dictionary] = events_of(events, "zone_effect_applied")
	assert_eq(rows.size(), 1, "one trigger only")
	assert_eq(String(rows[0].get("trigger", "")), "on_enter", "ending inside = entering, never a pass")
	var runner_conditions: Array[String] = []
	for row: Dictionary in events_of(events, "condition_applied"):
		if String(row.get("combatant", "")) == "runner":
			runner_conditions.append(String(row.get("condition", "")))
	assert_eq(runner_conditions, ["bleeding"], "on_enter's condition landed on the dasher, not on_pass's")


func test_free_moves_are_destination_only_no_pass() -> void:
	# The standing wall contract, honestly inherited: a 1-3 space free move is
	# a destination hop (the resolver validates the destination only), so
	# hopping OVER a zone hex fires nothing — traversal is only real on lanes.
	var sim: CombatSim = make_sim()
	add_human(sim, "hopper", {"team": "party", "position": [0, 0]})
	sim.create_zone({
		"key": "fire_wall", "hexes": [[1, 0]],
		"effects": {"on_pass": {"conditions": [{"condition": "burn", "tier": 1}]}},
	})
	var hopped: Array[Dictionary] = move(sim, "hopper", [2, 0])
	assert_event(hopped, "moved", "the 2-space free move resolved")
	assert_no_event(hopped, "zone_effect_applied",
		"no traversal is modeled for a free move — on_pass honestly does not fire")


# ---------------------------------------------------------------- effect vocabulary

func test_vocabulary_shock_and_advance_ops() -> void:
	# Shock rides the same conditions op ({"condition": "shock"} routes to
	# apply_shock — the fire_wall L6 "passers take tier 2 Shock" shape), and
	# the advance op is confluence's Toxic Surge ("advance all active Poison").
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	sim.create_zone({
		"key": "fire_wall", "owner": "caster", "hexes": [[2, 0]],
		"effects": {"on_enter": {"conditions": [{"condition": "shock", "tier": 2}]}},
	})
	var entered: Array[Dictionary] = move(sim, "h", [2, 0])
	var shocked: Dictionary = assert_event(entered, "shock_changed", "the zone shocked the enterer")
	assert_eq(int(shocked.get("to_tier", 0)), 2, "at the authored tier")
	assert_event(entered, "shock_stutter", "tier-2 entry effect fired through the normal machinery")
	# Toxic Surge: a control sim isolates the zone's +1 from the universal
	# Clock advancement (both sims advance identically otherwise).
	var surged: CombatSim = make_sim(9)
	var control: CombatSim = make_sim(9)
	for s: CombatSim in [surged, control]:
		add_human(s, "p", {"team": "party", "position": [1, 1]})
		s.apply_command({"type": "apply_condition", "target": "p", "part": "torso",
			"condition": "poison", "tier": 1, "poison_type": "pneumo"})
	surged.create_zone({
		"key": "elemental_confluence", "owner": "caster", "hexes": [[1, 1]],
		"effects": {"on_occupy_clock": {"advance": [{"condition": "poison", "steps": 1}]}},
	})
	var surge_events: Array[Dictionary] = advance(surged, Clock.TICKS_PER_CLOCK)
	advance(control, Clock.TICKS_PER_CLOCK)
	assert_event(surge_events, "zone_effect_applied", "the surge fired at the reset")
	var surged_tier: int = (surged.combatants["p"] as CombatantState).condition_tier("torso", "poison")
	var control_tier: int = (control.combatants["p"] as CombatantState).condition_tier("torso", "poison")
	assert_eq(surged_tier, control_tier + 1, "the zone advanced the ACTIVE poison one tier past the universal step")


func test_affects_selectors_gate_who_is_hit() -> void:
	# non_owner (confluence's "not you") and hostile (the L9 ally-safe rung).
	var sim: CombatSim = make_sim()
	add_human(sim, "caster", {"team": "party", "position": [0, 0]})
	add_human(sim, "ally", {"team": "party", "position": [0, 1]})
	add_human(sim, "foe", {"team": "enemies", "position": [0, 2]})
	sim.create_zone({
		"key": "fire_wall", "owner": "caster", "hexes": [[2, 0], [2, 1], [2, 2]],
		"effects": {"on_enter": {"affects": "hostile",
			"conditions": [{"condition": "burn", "tier": 1}]}},
	})
	var caster_in: Array[Dictionary] = move(sim, "caster", [2, 0])
	assert_no_event(caster_in, "zone_effect_applied", "hostile: the owner walks their own wall freely")
	var ally_in: Array[Dictionary] = move(sim, "ally", [2, 1])
	assert_no_event(ally_in, "zone_effect_applied", "hostile: allies pass (the ally-safe rung)")
	var foe_in: Array[Dictionary] = move(sim, "foe", [2, 2])
	assert_event(foe_in, "zone_effect_applied", "hostile: the enemy burns")


# ---------------------------------------------------------------- blocking

func test_blocking_zone_blocks_exactly_like_a_wall() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim)
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	add_human(sim, "vic", {"team": "enemies", "position": [4, 0]})
	# A blocking zone may not be raised on a living body (the door precedent).
	var on_body: Array[Dictionary] = sim.create_zone({
		"key": "frost_wall", "hexes": [[0, 0]], "blocks_movement": true})
	assert_eq(String(first_event(on_body, "zone_rejected").get("reason", "")),
		"zone_blocked_by_body", "raise-under-a-body rejects (frost L8 lifts this later)")
	var created: Array[Dictionary] = sim.create_zone({
		"key": "frost_wall", "hexes": [[2, 0]], "hp": 3,
		"blocks_movement": true, "blocks_los": true,
	})
	assert_event(created, "zone_created", "the ice stood up")
	# Movement: the same rejection a wall hex gives.
	assert_rejected(move(sim, "h", [2, 0]), "hex_blocked", "a blocks_movement zone IS a wall to a move")
	# Dash lanes: the declare-time lane gate sees it like any wall hex.
	var lane_try: Array[Dictionary] = declare(sim, "h",
		dash_action("vic", [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]]))
	assert_rejected(lane_try, "lane_blocked", "a lane through the ice rejects at declare")
	# The bounced-lane walk (the AI's lane geometry) ENDS at the zone.
	var walk: Dictionary = sim.arena.bounced_lane(Vector2i(0, 0), Vector2i(4, 0), 6, 0)
	assert_eq(walk["lane"], [Vector2i(0, 0), Vector2i(1, 0)], "the lane truncates before the ice")
	# LOS: flagged blocks_los -> the sight line through it is cut.
	assert_false(Stealth.has_los(sim.arena, Vector2i(0, 0), Vector2i(4, 0)),
		"LOS through the flagged zone is blocked")
	assert_true(Stealth.has_los(sim.arena, Vector2i(0, 2), Vector2i(4, 2)),
		"a line missing the zone is unaffected")
	# Staging honesty: nobody spawns inside the ice.
	var staged: Array[Dictionary] = add_human(sim, "late", {"team": "party", "position": [2, 0]})
	assert_rejected(staged, "staging_blocked_hex", "a spawn on the zone hex rejects like a wall hex")
	# A pure-effect zone (no flags) blocks nothing.
	sim.create_zone({"key": "poison_wall", "hexes": [[1, 1]]})
	advance(sim, 1)
	assert_event(move(sim, "h", [1, 1]), "moved", "a non-blocking zone is open ground")
	assert_true(Stealth.has_los(sim.arena, Vector2i(0, 1), Vector2i(2, 1)),
		"and cuts no sight line")


func test_frost_hp_decrements_via_api_and_frees_the_hex_at_zero() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim)
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	sim.create_zone({"key": "frost_wall", "hexes": [[2, 0]], "hp": 3,
		"blocks_movement": true, "blocks_los": true})
	var chip: Array[Dictionary] = sim.damage_zone(1, 2)
	var damaged: Dictionary = assert_event(chip, "zone_damaged", "the internal API wears the wall")
	assert_eq(int(damaged.get("hp", -1)), 1, "3 - 2 = 1")
	assert_no_event(chip, "zone_expired", "still standing")
	assert_rejected(move(sim, "h", [2, 0]), "hex_blocked", "and still a wall")
	var shatter: Array[Dictionary] = sim.damage_zone(1, 2)
	assert_eq(int(assert_event(shatter, "zone_damaged", "the second hit").get("hp", -1)), 0, "worn to 0")
	var gone: Dictionary = assert_event(shatter, "zone_expired", "the wall shatters at 0")
	assert_eq(String(gone.get("reason", "")), "destroyed", "reason destroyed")
	advance(sim, 1)
	assert_event(move(sim, "h", [2, 0]), "moved", "the hex is open ground again")
	assert_true(Stealth.has_los(sim.arena, Vector2i(0, 0), Vector2i(4, 0)), "and see-through again")
	# Indestructible zones reject the API; unknown ids reject.
	sim.create_zone({"key": "fire_wall", "hexes": [[3, 3]]})
	assert_eq(String(first_event(sim.damage_zone(2, 1), "zone_rejected").get("reason", "")),
		"zone_indestructible", "hp -1 = cannot be destroyed, only outlasted")
	assert_eq(String(first_event(sim.damage_zone(99, 1), "zone_rejected").get("reason", "")),
		"zone_unknown", "unknown id rejects")


# ---------------------------------------------------------------- attribution

func test_zone_wound_death_credits_the_owner_takedown_flows() -> void:
	# takedown-v2 end to end: the zone's owner authored the wound, so the
	# eventual condition death names them killer and the evidence credits them.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	add_human(sim, "m", {"team": "enemies", "position": [4, 0]})
	sim.create_zone({
		"key": "poison_wall", "owner": "h", "hexes": [[3, 0]],
		"effects": {"on_enter": {"conditions": [{"condition": "bleeding", "tier": 1}]}},
	})
	var entered: Array[Dictionary] = move(sim, "m", [3, 0])
	assert_event(entered, "zone_effect_applied", "the enemy walked into the wall")
	assert_eq(String(((sim.combatants["m"] as CombatantState).conditions.get("torso", {}) as Dictionary)
		.get("bleeding", {}).get("source", "")), "h", "the wound instance names the owner")
	var events: Array[Dictionary] = advance_until_death(sim, "m", 8)
	var died: Dictionary = assert_event(events, "combatant_died", "the zone-seeded wound eventually killed")
	assert_eq(String(died.get("killer", "")), "h", "a death in your wall credits YOU")
	var takedowns: Array[Dictionary] = entries_of(sim, "takedown")
	assert_eq(takedowns.size(), 1, "one takedown evidence entry")
	assert_eq(String(takedowns[0].get("actor", "")), "h", "credited to the zone's owner")


func test_environment_zone_wound_credits_nobody() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "m", {"team": "enemies", "position": [0, 0]})
	sim.create_zone({
		"key": "hazard", "owner": "", "hexes": [[2, 0]],
		"effects": {"on_enter": {"conditions": [{"condition": "bleeding", "tier": 1}]}},
	})
	move(sim, "m", [2, 0])
	var events: Array[Dictionary] = advance_until_death(sim, "m", 8)
	var died: Dictionary = assert_event(events, "combatant_died", "the hazard killed")
	assert_eq(String(died.get("killer", "")), "", "an authorless zone credits nobody — never guessed")
	assert_eq(entries_of(sim, "takedown").size(), 0, "and records no takedown")


# ---------------------------------------------------------------- validation

func test_create_validation_is_strict() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	var cases: Array = [
		[{"hexes": [[1, 0]]}, "zone_missing_key"],
		[{"key": "z"}, "zone_invalid_hexes"],
		[{"key": "z", "hexes": [[1]]}, "zone_invalid_hexes"],
		[{"key": "z", "hexes": [[1, 0]], "duration_clocks": 0}, "zone_invalid_duration"],
		[{"key": "z", "hexes": [[1, 0]], "hp": 0}, "zone_invalid_hp"],
		[{"key": "z", "hexes": [[1, 0]], "effects": {"on_tick": {}}}, "zone_unknown_trigger"],
		[{"key": "z", "hexes": [[1, 0]], "effects": {"on_enter": {"explode": true}}}, "zone_unknown_effect_op"],
		[{"key": "z", "hexes": [[1, 0]], "effects": {"on_enter": {"affects": "everyone"}}}, "zone_invalid_affects"],
		[{"key": "z", "hexes": [[1, 0]], "effects": {"on_enter": {"damage": {"amount": 2}}}}, "zone_invalid_damage"],
		[{"key": "z", "hexes": [[1, 0]], "effects": {"on_enter": {"conditions": [{"tier": 1}]}}}, "zone_invalid_conditions"],
		[{"key": "z", "hexes": [[1, 0]], "effects": {"on_enter": {"advance": [{"steps": 1}]}}}, "zone_invalid_advance"],
	]
	for case: Variant in cases:
		var events: Array[Dictionary] = sim.create_zone((case as Array)[0])
		assert_eq(String(first_event(events, "zone_rejected").get("reason", "")),
			String((case as Array)[1]), "strict validation: %s" % str((case as Array)[0]))
	assert_true(sim.zones == null or sim.zones.next_id == 0, "rejections never burned an id")
	assert_false(sim.to_dict().has("zones"), "rejections never opted the sim into the zones key")
	# Arena placement gates.
	set_arena(sim, [[3, 0]])
	assert_eq(String(first_event(sim.create_zone({"key": "z", "hexes": [[99, 99]]}), "zone_rejected")
		.get("reason", "")), "zone_out_of_bounds", "outside the room rejects")
	assert_eq(String(first_event(sim.create_zone({"key": "z", "hexes": [[3, 0]]}), "zone_rejected")
		.get("reason", "")), "zone_on_wall", "an authored wall hex rejects")


# ---------------------------------------------------------------- view

func test_view_zones_is_additive_and_read_only() -> void:
	var script: GDScript = load("res://controller/game_controller.gd")
	var game: Node = script.new()
	game.start_combat(1234, load_static_data())
	assert_eq((game.view_zones() as Array).size(), 0, "no zones -> the empty additive view")
	game.sim.create_zone({
		"key": "fire_wall", "owner": "caster", "hexes": [[2, 0], [1, 0]],
		"duration_clocks": 1,
		"effects": {"on_pass": {"conditions": [{"condition": "burn", "tier": 1}]}},
	})
	var rows: Array = game.view_zones()
	assert_eq(rows.size(), 1, "one row per live zone")
	var row: Dictionary = rows[0]
	assert_eq(int(row.get("id", 0)), 1, "id surfaced")
	assert_eq(String(row.get("key", "")), "fire_wall", "key surfaced")
	assert_eq(String(row.get("owner", "")), "caster", "owner surfaced")
	assert_eq(row.get("hexes", []), [[1, 0], [2, 0]], "hexes sorted")
	assert_eq(int(row.get("duration_clocks", 0)), 1, "remaining duration surfaced")
	assert_eq(int(row.get("hp", 0)), -1, "hp surfaced (-1 = indestructible)")
	assert_false(bool(row.get("blocks_movement", true)), "blocking flags surfaced")
	(row.get("hexes", []) as Array).clear()
	row["key"] = "vandalized"
	assert_eq(String((game.view_zones()[0] as Dictionary).get("key", "")), "fire_wall",
		"the view is a deep copy — mutating it never reaches the sim")
	game.free()


# ---------------------------------------------------------------- serialization + determinism

func test_create_serialize_restore_identical_hash() -> void:
	var sim: CombatSim = make_sim(77)
	set_arena(sim)
	add_human(sim, "h", {"team": "party", "position": [0, 0]})
	add_human(sim, "m", {"team": "enemies", "position": [5, 0]})
	sim.create_zone({
		"key": "frost_wall", "owner": "h", "hexes": [[2, 0], [2, 1]], "hp": 5,
		"duration_clocks": 2, "blocks_movement": true, "blocks_los": true,
		"effects": {"on_enter": {"conditions": [{"condition": "chilled", "tier": 1}]}},
	})
	sim.create_zone({
		"key": "poison_wall", "owner": "m", "hexes": [[4, 4]],
		"effects": {"on_occupy_clock": {"affects": "hostile",
			"conditions": [{"condition": "poison", "tier": 1, "poison_type": "pneumo"}]}},
	})
	sim.damage_zone(1, 2)  # mid-wear state must round-trip too
	var mid_hash: String = sim.state_hash()
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), mid_hash, "create -> serialize -> restore -> identical hash")
	assert_eq(restored.zones.next_id, 2, "the id counter round-trips")
	assert_eq(restored.zones.view(), sim.zones.view(), "identical zone rows")
	# The restored sim's blocking is LIVE (arena.zones rewired on restore).
	assert_rejected(move(restored, "h", [2, 0]), "hex_blocked", "restored ice still walls")
	assert_rejected(move(sim, "h", [2, 0]), "hex_blocked", "as does the original")
	# Both timelines proceed in lockstep through effects + expiry.
	var live: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK * 2)
	var resumed: Array[Dictionary] = advance(restored, Clock.TICKS_PER_CLOCK * 2)
	assert_eq(events_of(live, "zone_expired").size(), events_of(resumed, "zone_expired").size(),
		"same expiries on both timelines")
	assert_eq(restored.state_hash(), sim.state_hash(), "hashes stay identical after the lifecycle")


func test_id_counter_persists_after_every_zone_expired() -> void:
	# Save/restore transparency: a restored sim must hand out the same next
	# zone id a straight-through run would — the counter serializes even when
	# the store is empty (so the "zones" key persists once opted in).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [9, 9]})
	sim.create_zone({"key": "a", "hexes": [[0, 0]], "duration_clocks": 1})
	advance(sim, Clock.TICKS_PER_CLOCK)
	assert_true(sim.zones.is_empty(), "precondition: the only zone expired")
	assert_true(sim.to_dict().has("zones"), "the zones key persists (the counter is state)")
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "identical hash with an empty store")
	var live_id: int = int(first_event(sim.create_zone({"key": "b", "hexes": [[1, 1]]}),
		"zone_created").get("zone", 0))
	var resumed_id: int = int(first_event(restored.create_zone({"key": "b", "hexes": [[1, 1]]}),
		"zone_created").get("zone", 0))
	assert_eq(live_id, 2, "the straight-through run continues the sequence")
	assert_eq(resumed_id, live_id, "the restored run hands out the identical id")
	assert_eq(restored.state_hash(), sim.state_hash(), "and the hashes still agree")


func test_two_runs_same_log_identical_hashes() -> void:
	# Pure replay determinism over the whole substrate: two sims, same seed,
	# same command + internal-API sequence — byte-identical state throughout.
	var sims: Array = [make_sim(42), make_sim(42)]
	for s: CombatSim in sims:
		s.apply_command({"type": "set_arena", "arena": {"bounds": {"width": 21, "height": 21}}})
		add_human(s, "h", {"team": "party", "position": [0, 0]})
		add_human(s, "m", {"team": "enemies", "position": [5, 0]})
		s.create_zone({
			"key": "fire_wall", "owner": "h", "hexes": [[3, 0]], "duration_clocks": 2,
			"effects": {
				"on_enter": {"conditions": [{"condition": "burn", "tier": 1}]},
				"on_occupy_clock": {"damage": {"type": "burn", "amount": 1}},
				"on_pass": {"conditions": [{"condition": "shock", "tier": 1}]},
			},
		})
		s.apply_command({"type": "move", "actor": "m", "to": [3, 0]})
		advance(s, Clock.TICKS_PER_CLOCK)
		s.apply_command({"type": "move", "actor": "m", "to": [4, 0]})
		s.create_zone({"key": "frost_wall", "hexes": [[1, 1]], "hp": 3,
			"blocks_movement": true, "blocks_los": true})
		s.damage_zone(2, 3)
		advance(s, Clock.TICKS_PER_CLOCK)
	assert_eq((sims[0] as CombatSim).state_hash(), (sims[1] as CombatSim).state_hash(),
		"same log -> identical state hash (zones covered by the hash)")
	assert_true((sims[0] as CombatSim).zones.is_empty(),
		"precondition: the run exercised the full lifecycle (all zones gone)")
