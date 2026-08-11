extends SimTestBase
## KAN-5 wave 4c — STEALTH, DETECTION & COVER (rules-addendum R20, v1 binary
## sight/hearing — the slice R20's own phasing note authorizes).
##
## Under test:
##  * the LEGACY BYTE-COMPAT PIN: two stealth-free fights (plain + arena/door)
##    replay to the EXACT state hashes recorded on the pre-stealth engine
##    (e6c7c37) — opt-in stealth changes nothing it does not touch.
##  * the `stealth` command: hide/reveal, every rejection (unknown actor /
##    dead / helpless / unknown state / already_stealthed / not_stealthed /
##    in_grapple / in_enemy_sight with the observer named / free_action_used),
##    the R3 free-action slot cost (reveal is free).
##  * R20's exact sight numbers: seen iff hostile distance <= 2 x Mind with
##    LOS — the 2x boundary pinned both sides; Mind 0 sees nothing even
##    adjacent (the roach_dog); allies never break stealth; a helpless
##    (fainted) observer keeps no watch.
##  * cover/LOS through the one R29 query: a wall blocks sight; a CLOSED door
##    blocks, an OPEN one does not — and opening the door mid-fight REVEALS
##    the hider on the very command (the sweep runs in _post).
##  * breaks: seen (either side moving into range), the Shock-T1 Shout (R13
##    noise seed — via a real burn T1), downed, revealed_self; and the
##    negative: damage WITHOUT shock (crushed T1) breaks nothing.
##  * AI honesty: a stealthed target vanishes from _opponents (targeting +
##    the R23 draw — zero ai_rng consumed on the survivor/single pick); all
##    hidden -> the mob WAITS ("no_targets" — it honestly loses the target,
##    no search behavior, downscoped with hearing); honest re-acquisition on
##    reveal.
##  * hostile-surface gates: declare (attack + skill + grapple) and reactions
##    reject target_stealthed (nothing mutated); friendly fire on a stealthed
##    TEAMMATE stays legal (Q69 — the party coordinates with its scout); an
##    aimed windup whose target hides mid-windup COLLAPSES (R2), while an
##    instant never re-checks (R2: instants cannot be dodged) and a committed
##    CONE arc still burns the hidden BODY (physicality over information) —
##    whose burn shock then shouts the hider out (the ruled noise path).
##  * views/preview additively: view_combatants().stealthed; the preview row's
##    target_stealthed flag (present only for a stealthed hostile).
##  * serialization: "stealthed" key ONLY while true (combatant dict + tick
##    snapshot), round-trip mid-stealth, lockstep tails, full-fight
##    determinism, zero rng from any stealth path (R20 authors no roll).
##  * RunState carry: stealth never crosses the encounter gap.

## Pre-stealth engine hashes (recorded via a throwaway probe, the test_arena
## compat-pin idiom): the same command logs must reproduce these EXACTLY —
## any ENGINE drift means legacy fights are no longer byte-identical.
## RE-RECORDED wave 4d (2026-08-11): to_dict embeds static_data verbatim, so
## the war_hound herding DATA edit (enemies.json — `herder: true` + note
## rewrites, R11 #21) legitimately moved every hash. Re-record procedure
## (the honest one): the 9f0638c BASELINE engine + the new data produced
## these values, and the wave-4d engine reproduces them byte-identically —
## the engine change itself is proven byte-compatible; only the data moved.
const LEGACY_HASH_PLAIN: String = "f772da32ebec177ca96f0243e1aad7b5cfaa25e09b80d46255d4fa2930db50bf"
const LEGACY_HASH_ARENA_DOOR: String = "aa9257b0081cc5687053044601349e198b21e6156d2ccc051375bb351474f35e"


func stealth(sim: CombatSim, actor: String, to_state: String = "hide") -> Array[Dictionary]:
	return sim.apply_command({"type": "stealth", "actor": actor, "set": to_state})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## A hostile human WATCHER (Mind 3 -> R20 sight 6) — the observer used across
