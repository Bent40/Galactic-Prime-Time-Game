extends SimTestBase
## Content pass Round 3a — the unblocked KAN-5 skills (skills-r19-ladders-
## FINAL.md #2/#30/#42/#41/#11/#13/#15 on the R32/R33 substrates).
##
## Under test:
##  * CONTESTANT TERRAIN PRICING (closes R33's honest asymmetry) — the
##    destination-cost contract (rules-addendum R33 Round-3a annotation +
##    ActionResolver's movement-section header): priced spaces = hex distance
##    + (move_cost(destination) − 1) against the free allowance and the
##    scheduled conversion; interior hexes stay free (the documented
##    coarseness — the hop's only factual entry is the destination); the
##    Prone/Slowed budget-1 mirror; the no-terrain byte-compat pin.
##  * quick_step — the slot-free immediate stride window (difficult AND
##    rough read 1; water stays priced), duration rows, the
##    movement-remaining gate.
##  * swim — water reads 1 for the owner; the R9-capped submersion
##    suffocation track off the in_water reset (non-swimmer drowns on the
##    standard 2-Clock timer, Boss/no_airway never start it, surfacing
##    cancels, the L1 grace delays death exactly one Clock; grace stays 1
##    through L1-4 — the L2-4 rows author movement, the L6 "+2 total" rung
##    stays threshold data).
##  * acrobatics — rough immunity + the authored movement rows extending the
##    declared roll (the sim's acrobatic maneuver, PROVISIONAL); passives
##    reject declares.
##  * lockpicking — the scheduled pick: declare/windup/resolve through
##    CombatSim.pick_lock, tier Moments pinned (table minus the -1 rows,
##    floor 1), tier access, magical-without-special rejected, feints and
##    mid-windup premise breaks collapse into Forced Action – Tool.
##  * the three walls — placed-line zones via create_zone: poison's
##    entry-gated Poison, frost's blocking + attackability (the additive
##    zone_target attack shape, the R14 gate vs Zones.WALL_ROBUSTNESS,
##    burn x2, destroyed-at-0 unblocks, the strike-chill), fire's
##    enter-T1/occupy-T2 burn; durations expire; declare validation.
##  * leaps stay airborne (no terrain surcharge — the documented contract).
##  * determinism + serialization (round-trip incl. the new
##    quick_step_until_tick key + submersion timers).
## The CI-harness byte-diff (both harnesses stage none of this) is verified
## OUTSIDE this suite — the story's report carries the diff verdict.


func set_arena(sim: CombatSim, cfg: Dictionary) -> Array[Dictionary]:
	return sim.apply_command({"type": "set_arena", "arena": cfg})


func move(sim: CombatSim, id: String, to: Array) -> Array[Dictionary]:
	return sim.apply_command({"type": "move", "actor": id, "to": to})


## An 11x11 arena centered on the origin with authored terrain patches.
func terrain_arena(terrain: Array, extra: Dictionary = {}) -> Dictionary:
	var cfg: Dictionary = {"bounds": {"width": 11, "height": 11}}
	if not terrain.is_empty():
		cfg["terrain"] = terrain
	cfg.merge(extra, true)
	return cfg


func skill(key: String, level: int, extra: Dictionary = {}) -> Dictionary:
	var action: Dictionary = {"kind": "skill", "key": key, "level": level}
	action.merge(extra, true)
	return action


## Advance to (and through) the next Clock reset, returning that tick's events.
func advance_to_reset(sim: CombatSim) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for i: int in range(Clock.TICKS_PER_CLOCK):
		events = advance(sim)
		if has_event(events, "clock_reset"):
			return events
	return events


# ------------------------------------------------ contestant terrain pricing

func test_free_move_pays_destination_cost() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([{"type": "difficult", "hexes": [[2, 0], [3, 0]]}]))
	add_human(sim, "runner")
	# 2 spaces + destination surcharge 1 = 3 <= allowance 3: still FREE.
	var ok: Array[Dictionary] = move(sim, "runner", [2, 0])
	assert_event(ok, "moved", "2 spaces ending on difficult ground fits the 3 allowance")
	assert_true(bool(first_event(ok, "moved").get("free", false)), "within allowance = free move")
	advance(sim)
	# Sanity: the same 3-space distance onto NORMAL ground stays free.
	assert_event(move(sim, "runner", [2, 3]), "moved", "a 3-space hop onto normal ground is free")
	advance(sim)
	# 3 spaces + surcharge 1 = 4 > 3: the hop spills into a SCHEDULED move.
	var onto: Array[Dictionary] = move(sim, "runner", [3, 0])
	var declared: Dictionary = assert_event(onto, "action_declared",
		"3 spaces ending on difficult = priced 4 = a scheduled 1-Moment move")
	assert_eq(int(declared.get("cost", 0)), 1, "ceil((4-3)/4) = 1 Moment")
	assert_no_event(onto, "moved", "the priced hop is not immediate")
	advance(sim)
	assert_eq([sim.combatants["runner"].position.x, sim.combatants["runner"].position.y],
		[3, 0], "the scheduled move resolves onto the difficult hex")


