extends SimTestBase
## R34 FREE-ACTION BUDGET (owner ruling 2026-08-19 — amends R3's single slot).
##
## The ruling: "free actions are 2 per turn". R3 gave each combatant exactly
## ONE free (0-Moment) action per reset window, tracked as the boolean
## `free_action_used`; the allowance is now the COUNTER `free_actions_used`
## capped at CombatantState.FREE_ACTIONS_PER_CLOCK (2, PLACEHOLDER R14).
## Everything else in R3's free-action family is untouched: what qualifies
## (0-cost declares, the free 1-3 space move, the first inventory interaction,
## 0-cost reactions, the bit/door/voicebox/stealth family), the ONE shared
## pool across all of them, the inventory-interaction rule, and the rejection
## reason string — still byte-identically "free_action_used", because the HUD,
## the harnesses and a dozen tests read it.
##
## CADENCE (flagged, not silently re-ruled): R34's parenthetical calls the
## window a Clock; R3 as written AND as built prices the family per TICK —
## reset_tick_flags() clears the budget at every tick advance, which is why a
## free move is available every Moment. This story kept R3's live cadence and
## only deepened the pool; the discrepancy is flagged in the R3 amendment for
## the owner. These tests therefore say "tick" where R34 says "turn".
##
## What is pinned here:
##   * two free actions in one tick both land, the THIRD rejects (same reason);
##   * the budget refreshes at the next tick, per combatant, one shared pool;
##   * every free-action SITE draws on the same counter (declare, free move,
##     first inventory, 0-cost reaction, the bit);
##   * serialization: the counter round-trips mid-budget and is written
##     ONLY when spent, so a free-action-free fight hashes byte-identically
##     to the pre-R34 engine (LEGACY_HASH_NO_FREE_ACTIONS, captured by
##     replaying this exact log on the pre-change build);
##   * legacy saves (boolean only) load as exhausted / open correctly;
##   * determinism: spending the budget consumes ZERO rng (twin-state compare).

const DARIO_BIT: Dictionary = {
	"key": "the_bow", "name": "The Bow",
	"line": "Dario bows mid-combat — the applause is the point.",
}

## The pre-R34 state hash of no_free_action_fight() — captured by replaying
## that exact command log on the build at the base commit (72a00b6), BEFORE
## the counter existed. A fight nobody spends a free action in must serialize
## byte-identically forever: the counter is written only when set.
const LEGACY_HASH_NO_FREE_ACTIONS: String = "74953c2e7b40291ea9b2dcd10da8654fad5674ac0d0ef3bdbe13546e6e881627"


func free_declare(sim: CombatSim, actor: String, key: String) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "cost": 0, "key": key})


