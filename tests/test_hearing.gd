extends SimTestBase
## R20 round 3b — HEARING & THE ALERTED STATE (rules-addendum R20 "SHIPPED —
## hearing/alert"; closes the wave-4c "hearing beyond the Shout" downscope).
##
## Under test:
##  * the LEGACY BYTE-COMPAT PIN (the bar): the SAME two stealth-free fights
##    test_stealth.gd pins replay to the SAME recorded hashes — hearing is
##    structured so a fight with no stealth use produces IDENTICAL behavior
##    (the sweep no-ops, `_alert_or_wait` returns the old wait, no combatant
##    ever grows the `alerted` key).
##  * the LOUDNESS TABLE, pure and behavioral: shout LOUD (10) > attack/
##    explosion/door MODERATE (6) > movement QUIET (3); `derive_noises` maps
##    exactly the v1 source set; loudness IS the hearing range (a movement at
##    distance 5 is unheard, an attack at 5 is heard).
##  * the ALERTED contract: a hidden mover's noise alerts an unseeing AI;
##    the state stores ONLY {tick, sound} — no source id ("does not know
##    where you are"); an INVESTIGATOR walks to where the sound WAS, never
##    the mover's current hex (the pinned divergence); a NON-INVESTIGATOR
##    alerts but holds (`alerted_holding`, stance "alert"); hearing never
##    REVEALS (the hider stays stealthed throughout).
##  * the investigate/ignore personality gate: explicit `investigates` key
##    wins; derived default Mind >= 2 OR herder (PROVISIONAL) — war_hound
##    investigates, roach_dog / little_brother_roach / incinedile ignore.
##  * consumption honesty: a VISIBLE actor's noise changes nothing (default-
##    detected — redundant with detection itself), even while the sweep is
##    active for another hidden combatant; a hidden shouter is REVEALED by
##    the R13 self-break, not alert-tracked (strictly more information).
##  * decay: a full quiet Clock (TICKS_PER_CLOCK since the last heard noise)
##    clears the alert (`alert_cleared` reason "decayed"), boundary pinned
##    at exactly 10 ticks; behavior returns to the plain "no_targets" wait.
##  * serialization: `alerted` only-when-set (nobody else grows the key),
##    round-trip mid-alert, lockstep decay tails, full determinism, ZERO rng
##    from every hearing path (R20 authors no roll), additive view exposure.

## The recorded pre-stealth legacy hashes — SHARED TRUTH with
## tests/test_stealth.gd (same constants, same sequences; re-pin BOTH files
## together via that file's documented re-record procedure).
const LEGACY_HASH_PLAIN: String = "6d8046456d4aee1059e775d8d08f6eee2519c511f2e36df4b5c8ee25ca9b6a70"
const LEGACY_HASH_ARENA_DOOR: String = "f6f64238efd4596bcba526c5a32d60583d6c5d7c55e599aa328b2f41658680d5"


func stealth(sim: CombatSim, actor: String, to_state: String = "hide") -> Array[Dictionary]:
	return sim.apply_command({"type": "stealth", "actor": actor, "set": to_state})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


func add_enemy(sim: CombatSim, id: String, key: String, pos: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "enemy": key, "team": "enemies", "position": pos}})


func assert_no_hearing_events(events: Array[Dictionary], message: String) -> void:
	assert_no_event(events, "noise_heard", message)
	assert_no_event(events, "alerted", message)
	assert_no_event(events, "alert_cleared", message)


# ------------------------------------------------------------- legacy compat