func test_interior_terrain_is_free_documented_coarseness() -> void:
	var sim: CombatSim = make_sim()
	# The patch sits BETWEEN start and destination; the destination is normal.
	set_arena(sim, terrain_arena([{"type": "difficult", "hexes": [[1, 0], [2, 0]]}]))
	add_human(sim, "runner")
	assert_event(move(sim, "runner", [3, 0]), "moved",
		"a hop OVER interior difficult ground pays nothing — the documented "
		+ "destination-only coarseness (the wall contract's mirror)")


func test_prone_and_slowed_budget_one_mirror() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([{"type": "difficult", "hexes": [[1, 0], [1, 3]]}]))
	add_human(sim, "crawler")
	add_human(sim, "limper", {"position": [0, 3]})
	sim.apply_command({"type": "set_status", "target": "crawler", "status": "prone", "value": true})
	sim.apply_command({"type": "set_status", "target": "limper", "status": "slowed", "value": true})
	# Prone budget 1 cannot afford the adjacent cost-2 hex — and prone cannot
	# schedule (the EnemyAI budget walker's honesty, mirrored).
	assert_rejected(move(sim, "crawler", [1, 0]), "prone_can_only_crawl",
		"a prone crawler cannot afford an adjacent difficult hex")
	# Slowed spills into the scheduled conversion instead: 1 space + 1
	# surcharge = 2 -> 1 Moment, doubled by Slowed (R3).
	var limp: Array[Dictionary] = move(sim, "limper", [1, 3])
	var declared: Dictionary = assert_event(limp, "action_declared",
		"slowed budget 1 vs a cost-2 hex spills into the scheduled conversion")
	assert_eq(int(declared.get("cost", 0)), 2, "1 Moment doubled by Slowed")


func test_no_terrain_arena_byte_compat_pin() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([]))
	add_human(sim, "runner")
	assert_event(move(sim, "runner", [3, 0]), "moved",
		"a terrain-less arena prices every hex 1 — the legacy free move")
	var serialized: Dictionary = sim.to_dict()
	assert_false((serialized["combatants"]["runner"] as Dictionary).has("quick_step_until_tick"),
		"no stride ever declared -> no new serialization key (the only-when-set pin)")


# ------------------------------------------------------------------ quick_step

func test_quick_step_covers_difficult_and_rough_not_water() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([
		{"type": "difficult", "hexes": [[3, 0]]},
		{"type": "rough", "hexes": [[-3, 0]]},
		{"type": "water", "hexes": [[0, 3]]},
	]))
	add_human(sim, "dancer")
	var opened: Array[Dictionary] = declare(sim, "dancer", skill("quick_step", 1))
	var stride: Dictionary = assert_event(opened, "quick_step", "the stride window opens at declare")
	assert_eq(int(stride.get("moments", 0)), 1, "L1 covers this Moment")
	assert_rejected(declare(sim, "dancer", skill("quick_step", 1)), "already_active",
		"no stacking model is authored")
	assert_event(move(sim, "dancer", [3, 0]), "moved",
		"difficult reads 1 inside the stride window — the 3-space hop stays free")
	advance(sim)
	# The L1 window died with its Moment; get home and stride the ROUGH lane.
	move(sim, "dancer", [0, 0])
	advance(sim)
	declare(sim, "dancer", skill("quick_step", 1))
	assert_event(move(sim, "dancer", [-3, 0]), "moved", "rough reads 1 inside the window too")
	advance(sim)
	move(sim, "dancer", [0, 0])
	advance(sim)
	# WATER is not covered (swim's lane): even at L4 the hop prices.
	declare(sim, "dancer", skill("quick_step", 4))
	var wet: Array[Dictionary] = move(sim, "dancer", [0, 3])
	var declared: Dictionary = assert_event(wet, "action_declared",
		"water stays priced under quick_step — the 3-space hop schedules")
	assert_eq(int(declared.get("cost", 0)), 1, "priced 4 -> 1 Moment")


func test_quick_step_duration_and_movement_gate() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([{"type": "difficult", "hexes": [[3, 0]]}]))
	add_human(sim, "dancer")
	# "Must have movement remaining": declaring after this tick's move rejects.
	move(sim, "dancer", [1, 0])
	assert_rejected(declare(sim, "dancer", skill("quick_step", 1)), "movement_spent",
		"the data's own requirement")
	advance(sim)
	move(sim, "dancer", [0, 0])
	advance(sim)
	# L2 = 2 Moments: the window survives one tick advance.
	declare(sim, "dancer", skill("quick_step", 2))
	advance(sim)
	assert_event(move(sim, "dancer", [3, 0]), "moved",
		"the L2 window still prices difficult as 1 a Moment later")
	# L1's window is gone the Moment after (a fresh sim pins the expiry).
	var sim2: CombatSim = make_sim()
	set_arena(sim2, terrain_arena([{"type": "difficult", "hexes": [[3, 0]]}]))
	add_human(sim2, "dancer")
	declare(sim2, "dancer", skill("quick_step", 1))
	advance(sim2)
	assert_event(move(sim2, "dancer", [3, 0]), "action_declared",
		"the L1 window died with its Moment — the hop prices again")


# ------------------------------------------------------------------ swim