## the sight tests; a contestant-category enemy is a legal combatant and keeps
## the AI policy out of observer-only scenarios.
func add_watcher(sim: CombatSim, pos: Array, mind: int = 3) -> Array[Dictionary]:
	return add_human(sim, "watcher", {"team": "enemies", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": mind, "charm": 3}})


# ------------------------------------------------------------- legacy compat

func test_legacy_stealth_free_fight_hashes_are_byte_identical() -> void:
	# Sequence A (plain, no arena) — the exact pre-stealth engine hash.
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
	assert_eq(sim.state_hash(), LEGACY_HASH_PLAIN, "stealth-free plain fight replays the pre-stealth hash")
	# No "stealthed" key anywhere in the serialized state (the compat pin's
	# structural half — combatant dicts AND tick-snapshot entries).
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		assert_false((dict["combatants"][id] as Dictionary).has("stealthed"),
			"no stealthed key on a never-stealthed combatant (%s)" % id)
	for id: Variant in dict.get("tick_snapshot", {}) as Dictionary:
		assert_false((dict["tick_snapshot"][id] as Dictionary).has("stealthed"),
			"no stealthed key in a legacy snapshot entry (%s)" % id)

	# Sequence B (arena + wall + door flip) — the arena path stays untouched too.
	var sim2 := CombatSim.new(77, SimTestBase.load_static_data())
	sim2.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21},
		"walls": [[3, 0]],
		"doors": [{"key": "d", "position": [2, 0], "state": "closed"}]}})
	add_human(sim2, "h1", {"team": "party", "position": [1, 0]})
	sim2.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [5, 5]}})
	sim2.apply_command({"type": "door", "actor": "h1", "key": "d", "set": "open"})
	advance(sim2, 1)
	move(sim2, "h1", [2, 0])
	ai_decide(sim2, "mob")
	advance(sim2, 1)
	assert_eq(sim2.state_hash(), LEGACY_HASH_ARENA_DOOR, "stealth-free arena/door fight replays the pre-stealth hash")


# ------------------------------------------------------- entry / exit / slot

func test_stealth_entry_exit_and_free_action_slot() -> void:
	var sim: CombatSim = make_sim()
	add_watcher(sim, [20, 0])  # sight 6 — far out of range of the origin
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	assert_rejected(stealth(sim, "ghost"), "unknown_actor", "unknown actor")
	assert_rejected(stealth(sim, "h1", "ajar"), "unknown_stealth_state", "hide|reveal only")
	assert_rejected(stealth(sim, "h1", "reveal"), "not_stealthed", "nothing to reveal yet")
	var entered: Array[Dictionary] = stealth(sim, "h1")
	assert_event(entered, "stealth_entered", "unseen hide succeeds")
	assert_true(sim.combatants["h1"].stealthed, "state flag set")
	assert_true(sim.combatants["h1"].free_action_used, "the hide consumed the R3 free-action slot")
	assert_rejected(stealth(sim, "h1"), "already_stealthed", "no double hide")
	# Reveal is FREE (abandoning a state is not an act) and works slot-spent.
	var revealed: Array[Dictionary] = stealth(sim, "h1", "reveal")
	assert_eq(String(assert_event(revealed, "stealth_broken", "voluntary reveal").get("reason", "")),
		"revealed_self", "reveal reason")
	assert_false(sim.combatants["h1"].stealthed, "flag cleared")
	# The slot is spent this tick — a re-hide waits for the next Moment.
	assert_rejected(stealth(sim, "h1"), "free_action_used", "one free action per tick (door/bit family)")
	advance(sim, 1)
	assert_event(stealth(sim, "h1"), "stealth_entered", "fresh tick, fresh slot")