func test_legacy_stealth_free_fight_hashes_are_byte_identical() -> void:
	# Sequence A (plain, no arena) — byte-identical to the recorded engine,
	# and no hearing event ever fires (the sweep no-ops with nobody hidden).
	var sim: CombatSim = make_sim()
	add_human(sim, "h1", {"team": "party", "position": [1, 0]})
	assert_no_hearing_events(add_enemy(sim, "mob", "roach_dog", [5, 0]), "add is silent")
	assert_no_hearing_events(move(sim, "h1", [4, 0]), "a VISIBLE mover makes no consumed noise")
	assert_no_hearing_events(ai_decide(sim, "mob"), "the decide batch is hearing-silent")
	assert_no_hearing_events(advance(sim, 1), "the tick batch is hearing-silent")
	assert_no_hearing_events(
		declare(sim, "h1", attack_action("crushed", 3, "mob", "torso", {"attack_range": 6})),
		"the declare batch is hearing-silent")
	assert_no_hearing_events(advance(sim, 1), "the attack resolution alerts nobody (attacker visible)")
	ai_decide(sim, "mob")
	advance(sim, 2)
	assert_eq(sim.state_hash(), LEGACY_HASH_PLAIN, "stealth-free plain fight replays the recorded hash")
	# Structural half of the compat pin: the alerted key exists NOWHERE.
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		assert_false((dict["combatants"][id] as Dictionary).has("alerted"),
			"no alerted key on a never-alerted combatant (%s)" % id)
	for id: Variant in dict.get("tick_snapshot", {}) as Dictionary:
		assert_false((dict["tick_snapshot"][id] as Dictionary).has("alerted"),
			"no alerted key in a legacy snapshot entry (%s)" % id)

	# Sequence B (arena + wall + door flip) — the door flip is a MODERATE
	# noise row by table, but its actor is visible: derived, never consumed.
	var sim2 := CombatSim.new(77, SimTestBase.load_static_data())
	sim2.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21},
		"walls": [[3, 0]],
		"doors": [{"key": "d", "position": [2, 0], "state": "closed"}]}})
	add_human(sim2, "h1", {"team": "party", "position": [1, 0]})
	add_enemy(sim2, "mob", "roach_dog", [5, 5])
	assert_no_hearing_events(sim2.apply_command({"type": "door", "actor": "h1", "key": "d", "set": "open"}),
		"a VISIBLE actor's door slam alerts nobody")
	advance(sim2, 1)
	move(sim2, "h1", [2, 0])
	ai_decide(sim2, "mob")
	advance(sim2, 1)
	assert_eq(sim2.state_hash(), LEGACY_HASH_ARENA_DOOR, "stealth-free arena/door fight replays the recorded hash")


# ------------------------------------------------------------ the noise table

func test_noise_table_pinned_and_derivation_is_honest() -> void:
	# The pinned PLACEHOLDER (R14) loudness bands, ordered: shout > attack > move.
	assert_eq(Stealth.NOISE_LOUD, 10, "shout/Shock-T1 = loud, range 10")
	assert_eq(Stealth.NOISE_MODERATE, 6, "attacks/explosions/door slams = moderate, range 6")
	assert_eq(Stealth.NOISE_QUIET, 3, "movement = quiet, range 3")
	assert_true(Stealth.NOISE_LOUD > Stealth.NOISE_MODERATE and Stealth.NOISE_MODERATE > Stealth.NOISE_QUIET,
		"a shout reaches farther than an attack, an attack farther than footsteps")
	# Pure derivation over a synthetic batch: the table is applied to EVERY
	# mapped event — hidden or visible source alike (consumption filters later).
	var sim: CombatSim = make_sim()
	add_human(sim, "h1", {"team": "party", "position": [2, 2]})
	var batch: Array[Dictionary] = [
		{"type": "shock_shout", "combatant": "h1"},
		{"type": "moved", "actor": "h1", "to": [4, 0], "spaces": 2, "free": true},
		{"type": "action_resolved", "actor": "h1", "kind": "attack", "result": "ok"},
		{"type": "action_resolved", "actor": "h1", "kind": "skill", "result": "ok"},  # not a noise source
		{"type": "door_changed", "actor": "h1", "key": "d", "position": [7, 0], "state": "open"},
		{"type": "explosion_blast", "combatant": "h1", "phase": 2, "radius": 3, "position": [9, 9]},
		{"type": "moved", "actor": "nobody_known", "to": [1, 1]},  # unknown source with a position: still a row
		{"type": "shock_shout", "combatant": "ghost_unknown"},  # unknown source, no position: skipped
	]
	var noises: Array[Dictionary] = Stealth.derive_noises(batch, sim.combatants)
	assert_eq(noises.size(), 6, "exactly the mapped source set derives (skill resolution and sourceless rows do not)")
	assert_eq(int(noises[0]["loudness"]), Stealth.NOISE_LOUD, "shout row is LOUD")
	assert_eq(noises[0]["position"], Vector2i(2, 2), "positionless events read the source's hex")
	assert_eq(int(noises[1]["loudness"]), Stealth.NOISE_QUIET, "movement row is QUIET")
	assert_eq(noises[1]["position"], Vector2i(4, 0), "movement noise happens at the DESTINATION")
	assert_eq(int(noises[2]["loudness"]), Stealth.NOISE_MODERATE, "attack resolution row is MODERATE")
	assert_eq(int(noises[3]["loudness"]), Stealth.NOISE_MODERATE, "door flip row is MODERATE")
	assert_eq(noises[3]["position"], Vector2i(7, 0), "door noise happens at the door's hex")
	assert_eq(int(noises[4]["loudness"]), Stealth.NOISE_MODERATE, "explosion row is MODERATE")
	assert_eq(noises[4]["position"], Vector2i(9, 9), "blast noise happens at the blast center")
	assert_eq(String(noises[5]["source"]), "nobody_known", "an event-carried position needs no live source")
	# The range half of the sense: boundary inclusive, pure distance, no LOS.
	assert_true(Stealth.hears(Vector2i(0, 0), Vector2i(3, 0), Stealth.NOISE_QUIET), "distance == loudness is heard")
	assert_false(Stealth.hears(Vector2i(0, 0), Vector2i(4, 0), Stealth.NOISE_QUIET), "one past the band is not")


