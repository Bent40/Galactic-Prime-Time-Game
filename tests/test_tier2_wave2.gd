extends SimTestBase
## Tier-2 wave 2 (docs/design/tier2-rungs-proposal.md — BLESSED, owner
## 2026-08-18): the two fused ladders encoded this wave.
##   S6 combat_medic — ally_treatment EXTENDED: delay ANY condition on self
##      or any ally within treat_range (both parents' lanes fused), Triage's
##      charge economy kept ally-only (self-treatment never burns a charge),
##      and the S6-d RESOLVE mode ([FROM row 6] — Crush dropped): fully
##      remove one active Infection or Bleeding through ConditionEngine.
##      treat's own gates, once per Clock, NEVER HP and NEVER a lethal state
##      (the no-HP structural pin holds — updated in test_skills_batch_c).
##      S6-c (arrest/freeze) and S6-e (row 88) stay DATA.
##   S1 counterscript — fused_counter: the standing read (pattern_reads
##      substrate, Clock-reset expiry, read cap with S1-c's second enemy at
##      L3+) + the WIDENED counter gate (any declared action of the read
##      target with remaining cost — no winding_up prime; the honest
##      boundary: an action that already RESOLVED can never be countered,
##      so the widened gate covers exactly the SCHEDULED remainder), the
##      cut/collapse -> Forced BODY, and the S1-b per-source 3-Moment
##      immunity window (counter_immunities, enforced at the hit seams).
##      S1-d/e stay DATA ([NEEDS] R15 hooks / boss telegraph exposure).
## Plus: serialization only-when-set compat pins, round-trips, determinism,
## twin-rng discipline. All magnitudes PLACEHOLDER (R14).


func add_party(sim: CombatSim, id: String, pos: Array, overrides: Dictionary = {}) -> void:
	var spec: Dictionary = {"team": "party", "position": pos,
		"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}
	spec.merge(overrides, true)
	add_human(sim, id, spec)


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


func apply_cond(sim: CombatSim, target: String, part: String, condition: String, tier: int) -> Array[Dictionary]:
	return sim.apply_command({"type": "apply_condition", "target": target,
		"part": part, "condition": condition, "tier": tier})


func medic_declare(sim: CombatSim, actor: String, target: String, part: String, condition: String, level: int = 1, extra: Dictionary = {}) -> Array[Dictionary]:
	var action: Dictionary = {"kind": "skill", "key": "combat_medic", "level": level,
		"targets": [{"id": target, "part": part}], "condition": condition}
	action.merge(extra, true)
	return declare(sim, actor, action)


func read_declare(sim: CombatSim, actor: String, target: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "counterscript", "level": level,
		"mode": "read", "targets": [{"id": target}]})


func counter_declare(sim: CombatSim, actor: String, target: String, level: int = 1) -> Array[Dictionary]:
	return declare(sim, actor, {"kind": "skill", "key": "counterscript", "level": level,
		"targets": [{"id": target, "part": "torso"}]})


# ========================================================== S6 combat_medic

