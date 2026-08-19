extends SimTestBase
## Cross-character CHAIN (owner-approved 2026-08-19; every design detail is
## PROVISIONAL pending owner sign-off — see ActionResolver._teammate_chain_met
## and the rules-addendum R3 amendment). A CHAIN prime [after:X] is now met if
## EITHER the actor's own record satisfies it (clause 1 — the pre-change
## predicate, untouched) OR some OTHER combatant on the SAME TEAM last resolved
## X (or a key that chain-aliases to X) against the SAME target the declare
## names (clause 2). Real specs exercised: pounce -> slip_through (batch A),
## predators_arc's "chain_as": "pounce" seat (tier-2 wave 3), overhead_slam ->
## shockwave (batch A, targetless follower). Coverage: teammate same-target
## opens / different target does not / enemy does not (team gate, contrast
## twins) / alias via teammate / actor-local chain untouched (regression) /
## a DEAD teammate's opener still counts / a teammate's chain_open_key is NOT
## consulted (actor-local waiver) / self- or target-less actions never open a
## cross-chain / teamless actors have no teammates / twin-rng zero-draw proof /
## serialization round-trip mid-cross-chain / determinism / a chain-free fight
## pinned hash-identical to the pre-change engine.


## A non-dodging Elite (Mind 0: no reads; no dodge_threshold: no dodge stream).
func add_elite(sim: CombatSim, id: String, pos: Array, extra: Dictionary = {}) -> void:
	var spec: Dictionary = {
		"id": id, "name": id, "category": "Elite", "size": "Large",
		"team": "enemies", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3},
		"body_parts": [
			{"key": "head", "hp": 50, "lethal": true},
			{"key": "torso", "hp": 50, "lethal": true},
			{"key": "left_arm", "hp": 50, "lethal": false},
			{"key": "right_arm", "hp": 50, "lethal": false},
			{"key": "left_leg", "hp": 50, "lethal": false},
			{"key": "right_leg", "hp": 50, "lethal": false},
		],
	}
	spec.merge(extra, true)
	sim.apply_command({"type": "add_combatant", "combatant": spec})


## A small Mob (probe fodder): torso + one leg.
func add_mob(sim: CombatSim, id: String, pos: Array) -> void:
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "category": "Mob", "size": "Medium",
		"team": "enemies", "position": pos,
		"traits": {"physique": 2, "reflexes": 1, "mind": 1, "charm": 1},
		"body_parts": [
			{"key": "torso", "hp": 10, "lethal": true},
			{"key": "left_leg", "hp": 6, "lethal": false},
		]}})


func add_party(sim: CombatSim, id: String, pos: Array, physique: int = 3) -> void:
	add_human(sim, id, {"team": "party", "position": pos,
		"traits": {"physique": physique, "reflexes": 3, "mind": 3, "charm": 3}})


func pounce_declare(sim: CombatSim, actor: String, target: String, leap_to: Array) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "pounce", "level": 1,
		"leap_to": leap_to, "targets": [{"id": target, "part": "torso"}]})


func slip_declare(sim: CombatSim, actor: String, target: String) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": target}]})


func arc_declare(sim: CombatSim, actor: String, target: String, leap_to: Array, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "predators_arc", "level": level,
		"leap_to": leap_to, "targets": [{"id": target, "part": "torso"}]})


# ============================================= clause 2: the teammate handoff

