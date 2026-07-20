extends SimTestBase
## Priming gate (rules-addendum R3, decision-log #20 — "cooldowns do not exist").
## Skills gate on one of five canonical, requirement-shaped PRIMES, enforced at
## declare by ActionResolver._prime_unmet. One test per predicate plus a
## serialization round-trip over the new CombatantState fields.
##   CHAIN          — actor's last resolved action key must equal `after`
##   STANCE         — actor must hold the named stance (set_stance command)
##   STACK          — actor must have >= N of a resource (camera-call stacks / charges)
##   STATE-POSITION — the named combatant (self|target) must have a status
##   PREP-CHANNEL   — actor must have an armed prime; using it consumes the prime
## Deterministic (fixed seeds, no wall-clock; the fallback strike path uses RNG
## only via the existing ForcedAction stream, which these declares never trip).


# ------------------------------------------------------------------ CHAIN

func test_chain_prime_requires_prior_action_key() -> void:
	var sim: CombatSim = make_sim(101)
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	var chained: Dictionary = {
		"kind": "skill", "cost": 1, "key": "follow_up",
		"prime": {"type": "chain", "after": "opener"},
		"attack_range": 1, "damage": {"type": "crushed", "amount": 1},
		"targets": [{"id": "b", "part": "torso"}],
	}
	# No "opener" has resolved yet -> the chain is unmet.
	var early: Array[Dictionary] = declare(sim, "a", chained.duplicate(true))
	assert_rejected(early, "prime_unmet", "CHAIN needs the prior action key")
	# Resolve an "opener" so last_action_key becomes "opener".
	declare(sim, "a", {"kind": "skill", "cost": 1, "key": "opener"})
	advance(sim)
	var a: CombatantState = sim.combatants["a"]
	assert_eq(a.last_action_key, "opener", "a resolved action sets last_action_key")
	var ok: Array[Dictionary] = declare(sim, "a", chained.duplicate(true))
	assert_event(ok, "action_declared", "CHAIN satisfied once the opener has resolved")
	# A different resolved action clears the chain (last_action_key overwritten).
	advance(sim)  # resolves follow_up -> last_action_key = "follow_up"
	assert_eq(a.last_action_key, "follow_up", "a non-matching action overwrites the key")
	var stale: Array[Dictionary] = declare(sim, "a", chained.duplicate(true))
	assert_rejected(stale, "prime_unmet", "the chain no longer points at 'opener'")


# ------------------------------------------------------------------ STANCE

func test_stance_prime_requires_held_stance() -> void:
	var sim: CombatSim = make_sim(102)
	add_human(sim, "a", {"position": [0, 0]})
	var action: Dictionary = {
		"kind": "skill", "cost": 1, "key": "riposte",
		"prime": {"type": "stance", "stance": "defensive"},
	}
	var no: Array[Dictionary] = declare(sim, "a", action.duplicate(true))
	assert_rejected(no, "prime_unmet", "no stance held -> STANCE unmet")
	var set_ev: Array[Dictionary] = sim.apply_command({"type": "set_stance", "actor": "a", "stance": "defensive"})
	assert_event(set_ev, "stance_changed", "set_stance records the stance")
	var yes: Array[Dictionary] = declare(sim, "a", action.duplicate(true))
	assert_event(yes, "action_declared", "the held stance satisfies the STANCE prime")
	advance(sim)
	# Clearing the stance re-locks the skill.
	sim.apply_command({"type": "set_stance", "actor": "a", "stance": ""})
	var cleared: Array[Dictionary] = declare(sim, "a", action.duplicate(true))
	assert_rejected(cleared, "prime_unmet", "clearing the stance re-locks the skill")


# ------------------------------------------------------------------ STACK

func test_stack_prime_requires_resource_count() -> void:
	var sim: CombatSim = make_sim(103)
	# Charm 30 -> over_cap(30, 20) = floor(20/20) = 1 camera-call stack (R6).
	add_human(sim, "a", {"position": [0, 0],
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 30}})
	var a: CombatantState = sim.combatants["a"]
	assert_eq(int(a.derived_stats().get("camera_call_stacks", 0)), 1, "Charm 30 -> 1 camera-call stack")
	var one: Dictionary = {"kind": "skill", "cost": 1, "key": "spotlight_move",
		"prime": {"type": "stack", "resource": "camera_call", "count": 1}}
	assert_event(declare(sim, "a", one.duplicate(true)), "action_declared", "1 stack satisfies count 1 (camera_call reuses the Charm stacks)")
	advance(sim)
	var two: Dictionary = {"kind": "skill", "cost": 1, "key": "spotlight_move",
		"prime": {"type": "stack", "resource": "camera_call", "count": 2}}
	assert_rejected(declare(sim, "a", two.duplicate(true)), "prime_unmet", "only 1 stack -> count 2 is unmet")
	# Generic `charges` fallback for a non-camera-call resource.
	a.charges["combo_meter"] = 3
	advance(sim)
	var meter: Dictionary = {"kind": "skill", "cost": 1, "key": "meter_burn",
		"prime": {"type": "stack", "resource": "combo_meter", "count": 3}}
	assert_event(declare(sim, "a", meter.duplicate(true)), "action_declared", "3 charges satisfies count 3 (generic fallback)")
	advance(sim)
	var too_much: Dictionary = {"kind": "skill", "cost": 1, "key": "meter_burn",
		"prime": {"type": "stack", "resource": "combo_meter", "count": 4}}
	assert_rejected(declare(sim, "a", too_much.duplicate(true)), "prime_unmet", "3 charges -> count 4 is unmet")


