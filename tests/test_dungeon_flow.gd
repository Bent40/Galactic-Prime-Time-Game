extends SimTestBase
## KAN-5 wave 4b — DUNGEON FLOW: the room graph (rules-addendum R29).
##
## Under test:
##   * the authored demo BRANCH map's data contract (Brood Landing -> choice
##     of Kennel Gauntlet or Service Corridor -> the Incine-Dile den, terminal;
##     the den authors the wave-4b doors);
##   * BOTH branch drives, fully live through the controller: choice A (the
##     kennel) and choice B (the service corridor) each reach the den and WIN
##     the run (terminal auto-finish — no end_run), with per-drive determinism
##     and the bare-RunState-replay purity pin (run state = pure function of
##     (run seed, ordered run-command log), choose_exit included);
##   * choose_exit gating (mid-combat / mid-offer / outside the beat / unknown
##     key), the exits view, and the offer-outranks-exploration ordering;
##   * LINEAR backward compat pinned vs a control: a def set with no exits
##     runs exactly as the pre-graph engine (same events, end_run WIN, and the
##     to_dict key set carries NO graph key — the serialization compat pin);
##   * the hype chain PERSISTS through exploration beats (the #32 retention
##     ladder math is unchanged across a chosen exit);
##   * the v1 DAG guards (room_not_revisitable; revisitable: true honored);
##   * save/restore MID-exploration-beat -> identical continuation (in-memory
##     AND the disk envelope).
##
## Fight drives are the test_run_state.gd guarded-lockstep idiom (identical
## state always re-issues identical commands).

const DEMO_RUN_PATH := "res://data/demo_run.json"
const MAX_FIGHT_TICKS := 60


# ---------------------------------------------------------------- plumbing

func _controller() -> Node:
	return (load("res://controller/game_controller.gd") as GDScript).new()


static func demo_run_def() -> Dictionary:
	return (SimTestBase.load_json(DEMO_RUN_PATH) as Dictionary).get("run", {})


func _start_demo_run(gc: Node) -> Array[Dictionary]:
	var def: Dictionary = demo_run_def()
	return gc.start_run(int(def.get("run_seed", 0)), def.get("party", []),
		def.get("encounters", []), load_static_data())


func _declare(gc: Node, actor: String, action: Dictionary) -> Array[Dictionary]:
	return gc.apply_command({"type": "declare_action", "actor": actor, "action": action})


## Encounter 1 (brood_landing) — the test_run_state.gd drive, verbatim.
func _drive_encounter_one(gc: Node) -> void:
	gc.apply_run_command({"type": "begin_encounter"})
	_declare(gc, "roach_dog_1", attack_action("crushed", 4, "imani", "torso"))
	_declare(gc, "roach_dog_2", attack_action("crushed", 3, "sasha", "torso"))
	var pairs: Array = [["imani", "roach_dog_1"], ["dario", "roach_dog_3"], ["sasha", "roach_dog_2"]]
	for _i: int in range(20):
		if bool(gc.combat_status().get("over", false)):
			return
		var tick: int = gc.sim.clock.tick
		for pair: Variant in pairs:
			var attacker: CombatantState = gc.sim.combatants.get(String((pair as Array)[0]))
			var target: CombatantState = gc.sim.combatants.get(String((pair as Array)[1]))
			if attacker == null or target == null or not target.alive:
				continue
			if not attacker.can_act(tick) or tick < attacker.next_action_tick or attacker.windup_pending:
				continue
			if CombatantState.hex_distance(attacker.position, target.position) > 2:
				continue
			_declare(gc, attacker.id, attack_action("crushed", 3, target.id, "carapace", {"attack_range": 2}))
		gc.run_enemy_turn()
		gc.apply_command({"type": "advance_tick"})


func _treat_carried_wounds(gc: Node) -> void:
	for id: String in ["imani", "sasha"]:
		if gc.sim.combatants.has(id):
			gc.apply_command({"type": "treat", "target": id, "part": "torso", "condition": "crushed", "mode": "resolve"})


