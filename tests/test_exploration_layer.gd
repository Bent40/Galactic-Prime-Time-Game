extends SimTestBase
## R35 — THE EXPLORATION LAYER (owner rulings 2026-08-19; contract in
## docs/rules-addendum.md R35, model in simulation/exploration.gd). R34 shipped
## free-form exploration as a MOVEMENT MODE with four gaps named honestly; the
## owner ruled three of them the same day and this file pins all three. The
## fourth (run-loop + HUD wiring) is KAN-6 and is deliberately absent.
##
## Under test:
##  * #1 THE FREE-FORM ACTS — voicebox, lockpicking and (the owner's same-day
##    addition) INVENTORY / item use WORK out of combat and charge NOTHING (no
##    Moment, no free-action budget entry, no scheduling, and for inventory no
##    R3 `inventory_uses` entry either), with the CONTRAST pin that all three
##    cost normally the instant combat starts; every OTHER declare still
##    rejects clock_stopped.
##  * #1b THE SHARPEST EXPRESSION of R34's contact rule: a thrown sound starts
##    a fight SOMEWHERE ELSE — a far mob hears it, becomes ALERTED on the
##    THROWN hex (never on the thrower), and the thrower is never seen and
##    never revealed. No new machinery: the existing contact predicate.
##  * #2 PATROLS — one step per exploration TIME STEP (the owner's 2026-08-19
##    revision: "time should just be moving"; a party WALK grants no beat and
##    STANDING STILL NEVER FREEZES THE ROOM), an authored waypoint cycle, the
##    derived facing-axis pace with its about-face, a patrolling cone that
##    walks into a MOTIONLESS party and starts the fight naming SIGHT (with
##    the no-patrol CONTRAST proving the patrol caused it), determinism (same
##    log -> same hash) and the twin-RNG zero-draw pin.
##  * THE TIME MODEL — advance_tick is legal out of combat and runs the ONE
##    real tick path, so the per-tick sweeps really run: conditions advance,
##    hype decays and the crowd-goal director fires at a Clock reset. Pinned
##    explicitly rather than discovered later. PAUSE is the driver not
##    issuing time steps and has no sim state — asserted by its absence.
##  * #3 THE CROWD WATCHES — the three expressible sources with their authored
##    magnitudes, the ruled "idle walking through a cleared room pays nothing",
##    and the R29 chain carry (a tense approach arrives at the fight warm).
##  * DISCIPLINE — patrol serializes only-when-set, round-trips, and a
##    combat-only fight stays hash-identical to the recorded legacy hashes.

## The recorded pre-stealth legacy hashes — SHARED TRUTH with
## tests/test_exploration.gd, tests/test_stealth.gd and tests/test_hearing.gd.
const LEGACY_HASH_PLAIN: String = "6d8046456d4aee1059e775d8d08f6eee2519c511f2e36df4b5c8ee25ca9b6a70"


# ---------------------------------------------------------------- helpers

func explore(sim: CombatSim) -> Array[Dictionary]:
	return sim.apply_command({"type": "phase", "set": "exploration"})


func enter_combat(sim: CombatSim) -> Array[Dictionary]:
	return sim.apply_command({"type": "phase", "set": "combat"})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func skill(key: String, level: int, extra: Dictionary = {}) -> Dictionary:
	var action: Dictionary = {"kind": "skill", "key": key, "level": level}
	action.merge(extra, true)
	return action


func add_contestant(sim: CombatSim, id: String, pos: Array) -> Array[Dictionary]:
	return add_human(sim, id, {"team": "party", "position": pos})


## An AI-controlled mob with an explicit Mind (R20 sight = 2 x Mind) and an
## optional R35 patrol value (true = the derived pace; {"route": [...]} = the
## authored cycle; absent = the pre-R35 statue).
func add_mob(sim: CombatSim, id: String, pos: Array, mind: int = 3, patrol: Variant = null) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "category": "Mob", "team": "enemies", "position": pos,
		"traits": {"physique": 2, "reflexes": 2, "mind": mind, "charm": 1}}
	if patrol != null:
		spec["patrol"] = patrol
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


## A "large boss" for the R35 approach source: the Boss CATEGORY and the Huge
## size band both qualify (Exploration._spectacle_is_large).
func add_boss(sim: CombatSim, id: String, pos: Array, mind: int = 3) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "category": "Boss", "size": "Huge",
		"team": "enemies", "position": pos,
		"traits": {"physique": 6, "reflexes": 3, "mind": mind, "charm": 2}}})