func test_medic_delays_any_condition_on_any_ally_at_range() -> void:
	var sim: CombatSim = make_sim(8101)
	add_party(sim, "medic", [0, 0], {"charges": {"bandage_charge": 2}})
	add_party(sim, "ally", [2, 0])
	add_party(sim, "far_ally", [3, 0])
	add_elite(sim, "foe", [5, 0])
	# ANY condition (the parents' lanes fused): chilled — seal refused it,
	# the fused medic treats it; on an ally TWO hexes away (Triage's L5
	# reach at L1).
	apply_cond(sim, "ally", "left_arm", "chilled", 1)
	var declared: Array[Dictionary] = medic_declare(sim, "medic", "ally", "left_arm", "chilled")
	assert_event(declared, "action_declared", "any condition, 2 hexes, L1 — the fused core")
	var ev: Array[Dictionary] = advance(sim)
	var applied: Dictionary = assert_event(ev, "treatment_applied", "the treatment lands")
	assert_eq(int(applied.get("clocks", 0)), 4, "L1 delay = 4 Clocks (>= Seal's L5 total, PH)")
	assert_event(ev, "charge_consumed", "ALLY treatment consumes a bandage (Triage's economy kept)")
	# Range bounds at L1: three hexes is out.
	apply_cond(sim, "far_ally", "torso", "bleeding", 1)
	assert_rejected(medic_declare(sim, "medic", "far_ally", "torso", "bleeding"),
		"out_of_range", "L1 treats within 2 (PH)")
	# An enemy is not treated.
	apply_cond(sim, "foe", "torso", "bleeding", 1)
	assert_rejected(medic_declare(sim, "medic", "foe", "torso", "bleeding"),
		"target_not_ally", "an enemy is not treated")
	# SELF-treatment is in the fused lane and never touches the ally charge.
	apply_cond(sim, "medic", "torso", "bleeding", 1)
	advance(sim)
	var self_declared: Array[Dictionary] = medic_declare(sim, "medic", "medic", "torso", "bleeding")
	assert_event(self_declared, "action_declared", "self-treatment declares (Seal's lane kept)")
	var self_ev: Array[Dictionary] = advance(sim)
	assert_event(self_ev, "treatment_applied", "self-treatment lands")
	assert_no_event(self_ev, "charge_consumed", "self-treatment is charge-free (Seal had no charge)")
	var medic: CombatantState = sim.combatants["medic"]
	assert_eq(int(medic.charges.get("bandage_charge", -1)), 1, "one bandage spent on the ALLY only")


func test_medic_ally_charge_gate() -> void:
	var sim: CombatSim = make_sim(8102)
	add_party(sim, "medic", [0, 0])  # NO charges granted
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [5, 0])
	apply_cond(sim, "ally", "torso", "bleeding", 1)
	assert_rejected(medic_declare(sim, "medic", "ally", "torso", "bleeding"),
		"prime_unmet", "no bandage = no ALLY treatment (the Triage economy, target-conditional)")
	# The same charge-less medic still treats THEMSELVES.
	apply_cond(sim, "medic", "torso", "bleeding", 1)
	var declared: Array[Dictionary] = medic_declare(sim, "medic", "medic", "torso", "bleeding")
	assert_event(declared, "action_declared", "self-treatment needs no charge")


func test_medic_resolve_removes_infection_and_bleed_only() -> void:
	var sim: CombatSim = make_sim(8103)
	add_party(sim, "medic", [0, 0], {"charges": {"bandage_charge": 3}})
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [2, 0])
	# Wound the ally first so "never HP" is a real assertion, then infect.
	declare(sim, "foe", attack_action("crushed", 4, "ally", "torso"))
	advance(sim)
	var ally: CombatantState = sim.combatants["ally"]
	var hp_after_hit: int = int(ally.parts["torso"]["hp"])
	assert_true(hp_after_hit < ally.max_hp("torso"), "the ally is genuinely wounded")
	apply_cond(sim, "ally", "torso", "infected", 2)
	# Below L4 the mode does not exist (S6-d is the L4 rung).
	assert_rejected(medic_declare(sim, "medic", "ally", "torso", "infected", 3, {"mode": "resolve"}),
		"resolve_not_available", "no resolve below L4")
	# L4 resolves the infection FULLY — a real removal through the engine.
	var declared: Array[Dictionary] = medic_declare(sim, "medic", "ally", "torso", "infected", 4, {"mode": "resolve"})
	assert_event(declared, "action_declared", "the L4 resolve declares")
	var ev: Array[Dictionary] = advance(sim)
	var resolved: Dictionary = assert_event(ev, "treatment_resolved", "the S6-d resolve lands")
	assert_eq(String(resolved.get("condition", "")), "infected", "on the named condition")
	assert_event(ev, "condition_resolved", "the condition instance is REMOVED (engine path)")
	assert_event(ev, "charge_consumed", "an ally resolve still burns the bandage")
	assert_eq(ally.condition_tier("torso", "infected"), 0, "the infection is gone")
	# Never HP: the wound stays exactly as deep as it was.
	assert_no_event(ev, "healed", "never HP")
	assert_eq(int(ally.parts["torso"]["hp"]), hp_after_hit, "HP untouched by the resolve")
	# Only Infection/Bleed are resolvable (row 6, Crush dropped by the audit).
	apply_cond(sim, "ally", "left_arm", "chilled", 1)
	assert_rejected(medic_declare(sim, "medic", "ally", "left_arm", "chilled", 4, {"mode": "resolve"}),
		"condition_not_resolvable", "chilled delays fine but never resolves")
	apply_cond(sim, "ally", "torso", "crushed", 1)
	assert_rejected(medic_declare(sim, "medic", "ally", "torso", "crushed", 4, {"mode": "resolve"}),
		"condition_not_resolvable", "Crush was DROPPED from row 6 (structural damage)")
	# An unknown mode is rejected, not silently treated as a delay.
	assert_rejected(medic_declare(sim, "medic", "ally", "torso", "crushed", 4, {"mode": "cure"}),
		"unknown_treat_mode", "no smuggled modes")


