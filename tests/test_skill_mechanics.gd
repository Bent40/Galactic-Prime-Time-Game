extends SimTestBase
## Per-skill mechanics (SkillBook + ActionResolver kind=="skill" path). Covers the
## six demo-slice skills' authored behaviors plus their serialized state:
##   - brace (self_guard) buffers the next Crush/Burn hit, then is consumed
##   - feint (setup_debuff) collapses the target's next action into a Forced Tool
##   - pressure_strike (conditional_followup) adds Shock T1 only while feint pends
##   - dance (self_stance) enters a Charm stance that ends on hit / on attacking
##   - overhead_slam / strong_strike (committed_strike) deal typed damage; the
##     slam knocks a standing target Prone
##   - to_dict/from_dict round-trips brace_guard / feint_forced / dancing.
## Deterministic (fixed seed, no wall-clock, RNG only via ForcedAction).


## A large-HP, non-dodging Elite target so exact typed-damage numbers can be
## asserted without death or a dodge stream interfering.
func add_dummy(sim: CombatSim, id: String, pos: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "category": "Elite", "size": "Medium",
		"position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
			{"key": "left_arm", "hp": 50, "lethal": false},
			{"key": "right_arm", "hp": 50, "lethal": false},
		],
	}})


# ------------------------------------------------------------------ brace (self_guard)

func test_brace_reduces_next_crush_then_consumed() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "guard", {"position": [0, 0]})
	add_human(sim, "hitter", {"position": [1, 0]})
	# tick 0: brace is a free (cost 0) self action — no target.
	var braced: Array[Dictionary] = declare(sim, "guard", {"kind": "skill", "key": "brace", "level": 1})
	assert_event(braced, "action_declared", "brace declared as a free action")
	var resolved: Array[Dictionary] = advance(sim)
	assert_event(resolved, "brace_set", "brace resolves and arms the guard")
	var guard: CombatantState = sim.combatants["guard"]
	assert_eq(guard.brace_guard, 1, "Lv1 brace buffers 1")
	# tick 1: a Crush hit is reduced by the guard (5 - (3-1) = 3) and consumes it.
	declare(sim, "hitter", attack_action("crushed", 3, "guard", "torso"))
	var hit1: Array[Dictionary] = advance(sim)
	var absorbed: Dictionary = assert_event(hit1, "brace_absorbed", "the Crush hit is braced")
	assert_eq(int(absorbed.get("guard", -1)), 1, "the guard amount is recorded")
	assert_eq(int(guard.parts["torso"]["hp"]), 3, "5 - (3-1) = 3 after the brace shaved 1")
	assert_eq(guard.brace_guard, 0, "the guard is consumed")
	# tick 2: the next Crush hit is NOT reduced (3 - 3 = 0).
	declare(sim, "hitter", attack_action("crushed", 3, "guard", "torso"))
	var hit2: Array[Dictionary] = advance(sim)
	assert_no_event(hit2, "brace_absorbed", "a second hit finds no guard")
	assert_eq(int(guard.parts["torso"]["hp"]), 0, "3 - 3 = 0, unreduced")


func test_brace_reduces_burn_too() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "guard", {"position": [0, 0]})
	add_human(sim, "hitter", {"position": [1, 0]})
	declare(sim, "guard", {"kind": "skill", "key": "brace", "level": 2})
	advance(sim)
	var guard: CombatantState = sim.combatants["guard"]
	assert_eq(guard.brace_guard, 2, "Lv2 brace buffers 2")
	declare(sim, "hitter", attack_action("burn", 3, "guard", "torso"))
	var hit: Array[Dictionary] = advance(sim)
	assert_event(hit, "brace_absorbed", "Burn is a braced type as well as Crush")
	assert_eq(int(guard.parts["torso"]["hp"]), 4, "5 - (3-2) = 4")
	assert_eq(guard.brace_guard, 0, "guard consumed by the Burn hit")


func test_brace_not_consumed_by_bleed() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "guard", {"position": [0, 0]})
	add_human(sim, "hitter", {"position": [1, 0]})
	declare(sim, "guard", {"kind": "skill", "key": "brace", "level": 3})
	advance(sim)
	declare(sim, "hitter", attack_action("bleeding", 2, "guard", "torso"))
	var hit: Array[Dictionary] = advance(sim)
	assert_no_event(hit, "brace_absorbed", "Bleed does not consume a Crush/Burn brace")
	var guard: CombatantState = sim.combatants["guard"]
	assert_eq(guard.brace_guard, 3, "the guard is still armed after a Bleed hit")
	assert_eq(int(guard.parts["torso"]["hp"]), 3, "Bleed lands unreduced (5 - 2)")


# ------------------------------------------------------------------ feint (setup_debuff)