func open_arena(sim: CombatSim, extra: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {"bounds": {"width": 61, "height": 61}}
	spec.merge(extra, true)
	return sim.apply_command({"type": "set_arena", "arena": spec})


func lock_arena(sim: CombatSim, key: String, at: Array, tier: String) -> Array[Dictionary]:
	return open_arena(sim, {"doors": [
		{"key": key, "position": at, "state": "closed",
			"lock": {"tier": tier, "state": "locked"}}]})


# ======================================================================
# R35 #1 — VOICEBOX AND LOCKPICKING WORK IN EXPLORATION
# ======================================================================

func test_lockpicking_is_free_in_exploration_and_priced_in_combat() -> void:
	# EXPLORATION HALF: the pick resolves on the spot, reports 0 Moments (that
	# IS the waiver), schedules nothing and charges no budget entry.
	var sim: CombatSim = make_sim()
	lock_arena(sim, "vault", [1, 0], "simple")
	add_contestant(sim, "h1", [0, 0])
	var h1: CombatantState = sim.combatants["h1"]
	var ready_at: int = h1.next_action_tick
	explore(sim)
	# The locked door still rejects the plain door command (the R33 substrate).
	assert_rejected(sim.apply_command({"type": "door", "actor": "h1", "key": "vault",
		"set": "open"}), "door_locked", "exploration does not unlock doors by walking at them")
	var picked_batch: Array[Dictionary] = declare(sim, "h1", skill("lockpicking", 1, {"door": "vault"}))
	assert_no_event(picked_batch, "action_declared",
		"nothing is DECLARED out of combat — there is no schedule to declare into")
	var picked: Dictionary = assert_event(picked_batch, "lock_picked", "the pick resolves immediately")
	assert_eq(int(picked.get("moments", -1)), 0, "0 Moments charged — the R35 waiver, reported honestly")
	assert_event(picked_batch, "action_resolved", "the skill resolution completes in the same command")
	assert_eq(h1.free_actions_used, 0, "no free-action budget entry spent")
	assert_false(h1.free_action_used, "…and the derived budget-exhausted view agrees")
	assert_eq(h1.next_action_tick, ready_at, "no Moments charged (next_action_tick untouched)")
	assert_true(sim.clock.queue.is_empty(), "nothing was scheduled on the stopped clock")
	assert_eq(sim.clock.tick, 0, "no tick advanced")
	assert_event(sim.apply_command({"type": "door", "actor": "h1", "key": "vault", "set": "open"}),
		"door_changed", "the picked lock frees the door")

	# The gates still bind out of combat — the waiver is about COST, never legality.
	var sim2: CombatSim = make_sim()
	lock_arena(sim2, "cage", [1, 0], "moderate")
	add_contestant(sim2, "h1", [0, 0])
	explore(sim2)
	assert_rejected(declare(sim2, "h1", skill("lockpicking", 1, {"door": "cage"})),
		"lock_tier_beyond_skill", "L1 still cannot touch a moderate lock out of combat")
	assert_rejected(declare(sim2, "h1", skill("lockpicking", 3, {"door": "missing"})),
		"unknown_door", "an unknown door still rejects")
	var l3: Array[Dictionary] = declare(sim2, "h1", skill("lockpicking", 3, {"door": "cage"}))
	assert_eq(int(assert_event(l3, "lock_picked", "L3 reaches moderate").get("moments", -1)), 0,
		"a 2-Moment windup pick costs 0 out of combat too — no windup exists to pay for")
	assert_true(sim2.clock.queue.is_empty(), "and it is still not a windup")

	# COMBAT HALF (the contrast pin): the identical declare pays the full R3
	# price the instant the clock runs — a real 2-Moment windup.
	var sim3: CombatSim = make_sim()
	lock_arena(sim3, "cage", [1, 0], "moderate")
	add_contestant(sim3, "h1", [0, 0])
	var declared: Dictionary = assert_event(
		declare(sim3, "h1", skill("lockpicking", 3, {"door": "cage"})),
		"action_declared", "in combat the pick SCHEDULES")
	assert_eq(int(declared.get("cost", 0)), 2, "moderate = 2 Moments at L3 (the substrate tier table)")
	assert_true(bool(declared.get("windup", false)), "…and it is a real windup")
	assert_false(sim3.clock.queue.is_empty(), "the combat pick really is on the clock")
	assert_eq(int(assert_event(advance(sim3, 3), "lock_picked", "it resolves later").get("moments", -1)), 2,
		"the combat event reports the Moments actually charged — full R3 price")


func test_voicebox_is_free_in_exploration_and_budgeted_in_combat() -> void:
	# EXPLORATION HALF: throw as often as you like — no budget, no schedule.
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	var h1: CombatantState = sim.combatants["h1"]
	explore(sim)
	for at: Array in [[5, 0], [0, 5], [6, 1], [2, 2]]:
		var thrown: Dictionary = assert_event(
			declare(sim, "h1", skill("voicebox", 1, {"at": at})),
			"sound_thrown", "a free-form throw at %s" % str(at))
		assert_eq(int(thrown.get("loudness", 0)), Stealth.NOISE_LOUD,
			"the R20 table's LOUD row, unchanged by the waiver")
	assert_eq(h1.free_actions_used, 0, "four throws, zero free-action budget spent")
	assert_true(sim.clock.queue.is_empty(), "nothing scheduled")
	assert_eq(sim.clock.tick, 0, "no tick advanced")
	# The declare gates still bind: throw_range 10 is still 10.
	assert_rejected(declare(sim, "h1", skill("voicebox", 1, {"at": [50, 0]})),
		"out_of_range", "the waiver frees the COST, never the range")
	assert_rejected(declare(sim, "h1", skill("voicebox", 1)),
		"throw_target_required", "a throw still names a hex")

	# COMBAT HALF (the contrast pin): cost 0 means the FREE-ACTION BUDGET, and
	# the owner's budget is two per window (R34 amending R3) — the third
	# throw rejects free_action_used.
	assert_event(enter_combat(sim), "combat_started", "deliberate entry")
	var first: Array[Dictionary] = declare(sim, "h1", skill("voicebox", 1, {"at": [5, 0]}))
	assert_event(first, "action_declared",
		"in combat the throw is DECLARED onto the schedule — it resolves at its tick")
	assert_no_event(first, "sound_thrown", "…so nothing happens in the declare command itself")
	assert_eq(sim.combatants["h1"].free_actions_used, 1, "the R3 economy resumes the moment the clock runs")
	assert_event(declare(sim, "h1", skill("voicebox", 1, {"at": [5, 0]})),
		"action_declared", "second throw spends the rest of the budget")
	assert_eq(sim.combatants["h1"].free_actions_used, 2, "budget at two (R34 amending R3)")
	assert_rejected(declare(sim, "h1", skill("voicebox", 1, {"at": [5, 0]})),
		"free_action_used", "two free actions per window, then no more")
	assert_event(advance(sim, 1), "sound_thrown", "the scheduled throws land on their tick")


func test_inventory_and_item_use_are_free_in_exploration() -> void:
	# Owner, 2026-08-19: "Time can pause during inventory and item use in
	# exploration mode so players can heal their characters and the likes.
	# Pokemon had the same system for poison or burn, i think thats fine."
	var sim: CombatSim = make_sim()
	add_human(sim, "h1", {"team": "party", "position": [0, 0],
		"items": [{"key": "bandage", "name": "Bandage", "base_moment_cost": 2, "dropped": true}]})
	var h1: CombatantState = sim.combatants["h1"]
	var ready_at: int = h1.next_action_tick
	explore(sim)
	# FOUR interactions in one phase — in combat only the first is free.
	for i: int in range(4):
		var used: Dictionary = assert_event(
			sim.apply_command({"type": "inventory", "actor": "h1", "interaction": "use",
				"item": "bandage"}), "inventory_used", "interaction %d out of combat" % (i + 1))
		assert_true(bool(used.get("free", false)), "…and every one of them is free")
		assert_true(bool(used.get("exploration", false)), "flagged exploration for the view layer")
	assert_eq(h1.free_actions_used, 0, "no free-action budget entry spent")
	assert_eq(h1.inventory_uses, 0,
		"…and R3's first-free ledger is UNTOUCHED — an out-of-combat heal never charges the next fight")
	assert_eq(h1.next_action_tick, ready_at, "no Moments charged")
	assert_true(sim.clock.queue.is_empty(), "nothing scheduled")
	assert_eq(sim.clock.tick, 0, "and item use advances no tick of its own")
	# THE EFFECT REALLY RUNS (not an acceptance stub): a dropped item comes back.
	assert_true(bool((h1.items["bandage"] as Dictionary).get("dropped", false)),
		"sanity: the bandage is on the floor to start with")
	var recovered: Array[Dictionary] = sim.apply_command({"type": "inventory", "actor": "h1",
		"interaction": "pickup", "item": "bandage"})
	assert_event(recovered, "item_recovered", "the ordinary interaction effect fires out of combat")
	assert_false(bool((h1.items["bandage"] as Dictionary).get("dropped", true)),
		"…and the item really is back in hand")
	assert_rejected(sim.apply_command({"type": "inventory", "actor": "ghost"}),
		"unknown_actor", "the gates still bind")

	# COMBAT CONTRAST: R3's ladder resumes whole — first free (one budget
	# entry + the never-resetting inventory_uses), the next one costs Moments.
	assert_event(enter_combat(sim), "combat_started", "deliberate entry")
	var first: Dictionary = assert_event(sim.apply_command({"type": "inventory", "actor": "h1",
		"interaction": "use", "item": "bandage"}), "inventory_used", "first combat interaction")
	assert_true(bool(first.get("free", false)), "…is the R3 freebie")
	assert_eq(h1.inventory_uses, 1, "the never-resetting ledger starts counting the moment combat does")
	assert_eq(h1.free_actions_used, 1, "…and it spends a free-action budget entry")
	var second: Array[Dictionary] = sim.apply_command({"type": "inventory", "actor": "h1",
		"interaction": "use", "item": "bandage"})
	var declared: Dictionary = assert_event(second, "action_declared", "the second one is SCHEDULED")
	assert_eq(int(declared.get("cost", 0)), 2, "…at the item's own Moment cost (R3, exploit deleted)")
	assert_false(sim.clock.queue.is_empty(), "the combat interaction really is on the clock")


func test_the_menu_does_not_race_the_burn() -> void:
	# The owner's Pokemon intent, in the half the SIM can guarantee: an
	# inventory command advances no tick, so a wound cannot advance while the
	# player rummages. The other half is the driver contract (stop issuing
	# time steps while the UI is open) — documented, not modelled.
	var sim: CombatSim = make_sim()
	add_human(sim, "h1", {"team": "party", "position": [0, 0],
		"items": [{"key": "salve", "name": "Salve", "base_moment_cost": 1}]})
	sim.apply_command({"type": "apply_condition", "target": "h1", "part": "torso",
		"condition": "burn", "tier": 1})
	explore(sim)
	advance(sim, 9)  # nine steps: one short of the Clock that advances the burn
	assert_eq(sim.clock.tick, 9, "time really did flow while the party walked")
	var rummaging: Array[Dictionary] = []
	for _i: int in range(8):
		rummaging.append_array(sim.apply_command({"type": "inventory", "actor": "h1",
			"interaction": "use", "item": "salve"}))
	assert_eq(sim.clock.tick, 9, "eight interactions, not one tick — the menu is outside time")
	assert_no_event(rummaging, "condition_advanced", "THE BURN DOES NOT TICK WHILE YOU HEAL")
	assert_no_event(rummaging, "clock_reset", "no Clock can complete without a time step")
	# ...and the very next TIME STEP does advance it, so nothing is suppressed.
	assert_event(advance(sim, 1), "condition_advanced",
		"conditions tick while you WALK, not while you are in the menu — the ruled split")


func test_only_the_two_ruled_declares_are_waived() -> void:
	# The waiver is keyed on the ARCHETYPE and names exactly two acts; every
	# other declare keeps rejecting clock_stopped with the same reason string.
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	add_mob(sim, "mob", [30, 0])
	explore(sim)
	var before: String = sim.state_hash()
	assert_rejected(declare(sim, "h1", attack_action("crushed", 3, "mob", "torso")),
		"clock_stopped", "a plain attack is still clock-bound")
	assert_rejected(declare(sim, "h1", skill("pounce", 1, {
		"targets": [{"id": "mob", "part": "torso"}], "leap_to": [29, 0]})),
		"clock_stopped", "a strike SKILL is still clock-bound")
	assert_rejected(declare(sim, "h1", skill("camouflage", 1)),
		"clock_stopped", "a scheduled non-ruled skill is still clock-bound")
	assert_eq(sim.state_hash(), before, "every rejection mutated nothing")
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "and none of them started the fight")
	# The predicate itself, exercised straight.
	assert_true(Exploration.is_free_form_declare({"kind": "skill", "key": "voicebox", "level": 1}),
		"voicebox is waived")
	assert_true(Exploration.is_free_form_declare({"kind": "skill", "key": "lockpicking", "level": 3}),
		"lockpicking is waived")
	assert_false(Exploration.is_free_form_declare({"kind": "attack"}), "attacks never are")
	assert_false(Exploration.is_free_form_declare({"kind": "skill", "key": "pounce", "level": 1}),
		"strike skills never are")
	assert_eq(Exploration.FREE_FORM_ARCHETYPES, ["thrown_sound", "scheduled_pick"],
		"exactly the two SKILL archetypes R35 names (inventory is a command, not a declare)")