func test_medic_resolve_once_per_clock_and_round_trip() -> void:
	var sim: CombatSim = make_sim(8104)
	add_party(sim, "medic", [0, 0], {"charges": {"bandage_charge": 3}})
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [5, 0])
	apply_cond(sim, "ally", "torso", "infected", 1)
	apply_cond(sim, "ally", "left_leg", "bleeding", 1)
	medic_declare(sim, "medic", "ally", "torso", "infected", 4, {"mode": "resolve"})
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "treatment_resolved", "the first resolve lands in Clock 0")
	var medic: CombatantState = sim.combatants["medic"]
	assert_eq(medic.treat_resolve_used_clock, 0, "the per-Clock gate is spent")
	# Same Clock: the second resolve is refused — delay stays available.
	assert_rejected(medic_declare(sim, "medic", "ally", "left_leg", "bleeding", 4, {"mode": "resolve"}),
		"resolve_used_this_clock", "once per Clock (PH)")
	var delay_ev_declared: Array[Dictionary] = medic_declare(sim, "medic", "ally", "left_leg", "bleeding", 4)
	assert_event(delay_ev_declared, "action_declared", "the base delay mode is untouched by the gate")
	advance(sim)
	# The gate round-trips: a restored medic is still spent this Clock.
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "hash survives the mid-Clock round-trip")
	assert_eq((restored.combatants["medic"] as CombatantState).treat_resolve_used_clock, 0,
		"treat_resolve_used_clock round-trips")
	assert_rejected(medic_declare(restored, "medic", "ally", "left_leg", "bleeding", 4, {"mode": "resolve"}),
		"resolve_used_this_clock", "the restored gate still holds")
	# Cross the reset: the gate re-opens (Clock index moves, no sweep needed).
	advance(sim, 8)  # ticks 2..9 complete Clock 0
	var reopened: Array[Dictionary] = medic_declare(sim, "medic", "ally", "left_leg", "bleeding", 4, {"mode": "resolve"})
	assert_event(reopened, "action_declared", "the resolve re-opens after the reset")
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "treatment_resolved", "and lands in Clock 1")
	assert_eq(medic.treat_resolve_used_clock, 1, "the gate tracks the new Clock")