## The core combo fantasy (PROVISIONAL design): ally A pounces the boss, ally B
## — who never pounced — follows up with slip_through on the SAME boss. Also
## pins: only RESOLVED openers count (a mid-windup pounce opens nothing), and
## the whole handoff needs no new serialized state (round-trip mid-open).
func test_teammate_same_target_opens_chain() -> void:
	var sim: CombatSim = make_sim(7701)
	add_party(sim, "a", [0, 0])
	add_party(sim, "b", [3, 1])
	add_elite(sim, "prey", [3, 0])
	# Before anything resolves, b's chain is unmet.
	assert_rejected(slip_declare(sim, "b", "prey"), "prime_unmet",
		"no opener anywhere -> the chain is unmet")
	var opened: Array[Dictionary] = pounce_declare(sim, "a", "prey", [2, 0])
	assert_event(opened, "action_declared", "a's pounce declares (cost-2 windup)")
	# A DECLARED-but-unresolved opener opens nothing: last_action_key is
	# written at resolution, and clause 2 reads the same field.
	assert_rejected(slip_declare(sim, "b", "prey"), "prime_unmet",
		"a mid-windup pounce has not HAPPENED yet — no cross-chain")
	advance(sim, 3)
	var a: CombatantState = sim.combatants["a"]
	assert_eq(a.last_action_key, "pounce", "the opener's record: key")
	assert_eq(a.last_action_target, "prey", "the opener's record: target")
	# No new state: the handoff survives a serialization round-trip.
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "hash survives the mid-open round-trip")
	for s: CombatSim in [sim, restored]:
		assert_event(slip_declare(s, "b", "prey"), "action_declared",
			"the teammate's resolved pounce on the same target opens b's slip_through")
		assert_event(advance(s), "slip_through_reposition",
			"the follow-up actually RESOLVED — a real slip, not just a declare")
	assert_eq(restored.state_hash(), sim.state_hash(), "restore -> replay tail = same hash")
	var b: CombatantState = sim.combatants["b"]
	assert_eq(b.last_action_key, "slip_through", "b's record now carries the follow-up")


## Same-target constraint (PROVISIONAL): a teammate's opener on a DIFFERENT
## target does not open the chain — the handoff is same-boss only.
func test_teammate_different_target_does_not_open() -> void:
	var sim: CombatSim = make_sim(7702)
	add_party(sim, "a", [0, 0])
	add_party(sim, "b", [5, 1])
	add_elite(sim, "prey", [3, 0])
	add_elite(sim, "prey2", [5, 0])
	pounce_declare(sim, "a", "prey", [2, 0])
	advance(sim, 3)
	assert_eq((sim.combatants["a"] as CombatantState).last_action_target, "prey",
		"precondition: the opener hit prey")
	assert_rejected(slip_declare(sim, "b", "prey2"), "prime_unmet",
		"a's pounce on prey does not open b's slip_through on prey2")
	# (The shared-target acceptance contrast lives in
	# test_teammate_same_target_opens_chain — same layout, target prey.)


## Team gate (PROVISIONAL: strict team equality): an ENEMY's opener never opens
## a party chain. Contrast twins — identical layout, only the opener's team
## differs — pin that the team line is the one doing the rejecting.
func test_enemy_opener_does_not_open() -> void:
	for opener_team: String in ["enemies", "party"]:
		var sim: CombatSim = make_sim(7703)
		add_human(sim, "x", {"team": opener_team, "position": [1, 0]})
		add_human(sim, "p", {"team": "party", "position": [2, 1]})
		add_human(sim, "victim", {"team": "victims", "position": [2, 0]})
		declare(sim, "x", {"kind": "skill", "cost": 1, "key": "opener", "attack_range": 1,
			"damage": {"type": "crushed", "amount": 1}, "targets": [{"id": "victim", "part": "torso"}]})
		advance(sim)
		assert_eq((sim.combatants["x"] as CombatantState).last_action_key, "opener",
			"precondition (%s): the opener resolved" % opener_team)
		var follow: Array[Dictionary] = declare(sim, "p", {"kind": "skill", "cost": 1,
			"key": "follow_up", "prime": {"type": "chain", "after": "opener"},
			"attack_range": 1, "damage": {"type": "crushed", "amount": 1},
			"targets": [{"id": "victim", "part": "torso"}]})
		if opener_team == "enemies":
			assert_rejected(follow, "prime_unmet", "an enemy's opener opens nothing for the party")
		else:
			assert_event(follow, "action_declared", "the SAME layout with a party opener goes through")