func test_a_thrown_sound_starts_the_fight_somewhere_else() -> void:
	# R35: "an authored noise that can start a fight SOMEWHERE ELSE, with the
	# thrower never seen. The contact predicate already consumes derived
	# noises from any hostile-side source, so this composes with no new
	# machinery." This is that test, end to end.
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	# The mob standing right next to the party — Mind 1 (sight 2), so it can
	# neither see the thrower at 5 hexes nor hear a sound thrown 15 away.
	add_mob(sim, "aa_near", [-5, 0], 1)
	# The patrolling guard 18 hexes away, across the map.
	add_mob(sim, "zz_far", [18, 0], 3, true)
	assert_event(sim.apply_command({"type": "stealth", "actor": "h1"}), "stealth_entered",
		"the thrower hides first — nobody can see that far")
	assert_no_contact(sim, explore(sim), "nothing has happened yet")

	# Throw at [10, 0]: within the skill's range-10 reach of the thrower, and
	# 8 hexes from the far guard — inside the LOUD(10) carry.
	var events: Array[Dictionary] = declare(sim, "h1", skill("voicebox", 1, {"at": [10, 0]}))
	assert_event(events, "sound_thrown", "the sound lands on the chosen hex")
	var contact: Dictionary = assert_event(events, "contact", "the FAR guard hears it")
	assert_eq(String(contact.get("by", "")), "zz_far", "the fight starts SOMEWHERE ELSE")
	assert_eq(String(contact.get("sense", "")), "hearing", "by hearing, never by sight")
	assert_eq(String(contact.get("target", "")), "h1", "the noise's maker is named (the door precedent)")
	assert_eq(String(assert_event(events, "combat_started", "clock starts").get("reason", "")),
		"contact", "involuntary entry")
	# THE THROWER IS NEVER SEEN.
	assert_no_event(events, "stealth_broken", "the throw reveals nothing (R20 round 5, unchanged)")
	assert_true(sim.combatants["h1"].stealthed, "still hidden after starting a fight across the room")
	assert_false(Stealth.sees(sim.combatants["zz_far"], sim.combatants["h1"], sim.arena, 0),
		"the guard that started the fight cannot see who did it")
	# The mob standing NEXT to the party never noticed a thing.
	assert_true(sim.combatants["aa_near"].alerted.is_empty(),
		"a sound 15 hexes away is out of the near mob's LOUD(10) carry — it sleeps through it")

	# ...and the guard is PULLED TO THE THROWN HEX, not to the thrower: the
	# alert stores a sound, never a source (R20's "it does NOT know where you
	# are"), so its first decision walks toward [10, 0] — AWAY from h1.
	assert_eq(sim.combatants["zz_far"].alerted.get("sound", []), [10, 0],
		"the alert anchors on the thrown hex")
	var decided: Array[Dictionary] = sim.apply_command({"type": "ai_decide", "actor": "zz_far"})
	var decision: Dictionary = assert_event(decided, "ai_decision", "the guard decides")
	assert_eq(String(decision.get("reason", "")), "investigating", "it investigates the SOUND")
	var walked: Vector2i = sim.combatants["zz_far"].position
	assert_true(walked.x < 18 and walked.x >= 10,
		"it walked WEST toward the thrown hex (landed on %s)" % str(walked))
	assert_true(CombatantState.hex_distance(walked, Vector2i(10, 0))
		< CombatantState.hex_distance(Vector2i(18, 0), Vector2i(10, 0)),
		"…closing on the SOUND, never on the thrower's hex")