func test_entry_gates_grapple_and_helpless() -> void:
	var sim: CombatSim = make_sim()
	add_watcher(sim, [20, 0])
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	# R9 physical contact = detection: neither side of a live grapple can hide.
	sim.combatants["h1"].grappling = "watcher"
	assert_rejected(stealth(sim, "h1"), "in_grapple", "a grappler cannot hide")
	sim.combatants["h1"].grappling = ""
	sim.combatants["h1"].grappled_by = "watcher"
	assert_rejected(stealth(sim, "h1"), "in_grapple", "a held victim cannot hide")
	sim.combatants["h1"].grappled_by = ""
	# Helpless (fainted) cannot act — same actor gate as every command.
	sim.cond.apply_shock(sim.combatants["h1"], 3, sim.clock.tick)
	assert_rejected(stealth(sim, "h1"), "helpless", "a fainted combatant cannot hide")


# ------------------------------------------------------- sight numbers (R20)

func test_sight_is_exactly_twice_mind_with_the_observer_named() -> void:
	var sim: CombatSim = make_sim()
	add_watcher(sim, [0, 0])  # Mind 3 -> sight 6, exactly
	add_human(sim, "h1", {"team": "party", "position": [6, 0]})
	var seen: Array[Dictionary] = stealth(sim, "h1")
	assert_rejected(seen, "in_enemy_sight", "distance 6 = 2 x Mind 3 — still seen (boundary inclusive)")
	assert_eq(String(first_event(seen, "command_rejected").get("observer", "")), "watcher",
		"the rejection names the observer")
	move(sim, "h1", [7, 0])
	advance(sim, 1)
	assert_event(stealth(sim, "h1"), "stealth_entered", "distance 7 > 6 — out of the Mind range")


func test_mind_zero_sees_nothing_and_allies_never_break_stealth() -> void:
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [1, 0]}})
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	add_human(sim, "h2", {"team": "party", "position": [0, 1]})  # adjacent ALLY, Mind 3
	# The roach_dog's Mind 0 -> sight 0: it cannot see an ADJACENT contestant
	# ("Mind sufficient" in its purest form), and the watching ally is exempt
	# by design — you hide WITH your party FROM the enemy.
	assert_event(stealth(sim, "h1"), "stealth_entered", "Mind 0 adjacent + ally in full view: hide holds")
	assert_true(sim.combatants["h1"].stealthed, "still stealthed after the sweep")


func test_helpless_observer_keeps_no_watch() -> void:
	var sim: CombatSim = make_sim()
	add_watcher(sim, [3, 0])  # in range (3 <= 6)...
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	assert_rejected(stealth(sim, "h1"), "in_enemy_sight", "awake watcher blocks the hide")
	# ...but a FAINTED watcher (Shock T3 -> Helpless) sees nothing (R13/R20).
	sim.cond.apply_shock(sim.combatants["watcher"], 3, sim.clock.tick)
	assert_event(stealth(sim, "h1"), "stealth_entered", "a fainted observer keeps no watch")


# ----------------------------------------------------- cover / LOS (R29 query)

func test_walls_and_closed_doors_block_sight_open_door_reveals() -> void:
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21},
		"walls": [],
		"doors": [{"key": "d", "position": [2, 0], "state": "closed"}]}})
	add_watcher(sim, [0, 0])
	add_human(sim, "h1", {"team": "party", "position": [4, 0]})   # distance 4 <= 6, but...
	add_human(sim, "h2", {"team": "party", "position": [1, 0]})   # the door opener
	# The [0,0]->[4,0] sight line crosses [2,0]: the CLOSED door blocks LOS
	# through the ONE R29 query (Arena.is_wall via blocks_lane), so the hide
	# lands in what would otherwise be plain view.
	assert_event(stealth(sim, "h1"), "stealth_entered", "closed door = full-height cover")
	# Opening the door REVEALS on that very command — the sweep runs in _post.
	var flip: Array[Dictionary] = sim.apply_command({"type": "door", "actor": "h2", "key": "d", "set": "open"})
	var broken: Dictionary = assert_event(flip, "stealth_broken", "the opened sight line finds the hider")
	assert_eq(String(broken.get("reason", "")), "seen", "seen, not any other break")
	assert_eq(String(broken.get("observer", "")), "watcher", "by the watcher")
	assert_false(sim.combatants["h1"].stealthed, "revealed")
	# Static wall variant: LOS pinned at the query level too (both states).
	var arena: Arena = sim.arena
	assert_true(Stealth.has_los(arena, Vector2i(0, 0), Vector2i(4, 0)), "open door blocks nothing")
	arena.doors[0]["state"] = "closed"
	assert_false(Stealth.has_los(arena, Vector2i(0, 0), Vector2i(4, 0)), "closed door blocks the line")
	arena.walls[Vector2i(2, 1)] = true
	assert_false(Stealth.has_los(arena, Vector2i(0, 2), Vector2i(4, 0)), "a wall on an intermediate hex blocks")
	assert_true(Stealth.has_los(null, Vector2i(0, 0), Vector2i(40, 0)), "no arena = nothing to block (legacy)")