func test_medic_resolve_honors_the_infection_gate() -> void:
	# R10 through the engine's own chokepoint: Infected T1+ prevents the
	# resolution of OTHER conditions — the medic's resolve does not bypass it.
	var sim: CombatSim = make_sim(8105)
	add_party(sim, "medic", [0, 0], {"charges": {"bandage_charge": 2}})
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [5, 0])
	apply_cond(sim, "ally", "torso", "infected", 1)
	apply_cond(sim, "ally", "left_leg", "bleeding", 1)
	medic_declare(sim, "medic", "ally", "left_leg", "bleeding", 4, {"mode": "resolve"})
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "heal_blocked", "the infection blocks resolving the bleed (R10, engine-owned)")
	assert_no_event(ev, "treatment_resolved", "nothing resolved")
	assert_no_event(ev, "charge_consumed", "a blocked resolve never burns the bandage")
	var medic: CombatantState = sim.combatants["medic"]
	assert_eq(medic.treat_resolve_used_clock, -1, "a blocked resolve never spends the per-Clock gate")
	assert_eq((sim.combatants["ally"] as CombatantState).condition_tier("left_leg", "bleeding"), 1,
		"the bleed is still there")
	# Resolving the INFECTION itself is the legal play — same Clock, gate unspent.
	medic_declare(sim, "medic", "ally", "torso", "infected", 4, {"mode": "resolve"})
	var ev2: Array[Dictionary] = advance(sim)
	assert_event(ev2, "treatment_resolved", "the infection itself resolves")


func test_medic_resolve_never_touches_a_lethal_state() -> void:
	var sim: CombatSim = make_sim(8106)
	add_party(sim, "medic", [0, 0], {"charges": {"bandage_charge": 2}})
	add_party(sim, "ally", [1, 0])
	add_elite(sim, "foe", [5, 0])
	# Bleeding T3 on the torso: part death + bleed-out (R5) — a LETHAL state.
	var down_ev: Array[Dictionary] = apply_cond(sim, "ally", "torso", "bleeding", 3)
	assert_event(down_ev, "bleed_out_started", "the ally is bleeding out")
	# The resolve is REFUSED: a lethal state is held, never cured (default #8).
	assert_rejected(medic_declare(sim, "medic", "ally", "torso", "bleeding", 4, {"mode": "resolve"}),
		"lethal_state_held_not_cured", "the S6-d boundary — no cure of a lethal state")
	# The DELAY lane still stabilizes per R5 — alive, held, 0 HP, not healed.
	medic_declare(sim, "medic", "ally", "torso", "bleeding", 4)
	var ev: Array[Dictionary] = advance(sim)
	assert_event(ev, "treatment_applied", "the delay lands on the downed ally")
	assert_event(ev, "bleed_out_stabilized", "delaying the driving condition stabilizes (R5)")
	var ally: CombatantState = sim.combatants["ally"]
	assert_true(ally.alive, "alive")
	assert_eq(int(ally.parts["torso"]["hp"]), 0, "0-HP-stabilized — no HP restored")
	assert_eq(ally.condition_tier("torso", "bleeding"), 3, "the lethal condition is HELD, not cured")


# ========================================================= S1 counterscript

func test_counterscript_read_records_and_expires() -> void:
	var sim: CombatSim = make_sim(8201)
	add_party(sim, "reader", [0, 0])
	add_party(sim, "buddy", [0, -1])
	add_elite(sim, "ea", [1, 0])
	add_elite(sim, "far", [5, 0])
	# Gates: enemies only, within read_range 3, and never an ally.
	assert_rejected(read_declare(sim, "reader", "far"), "out_of_range", "read reaches 3 (the parent's)")
	assert_rejected(read_declare(sim, "reader", "buddy"), "target_not_enemy", "reads are for enemies")
	var declared: Array[Dictionary] = read_declare(sim, "reader", "ea")
	assert_event(declared, "action_declared", "the read declares (cost 1)")
	var ev: Array[Dictionary] = advance(sim)
	var read: Dictionary = assert_event(ev, "counterscript_read", "the attributed read event")
	assert_eq(String(read.get("target", "")), "ea", "on the read target")
	assert_eq(int(read.get("actions", 0)), 5, "L1 read depth = 5 (>= the parent's L5 total, PH)")
	var reader: CombatantState = sim.combatants["reader"]
	assert_true(reader.pattern_reads.has("ea"), "the read rides the pattern_reads substrate")
	# The read lives until the Clock reset — the EXISTING expiry sweep owns it.
	var reset_ev: Array[Dictionary] = advance(sim, 9)
	assert_event(reset_ev, "pattern_read_expired", "the reset expires the read (shared sweep)")
	assert_true(reader.pattern_reads.is_empty(), "the read is gone")
	# And with it the counter gate closes.
	assert_rejected(counter_declare(sim, "reader", "ea"), "target_not_read",
		"no live read = no counter (the read IS the prime)")


