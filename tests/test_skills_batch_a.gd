extends SimTestBase
## Content pass batch A — chains & strikes (docs/design/skills-r19-ladders-FINAL.md).
## Nine encoded skills: the pounce→slip_through→decapitate chain (size gate,
## REAR-ARC reposition + Exposed rider + the not_behind_target gate — the R30
## facing retrofit, decision #33, retiring the interim F5 far-side/Exposed
## approximation; head-gate bypass, cinematic_kill spectacle scoring), the
## overhead_slam→shockwave→
## execution chain (cone membership + slam-victim exclusion, knockback
## wall-stop, Forced Body on Mobs, the Prone|Helpless gate + Shock T3 rider),
## thousand_cuts (multi-part declare + the all-3-bleeding tier payoff),
## controlled_sweep (adjacency gate, Mob-only expansion, merged-force
## non-interference), slice_n_dice (the G8 math, pinned), heroic_punch (the
## Exposed-Head Shock rider + POW beat). Plus: every chain rejects out of
## sequence, determinism, and a serialization round-trip mid-chain.
## All magnitudes asserted here are the PLACEHOLDER (R14) numbers the SkillBook
## authors — the assertions pin structure + the current placeholder table.
## Deterministic: fixed seeds; rng touched only via ForcedAction where stated.


## A non-dodging Elite (Mind 0: feint-reads impossible; no dodge_threshold: no
## dodge stream). `extra` merges over the spec (size, parts, position, team).
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


## A small Mob (the shockwave / sweep fodder): torso + one leg.
func add_mob(sim: CombatSim, id: String, pos: Array) -> void:
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "category": "Mob", "size": "Medium",
		"team": "enemies", "position": pos,
		"traits": {"physique": 2, "reflexes": 1, "mind": 1, "charm": 1},
		"body_parts": [
			{"key": "torso", "hp": 10, "lethal": true},
			{"key": "left_leg", "hp": 6, "lethal": false},
		],
	}})


func add_party(sim: CombatSim, id: String, pos: Array, physique: int = 3) -> void:
	add_human(sim, id, {"team": "party", "position": pos,
		"traits": {"physique": physique, "reflexes": 3, "mind": 3, "charm": 3}})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


# ================================================= chain 1: pounce → slip → decapitate

## Stages sasha (Medium) vs a Large elite 3 hexes out; head HP parameterized so
## the L1 decapitate (net 3) exactly kills or plainly wounds.
func _chain_one_sim(head_hp: int) -> CombatSim:
	var sim: CombatSim = make_sim(4801)
	add_party(sim, "sasha", [0, 0])
	add_elite(sim, "prey", [3, 0], {"body_parts": [
		{"key": "head", "hp": head_hp, "lethal": true},
		{"key": "torso", "hp": 50, "lethal": true},
		{"key": "left_leg", "hp": 50, "lethal": false},
		{"key": "right_leg", "hp": 50, "lethal": false},
	]})
	return sim


func test_chain_one_full_to_cinematic_kill() -> void:
	var sim: CombatSim = _chain_one_sim(3)
	var sasha: CombatantState = sim.combatants["sasha"]
	var prey: CombatantState = sim.combatants["prey"]
	# Out of sequence: slip_through before any pounce rejects on the prime.
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": "prey"}]}), "prime_unmet", "slip_through without pounce rejects")
	# t0: pounce — leap 2 hexes to [2,0], torso strike; a cost-2 windup.
	var declared: Array[Dictionary] = declare(sim, "sasha", {
		"kind": "skill", "key": "pounce", "level": 1, "leap_to": [2, 0],
		"targets": [{"id": "prey", "part": "torso"}],
	})
	var decl: Dictionary = assert_event(declared, "action_declared", "pounce declares")
	assert_true(bool(decl.get("windup", false)), "pounce is a cost-2 windup")
	var ev: Array[Dictionary] = advance(sim, 3)
	var leap: Dictionary = assert_event(ev, "pounce_leap", "the leap lands at resolution")
	assert_eq(leap.get("to", []), [2, 0], "landed on the declared hex")
	assert_eq(sasha.position, Vector2i(2, 0), "movement absorbed into the action")
	assert_eq(int(prey.parts["torso"]["hp"]), 48, "2 Bleed: Force 2+1 − Robustness 1 = 2 (50 → 48)")
	assert_eq(prey.condition_tier("torso", "bleeding"), 1, "the torso Bleed rides the landed hit")
	assert_eq(sasha.last_action_key, "pounce", "chain key recorded")
	assert_eq(sasha.last_action_target, "prey", "chain target recorded")
	# Out of sequence: decapitate straight after pounce rejects (needs slip_through).
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "decapitate", "level": 1,
		"targets": [{"id": "prey", "part": "head"}]}), "prime_unmet", "decapitate without slip_through rejects")
	# slip_through: leg cuts + far-side reposition + Exposed rider (F5 approximation).
	var slipped: Array[Dictionary] = declare(sim, "sasha", {
		"kind": "skill", "key": "slip_through", "level": 1, "targets": [{"id": "prey"}],
	})
	assert_event(slipped, "action_declared", "the chained slip_through declares (cost 1)")
	var ev2: Array[Dictionary] = advance(sim)
	assert_eq(events_of(ev2, "damage_applied").size(), 2, "one cut per leg")
	assert_eq(int(prey.parts["left_leg"]["hp"]), 49, "1 Bleed per leg: Force 1+1 − 1 = 1")
	assert_eq(int(prey.parts["right_leg"]["hp"]), 49, "both legs cut")
	assert_eq(prey.condition_tier("left_leg", "bleeding"), 1, "leg Bleed T1")
	assert_eq(prey.condition_tier("right_leg", "bleeding"), 1, "leg Bleed T1")
	var repos: Dictionary = assert_event(ev2, "slip_through_reposition", "the rear-arc reposition happened")
	# R30 retrofit: prey staged facing W (toward sasha), so directly-behind =
	# facing+3 = E = [4,0] — the REAL rear arc, no longer the F5 far-side
	# approximation (which lands the same hex in this head-on geometry).
	assert_eq(repos.get("to", []), [4, 0], "directly behind prey (facing W -> rear E) from [2,0] is [4,0]")
	assert_eq(sasha.position, Vector2i(4, 0), "actor stands behind the target")
	assert_true(Stealth.is_behind(prey, sasha.position), "the destination is IN the target's rear arc (R30)")
	assert_event(ev2, "slip_through_exposed", "the Exposed rider is an attributed event")
	assert_true(prey.exposed_cache, "the target is Exposed for the finisher window")
	# decapitate: bypass-gated head slash; head 3 → 0 = the cinematic kill.
	var decap: Array[Dictionary] = declare(sim, "sasha", {
		"kind": "skill", "key": "decapitate", "level": 1,
		"targets": [{"id": "prey", "part": "head"}],
	})
	assert_event(decap, "action_declared", "the chained decapitate declares (cost 1)")
	var ev3: Array[Dictionary] = advance(sim)
	assert_eq(int(prey.parts["head"]["hp"]), 0, "3 Head Bleed: Force 3+1 − 1 = 3 (3 → 0)")
	var died: Dictionary = assert_event(ev3, "combatant_died", "Head → 0 is the normal lethal path")
	assert_eq(String(died.get("killer", "")), "sasha", "the kill is attributed")
	var cine: Dictionary = assert_event(ev3, "cinematic_kill", "the cinematic-kill beat fires")
	assert_eq(String(cine.get("actor", "")), "sasha", "attributed to the killer")
	assert_eq(int(cine.get("spectacle_points", 0)), 45, "authored payout rides the event (PLACEHOLDER R14)")
	assert_true(int(sim.hype.ledger.get("sasha", 0)) >= 45,
		"the payout scored through the HypeEngine spectacle_points hook")