func assert_no_contact(sim: CombatSim, events: Array[Dictionary], message: String) -> void:
	assert_no_event(events, "contact", message)
	assert_no_event(events, "combat_started", message)
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "still exploring: " + message)


# ======================================================================
# R35 #2 — MOBS PATROL DURING EXPLORATION
# ======================================================================

func test_one_patrol_step_per_time_step_and_none_from_a_walk() -> void:
	# THE BEAT, after the owner's 2026-08-19 revision ("time should just be
	# moving"): the exploration TIME STEP grants each patrolling mob one step.
	# A party walk grants none — and the headline consequence, pinned in the
	# same test: STANDING STILL NEVER FREEZES THE ROOM.
	var sim: CombatSim = make_sim()
	open_arena(sim, {"doors": [{"key": "d", "position": [0, 4], "state": "closed"}]})
	add_contestant(sim, "h1", [0, 0])
	# Mind 0 = blind (the roach_dog precedent), so nothing here can make
	# contact by sight; the party stays 10 hexes out, past QUIET(3) hearing.
	add_mob(sim, "guard", [10, 0], 0, {"route": [[10, 0], [10, 4]]})
	explore(sim)
	var guard: CombatantState = sim.combatants["guard"]
	assert_eq(guard.position, Vector2i(10, 0), "the guard starts on its post")

	# NOT the beat: walking, hiding, doors, throws — none of them is time.
	var walked: Array[Dictionary] = move(sim, "h1", [1, 0])
	assert_eq(events_of(walked, "moved").size(), 1, "a party walk moves the PARTY and nothing else")
	sim.apply_command({"type": "stealth", "actor": "h1"})
	sim.apply_command({"type": "stealth", "actor": "h1", "set": "reveal"})
	sim.apply_command({"type": "door", "actor": "h1", "key": "d", "set": "open"})
	# (thrown well away from the guard — a LOUD(10) sound it could hear would
	# be CONTACT, which is R34 working, not a patrol beat)
	declare(sim, "h1", skill("voicebox", 1, {"at": [1, -9]}))
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "the sound reached nobody")
	assert_eq(guard.position, Vector2i(10, 0), "no command but the time step is a beat")
	assert_eq(sim.clock.tick, 0, "…and none of them advanced the clock either")

	# THE BEAT: one tick, one step — with the party standing perfectly still.
	var frozen: Vector2i = sim.combatants["h1"].position
	var beat: Array[Dictionary] = advance(sim, 1)
	var steps: Array[Dictionary] = events_of(beat, "moved")
	assert_eq(steps.size(), 1, "exactly one patrol step per time step")
	assert_true(bool((steps[0] as Dictionary).get("patrol", false)), "flagged patrol")
	assert_eq(int((steps[0] as Dictionary).get("spaces", 0)), 1, "a beat is ONE hex, never a route")
	assert_eq(guard.position, Vector2i(10, 1), "the guard really moved")
	assert_eq(guard.facing, 5, "the eyeline turned with it (R30: faced along the step, SE)")
	assert_eq(sim.combatants["h1"].position, frozen,
		"STANDING STILL NO LONGER FREEZES THE ROOM — the owner's revision, pinned")
	assert_eq(sim.clock.tick, 1, "the one real clock advanced")

	# THREE more ticks reach the far waypoint; the CYCLE then wraps.
	advance(sim, 3)
	assert_eq(guard.position, Vector2i(10, 4), "four beats, four hexes — it arrived")
	advance(sim, 1)
	assert_eq(guard.position, Vector2i(10, 3), "the route is a loop — a two-point route paces")
	assert_eq(int(guard.patrol.get("index", -1)), 0, "the cursor wrapped to waypoint 0")
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "and nobody ever made contact")
	# PAUSE needs no sim state: the driver simply stops issuing time steps.
	var paused: Vector2i = guard.position
	for _i: int in range(4):
		move(sim, "h1", [2, 0])
		move(sim, "h1", [1, 0])
	assert_eq(guard.position, paused,
		"a paused driver issues no time steps, so nothing moves — and no `paused` flag exists")
	assert_false(sim.to_dict().has("paused"), "PAUSE is deliberately NOT sim state")