func test_movement_band_vs_attack_band_behavioral() -> void:
	# Loudness IS the hearing range: at distance 5, footsteps (3) are silent
	# but an attack from stealth (6) is heard — the bands split behaviorally.
	# The strike lands on a BLIND non-AI dummy (Mind 0, Contestant category)
	# so the AI listener survives to hear it — and the dummy itself pins the
	# hearer gate: only AI combatants ever alert.
	var sim: CombatSim = make_sim()
	add_enemy(sim, "mob", "roach_dog", [0, 0])  # Mind 0: sight 0 — hears, never sees
	add_human(sim, "dummy", {"team": "enemies", "position": [6, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3}})
	add_human(sim, "ghost", {"team": "party", "position": [6, 1]})
	stealth(sim, "ghost")
	advance(sim, 1)
	var step: Array[Dictionary] = move(sim, "ghost", [5, 0])
	assert_no_hearing_events(step, "footsteps at distance 5 > quiet range 3 — unheard")
	assert_true(sim.combatants["mob"].alerted.is_empty(), "no alert from the unheard move")
	advance(sim, 1)
	declare(sim, "ghost", attack_action("crushed", 1, "dummy", "torso", {"attack_range": 1}))
	var resolution: Array[Dictionary] = advance(sim, 2)
	var heard: Dictionary = assert_event(resolution, "noise_heard", "the strike at distance 5 <= moderate range 6 is heard")
	assert_eq(String(heard.get("combatant", "")), "mob", "the mob is the hearer")
	assert_eq(String(heard.get("source", "")), "ghost", "the broadcast names the source (omniscient cameras)")
	assert_eq(int(heard.get("loudness", 0)), Stealth.NOISE_MODERATE, "attack loudness rides the event")
	assert_event(resolution, "alerted", "the unalerted mob transitions to ALERTED")
	assert_true(sim.combatants["ghost"].stealthed, "attacking from stealth stays hidden (wave 4c rule) — heard, not seen")
	assert_eq(sim.combatants["mob"].alerted.get("sound", []), [5, 0], "the alert stores where the sound happened")
	assert_true(sim.combatants["dummy"].alerted.is_empty(), "a non-AI bystander never alerts — its ears are the player's")


