extends SimTestBase
## R34 — FREE-FORM EXPLORATION & CONTACT DETECTION (owner rulings 2026-08-19;
## contract in docs/rules-addendum.md R34 + the R29 amendment; model in
## simulation/exploration.gd).
##
## Under test:
##  * the LEGACY BYTE-COMPAT PIN (the bar): the two recorded stealth-free
##    fights test_stealth.gd / test_hearing.gd pin replay to the SAME hashes —
##    a combat-only sim never grows the `phase` key and never reaches a single
##    exploration code path.
##  * FREE-FORM ECONOMY: while exploring, move / door / stealth advance no
##    tick, schedule nothing, and charge neither the R3 free-action slot nor
##    Moments — three doors and two hides in one phase, then the CONTRAST pin
##    that the same second door flip rejects free_action_used back in combat.
##  * THE NO-TURN-ORDER REJECT FAMILY: declare_action / combined_action /
##    reaction / ai_decide / camera_call / bit all reject `clock_stopped` and
##    mutate nothing. **R35 also took `inventory` out of this family** (the
##    owner's item-use addition) — pinned in test_exploration_layer.gd. **R35 revision (owner, 2026-08-19 —
##    "time should just be moving"): advance_tick LEFT this family.** Time
##    flows during exploration; what is gone out of combat is the Moment
##    ORDER, not the clock. The exploration-side time step, the patrol beat it
##    drives and the tick-sweep consequences are pinned in
##    tests/test_exploration_layer.gd.
##  * CONTACT — SIGHT: a contestant walking into a mob's cone starts the fight,
##    `contact` names sense "sight" and the detector; the R30 rear arc is the
##    contrast (same distance, same Mind, facing away = no contact).
##  * CONTACT — HEARING: a door flipped through a WALL, out of the mob's sight
##    range entirely, still pulls the room (sense "hearing"); the R20 loudness
##    table is the only number involved.
##  * CONCEALMENT (R20/S8): a concealed contestant inside the cone at 3 hexes
##    is NOT seen (the conceal radius caps the reveal distance) but IS heard
##    when it creeps — the ruled "concealment genuinely delays the fight".
##  * DELIBERATE ENTRY: the phase command's combat side starts the fight with
##    NO contact event, and the clock runs again immediately after.
##  * SERIALIZATION: `phase` only-when-set, round-trip mid-exploration,
##    determinism/lockstep, and ZERO rng out of every exploration path.
##  * WALK LEGALITY: bounds / walls / closed doors / trash cans / occupied
##    hexes / an unreachable pocket all reject, and the walk faces its last
##    step (R30).

## The recorded pre-stealth legacy hashes — SHARED TRUTH with
## tests/test_stealth.gd and tests/test_hearing.gd (same constants, same
## sequences; re-pin all three files together via test_stealth's documented
## re-record procedure).
const LEGACY_HASH_PLAIN: String = "6d8046456d4aee1059e775d8d08f6eee2519c511f2e36df4b5c8ee25ca9b6a70"
const LEGACY_HASH_ARENA_DOOR: String = "f6f64238efd4596bcba526c5a32d60583d6c5d7c55e599aa328b2f41658680d5"


# ---------------------------------------------------------------- helpers

func explore(sim: CombatSim) -> Array[Dictionary]:
	return sim.apply_command({"type": "phase", "set": "exploration"})


func enter_combat(sim: CombatSim) -> Array[Dictionary]:
	return sim.apply_command({"type": "phase", "set": "combat"})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func door(sim: CombatSim, actor: String, key: String, to_state: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "door", "actor": actor, "key": key, "set": to_state})


func stealth(sim: CombatSim, actor: String, to_state: String = "hide") -> Array[Dictionary]:
	return sim.apply_command({"type": "stealth", "actor": actor, "set": to_state})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## An AI-controlled mob with an explicit Mind (R20 sight = 2 x Mind), so every
## detection number in this file is visible in the call.
func add_mob(sim: CombatSim, id: String, pos: Array, mind: int = 3) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "category": "Mob", "team": "enemies", "position": pos,
		"traits": {"physique": 2, "reflexes": 2, "mind": mind, "charm": 1}}})