func test_the_derived_pace_walks_its_axis_and_turns_around() -> void:
	# No authored route: `patrol: true` buys the DERIVED pace — step along the
	# mob's own facing while the hex ahead is open and inside the leash, else
	# spend the beat about-facing. Zero authoring, zero rng.
	var sim: CombatSim = make_sim()
	open_arena(sim)
	# Staged FIRST with no opponent on the board -> the documented default
	# facing 0 (East); the leash anchors on the staged hex.
	add_mob(sim, "sentry", [5, 0], 0, true)
	add_contestant(sim, "h1", [0, 20])
	var sentry: CombatantState = sim.combatants["sentry"]
	assert_eq(sentry.facing, 0, "staged facing East (no opponent yet)")
	assert_eq(sentry.patrol.get("anchor", []), [5, 0], "the leash anchors where it was staged")
	assert_eq(int(sentry.patrol.get("reach", -1)), Exploration.PATROL_PACE_REACH,
		"the default leash (PLACEHOLDER R14)")
	explore(sim)

	# Three beats east take it to the leash edge.
	for i: int in range(3):
		advance(sim, 1)
		assert_eq(sentry.position, Vector2i(6 + i, 0), "pace step %d east" % (i + 1))
		assert_eq(sentry.facing, 0, "still facing East")
	# The fourth beat is spent TURNING: [9, 0] is 4 hexes off the anchor.
	var turn: Array[Dictionary] = advance(sim, 1)
	assert_eq(int(assert_event(turn, "patrol_turned", "the about-face").get("facing", -1)), 3,
		"turned 180 degrees (West)")
	assert_eq(sentry.position, Vector2i(8, 0), "the beat bought a turn, not a step")
	assert_eq(events_of(turn, "moved").size(), 0, "nothing moved on a turning beat")
	# ...and now it paces back the other way, six hexes to the far leash edge.
	for i: int in range(6):
		advance(sim, 1)
		assert_eq(sentry.position, Vector2i(7 - i, 0), "pace step %d west" % (i + 1))
	advance(sim, 1)
	assert_eq(sentry.facing, 0, "the far edge turns it around again — a closed, repeating sweep")
	assert_eq(sentry.position, Vector2i(2, 0), "and that beat was a turn too")


func test_a_patrolling_cone_walks_into_a_standing_party_and_names_sight() -> void:
	# The headline of the ruling: "they move, and their eyelines move with
	# them" — and the case the RETIRED walk-driven beat got wrong. The party
	# issues NOT ONE movement command: it stands still and time does the rest.
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	add_mob(sim, "guard", [8, 0], 3, {"route": [[8, 0], [2, 0]]})  # Mind 3 -> sight 6
	assert_no_contact(sim, explore(sim), "8 hexes out is beyond sight (6) and hearing (3)")
	assert_no_contact(sim, advance(sim, 1), "time step one: the guard is still 7 out")
	assert_eq(sim.combatants["guard"].position, Vector2i(7, 0), "the guard took its beat")
	var events: Array[Dictionary] = advance(sim, 1)
	assert_eq(sim.combatants["guard"].position, Vector2i(6, 0), "the guard walked into range")
	assert_eq(sim.combatants["h1"].position, Vector2i(0, 0), "the party never moved a hex")
	var contact: Dictionary = assert_event(events, "contact", "the moving cone acquired the party")
	assert_eq(String(contact.get("sense", "")), "sight", "the sense is SIGHT — the cone, not a sound")
	assert_eq(String(contact.get("by", "")), "guard", "the patroller is the detector")
	assert_eq(String(contact.get("target", "")), "h1", "the contestant it found")
	assert_eq(String(assert_event(events, "combat_started", "clock starts").get("reason", "")),
		"contact", "involuntary entry")
	assert_eq(sim.phase, Exploration.PHASE_COMBAT, "the fight is on")
	# ...and the patrol stops the moment exploration does — combat is the AI's.
	var post: Vector2i = sim.combatants["guard"].position
	advance(sim, 3)
	assert_eq(sim.combatants["guard"].position, post, "no beat exists in combat")

	# THE CONTRAST: the identical board with NO patrol authored never contacts.
	var control: CombatSim = make_sim()
	add_contestant(control, "h1", [0, 0])
	add_mob(control, "guard", [8, 0], 3)
	explore(control)
	assert_no_contact(control, advance(control, 6), "a statue never finds you")
	assert_eq(control.combatants["guard"].position, Vector2i(8, 0), "…because it never moved")


func test_a_blocked_patrol_holds_and_a_downed_one_walks_no_beat() -> void:
	var sim: CombatSim = make_sim()
	# The route's next waypoint sits behind a wall pocket it cannot route to.
	open_arena(sim, {"walls": [[11, 0], [11, -1], [10, -1], [9, 0], [9, 1], [10, 1]]})
	add_contestant(sim, "h1", [0, 0])
	add_mob(sim, "walled", [10, 0], 0, {"route": [[10, 0], [20, 0]]})
	add_mob(sim, "dead", [30, 0], 0, true)
	explore(sim)
	sim.combatants["dead"].alive = false
	advance(sim, 2)
	assert_eq(sim.combatants["walled"].position, Vector2i(10, 0),
		"an unreachable waypoint HOLDS the post — it never thrashes to another goal")
	assert_eq(sim.combatants["dead"].position, Vector2i(30, 0), "a downed body walks no beat")
	assert_true(sim.combatants["h1"].patrol.is_empty(), "contestants carry no patrol")