func test_widened_counter_connects_where_counter_surge_cannot() -> void:
	# The precognition play (S1-a): the counter is declared FIRST — old
	# counter_surge cannot even declare (no windup, prime_unmet) — then the
	# read target commits a cost-1 INSTANT, and the counter, resolving first
	# (lower seq), answers it: the instant collapses at its own slot into
	# Forced Action – BODY and never fires.
	var sim: CombatSim = make_sim(8202)
	add_party(sim, "ace", [0, 0])
	add_party(sim, "ally", [2, 0])
	add_elite(sim, "foe", [1, 0])
	read_declare(sim, "ace", "foe")
	advance(sim)
	# Old counter_surge: REJECTED — nothing is winding up.
	assert_rejected(declare(sim, "ace", {"kind": "skill", "key": "counter_surge", "level": 1,
		"targets": [{"id": "foe", "part": "torso"}]}), "prime_unmet",
		"counter_surge needs an executing 2+ Moment windup")
	# Counterscript: the widened gate accepts — the read is the whole prime.
	var declared: Array[Dictionary] = counter_declare(sim, "ace", "foe")
	assert_event(declared, "action_declared", "the widened counter declares with NOTHING scheduled yet")
	# The read target now commits a cost-1 instant at the ally (a later seq —
	# declared after the counter, still pending when the counter resolves).
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ev: Array[Dictionary] = advance(sim)
	# The counter strike landed...
	assert_true(int((sim.combatants["foe"] as CombatantState).parts["torso"]["hp"]) < 50,
		"the counter strike connected")
	# ...and answered the pending instant: cut, collapse, Forced BODY.
	var countered: Dictionary = assert_event(ev, "action_countered", "the cost-1-remaining action is countered")
	assert_eq(String(countered.get("victim", "")), "foe", "attributed to the victim")
	assert_eq(int(countered.get("remaining_before", 0)), 1, "its whole remaining cost: the 1 Moment")
	var invalidated: Dictionary = assert_event(ev, "action_invalidated", "the instant dies at its own slot")
	assert_eq(String(invalidated.get("reason", "")), "countered", "reason: countered")
	assert_eq(String(invalidated.get("by", "")), "ace", "by the counter-actor")
	var forced: Dictionary = assert_event(ev, "forced_action_triggered", "the victim rolls")
	assert_eq(String(forced.get("table", "")), "body", "Forced Action – BODY (the parameterized table)")
	assert_eq(int((sim.combatants["ally"] as CombatantState).parts["torso"]["hp"]),
		(sim.combatants["ally"] as CombatantState).max_hp("torso"),
		"the countered attack NEVER fires — the ally is untouched")


func test_counter_cannot_answer_an_already_resolved_instant() -> void:
	# The honest boundary, stated: same-tick instants resolve in declaration
	# order — an instant with a LOWER seq resolves before the counter, and
	# countering after resolution is impossible. The widened gate covers
	# exactly the SCHEDULED remainder.
	var sim: CombatSim = make_sim(8203)
	add_party(sim, "ace", [0, 0])
	add_party(sim, "ally", [2, 0])
	add_elite(sim, "foe", [1, 0])
	read_declare(sim, "ace", "foe")
	advance(sim)
	# The instant is declared FIRST (lower seq)...
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	# ...old counter_surge still rejects (window 0 is not a windup)...
	assert_rejected(declare(sim, "ace", {"kind": "skill", "key": "counter_surge", "level": 1,
		"targets": [{"id": "foe", "part": "torso"}]}), "prime_unmet",
		"a declared instant is not a windup — counter_surge rejects")
	# ...counterscript declares, but the instant resolves before it.
	counter_declare(sim, "ace", "foe")
	var ev: Array[Dictionary] = advance(sim)
	var missed: Dictionary = assert_event(ev, "counter_missed", "the honest after-resolution miss")
	assert_eq(String(missed.get("reason", "")), "nothing_pending", "nothing was left to answer")
	assert_no_event(ev, "action_countered", "no retroactive counter")
	assert_true(int((sim.combatants["ally"] as CombatantState).parts["torso"]["hp"])
		< (sim.combatants["ally"] as CombatantState).max_hp("torso"),
		"the instant fired normally — it had already resolved")