func add_contestant(sim: CombatSim, id: String, pos: Array) -> Array[Dictionary]:
	return add_human(sim, id, {"team": "party", "position": pos})


func assert_no_contact(sim: CombatSim, events: Array[Dictionary], message: String) -> void:
	assert_no_event(events, "contact", message)
	assert_no_event(events, "combat_started", message)
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "still exploring: " + message)


# ------------------------------------------------------------- legacy compat

func test_legacy_combat_only_fights_are_hash_identical() -> void:
	# Sequence A (plain, no arena) — the exact pre-exploration engine hash.
	var sim: CombatSim = make_sim()
	add_human(sim, "h1", {"team": "party", "position": [1, 0]})
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [5, 0]}})
	move(sim, "h1", [4, 0])
	ai_decide(sim, "mob")
	advance(sim, 1)
	declare(sim, "h1", attack_action("crushed", 3, "mob", "torso", {"attack_range": 6}))
	advance(sim, 1)
	ai_decide(sim, "mob")
	advance(sim, 2)
	assert_eq(sim.state_hash(), LEGACY_HASH_PLAIN,
		"a combat-only plain fight replays the pre-exploration hash")
	assert_eq(sim.phase, Exploration.PHASE_COMBAT, "phase defaults to combat")
	var dict: Dictionary = sim.to_dict()
	assert_false(dict.has("phase"), "no phase key in a combat-only dict (the compat pin)")

	# Sequence B (arena + wall + door flip) — the arena/door path too. The door
	# flip here still costs the R3 free-action slot: the free-form waiver is
	# exploration-only.
	var sim2 := CombatSim.new(77, SimTestBase.load_static_data())
	sim2.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21},
		"walls": [[3, 0]],
		"doors": [{"key": "d", "position": [2, 0], "state": "closed"}]}})
	add_human(sim2, "h1", {"team": "party", "position": [1, 0]})
	sim2.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [5, 5]}})
	door(sim2, "h1", "d", "open")
	advance(sim2, 1)
	move(sim2, "h1", [2, 0])
	ai_decide(sim2, "mob")
	advance(sim2, 1)
	assert_eq(sim2.state_hash(), LEGACY_HASH_ARENA_DOOR,
		"a combat-only arena/door fight replays the pre-exploration hash")
	assert_false(sim2.to_dict().has("phase"), "no phase key on the arena sim either")


# ------------------------------------------------------- the free-form economy

func test_exploration_commands_advance_no_tick_and_charge_no_moments() -> void:
	# No enemies at all: nothing can make contact, so the economy is the only
	# thing under test here.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21},
		"doors": [{"key": "d", "position": [2, 0], "state": "closed"}]}})
	add_contestant(sim, "h1", [1, 0])
	assert_event(explore(sim), "exploration_started", "the clock stops")
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "phase flipped")
	var h1: CombatantState = sim.combatants["h1"]
	var ready_at: int = h1.next_action_tick

	# THREE door flips in one phase — in combat the second would reject
	# free_action_used (one free action per tick, and no tick ever completes
	# while the clock is stopped).
	assert_event(door(sim, "h1", "d", "open"), "door_changed", "first flip free")
	assert_event(door(sim, "h1", "d", "closed"), "door_changed", "second flip free")
	assert_event(door(sim, "h1", "d", "open"), "door_changed", "third flip free")
	assert_false(h1.free_action_used, "no free-action slot charged by a door out of combat")

	# Hide / reveal / hide — the ruled "scouting" free action, uncapped.
	assert_event(stealth(sim, "h1"), "stealth_entered", "hide is free")
	assert_event(stealth(sim, "h1", "reveal"), "stealth_broken", "reveal")
	assert_event(stealth(sim, "h1"), "stealth_entered", "second hide free too")
	stealth(sim, "h1", "reveal")
	assert_false(h1.free_action_used, "no free-action slot charged by a hide out of combat")

	# Free-form movement: any number of walks, no allowance, no slot, no
	# scheduling, no tick.
	for target: Array in [[4, 0], [8, 0], [8, 4], [1, 0]]:
		var moved: Dictionary = assert_event(move(sim, "h1", target), "moved", "free-form walk")
		assert_true(bool(moved.get("exploration", false)), "the walk is flagged exploration")
		assert_true(bool(moved.get("free", false)), "the walk is free")
	assert_false(h1.moved_this_tick, "moved_this_tick is never set out of combat")
	assert_false(h1.free_action_used, "no free-action slot charged by a walk")
	assert_eq(h1.next_action_tick, ready_at, "no Moments charged (next_action_tick untouched)")
	assert_eq(sim.clock.tick, 0, "no tick ever advanced")
	assert_true(sim.clock.queue.is_empty(), "nothing was scheduled on the stopped clock")

	# CONTRAST: back in combat the free-action BUDGET starts being charged again.
	# The owner ruled two per window (R34, amending R3's one), so it is the THIRD
	# flip that rejects — the point of the contrast is that exploration charges
	# nothing at all while combat charges every one.
	assert_event(enter_combat(sim), "combat_started", "deliberate entry")
	assert_eq(sim.combatants["h1"].free_actions_used, 0, "budget is untouched by everything above")
	assert_event(door(sim, "h1", "d", "closed"), "door_changed", "first combat flip spends budget")
	assert_eq(sim.combatants["h1"].free_actions_used, 1, "R3 economy resumes the moment the clock runs")
	assert_event(door(sim, "h1", "d", "open"), "door_changed", "second flip spends the rest of it")
	assert_true(sim.combatants["h1"].free_action_used, "budget exhausted at two (R34)")
	assert_rejected(door(sim, "h1", "d", "closed"), "free_action_used",
		"two free actions per window, then no more (R34 amending R3)")