## Team-symmetry (PROVISIONAL): the predicate is team-agnostic — an enemy-team
## pair chains exactly like a party pair (the AI does not exploit this yet;
## future AI hook, enemy_ai.gd untouched).
func test_enemy_team_pair_chains_too() -> void:
	var sim: CombatSim = make_sim(7708)
	add_human(sim, "m1", {"team": "enemies", "position": [1, 0]})
	add_human(sim, "m2", {"team": "enemies", "position": [2, 1]})
	add_human(sim, "hero", {"team": "party", "position": [2, 0]})
	declare(sim, "m1", {"kind": "skill", "cost": 1, "key": "opener", "attack_range": 1,
		"damage": {"type": "crushed", "amount": 1}, "targets": [{"id": "hero", "part": "torso"}]})
	advance(sim)
	assert_event(declare(sim, "m2", {"kind": "skill", "cost": 1, "key": "follow_up",
		"prime": {"type": "chain", "after": "opener"}, "attack_range": 1,
		"damage": {"type": "crushed", "amount": 1},
		"targets": [{"id": "hero", "part": "torso"}]}), "action_declared",
		"mobs chain off mobs — the predicate is team-symmetric")


## Teamless actors (PROVISIONAL, the hype_surge precedent): a "" team has no
## teammates — "" == "" never matches, so two teamless humans cannot cross-chain.
func test_teamless_actor_has_no_teammates() -> void:
	var sim: CombatSim = make_sim(7709)
	add_human(sim, "x", {"position": [1, 0]})       # team "" (add_human default)
	add_human(sim, "p", {"position": [2, 1]})       # team ""
	add_human(sim, "victim", {"position": [2, 0]})  # team ""
	declare(sim, "x", {"kind": "skill", "cost": 1, "key": "opener", "attack_range": 1,
		"damage": {"type": "crushed", "amount": 1}, "targets": [{"id": "victim", "part": "torso"}]})
	advance(sim)
	assert_rejected(declare(sim, "p", {"kind": "skill", "cost": 1, "key": "follow_up",
		"prime": {"type": "chain", "after": "opener"}, "attack_range": 1,
		"damage": {"type": "crushed", "amount": 1},
		"targets": [{"id": "victim", "part": "torso"}]}), "prime_unmet",
		"a teamless actor has no party to chain off (the hype_surge precedent)")


# ==================================================== alias + actor-local bits

## The ruling-#4 chain seat rides clause 2 (PROVISIONAL): a teammate's
## predators_arc ("chain_as": "pounce") counts as Pounce for b's slip_through —
## on the SHARED target only. And the S2-b chain-open marker stays ACTOR-LOCAL
## (PROVISIONAL): the opener's own L2 waiver never widens a TEAMMATE's targets.
func test_chain_alias_via_teammate() -> void:
	var sim: CombatSim = make_sim(7704)
	add_party(sim, "sasha", [0, 0])
	add_party(sim, "b", [3, 1])
	add_elite(sim, "prey", [3, 0])
	add_elite(sim, "prey2", [4, 2])
	arc_declare(sim, "sasha", "prey", [4, 0], 2)  # L2: sets sasha's chain_open_key
	advance(sim, 3)
	var sasha: CombatantState = sim.combatants["sasha"]
	assert_eq(sasha.last_action_key, "predators_arc", "the REAL key is recorded (never 'pounce')")
	assert_eq(sasha.chain_open_key, "predators_arc", "precondition: sasha's own chain-open is live")
	# The teammate's chain_open_key is NOT consulted: b on a different target
	# still rejects, even while sasha's own waiver is live.
	assert_rejected(slip_declare(sim, "b", "prey2"), "prime_unmet",
		"sasha's chain-open waiver is sasha's alone — b's cross-chain stays same-target")
	# The alias itself carries the handoff on the shared target.
	assert_event(slip_declare(sim, "b", "prey"), "action_declared",
		"teammate's predators_arc counts as pounce (chain_as) for b's slip_through")