func test_swimmer_crosses_water_unpenalized() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([{"type": "water", "hexes": [[3, 0], [0, 3]]}]))
	add_human(sim, "fish", {"skills": [{"key": "swim", "level": 1}]})
	add_human(sim, "brick", {"position": [0, 0], "id": "brick"})
	# The swimmer's 3-space hop into the pool stays free…
	assert_event(move(sim, "fish", [3, 0]), "moved",
		"water reads 1 for the swim owner — the 3-space hop stays free")
	# …the non-swimmer's identical hop prices into a scheduled Moment.
	var sink: Array[Dictionary] = move(sim, "brick", [0, 3])
	var declared: Dictionary = assert_event(sink, "action_declared",
		"the non-swimmer pays the water surcharge — priced 4 = 1 Moment")
	assert_eq(int(declared.get("cost", 0)), 1, "ceil((4-3)/4) = 1")


func test_non_swimmer_drowns_r9_capped() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([{"type": "water", "hexes": [[0, 0], [0, 3], [0, 5]]}]))
	# Spawning ON water is legal (R33) — stage everyone mid-pool.
	add_human(sim, "victim")
	add_human(sim, "boss", {"position": [0, 3], "category": "Boss"})
	add_human(sim, "gilled", {"position": [0, 5], "boss_traits": {"no_airway": true}})
	# Reset 1: in_water marker + the track STARTS (standard 2-Clock timer).
	var reset1: Array[Dictionary] = advance(sim, 10)
	assert_event(reset1, "in_water", "the R33 marker still fires")
	var started: Array[Dictionary] = events_of(reset1, "timer_started")
	assert_eq(started.size(), 1, "exactly ONE track starts — Boss and no_airway are R9-capped out")
	assert_eq(String(started[0].get("combatant", "")), "victim", "the mortal drowns")
	assert_eq(String(started[0].get("cause", "")), "submersion", "the water-sourced track is marked")
	# Reset 2: the track advances (2 -> 1).
	var reset2: Array[Dictionary] = advance(sim, 10)
	var advanced: Dictionary = assert_event(reset2, "timer_advanced", "the countdown runs while submerged")
	assert_eq(int(advanced.get("clocks_remaining", 0)), 1, "2-Clock timer at 1")
	# Reset 3: expiry -> death by suffocation (the standard terminal).
	var reset3: Array[Dictionary] = advance(sim, 10)
	assert_event(reset3, "timer_expired", "the track completes")
	var death: Dictionary = assert_event(reset3, "combatant_died", "drowning kills")
	assert_eq(String(death.get("cause", "")), "suffocation", "the standard suffocation terminal")
	assert_eq(String(death.get("combatant", "")), "victim", "only the mortal died")
	assert_true(sim.combatants["boss"].alive, "bosses are never drowned — wins are discovered (R9)")
	assert_true(sim.combatants["gilled"].alive, "no coverable airway -> no drowning (the R9 gate's airway half)")


func test_swim_grace_delays_death_and_surfacing_cancels() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([{"type": "water", "hexes": [[0, 0], [0, 3], [4, 3]]}]))
	add_human(sim, "swimmer", {"skills": [{"key": "swim", "level": 1}], "position": [0, 3]})
	add_human(sim, "sinker", {"position": [0, 0]})
	# Reset 1: both tracks start; the swimmer's carries the L1 grace as delay.
	var reset1: Array[Dictionary] = advance(sim, 10)
	assert_eq(events_of(reset1, "timer_started").size(), 2, "both tracks start at the first submerged reset")
	# Reset 2: the sinker's countdown runs; the swimmer's GRACE consumes first.
	var reset2: Array[Dictionary] = advance(sim, 10)
	var delayed: Dictionary = assert_event(reset2, "timer_delay_consumed",
		"the swim grace eats the first advancement — 'extends the timer before it begins' (L1)")
	assert_eq(String(delayed.get("combatant", "")), "swimmer", "the grace is the swimmer's")
	# Reset 3: the sinker dies; the swimmer is exactly one Clock behind.
	var reset3: Array[Dictionary] = advance(sim, 10)
	var death3: Dictionary = assert_event(reset3, "combatant_died", "the non-swimmer drowns first")
	assert_eq(String(death3.get("combatant", "")), "sinker", "grace = +1 Clock of life")
	assert_true(sim.combatants["swimmer"].alive, "the swimmer breathes one Clock longer")
	# Reset 4 would kill the swimmer — but SURFACING cancels the track.
	move(sim, "swimmer", [2, 3])
	var reset4: Array[Dictionary] = advance(sim, 10)
	var cancelled: Dictionary = assert_event(reset4, "timer_cancelled", "surfacing cancels the drowning track")
	assert_eq(String(cancelled.get("reason", "")), "surfaced", "the cancel names its reason")
	assert_true(sim.combatants["swimmer"].alive, "out of the pool = alive")
	# Grace scaling honesty pin: the grace stays 1 through L1-4 (the L2-4 rows
	# author MOVEMENT; the L6 '+2 Clocks total' rung stays threshold data).
	assert_eq(int(SkillBook.mechanics("swim", 4).get("suffocation_grace_clocks", 0)), 1,
		"grace constant through L1-4 — scaling past 1 lives at the L6 threshold (data)")
	# A dip shorter than the grace never advances the track — the L1 swimmer
	# is exempt in practice.
	add_human(sim, "dipper", {"skills": [{"key": "swim", "level": 1}], "position": [4, 3]})
	var dip1: Array[Dictionary] = advance(sim, 10)
	assert_eq(events_of(dip1, "timer_started").size(), 1, "the dipper's track starts (delayed by the grace)")
	move(sim, "dipper", [3, 4])
	var dip2: Array[Dictionary] = advance(sim, 10)
	assert_event(dip2, "timer_cancelled", "surfaced within the grace — nothing ever advanced")
	assert_true(sim.combatants["dipper"].alive, "the L1 swimmer shrugged the dip off entirely")