func test_clock_bound_commands_are_rejected_while_exploring() -> void:
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	add_mob(sim, "mob", [30, 0])  # far out of every sense
	explore(sim)
	# R35 revision: advance_tick is no longer in this family — it IS the
	# exploration time step now, so it is asserted ACCEPTED before the hash
	# baseline is taken (test_exploration_layer.gd owns its full contract).
	assert_no_event(sim.apply_command({"type": "advance_tick"}), "command_rejected",
		"time flows out of combat (R35): the time step is legal")
	assert_eq(sim.clock.tick, 1, "…and it really advanced the one real clock")
	var before: String = sim.state_hash()
	assert_rejected(declare(sim, "h1", attack_action("crushed", 3, "mob", "torso")),
		"clock_stopped", "no Moment order to declare into")
	assert_rejected(sim.apply_command({"type": "combined_action", "members": []}),
		"clock_stopped", "combined actions are scheduled")
	assert_rejected(sim.apply_command({"type": "reaction", "actor": "h1", "cost": 0}),
		"clock_stopped", "reactions ride the clock")
	assert_rejected(ai_decide(sim, "mob"), "clock_stopped", "no enemy turn out of combat")
	# R35 inventory addition: `inventory` LEFT this family too (owner
	# 2026-08-19 — item use out of combat is how a party heals between rooms).
	# Its full contract lives in tests/test_exploration_layer.gd.
	assert_no_event(sim.apply_command({"type": "inventory", "actor": "h1", "interaction": "swap"}),
		"command_rejected", "inventory works out of combat (R35)")
	assert_rejected(sim.apply_command({"type": "camera_call", "actor": "h1", "target": "mob"}),
		"clock_stopped", "camera call spends the free slot")
	assert_rejected(sim.apply_command({"type": "bit", "actor": "h1"}),
		"clock_stopped", "the bit spends the free slot")
	assert_eq(sim.clock.tick, 1, "no MOMENT-ORDER command moved the clock")
	assert_eq(sim.state_hash(), before, "every rejection mutated nothing")
	assert_eq(sim.phase, Exploration.PHASE_EXPLORATION, "and none of them started the fight")


# --------------------------------------------------------------- contact: sight