func test_hidden_shouter_is_revealed_not_alert_tracked() -> void:
	# The documented v1 consequence: a shout never alerts — the R13 wire (the
	# stealth sweep, which runs FIRST) breaks the shouter's own stealth, fully
	# revealing it: strictly MORE information than an alert. The LOUD table
	# row stays real for authored no-visible-source noises (voicebox).
	var sim: CombatSim = make_sim()
	add_enemy(sim, "mob", "roach_dog", [0, 0])
	add_human(sim, "ghost", {"team": "party", "position": [5, 0]})
	stealth(sim, "ghost")
	var batch: Array[Dictionary] = sim.apply_command({"type": "apply_condition",
		"target": "ghost", "part": "torso", "condition": "burn", "tier": 1})
	assert_event(batch, "shock_shout", "burn T1 shouts (R13)")
	var broken: Dictionary = assert_event(batch, "stealth_broken", "the shout breaks the SHOUTER's stealth")
	assert_eq(String(broken.get("reason", "")), "shout", "the wave-4c self-break rule, unchanged")
	assert_no_hearing_events(batch, "no alert: the revealed shouter is default-detected again")
	assert_true(sim.combatants["mob"].alerted.is_empty(), "the mob tracks nothing — it simply KNOWS")


# ------------------------------------------------- the ALERTED state + behavior

func test_hidden_movers_noise_alerts_investigator_who_walks_to_the_sound() -> void:
	# THE PINNED DIVERGENCE: the investigator walks to where the sound WAS,
	# never to the mover's CURRENT hex — the alert stores a sound, not a who.
	var sim: CombatSim = make_sim()
	add_enemy(sim, "hound", "war_hound", [0, 0])  # Mind 1: sight 2; herder -> investigates
	add_human(sim, "ghost", {"team": "party", "position": [6, 0]})
	assert_event(stealth(sim, "ghost"), "stealth_entered", "distance 6 > sight 2 — unseen hide")
	advance(sim, 1)
	# The hidden mover closes to [3, 0]: distance 3 — outside sight 2, inside
	# quiet range 3. Heard, not seen.
	var step: Array[Dictionary] = move(sim, "ghost", [3, 0])
	var heard: Dictionary = assert_event(step, "noise_heard", "footsteps at distance 3 <= quiet 3")
	assert_eq(String(heard.get("combatant", "")), "hound", "the hound heard it")
	assert_eq(int(heard.get("loudness", 0)), Stealth.NOISE_QUIET, "movement loudness")
	var alert_event: Dictionary = assert_event(step, "alerted", "unalerted -> ALERTED transition")
	assert_eq(alert_event.get("position", []), [3, 0], "the event carries the sound's hex")
	assert_true(sim.combatants["ghost"].stealthed, "hearing never REVEALS — the mover stays hidden")
	var alerted: Dictionary = sim.combatants["hound"].alerted
	assert_eq(alerted.get("sound", []), [3, 0], "the state stores WHERE THE SOUND WAS")
	var keys: Array = alerted.keys()
	keys.sort()
	assert_eq(keys, ["sound", "tick"], "the state stores ONLY {sound, tick} — no source id, by ruling")
	advance(sim, 1)
	# The mover slips away to [3, 3]: distance 6 from the hound — out of the
	# quiet band, so the second move is UNHEARD and the alert stays anchored.
	var away: Array[Dictionary] = move(sim, "ghost", [3, 3])
	assert_no_hearing_events(away, "footsteps at distance 6 are out of the quiet band")
	assert_eq(sim.combatants["hound"].alerted.get("sound", []), [3, 0], "the anchor did not follow the mover")
	# The investigator's decide: no visible targets + a live alert -> it moves
	# toward the SOUND's hex — and lands on [3, 0], not the mover's [3, 3].
	var ai_rng_before: int = sim.ai.ai_rng.state
	var decide: Array[Dictionary] = ai_decide(sim, "hound")
	var decision: Dictionary = assert_event(decide, "ai_decision", "the hound decided")
	assert_eq(String(decision.get("choice", "")), "move", "an investigator MOVES")
	assert_eq(String(decision.get("reason", "")), "investigating", "the documented reason")
	assert_true(bool(decision.get("moves", false)), "the step really resolves")
	assert_eq(sim.combatants["hound"].position, Vector2i(3, 0), "it walked to where the sound WAS")
	assert_ne(sim.combatants["hound"].position, Vector2i(3, 3), "NOT to the mover's new position (the divergence pin)")
	assert_eq(sim.ai.ai_rng.state, ai_rng_before, "zero rng: no candidates exist, nothing is drawn")
	assert_eq(String(sim.ai.stances.get("hound", "")), "alert", "stance surfaces the hearing state")
	assert_true(sim.combatants["ghost"].stealthed, "still hidden after the investigation walk (distance 3 > sight 2)")
	# Arrived on the sound's hex with nothing there: the next decide HOLDS.
	advance(sim, 1)
	var hold: Dictionary = assert_event(ai_decide(sim, "hound"), "ai_decision", "the follow-up decide")
	assert_eq(String(hold.get("choice", "")), "wait", "arrived — nothing here — hold and listen")
	assert_eq(String(hold.get("reason", "")), "alerted_holding", "the documented hold reason")
	assert_eq(String(sim.ai.stances.get("hound", "")), "alert", "still on edge")