# ------------------------------------------------------------------ acrobatics

func test_acrobatics_rough_immunity_and_roll_bonus() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([
		{"type": "rough", "hexes": [[3, 0]]},
		{"type": "difficult", "hexes": [[0, 3]]},
	]))
	add_human(sim, "tumbler", {"skills": [{"key": "acrobatics", "level": 3}]})
	add_human(sim, "walker", {"position": [-2, 0]})
	assert_event(move(sim, "tumbler", [3, 0]), "moved",
		"rough reads 1 for the acrobatics owner — the hop stays free")
	advance(sim)
	move(sim, "tumbler", [0, 0])
	advance(sim)
	# Difficult is NOT acrobatics' lane (quick_step's): it still prices.
	var hard: Array[Dictionary] = move(sim, "tumbler", [0, 3])
	assert_event(hard, "action_declared", "difficult still prices for the acrobat — lanes stay distinct")
	# Passives never declare (the aura rule).
	assert_rejected(declare(sim, "walker", skill("acrobatics", 1)), "passive_skill",
		"acrobatics is passive — owning it is the mechanic")
	assert_rejected(declare(sim, "walker", skill("swim", 1)), "passive_skill", "swim is passive too")
	advance(sim)
	# The authored movement rows extend the declared roll: L3 = +2 over the
	# tactical_roll L1 base 2 -> a 4-space roll lands.
	var far_roll: Array[Dictionary] = declare(sim, "tumbler", skill("tactical_roll", 1, {"to": [4, 3]}))
	assert_event(far_roll, "tactical_roll",
		"+2 acrobatic movement carries the roll to 4 spaces (the PROVISIONAL row reading)")
	assert_rejected(declare(sim, "walker", skill("tactical_roll", 1, {"to": [2, 0]})),
		"roll_out_of_range", "without acrobatics the L1 roll caps at 2")


func test_roll_pays_terrain_leap_does_not() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([{"type": "difficult", "hexes": [[2, 0], [3, 3]]}]))
	add_human(sim, "roller")
	# A roll IS movement: the destination surcharge counts against roll_range —
	# the L1 2-space roll cannot END on difficult ground 2 away.
	assert_rejected(declare(sim, "roller", skill("tactical_roll", 1, {"to": [2, 0]})),
		"roll_out_of_range", "the roll pays the destination-cost contract")
	assert_event(declare(sim, "roller", skill("tactical_roll", 1, {"to": [1, 0]})),
		"tactical_roll", "a 1-space roll onto normal ground still lands")
	advance(sim)
	# The pounce LEAP is airborne — it ignores ground (the ladder's own
	# texture, #20 L9; an arc over the ground is not an entry).
	add_human(sim, "cat", {"position": [0, 3]})
	add_human(sim, "prey", {"position": [4, 3], "team": "enemies"})
	var pounce: Array[Dictionary] = declare(sim, "cat", skill("pounce", 1, {
		"targets": [{"id": "prey", "part": "torso"}],
		"leap_to": [3, 3],
	}))
	assert_event(pounce, "action_declared",
		"a full-range leap ENDING on difficult ground declares fine — leaps never pay terrain")


# ------------------------------------------------------------------ lockpicking

func lock_arena(tier: String) -> Dictionary:
	return terrain_arena([], {"doors": [{"key": "cage", "position": [1, 0],
		"state": "closed", "lock": {"tier": tier, "state": "locked"}}]})


func test_lockpick_full_flow_simple() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, lock_arena("simple"))
	add_human(sim, "picker")
	# The locked door still rejects the door command (the substrate).
	assert_rejected(sim.apply_command({"type": "door", "actor": "picker", "key": "cage",
		"set": "open"}), "door_locked", "a locked door cannot be worked open")
	# Declare the pick: simple prices 1 Moment (the substrate tier table).
	var pick: Array[Dictionary] = declare(sim, "picker", skill("lockpicking", 1, {"door": "cage"}))
	var declared: Dictionary = assert_event(pick, "action_declared", "the pick schedules")
	assert_eq(int(declared.get("cost", 0)), 1, "simple = 1 Moment (LOCK_PICK_MOMENTS)")
	assert_false(bool(declared.get("windup", true)), "a 1-Moment pick is an instant")
	var resolved: Array[Dictionary] = advance(sim)
	var picked: Dictionary = assert_event(resolved, "lock_picked", "resolve calls the R33 API")
	assert_eq(int(picked.get("moments", -1)), 1, "the event reports the Moments actually charged")
	assert_event(resolved, "action_resolved", "the skill resolution completes")
	# The picked door now opens like any unlocked door.
	assert_event(sim.apply_command({"type": "door", "actor": "picker", "key": "cage",
		"set": "open"}), "door_changed", "the picked lock frees the door")