func test_walking_into_a_cone_starts_combat_and_names_sight() -> void:
	var sim: CombatSim = make_sim()
	# The contestant is staged EAST of the mob, so the mob's R30 staging
	# facing points straight at it (nearest opponent) — a live cone.
	add_contestant(sim, "h1", [12, 0])
	add_mob(sim, "mob", [0, 0], 3)  # Mind 3 -> R20 sight range 6
	assert_no_contact(sim, explore(sim), "12 hexes out is beyond sight (6) and hearing (3)")
	assert_no_contact(sim, move(sim, "h1", [9, 0]), "9 hexes: still unseen, still unheard")
	assert_no_contact(sim, move(sim, "h1", [7, 0]), "7 hexes: one hex outside the cone's reach")
	var events: Array[Dictionary] = move(sim, "h1", [6, 0])
	var contact: Dictionary = assert_event(events, "contact", "the cone lands at exactly 2 x Mind")
	assert_eq(String(contact.get("sense", "")), "sight", "the sense is named")
	assert_eq(String(contact.get("by", "")), "mob", "the detector is named")
	assert_eq(String(contact.get("target", "")), "h1", "the detected contestant is named")
	assert_eq(String(assert_event(events, "combat_started", "the clock starts").get("reason", "")),
		"contact", "combat started BY CONTACT, not by a deliberate entry")
	assert_eq(sim.phase, Exploration.PHASE_COMBAT, "the fight is on")
	assert_eq(sim.clock.tick, 0, "contact itself advanced no tick — the driver owns the first one")
	# ...and the R3 economy is live again from this very command onward.
	assert_no_event(sim.apply_command({"type": "advance_tick"}), "command_rejected",
		"the clock runs the moment contact lands")
	assert_eq(sim.clock.tick, 1, "the driver's first tick is accepted")


func test_an_enemy_facing_away_does_not_see_R30() -> void:
	# The mob is staged FIRST (no opponents yet -> the documented default
	# facing 0 = East) and the contestant walks up behind it from the West.
	var sim: CombatSim = make_sim()
	add_mob(sim, "mob", [0, 0], 3)  # sight 6
	add_contestant(sim, "h1", [-5, 0])  # rear arc, distance 5 (INSIDE sight range)
	assert_eq(sim.combatants["mob"].facing, 0, "staging default faces East with no opponent yet")
	assert_true(Stealth.front_arc_contains(Vector2i(0, 0), 0, Vector2i(5, 0)),
		"sanity: East IS the front arc")
	assert_false(Stealth.front_arc_contains(Vector2i(0, 0), 0, Vector2i(-5, 0)),
		"sanity: West is the REAR arc")
	assert_no_contact(sim, explore(sim), "inside sight RANGE but behind the shoulder")
	# A creep at distance 4 is still rear-arc and still beyond QUIET (3).
	assert_no_contact(sim, move(sim, "h1", [-4, 0]), "creeping up behind stays uncontacted")

	# CONTRAST: identical distance and Mind, the mob simply faces the other
	# way (staged second, so it faces its nearest opponent).
	var sim2: CombatSim = make_sim()
	add_contestant(sim2, "h1", [-5, 0])
	add_mob(sim2, "mob", [0, 0], 3)
	assert_eq(sim2.combatants["mob"].facing, 3, "staged facing the contestant (West)")
	var contact: Dictionary = assert_event(explore(sim2), "contact",
		"the same body at the same range IS seen from the front")
	assert_eq(String(contact.get("sense", "")), "sight", "sense")
	assert_eq(sim2.phase, Exploration.PHASE_COMBAT, "contact on the very command that stops the clock")


# ------------------------------------------------------------- contact: hearing

func test_a_door_heard_through_a_wall_pulls_the_room() -> void:
	# R34 verbatim: "a door heard through a wall can pull a room onto you
	# before you enter it". The mob is Mind 1 (sight 2), so the contestant at
	# 5 hexes can NEVER be seen — only the door's MODERATE (6) noise reaches.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21},
		"walls": [[6, 0], [6, 1], [6, 3], [6, 4]],
		"doors": [{"key": "hatch", "position": [6, 2], "state": "closed"}]}})
	add_contestant(sim, "h1", [5, 2])
	add_mob(sim, "mob", [10, 2], 1)  # sight 2; distance to h1 = 5
	assert_false(Stealth.sees(sim.combatants["mob"], sim.combatants["h1"], sim.arena, 0),
		"sanity: a Mind-1 mob cannot see 5 hexes, wall or no wall")
	assert_no_contact(sim, explore(sim), "nothing has happened yet")
	assert_no_contact(sim, move(sim, "h1", [5, 1]), "a QUIET(3) footfall at 5 hexes is unheard")
	move(sim, "h1", [5, 2])
	var events: Array[Dictionary] = door(sim, "h1", "hatch", "open")
	assert_event(events, "door_changed", "the hatch swings")
	var contact: Dictionary = assert_event(events, "contact", "MODERATE(6) at 4 hexes lands")
	assert_eq(String(contact.get("sense", "")), "hearing", "the sense is named HEARING")
	assert_eq(String(contact.get("by", "")), "mob", "the detector is named")
	assert_eq(String(contact.get("target", "")), "h1", "the noise's maker is the contact target")
	assert_eq(String(assert_event(events, "combat_started", "clock starts").get("reason", "")),
		"contact", "involuntary entry")
	assert_eq(sim.phase, Exploration.PHASE_COMBAT, "the room came to you")