func test_chain_one_gates() -> void:
	# Same-target: pounce on prey does NOT open slip_through on another body.
	var sim: CombatSim = _chain_one_sim(50)
	add_elite(sim, "bystander", [1, 0], {"size": "Large"})
	declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1, "leap_to": [2, 0],
		"targets": [{"id": "prey", "part": "torso"}]})
	advance(sim, 3)
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": "bystander"}]}), "prime_unmet", "slip_through on a different target rejects (same-target gate)")
	# Size gate: a same-size (Medium) chain target rejects at declare.
	var sim2: CombatSim = make_sim(4811)
	add_party(sim2, "sasha", [0, 0])
	add_elite(sim2, "runt", [1, 0], {"size": "Medium"})
	declare(sim2, "sasha", {"kind": "skill", "key": "pounce", "level": 1,
		"targets": [{"id": "runt", "part": "torso"}]})
	advance(sim2, 3)
	assert_rejected(declare(sim2, "sasha", {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": "runt"}]}), "target_not_larger", "the size gate reads size_rank, at least one size larger")
	# Exposure gate: chain intact but the Exposed window lapsed → decapitate rejects.
	var sim3: CombatSim = _chain_one_sim(50)
	declare(sim3, "sasha", {"kind": "skill", "key": "pounce", "level": 1, "leap_to": [2, 0],
		"targets": [{"id": "prey", "part": "torso"}]})
	advance(sim3, 3)
	declare(sim3, "sasha", {"kind": "skill", "key": "slip_through", "level": 1, "targets": [{"id": "prey"}]})
	advance(sim3)
	advance(sim3)  # idle past the Exposed window (until_tick lapses)
	var prey3: CombatantState = sim3.combatants["prey"]
	assert_false(prey3.exposed_cache, "precondition: the opening closed")
	assert_eq((sim3.combatants["sasha"] as CombatantState).last_action_key, "slip_through",
		"precondition: the chain key itself is still live")
	assert_rejected(declare(sim3, "sasha", {"kind": "skill", "key": "decapitate", "level": 1,
		"targets": [{"id": "prey", "part": "head"}]}), "target_not_exposed",
		"the STATE half of the finisher gate is enforced at declare")


func test_decapitate_rejects_from_the_front_arc() -> void:
	# The R30 retrofit's other half (decision #33): the ladder's "positioned
	# behind" is REAL — exposure alone no longer opens the finisher. Chain +
	# Exposed both live, but sasha walks around to the target's FRONT arc
	# (prey faces W; [2,0] is its front-W hex) -> not_behind_target.
	var sim: CombatSim = _chain_one_sim(50)
	declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1, "leap_to": [2, 0],
		"targets": [{"id": "prey", "part": "torso"}]})
	advance(sim, 3)
	declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1, "targets": [{"id": "prey"}]})
	advance(sim)
	var prey: CombatantState = sim.combatants["prey"]
	assert_true(prey.exposed_cache, "precondition: the Exposed window is open")
	assert_eq((sim.combatants["sasha"] as CombatantState).last_action_key, "slip_through",
		"precondition: the chain is live")
	move(sim, "sasha", [2, 0])  # a free move never clears the chain bookkeeping
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "decapitate", "level": 1,
		"targets": [{"id": "prey", "part": "head"}]}), "not_behind_target",
		"Exposed + chain intact, but the actor stands in the FRONT arc — the real gate rejects")