## The kennel fight (branch A) — test_run_state.gd's drive, verbatim.
func _fight_hounds(gc: Node, max_ticks: int) -> void:
	for _i: int in range(max_ticks):
		if bool(gc.combat_status().get("over", false)):
			return
		var tick: int = gc.sim.clock.tick
		var pairs: Array = [["imani", "war_hound_1"], ["sasha", "war_hound_2"]]
		for pair: Variant in pairs:
			var attacker: CombatantState = gc.sim.combatants.get(String((pair as Array)[0]))
			var target: CombatantState = gc.sim.combatants.get(String((pair as Array)[1]))
			if attacker == null or target == null or not target.alive:
				continue
			if attacker.id == "sasha" and tick < 1:
				continue
			if not attacker.can_act(tick) or tick < attacker.next_action_tick or attacker.windup_pending:
				continue
			if CombatantState.hex_distance(attacker.position, target.position) > 2:
				continue
			_declare(gc, attacker.id, attack_action("crushed", 9, target.id, "torso", {"attack_range": 2}))
		gc.run_enemy_turn()
		gc.apply_command({"type": "advance_tick"})


## The service-corridor fight (branch B): the roach pair falls to the same
## guarded pattern (any net >= 1 kills a 1-HP carapace).
func _fight_corridor(gc: Node, max_ticks: int) -> void:
	for _i: int in range(max_ticks):
		if bool(gc.combat_status().get("over", false)):
			return
		var tick: int = gc.sim.clock.tick
		var pairs: Array = [["imani", "roach_dog_1"], ["sasha", "roach_dog_2"]]
		for pair: Variant in pairs:
			var attacker: CombatantState = gc.sim.combatants.get(String((pair as Array)[0]))
			var target: CombatantState = gc.sim.combatants.get(String((pair as Array)[1]))
			if attacker == null or target == null or not target.alive:
				continue
			if not attacker.can_act(tick) or tick < attacker.next_action_tick or attacker.windup_pending:
				continue
			if CombatantState.hex_distance(attacker.position, target.position) > 2:
				continue
			_declare(gc, attacker.id, attack_action("crushed", 3, target.id, "carapace", {"attack_range": 2}))
		gc.run_enemy_turn()
		gc.apply_command({"type": "advance_tick"})


func _treat_lingering_wounds(gc: Node) -> void:
	for id: String in ["imani", "dario", "sasha"]:
		var c: CombatantState = gc.sim.combatants.get(id)
		if c == null:
			continue
		var part_keys: Array = c.parts.keys()
		part_keys.sort()
		for part_key: Variant in part_keys:
			for cond_id: String in ["bleeding", "crushed"]:
				if c.condition_tier(String(part_key), cond_id) > 0:
					gc.apply_command({"type": "treat", "target": id, "part": String(part_key),
						"condition": cond_id, "mode": "resolve"})


## The den finale — test_run_state.gd's boss drive, verbatim.
func _fight_boss(gc: Node, max_ticks: int) -> void:
	for _i: int in range(max_ticks):
		if bool(gc.combat_status().get("over", false)):
			return
		var boss: CombatantState = gc.sim.combatants.get("boss")
		var imani: CombatantState = gc.sim.combatants.get("imani")
		var tick: int = gc.sim.clock.tick
		if boss != null and boss.alive and imani != null and imani.can_act(tick) \
				and tick >= imani.next_action_tick and not imani.windup_pending:
			if not boss.breached:
				_declare(gc, "imani", attack_action("crushed", 10, "boss", "left_hand", {"attack_range": 2}))
			elif int((boss.parts.get("network", {}) as Dictionary).get("hp", 0)) > 0:
				_declare(gc, "imani", attack_action("crushed", 55, "boss", "network", {"attack_range": 2}))
		gc.run_enemy_turn()
		gc.apply_command({"type": "advance_tick"})


## One full BRANCH drive: enc 1 + accept, choose `exit_key`, fight the chosen
## mid room, then the den. Returns {hash, outcome, events} where `events` is
## every run event seen (for beat/ordering assertions).
func _drive_branch(gc: Node, exit_key: String) -> Dictionary:
	var seen: Array[Dictionary] = []
	gc.run_event.connect(func(e: Dictionary) -> void: seen.append(e))
	_start_demo_run(gc)
	_drive_encounter_one(gc)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	gc.apply_run_command({"type": "accept_recruit"})
	gc.apply_run_command({"type": "choose_exit", "key": exit_key})
	gc.apply_run_command({"type": "begin_encounter"})
	_treat_carried_wounds(gc)
	if exit_key == "kennel_run":
		_declare(gc, "war_hound_1", attack_action("bleeding", 1, "imani", "torso"))
		_declare(gc, "war_hound_2", attack_action("bleeding", 1, "sasha", "torso"))
		_fight_hounds(gc, MAX_FIGHT_TICKS)
	else:
		_fight_corridor(gc, MAX_FIGHT_TICKS)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "begin_encounter"})
	_treat_lingering_wounds(gc)
	_fight_boss(gc, MAX_FIGHT_TICKS)
	gc.apply_run_command({"type": "end_encounter"})
	return {"hash": gc.run.state_hash(), "outcome": String(gc.run.outcome), "events": seen}