func test_wall_cover_holds_until_someone_moves() -> void:
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 21, "height": 21}, "walls": [[2, 0]]}})
	add_watcher(sim, [0, 0])
	add_human(sim, "h1", {"team": "party", "position": [4, 0]})
	assert_event(stealth(sim, "h1"), "stealth_entered", "the wall shields the hide")
	# The WATCHER moves off the blocked line -> the sweep catches the hider
	# (R20's "reacting turns/moves it so you enter its cone" analog: v1 has no
	# facing, so the escalation is purely positional).
	var step: Array[Dictionary] = move(sim, "watcher", [0, 2])
	var broken: Dictionary = assert_event(step, "stealth_broken", "observer movement re-opens the line")
	assert_eq(String(broken.get("reason", "")), "seen", "seen on the observer's own move")
	assert_false(sim.combatants["h1"].stealthed, "revealed by the flank")


func test_moving_into_sight_breaks_stealth() -> void:
	var sim: CombatSim = make_sim()
	add_watcher(sim, [0, 0])
	add_human(sim, "h1", {"team": "party", "position": [7, 0]})
	assert_event(stealth(sim, "h1"), "stealth_entered", "hidden at 7 > 6")
	advance(sim, 1)  # the hide spent this tick's free slot (R3) — step next Moment
	var step: Array[Dictionary] = move(sim, "h1", [6, 0])
	var broken: Dictionary = assert_event(step, "stealth_broken", "stepping to 6 = 2 x Mind is stepping into view")
	assert_eq(String(broken.get("reason", "")), "seen", "the hider's own move revealed it")
	assert_eq(String(broken.get("observer", "")), "watcher", "observer named")


# ------------------------------------------------------------- breaks (R13/R20)

func test_shout_breaks_stealth_but_plain_damage_does_not() -> void:
	var sim: CombatSim = make_sim()
	add_watcher(sim, [20, 0])
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	stealth(sim, "h1")
	# Crushed T1 carries shock_tier 0: real damage, NO shout — stealth holds
	# (damage alone is not a ruled break; only sight and noise are).
	var quiet: Array[Dictionary] = sim.apply_command({
		"type": "apply_condition", "target": "h1", "part": "torso", "condition": "crushed", "tier": 1})
	assert_no_event(quiet, "stealth_broken", "a quiet wound breaks nothing")
	assert_true(sim.combatants["h1"].stealthed, "still hidden after crushed T1")
	# Burn T1 applies Shock T1 (the cauterize cost) -> the T1 SHOUT — R13's
	# "noise/stealth break", wired: the shouter reveals itself, range-free.
	var loud: Array[Dictionary] = sim.apply_command({
		"type": "apply_condition", "target": "h1", "part": "torso", "condition": "burn", "tier": 1})
	assert_event(loud, "shock_shout", "burn T1 shocked the hider into a shout")
	var broken: Dictionary = assert_event(loud, "stealth_broken", "the shout breaks the shouter's stealth")
	assert_eq(String(broken.get("reason", "")), "shout", "reason = shout (the R13 noise seed)")
	assert_false(sim.combatants["h1"].stealthed, "outed by its own voice")