func test_lockpick_tiers_and_gates_pinned() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, lock_arena("moderate"))
	add_human(sim, "picker")
	# Tier access: moderate needs L3 (the data rows).
	assert_rejected(declare(sim, "picker", skill("lockpicking", 1, {"door": "cage"})),
		"lock_tier_beyond_skill", "L1 cannot touch a moderate lock")
	var l3: Array[Dictionary] = declare(sim, "picker", skill("lockpicking", 3, {"door": "cage"}))
	var declared: Dictionary = assert_event(l3, "action_declared", "L3 reaches moderate")
	assert_eq(int(declared.get("cost", 0)), 2, "moderate = 2 Moments at L3 (no discount yet)")
	assert_true(bool(declared.get("windup", false)), "a 2-Moment pick is a real windup")
	var landed: Array[Dictionary] = advance(sim, 3)
	assert_event(landed, "lock_picked", "the windup pick resolves")
	assert_eq(String(((sim.arena.doors[0] as Dictionary).get("lock", {}) as Dictionary).get("state", "")),
		"unlocked", "…and flipped the lock")
	# L4's authored "-1 Moment to Simple and Moderate": moderate prices 1.
	var sim2: CombatSim = make_sim()
	set_arena(sim2, lock_arena("moderate"))
	add_human(sim2, "picker")
	var l4: Array[Dictionary] = declare(sim2, "picker", skill("lockpicking", 4, {"door": "cage"}))
	assert_eq(int(assert_event(l4, "action_declared", "L4 declare").get("cost", 0)), 1,
		"L4 moderate = 1 Moment (the -1 row)")
	# Simple already sits on the 1-Moment floor: the -1 row floors at 1.
	var sim3: CombatSim = make_sim()
	set_arena(sim3, lock_arena("simple"))
	add_human(sim3, "picker")
	var l2: Array[Dictionary] = declare(sim3, "picker", skill("lockpicking", 2, {"door": "cage"}))
	assert_eq(int(assert_event(l2, "action_declared", "L2 declare").get("cost", 0)), 1,
		"simple floors at 1 Moment (PLACEHOLDER R14 — a scheduled act costs at least one)")
	# Magical rejects without the special capability (the L6/L9 rungs stay data).
	var sim4: CombatSim = make_sim()
	set_arena(sim4, lock_arena("magical"))
	add_human(sim4, "picker")
	assert_rejected(declare(sim4, "picker", skill("lockpicking", 4, {"door": "cage"})),
		"magical_lock_needs_special", "no special capability below the threshold rungs")
	# Complex is the L5 threshold — unreachable at L1-4.
	var sim5: CombatSim = make_sim()
	set_arena(sim5, lock_arena("complex"))
	add_human(sim5, "picker")
	assert_rejected(declare(sim5, "picker", skill("lockpicking", 4, {"door": "cage"})),
		"lock_tier_beyond_skill", "complex stays threshold data at L1-4")


func test_lockpick_feint_and_interruption_collapse() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, lock_arena("moderate"))
	# Mind 0 makes the R24 feint-read IMPOSSIBLE (0 + d4 max < threshold 5),
	# so the feint lands deterministically — no rng consumed (the R22 skip).
	add_human(sim, "picker", {"traits": {"physique": 3, "reflexes": 3, "mind": 0, "charm": 3}})
	add_human(sim, "trickster", {"position": [0, 1]})
	# The pick winds up (L3 moderate, 2 Moments); the trickster feints the
	# picker the same tick — the feint's pending consequence collapses the
	# pick at its resolution (Forced Action – Tool, the standard machinery).
	declare(sim, "picker", skill("lockpicking", 3, {"door": "cage"}))
	assert_event(declare(sim, "trickster", skill("feint", 1, {
		"targets": [{"id": "picker", "part": "torso"}]})),
		"action_declared", "the feint declares against the winding-up picker")
	advance(sim)  # the feint resolves; the pick still winds
	advance(sim)
	var slot: Array[Dictionary] = advance(sim)  # the pick's own slot: collapse
	assert_no_event(slot, "lock_picked", "the feinted pick never opens the lock")
	assert_event(slot, "action_invalidated", "the pick collapses")
	assert_event(slot, "forced_action_triggered", "…into the Forced Action – Tool roll")
	assert_eq(String(((sim.arena.doors[0] as Dictionary).get("lock", {}) as Dictionary).get("state", "")),
		"locked", "the lock survives the feinted attempt")
	# Premise break mid-windup: a direct/GM pick unlocks the door while a
	# windup runs — the resolve collapses (Forced Tool), no double-flip.
	var sim2: CombatSim = make_sim()
	set_arena(sim2, lock_arena("moderate"))
	add_human(sim2, "picker")
	declare(sim2, "picker", skill("lockpicking", 3, {"door": "cage"}))
	sim2.pick_lock("picker", "cage")  # the direct-call API (test/GM driver)
	var broken: Array[Dictionary] = advance(sim2, 3)
	assert_event(broken, "action_invalidated", "the windup premise broke")
	assert_event(broken, "forced_action_triggered", "…and collapses into the Tool roll")


# ------------------------------------------------------------------ the walls