func test_concealment_delays_sight_but_never_hearing() -> void:
	# R20/S8: the conceal radius CAPS the observer's reveal distance against
	# that target — the contestant sits 3 hexes inside a live cone unseen.
	# Creeping (the S8-a mobile conceal, 1 hex) keeps the concealment and
	# still makes a QUIET(3) footfall — which is exactly what is heard.
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [3, 0])
	add_mob(sim, "mob", [0, 0], 3)  # sight 6, facing the contestant
	var h1: CombatantState = sim.combatants["h1"]
	h1.conceal = {"radius": 1, "anchor": [3, 0], "mobile": true}
	assert_event(stealth(sim, "h1"), "stealth_entered",
		"the conceal cap makes the hide legal inside the cone")
	assert_false(Stealth.sees(sim.combatants["mob"], h1, sim.arena, 0),
		"concealed at 3 hexes vs. a reveal radius of 1: unseen")
	assert_no_contact(sim, explore(sim), "concealment genuinely delays the fight")
	# One hex sideways, still exactly 3 hexes from the mob: unseen, but heard.
	var events: Array[Dictionary] = move(sim, "h1", [3, -1])
	assert_true(sim.combatants["h1"].stealthed, "the mobile conceal survives the creep (S8-a)")
	assert_false(Stealth.sees(sim.combatants["mob"], sim.combatants["h1"], sim.arena, 0),
		"still not SEEN after the creep")
	var contact: Dictionary = assert_event(events, "contact", "the footfall is heard")
	assert_eq(String(contact.get("sense", "")), "hearing",
		"concealment hides you from EYES only — the second sense still lands")
	assert_eq(String(contact.get("target", "")), "h1", "target")


# ------------------------------------------------------------ deliberate entry

func test_deliberate_entry_starts_combat_without_a_contact_event() -> void:
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [12, 0])
	add_mob(sim, "mob", [0, 0], 3)
	explore(sim)
	var events: Array[Dictionary] = enter_combat(sim)
	assert_no_event(events, "contact", "walking in on purpose is not being caught")
	assert_eq(String(assert_event(events, "combat_started", "the fight starts").get("reason", "")),
		"deliberate", "the reason separates the ENTER commit from contact")
	assert_eq(sim.phase, Exploration.PHASE_COMBAT, "phase flipped")
	# The clock runs again immediately.
	assert_no_event(sim.apply_command({"type": "advance_tick"}), "command_rejected",
		"advance_tick is legal again")
	assert_eq(sim.clock.tick, 1, "the clock is running")
	assert_rejected(enter_combat(sim), "already_in_phase", "no double entry")
	assert_rejected(sim.apply_command({"type": "phase", "set": "sideways"}),
		"unknown_phase", "only the two phases exist")


func test_exploration_is_rejected_mid_swing() -> void:
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	# A real templated enemy — this one is a WINDUP target, so it needs parts.
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [20, 0]}})
	assert_no_event(declare(sim, "h1", attack_action("crushed", 3, "mob", "carapace",
		{"cost": 3, "attack_range": 30})), "command_rejected", "a 3-Moment windup is declared")
	assert_false(sim.clock.queue.is_empty(), "a windup is queued")
	assert_rejected(explore(sim), "combat_in_progress",
		"you cannot stop the clock mid-swing (the swing could never resolve)")
	assert_eq(sim.phase, Exploration.PHASE_COMBAT, "phase untouched by the rejection")


# ----------------------------------------------------------------- walk legality