func test_slip_through_prefers_a_flanking_rear_hex_when_directly_behind_is_blocked() -> void:
	# The documented rear-arc scan order: directly behind (facing+3) first,
	# then facing+2, then facing+4 — a body on [4,0] pushes the slip onto the
	# SE rear flank [3,1], still behind, and the finisher still fires from it.
	var sim: CombatSim = _chain_one_sim(3)
	add_elite(sim, "blocker", [4, 0], {})
	var sasha: CombatantState = sim.combatants["sasha"]
	var prey: CombatantState = sim.combatants["prey"]
	declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1, "leap_to": [2, 0],
		"targets": [{"id": "prey", "part": "torso"}]})
	advance(sim, 3)
	declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1, "targets": [{"id": "prey"}]})
	var ev: Array[Dictionary] = advance(sim)
	var repos: Dictionary = assert_event(ev, "slip_through_reposition", "the reposition still happens")
	assert_eq(repos.get("to", []), [3, 1], "blocked directly-behind -> the facing+2 rear flank (SE of prey)")
	assert_eq(sasha.position, Vector2i(3, 1), "actor stands on the rear flank")
	assert_true(Stealth.is_behind(prey, sasha.position), "the flank hex is still IN the rear arc")
	# The finisher accepts from the flank (rear-arc, not just directly-behind).
	declare(sim, "sasha", {"kind": "skill", "key": "decapitate", "level": 1,
		"targets": [{"id": "prey", "part": "head"}]})
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "cinematic_kill", "the rear-flank finisher fires — the whole retrofit chain holds")


func test_decapitate_without_kill_has_no_cinematic_beat() -> void:
	var sim: CombatSim = _chain_one_sim(50)
	declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1, "leap_to": [2, 0],
		"targets": [{"id": "prey", "part": "torso"}]})
	advance(sim, 3)
	declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1, "targets": [{"id": "prey"}]})
	advance(sim)
	declare(sim, "sasha", {"kind": "skill", "key": "decapitate", "level": 1,
		"targets": [{"id": "prey", "part": "head"}]})
	var ev: Array[Dictionary] = advance(sim)
	var prey: CombatantState = sim.combatants["prey"]
	assert_eq(int(prey.parts["head"]["hp"]), 47, "the head slash wounds (50 → 47)")
	assert_true(prey.alive, "no kill on a healthy head")
	assert_no_event(ev, "cinematic_kill", "no cinematic beat without the Head kill")


func test_bypass_head_gate_is_a_data_driven_action_flag() -> void:
	# The audit's one-line flag on the shared attack gate (the R26 undodgable
	# trust model: hand-built commands may carry it; decapitate's spec does).
	var sim: CombatSim = make_sim(4812)
	add_party(sim, "a", [0, 0])
	add_elite(sim, "t", [1, 0])
	var head_attack: Dictionary = attack_action("bleeding", 1, "t", "head")
	assert_rejected(declare(sim, "a", head_attack.duplicate(true)), "head_not_targetable",
		"the head gate holds for a plain attack on an unexposed target")
	var bypassed: Dictionary = attack_action("bleeding", 1, "t", "head", {"bypass_head_gate": true})
	assert_event(declare(sim, "a", bypassed), "action_declared", "the flag opens the same declare")


# ============================================ chain 2: slam → shockwave → execution

## Stages imani adjacent to the slam victim with two Mobs in the eastward cone.
## offset shifts every hex (the arena variant needs non-negative coordinates).
func _chain_two_sim(sim_seed: int, offset: Vector2i = Vector2i.ZERO) -> CombatSim:
	var sim: CombatSim = make_sim(sim_seed)
	add_party(sim, "imani", [offset.x, offset.y], 5)
	add_elite(sim, "victim", [offset.x + 1, offset.y])
	add_mob(sim, "mob_a", [offset.x + 2, offset.y])
	add_mob(sim, "mob_b", [offset.x + 2, offset.y - 1])
	return sim


func _run_slam(sim: CombatSim, offset: Vector2i = Vector2i.ZERO) -> Array[Dictionary]:
	declare(sim, "imani", {"kind": "skill", "key": "overhead_slam", "level": 1,
		"attack_range": 1, "targets": [{"id": "victim", "part": "torso"}]})
	var _mid: Array[Dictionary] = advance(sim, 2)
	var ev: Array[Dictionary] = advance(sim)
	var shock_declared: Array[Dictionary] = declare(sim, "imani", {
		"kind": "skill", "key": "shockwave", "level": 1,
		"area_shape": {"kind": "cone", "toward": [1, 0]},
	})
	assert_event(shock_declared, "action_declared", "the chained shockwave declares (cost 1)")
	ev.append_array(advance(sim))
	return ev


func test_chain_two_shockwave_cone_knockback_and_forced_body() -> void:
	var sim: CombatSim = _chain_two_sim(4820)
	var ev: Array[Dictionary] = _run_slam(sim)
	var victim: CombatantState = sim.combatants["victim"]
	assert_true(bool(victim.statuses.get("prone", false)), "the slam knocked the victim Prone")
	assert_eq(int(victim.parts["torso"]["hp"]), 46, "slam: Force 3+2 − 1 = 4 (50 → 46)")
	# Cone membership: both Mobs caught; the slam victim EXCLUDED (authored L1
	# core — and load-bearing: shoving them would break Execution's adjacency).
	# The cone strikes, pinned via events (final HP would also fold in each
	# Mob's own Forced-Body consequence — e.g. tear_something's 1 dmg).
	var mob_a: CombatantState = sim.combatants["mob_a"]
	for id: String in ["mob_a", "mob_b"]:
		var wave_hit: bool = false
		for event: Dictionary in ev:
			if String(event.get("type", "")) == "damage_applied" \
					and String(event.get("combatant", "")) == id \
					and String(event.get("part", "")) == "left_leg" \
					and String(event.get("source", "")) == "weapon" \
					and int(event.get("amount", -1)) == 2:
				wave_hit = true
		assert_true(wave_hit, "%s: cone Crush to the legs — Force 1+2 − 1 = 2" % id)
	var knocks: Array[Dictionary] = events_of(ev, "knocked_back")
	assert_eq(knocks.size(), 2, "each connected Mob is knocked back 1 hex — never the excluded victim")
	for knock: Dictionary in knocks:
		assert_true(bool(knock.get("displaced", false)), "open ground: both shoves displace")
		assert_ne(String(knock.get("combatant", "")), "victim", "the slam victim is never shoved")
	assert_eq(victim.position, Vector2i(1, 0), "the victim holds the finisher-adjacent hex")
	assert_eq(int(victim.parts["left_leg"]["hp"]), 50, "no cone damage on the excluded victim")
	for knock: Dictionary in knocks:
		assert_eq(knock.get("from", [])[1], knock.get("to", [])[1],
			"the eastward shove keeps r (E push: [q+1, r]) — direction is the away ray")
	# Mobs caught roll Forced Action – Body (the existing rng stream).
	var forced: Array[Dictionary] = events_of(ev, "forced_action_triggered")
	var body_rolls: int = 0
	for f: Dictionary in forced:
		if String(f.get("table", "")) == "body" and String(f.get("reason", "")) == "shockwave":
			body_rolls += 1
	assert_eq(body_rolls, 2, "each caught Mob rolled Forced Action – Body")
	# No prone from the knockback (the ladder says knockback, not knockdown).
	assert_false(bool(mob_a.statuses.get("prone", false)) and _mob_prone_from_knockback(ev, "mob_a"),
		"knockback implies no prone (a Forced-Body consequence may, separately)")