func test_patrols_are_deterministic_and_draw_zero_rng() -> void:
	# TWIN-RNG STATE COMPARE: two identically-seeded sims, one of which runs a
	# whole patrolling exploration phase (walks, time steps, an about-face and
	# a real CONTACT) INSIDE ONE CLOCK, so no Clock-reset beat fires. Every
	# stream must be untouched — R35 authors no roll and none was invented.
	# (The Clock-reset draw the tick path DOES make out of combat is pinned
	# separately, honestly, in test_exploration_time_steps_run_the_real_tick_path.)
	var quiet := CombatSim.new(90210, SimTestBase.load_static_data())
	var busy := CombatSim.new(90210, SimTestBase.load_static_data())
	for sim: CombatSim in [quiet, busy]:
		_stage_patrol_scenario(sim)
	assert_eq(busy.rng.state, quiet.rng.state, "twins start level (action rng)")

	_run_patrol_scenario(busy)
	assert_true(busy.clock.tick < Clock.TICKS_PER_CLOCK, "the scenario stayed inside one Clock")
	assert_eq(busy.phase, Exploration.PHASE_COMBAT, "the phase really did end in contact")
	assert_eq(busy.rng.state, quiet.rng.state, "action RNG untouched by every patrol path")
	assert_eq(busy.ai.ai_rng.state, quiet.ai.ai_rng.state, "AI RNG untouched — patrols draw nothing")
	assert_eq(busy.hype.goal_rng.state, quiet.hype.goal_rng.state, "crowd-goal RNG untouched")

	# LOCKSTEP: the same seed + the same command log = the same hash.
	var replay := CombatSim.new(90210, SimTestBase.load_static_data())
	_stage_patrol_scenario(replay)
	_run_patrol_scenario(replay)
	assert_eq(replay.state_hash(), busy.state_hash(), "identical command logs replay identically")
	# ...and a mid-patrol save resumes the same walk.
	var mid := CombatSim.new(90210, SimTestBase.load_static_data())
	_stage_patrol_scenario(mid)
	explore(mid)
	advance(mid, 2)
	var restored: CombatSim = CombatSim.from_dict(mid.to_dict())
	assert_eq(restored.state_hash(), mid.state_hash(), "hash-identical round trip mid-patrol")
	advance(mid, 1)
	advance(restored, 1)
	assert_eq(restored.state_hash(), mid.state_hash(), "the restored sim patrols on identically")


func _stage_patrol_scenario(sim: CombatSim) -> void:
	open_arena(sim)
	add_contestant(sim, "h1", [0, 0])
	add_mob(sim, "pacer", [14, 0], 0, true)
	add_mob(sim, "router", [8, 0], 3, {"route": [[8, 0], [2, 0]]})


func _run_patrol_scenario(sim: CombatSim) -> void:
	explore(sim)
	sim.apply_command({"type": "move", "actor": "h1", "to": [0, 1]})
	sim.apply_command({"type": "advance_tick"})
	sim.apply_command({"type": "move", "actor": "h1", "to": [0, 0]})
	sim.apply_command({"type": "advance_tick"})


func test_exploration_time_steps_run_the_real_tick_path() -> void:
	# THE OWNER'S INSTRUCTION, made explicit: "reuse the one real tick path —
	# do not build a parallel clock." These are the consequences that follow,
	# pinned rather than discovered later. Nothing is suppressed.
	var sim: CombatSim = make_sim(4242)
	add_contestant(sim, "h1", [0, 0])
	# A burn on the torso: a wound that ADVANCES at the Clock boundary.
	sim.apply_command({"type": "apply_condition", "target": "h1", "part": "torso",
		"condition": "burn", "tier": 1})
	var goal_rng_before: int = sim.hype.goal_rng.state
	explore(sim)

	# Nine ticks: the clock really moves, one Moment at a time, and nothing
	# resolves (there is no schedule out of combat).
	var nine: Array[Dictionary] = advance(sim, 9)
	assert_eq(sim.clock.tick, 9, "nine exploration time steps, nine ticks (R1: ~4.5 seconds)")
	assert_event(nine, "clock_moment_changed", "each step reports its Moment")
	assert_no_event(nine, "clock_reset", "…and nine is not yet a Clock")
	assert_no_event(nine, "action_resolved", "nothing can be scheduled, so nothing resolves")
	assert_eq(sim.hype.goal_rng.state, goal_rng_before, "no Clock, no goal draw")

	# The tenth completes the Clock and the ORDINARY reset beat runs.
	var reset: Array[Dictionary] = advance(sim, 1)
	assert_event(reset, "clock_reset", "the tenth step completes a Clock (~5 fictional seconds)")
	assert_event(reset, "condition_advanced", "A WOUND BURNS WHILE YOU WALK — the ruled consequence")
	assert_event(reset, "hype_goal_offered", "the show stays on air: the crowd-goal director runs")
	assert_ne(sim.hype.goal_rng.state, goal_rng_before,
		"…which draws its usual ONE goal_rng draw per Clock — the same draw combat makes")
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "all of it while still exploring")

	# THE METER DECAYS between beats, measured on a QUIET board (the burn above
	# scores points of its own, which would mask it): "the crowd is bored by
	# safety" (R35) becomes literally true — an unspectacular stroll bleeds
	# meter exactly as an unspectacular Clock of combat does.
	var quiet: CombatSim = make_sim(4242)
	add_contestant(quiet, "h1", [0, 0])
	quiet.hype.meter = 60
	explore(quiet)
	advance(quiet, 10)
	assert_eq(quiet.hype.meter, 60 - HypeEngine.DECAY_PER_CLOCK,
		"one exploration Clock costs exactly the ordinary boredom decay (PLACEHOLDER R14)")
	# The free-action budget refresh is a live no-op out of combat: nothing
	# spends an entry, so nothing ever needs refunding.
	assert_eq(sim.combatants["h1"].free_actions_used, 0, "no budget entry was ever spent")
	# And the exploration clock is genuinely THE clock — combat resumes on it.
	assert_event(enter_combat(sim), "combat_started", "the party commits")
	assert_eq(sim.clock.tick, 10, "the fight starts on tick 10, not on a fresh clock")


func test_patrol_serializes_only_when_set() -> void:
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	add_mob(sim, "statue", [20, 0], 0)
	for row: Variant in (sim.to_dict().get("combatants", []) as Array):
		assert_false((row as Dictionary).has("patrol"),
			"no patrol key anywhere on a board nobody told to walk (the compat pin)")
	# A combat-only fight is still hash-identical to the recorded legacy hash.
	assert_eq(_legacy_plain_hash(), LEGACY_HASH_PLAIN,
		"a combat-only plain fight replays the pre-exploration hash — R35 changed nothing in combat")

	var patrolled: CombatSim = make_sim()
	open_arena(patrolled)
	add_contestant(patrolled, "h1", [0, 0])
	add_mob(patrolled, "guard", [10, 0], 0, {"route": [[10, 0], [10, 4]]})
	explore(patrolled)
	move(patrolled, "h1", [1, 0])
	var guard_row: Dictionary = {}
	for row: Variant in (patrolled.to_dict().get("combatants", []) as Array):
		if String((row as Dictionary).get("id", "")) == "guard":
			guard_row = row
	assert_true(guard_row.has("patrol"), "a patrolling body carries the record")
	assert_eq(int((guard_row["patrol"] as Dictionary).get("index", -1)), 1,
		"…including the live cursor (hash-covered)")
	var restored: CombatSim = CombatSim.from_dict(patrolled.to_dict())
	assert_eq(restored.state_hash(), patrolled.state_hash(), "hash-identical round trip")
	assert_eq(restored.combatants["guard"].patrol, patrolled.combatants["guard"].patrol, "record survives")
	# A legacy save with no patrol key resumes as the pre-R35 statue.
	var dict: Dictionary = patrolled.to_dict()
	for row: Variant in (dict.get("combatants", []) as Array):
		(row as Dictionary).erase("patrol")
	var legacy: CombatSim = CombatSim.from_dict(dict)
	assert_true(legacy.combatants["guard"].patrol.is_empty(), "no key = no patrol")
	move(legacy, "h1", [2, 0])
	assert_eq(legacy.combatants["guard"].position, patrolled.combatants["guard"].position,
		"…and it holds its hex forever")