func test_downed_stealther_is_revealed() -> void:
	var sim: CombatSim = make_sim()
	add_watcher(sim, [20, 0])
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	add_human(sim, "h2", {"team": "party", "position": [1, 0]})
	stealth(sim, "h1")
	# Friendly fire is ON (Q69) and allies may target their hidden scout: h2's
	# oversized hit fells the stealthed h1 — a corpse is not hidden.
	declare(sim, "h2", attack_action("crushed", 20, "h1", "torso"))
	var tick_events: Array[Dictionary] = advance(sim, 1)
	assert_event(tick_events, "combatant_died", "the torso hit was lethal")
	var broken: Dictionary = assert_event(tick_events, "stealth_broken", "death drops the veil")
	assert_eq(String(broken.get("reason", "")), "downed", "reason = downed")
	assert_false(sim.combatants["h1"].stealthed, "cleared on the corpse")


# ------------------------------------------------------------- AI honesty (R20)

func test_ai_excludes_stealthed_targets_loses_all_and_reacquires() -> void:
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [1, 0]}})
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	add_human(sim, "h2", {"team": "party", "position": [0, 1]})
	# Two candidates: the R23 draw runs (one ai_rng draw, both in the pool).
	var first: Dictionary = assert_event(ai_decide(sim, "mob"), "ai_decision", "baseline decide")
	assert_true(["h1", "h2"].has(String(first.get("target", ""))), "an un-stealthed pool of two")
	advance(sim, 1)
	# h1 hides (roach Mind 0 sees nothing): the pool honestly shrinks to h2 —
	# a SINGLE candidate consumes ZERO draws (R23 rng-cost rule holds).
	assert_event(stealth(sim, "h1"), "stealth_entered", "h1 slips away mid-fight")
	var rng_before: int = sim.ai.ai_rng.state
	var second: Dictionary = assert_event(ai_decide(sim, "mob"), "ai_decision", "decide with one visible target")
	assert_eq(String(second.get("target", "")), "h2", "the stealthed h1 does not exist to the policy")
	assert_eq(sim.ai.ai_rng.state, rng_before, "single-candidate pick consumed zero ai_rng draws")
	advance(sim, 1)
	# Both hidden: the mob LOSES the target and waits — no search, no
	# last-known-position (R20's investigate rides the downscoped hearing
	# model; the honest v1 is losing the prey outright).
	assert_event(stealth(sim, "h2"), "stealth_entered", "h2 vanishes too")
	rng_before = sim.ai.ai_rng.state
	var lost: Dictionary = assert_event(ai_decide(sim, "mob"), "ai_decision", "decide with nobody visible")
	assert_eq(String(lost.get("choice", "")), "wait", "the mob honestly loses the target")
	assert_eq(String(lost.get("reason", "")), "no_targets", "no invented information")
	assert_eq(sim.ai.ai_rng.state, rng_before, "an empty pool consumes nothing")
	advance(sim, 1)
	# Honest re-acquisition: a voluntary reveal puts h1 straight back in play.
	stealth(sim, "h1", "reveal")
	var again: Dictionary = assert_event(ai_decide(sim, "mob"), "ai_decision", "decide after the reveal")
	assert_eq(String(again.get("target", "")), "h1", "the revealed contestant is a target again")


# ------------------------------------------------- hostile-surface gates (R20)

## A hostile stealther the party can try to aim at: the Mind-0 attacker "att"
## cannot see the adjacent "sneak" (enemies team), so the hide legally holds
## right next to it — the only geometry where adjacent gates (grapple) can
## ever meet a stealthed target.
func _sim_with_adjacent_hidden_hostile() -> CombatSim:
	var sim: CombatSim = make_sim()
	add_human(sim, "att", {"team": "party", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3}})
	add_human(sim, "sneak", {"team": "enemies", "position": [1, 0]})
	stealth(sim, "sneak")
	return sim