## Was mob knocked prone BY the knockback itself (it never is — prone can only
## arrive via a Forced-Body consequence, a separate attributed event)?
func _mob_prone_from_knockback(events: Array[Dictionary], id: String) -> bool:
	for event: Dictionary in events:
		if String(event.get("type", "")) == "knocked_prone" \
				and String(event.get("combatant", "")) == id \
				and String(event.get("skill", "")) == "shockwave":
			return true
	return false


func test_shockwave_knockback_stops_at_walls() -> void:
	var sim: CombatSim = _chain_two_sim(4821, Vector2i(5, 5))
	sim.apply_command({"type": "set_arena", "arena": {
		"bounds": {"width": 20, "height": 20},
		"walls": [[8, 5]],
	}})
	var ev: Array[Dictionary] = _run_slam(sim, Vector2i(5, 5))
	var knocks: Array[Dictionary] = events_of(ev, "knocked_back")
	assert_eq(knocks.size(), 2, "both Mobs still connected")
	var mob_a: CombatantState = sim.combatants["mob_a"]
	for knock: Dictionary in knocks:
		if String(knock.get("combatant", "")) == "mob_a":
			assert_false(bool(knock.get("displaced", true)), "the wall at [8,5] stops mob_a's shove")
			assert_eq(knock.get("to", []), [7, 5], "no displacement — to == from")
	assert_eq(mob_a.position, Vector2i(7, 5), "wall-stop is occupation/wall-honest")
	var mob_b: CombatantState = sim.combatants["mob_b"]
	assert_eq(mob_b.position, Vector2i(8, 4), "the open-lane Mob still flies 1 hex east")


func test_chain_two_execution_torso_shock_and_head_kill() -> void:
	var sim: CombatSim = _chain_two_sim(4822)
	_run_slam(sim)
	# Torso finisher: Shock T3 rider.
	var declared: Array[Dictionary] = declare(sim, "imani", {"kind": "skill", "key": "execution",
		"level": 1, "targets": [{"id": "victim", "part": "torso"}]})
	assert_event(declared, "action_declared", "the chained execution declares (cost 2)")
	var ev: Array[Dictionary] = advance(sim, 3)
	var victim: CombatantState = sim.combatants["victim"]
	assert_eq(int(victim.parts["torso"]["hp"]), 41, "execution: Force 4+2 − 1 = 5 (46 → 41)")
	var rider: Dictionary = assert_event(ev, "execution_shock", "the Torso rider is attributed")
	assert_eq(int(rider.get("tier", 0)), 3, "Shock T3 (Faint)")
	assert_eq(victim.shock, 3, "the victim faints")
	assert_true(victim.is_helpless(sim.clock.tick), "T3 Faint = Helpless for the Clock")
	# Head finisher on a fresh chain: the normal lethal path, no cinematic beat.
	var sim2: CombatSim = _chain_two_sim(4823)
	(sim2.combatants["victim"] as CombatantState).parts["head"]["hp"] = 5
	_run_slam(sim2)
	declare(sim2, "imani", {"kind": "skill", "key": "execution", "level": 1,
		"targets": [{"id": "victim", "part": "head"}]})
	var ev2: Array[Dictionary] = advance(sim2, 3)
	var victim2: CombatantState = sim2.combatants["victim"]
	assert_false(victim2.alive, "Head 5 − net 5 = 0: instant death (normal lethal path)")
	var died: Dictionary = assert_event(ev2, "combatant_died", "the kill happened")
	assert_eq(String(died.get("killer", "")), "imani", "attributed")
	assert_no_event(ev2, "cinematic_kill", "the cinematic beat is decapitate's, not execution's")


func test_execution_gates_and_stand_up_escape() -> void:
	# STATE gate: chain met, target standing → rejected at declare.
	var sim: CombatSim = _chain_two_sim(4824)
	declare(sim, "imani", {"kind": "skill", "key": "overhead_slam", "level": 1,
		"attack_range": 1, "targets": [{"id": "mob_a", "part": "torso"}]})
	advance(sim, 3)
	declare(sim, "imani", {"kind": "skill", "key": "shockwave", "level": 1,
		"area_shape": {"kind": "cone", "toward": [1, 0]}})
	advance(sim)
	assert_rejected(declare(sim, "imani", {"kind": "skill", "key": "execution", "level": 1,
		"targets": [{"id": "victim", "part": "torso"}]}), "target_not_downed",
		"a standing target rejects the finisher at declare")
	# Stand-up mid-windup: the premise breaks and the windup collapses.
	var sim2: CombatSim = _chain_two_sim(4825)
	_run_slam(sim2)
	declare(sim2, "imani", {"kind": "skill", "key": "execution", "level": 1,
		"targets": [{"id": "victim", "part": "torso"}]})
	declare(sim2, "victim", {"kind": "stand", "cost": 1})
	advance(sim2, 2)
	var ev: Array[Dictionary] = advance(sim2)
	var invalidated: Dictionary = assert_event(ev, "action_invalidated", "the finisher premise broke")
	assert_eq(String(invalidated.get("reason", "")), "target_not_downed", "standing up escapes the execution")
	assert_event(ev, "forced_action_triggered", "the standard windup collapse (Forced Tool)")
	var victim2: CombatantState = sim2.combatants["victim"]
	assert_eq(int(victim2.parts["torso"]["hp"]), 46, "no execution damage landed")