func _record_indexes(gc: Node) -> Array:
	var out: Array = []
	for record: Dictionary in gc.run.records:
		out.append(int(record.get("index", -1)))
	return out


# ------------------------------------------- (0) the branch map's data contract

func test_demo_run_graph_data_contract() -> void:
	var def: Dictionary = demo_run_def()
	var encounters: Array = def.get("encounters", [])
	assert_eq(encounters.size(), 4, "the demo run is 4 rooms (wave 4b branch map)")
	var brood: Dictionary = encounters[0]
	assert_eq(String(brood.get("key", "")), "brood_landing", "the entry room is index 0 (documented)")
	assert_eq(String(brood.get("recruit_offer", "")), "sasha_the_tell",
		"Sasha's offer STAYS on Brood Landing (wave 4b changes no recruit beats)")
	var brood_exits: Array = brood.get("exits", [])
	assert_eq(brood_exits.size(), 2, "the entry room branches two ways (the exploration beat)")
	assert_eq(String((brood_exits[0] as Dictionary).get("key", "")), "kennel_run", "branch A key")
	assert_eq(String((brood_exits[0] as Dictionary).get("to", "")), "kennel_gauntlet", "branch A target")
	assert_eq(String((brood_exits[1] as Dictionary).get("key", "")), "service_route", "branch B key")
	assert_eq(String((brood_exits[1] as Dictionary).get("to", "")), "service_corridor", "branch B target")
	for i: int in range(brood_exits.size()):
		assert_true(String((brood_exits[i] as Dictionary).get("label", "")).length() > 0,
			"exit %d carries a label (view copy)" % i)
	var kennel: Dictionary = encounters[1]
	var corridor: Dictionary = encounters[2]
	var den: Dictionary = encounters[3]
	assert_eq(String(kennel.get("key", "")), "kennel_gauntlet", "index 1: the kennel (branch A)")
	assert_eq(String(corridor.get("key", "")), "service_corridor", "index 2: the corridor (branch B)")
	assert_eq(String(den.get("key", "")), "incinedile_den", "index 3: the den")
	assert_eq(String(((kennel.get("exits", []) as Array)[0] as Dictionary).get("to", "")),
		"incinedile_den", "the kennel's single exit converges on the den")
	assert_eq(String(((corridor.get("exits", []) as Array)[0] as Dictionary).get("to", "")),
		"incinedile_den", "the corridor's single exit converges on the den")
	assert_false(den.has("exits"), "the den is the TERMINAL room (clearing it wins the run)")
	# The soft route reuses the roach mob template — a lighter fight, no new content.
	var corridor_row: Dictionary = (corridor.get("enemies", []) as Array)[0]
	assert_eq(String(corridor_row.get("enemy_key", "")), "roach_dog", "branch B reuses the roach mob")
	assert_eq(int(corridor_row.get("count", 0)), 2, "as a light pair")
	# Wave 4b doors on the den (PLACEHOLDER positions, PROVISIONAL).
	var doors: Array = (den.get("arena", {}) as Dictionary).get("doors", [])
	assert_eq(doors.size(), 2, "the den authors two doors")
	var states: Array = [String((doors[0] as Dictionary).get("state", "")),
		String((doors[1] as Dictionary).get("state", ""))]
	states.sort()
	assert_eq(states, ["closed", "open"], "one closed (the service hatch), one open (the kennel gate)")


# ------------------------------------------- (1) both branches reach the den