func test_non_investigator_alerts_but_holds() -> void:
	var sim: CombatSim = make_sim()
	add_enemy(sim, "mob", "roach_dog", [0, 0])  # Mind 0, not a herder -> ignores
	add_human(sim, "ghost", {"team": "party", "position": [4, 0]})
	stealth(sim, "ghost")
	advance(sim, 1)
	var step: Array[Dictionary] = move(sim, "ghost", [1, 0])
	assert_event(step, "alerted", "the roach still becomes ALERTED — it knows SOMETHING is there")
	var decide: Dictionary = assert_event(ai_decide(sim, "mob"), "ai_decision", "the roach decided")
	assert_eq(String(decide.get("choice", "")), "wait", "a non-investigator holds")
	assert_eq(String(decide.get("reason", "")), "alerted_holding", "alerted, not plain no_targets")
	assert_eq(sim.combatants["mob"].position, Vector2i(0, 0), "it did not move")
	assert_eq(String(sim.ai.stances.get("mob", "")), "alert", "the stance shifts — the only behavior change")
	assert_true(sim.combatants["ghost"].stealthed, "adjacent-ish but Mind 0 sees nothing — still hidden")


func test_investigates_personality_gate_and_template_landing() -> void:
	# Derived default (PROVISIONAL, R14): Mind >= 2 OR herder; explicit key wins.
	var data: Dictionary = SimTestBase.load_static_data()
	var hound: CombatantState = CombatantState.from_spec({"id": "a", "enemy": "war_hound"}, data)
	var roach: CombatantState = CombatantState.from_spec({"id": "b", "enemy": "roach_dog"}, data)
	var tender: CombatantState = CombatantState.from_spec({"id": "c", "enemy": "little_brother_roach"}, data)
	var boss: CombatantState = CombatantState.from_spec({"id": "d", "enemy": "incinedile"}, data)
	assert_true(EnemyAI.investigates(hound), "war_hound investigates (herder — the hunter's nose, Mind 1)")
	assert_false(EnemyAI.investigates(roach), "roach_dog ignores (Mind 0, no herder)")
	assert_false(EnemyAI.investigates(tender), "little_brother_roach ignores (Mind 1)")
	assert_false(EnemyAI.investigates(boss), "incinedile ignores (Mind 1 — the boss holds its arena)")
	var smart: CombatantState = CombatantState.from_spec({"id": "e", "race": "human", "category": "Mob",
		"traits": {"physique": 1, "reflexes": 1, "mind": 2, "charm": 1}}, data)
	assert_true(EnemyAI.investigates(smart), "Mind 2 crosses the derived smart threshold")
	var timid: CombatantState = CombatantState.from_spec({"id": "f", "enemy": "war_hound",
		"personality": {"investigates": false}}, data)
	assert_false(EnemyAI.investigates(timid), "an explicit authored key beats the herder default")
	var curious: CombatantState = CombatantState.from_spec({"id": "g", "enemy": "roach_dog",
		"personality": {"investigates": true}}, data)
	assert_true(EnemyAI.investigates(curious), "an explicit authored key beats the Mind default")