## The exact pre-exploration combat sequence tests/test_exploration.gd pins —
## re-run here so R35's own file proves combat is untouched.
func _legacy_plain_hash() -> String:
	var sim: CombatSim = make_sim()
	add_human(sim, "h1", {"team": "party", "position": [1, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [5, 0]}})
	move(sim, "h1", [4, 0])
	sim.apply_command({"type": "ai_decide", "actor": "mob"})
	advance(sim, 1)
	declare(sim, "h1", attack_action("crushed", 3, "mob", "torso", {"attack_range": 6}))
	advance(sim, 1)
	sim.apply_command({"type": "ai_decide", "actor": "mob"})
	advance(sim, 2)
	assert_false(sim.to_dict().has("phase"), "no phase key in a combat-only dict")
	return sim.state_hash()


# ======================================================================
# R35 #3 — THE CROWD WATCHES EXPLORATION
# ======================================================================

func test_an_idle_walk_through_a_cleared_room_pays_nothing() -> void:
	# The ruling, verbatim: "Idle walking through a cleared room pays nothing —
	# the crowd is bored by safety, which is the whole point."
	var sim: CombatSim = make_sim()
	open_arena(sim)
	add_contestant(sim, "h1", [0, 0])
	add_contestant(sim, "h2", [3, 3])  # an ALLY is not danger
	explore(sim)
	for target: Array in [[6, 0], [12, 0], [12, 6], [0, 0]]:
		var moved: Dictionary = assert_event(move(sim, "h1", target), "moved", "an idle walk")
		assert_false(moved.has("spectacle_points"), "no points key at all on a safe walk")
		assert_false(moved.has("spectacle"), "and no breakdown either")
	assert_eq(sim.hype.meter, 0, "the meter never moved")
	assert_eq(sim.hype.ledger.get("h1", 0), 0, "and nothing was credited")
	# A DEAD hostile is a cleared room too — safety is safety.
	add_mob(sim, "corpse", [1, 0], 3)
	sim.combatants["corpse"].alive = false
	assert_false(assert_event(move(sim, "h1", [2, 0]), "moved", "walk past a corpse")
		.has("spectacle_points"), "a dead mob is not danger")


func test_the_three_ruled_spectacle_sources_and_their_magnitudes() -> void:
	# The pure query, exercised straight so each ruled source is isolated with
	# its authored magnitude visible in the call. Every number PLACEHOLDER
	# (R14) and named on its constant in simulation/exploration.gd.
	assert_eq(Exploration.SPECTACLE_DANGER_RADIUS, 6, "\"nearby\" is 6 hexes (PH)")
	assert_eq(Exploration.SPECTACLE_DANGER_STEP, 2, "2 points per hex inside the radius (PH)")
	assert_eq(Exploration.SPECTACLE_UNSEEN_BONUS, 4, "moving unseen with danger near (PH)")
	assert_eq(Exploration.SPECTACLE_IN_CONE_BONUS, 8, "the money shot (PH)")
	assert_eq(Exploration.SPECTACLE_BOSS_STEP, 6, "per hex closed on a large boss (PH)")

	# (a) DANGER ALONE — a mob that genuinely SEES the mover: no stealth bonus.
	var seen: CombatSim = make_sim()
	add_contestant(seen, "h1", [4, 0])
	add_mob(seen, "mob", [0, 0], 3)  # sight 6, staged facing the contestant
	assert_true(Stealth.sees(seen.combatants["mob"], seen.combatants["h1"], null, 0), "sanity: seen")
	var danger: Dictionary = Exploration.walk_spectacle(
		seen.combatants["h1"], seen.combatants, null, 0, Vector2i(5, 0), Vector2i(4, 0))
	assert_eq(int(danger.get("danger", -1)), 6, "d=4 inside radius 6: 2 x (6 + 1 - 4)")
	assert_eq(int(danger.get("stealth", -1)), 0, "you are being watched — that is not stealth")
	assert_eq(int(danger.get("boss", -1)), 0, "a Mob is not a large boss")
	assert_eq(int(danger.get("points", -1)), 6, "the total is the sum")
	# One hex past the radius pays nothing at all.
	assert_true(Exploration.walk_spectacle(seen.combatants["h1"], seen.combatants, null, 0,
		Vector2i(8, 0), Vector2i(7, 0)).is_empty(), "d=7 is past the radius: {} (no key at all)")

	# (b) GOOD STEALTH — unseen, danger nearby, but OUTSIDE the eyeline: the
	# base bonus only. The mob faces East with the contestant behind it.
	var behind: CombatSim = make_sim()
	add_mob(behind, "mob", [0, 0], 3)          # staged first -> faces East (0)
	add_contestant(behind, "h1", [-4, 0])      # rear arc, inside sight RANGE
	assert_false(Stealth.sees(behind.combatants["mob"], behind.combatants["h1"], null, 0),
		"sanity: an observer sees nothing over its shoulder (R30)")
	var creep: Dictionary = Exploration.walk_spectacle(
		behind.combatants["h1"], behind.combatants, null, 0, Vector2i(-5, 0), Vector2i(-4, 0))
	assert_eq(int(creep.get("danger", -1)), 6, "d=4: the same proximity ramp")
	assert_eq(int(creep.get("stealth", -1)), Exploration.SPECTACLE_UNSEEN_BONUS,
		"unseen with danger nearby — but no cone to be inside")

	# (c) THE MONEY SHOT — unseen INSIDE a live cone (concealment caps the
	# observer's reveal distance; the geometry still holds the contestant).
	var money: CombatSim = make_sim()
	add_contestant(money, "h1", [4, 0])
	add_mob(money, "mob", [0, 0], 3)           # staged facing the contestant
	money.combatants["h1"].conceal = {"radius": 1, "anchor": [4, 0], "mobile": true}
	assert_false(Stealth.sees(money.combatants["mob"], money.combatants["h1"], null, 0),
		"sanity: concealed at 4 hexes vs a reveal radius of 1 — unseen")
	assert_true(Stealth.front_arc_contains(Vector2i(0, 0), money.combatants["mob"].facing, Vector2i(4, 0)),
		"sanity: …but standing squarely in the cone")
	var shot: Dictionary = Exploration.walk_spectacle(
		money.combatants["h1"], money.combatants, null, 0, Vector2i(5, 0), Vector2i(4, 0))
	assert_eq(int(shot.get("stealth", -1)),
		Exploration.SPECTACLE_UNSEEN_BONUS + Exploration.SPECTACLE_IN_CONE_BONUS,
		"the cone bonus COMPOSES on top of the base — creeping through the eyeline is better television")

	# (d) APPROACHING A LARGE BOSS — per hex CLOSED, and nothing for backing off.
	var arena_boss: CombatSim = make_sim()
	add_contestant(arena_boss, "h1", [0, 0])
	add_boss(arena_boss, "colossus", [20, 0], 3)
	var closing: Dictionary = Exploration.walk_spectacle(
		arena_boss.combatants["h1"], arena_boss.combatants, null, 0, Vector2i(0, 0), Vector2i(3, 0))
	assert_eq(int(closing.get("boss", -1)), 18, "3 hexes closed x 6 (PH)")
	assert_eq(int(closing.get("danger", -1)), 0, "17 hexes out is not \"nearby\"")
	assert_eq(int(closing.get("stealth", -1)), 0, "…and with no danger nearby there is no stealth beat")
	var retreating: Dictionary = Exploration.walk_spectacle(
		arena_boss.combatants["h1"], arena_boss.combatants, null, 0, Vector2i(3, 0), Vector2i(0, 0))
	assert_true(retreating.is_empty(), "the crowd wants the approach, not the retreat")
	# A Huge non-Boss qualifies too (the size band).
	assert_true(Exploration._spectacle_is_large(arena_boss.combatants["colossus"]), "Boss category")
	var huge: CombatantState = arena_boss.combatants["h1"]
	assert_false(Exploration._spectacle_is_large(huge), "a Medium contestant is not a large boss")