func test_branch_a_kennel_reaches_the_den_and_wins() -> void:
	var gc: Node = _controller()
	var first: Dictionary = _drive_branch(gc, "kennel_run")
	assert_eq(String(first["outcome"]), "WIN", "branch A: terminal room cleared = run WIN (no end_run)")
	assert_eq(String(gc.run.phase), "finished", "the terminal WIN auto-finished the run")
	assert_eq(_record_indexes(gc), [0, 1, 3], "the path on the record: brood -> kennel -> den")
	# Beat ordering: the offer OUTRANKS exploration — the beat opened at
	# accept_recruit, not at end_encounter.
	var events: Array = first["events"]
	var order: Array[String] = []
	for e: Variant in events:
		var t := String((e as Dictionary).get("type", ""))
		if ["run_recruit_joined", "run_exploration_beat", "run_exit_chosen", "run_ended"].has(t):
			order.append(t)
	assert_eq(order, ["run_recruit_joined", "run_exploration_beat", "run_exit_chosen",
		"run_exit_chosen", "run_ended"],
		"joined -> beat -> chosen (the branch) -> chosen (the kennel's auto single exit) -> ended")
	var auto_exit: Dictionary = {}
	for e: Variant in events:
		if String((e as Dictionary).get("type", "")) == "run_exit_chosen" and bool((e as Dictionary).get("auto", false)):
			auto_exit = e
	assert_eq(String(auto_exit.get("to", "")), "incinedile_den",
		"the kennel's single exit AUTO-advanced to the den (no beat for corridors)")
	var final_ended: Dictionary = {}
	for e: Variant in events:
		if String((e as Dictionary).get("type", "")) == "run_ended":
			final_ended = e
	assert_eq(String(final_ended.get("outcome", "")), "WIN", "the auto-finish carried WIN")
	assert_eq(int(final_ended.get("encounters_cleared", -1)), 3, "three rooms cleared on this path")
	# Determinism: the identical drive lands the identical final run hash.
	var gc_b: Node = _controller()
	var second: Dictionary = _drive_branch(gc_b, "kennel_run")
	assert_eq(String(second["hash"]), String(first["hash"]),
		"same run seed + same run+combat command log = same final run hash (choose_exit included)")
	# Purity: a bare RunState replay of the run-command log ALONE reproduces it.
	var bare: RunState = RunState.new()
	for cmd: Dictionary in gc.run_command_log:
		bare.apply_command(cmd)
	assert_eq(bare.state_hash(), String(first["hash"]),
		"bare-reducer replay of the run log (choose_exit included) reproduces the run state")
	gc.free()
	gc_b.free()


func test_branch_b_service_corridor_reaches_the_den_and_wins() -> void:
	var gc: Node = _controller()
	var result: Dictionary = _drive_branch(gc, "service_route")
	assert_eq(String(result["outcome"]), "WIN", "branch B: the soft route also wins the run")
	assert_eq(String(gc.run.phase), "finished", "terminal auto-finish on this path too")
	assert_eq(_record_indexes(gc), [0, 2, 3], "the path on the record: brood -> corridor -> den")
	assert_eq(gc.run.roster.size(), 3, "the recruit rode branch B")
	# The corridor room really staged its authored content mid-drive: its
	# record carries the fight (index 2 WIN with survivors).
	var corridor_record: Dictionary = gc.run.records[1]
	assert_eq(String(corridor_record.get("key", "")), "service_corridor", "the mid record IS the corridor")
	assert_eq(String(corridor_record.get("outcome", "")), "WIN", "cleared")
	assert_true((corridor_record.get("survivors", []) as Array).has("sasha"), "with the recruit staged in it")
	var bare: RunState = RunState.new()
	for cmd: Dictionary in gc.run_command_log:
		bare.apply_command(cmd)
	assert_eq(bare.state_hash(), gc.run.state_hash(), "bare replay holds on branch B too")
	gc.free()


# ------------------------------------------- (2) choose_exit gating + the view