func test_feint_collapses_targets_next_action() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"position": [0, 0]})
	add_human(sim, "mark", {"position": [1, 0]})
	# tick 0: feint (cost 1 instant) — no damage; flags the mark.
	var declared: Array[Dictionary] = declare(sim, "trick", {
		"kind": "skill", "key": "feint", "level": 1, "attack_range": 1,
		"targets": [{"id": "mark", "part": "torso"}],
	})
	assert_event(declared, "action_declared", "feint declared")
	var resolved: Array[Dictionary] = advance(sim)
	assert_event(resolved, "feint_applied", "feint resolves onto the mark")
	var mark: CombatantState = sim.combatants["mark"]
	assert_true(mark.feint_forced, "the mark is feint-forced")
	# tick 1: the mark's next scheduled action collapses into a Forced Action – Tool.
	declare(sim, "mark", attack_action("crushed", 3, "trick", "torso"))
	var collapse: Array[Dictionary] = advance(sim)
	var invalidated: Dictionary = assert_event(collapse, "action_invalidated", "the feinted action collapses")
	assert_eq(String(invalidated.get("reason", "")), "feinted", "collapse reason is 'feinted'")
	var forced: Dictionary = assert_event(collapse, "forced_action_triggered", "it becomes a Forced Action")
	assert_eq(String(forced.get("table", "")), "tool", "the Tool d6 table")
	assert_eq(String(forced.get("reason", "")), "feinted", "the forced roll is tagged feinted")
	assert_false(mark.feint_forced, "the flag clears after the collapse (only the NEXT action)")
	# The mark's crush never landed (only a possible 1-pt Tool collateral can touch trick).
	var trick: CombatantState = sim.combatants["trick"]
	assert_true(int(trick.parts["torso"]["hp"]) >= 4, "trick's torso did not take the 3-dmg strike")


# ------------------------------------------------------------ pressure_strike (conditional_followup)

func test_pressure_strike_shock_when_feinted() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "duelist", {"position": [0, 0]})
	add_dummy(sim, "mark", [1, 0])
	# Feint the mark first (leaves feint_forced pending — the mark never acts).
	declare(sim, "duelist", {
		"kind": "skill", "key": "feint", "level": 1, "attack_range": 1,
		"targets": [{"id": "mark", "part": "torso"}],
	})
	advance(sim)
	var mark: CombatantState = sim.combatants["mark"]
	assert_true(mark.feint_forced, "the mark is feint-forced")
	# pressure_strike is a cost-2 windup; resolves 2 ticks after declare.
	declare(sim, "duelist", {
		"kind": "skill", "key": "pressure_strike", "level": 1, "attack_range": 1,
		"targets": [{"id": "mark", "part": "torso"}],
	})
	advance(sim, 2)
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "pressure_bonus_shock", "the Shock rider fires while the feint pends")
	assert_eq(mark.shock, 1, "Shock T1 applied to the feinted target")
	assert_true(int(mark.parts["torso"]["hp"]) < 50, "the Bleed strike also landed (50 -> 48)")


func test_pressure_strike_no_shock_without_feint() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "duelist", {"position": [0, 0]})
	add_dummy(sim, "mark", [1, 0])
	declare(sim, "duelist", {
		"kind": "skill", "key": "pressure_strike", "level": 1, "attack_range": 1,
		"targets": [{"id": "mark", "part": "torso"}],
	})
	advance(sim, 2)
	var ev: Array[Dictionary] = advance(sim)
	assert_no_event(ev, "pressure_bonus_shock", "no bonus without a pending feint")
	var mark: CombatantState = sim.combatants["mark"]
	assert_eq(mark.shock, 0, "no Shock applied")
	assert_true(int(mark.parts["torso"]["hp"]) < 50, "the Bleed strike still landed")


# ------------------------------------------------------------------ dance (self_stance)

func test_dance_stance_and_ends_on_declaring_attack() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "star", {"position": [0, 0]})
	add_dummy(sim, "foe", [1, 0])
	var declared: Array[Dictionary] = declare(sim, "star", {"kind": "skill", "key": "dance", "level": 1})
	assert_event(declared, "action_declared", "dance declared as a free action")
	var resolved: Array[Dictionary] = advance(sim)
	assert_event(resolved, "dance_started", "the stance begins on resolve")
	var star: CombatantState = sim.combatants["star"]
	assert_true(star.dancing, "star is dancing")
	assert_eq(star.dance_charm_bonus(), 1, "+1 Charm effect while dancing (Lv1)")
	# Committing to an attack ends the stance at declare time.
	var atk: Array[Dictionary] = declare(sim, "star", attack_action("crushed", 1, "foe", "torso"))
	assert_event(atk, "dance_ended", "declaring an attack ends the dance")
	assert_false(star.dancing, "the stance is cleared")
	assert_eq(star.dance_charm_bonus(), 0, "no bonus once the stance ends")