func test_chains_reject_out_of_sequence() -> void:
	var sim: CombatSim = make_sim(4826)
	add_party(sim, "a", [0, 0], 5)
	add_elite(sim, "t", [1, 0])
	sim.apply_command({"type": "set_status", "target": "t", "status": "prone", "value": true})
	assert_rejected(declare(sim, "a", {"kind": "skill", "key": "shockwave", "level": 1,
		"area_shape": {"kind": "cone", "toward": [1, 0]}}), "prime_unmet", "shockwave needs overhead_slam")
	assert_rejected(declare(sim, "a", {"kind": "skill", "key": "execution", "level": 1,
		"targets": [{"id": "t", "part": "torso"}]}), "prime_unmet", "execution needs shockwave (even vs a Prone target)")
	assert_rejected(declare(sim, "a", {"kind": "skill", "key": "thousand_cuts", "level": 1,
		"targets": [{"id": "t", "part": "torso"}, {"id": "t", "part": "left_arm"}, {"id": "t", "part": "right_arm"}]}),
		"prime_unmet", "thousand_cuts needs pressure_strike")
	assert_rejected(declare(sim, "a", {"kind": "skill", "key": "slip_through", "level": 1,
		"targets": [{"id": "t"}]}), "prime_unmet", "slip_through needs pounce")
	assert_rejected(declare(sim, "a", {"kind": "skill", "key": "decapitate", "level": 1,
		"targets": [{"id": "t", "part": "head"}]}), "prime_unmet", "decapitate needs slip_through")


# ============================================================= thousand_cuts

func _flurry_sim(pre_bleed_all: bool) -> CombatSim:
	var sim: CombatSim = make_sim(4830)
	add_party(sim, "duelist", [0, 0])
	add_elite(sim, "mark", [1, 0], {"size": "Medium"})
	if pre_bleed_all:
		for part: String in ["torso", "left_arm", "right_arm"]:
			sim.apply_command({"type": "apply_condition", "target": "mark",
				"part": part, "condition": "bleeding", "tier": 1})
	# The chain, honestly: feint (t0) → pressure_strike on a LEG (keeps the
	# flurry's three parts clean of the pressure Bleed) → resolves tick 3.
	declare(sim, "duelist", {"kind": "skill", "key": "feint", "level": 1,
		"attack_range": 1, "targets": [{"id": "mark", "part": "torso"}]})
	advance(sim)
	declare(sim, "duelist", {"kind": "skill", "key": "pressure_strike", "level": 1,
		"attack_range": 1, "targets": [{"id": "mark", "part": "left_leg"}]})
	advance(sim, 3)
	return sim


func test_thousand_cuts_multi_part_declare_and_validation() -> void:
	var sim: CombatSim = _flurry_sim(false)
	# Shape gates.
	assert_rejected(declare(sim, "duelist", {"kind": "skill", "key": "thousand_cuts", "level": 1,
		"targets": [{"id": "mark", "part": "torso"}, {"id": "mark", "part": "left_arm"}]}),
		"three_parts_required", "two rows are not a flurry")
	assert_rejected(declare(sim, "duelist", {"kind": "skill", "key": "thousand_cuts", "level": 1,
		"targets": [{"id": "mark", "part": "torso"}, {"id": "mark", "part": "torso"}, {"id": "mark", "part": "left_arm"}]}),
		"distinct_parts_required", "duplicate parts are not three chosen parts")
	# The real flurry: 3 parts, 1 Bleed each; NOT all pre-bleeding → no payoff.
	var declared: Array[Dictionary] = declare(sim, "duelist", {"kind": "skill", "key": "thousand_cuts", "level": 1,
		"targets": [{"id": "mark", "part": "torso"}, {"id": "mark", "part": "left_arm"}, {"id": "mark", "part": "right_arm"}]})
	assert_event(declared, "action_declared", "the chained flurry declares (cost 2)")
	var ev: Array[Dictionary] = advance(sim, 3)
	var mark: CombatantState = sim.combatants["mark"]
	assert_eq(events_of(ev, "damage_applied").size(), 3, "three separate cuts")
	assert_eq(int(mark.parts["torso"]["hp"]), 49, "1 Bleed per cut: Force 1+1 − 1 = 1")
	assert_eq(mark.condition_tier("torso", "bleeding"), 1, "fresh Bleed on a clean part")
	assert_eq(mark.condition_tier("left_arm", "bleeding"), 1, "fresh Bleed")
	assert_no_event(ev, "thousand_cuts_tier_advance", "no payoff unless ALL 3 parts already bled")
	assert_event(ev, "thousand_cuts_reposition", "the post-flurry reposition is surfaced")


