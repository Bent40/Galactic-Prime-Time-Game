extends SimTestBase
## Regression: forced_body_required must not crash on a condition tier whose
## forced_action_type is JSON null (e.g. burn T1). Previously `String(null)` threw
## "Invalid call to constructor 'String'" and spammed the log whenever a burning
## combatant acted (condition_engine.gd:122).


func test_forced_body_required_handles_null_forced_action_type() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"position": [0, 0]})
	var c: CombatantState = sim.combatants["a"]
	# Burn T1 on the acting part: its forced_action_type is null in the data.
	sim.cond.apply(c, "torso", "burn", sim.clock.tick, {"tier": 1})
	# Must return a clean bool (false — T1 burn does not force a Body action) with
	# no "Invalid call 'String' constructor" error pushed.
	var forced: bool = sim.cond.forced_body_required(c, "torso")
	assert_false(forced, "burn T1 (null forced_action_type) does not force a Body action, and does not crash")
	# Burn T2 DOES force a Body action — proves the check still works positively.
	sim.cond.apply(c, "torso", "burn", sim.clock.tick, {"tier": 2})
	assert_true(sim.cond.forced_body_required(c, "torso"), "burn T2 forces a Body action")