func test_declares_and_reactions_reject_a_stealthed_hostile() -> void:
	var sim: CombatSim = _sim_with_adjacent_hidden_hostile()
	assert_true(sim.combatants["sneak"].stealthed, "the sneak is hidden beside a Mind-0 attacker")
	# Attack declare — rejected, nothing scheduled.
	assert_rejected(declare(sim, "att", attack_action("crushed", 2, "sneak", "torso")),
		"target_stealthed", "an attack cannot aim at what the fiction cannot see")
	# Skill declare (the targets-carrying skill path has no other declare-time
	# target validation — the stealth gate covers it too).
	assert_rejected(declare(sim, "att", {"kind": "skill", "key": "improvised_jab", "cost": 1,
		"damage": {"type": "crushed", "amount": 2}, "attack_range": 1,
		"targets": [{"id": "sneak", "part": "torso"}]}),
		"target_stealthed", "the skill path gates identically")
	# Grapple — the single-"target" field is covered by the same gate.
	assert_rejected(declare(sim, "att", {"kind": "grapple", "cost": 1, "target": "sneak"}),
		"target_stealthed", "hands cannot find an unseen body")
	# Reaction — rejected BEFORE the slot/readiness mutations.
	assert_rejected(sim.apply_command({"type": "reaction", "actor": "att", "cost": 0,
		"target": "sneak", "part": "torso", "damage": {"type": "crushed", "amount": 1}}),
		"target_stealthed", "a damaging reaction gates the same way")
	assert_false(sim.combatants["att"].reaction_used, "the rejected reaction consumed nothing")
	assert_false(sim.combatants["att"].free_action_used, "no slot burned either")
	# Friendly fire on a stealthed TEAMMATE stays legal (Q69): sneak's ally.
	add_human(sim, "e2", {"team": "enemies", "position": [2, 0]})
	advance(sim, 1)
	assert_event(declare(sim, "e2", attack_action("crushed", 1, "sneak", "torso")),
		"action_declared", "allies coordinate — the gate is hostile-only")


func test_preview_reports_target_stealthed_honestly() -> void:
	var sim: CombatSim = _sim_with_adjacent_hidden_hostile()
	var preview: Dictionary = sim.resolver.preview_action(sim.combatants["att"],
		attack_action("crushed", 2, "sneak", "torso"))
	var rows: Array = preview.get("per_target", [])
	assert_eq(rows.size(), 1, "one preview row")
	assert_true(bool((rows[0] as Dictionary).get("target_stealthed", false)),
		"the row says the declare would reject (additive key)")
	# The ally's preview of the same body carries NO stealth flag (row shape
	# unchanged for every legal ask).
	add_human(sim, "e2", {"team": "enemies", "position": [2, 0]})
	var ally_preview: Dictionary = sim.resolver.preview_action(sim.combatants["e2"],
		attack_action("crushed", 2, "sneak", "torso"))
	var ally_rows: Array = ally_preview.get("per_target", [])
	assert_eq(ally_rows.size(), 1, "ally row present")
	assert_false((ally_rows[0] as Dictionary).has("target_stealthed"),
		"no flag on a same-team ask — key present only when it gates")