func test_the_free_form_walk_is_still_legal_movement() -> void:
	var sim: CombatSim = make_sim()
	# A pocket at [5, 5] fully ringed by walls — in bounds, not a wall, and
	# completely unreachable on foot.
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21},
		"walls": [[6, 5], [6, 4], [5, 4], [4, 5], [4, 6], [5, 6], [1, 1]],
		"objects": [{"key": "can", "position": [2, 0]}],
		"doors": [{"key": "d", "position": [0, 3], "state": "closed"}]}})
	add_contestant(sim, "h1", [0, 0])
	add_contestant(sim, "h2", [3, 0])
	explore(sim)
	assert_rejected(move(sim, "h1", [0, 0]), "no_move", "a walk to your own hex is not a walk")
	assert_rejected(move(sim, "h1", [99, 99]), "out_of_bounds", "the void is not a destination")
	assert_rejected(move(sim, "h1", [1, 1]), "hex_blocked", "walls still block")
	assert_rejected(move(sim, "h1", [2, 0]), "hex_blocked", "trash cans still block")
	assert_rejected(move(sim, "h1", [0, 3]), "hex_blocked", "a CLOSED door still blocks")
	assert_rejected(move(sim, "h1", [3, 0]), "hex_blocked", "a living body's hex is not a destination")
	assert_rejected(move(sim, "h1", [5, 5]), "unreachable",
		"free-form is not teleportation — a walled pocket stays walled")
	assert_rejected(move(sim, "ghost", [1, 0]), "unknown_actor", "unknown actor")
	# A legal long walk lands exactly, and faces its LAST STEP (R30).
	var moved: Dictionary = assert_event(move(sim, "h1", [0, 6]), "moved", "a long free walk")
	assert_eq(sim.combatants["h1"].position, Vector2i(0, 6), "landed on the asked hex")
	assert_true(int(moved.get("spaces", 0)) >= 6, "spaces counts the STEPS actually walked")
	assert_eq(sim.clock.tick, 0, "still no tick")


# --------------------------------------------------- serialization / determinism

func test_phase_round_trips_only_when_set() -> void:
	var sim: CombatSim = make_sim()
	add_contestant(sim, "h1", [0, 0])
	assert_false(sim.to_dict().has("phase"), "combat sims never carry the key")
	explore(sim)
	move(sim, "h1", [3, 0])
	var dict: Dictionary = sim.to_dict()
	assert_true(dict.has("phase"), "an exploring sim carries it")
	assert_eq(String(dict["phase"]), "exploration", "value")
	var restored: CombatSim = CombatSim.from_dict(dict)
	assert_eq(restored.phase, Exploration.PHASE_EXPLORATION, "phase survives the round trip")
	assert_eq(restored.state_hash(), sim.state_hash(), "hash-identical round trip")
	# The restored sim is still exploring — the economy comes back with it.
	assert_rejected(restored.apply_command({"type": "declare_action", "actor": "h1",
		"action": {"kind": "wait", "cost": 1}}), "clock_stopped",
		"a resumed exploration is still an exploration (no Moment order)")
	assert_event(restored.apply_command({"type": "move", "actor": "h1", "to": [4, 0]}),
		"moved", "and the free-form walk still works")
	# A pre-exploration save (no key) resumes in combat.
	dict.erase("phase")
	assert_eq(CombatSim.from_dict(dict).phase, Exploration.PHASE_COMBAT,
		"a legacy save with no phase key resumes in combat")


func test_exploration_draws_zero_rng_and_replays_in_lockstep() -> void:
	# TWIN-RNG STATE COMPARE: two identically-seeded sims, one of which runs a
	# whole exploration phase (a door, a hide, walks, and a real CONTACT).
	# Every stream must be untouched — neither R20 sense authors a roll.
	var quiet := CombatSim.new(31337, SimTestBase.load_static_data())
	var busy := CombatSim.new(31337, SimTestBase.load_static_data())
	for sim: CombatSim in [quiet, busy]:
		_stage_rng_scenario(sim)
	assert_eq(busy.rng.state, quiet.rng.state, "twins start level (action rng)")

	_run_rng_scenario(busy)
	assert_eq(busy.phase, Exploration.PHASE_COMBAT, "the phase really did end in contact")
	assert_eq(busy.rng.state, quiet.rng.state, "action RNG untouched by every exploration path")
	assert_eq(busy.ai.ai_rng.state, quiet.ai.ai_rng.state, "AI RNG untouched")
	assert_eq(busy.hype.goal_rng.state, quiet.hype.goal_rng.state, "crowd-goal RNG untouched")

	# LOCKSTEP: the same seed + the same command log = the same hash.
	var replay := CombatSim.new(31337, SimTestBase.load_static_data())
	_stage_rng_scenario(replay)
	_run_rng_scenario(replay)
	assert_eq(replay.state_hash(), busy.state_hash(), "identical command logs replay identically")