func test_choose_exit_gating_and_exits_view() -> void:
	var gc: Node = _controller()
	_start_demo_run(gc)
	# Outside any beat (nothing cleared yet).
	var too_early: Array[Dictionary] = gc.apply_run_command({"type": "choose_exit", "key": "kennel_run"})
	assert_eq(String(first_event(too_early, "run_command_rejected").get("reason", "")), "no_exploration_beat",
		"no beat before anything is cleared")
	gc.apply_run_command({"type": "begin_encounter"})
	# Mid-combat.
	var mid_combat: Array[Dictionary] = gc.apply_run_command({"type": "choose_exit", "key": "kennel_run"})
	assert_eq(String(first_event(mid_combat, "run_command_rejected").get("reason", "")), "encounter_active",
		"choose_exit rejects mid-combat")
	_drive_encounter_one_body(gc)
	gc.apply_run_command({"type": "end_encounter"})
	assert_eq(String(gc.run.phase), "between", "the offer beat OUTRANKS: no exploration while it is unresolved")
	assert_eq((gc.view_run().get("exits", []) as Array).size(), 0, "no exits on the view before the beat")
	var pre_offer: Array[Dictionary] = gc.apply_run_command({"type": "choose_exit", "key": "kennel_run"})
	assert_eq(String(first_event(pre_offer, "run_command_rejected").get("reason", "")), "no_exploration_beat",
		"the beat has not opened yet (the offer is unresolved)")
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	# Mid-offer.
	var mid_offer: Array[Dictionary] = gc.apply_run_command({"type": "choose_exit", "key": "kennel_run"})
	assert_eq(String(first_event(mid_offer, "run_command_rejected").get("reason", "")), "offer_pending",
		"choose_exit rejects while the offer beat is open")
	var declined: Array[Dictionary] = gc.apply_run_command({"type": "decline_recruit"})
	var beat: Dictionary = assert_event(declined, "run_exploration_beat",
		"the beat opens the moment the recruit beat resolves")
	assert_eq(String(beat.get("key", "")), "brood_landing", "the beat belongs to the cleared room")
	assert_eq((beat.get("exits", []) as Array).size(), 2, "both branches on the event")
	assert_eq(String(gc.run.phase), "exploration", "phase: the exploration beat")
	# The view exposes the exits, verbatim rows.
	var view_exits: Array = gc.view_run().get("exits", [])
	assert_eq(view_exits.size(), 2, "view_run exposes both exits during the beat")
	assert_eq(String((view_exits[0] as Dictionary).get("key", "")), "kennel_run", "exit key on the view")
	assert_eq(String((view_exits[0] as Dictionary).get("to", "")), "kennel_gauntlet", "exit target on the view")
	assert_true(String((view_exits[0] as Dictionary).get("label", "")).length() > 0, "label on the view")
	# The beat is unmissable: begin and end_run both reject.
	var begin_blocked: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	assert_eq(String(first_event(begin_blocked, "run_command_rejected").get("reason", "")), "exit_unchosen",
		"begin_encounter rejects mid-beat")
	var end_blocked: Array[Dictionary] = gc.apply_run_command({"type": "end_run"})
	assert_eq(String(first_event(end_blocked, "run_command_rejected").get("reason", "")), "exit_unchosen",
		"end_run rejects mid-beat (unmissable, like the offer beat)")
	# Invalid key.
	var bad_key: Array[Dictionary] = gc.apply_run_command({"type": "choose_exit", "key": "wrong_way"})
	assert_eq(String(first_event(bad_key, "run_command_rejected").get("reason", "")), "unknown_exit",
		"an unknown exit key rejects")
	assert_eq(String(gc.run.phase), "exploration", "rejections leave the beat open")
	# The choice resolves the beat.
	var chosen: Array[Dictionary] = gc.apply_run_command({"type": "choose_exit", "key": "service_route"})
	var exit_event: Dictionary = assert_event(chosen, "run_exit_chosen", "the pick emits its event")
	assert_eq(String(exit_event.get("to", "")), "service_corridor", "carrying the target")
	assert_false(bool(exit_event.get("auto", true)), "an explicit pick is not auto")
	assert_eq((gc.view_run().get("exits", []) as Array).size(), 0, "the exits view closes with the beat")
	var again: Array[Dictionary] = gc.apply_run_command({"type": "choose_exit", "key": "kennel_run"})
	assert_eq(String(first_event(again, "run_command_rejected").get("reason", "")), "no_exploration_beat",
		"the beat is spent — no second pick")
	gc.apply_run_command({"type": "begin_encounter"})
	assert_true(gc.sim.combatants.has("roach_dog_1"), "begin stages the CHOSEN room (the corridor)")
	assert_false(gc.sim.combatants.has("sasha"), "without the declined recruit")
	assert_eq(int((gc.view_run().get("encounter", {}) as Dictionary).get("active_index", -1)), 2,
		"the corridor (index 2) is the active room")
	gc.free()