func test_counter_collapses_a_windup_to_body() -> void:
	var sim: CombatSim = make_sim(8204)
	add_party(sim, "ace", [0, 0])
	add_elite(sim, "foe", [1, 0])
	add_elite(sim, "dummy", [2, 0])
	# The counter needs the read: an unread mid-windup enemy still rejects.
	declare(sim, "foe", {"kind": "skill", "key": "strong_strike", "level": 1,
		"targets": [{"id": "dummy", "part": "torso"}]})
	assert_rejected(counter_declare(sim, "ace", "foe"), "target_not_read",
		"the counter answers only YOUR read target")
	read_declare(sim, "ace", "foe")
	advance(sim)
	# Tick 1: remaining 1 on the windup; L1 cut 5 >= 1 — full collapse.
	counter_declare(sim, "ace", "foe")
	var ev: Array[Dictionary] = advance(sim)
	var collapsed: Dictionary = assert_event(ev, "windup_collapsed", "cut >= remaining: collapse")
	assert_eq(String(collapsed.get("victim", "")), "foe", "attributed")
	assert_eq(String(collapsed.get("key", "")), "strong_strike", "names what died")
	var forced: Dictionary = assert_event(ev, "forced_action_triggered", "the victim rolls")
	assert_eq(String(forced.get("table", "")), "body", "Forced Action – BODY")
	advance(sim, 2)
	assert_eq(int((sim.combatants["dummy"] as CombatantState).parts["torso"]["hp"]), 50,
		"the collapsed windup never fires")
	assert_no_event(ev, "counter_immunity", "a COLLAPSED action arms no immunity window (S1-b is the cut path)")