func test_poison_wall_line_entry_gate_and_duration() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([]))
	add_human(sim, "caster")
	add_human(sim, "walker", {"position": [3, 1]})
	var cast: Array[Dictionary] = declare(sim, "caster", skill("poison_wall", 1, {
		"from": [2, 0], "to": [2, 2]}))
	assert_event(cast, "action_declared", "the wall declares (2-Moment windup)")
	var landed: Array[Dictionary] = advance(sim, 3)
	var created: Dictionary = assert_event(landed, "zone_created", "the line zone exists")
	assert_eq(String(created.get("key", "")), "poison_wall", "keyed to the skill")
	assert_eq((created.get("hexes", []) as Array).size(), 3, "the declared 3-hex line")
	assert_eq(int(created.get("duration_clocks", 0)), 1, "persists 1 Clock (authored)")
	# UNWOUNDED entry: the poison ENTRY GATE holds — nothing lands.
	var dry_walk: Array[Dictionary] = move(sim, "walker", [2, 1])
	assert_event(dry_walk, "zone_effect_applied", "on_enter fires")
	var ignored: Dictionary = assert_event(dry_walk, "condition_ignored",
		"an unwounded walker shrugs the vapor — the entry-condition gate")
	assert_eq(String(ignored.get("reason", "")), "no_entry_condition", "the gate names itself")
	# WOUNDED entry: bleed the walker, walk out and back in — Poison T1 lands.
	advance(sim)
	sim.apply_command({"type": "apply_condition", "target": "walker", "part": "torso",
		"condition": "bleeding"})
	move(sim, "walker", [3, 1])
	advance(sim)
	var wet_walk: Array[Dictionary] = move(sim, "walker", [2, 1])
	var poisoned: Dictionary = assert_event(wet_walk, "condition_applied",
		"the open wound lets the toxin in")
	assert_eq(String(poisoned.get("condition", "")), "poison", "Poison lands")
	assert_eq(String((sim.combatants["walker"].condition_instance("torso", "poison")).get("poison_type", "")),
		"pneumo", "the authored toxin below the L6 choose rung")
	assert_eq(String((sim.combatants["walker"].condition_instance("torso", "poison")).get("source", "")),
		"caster", "the wall's owner authors the wound (R32 attribution)")
	# The next reset: the occupancy bite fires, then the 1-Clock wall expires.
	var reset: Array[Dictionary] = advance_to_reset(sim)
	var expired: Dictionary = assert_event(reset, "zone_expired", "the 1-Clock wall dies at its reset")
	assert_eq(String(expired.get("reason", "")), "duration", "outlasted, not destroyed")


func test_frost_wall_blocks_attackable_destroyed_unblocks() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([]))
	add_human(sim, "caster")
	add_human(sim, "breaker", {"position": [1, 1]})
	declare(sim, "caster", skill("frost_wall", 1, {"from": [2, 0], "to": [2, 2]}))
	var landed: Array[Dictionary] = advance(sim, 3)
	var created: Dictionary = assert_event(landed, "zone_created", "the ice line exists")
	assert_eq(int(created.get("hp", 0)), 3, "wall HP 3 at L1")
	assert_true(bool(created.get("blocks_movement", false)), "solid ice blocks")
	var zone_id: int = int(created.get("zone", 0))
	# The wall blocks like a wall (Arena.is_wall parity).
	assert_rejected(move(sim, "breaker", [2, 1]), "hex_blocked", "no walking through ice")
	# Attack the zone (the additive target shape): crush 2 + physique push 1
	# -> force 3 vs robustness 1 -> 2 HP off; the striking limb is CHILLED.
	declare(sim, "breaker", {"kind": "attack", "cost": 1,
		"zone_target": zone_id, "damage": {"type": "crushed", "amount": 2}})
	var hit: Array[Dictionary] = advance(sim)
	var attacked: Dictionary = assert_event(hit, "zone_attacked", "the strike resolves against the wall")
	assert_eq(int(attacked.get("force", 0)), 3, "force = amount 2 + floor(3/2) physique push (R14)")
	assert_eq(int(attacked.get("robustness", 0)), 1, "Zones.WALL_ROBUSTNESS (PLACEHOLDER R14)")
	assert_eq(int(attacked.get("amount", 0)), 2, "net damage through the gate")
	assert_eq(int(first_event(hit, "zone_damaged").get("hp", -1)), 1, "3 HP - 2 = 1")
	var chilled: Dictionary = assert_event(hit, "condition_applied", "the ice bites back")
	assert_eq(String(chilled.get("condition", "")), "chilled", "Chilled to the striking limb")
	assert_eq(String(chilled.get("combatant", "")), "breaker", "…on the striker")
	# A too-weak blow is BLOCKED by the gate (0 damage is a real outcome, R14).
	declare(sim, "breaker", {"kind": "attack", "cost": 1,
		"zone_target": zone_id, "damage": {"type": "crushed", "amount": 0}})
	var tap_hit: Array[Dictionary] = advance(sim)
	assert_eq(int(assert_event(tap_hit, "zone_attacked", "the gate ran").get("amount", -1)), 0,
		"force 1 vs robustness 1 = blocked (R14: 0 damage is a real outcome)")
	assert_no_event(tap_hit, "zone_damaged", "a blocked blow wears nothing down")
	# BURN deals double vs frost: burn 1 + push 1 = force 2, net 1, doubled
	# to 2 -> the wall (1 HP) melts and UNBLOCKS.
	declare(sim, "breaker", {"kind": "attack", "cost": 1,
		"zone_target": zone_id, "damage": {"type": "burn", "amount": 1}})
	var melt: Array[Dictionary] = advance(sim)
	assert_eq(int(assert_event(melt, "zone_attacked", "the burn resolves").get("amount", 0)), 2,
		"net 1 doubled vs frost (the authored burn weakness)")
	var expired: Dictionary = assert_event(melt, "zone_expired", "the wall melts at 0")
	assert_eq(String(expired.get("reason", "")), "destroyed", "destroyed, not outlasted")
	assert_event(move(sim, "breaker", [2, 1]), "moved", "the melted wall frees the hex")