func test_windup_collapses_when_the_target_hides_but_instants_never_recheck() -> void:
	# WINDUP: att commits a 2-Moment swing; the victim slips into stealth
	# before it resolves — the R2 snapshot re-check collapses it exactly like
	# leaving range (Forced Action - Tool rides the collapse).
	var sim: CombatSim = make_sim()
	add_human(sim, "att", {"team": "party", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3}})
	add_human(sim, "vic", {"team": "enemies", "position": [1, 0]})
	declare(sim, "att", attack_action("crushed", 2, "vic", "torso", {"cost": 2}))
	assert_event(stealth(sim, "vic"), "stealth_entered", "the victim vanishes mid-windup")
	var resolution: Array[Dictionary] = advance(sim, 3)
	var invalidated: Dictionary = assert_event(resolution, "action_invalidated", "the aimed windup collapses")
	assert_eq(String(invalidated.get("reason", "")), "target_stealthed", "collapse reason")
	for hit: Dictionary in events_of(resolution, "damage_applied"):
		assert_ne(String(hit.get("combatant", "")), "vic",
			"no hit landed on the vanished target (a Tool consequence may hit the actor)")
	# INSTANT: declared while the target was visible, it resolves without
	# re-checks (R2: instants cannot be dodged) — and the quiet crushed hit
	# does NOT break the fresh stealth (no shock, no shout, no sight: Mind 0).
	var sim2: CombatSim = make_sim()
	add_human(sim2, "att", {"team": "party", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3}})
	add_human(sim2, "vic", {"team": "enemies", "position": [1, 0]})
	declare(sim2, "att", attack_action("crushed", 2, "vic", "torso"))
	stealth(sim2, "vic")
	var tick_events: Array[Dictionary] = advance(sim2, 1)
	assert_event(tick_events, "damage_applied", "the committed instant still lands (R2)")
	assert_no_event(tick_events, "stealth_broken", "a quiet hit reveals nothing")
	assert_true(sim2.combatants["vic"].stealthed, "still hidden after the instant")


func test_committed_cone_burns_the_hidden_body_and_the_shout_outs_it() -> void:
	# Physicality over information: the cone is committed GEOMETRY — a body in
	# the arc gets burned, stealthed or not. The burn's Shock-T1 Shout then
	# breaks the stealth through the RULED noise path (not through sight).
	var sim: CombatSim = make_sim()
	add_human(sim, "att", {"team": "party", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3}})
	add_human(sim, "vic", {"team": "enemies", "position": [2, 0]})
	declare(sim, "att", {"kind": "attack", "cost": 2, "attack_range": 3,
		"damage": {"type": "burn", "amount": 2},
		"targets": [{"id": "vic", "part": "torso"}],
		"area_shape": {"kind": "cone", "toward": [1, 0], "size": 3}})
	assert_event(stealth(sim, "vic"), "stealth_entered", "hidden inside a committed arc")
	var resolution: Array[Dictionary] = advance(sim, 3)
	assert_no_event(resolution, "windup_target_escaped", "stealth does not move the body out of the fire")
	assert_event(resolution, "damage_applied", "the arc burned the hidden body")
	var broken: Dictionary = assert_event(resolution, "stealth_broken", "the burn shock shouted the hider out")
	assert_eq(String(broken.get("reason", "")), "shout", "the RULED noise path, not sight (Mind 0 all around)")


# ------------------------------------------------- views / serialization / rng

func test_view_combatants_carries_the_stealthed_flag() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, SimTestBase.load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "h1", "name": "h1", "race": "human", "team": "party", "position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}})
	var view_hidden: bool = true
	for cd: Dictionary in game.view_combatants():
		if String(cd.get("id", "")) == "h1":
			view_hidden = bool(cd.get("stealthed", true))
	assert_false(view_hidden, "detected by default in the view")
	game.apply_command({"type": "stealth", "actor": "h1"})
	for cd: Dictionary in game.view_combatants():
		if String(cd.get("id", "")) == "h1":
			view_hidden = bool(cd.get("stealthed", false))
	assert_true(view_hidden, "the broadcast sees the hidden contestant (cameras are omniscient, R20)")
	game.free()


