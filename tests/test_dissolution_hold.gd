extends SimTestBase
## R30 — Dissolution: grace, then a climbing Hold Threshold (v1 §8.2 + §10 errata,
## owner 2026-08-18). The flat 2-Clock timer is gone. One Clock of grace, then a
## FREE per-Moment check against `1 + moments * escalation`, resolved on R22/R24's
## threshold machinery against MIND. One failure is permanent removal. Removing the
## cause freezes the number; it never resets. Escalation rides the SOURCE, which is
## the knob that keeps the condition lethal against a farmed Mind.


func dissolve(sim: CombatSim, id: String, part: String = "head", ctx: Dictionary = {}) -> Array[Dictionary]:
	var cmd: Dictionary = {"type": "apply_condition", "target": id, "part": part, "condition": "dissolution"}
	cmd.merge(ctx, true)
	return sim.apply_command(cmd)


func holds_in(events: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in events:
		if String(e.get("type", "")) == "dissolution_hold":
			out.append(e)
	return out


func timer_of(sim: CombatSim, id: String) -> Dictionary:
	for t: Dictionary in sim.combatants[id].timers:
		if String(t.get("kind", "")) == "dissolution":
			return t
	return {}


# ---------------------------------------------------------------- grace

func test_the_first_clock_is_grace_and_nothing_is_checked() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	dissolve(sim, "h")
	var ev: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_true(holds_in(ev).is_empty(), "no Hold check happens during the Clock of grace")
	assert_true(sim.combatants["h"].alive and not sim.combatants["h"].removed_from_play, "and nobody is removed")


func test_checks_begin_once_grace_is_spent() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	dissolve(sim, "h")
	advance(sim, Clock.TICKS_PER_CLOCK)          # burn the grace Clock
	var ev: Array[Dictionary] = advance(sim, 1)  # the very next Moment
	var rows: Array[Dictionary] = holds_in(ev)
	assert_eq(rows.size(), 1, "exactly one Hold check per Moment")
	assert_eq(int(rows[0]["threshold"]), 1, "the first threshold is 1 + 0 elapsed")
	assert_true(bool(rows[0]["held"]) and bool(rows[0]["auto"]), "Mind 3 auto-holds against 1 — and consumes no rng")


func test_psychic_resistance_buys_grace_not_a_slower_climb() -> void:
	# R6's reward, re-pointed by R30: +1 CLOCK OF GRACE per tier. It delays when the
	# climb starts; it never slows the climb.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 30, "charm": 3}})
	dissolve(sim, "h")
	var t: Dictionary = timer_of(sim, "h")
	assert_true(int(t.get("grace_clocks", 0)) >= 2, "Mind 30 is 1 psychic tier (over_cap /15), so grace is 1 + tiers")
	var ev: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
	assert_true(holds_in(ev).is_empty(), "still inside grace after one Clock")


# ---------------------------------------------------------------- the climb

func test_the_threshold_climbs_one_per_moment_by_default() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 40, "charm": 3}})
	dissolve(sim, "h")
	advance(sim, Clock.TICKS_PER_CLOCK * 4)  # clear grace (Mind 40 = 2 tiers -> 3 Clocks)
	var seen: Array[int] = []
	for i: int in range(5):
		for row: Dictionary in holds_in(advance(sim, 1)):
			seen.append(int(row["threshold"]))
	assert_true(seen.size() >= 5, "a check every Moment")
	for i: int in range(1, seen.size()):
		assert_eq(seen[i] - seen[i - 1], 1, "default escalation is +1 per Moment")


func test_escalation_rides_the_source_not_the_victim() -> void:
	# The whole point of R30: a divine source is dangerous to a farmed Mind because
	# the SOURCE escalates faster, not because the victim's stat got worse.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 12, "charm": 3}})
	dissolve(sim, "h", "head", {"escalation": 3})
	assert_eq(int(timer_of(sim, "h").get("escalation", 0)), 3, "a divine source stores +3/Moment")
	advance(sim, Clock.TICKS_PER_CLOCK)
	var seen: Array[int] = []
	for i: int in range(3):
		for row: Dictionary in holds_in(advance(sim, 1)):
			seen.append(int(row["threshold"]))
	assert_eq(seen[0], 1, "still opens at 1")
	assert_eq(seen[1], 4, "then +3")
	assert_eq(seen[2], 7, "then +3 again")


func test_a_farmed_mind_survives_longer_but_not_forever() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 24, "charm": 3}})
	dissolve(sim, "h", "head", {"escalation": 3})
	var removed := false
	for i: int in range(Clock.TICKS_PER_CLOCK * 12):
		advance(sim, 1)
		if sim.combatants["h"].removed_from_play:
			removed = true
			break
	assert_true(removed, "Mind 24 against a divine aura still loses — that is the knob working")


# ---------------------------------------------------------------- §14 disclosure