## Regression: clause 1 — the actor's OWN chain — is untouched, teammates
## present or not. Same-target still enforced actor-locally when no teammate
## record matches the declared target.
func test_actor_own_chain_untouched() -> void:
	var sim: CombatSim = make_sim(7705)
	add_party(sim, "a", [0, 0])
	add_party(sim, "helper", [6, 1])
	add_elite(sim, "prey", [3, 0])
	add_elite(sim, "prey2", [6, 0])
	# helper resolves an unrelated plain attack on prey2 (records no useful key).
	declare(sim, "helper", attack_action("crushed", 1, "prey2", "torso"))
	pounce_declare(sim, "a", "prey", [2, 0])
	advance(sim, 3)
	# a's own pounce -> a's own slip_through on the same target: clause 1, as ever.
	assert_event(slip_declare(sim, "a", "prey"), "action_declared",
		"the actor's own chain works exactly as before")
	advance(sim)
	# After the slip resolves, a's chain no longer points at pounce and nobody's
	# record matches prey2 with key pounce — both clauses honestly unmet.
	assert_rejected(slip_declare(sim, "a", "prey2"), "prime_unmet",
		"no record anywhere opens prey2 — the widened predicate is not a bypass")


## Opener's life state (PROVISIONAL: ignored — the action HAPPENED): a DEAD
## teammate's opener still opens the chain.
func test_downed_teammate_opener_still_counts() -> void:
	var sim: CombatSim = make_sim(7706)
	add_party(sim, "a", [0, 0])
	add_party(sim, "b", [3, 1])
	add_elite(sim, "prey", [3, 0])
	add_elite(sim, "eb", [1, 0])
	pounce_declare(sim, "a", "prey", [2, 0])
	advance(sim, 3)
	# eb kills the opener (torso 5, lethal; no dodge stream on a plain human).
	declare(sim, "eb", attack_action("crushed", 20, "a", "torso"))
	advance(sim)
	var a: CombatantState = sim.combatants["a"]
	assert_false(a.alive, "precondition: the opener is dead")
	assert_eq(a.last_action_key, "pounce", "the record survives the death")
	assert_event(slip_declare(sim, "b", "prey"), "action_declared",
		"the dead teammate's pounce still opens b's slip_through (the action happened)")


## Concrete-shared-target constraint (PROVISIONAL): target-less actions on
## EITHER side never cross-chain. Generic half: a target-less opener records
## last_action_target "" and opens nothing. Real-skill half: shockwave declares
## a cone (no "targets"), so a teammate's overhead_slam cannot open it — while
## the actor's OWN slam still can (clause 1 needs no target row).
func test_targetless_actions_never_cross_chain() -> void:
	# A self/target-less opener opens nothing for teammates.
	var sim: CombatSim = make_sim(7707)
	add_human(sim, "x", {"team": "party", "position": [1, 0]})
	add_human(sim, "p", {"team": "party", "position": [2, 1]})
	add_human(sim, "victim", {"team": "enemies", "position": [2, 0]})
	declare(sim, "x", {"kind": "skill", "cost": 1, "key": "opener"})  # no targets
	advance(sim)
	assert_eq((sim.combatants["x"] as CombatantState).last_action_target, "",
		"precondition: the target-less opener recorded no target")
	assert_rejected(declare(sim, "p", {"kind": "skill", "cost": 1, "key": "follow_up",
		"prime": {"type": "chain", "after": "opener"}, "attack_range": 1,
		"damage": {"type": "crushed", "amount": 1},
		"targets": [{"id": "victim", "part": "torso"}]}), "prime_unmet",
		"a target-less opener cannot anchor a cross-chain")
	# A target-less FOLLOWER cannot lean on a teammate either: shockwave.
	var sim2: CombatSim = make_sim(7710)
	add_party(sim2, "bruiser", [0, 0])
	add_party(sim2, "waver", [0, 1])
	add_elite(sim2, "victim", [1, 0])
	declare(sim2, "bruiser", {"kind": "skill", "key": "overhead_slam", "level": 1,
		"targets": [{"id": "victim", "part": "torso"}]})
	advance(sim2, 3)
	assert_eq((sim2.combatants["bruiser"] as CombatantState).last_action_key, "overhead_slam",
		"precondition: the teammate's slam resolved")
	assert_rejected(declare(sim2, "waver", {"kind": "skill", "key": "shockwave", "level": 1,
		"area_shape": {"toward": [1, 0]}}), "prime_unmet",
		"shockwave names no target row — no concrete shared target, no cross-chain")
	# Contrast: the slammer's OWN shockwave (clause 1) still needs no target row.
	assert_event(declare(sim2, "bruiser", {"kind": "skill", "key": "shockwave", "level": 1,
		"area_shape": {"toward": [1, 0]}}), "action_declared",
		"the actor-local chain never needed a target row — unchanged")