func test_zone_attack_validation_and_frost_duration() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([]))
	add_human(sim, "caster")
	add_human(sim, "archer", {"position": [-4, 0]})
	# Fire wall: indestructible — never a legal target.
	declare(sim, "caster", skill("fire_wall", 1, {"from": [2, 0], "to": [2, 1]}))
	var fire_landed: Array[Dictionary] = advance(sim, 4)
	var fire_id: int = int(assert_event(fire_landed, "zone_created", "fire wall up").get("zone", 0))
	assert_rejected(declare(sim, "archer", {"kind": "attack", "cost": 1,
		"zone_target": fire_id, "damage": {"type": "crushed", "amount": 5}}),
		"zone_indestructible", "'cannot be destroyed — only outlasted'")
	assert_rejected(declare(sim, "archer", {"kind": "attack", "cost": 1,
		"zone_target": 999, "damage": {"type": "crushed", "amount": 5}}),
		"zone_unknown", "no such zone")
	# Frost persists 2 Clocks: survives the first reset, dies at the second.
	declare(sim, "caster", skill("frost_wall", 1, {"from": [-2, 3], "to": [-2, 4]}))
	advance(sim, 3)
	var frost_id: int = 0
	for zone: Dictionary in sim.zones.zones:
		if String(zone.get("key", "")) == "frost_wall":
			frost_id = int(zone.get("id", 0))
	assert_true(frost_id > 0, "the frost wall exists")
	# The distant archer cannot reach the frost line with a melee swing.
	assert_rejected(declare(sim, "archer", {"kind": "attack", "cost": 1,
		"zone_target": frost_id, "damage": {"type": "crushed", "amount": 2}}),
		"out_of_range", "reach gates the zone attack like any attack")
	advance_to_reset(sim)
	var still: bool = false
	for zone: Dictionary in sim.zones.zones:
		if int(zone.get("id", 0)) == frost_id:
			still = true
	assert_true(still, "the 2-Clock wall survives its first reset")
	advance_to_reset(sim)
	var gone: bool = true
	for zone: Dictionary in sim.zones.zones:
		if int(zone.get("id", 0)) == frost_id:
			gone = false
	assert_true(gone, "…and expires at the second (duration 2)")


func test_fire_wall_burns_enter_t1_occupy_t2() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([]))
	add_human(sim, "caster")
	add_human(sim, "stander", {"position": [2, 1]})
	add_human(sim, "walker", {"position": [3, 3]})
	# The wall rises UNDER the stander (fire never blocks — legal placement;
	# standing there at creation is occupancy, not entry: R32).
	declare(sim, "caster", skill("fire_wall", 1, {"from": [2, 0], "to": [2, 2]}))
	var landed: Array[Dictionary] = advance(sim, 4)
	assert_event(landed, "zone_created", "the curtain exists")
	assert_no_event(landed, "condition_applied", "materializing under a body is not entering")
	# Walking IN takes Burn T1 (attributed to the caster).
	var walk_in: Array[Dictionary] = move(sim, "walker", [2, 2])
	var t1: Dictionary = assert_event(walk_in, "condition_applied", "passing into the fire burns")
	assert_eq(String(t1.get("condition", "")), "burn", "Burn")
	assert_eq(int(t1.get("tier", 0)), 1, "Tier 1 on entry")
	assert_eq(String((sim.combatants["walker"].condition_instance("torso", "burn")).get("source", "")),
		"caster", "the burn credits the caster (takedown-v2 attribution)")
	# The reset: the STANDER (inside since creation) takes the occupy bite —
	# a fresh Burn T2 ("starting inside") — then the 1-Clock curtain expires.
	var reset: Array[Dictionary] = advance_to_reset(sim)
	var stander_burn: Dictionary = {}
	for event: Dictionary in events_of(reset, "condition_applied"):
		if String(event.get("combatant", "")) == "stander":
			stander_burn = event
	assert_eq(String(stander_burn.get("condition", "")), "burn", "the occupant burns at the reset")
	assert_eq(int(stander_burn.get("tier", 0)), 2, "Tier 2 for starting inside (authored)")
	assert_event(reset, "zone_expired", "the 1-Clock curtain is outlasted at its reset")