## The encounter-1 fight body without the begin (the gating test opens it).
func _drive_encounter_one_body(gc: Node) -> void:
	_declare(gc, "roach_dog_1", attack_action("crushed", 4, "imani", "torso"))
	_declare(gc, "roach_dog_2", attack_action("crushed", 3, "sasha", "torso"))
	var pairs: Array = [["imani", "roach_dog_1"], ["dario", "roach_dog_3"], ["sasha", "roach_dog_2"]]
	for _i: int in range(20):
		if bool(gc.combat_status().get("over", false)):
			return
		var tick: int = gc.sim.clock.tick
		for pair: Variant in pairs:
			var attacker: CombatantState = gc.sim.combatants.get(String((pair as Array)[0]))
			var target: CombatantState = gc.sim.combatants.get(String((pair as Array)[1]))
			if attacker == null or target == null or not target.alive:
				continue
			if not attacker.can_act(tick) or tick < attacker.next_action_tick or attacker.windup_pending:
				continue
			if CombatantState.hex_distance(attacker.position, target.position) > 2:
				continue
			_declare(gc, attacker.id, attack_action("crushed", 3, target.id, "carapace", {"attack_range": 2}))
		gc.run_enemy_turn()
		gc.apply_command({"type": "advance_tick"})


# ------------------------------------------- (3) linear backward compat (control pin)

static func _plain_defs(count: int) -> Array:
	var defs: Array = []
	for i: int in range(count):
		defs.append({"key": "enc_%d" % (i + 1), "kind": "combat"})
	return defs


static func _start_synthetic(run: RunState, defs: Array) -> void:
	run.apply_command({"type": "start_run", "seed": 9,
		"party": [{"id": "ava", "name": "Ava"}], "encounters": defs})


static func _win_cmd(hype: int) -> Dictionary:
	return {"type": "end_encounter", "outcome": "WIN",
		"carried": {"ava": {"alive": true}}, "hype_meter": hype}


func test_linear_run_without_exits_behaves_exactly_as_before() -> void:
	# The old 3-encounter linear shape, driven twice — the second run is the
	# CONTROL the first must match event-for-event and hash-for-hash. No def
	# authors exits, so nothing of wave 4b may surface anywhere.
	var runs: Array = []
	for _i: int in range(2):
		var run := RunState.new()
		var seen: Array[String] = []
		_start_synthetic(run, _plain_defs(3))
		for enc: int in range(3):
			for e: Dictionary in run.apply_command({"type": "begin_encounter"}):
				seen.append(String(e.get("type", "")))
			for e: Dictionary in run.apply_command(_win_cmd(10 * (enc + 1))):
				seen.append(String(e.get("type", "")))
		for e: Dictionary in run.apply_command({"type": "end_run"}):
			seen.append(String(e.get("type", "")))
		runs.append({"run": run, "events": seen})
	var live: RunState = (runs[0] as Dictionary)["run"]
	var control: RunState = (runs[1] as Dictionary)["run"]
	assert_eq(String(live.outcome), "WIN", "the linear run still WINs via end_run (all cleared)")
	assert_eq((runs[0] as Dictionary)["events"], (runs[1] as Dictionary)["events"],
		"event stream pinned vs the control — identical")
	assert_eq(live.state_hash(), control.state_hash(), "final hash pinned vs the control")
	for event_type: String in (runs[0] as Dictionary)["events"] as Array[String]:
		assert_ne(event_type, "run_exploration_beat", "no exploration beat ever fires on a linear run")
		assert_ne(event_type, "run_exit_chosen", "no exit event ever fires on a linear run")
	# The serialization compat pin: NO graph key on a linear run's to_dict —
	# the exact pre-graph key set (the arena/doors idiom, one level up).
	var keys: Array = live.to_dict().keys()
	keys.sort()
	assert_eq(keys, ["active_index", "available_offer", "completed", "declined", "encounters",
		"hype_chain_index", "outcome", "pending_offer", "phase", "records", "roster", "run_seed"],
		"linear to_dict = the exact pre-graph key set (no next_index)")
	# And a GRAPH run declares its state (the key appears, hash-covered).
	var graph := RunState.new()
	_start_synthetic(graph, [
		{"key": "a", "kind": "combat", "exits": [{"key": "on", "to": "b", "label": "x"}]},
		{"key": "b", "kind": "combat"},
	])
	assert_true(graph.to_dict().has("next_index"), "a graph run serializes next_index")