func test_dance_ends_when_hit() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "star", {"position": [0, 0]})
	add_human(sim, "brute", {"position": [1, 0]})
	declare(sim, "star", {"kind": "skill", "key": "dance", "level": 2})
	advance(sim)
	var star: CombatantState = sim.combatants["star"]
	assert_true(star.dancing, "dancing")
	assert_eq(star.dance_charm_bonus(), 2, "Lv2 dance grants +2 Charm effect")
	# Taking a hit ends the stance.
	declare(sim, "brute", attack_action("crushed", 2, "star", "torso"))
	var hit: Array[Dictionary] = advance(sim)
	assert_event(hit, "dance_ended", "being hit ends the dance")
	assert_false(star.dancing, "the stance is cleared by the hit")
	assert_eq(star.dance_charm_bonus(), 0, "the accessor reports no bonus")


# ------------------------------------------------------------- committed_strike (slam / strike)

func test_overhead_slam_knocks_prone_and_deals_crush() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "smasher", {"position": [0, 0]})
	add_dummy(sim, "foe", [1, 0])
	var declared: Array[Dictionary] = declare(sim, "smasher", {
		"kind": "skill", "key": "overhead_slam", "level": 1, "attack_range": 1,
		"targets": [{"id": "foe", "part": "torso"}],
	})
	var decl: Dictionary = assert_event(declared, "action_declared", "overhead_slam is a windup")
	assert_true(bool(decl.get("windup", false)), "cost-2 skill is a windup")
	var smasher: CombatantState = sim.combatants["smasher"]
	assert_true(smasher.exposed_until_tick > 0, "the actor is Exposed during the windup")
	var foe: CombatantState = sim.combatants["foe"]
	assert_false(bool(foe.statuses.get("prone", false)), "foe is standing before the hit")
	advance(sim, 2)
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "action_resolved", "the slam resolves at its tick")
	assert_eq(int(foe.parts["torso"]["hp"]), 47, "3 Crush at Lv1 (50 -> 47)")
	assert_event(ev, "knocked_prone", "a standing target is knocked Prone on a landed hit")
	assert_true(bool(foe.statuses.get("prone", false)), "foe is now Prone")


func test_strong_strike_deals_typed_damage() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "bruiser", {"position": [0, 0]})
	add_dummy(sim, "foe", [1, 0])
	declare(sim, "bruiser", {
		"kind": "skill", "key": "strong_strike", "level": 1, "attack_range": 1,
		"targets": [{"id": "foe", "part": "torso"}],
	})
	advance(sim, 2)
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "action_resolved", "strong_strike resolves")
	var foe: CombatantState = sim.combatants["foe"]
	assert_eq(int(foe.parts["torso"]["hp"]), 44, "6 Crush landed (50 -> 44)")
	# No knockdown rider on strong_strike.
	assert_no_event(ev, "knocked_prone", "strong_strike does not knock down")


# ------------------------------------------------------------------ serialization round-trip

func test_serialization_roundtrip_preserves_skill_state() -> void:
	var sim: CombatSim = make_sim(9090)
	add_human(sim, "dancer", {"position": [0, 0]})
	add_human(sim, "guard", {"position": [1, 0]})
	add_human(sim, "trick", {"position": [0, 1]})
	# tick 0: dancer dances (Lv3), guard braces (Lv2) — both free self actions.
	declare(sim, "dancer", {"kind": "skill", "key": "dance", "level": 3})
	declare(sim, "guard", {"kind": "skill", "key": "brace", "level": 2})
	advance(sim)
	var dancer: CombatantState = sim.combatants["dancer"]
	var guard: CombatantState = sim.combatants["guard"]
	assert_true(dancer.dancing, "dancer is dancing pre-serialize")
	assert_eq(guard.brace_guard, 2, "guard buffered pre-serialize")
	# tick 1: trick feints the dancer (feint_forced on the dancer; it never acts).
	declare(sim, "trick", {
		"kind": "skill", "key": "feint", "level": 1, "attack_range": 1,
		"targets": [{"id": "dancer", "part": "torso"}],
	})
	advance(sim)
	assert_true(dancer.feint_forced, "dancer is feint-forced pre-serialize")
	assert_true(dancer.dancing, "dancer is still dancing (feint does not hit it)")
	# Round-trip.
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), sim.state_hash(), "full-state hash survives to_dict -> from_dict")
	var r_dancer: CombatantState = restored.combatants["dancer"]
	var r_guard: CombatantState = restored.combatants["guard"]
	assert_true(r_dancer.dancing, "dancing preserved")
	assert_eq(r_dancer.dance_charm, 3, "dance_charm preserved (Lv3)")
	assert_eq(r_dancer.dance_charm_bonus(), 3, "accessor works after restore")
	assert_true(r_dancer.feint_forced, "feint_forced preserved")
	assert_eq(r_guard.brace_guard, 2, "brace_guard preserved")