func test_thousand_cuts_all_bleeding_payoff_advances_tiers() -> void:
	var sim: CombatSim = _flurry_sim(true)
	declare(sim, "duelist", {"kind": "skill", "key": "thousand_cuts", "level": 1,
		"targets": [{"id": "mark", "part": "torso"}, {"id": "mark", "part": "left_arm"}, {"id": "mark", "part": "right_arm"}]})
	var ev: Array[Dictionary] = advance(sim, 3)
	var mark: CombatantState = sim.combatants["mark"]
	var payoff: Dictionary = assert_event(ev, "thousand_cuts_tier_advance", "all-3-bleeding payoff fires")
	assert_eq(String(payoff.get("actor", "")), "duelist", "attributed")
	assert_eq((payoff.get("parts", []) as Array).size(), 3, "all three parts named")
	# T1 seed + the engine-standard reapply advance (+1) + the authored payoff
	# (+1) = T3 on every struck part.
	assert_eq(mark.condition_tier("torso", "bleeding"), 3, "T1 → T2 (reapply) → T3 (payoff)")
	assert_eq(mark.condition_tier("left_arm", "bleeding"), 3, "same ladder on each part")
	assert_eq(mark.condition_tier("right_arm", "bleeding"), 3, "same ladder on each part")


# =========================================================== controlled_sweep

func test_controlled_sweep_gate_and_mob_only_expansion() -> void:
	var sim: CombatSim = make_sim(4840)
	add_party(sim, "sweeper", [0, 0])
	add_mob(sim, "m1", [1, 0])
	add_mob(sim, "m2", [0, 1])
	add_mob(sim, "m3", [1, -1])
	add_elite(sim, "e", [-1, 0], {"traits": {"physique": 4, "reflexes": 3, "mind": 0, "charm": 3}})
	# Mob-only rows; the sweep never merges; damage must come from somewhere.
	assert_rejected(declare(sim, "sweeper", {"kind": "skill", "key": "controlled_sweep", "level": 1,
		"damage": {"type": "crushed", "amount": 2},
		"targets": [{"id": "m1", "part": "torso"}, {"id": "e", "part": "torso"}]}),
		"target_not_mob", "an Elite in the rows rejects (Mob-only below the L6 rung)")
	assert_rejected(declare(sim, "sweeper", {"kind": "skill", "key": "controlled_sweep", "level": 1,
		"combo_id": "x", "damage": {"type": "crushed", "amount": 2},
		"targets": [{"id": "m1", "part": "torso"}]}),
		"sweep_cannot_merge", "separate single-target strikes never merge (R15)")
	assert_rejected(declare(sim, "sweeper", {"kind": "skill", "key": "controlled_sweep", "level": 1,
		"targets": [{"id": "m1", "part": "torso"}]}),
		"no_damage_source", "no weapon and no action damage = nothing to swing")
	# The sweep: 3 Mobs, 3 separate strikes, one declare.
	var ev_declared: Array[Dictionary] = declare(sim, "sweeper", {"kind": "skill", "key": "controlled_sweep",
		"level": 1, "damage": {"type": "crushed", "amount": 2},
		"targets": [{"id": "m1", "part": "torso"}, {"id": "m2", "part": "torso"}, {"id": "m3", "part": "torso"}]})
	assert_event(ev_declared, "action_declared", "the sweep declares (cost 1)")
	var ev: Array[Dictionary] = advance(sim)
	assert_eq(events_of(ev, "damage_applied").size(), 3, "one separate strike per Mob")
	for id: String in ["m1", "m2", "m3"]:
		assert_eq(int((sim.combatants[id] as CombatantState).parts["torso"]["hp"]), 8,
			"%s: Force 2+1 − 1 = 2 (10 → 8)" % id)
	var resolved: Dictionary = assert_event(ev, "action_resolved", "one action, many strikes")
	assert_eq(int(resolved.get("rounds", 0)), 3, "three rounds in the one declare")


func test_controlled_sweep_adjacency_floor() -> void:
	var sim: CombatSim = make_sim(4841)
	add_party(sim, "sweeper", [0, 0])
	add_mob(sim, "m1", [1, 0])
	add_mob(sim, "m_far", [5, 5])
	assert_rejected(declare(sim, "sweeper", {"kind": "skill", "key": "controlled_sweep", "level": 1,
		"damage": {"type": "crushed", "amount": 2}, "targets": [{"id": "m1", "part": "torso"}]}),
		"needs_two_adjacent_mobs", "the >= 2 adjacent Mobs floor is declare validation")


func test_controlled_sweep_does_not_disturb_merged_force() -> void:
	var sim: CombatSim = make_sim(4842)
	add_party(sim, "sweeper", [0, 0])
	add_mob(sim, "m1", [1, 0])
	add_mob(sim, "m2", [0, 1])
	add_elite(sim, "e", [-1, 0], {"traits": {"physique": 4, "reflexes": 3, "mind": 0, "charm": 3}})
	add_human(sim, "p1", {"team": "party", "position": [-1, -1],
		"traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	add_human(sim, "p2", {"team": "party", "position": [-2, 1],
		"traits": {"physique": 4, "reflexes": 3, "mind": 3, "charm": 3}})
	# Same tick: the pair's merged combo on the Elite + the sweep on the Mobs.
	sim.apply_command({"type": "combined_action", "combo_id": "pair", "members": [
		{"actor": "p1", "action": attack_action("crushed", 3, "e", "torso")},
		{"actor": "p2", "action": attack_action("crushed", 3, "e", "torso")},
	]})
	declare(sim, "sweeper", {"kind": "skill", "key": "controlled_sweep", "level": 1,
		"damage": {"type": "crushed", "amount": 2},
		"targets": [{"id": "m1", "part": "torso"}, {"id": "m2", "part": "torso"}]})
	var ev: Array[Dictionary] = advance(sim)
	var cf: Dictionary = assert_event(ev, "combined_force", "the pair's merge still fires")
	assert_eq(int(cf.get("force", -1)), 10, "merged Force (3+2)+(3+2) = 10 — the sweep contributed nothing")
	assert_eq(int(cf.get("net", -1)), 8, "net = 10 − Robustness 2")
	assert_eq(cf.get("actors", []), ["p1", "p2"], "only the linked pair merged")
	assert_eq(int((sim.combatants["m1"] as CombatantState).parts["torso"]["hp"]), 8, "sweep strike 1 landed solo")
	assert_eq(int((sim.combatants["m2"] as CombatantState).parts["torso"]["hp"]), 8, "sweep strike 2 landed solo")