# ------------------------------------------------------------------ STATE-POSITION

func test_state_prime_requires_target_status() -> void:
	var sim: CombatSim = make_sim(104)
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	var action: Dictionary = {
		"kind": "skill", "cost": 1, "key": "exploit_opening",
		"prime": {"type": "state", "who": "target", "status": "prone"},
		"attack_range": 1, "damage": {"type": "crushed", "amount": 1},
		"targets": [{"id": "b", "part": "torso"}],
	}
	var standing: Array[Dictionary] = declare(sim, "a", action.duplicate(true))
	assert_rejected(standing, "prime_unmet", "STATE unmet while the target is not Prone")
	sim.apply_command({"type": "set_status", "target": "b", "status": "prone", "value": true})
	var prone: Array[Dictionary] = declare(sim, "a", action.duplicate(true))
	assert_event(prone, "action_declared", "a Prone target satisfies the STATE prime")


# ------------------------------------------------------------------ PREP-CHANNEL

func test_prep_prime_arms_then_consumes() -> void:
	var sim: CombatSim = make_sim(105)
	add_human(sim, "a", {"position": [0, 0]})
	add_human(sim, "b", {"position": [1, 0]})
	var action: Dictionary = {
		"kind": "skill", "cost": 1, "key": "unleash",
		"prime": {"type": "prep", "key": "charge"},
		"attack_range": 1, "damage": {"type": "crushed", "amount": 1},
		"targets": [{"id": "b", "part": "torso"}],
	}
	assert_rejected(declare(sim, "a", action.duplicate(true)), "prime_unmet", "not primed -> PREP unmet")
	var armed: Array[Dictionary] = sim.apply_command({"type": "prime", "actor": "a", "key": "charge"})
	assert_event(armed, "prime_armed", "the prime is armed")
	var a: CombatantState = sim.combatants["a"]
	assert_true(bool(a.armed_primes.get("charge", false)), "armed_primes carries the key")
	assert_event(declare(sim, "a", action.duplicate(true)), "action_declared", "an armed prep prime lets the action through")
	advance(sim)  # resolves -> consumes the prime
	assert_false(bool(a.armed_primes.get("charge", false)), "resolving the prep-gated action consumed the prime")
	assert_rejected(declare(sim, "a", action.duplicate(true)), "prime_unmet", "the consumed prime re-locks the gate")


# ------------------------------------------------------------------ serialization

func test_serialization_roundtrip_preserves_prime_state() -> void:
	var sim: CombatSim = make_sim(4242)
	add_human(sim, "a", {"position": [0, 0]})
	var a: CombatantState = sim.combatants["a"]
	sim.apply_command({"type": "set_stance", "actor": "a", "stance": "aggressive"})
	sim.apply_command({"type": "prime", "actor": "a", "key": "overload"})
	a.charges["combo_meter"] = 5
	# Resolve a keyed action so last_action_key is populated (jab has no prep prime,
	# so the armed "overload" stays armed).
	declare(sim, "a", {"kind": "skill", "cost": 1, "key": "jab"})
	advance(sim)
	assert_eq(a.last_action_key, "jab", "last_action_key set by the resolved jab")
	assert_true(bool(a.armed_primes.get("overload", false)), "overload still armed (jab did not consume it)")
	# Round-trip.
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), sim.state_hash(), "full-state hash survives to_dict -> from_dict")
	var r: CombatantState = restored.combatants["a"]
	assert_eq(r.stance, "aggressive", "stance preserved")
	assert_true(bool(r.armed_primes.get("overload", false)), "armed_primes preserved")
	assert_eq(int(r.charges.get("combo_meter", 0)), 5, "charges preserved")
	assert_eq(r.last_action_key, "jab", "last_action_key preserved")