func test_wall_declare_validation() -> void:
	var sim: CombatSim = make_sim()
	set_arena(sim, terrain_arena([], {"walls": [[0, -2]]}))
	add_human(sim, "caster")
	add_human(sim, "bystander", {"position": [3, 0]})
	# Too long: a 6-hex line overruns the L1 length 5.
	assert_rejected(declare(sim, "caster", skill("frost_wall", 1, {"from": [2, -2], "to": [2, 3]})),
		"wall_too_long", "L1 frost caps at 5 hexes")
	# Out of range: a hex beyond the spec range 5.
	assert_rejected(declare(sim, "caster", skill("poison_wall", 1, {"from": [4, 1], "to": [4, 2]})),
		"out_of_range", "hex [4,2] sits 6 away — every wall hex must be reachable")
	# On an authored solid: the zones.create gate, mirrored at declare.
	assert_rejected(declare(sim, "caster", skill("poison_wall", 1, {"from": [0, -2], "to": [0, -2]})),
		"wall_on_solid", "no vapor inside solid rock")
	# Behind the solid: no line of sight (the aoe_blast precedent).
	assert_rejected(declare(sim, "caster", skill("poison_wall", 1, {"from": [0, -3], "to": [0, -3]})),
		"no_line_of_sight", "you conjure where you can see")
	# A BLOCKING wall may not rise on a living body (the door-close rule).
	assert_rejected(declare(sim, "caster", skill("frost_wall", 1, {"from": [3, 0], "to": [3, 1]})),
		"zone_blocked_by_body", "frost L8 'raise it under a target' stays data")
	# The fire/poison walls are non-blocking: the same line declares fine.
	assert_event(declare(sim, "caster", skill("fire_wall", 1, {"from": [3, 0], "to": [3, 1]})),
		"action_declared", "a non-blocking curtain may cover a body")


# ------------------------------------------- determinism + serialization

func test_determinism_and_serialization_roundtrip() -> void:
	var arena_cfg: Dictionary = terrain_arena([
		{"type": "difficult", "hexes": [[3, 0]]},
		{"type": "water", "hexes": [[0, 3], [0, 4]]},
	], {"doors": [{"key": "cage", "position": [-1, 0], "state": "closed",
		"lock": {"tier": "simple", "state": "locked"}}]})
	var log: Array[Dictionary] = [
		{"type": "set_arena", "arena": arena_cfg},
		{"type": "add_combatant", "combatant": {"id": "hero", "name": "hero",
			"race": "human", "position": [0, 0],
			"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3},
			"skills": [{"key": "swim", "level": 1}, {"key": "acrobatics", "level": 2}]}},
		{"type": "add_combatant", "combatant": {"id": "mage", "name": "mage",
			"race": "human", "position": [1, 1],
			"traits": {"physique": 3, "reflexes": 3, "mind": 4, "charm": 3}}},
		{"type": "add_combatant", "combatant": {"id": "diver", "name": "diver",
			"race": "human", "position": [0, 3],
			"traits": {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}}},
		{"type": "declare_action", "actor": "hero", "action":
			{"kind": "skill", "key": "quick_step", "level": 2}},
		{"type": "move", "actor": "hero", "to": [3, 0]},
		{"type": "declare_action", "actor": "mage", "action":
			{"kind": "skill", "key": "frost_wall", "level": 1, "from": [3, 3], "to": [3, 4]}},
	]
	for i: int in range(12):
		log.append({"type": "advance_tick"})
	log.append({"type": "move", "actor": "hero", "to": [3, 2]})
	log.append({"type": "declare_action", "actor": "hero", "action":
		{"kind": "attack", "cost": 1, "zone_target": 1,
			"damage": {"type": "crushed", "amount": 2}}})
	for i: int in range(10):
		log.append({"type": "advance_tick"})

	var sim_a: CombatSim = make_sim(777)
	var sim_b: CombatSim = make_sim(777)
	for cmd: Dictionary in log:
		sim_a.apply_command(cmd.duplicate(true))
		sim_b.apply_command(cmd.duplicate(true))
	assert_eq(sim_a.state_hash(), sim_b.state_hash(),
		"identical (seed, command log) -> identical hash with every Round-3a feature live")
	# The stride window + the submersion timer serialized honestly.
	var hero_dict: Dictionary = sim_a.to_dict()["combatants"]["hero"]
	assert_true(hero_dict.has("quick_step_until_tick"), "the used stride window serializes")
	var diver_timers: Array = (sim_a.to_dict()["combatants"]["diver"] as Dictionary).get("timers", [])
	var has_submersion: bool = false
	for timer: Variant in diver_timers:
		if String((timer as Dictionary).get("cause", "")) == "submersion":
			has_submersion = true
	assert_true(has_submersion, "the drowning track serializes with its cause marker")
	# Round-trip: restore mid-state, replay a tail, hashes stay locked.
	var sim_c: CombatSim = CombatSim.from_dict(sim_a.to_dict())
	assert_eq(sim_c.state_hash(), sim_a.state_hash(), "restore is exact")
	var tail: Array[Dictionary] = [
		{"type": "move", "actor": "hero", "to": [2, 2]},
		{"type": "advance_tick"}, {"type": "advance_tick"},
	]
	for cmd: Dictionary in tail:
		sim_a.apply_command(cmd.duplicate(true))
		sim_c.apply_command(cmd.duplicate(true))
	assert_eq(sim_c.state_hash(), sim_a.state_hash(), "the replayed tail stays in lockstep")