## Staging half of the twin-RNG scenario. The mob is Mind 1 (R20 sight 2), so
## nothing in the phase below can be SEEN from range — the contact at the end
## is earned by the loudness table alone.
func _stage_rng_scenario(sim: CombatSim) -> void:
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21},
		"doors": [{"key": "d", "position": [2, 0], "state": "closed"}]}})
	add_contestant(sim, "h1", [1, 0])
	add_mob(sim, "mob", [1, 9], 1)


func _run_rng_scenario(sim: CombatSim) -> void:
	explore(sim)
	door(sim, "h1", "d", "open")      # MODERATE(6) at 9 hexes: unheard
	stealth(sim, "h1")
	stealth(sim, "h1", "reveal")
	move(sim, "h1", [1, 5])            # QUIET(3) at 4 hexes: unheard
	move(sim, "h1", [1, 7])            # QUIET(3) at 2 hexes: CONTACT


func test_contact_predicate_is_pure_and_direction_ruled() -> void:
	# The pure query, exercised straight (no sim mutation): a contestant that
	# SEES a mob does NOT make contact — R34's examples are all
	# enemy-detects-contestant, and that reading is load-bearing for stealth.
	var sim: CombatSim = make_sim()
	add_mob(sim, "mob", [0, 0], 0)  # Mind 0 -> blind (the roach_dog precedent)
	add_contestant(sim, "h1", [1, 0])  # Mind 3 -> the CONTESTANT can see the mob
	assert_true(Stealth.sees(sim.combatants["h1"], sim.combatants["mob"], null, 0),
		"sanity: the contestant sees the mob at 1 hex")
	assert_false(Stealth.sees(sim.combatants["mob"], sim.combatants["h1"], null, 0),
		"sanity: a Mind-0 mob sees nothing, even adjacent")
	var empty: Array[Dictionary] = []
	assert_true(Exploration.first_contact(sim.combatants, null, 0, empty).is_empty(),
		"a contestant seeing a mob is NOT contact (the ruled direction)")
	assert_no_contact(sim, explore(sim), "and the sim agrees")
	# A blind mob still HEARS: the same body, one loud row away from a fight.
	var noises: Array[Dictionary] = [
		{"source": "h1", "position": Vector2i(4, 0), "loudness": Stealth.NOISE_MODERATE}]
	var heard: Dictionary = Exploration.first_contact(sim.combatants, null, 0, noises)
	assert_eq(String(heard.get("sense", "")), "hearing", "MODERATE(6) at 4 hexes is heard")
	assert_eq(String(heard.get("by", "")), "mob", "detector")
	# Out of earshot: MODERATE(6) is exactly 6 hexes, 7 is silence.
	var far: Array[Dictionary] = [
		{"source": "h1", "position": Vector2i(7, 0), "loudness": Stealth.NOISE_MODERATE}]
	assert_true(Exploration.first_contact(sim.combatants, null, 0, far).is_empty(),
		"one hex past the loudness is silence (boundary inclusive)")
	# An ALLY's noise alarms nobody, and a DOWNED mob neither watches nor listens.
	var friendly: Array[Dictionary] = [
		{"source": "mob", "position": Vector2i(1, 0), "loudness": Stealth.NOISE_LOUD}]
	assert_true(Exploration.first_contact(sim.combatants, null, 0, friendly).is_empty(),
		"a mob hearing its own side is not contact")
	sim.combatants["mob"].alive = false
	assert_true(Exploration.first_contact(sim.combatants, null, 0, noises).is_empty(),
		"a dead mob makes no contact")