func test_an_unreachable_threshold_is_announced_and_rolls_nothing() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 1, "charm": 3}})
	dissolve(sim, "h", "head", {"escalation": 3})
	advance(sim, Clock.TICKS_PER_CLOCK)
	var rows: Array[Dictionary] = []
	for i: int in range(4):
		rows.append_array(holds_in(advance(sim, 1)))
		if sim.combatants["h"].removed_from_play:
			break
	var unreachable: Array[Dictionary] = []
	for r: Dictionary in rows:
		if bool(r.get("unreachable", false)):
			unreachable.append(r)
	assert_true(unreachable.size() >= 1, "§14 obliges announcing the impossible check")
	assert_eq(int(unreachable[0]["roll"]), 0, "and no die is rolled for it")
	assert_false(bool(unreachable[0]["held"]), "an unreachable check is a failure")


func test_moments_left_is_answerable_before_the_table_asks() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 7, "charm": 3}})
	assert_eq(sim.cond.dissolution_moments_left(sim.combatants["h"]), -1, "-1 when nothing is running")
	dissolve(sim, "h")
	var before: int = sim.cond.dissolution_moments_left(sim.combatants["h"])
	assert_true(before > 0, "a live Dissolution can always say how many Moments remain")
	advance(sim, Clock.TICKS_PER_CLOCK)
	advance(sim, 1)
	assert_eq(sim.cond.dissolution_moments_left(sim.combatants["h"]), before - 1, "and it counts down as checks are spent")


# ---------------------------------------------------------------- one failure is final

func test_one_failure_is_permanent_removal_not_death() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 1, "charm": 3}})
	dissolve(sim, "h", "head", {"escalation": 3})
	var died := false
	for i: int in range(Clock.TICKS_PER_CLOCK * 4):
		for e: Dictionary in advance(sim, 1):
			if String(e.get("type", "")) == "combatant_died":
				died = true
		if sim.combatants["h"].removed_from_play:
			break
	assert_true(sim.combatants["h"].removed_from_play, "the contestant is removed from play")
	assert_false(died, "R5 is unchanged — mind_collapsed, never died")


func test_a_cosmetic_part_still_cannot_be_collapsed() -> void:
	# The F2 lethal-exposed gate outranks R30, exactly as it outranked the old timer.
	var sim: CombatSim = make_sim()
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": "boss", "name": "boss", "enemy": "incinedile", "team": "enemies", "position": [0, 0]}})
	dissolve(sim, "boss", "head", {"escalation": 3})
	for i: int in range(Clock.TICKS_PER_CLOCK * 6):
		advance(sim, 1)
	assert_false(sim.combatants["boss"].removed_from_play, "dissolution on a puppet's cosmetic head still collapses nothing")


# ---------------------------------------------------------------- freeze, never reset

func test_removing_the_cause_freezes_and_does_not_reset() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 40, "charm": 3}})
	dissolve(sim, "h")
	advance(sim, Clock.TICKS_PER_CLOCK * 4)
	advance(sim, 3)
	var at_freeze: int = int(timer_of(sim, "h").get("moments", 0))
	assert_true(at_freeze > 0, "some checks were spent before we walked out")
	sim.cond.freeze_dissolution(sim.combatants["h"])
	advance(sim, 5)
	assert_eq(int(timer_of(sim, "h").get("moments", 0)), at_freeze, "a frozen threshold does not climb")
	sim.cond.freeze_dissolution(sim.combatants["h"], false)
	advance(sim, 1)
	assert_eq(int(timer_of(sim, "h").get("moments", 0)), at_freeze + 1,
		"and thawing RESUMES from where it stood — it never resets to 1")


# ---------------------------------------------------------------- determinism

func test_the_hold_check_is_a_pure_function_of_seed_and_command_log() -> void:
	var a: CombatSim = make_sim(99)
	var b: CombatSim = make_sim(99)
	for sim: CombatSim in [a, b]:
		add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 6, "charm": 3}})
		dissolve(sim, "h", "head", {"escalation": 2})
		advance(sim, Clock.TICKS_PER_CLOCK * 3)
	assert_eq(a.state_hash(), b.state_hash(), "two runs of the same log agree through the Hold checks")
	assert_eq(int(timer_of(a, "h").get("moments", 0)), int(timer_of(b, "h").get("moments", 0)), "same Moments spent")


func test_a_dissolving_combatant_round_trips_through_serialization() -> void:
	var sim: CombatSim = make_sim(7)
	add_human(sim, "h", {"traits": {"physique": 3, "reflexes": 3, "mind": 40, "charm": 3}})
	dissolve(sim, "h", "head", {"escalation": 2})
	advance(sim, Clock.TICKS_PER_CLOCK * 4)
	advance(sim, 2)
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "the R30 timer shape survives to_dict/from_dict")
	var t: Dictionary = timer_of(restored, "h")
	assert_eq(int(t.get("escalation", 0)), 2, "escalation survives")
	assert_true(t.has("moments") and t.has("grace_clocks") and t.has("frozen"), "so do the other R30 fields")