func test_visible_actors_noise_changes_nothing() -> void:
	# The redundant-with-detection pin, with the sweep ACTIVE (a hidden third
	# party keeps it from short-circuiting): a visible actor's noise derives
	# but is never consumed — the AI already knows the actor is there.
	var sim: CombatSim = make_sim()
	add_enemy(sim, "mob", "roach_dog", [0, 0])
	add_human(sim, "h1", {"team": "party", "position": [3, 0]})
	add_human(sim, "ghost", {"team": "party", "position": [30, 0]})
	stealth(sim, "ghost")  # far away — keeps any_hidden true, makes no noise
	advance(sim, 1)
	var step: Array[Dictionary] = move(sim, "h1", [1, 0])
	assert_no_hearing_events(step, "the visible mover's footsteps alert nobody")
	assert_true(sim.combatants["mob"].alerted.is_empty(), "no state change either")


func test_alert_decays_after_a_quiet_clock() -> void:
	var sim: CombatSim = make_sim()
	add_enemy(sim, "mob", "roach_dog", [0, 0])
	add_human(sim, "ghost", {"team": "party", "position": [4, 0]})
	stealth(sim, "ghost")
	advance(sim, 1)
	move(sim, "ghost", [1, 0])
	assert_false(sim.combatants["mob"].alerted.is_empty(), "alerted by the footsteps")
	# The boundary, pinned exactly: heard at tick T -> clears once
	# clock.tick >= T + TICKS_PER_CLOCK (a full quiet Clock). 9 ticks: alive.
	var nine: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK - 1)
	assert_no_event(nine, "alert_cleared", "nine quiet ticks are not a full Clock")
	assert_false(sim.combatants["mob"].alerted.is_empty(), "still alerted at 9")
	var tenth: Array[Dictionary] = advance(sim, 1)
	var cleared: Dictionary = assert_event(tenth, "alert_cleared", "the tenth quiet tick decays it")
	assert_eq(String(cleared.get("reason", "")), "decayed", "the decay reason")
	assert_true(sim.combatants["mob"].alerted.is_empty(), "state cleared")
	# Behavior returns to the plain pre-hearing wait.
	var decide: Dictionary = assert_event(ai_decide(sim, "mob"), "ai_decision", "post-decay decide")
	assert_eq(String(decide.get("reason", "")), "no_targets", "the honest old wait is back")
	assert_eq(String(sim.ai.stances.get("mob", "")), "defensive", "stance back to the wait bucket")


func test_new_noise_refreshes_the_alert_anchor() -> void:
	var sim: CombatSim = make_sim()
	add_enemy(sim, "mob", "roach_dog", [0, 0])
	add_human(sim, "ghost", {"team": "party", "position": [4, 0]})
	stealth(sim, "ghost")
	advance(sim, 1)
	move(sim, "ghost", [1, 0])
	var first_tick: int = int(sim.combatants["mob"].alerted.get("tick", -1))
	advance(sim, 3)
	var again: Array[Dictionary] = move(sim, "ghost", [2, 0])
	assert_event(again, "noise_heard", "the refresh is heard")
	assert_no_event(again, "alerted", "no second transition event — refreshes ride noise_heard")
	assert_eq(sim.combatants["mob"].alerted.get("sound", []), [2, 0], "the anchor moved to the fresh sound")
	assert_true(int(sim.combatants["mob"].alerted.get("tick", -1)) > first_tick, "the decay window restarted")


# ------------------------------------------------- views / serialization / rng