# ------------------------------------------- (4) chain retention across the beat

func test_hype_chain_persists_through_the_exploration_beat() -> void:
	# The #32 retention ladder is UNTOUCHED by exploration beats: link 2 opens
	# at floor(40% x the previous ending meter) whether or not a beat (and a
	# choose_exit) sits between the fights — the beat is back-to-back glue.
	var run := RunState.new()
	_start_synthetic(run, [
		{"key": "a", "kind": "combat", "exits": [
			{"key": "left", "to": "b", "label": "L"}, {"key": "right", "to": "c", "label": "R"}]},
		{"key": "b", "kind": "combat", "exits": [{"key": "on", "to": "d", "label": "on"}]},
		{"key": "c", "kind": "combat", "exits": [{"key": "on", "to": "d", "label": "on"}]},
		{"key": "d", "kind": "combat"},
	])
	run.apply_command({"type": "begin_encounter"})
	run.apply_command(_win_cmd(137))
	assert_eq(String(run.phase), "exploration", "the two-way branch opened the beat")
	assert_eq(run.hype_chain_index, 1, "the chain advanced with the cleared fight")
	assert_eq(run.chain_hype_start(), 54, "mid-beat the retained meter already reads floor(137 x 40%) = 54")
	run.apply_command({"type": "choose_exit", "key": "left"})
	var started: Array[Dictionary] = run.apply_command({"type": "begin_encounter"})
	assert_eq(int(assert_event(started, "run_encounter_started", "link 2 starts").get("hype_start", -1)),
		54, "the chosen room OPENS at the retained meter — retention math unchanged across a chosen exit")
	assert_eq(int(run.staging().get("hype_start", -1)), 54, "staging agrees")
	# Link 3 rides the 60% rung through the single-exit auto-advance.
	run.apply_command(_win_cmd(47))
	var final_started: Array[Dictionary] = run.apply_command({"type": "begin_encounter"})
	assert_eq(int(assert_event(final_started, "run_encounter_started", "link 3 starts").get("hype_start", -1)),
		28, "floor(47 x 60%) = 28 through the auto-advance too")
	run.apply_command(_win_cmd(5))
	assert_eq(String(run.outcome), "WIN", "terminal room d closed the run")


# ------------------------------------------- (5) the v1 DAG guards

func test_revisit_guard_and_revisitable_rooms() -> void:
	# Synthetic graph the validator would reject (it has a back edge) — the
	# reducer's own guard must hold anyway: A(revisitable) <-> B, both exit to
	# the terminal T. A may be re-entered (authored revisitable: true); B may
	# not (the default).
	var run := RunState.new()
	_start_synthetic(run, [
		{"key": "a", "kind": "combat", "revisitable": true, "exits": [
			{"key": "to_b", "to": "b", "label": "B"}, {"key": "to_t", "to": "t", "label": "T"}]},
		{"key": "b", "kind": "combat", "exits": [
			{"key": "back", "to": "a", "label": "A"}, {"key": "to_t", "to": "t", "label": "T"}]},
		{"key": "t", "kind": "combat"},
	])
	run.apply_command({"type": "begin_encounter"})
	run.apply_command(_win_cmd(0))
	run.apply_command({"type": "choose_exit", "key": "to_b"})
	run.apply_command({"type": "begin_encounter"})
	run.apply_command(_win_cmd(0))
	# Back to A: allowed — A authors revisitable: true.
	var back: Array[Dictionary] = run.apply_command({"type": "choose_exit", "key": "back"})
	assert_event(back, "run_exit_chosen", "a revisitable room may be re-entered")
	var restarted: Array[Dictionary] = run.apply_command({"type": "begin_encounter"})
	assert_eq(int(assert_event(restarted, "run_encounter_started", "A restarts").get("index", -1)), 0,
		"the revisit is room index 0 again (sim seeds stay per-INDEX — path-independent)")
	run.apply_command(_win_cmd(0))
	# From A's second beat: B is VISITED and not revisitable — the guard holds.
	var blocked: Array[Dictionary] = run.apply_command({"type": "choose_exit", "key": "to_b"})
	assert_eq(String(first_event(blocked, "run_command_rejected").get("reason", "")), "room_not_revisitable",
		"a visited non-revisitable room rejects (v1 DAG honesty — validator-clean maps never hit this)")
	var out: Array[Dictionary] = run.apply_command({"type": "choose_exit", "key": "to_t"})
	assert_event(out, "run_exit_chosen", "the terminal route stays open")
	run.apply_command({"type": "begin_encounter"})
	run.apply_command(_win_cmd(0))
	assert_eq(String(run.outcome), "WIN", "and the run still closes clean")
	# A dangling exit (unvalidated data) rejects honestly instead of crashing.
	var bad := RunState.new()
	_start_synthetic(bad, [
		{"key": "a", "kind": "combat", "exits": [
			{"key": "off", "to": "nowhere", "label": "?"}, {"key": "also_off", "to": "nada", "label": "?"}]},
		{"key": "b", "kind": "combat"},
	])
	bad.apply_command({"type": "begin_encounter"})
	bad.apply_command(_win_cmd(0))
	var dangling: Array[Dictionary] = bad.apply_command({"type": "choose_exit", "key": "off"})
	assert_eq(String(first_event(dangling, "run_command_rejected").get("reason", "")), "unknown_encounter",
		"an exit into a non-existent room rejects (the validator gates authored data)")