func test_a_stealthed_approach_to_a_boss_warms_the_meter() -> void:
	# All three sources at once, through the REAL command path: the points ride
	# the walk's own `moved` event as the generic spectacle_points field and
	# land in the ordinary meter — no new hype plumbing exists.
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [5, 0])
	add_boss(sim, "colossus", [12, 0], 3)  # Boss + Huge, sight 6, facing the party
	sim.apply_command({"type": "stealth", "actor": "h1"})
	sim.combatants["h1"].conceal = {"radius": 1, "anchor": [5, 0], "mobile": true}
	explore(sim)
	assert_eq(sim.hype.meter, 0, "the meter opens cold")

	var events: Array[Dictionary] = move(sim, "h1", [6, 0])
	var moved: Dictionary = assert_event(events, "moved", "one creeping hex closer")
	assert_true(sim.combatants["h1"].stealthed, "the mobile conceal survives a slow step (S8-a)")
	assert_eq(int(moved.get("spectacle_points", -1)), 20, "danger 2 + stealth 12 + boss 6")
	var breakdown: Dictionary = moved.get("spectacle", {})
	assert_eq(int(breakdown.get("danger", -1)), 2, "d=6 sits on the radius edge: 2 x (6 + 1 - 6)")
	assert_eq(int(breakdown.get("stealth", -1)), 12, "unseen (4) INSIDE the boss's cone (8)")
	assert_eq(int(breakdown.get("boss", -1)), 6, "one hex closed on a Huge/Boss x 6")
	assert_eq(sim.hype.meter, 20, "…and it landed in the ordinary meter")
	assert_eq(int(sim.hype.ledger.get("h1", 0)), 20, "credited to the contestant who took the risk")
	assert_no_contact(sim, events, "…all without being seen or heard")
	# The scenery is never scored: a patrolling mob's own step pays nobody.
	assert_no_event(events, "hype_goal_completed", "no goal was involved")


func test_exploration_hype_arrives_at_the_fight_and_rides_the_R29_chain() -> void:
	# "This composes with R29: exploration hype feeds the same meter the chain
	# carries forward, so a tense approach can arrive at the fight already warm."
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	add_boss(sim, "colossus", [20, 0], 0)  # Mind 0: it never sees the approach
	explore(sim)
	for target: Array in [[4, 0], [8, 0], [11, 0]]:
		assert_true(assert_event(move(sim, "h1", target), "moved", "closing on the boss")
			.has("spectacle_points"), "each approach beat scores")
	var warm: int = sim.hype.meter
	assert_true(warm > 0, "the approach warmed the meter (got %d)" % warm)
	# THE ARRIVAL: the deliberate entry does not reset a thing.
	assert_event(enter_combat(sim), "combat_started", "the party commits")
	assert_eq(sim.hype.meter, warm, "the fight OPENS on the exploration meter — already warm")
	assert_eq(sim.phase, Exploration.PHASE_COMBAT, "and the clock is running")

	# THE R29 CHAIN: the warm meter is what end_encounter records, and the
	# retention ladder carries it into the next room exactly as before.
	var run := RunState.new()
	run.apply_command({"type": "start_run", "seed": 9,
		"party": [{"id": "h1", "name": "h1"}],
		"encounters": [{"key": "a", "kind": "combat"}, {"key": "b", "kind": "combat"}]})
	run.apply_command({"type": "begin_encounter"})
	run.apply_command({"type": "end_encounter", "outcome": "WIN",
		"carried": {"h1": {"alive": true}}, "hype_meter": warm})
	var carried: int = run.chain_hype_start()
	assert_true(carried > 0, "exploration hype really does survive the encounter boundary")
	assert_eq(carried, int(floor(warm * 0.4)),
		"the #32 retention ladder is untouched — link 2 opens at 40%% of a meter exploration helped fill")
	var started: Array[Dictionary] = run.apply_command({"type": "begin_encounter"})
	assert_eq(int(assert_event(started, "run_encounter_started", "link 2 starts").get("hype_start", -1)),
		carried, "the next room opens warm because of a walk in the last one")