func test_s1b_immunity_window_exactly_three_moments() -> void:
	var sim: CombatSim = make_sim(8205)
	add_party(sim, "ace", [0, 0])
	add_party(sim, "ally", [2, 0])
	add_elite(sim, "foe", [1, 0])
	# Tick 0: the foe commits a LONG windup at ace; ace reads the foe.
	declare(sim, "foe", attack_action("crushed", 3, "ace", "torso", {"cost": 9}))
	read_declare(sim, "ace", "foe")
	advance(sim)
	# Tick 1: the L2 counter cuts 6 of the remaining 8 — no collapse, so the
	# S1-b window arms: the foe cannot affect ace for the NEXT 3 Moments
	# (ticks 2-4; until_tick 5).
	counter_declare(sim, "ace", "foe", 2)
	var ev: Array[Dictionary] = advance(sim)
	var cut: Dictionary = assert_event(ev, "windup_cut", "the deepened L2 cut (6, PH)")
	assert_eq(int(cut.get("remaining_before", 0)), 8, "8 Moments remained")
	assert_eq(int(cut.get("resolve_tick", 0)), 3, "rescheduled to tick 3")
	var window: Dictionary = assert_event(ev, "counter_immunity", "the per-source window arms")
	assert_eq(String(window.get("source", "")), "foe", "keyed by the countered source")
	assert_eq(int(window.get("moments", 0)), 3, "3 Moments (PH)")
	assert_eq(int(window.get("until_tick", 0)), 5, "ticks 2-4 — the NEXT 3 Moments")
	var ace: CombatantState = sim.combatants["ace"]
	assert_eq(int(ace.counter_immunities.get("foe", 0)), 5, "the serialized record")
	# Mid-window round-trip: the window survives serialization functionally.
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "hash survives the mid-window round-trip")
	assert_eq(int((restored.combatants["ace"] as CombatantState).counter_immunities.get("foe", 0)), 5,
		"counter_immunities round-trips")
	# Tick 2 (nothing due) then tick 3: the countered windup resolves INSIDE
	# the window — it simply misses ace. Both timelines agree.
	var live_ev: Array[Dictionary] = advance(sim, 2)
	var rest_ev: Array[Dictionary] = advance(restored, 2)
	var immune: Dictionary = assert_event(live_ev, "attack_immune", "the countered action cannot affect ace")
	assert_eq(String(immune.get("source", "")), "foe", "per-source")
	assert_no_event(live_ev, "damage_applied", "no damage reached anyone")
	assert_event(rest_ev, "attack_immune", "the restored window excludes identically")
	assert_eq(restored.state_hash(), sim.state_hash(), "restore -> replay tail = same hash")
	assert_eq(int(ace.parts["torso"]["hp"]), ace.max_hp("torso"), "ace is untouched")
	# Tick 4, still in-window: the SOURCE is only excluded against ACE —
	# others are still affected.
	declare(sim, "foe", attack_action("crushed", 3, "ally", "torso"))
	var ally_ev: Array[Dictionary] = advance(sim)
	assert_event(ally_ev, "damage_applied", "the ally is NOT protected — the exclusion is ace-only")
	assert_no_event(ally_ev, "attack_immune", "no immunity fired for the ally")
	# Tick 5: the window has expired — exactly 3 Moments, not four.
	declare(sim, "foe", attack_action("crushed", 3, "ace", "torso"))
	var expired_ev: Array[Dictionary] = advance(sim)
	assert_no_event(expired_ev, "attack_immune", "the window expired at tick 5")
	assert_event(expired_ev, "damage_applied", "the foe affects ace again")


func test_s1c_second_read_at_l3() -> void:
	var sim: CombatSim = make_sim(8206)
	add_party(sim, "ace", [0, 0])
	add_elite(sim, "ea", [1, 0])
	add_elite(sim, "eb", [2, 0])
	# L1: ONE read at a time — a second read moves the attention (the oldest
	# read drops, and its counter gate closes with it).
	read_declare(sim, "ace", "ea")
	advance(sim)
	read_declare(sim, "ace", "eb")
	var ev: Array[Dictionary] = advance(sim)
	var dropped: Dictionary = assert_event(ev, "counterscript_read_dropped", "the L1 cap: one read holds")
	assert_eq(String(dropped.get("target", "")), "ea", "the OLDEST read drops")
	var ace: CombatantState = sim.combatants["ace"]
	assert_false(ace.pattern_reads.has("ea"), "ea is no longer read")
	assert_true(ace.pattern_reads.has("eb"), "eb is")
	assert_rejected(counter_declare(sim, "ace", "ea"), "target_not_read",
		"the dropped target cannot be countered")
	# L3 (S1-c): the read holds on a SECOND enemy at once, deeper queue.
	var sim2: CombatSim = make_sim(8207)
	add_party(sim2, "ace", [0, 0])
	add_elite(sim2, "ea", [1, 0])
	add_elite(sim2, "eb", [2, 0])
	read_declare(sim2, "ace", "ea", 3)
	var deep_ev: Array[Dictionary] = advance(sim2)
	assert_eq(int(assert_event(deep_ev, "counterscript_read", "L3 read").get("actions", 0)), 9,
		"L3 read depth = 9 (row 10's +4, PH)")
	read_declare(sim2, "ace", "eb", 3)
	var second_ev: Array[Dictionary] = advance(sim2)
	assert_no_event(second_ev, "counterscript_read_dropped", "TWO reads hold at L3")
	var ace2: CombatantState = sim2.combatants["ace"]
	assert_true(ace2.pattern_reads.has("ea") and ace2.pattern_reads.has("eb"), "both reads live")
	# The counter answers EITHER read target (declare acceptance is the gate).
	var vs_first: Array[Dictionary] = counter_declare(sim2, "ace", "ea", 3)
	assert_event(vs_first, "action_declared", "the counter answers the first read target too")