# ============================================================== slice_n_dice

## The G8 math, pinned per mode (slicer Physique 3 → Force amount+1; target
## Robustness 1). Each mode runs on a fresh sim so tier reapplies never blur
## the pinned amounts.
func _slice_sim() -> CombatSim:
	var sim: CombatSim = make_sim(4850)
	add_party(sim, "slicer", [0, 0])
	add_elite(sim, "v1", [1, 0], {"size": "Medium"})
	add_elite(sim, "v2", [0, 1], {"size": "Medium"})
	return sim


func _slice(sim: CombatSim, rows: Array) -> Array[Dictionary]:
	var declared: Array[Dictionary] = declare(sim, "slicer", {
		"kind": "skill", "key": "slice_n_dice", "level": 1, "targets": rows})
	assert_event(declared, "action_declared", "the crossing arc declares")
	return advance(sim, 3)


func test_slice_n_dice_g8_math_pinned() -> void:
	# Single target, two limbs: 2 Bleed to EACH of two limbs.
	var sim: CombatSim = _slice_sim()
	var ev: Array[Dictionary] = _slice(sim, [{"id": "v1", "part": "left_arm"}, {"id": "v1", "part": "right_arm"}])
	var v1: CombatantState = sim.combatants["v1"]
	assert_eq(int(v1.parts["left_arm"]["hp"]), 48, "limb mode: 2 Bleed → Force 3 − 1 = 2 per limb")
	assert_eq(int(v1.parts["right_arm"]["hp"]), 48, "both limbs cut")
	assert_eq(events_of(ev, "damage_applied").size(), 2, "two strikes in the arc")
	assert_eq(v1.condition_tier("left_arm", "bleeding"), 1, "Bleed rides each landed cut")
	# Single target, torso: OR 3 Bleed to the Torso.
	var sim2: CombatSim = _slice_sim()
	_slice(sim2, [{"id": "v1", "part": "torso"}])
	assert_eq(int((sim2.combatants["v1"] as CombatantState).parts["torso"]["hp"]), 47,
		"torso mode: 3 Bleed → Force 4 − 1 = 3")
	# Two adjacent targets, one limb each: 2 Bleed to one limb on each.
	var sim3: CombatSim = _slice_sim()
	_slice(sim3, [{"id": "v1", "part": "left_arm"}, {"id": "v2", "part": "left_arm"}])
	assert_eq(int((sim3.combatants["v1"] as CombatantState).parts["left_arm"]["hp"]), 48, "pair-limb: 2 each")
	assert_eq(int((sim3.combatants["v2"] as CombatantState).parts["left_arm"]["hp"]), 48, "pair-limb: 2 each")
	# Two adjacent targets, torsos: OR 1 Bleed to each Torso.
	var sim4: CombatSim = _slice_sim()
	_slice(sim4, [{"id": "v1", "part": "torso"}, {"id": "v2", "part": "torso"}])
	assert_eq(int((sim4.combatants["v1"] as CombatantState).parts["torso"]["hp"]), 49, "pair-torso: 1 each")
	assert_eq(int((sim4.combatants["v2"] as CombatantState).parts["torso"]["hp"]), 49, "pair-torso: 1 each")


func test_slice_n_dice_rejects_shapes_outside_g8() -> void:
	var sim: CombatSim = _slice_sim()
	assert_rejected(declare(sim, "slicer", {"kind": "skill", "key": "slice_n_dice", "level": 1,
		"targets": [{"id": "v1", "part": "torso"}, {"id": "v1", "part": "left_arm"}]}),
		"invalid_arc_shape", "torso + limb on one target is not a G8 mode")
	assert_rejected(declare(sim, "slicer", {"kind": "skill", "key": "slice_n_dice", "level": 1,
		"targets": [{"id": "v1", "part": "head"}]}), "invalid_arc_shape", "a lone head row is not a G8 mode")
	assert_rejected(declare(sim, "slicer", {"kind": "skill", "key": "slice_n_dice", "level": 1,
		"targets": [{"id": "v1", "part": "left_arm"}, {"id": "v1", "part": "right_arm"}, {"id": "v2", "part": "left_arm"}]}),
		"invalid_arc_shape", "three rows are not a crossing arc")


# ============================================================== heroic_punch

func test_heroic_punch_exposed_head_shock_rider_and_pow() -> void:
	var sim: CombatSim = make_sim(4860)
	add_party(sim, "mario", [0, 0])
	add_elite(sim, "foe", [1, 0], {"size": "Medium"})
	# The head gate holds — no bypass on the punch.
	assert_rejected(declare(sim, "mario", {"kind": "skill", "key": "heroic_punch", "level": 1,
		"targets": [{"id": "foe", "part": "head"}]}), "head_not_targetable",
		"an unexposed head is closed to the punch")
	# Prone → Exposed → the Head opens, the rider fires.
	sim.apply_command({"type": "set_status", "target": "foe", "status": "prone", "value": true})
	declare(sim, "mario", {"kind": "skill", "key": "heroic_punch", "level": 1,
		"targets": [{"id": "foe", "part": "head"}]})
	var ev: Array[Dictionary] = advance(sim)
	var foe: CombatantState = sim.combatants["foe"]
	assert_eq(int(foe.parts["head"]["hp"]), 48, "committed unarmed Crush: Force 2+1 − 1 = 2")
	var pow_event: Dictionary = assert_event(ev, "heroic_punch_pow", "the POW beat fires on a landed Head hit")
	assert_eq(String(pow_event.get("actor", "")), "mario", "attributed")
	assert_eq(int(pow_event.get("spectacle_points", 0)), 20, "authored payout (PLACEHOLDER R14)")
	assert_event(ev, "heroic_punch_shock", "the Shock rider fires vs an Exposed target's Head")
	assert_eq(foe.shock, 1, "Shock T1 (rattle)")
	assert_true(int(sim.hype.ledger.get("mario", 0)) >= 20, "the POW payout scored through the hype hook")