# ------------------------------------------- (6) save/restore MID-exploration-beat

func test_save_restore_mid_exploration_beat_identical_continuation() -> void:
	var gc_live: Node = _controller()
	_start_demo_run(gc_live)
	_drive_encounter_one(gc_live)
	gc_live.apply_run_command({"type": "end_encounter"})
	gc_live.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	gc_live.apply_run_command({"type": "accept_recruit"})
	assert_eq(String(gc_live.run.phase), "exploration", "precondition: saving MID-exploration-beat")
	var exits_at_save: Array = gc_live.view_run().get("exits", [])
	assert_eq(exits_at_save.size(), 2, "precondition: the beat is open with both exits")
	var checkpoint: Dictionary = gc_live.run.to_dict()
	assert_eq(String(checkpoint.get("phase", "")), "exploration", "the beat phase serializes")
	assert_true(checkpoint.has("next_index"), "graph state serializes with it (hash-covered)")
	assert_true(gc_live.save_run("dungeonflow_midbeat"), "the DISK envelope saves mid-beat too")
	# Live continuation: branch A to the end.
	_continue_from_beat(gc_live)
	var live_hash: String = gc_live.run.state_hash()
	assert_eq(String(gc_live.run.outcome), "WIN", "precondition: the live continuation wins")
	# In-memory restore -> identical views -> identical continuation.
	var gc_restored: Node = _controller()
	gc_restored.restore_run(checkpoint, {}, load_static_data())
	assert_eq(String(gc_restored.run.phase), "exploration", "the restored run is still mid-beat")
	assert_eq(gc_restored.view_run().get("exits", []), exits_at_save,
		"the exits view reads identically after the restore")
	_continue_from_beat(gc_restored)
	assert_eq(gc_restored.run.state_hash(), live_hash,
		"restore mid-exploration-beat -> identical continuation (identical final run hash)")
	# Disk round trip: load, then the same continuation.
	var gc_loaded: Node = _controller()
	assert_true(gc_loaded.load_run("dungeonflow_midbeat", load_static_data()), "load_run succeeds mid-beat")
	assert_eq(gc_loaded.view_run().get("exits", []), exits_at_save, "the disk envelope preserved the beat")
	_continue_from_beat(gc_loaded)
	assert_eq(gc_loaded.run.state_hash(), live_hash, "the disk continuation matches hash-for-hash")
	gc_live.free()
	gc_restored.free()
	gc_loaded.free()


## The shared post-beat continuation (branch A), command-identical everywhere.
func _continue_from_beat(gc: Node) -> void:
	gc.apply_run_command({"type": "choose_exit", "key": "kennel_run"})
	gc.apply_run_command({"type": "begin_encounter"})
	_treat_carried_wounds(gc)
	_declare(gc, "war_hound_1", attack_action("bleeding", 1, "imani", "torso"))
	_declare(gc, "war_hound_2", attack_action("bleeding", 1, "sasha", "torso"))
	_fight_hounds(gc, MAX_FIGHT_TICKS)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "begin_encounter"})
	_treat_lingering_wounds(gc)
	_fight_boss(gc, MAX_FIGHT_TICKS)
	gc.apply_run_command({"type": "end_encounter"})