# ================================================ serialization & determinism

func test_wave2_fields_serialize_only_when_set() -> void:
	# The compat pin: a wave-2-free fight carries neither new key.
	var sim: CombatSim = make_sim(8301)
	add_party(sim, "a", [0, 0])
	add_elite(sim, "e", [1, 0])
	declare(sim, "a", attack_action("crushed", 2, "e", "torso"))
	advance(sim)
	var dict: Dictionary = sim.to_dict()
	for id: Variant in dict.get("combatants", {}) as Dictionary:
		var c: Dictionary = dict["combatants"][id]
		assert_false(c.has("counter_immunities"), "no 'counter_immunities' key unarmed (%s)" % id)
		assert_false(c.has("treat_resolve_used_clock"), "no 'treat_resolve_used_clock' key unused (%s)" % id)


func test_wave2_twin_rng_discipline() -> void:
	# Twin sims, same seed: twin B additionally reads AND counter-cuts (the
	# non-collapse path). The next Forced Body draw must be the SAME stream
	# value in both — the read is zero-rng and the cut is pure Clock
	# arithmetic (no new rng anywhere in the wave).
	var twin_a: CombatSim = make_sim(8302)
	var twin_b: CombatSim = make_sim(8302)
	for twin: CombatSim in [twin_a, twin_b]:
		add_party(twin, "ace", [0, 0])
		add_party(twin, "weakling", [5, 0], {"traits": {"physique": 2, "reflexes": 3, "mind": 3, "charm": 3}})
		add_elite(twin, "foe", [1, 0])
		add_elite(twin, "eb", [6, 0])
		declare(twin, "foe", attack_action("crushed", 3, "ace", "torso", {"cost": 9}))
	read_declare(twin_b, "ace", "foe")
	for twin: CombatSim in [twin_a, twin_b]:
		advance(twin)
	counter_declare(twin_b, "ace", "foe", 2)  # cut 6 of 8 — no collapse, no rng
	# The stream probe: an above-weight grapple's Forced Body (physique 2 < 3).
	for twin: CombatSim in [twin_a, twin_b]:
		declare(twin, "weakling", {"kind": "grapple", "target": "eb"})
	var roll_a: int = int(assert_event(advance(twin_a), "forced_action_triggered", "twin A probe").get("roll", -1))
	var roll_b: int = int(assert_event(advance(twin_b), "forced_action_triggered", "twin B probe").get("roll", -2))
	assert_eq(roll_a, roll_b, "identical stream draw — the read and the cut consumed zero rng")


func test_wave2_determinism_same_log_same_hash() -> void:
	var hashes: Array[String] = []
	for run: int in range(2):
		var sim: CombatSim = make_sim(8303)
		add_party(sim, "ace", [0, 0])
		add_party(sim, "medic", [0, 4], {"charges": {"bandage_charge": 2}})
		add_party(sim, "ally", [1, 4])
		add_elite(sim, "foe", [1, 0])
		add_elite(sim, "goon", [2, 4])
		apply_cond(sim, "ally", "torso", "infected", 1)
		apply_cond(sim, "ally", "left_leg", "chilled", 1)
		declare(sim, "foe", attack_action("crushed", 3, "ace", "torso", {"cost": 9}))
		read_declare(sim, "ace", "foe")
		medic_declare(sim, "medic", "ally", "torso", "infected", 4, {"mode": "resolve"})
		advance(sim)
		counter_declare(sim, "ace", "foe", 2)
		medic_declare(sim, "medic", "ally", "left_leg", "chilled", 4)
		advance(sim)
		declare(sim, "goon", attack_action("crushed", 2, "ally", "torso"))
		advance(sim, 12)  # through the Clock reset (read expiry sweep included)
		hashes.append(sim.state_hash())
	assert_eq(hashes[0], hashes[1], "same (seed, command log) = same hash across the whole wave")