func test_heroic_punch_no_riders_off_the_head_or_off_exposure() -> void:
	var sim: CombatSim = make_sim(4861)
	add_party(sim, "mario", [0, 0])
	add_elite(sim, "foe", [1, 0], {"size": "Medium"})
	# Torso hit: damage only.
	declare(sim, "mario", {"kind": "skill", "key": "heroic_punch", "level": 1,
		"targets": [{"id": "foe", "part": "torso"}]})
	var ev: Array[Dictionary] = advance(sim)
	assert_eq(int((sim.combatants["foe"] as CombatantState).parts["torso"]["hp"]), 48, "the Crush lands")
	assert_no_event(ev, "heroic_punch_pow", "no POW beat off the Head")
	assert_no_event(ev, "heroic_punch_shock", "no Shock rider off the Head")
	# Overwhelmed (head-legal but NOT Exposed): POW yes, Shock no — the rider
	# asks Exposed specifically.
	sim.apply_command({"type": "set_status", "target": "foe", "status": "overwhelmed", "value": true})
	declare(sim, "mario", {"kind": "skill", "key": "heroic_punch", "level": 1,
		"targets": [{"id": "foe", "part": "head"}]})
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "heroic_punch_pow", "a landed Head hit is always the crowd beat")
	assert_no_event(ev2, "heroic_punch_shock", "Overwhelmed is head-legal but not Exposed — no rattle")
	assert_eq((sim.combatants["foe"] as CombatantState).shock, 0, "no Shock applied")


# ========================================= determinism + serialization mid-chain

func test_chain_determinism_two_runs_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = _chain_one_sim(3)
		declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1, "leap_to": [2, 0],
			"targets": [{"id": "prey", "part": "torso"}]})
		advance(sim, 3)
		declare(sim, "sasha", {"kind": "skill", "key": "slip_through", "level": 1, "targets": [{"id": "prey"}]})
		advance(sim)
		declare(sim, "sasha", {"kind": "skill", "key": "decapitate", "level": 1,
			"targets": [{"id": "prey", "part": "head"}]})
		advance(sim)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash through the full chain")


func test_serialization_roundtrip_mid_chain_preserves_the_chain() -> void:
	# Snapshot BETWEEN links: the slam has resolved (chain key + same-target id
	# live on the actor), the shockwave not yet declared.
	var live: CombatSim = _chain_two_sim(4870)
	declare(live, "imani", {"kind": "skill", "key": "overhead_slam", "level": 1,
		"attack_range": 1, "targets": [{"id": "victim", "part": "torso"}]})
	advance(live, 3)
	var imani: CombatantState = live.combatants["imani"]
	assert_eq(imani.last_action_key, "overhead_slam", "precondition: chain key live")
	assert_eq(imani.last_action_target, "victim", "precondition: chain target live")
	var restored: CombatSim = CombatSim.from_dict(live.to_dict())
	assert_eq(restored.state_hash(), live.state_hash(), "full-state hash survives to_dict → from_dict mid-chain")
	var r_imani: CombatantState = restored.combatants["imani"]
	assert_eq(r_imani.last_action_target, "victim", "the same-target chain field round-trips")
	# Both timelines continue the chain identically: the shockwave declares
	# (chain honored) and the restored run still EXCLUDES the slam victim.
	var live_ev: Array[Dictionary] = declare(live, "imani", {"kind": "skill", "key": "shockwave",
		"level": 1, "area_shape": {"kind": "cone", "toward": [1, 0]}})
	var rest_ev: Array[Dictionary] = declare(restored, "imani", {"kind": "skill", "key": "shockwave",
		"level": 1, "area_shape": {"kind": "cone", "toward": [1, 0]}})
	assert_event(live_ev, "action_declared", "live chain continues")
	assert_event(rest_ev, "action_declared", "restored chain continues — the prime state survived")
	var live_res: Array[Dictionary] = advance(live)
	var rest_res: Array[Dictionary] = advance(restored)
	assert_eq(restored.state_hash(), live.state_hash(), "restore → replay tail = same hash")
	for events: Array[Dictionary] in [live_res, rest_res]:
		for knock: Dictionary in events_of(events, "knocked_back"):
			assert_ne(String(knock.get("combatant", "")), "victim",
				"the restored exclusion still spares the slam victim")
	assert_eq(events_of(live_res, "knocked_back").size(), events_of(rest_res, "knocked_back").size(),
		"identical knockback sets on both timelines")


## Pounce validation edges: the leap respects range, landing adjacency, and
## occupancy through the existing movement gates.
func test_pounce_leap_validation() -> void:
	var sim: CombatSim = make_sim(4880)
	add_party(sim, "sasha", [0, 0])
	add_elite(sim, "prey", [3, 0])
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1,
		"targets": [{"id": "prey", "part": "torso"}]}), "leap_required",
		"a non-adjacent pounce must declare its landing hex (no auto-pathing)")
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1,
		"leap_to": [1, 0], "targets": [{"id": "prey", "part": "torso"}]}), "landing_not_adjacent",
		"the landing must put the claws in reach")
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1,
		"leap_to": [3, 1], "targets": [{"id": "prey", "part": "torso"}]}), "leap_out_of_range",
		"L1 leap reach is 3 hexes")
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1,
		"leap_to": [3, 0], "targets": [{"id": "prey", "part": "torso"}]}), "hex_occupied",
		"the landing honors body occupancy")
	assert_rejected(declare(sim, "sasha", {"kind": "skill", "key": "pounce", "level": 1,
		"leap_to": [2, 0], "targets": [{"id": "prey", "part": "left_leg"}]}), "torso_only",
		"the pounce strike is the authored torso slash")