# ============================================ determinism / rng / hash pins

## Twin-rng: the cross-chain predicate reads state only — twin B runs a full
## teammate handoff (pounce -> cross slip_through), twin A idles; the next
## Forced Action draw is the SAME stream value in both twins (zero rng impact).
func test_cross_chain_twin_rng_no_new_draws() -> void:
	var twin_a: CombatSim = make_sim(7801)
	var twin_b: CombatSim = make_sim(7801)
	for twin: CombatSim in [twin_a, twin_b]:
		add_party(twin, "a", [0, 0])
		add_party(twin, "b", [3, 1])
		add_party(twin, "weakling", [7, 0], 2)  # physique 2 — the grapple probe's underdog
		add_elite(twin, "prey", [3, 0])
		add_elite(twin, "eb", [8, 0])
	pounce_declare(twin_b, "a", "prey", [2, 0])
	for twin: CombatSim in [twin_a, twin_b]:
		advance(twin, 3)
	assert_event(slip_declare(twin_b, "b", "prey"), "action_declared",
		"precondition: twin B actually exercised the cross-chain")
	for twin: CombatSim in [twin_a, twin_b]:
		advance(twin)
	for twin: CombatSim in [twin_a, twin_b]:
		declare(twin, "weakling", {"kind": "grapple", "target": "eb"})
	var roll_a: int = int(assert_event(advance(twin_a), "forced_action_triggered", "twin A probe").get("roll", -1))
	var roll_b: int = int(assert_event(advance(twin_b), "forced_action_triggered", "twin B probe").get("roll", -2))
	assert_eq(roll_a, roll_b, "identical stream draw — the cross-chain consumed zero rng")


## Same (seed, command log) = same hash with cross-chains in the log.
func test_cross_chain_determinism_same_log_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(7802)
		add_party(sim, "a", [0, 0])
		add_party(sim, "b", [3, 1])
		add_elite(sim, "prey", [3, 0])
		add_mob(sim, "m", [4, 1])
		pounce_declare(sim, "a", "prey", [2, 0])
		advance(sim, 3)
		slip_declare(sim, "b", "prey")
		advance(sim, 2)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash with a cross-chain")


## A full fight that never touches a chain prime hashes byte-identically to the
## PRE-CHANGE engine: the pinned value below was captured by running this exact
## (seed, command log) on the baseline worktree (commit 8853e34, before the
## cross-chain predicate landed). The predicate change added no state, no rng
## draws and no serialization changes — so the pin must hold forever unless a
## FUTURE change deliberately touches fight state (in which case re-pin with
## the same two-engine capture and say so in the commit).
func test_no_chain_fight_hash_pinned() -> void:
	var sim: CombatSim = make_sim(7801)
	add_human(sim, "a", {"team": "party", "position": [1, 0]})
	add_human(sim, "b", {"team": "party", "position": [2, 1]})
	add_elite(sim, "e", [2, 0])
	add_mob(sim, "m", [3, 0])
	declare(sim, "a", {"kind": "skill", "key": "overhead_slam", "level": 1,
		"targets": [{"id": "e", "part": "torso"}]})
	declare(sim, "b", {"kind": "attack", "cost": 1, "damage": {"type": "crushed", "amount": 2},
		"attack_range": 1, "targets": [{"id": "m", "part": "torso"}]})
	advance(sim, 3)
	declare(sim, "b", {"kind": "attack", "cost": 1, "damage": {"type": "bleeding", "amount": 1},
		"attack_range": 1, "targets": [{"id": "e", "part": "left_arm"}]})
	advance(sim, 2)
	sim.apply_command({"type": "move", "actor": "a", "to": [1, 1]})
	advance(sim, 2)
	assert_eq(sim.state_hash(),
		"3126ecebf0084571927eceeb5d9a03f1298a6ca4c84544cc3cdc335a23a85b57",
		"chain-free fight = byte-identical state vs the pre-change engine")