func move(sim: CombatSim, actor: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": actor, "to": to})


## A fight that spends NOT ONE free action: scheduled attacks only, no moves,
## no inventory, no bit, no AI (the AI free-moves). The legacy-hash pin.
func no_free_action_fight() -> CombatSim:
	var sim: CombatSim = make_sim(4242)
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	add_human(sim, "b", {"team": "enemies", "position": [1, 0]})
	declare(sim, "a", attack_action("crushed", 3, "b", "torso"))
	advance(sim, 2)
	declare(sim, "b", attack_action("bleeding", 2, "a", "torso", {"cost": 2}))
	advance(sim, 3)
	declare(sim, "a", attack_action("crushed", 2, "b", "left_arm"))
	advance(sim, 2)
	return sim


# ------------------------------------------------------------- the allowance

func test_two_free_actions_land_and_the_third_rejects() -> void:
	assert_eq(CombatantState.FREE_ACTIONS_PER_CLOCK, 2,
		"the ruled budget: 2 per turn (owner 2026-08-19, PLACEHOLDER R14)")
	var sim: CombatSim = make_sim(4301)
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	assert_event(free_declare(sim, "a", "taunt"), "action_declared", "entry 1 lands (R3, unchanged)")
	assert_eq((sim.combatants["a"] as CombatantState).free_actions_used, 1, "one spent")
	assert_event(free_declare(sim, "a", "flex"), "action_declared",
		"entry 2 lands — THE RULING: this is what R3 used to reject")
	var a: CombatantState = sim.combatants["a"]
	assert_eq(a.free_actions_used, 2, "both spent")
	assert_eq(a.free_actions_left(), 0, "nothing left")
	assert_true(a.free_action_used, "the derived flag means EXHAUSTED — what the HUD dims on")
	var before: String = sim.state_hash()
	var third: Array[Dictionary] = free_declare(sim, "a", "flex2")
	assert_rejected(third, "free_action_used",
		"the third rejects with the SAME reason string as the old second (byte-identical)")
	assert_no_event(third, "action_declared", "nothing declared past the budget")
	assert_eq(sim.state_hash(), before, "the rejection mutates NOTHING")


func test_budget_refreshes_on_the_next_window() -> void:
	var sim: CombatSim = make_sim(4302)
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	free_declare(sim, "a", "taunt")
	free_declare(sim, "a", "flex")
	assert_rejected(free_declare(sim, "a", "flex2"), "free_action_used", "spent")
	advance(sim, 1)  # reset_tick_flags — R3's live cadence, unchanged by R34
	assert_eq((sim.combatants["a"] as CombatantState).free_actions_used, 0, "the counter reset")
	assert_event(free_declare(sim, "a", "taunt"), "action_declared", "a fresh window, a fresh budget")
	assert_event(free_declare(sim, "a", "flex"), "action_declared", "both entries again")
	assert_rejected(free_declare(sim, "a", "flex2"), "free_action_used", "and the same cap")


func test_budget_is_per_combatant() -> void:
	var sim: CombatSim = make_sim(4303)
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	add_human(sim, "b", {"team": "party", "position": [4, 0]})
	free_declare(sim, "a", "taunt")
	free_declare(sim, "a", "flex")
	assert_rejected(free_declare(sim, "a", "flex2"), "free_action_used", "a is spent")
	assert_eq((sim.combatants["b"] as CombatantState).free_actions_used, 0,
		"b's budget is untouched by a's spending")
	assert_event(move(sim, "b", [5, 0]), "moved", "b still has a free move the same tick")
	assert_event(free_declare(sim, "b", "taunt"), "action_declared", "and b's second entry")
	assert_rejected(free_declare(sim, "b", "flex"), "free_action_used", "b caps on its OWN budget")


func test_every_free_action_site_draws_on_the_one_pool() -> void:
	# The R3 family shares ONE pool — the ruling deepened it, it did not fork
	# it per family. Each pair below spends both entries at a DIFFERENT pair of
	# real sites, then proves the third is refused.
	# (a) free move + first inventory interaction
	var sim: CombatSim = make_sim(4304)
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	assert_event(move(sim, "a", [1, 0]), "moved", "entry 1: the free 1-3 space move")
	var used: Dictionary = assert_event(sim.apply_command({"type": "inventory", "actor": "a"}),
		"inventory_used", "entry 2: the combat's FIRST inventory interaction")
	assert_true(bool(used.get("free", false)), "still the free interaction (R3's rule stands)")
	assert_rejected(free_declare(sim, "a", "taunt"), "free_action_used", "and the pool is empty")
	# (b) 0-cost declare + 0-cost reaction
	var sim2: CombatSim = make_sim(4305)
	add_human(sim2, "a", {"team": "party", "position": [0, 0]})
	assert_event(free_declare(sim2, "a", "taunt"), "action_declared", "entry 1: the 0-cost declare")
	assert_event(sim2.apply_command({"type": "reaction", "actor": "a", "cost": 0}),
		"reaction_resolved", "entry 2: the 0-cost reaction")
	assert_rejected(move(sim2, "a", [1, 0]), "free_action_used", "the free move has nothing left to spend")
	# (c) the bit twice (CombatSim's own free-action site, untouched by this story)
	var sim3: CombatSim = make_sim(4306)
	add_human(sim3, "dario", {"team": "party", "position": [0, 0], "bit": DARIO_BIT})
	assert_event(sim3.apply_command({"type": "bit", "actor": "dario"}), "bit_performed", "entry 1")
	assert_event(sim3.apply_command({"type": "bit", "actor": "dario"}), "bit_performed", "entry 2")
	assert_rejected(sim3.apply_command({"type": "bit", "actor": "dario"}), "free_action_used",
		"the bit is still bounded per Moment — the anti-spam ruling survives the deeper pool")


# ---------------------------------------------------------- serialization

func test_counter_round_trips_mid_budget() -> void:
	var live: CombatSim = make_sim(4307)
	add_human(live, "a", {"team": "party", "position": [0, 0]})
	add_human(live, "b", {"team": "enemies", "position": [4, 0]})
	assert_event(move(live, "a", [1, 0]), "moved", "one entry spent — mid-budget")
	var a_live: CombatantState = live.combatants["a"]
	assert_eq(a_live.free_actions_used, 1, "precondition: exactly one spent")
	assert_true(a_live.has_free_action(), "precondition: one entry left")
	var dict: Dictionary = live.to_dict()
	var row: Dictionary = (dict["combatants"] as Dictionary)["a"]
	assert_eq(int(row.get("free_actions_used", -1)), 1, "the counter is serialized while set")
	assert_false(bool(row.get("free_action_used", true)),
		"and the legacy bool reads FALSE mid-budget — it means exhausted, not touched")
	var restored: CombatSim = CombatSim.from_dict(dict)
	assert_eq(restored.state_hash(), live.state_hash(), "hash survives the mid-budget round trip")
	var a_r: CombatantState = restored.combatants["a"]
	assert_eq(a_r.free_actions_used, 1, "free_actions_used round-trips")
	assert_true(a_r.has_free_action(), "the restored actor still holds its second entry")
	# Both timelines spend that entry and refuse the next, identically.
	assert_event(free_declare(restored, "a", "taunt"), "action_declared", "restored: entry 2 lands")
	assert_event(free_declare(live, "a", "taunt"), "action_declared", "live: entry 2 lands")
	assert_rejected(free_declare(restored, "a", "flex"), "free_action_used", "restored: capped")
	assert_rejected(free_declare(live, "a", "flex"), "free_action_used", "live: capped")
	assert_eq(restored.state_hash(), live.state_hash(), "restore -> replay tail = same hash")


func test_free_action_free_fight_is_byte_identical_to_the_pre_r34_engine() -> void:
	# The compat pin, structural half: no counter key anywhere in a fight that
	# never spends one — combatant rows AND tick-snapshot entries.
	var sim: CombatSim = no_free_action_fight()
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		var row: Dictionary = (dict["combatants"] as Dictionary)[id]
		assert_false(row.has("free_actions_used"),
			"no 'free_actions_used' key on a combatant that never spent one (%s)" % id)
		assert_true(row.has("free_action_used"),
			"the legacy boolean keeps its place in the shape (%s)" % id)
	for id: Variant in dict.get("tick_snapshot", {}) as Dictionary:
		assert_false((dict["tick_snapshot"][id] as Dictionary).has("free_actions_used"),
			"nor in a legacy snapshot entry (%s)" % id)
	# The numeric half: the exact pre-change hash of this exact log.
	assert_eq(sim.state_hash(), LEGACY_HASH_NO_FREE_ACTIONS,
		"a free-action-free fight replays the pre-R34 hash — old saves are untouched")


func test_legacy_boolean_saves_load_as_exhausted_or_open() -> void:
	# Pre-R34 saves carry ONLY the boolean: true = the (then single) slot was
	# spent = no free action is legal any more; false = untouched.
	var sim: CombatSim = make_sim(4308)
	add_human(sim, "a", {"team": "party", "position": [0, 0]})
	add_human(sim, "b", {"team": "party", "position": [4, 0]})
	var dict: Dictionary = sim.to_dict()
	var rows: Dictionary = dict["combatants"]
	(rows["a"] as Dictionary).erase("free_actions_used")
	(rows["a"] as Dictionary)["free_action_used"] = true
	(rows["b"] as Dictionary).erase("free_actions_used")
	(rows["b"] as Dictionary)["free_action_used"] = false
	var restored: CombatSim = CombatSim.from_dict(dict)
	var a: CombatantState = restored.combatants["a"]
	assert_eq(a.free_actions_used, CombatantState.FREE_ACTIONS_PER_CLOCK,
		"a legacy true loads as EXHAUSTED — never as a free upgrade to the new budget")
	assert_false(a.has_free_action(), "so nothing free is legal for a this tick")
	assert_rejected(free_declare(restored, "a", "taunt"), "free_action_used", "and the engine agrees")
	var b: CombatantState = restored.combatants["b"]
	assert_eq(b.free_actions_used, 0, "a legacy false loads as untouched")
	assert_eq(b.free_actions_left(), CombatantState.FREE_ACTIONS_PER_CLOCK, "with the whole budget")


# ------------------------------------------------------------- determinism

func test_twin_rng_spending_the_budget_consumes_zero_rng() -> void:
	# Twin sims, same seed: twin B additionally spends BOTH free-action entries
	# (and eats a rejection). The next Forced Body draw must be the SAME stream
	# value in both — the budget touches no rng.
	var twin_a: CombatSim = make_sim(4309)
	var twin_b: CombatSim = make_sim(4309)
	for twin: CombatSim in [twin_a, twin_b]:
		twin.apply_command({"type": "add_combatant", "combatant": {
			"id": "hound", "name": "hound", "enemy": "war_hound", "team": "enemies", "position": [0, 0]}})
		add_human(twin, "weakling", {"team": "party", "position": [1, 0],
			"traits": {"physique": 1, "reflexes": 3, "mind": 3, "charm": 3}})
	free_declare(twin_b, "weakling", "taunt")
	free_declare(twin_b, "weakling", "flex")
	assert_rejected(free_declare(twin_b, "weakling", "flex2"), "free_action_used",
		"precondition: twin B really hit the cap")
	for twin: CombatSim in [twin_a, twin_b]:
		advance(twin, 1)
	# The stream probe: an above-weight grapple's Forced Body (physique 1 < 2).
	for twin: CombatSim in [twin_a, twin_b]:
		declare(twin, "weakling", {"kind": "grapple", "target": "hound"})
	var roll_a: int = int(assert_event(advance(twin_a, 1), "forced_action_triggered", "twin A probe").get("roll", -1))
	var roll_b: int = int(assert_event(advance(twin_b, 1), "forced_action_triggered", "twin B probe").get("roll", -2))
	assert_eq(roll_a, roll_b, "identical stream draw — spending the budget consumed zero rng")


func test_same_log_same_hash_twice() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(4310)
		add_human(sim, "a", {"team": "party", "position": [0, 0]})
		add_human(sim, "b", {"team": "enemies", "position": [3, 0]})
		move(sim, "a", [1, 0])
		free_declare(sim, "a", "taunt")
		free_declare(sim, "a", "flex")  # rejected — the cap is deterministic too
		declare(sim, "b", attack_action("crushed", 2, "a", "torso", {"attack_range": 3}))
		advance(sim, 3)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same log, same hash — the counter is ordinary state")