func test_serialization_roundtrip_mid_stealth_and_lockstep() -> void:
	var sim: CombatSim = make_sim()
	add_watcher(sim, [0, 0])
	add_human(sim, "h1", {"team": "party", "position": [7, 0]})
	stealth(sim, "h1")
	advance(sim, 1)
	var dict: Dictionary = sim.to_dict()
	assert_true(bool((dict["combatants"]["h1"] as Dictionary).get("stealthed", false)),
		"the hider serializes stealthed: true")
	assert_false((dict["combatants"]["watcher"] as Dictionary).has("stealthed"),
		"nobody else grows the key")
	assert_true(bool((dict["tick_snapshot"]["h1"] as Dictionary).get("stealthed", false)),
		"the tick snapshot carries it too (windup re-checks read it)")
	var mid_hash: String = sim.state_hash()
	var restored: CombatSim = CombatSim.from_dict(dict)
	assert_eq(restored.state_hash(), mid_hash, "round-trip hash identical (stealth covered)")
	assert_true(restored.combatants["h1"].stealthed, "the flag survived the trip")
	# Lockstep tail: the hider steps into view on BOTH sims -> same break,
	# same hash (the sweep is deterministic, rng-free).
	for target: CombatSim in [sim, restored] as Array[CombatSim]:
		var step: Array[Dictionary] = target.apply_command({"type": "move", "actor": "h1", "to": [6, 0]})
		assert_event(step, "stealth_broken", "both sims reveal on the same step")
	assert_eq(restored.state_hash(), sim.state_hash(), "identical tails end on the same hash")


func test_stealth_paths_consume_zero_rng_and_replay_deterministically() -> void:
	# R20 authors NO detection roll: every stealth path (entry, sweep, breaks)
	# must consume neither the action RNG nor the salted AI stream.
	var sim: CombatSim = make_sim()
	add_watcher(sim, [0, 0])
	add_human(sim, "h1", {"team": "party", "position": [7, 0]})
	var action_rng: int = sim.rng.state
	var ai_rng: int = sim.ai.ai_rng.state
	stealth(sim, "h1")                     # entry + sweep
	advance(sim, 1)                        # fresh free slot (nothing scheduled — no rng)
	move(sim, "h1", [8, 0])                # sweep (still hidden)
	advance(sim, 1)
	move(sim, "h1", [6, 0])                # sweep -> seen break
	assert_false(sim.combatants["h1"].stealthed, "the walk into view broke it")
	assert_rejected(stealth(sim, "h1"), "in_enemy_sight", "re-hiding in plain view rejects — still no rng")
	assert_eq(sim.rng.state, action_rng, "action RNG untouched by every stealth path")
	assert_eq(sim.ai.ai_rng.state, ai_rng, "AI RNG untouched too (no roll authored)")
	# Full-fight determinism: the same seed + the same stealth-heavy command
	# log lands on the same hash, twice.
	var hashes: Array[String] = []
	for _round: int in range(2):
		var replay: CombatSim = make_sim(99)
		replay.apply_command({"type": "add_combatant", "combatant": {
			"id": "mob", "name": "mob", "enemy": "roach_dog", "team": "enemies", "position": [1, 0]}})
		add_human(replay, "h1", {"team": "party", "position": [0, 0]})
		add_human(replay, "h2", {"team": "party", "position": [0, 1]})
		replay.apply_command({"type": "ai_decide", "actor": "mob"})
		replay.apply_command({"type": "advance_tick"})
		replay.apply_command({"type": "stealth", "actor": "h1"})
		replay.apply_command({"type": "ai_decide", "actor": "mob"})
		replay.apply_command({"type": "advance_tick"})
		replay.apply_command({"type": "stealth", "actor": "h2"})
		replay.apply_command({"type": "ai_decide", "actor": "mob"})
		replay.apply_command({"type": "advance_tick"})
		replay.apply_command({"type": "stealth", "actor": "h1", "set": "reveal"})
		replay.apply_command({"type": "ai_decide", "actor": "mob"})
		replay.apply_command({"type": "advance_tick"})
		hashes.append(replay.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) -> same hash through the stealth kit")


func test_run_carry_never_keeps_stealth() -> void:
	# R20: stealth is in-encounter concealment — the next room re-stages (and
	# re-sees) you. The carry ERASES the compat-conditional key.
	var sim: CombatSim = make_sim()
	add_watcher(sim, [20, 0])
	add_human(sim, "h1", {"team": "party", "position": [0, 0]})
	stealth(sim, "h1")
	var carry: Dictionary = RunState._sanitize_carry(sim.combatants["h1"].to_dict())
	assert_false(carry.has("stealthed"), "stealth never crosses the encounter gap")