func test_view_combatants_carries_alerted_only_when_set() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, SimTestBase.load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [0, 0]}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "ghost", "name": "ghost", "race": "human", "team": "party", "position": [4, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	for row: Dictionary in game.view_combatants():
		assert_false(row.has("alerted"), "no alerted key while nothing was heard (%s)" % String(row.get("id", "")))
	game.apply_command({"type": "stealth", "actor": "ghost"})
	game.apply_command({"type": "advance_tick"})
	game.apply_command({"type": "move", "actor": "ghost", "to": [1, 0]})
	var seen: bool = false
	for row: Dictionary in game.view_combatants():
		if String(row.get("id", "")) == "mob":
			seen = row.has("alerted")
			assert_eq((row.get("alerted", {}) as Dictionary).get("sound", []), [1, 0],
				"the view carries the state verbatim — the sound's hex, no source id")
		else:
			assert_false(row.has("alerted"), "only the alerted AI row grows the key")
	assert_true(seen, "the alerted AI row exposes the state (the broadcast is omniscient)")
	game.free()


func test_serialization_roundtrip_mid_alert_and_lockstep_decay() -> void:
	var sim: CombatSim = make_sim()
	add_enemy(sim, "mob", "roach_dog", [0, 0])
	add_human(sim, "ghost", {"team": "party", "position": [4, 0]})
	stealth(sim, "ghost")
	advance(sim, 1)
	move(sim, "ghost", [1, 0])
	var dict: Dictionary = sim.to_dict()
	assert_true((dict["combatants"]["mob"] as Dictionary).has("alerted"), "the alerted mob serializes the key")
	assert_false((dict["combatants"]["ghost"] as Dictionary).has("alerted"), "nobody else grows it")
	var mid_hash: String = sim.state_hash()
	var restored: CombatSim = CombatSim.from_dict(dict)
	assert_eq(restored.state_hash(), mid_hash, "round-trip hash identical (alerted covered)")
	assert_eq(restored.combatants["mob"].alerted.get("sound", []), [1, 0], "the state survived the trip")
	# Lockstep tail through the DECAY: both sims run the same quiet Clock and
	# clear the alert on the same tick with the same events.
	for target: CombatSim in [sim, restored] as Array[CombatSim]:
		var tail: Array[Dictionary] = []
		for i: int in range(Clock.TICKS_PER_CLOCK):
			tail.append_array(target.apply_command({"type": "advance_tick"}))
		assert_event(tail, "alert_cleared", "both sims decay on the same quiet Clock")
		assert_true(target.combatants["mob"].alerted.is_empty(), "both cleared")
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash")


func test_hearing_paths_consume_zero_rng_and_replay_deterministically() -> void:
	# R20 authors NO hearing roll: derivation, consumption, alerting, the
	# investigate walk and the decay must consume neither rng stream.
	var sim: CombatSim = make_sim()
	add_enemy(sim, "hound", "war_hound", [0, 0])
	add_human(sim, "ghost", {"team": "party", "position": [6, 0]})
	stealth(sim, "ghost")
	advance(sim, 1)
	var action_rng: int = sim.rng.state
	var ai_rng: int = sim.ai.ai_rng.state
	move(sim, "ghost", [3, 0])       # heard -> alerted
	advance(sim, 1)
	move(sim, "ghost", [3, 3])       # slips away unheard — stays hidden
	ai_decide(sim, "hound")          # investigate walk to the sound (no candidates -> no draw)
	advance(sim, 1)
	ai_decide(sim, "hound")          # arrived: alerted_holding
	advance(sim, Clock.TICKS_PER_CLOCK)  # decay
	assert_true(sim.combatants["hound"].alerted.is_empty(), "decayed on the quiet Clock")
	assert_true(sim.combatants["ghost"].stealthed, "hidden through the whole investigation")
	assert_eq(sim.rng.state, action_rng, "action RNG untouched by every hearing path")
	assert_eq(sim.ai.ai_rng.state, ai_rng, "AI RNG untouched too (no roll authored)")
	# Full-fight determinism: the same seed + the same hearing-heavy log lands
	# on the same hash, twice.
	var hashes: Array[String] = []
	for _round: int in range(2):
		hashes.append(_hearing_fight_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) -> same hash through the hearing kit")


## One full hearing-heavy fight from a fixed seed; returns its final hash.
func _hearing_fight_hash() -> String:
	var sim: CombatSim = make_sim(99)
	add_enemy(sim, "hound", "war_hound", [0, 0])
	add_enemy(sim, "mob", "roach_dog", [0, 3])
	add_human(sim, "ghost", {"team": "party", "position": [6, 0]})
	stealth(sim, "ghost")
	advance(sim, 1)
	move(sim, "ghost", [3, 0])
	ai_decide(sim, "hound")
	ai_decide(sim, "mob")
	advance(sim, 1)
	move(sim, "ghost", [3, 3])
	ai_decide(sim, "hound")
	ai_decide(sim, "mob")
	advance(sim, 1)
	declare(sim, "ghost", attack_action("crushed", 1, "mob", "carapace", {"attack_range": 6}))
	advance(sim, Clock.TICKS_PER_CLOCK + 1)
	return sim.state_hash()
