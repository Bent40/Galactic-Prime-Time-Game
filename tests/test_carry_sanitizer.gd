extends SimTestBase
## The encounter-carry SANITIZER GAP closed — the KAN-4 persists/resets policy
## (simulation/run_state.gd header table) audited against every combat-scoped
## CombatantState field added AFTER the sanitizer was written (content batches
## A-D + R25/R30), flagged by the batch B/C/D stories:
##   * RESET (only-when-set keys ERASED, the stealthed idiom):
##     last_action_target (batch A chain gate), guard + iron_stance (batch B
##     retarget_guard family), forced_save (batch C acrobatic_save arming),
##     pattern_reads (batch C intel), conceal (batch D camouflage),
##     channeling + held_by (batch D telekinesis); rolled_this_window (R25 —
##     always-serialized per-tick flag, zeroed with its family).
##   * PERSIST: charges — the STACK counter is batch C's consumable
##     bandage_charge economy, so B11/Q29 governs (consumed stays consumed,
##     unspent stays held); tier-2 absorb/cap markers (#34/#35) are
##     ROSTER-layer spec annotations and never enter the carry at all.
##   * facing (R30/#33): NOT sanitized — re-derived at staging by the
##     controller splice (verified live: a carried non-default facing does
##     not leak into the next room).
##   * free_actions_used (R34, the 2026-08-19 free-action budget): same shape —
##     NOT sanitized (run_state.gd's table still zeroes only the legacy
##     boolean, which no longer clears the counter), ERASED at staging by the
##     controller splice; verified live below with a victory free action.
## What these tests pin:
##   (1) a LIVE run through the controller where one encounter ends with EVERY
##       new field armed via REAL commands (intercept guard, armed save, a
##       pattern read, camouflage stealth, a TK grip on an ally, an iron
##       stance, a spent bandage) -> the next encounter stages every
##       combat-scoped field clean and every roster-layer field intact
##       (charges count pinned at the spent value, absorb marker untouched);
##   (2) determinism with the new fields in the LOGGED captures: a
##       between-encounters save/restore lands an identical continuation
##       (staged sim hash + final run hash), and a bare RunState replaying the
##       controller's run log alone re-sanitizes to the identical final hash;
##   (3) the reducer-level disposition table over a hand-built fully-loaded
##       capture (the enriched end_encounter idiom — covers the one field a
##       live capture cannot hold, rolled_this_window, which resets with the
##       tick before any over-state exists).

const RUN_SEED := 4242
## Tier-2 wave 4 appended con / conned_by / con_steps (the_long_con — the con
## names per-encounter enemy ids; scene end is one of its AUTHORED ends).
const NEW_FIELD_KEYS: Array[String] = ["guard", "iron_stance", "forced_save",
	"pattern_reads", "conceal", "channeling", "held_by", "last_action_target",
	"stealthed", "con", "conned_by", "con_steps"]


# ---------------------------------------------------------------- plumbing

func _controller() -> Node:
	return (load("res://controller/game_controller.gd") as GDScript).new()


func _declare(gc: Node, actor: String, action: Dictionary) -> Array[Dictionary]:
	return gc.apply_command({"type": "declare_action", "actor": actor, "action": action})


## Six-member party, one loaded role each (see _drive_loaded_encounter):
## hero reads + strikes (and carries the tier-2 absorb marker on its SPEC
## skill row — the #34/#35 roster-layer shape), guardian intercepts, acrobat
## arms the save + spends a bandage, sneak camouflages, tk grips buddy, buddy
## holds the iron stance and ends the fight telekinetically held.
static func _party() -> Array:
	var human_traits: Dictionary = {"physique": 3, "reflexes": 3, "mind": 3, "charm": 3}
	return [
		{"id": "hero", "name": "hero", "race": "human", "team": "party", "position": [0, 0],
			"traits": human_traits.duplicate(true),
			"skills": [{"key": "strong_strike", "level": 5, "absorbed": "quick_slash", "cap": 8}]},
		{"id": "guardian", "name": "guardian", "race": "human", "team": "party", "position": [1, 0],
			"traits": human_traits.duplicate(true)},
		{"id": "acrobat", "name": "acrobat", "race": "human", "team": "party", "position": [0, 1],
			"traits": human_traits.duplicate(true), "charges": {"bandage_charge": 2}},
		{"id": "sneak", "name": "sneak", "race": "human", "team": "party", "position": [-3, 0],
			"traits": human_traits.duplicate(true)},
		{"id": "tk", "name": "tk", "race": "human", "team": "party", "position": [-1, -1],
			"traits": human_traits.duplicate(true)},
		{"id": "buddy", "name": "buddy", "race": "human", "team": "party", "position": [1, -1],
			"traits": human_traits.duplicate(true)},
	]


## Two linear rooms, one 1-HP roach each (Mind 0 — it sees nothing, so the
## camouflage geometry is trivially safe and the roach is never driven).
static func _defs() -> Array:
	return [
		{"key": "stage_room", "kind": "combat",
			"enemies": [{"enemy_key": "roach_dog", "id": "roach_a", "name": "Roach A", "position": [3, 0]}]},
		{"key": "check_room", "kind": "combat",
			"enemies": [{"enemy_key": "roach_dog", "id": "roach_b", "name": "Roach B", "position": [2, 0]}]},
	]


func _start_run(gc: Node) -> void:
	gc.start_run(RUN_SEED, _party(), _defs(), load_static_data())


## Encounter 1, fully loaded through REAL commands. Timeline (5 ticks):
##   t0: guardian intercepts hero (cost 0), acrobat arms the save (instant,
##       G1 movement forfeit) then triages guardian's staged chilled (cost 1,
##       burns a bandage), sneak starts the 3-Moment camouflage windup, buddy
##       takes the iron stance (cost 0), hero reads roach_a (cost 1, range 3).
##   t1-t2: the camouflage winds (nothing else due).
##   t3: camouflage resolves -> stealth + conceal.
##   t4: tk grips buddy (ally grip — team-agnostic visibility, buddy pure E
##       in tk's front arc), hero's strike kills the 1-HP carapace the same
##       resolution -> combat over WIN with every field still live (the grip
##       resolved ON the final tick, so the upkeep lapse never fires; the
##       Clock reset that would expire the pattern read is ~5 ticks away).
func _drive_loaded_encounter(gc: Node) -> void:
	gc.apply_run_command({"type": "begin_encounter"})
	deliberate_enter(gc)  # R34 deliberate ENTER (the room opens free-form)
	gc.apply_command({"type": "apply_condition", "target": "guardian", "part": "torso",
		"condition": "chilled", "tier": 1})
	_declare(gc, "guardian", {"kind": "skill", "key": "intercept", "level": 1,
		"targets": [{"id": "hero"}]})
	var armed: Array[Dictionary] = _declare(gc, "acrobat", {"kind": "skill", "key": "acrobatic_save", "level": 1})
	assert_event(armed, "acrobatic_save_armed", "precondition: the save armed at declare (batch C)")
	_declare(gc, "acrobat", {"kind": "skill", "key": "field_triage", "level": 1,
		"targets": [{"id": "guardian", "part": "torso"}], "condition": "chilled"})
	_declare(gc, "sneak", {"kind": "skill", "key": "camouflage", "level": 1})
	_declare(gc, "buddy", {"kind": "skill", "key": "iron_stance", "level": 1})
	_declare(gc, "hero", {"kind": "skill", "key": "read_the_pattern", "level": 1,
		"targets": [{"id": "roach_a", "part": "carapace"}]})
	var t0: Array[Dictionary] = gc.apply_command({"type": "advance_tick"})
	assert_event(t0, "guard_set", "precondition: the intercept guard armed (batch B)")
	assert_event(t0, "iron_stance_started", "precondition: the stance is held (batch B)")
	assert_event(t0, "pattern_read", "precondition: the intel reveal recorded (batch C)")
	assert_event(t0, "charge_consumed", "precondition: the triage burned a bandage (batch C)")
	var winding: Array[Dictionary] = []
	for _i: int in range(3):
		winding.append_array(gc.apply_command({"type": "advance_tick"}))
	assert_event(winding, "stealth_entered", "precondition: camouflage resolved into stealth (batch D)")
	_declare(gc, "tk", {"kind": "skill", "key": "telekinesis", "level": 1,
		"targets": [{"id": "buddy"}]})
	_declare(gc, "hero", attack_action("crushed", 3, "roach_a", "carapace", {"attack_range": 3}))
	var final_tick: Array[Dictionary] = gc.apply_command({"type": "advance_tick"})
	assert_event(final_tick, "telekinesis_grip", "precondition: the grip landed on the final tick (batch D)")
	assert_eq(String(gc.combat_status().get("outcome", "")), "WIN", "precondition: the stage room falls")


## Encounter 2 to the end of the run — shared so save/restore continuations
## are command-identical.
func _finish_encounter_two(gc: Node) -> void:
	gc.apply_run_command({"type": "begin_encounter"})
	deliberate_enter(gc)  # R34 deliberate ENTER (the room opens free-form)
	_declare(gc, "hero", attack_action("crushed", 3, "roach_b", "carapace", {"attack_range": 2}))
	gc.apply_command({"type": "advance_tick"})
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "end_run"})


func _roster_row(gc: Node, id: String) -> Dictionary:
	for row: Dictionary in gc.run.roster:
		if String(row["id"]) == id:
			return row
	return {}


# ------------------------- (1) the live gap-closure across a real hand-off

func test_every_new_field_lives_at_encounter_end_and_stages_clean() -> void:
	var gc: Node = _controller()
	_start_run(gc)
	_drive_loaded_encounter(gc)
	# Honesty preconditions: every audited field is LIVE on the sim the moment
	# the fight is over — the capture the sanitizer is about to see is real.
	var live_guardian: CombatantState = gc.sim.combatants["guardian"]
	var live_acrobat: CombatantState = gc.sim.combatants["acrobat"]
	var live_hero: CombatantState = gc.sim.combatants["hero"]
	var live_sneak: CombatantState = gc.sim.combatants["sneak"]
	var live_tk: CombatantState = gc.sim.combatants["tk"]
	var live_buddy: CombatantState = gc.sim.combatants["buddy"]
	assert_eq(String(live_guardian.guard.get("ally", "")), "hero", "precondition: the guard record is live")
	assert_eq(live_guardian.facing, 3, "precondition: the intercept declare re-faced the guardian W (R30)")
	assert_eq(int(live_acrobat.forced_save.get("dice", 0)), 1, "precondition: the armed save is live")
	assert_eq(int(live_acrobat.charges.get("bandage_charge", -1)), 1, "precondition: one bandage spent, one held")
	assert_true(live_hero.pattern_reads.has("roach_a"), "precondition: the reveal is live at combat end")
	assert_eq(live_hero.last_action_target, "roach_a", "precondition: the chain gate points at the kill")
	assert_true(live_sneak.stealthed, "precondition: the sneak ends the fight stealthed")
	assert_eq(int(live_sneak.conceal.get("radius", 0)), 6, "precondition: the camouflage modifier is live")
	assert_eq(String(live_tk.channeling.get("target", "")), "buddy", "precondition: the channel is live")
	assert_eq(live_buddy.held_by, "tk", "precondition: the held-by mirror is live")
	assert_false(live_buddy.iron_stance.is_empty(), "precondition: the stance is still held")
	# R34: a victory free action (the bow after the kill) is spent AFTER the
	# last tick, so it is still live in the capture the sanitizer sees.
	_declare(gc, "hero", {"kind": "skill", "cost": 0, "key": "taunt"})
	assert_eq(live_hero.free_actions_used, 1,
		"precondition: one free-action entry is live at capture (R3/R34 budget)")
	gc.apply_run_command({"type": "end_encounter"})
	# The roster carry is SANITIZED: every only-when-set key erased, charges kept.
	for id: String in ["hero", "guardian", "acrobat", "sneak", "tk", "buddy"]:
		var carried: Dictionary = _roster_row(gc, id)["carried"]
		for gone: String in NEW_FIELD_KEYS:
			assert_false(carried.has(gone), "%s: '%s' is combat-scoped — erased from the carry" % [id, gone])
	assert_eq(((_roster_row(gc, "acrobat")["carried"] as Dictionary).get("charges", {}) as Dictionary)
		.get("bandage_charge", -1), 1,
		"the spent bandage economy crossed the gap at the spent count (B11/Q29 — consumed stays consumed)")
	# The tier-2 absorb marker is ROSTER-layer (#34/#35): the SPEC skill row
	# keeps it untouched through the whole hand-off.
	var hero_spec_skill: Dictionary = ((_roster_row(gc, "hero")["spec"] as Dictionary)["skills"] as Array)[0]
	assert_eq(String(hero_spec_skill.get("absorbed", "")), "quick_slash", "the absorb marker survives on the spec")
	assert_eq(int(hero_spec_skill.get("cap", 0)), 8, "the absorb cap survives on the spec")
	# Next encounter staged: every combat-scoped field clean on the LIVE sim.
	gc.apply_run_command({"type": "begin_encounter"})
	deliberate_enter(gc)  # R34 deliberate ENTER (the room opens free-form)
	var staged_plan: Dictionary = gc.run.staging()
	var hero: CombatantState = gc.sim.combatants["hero"]
	var guardian: CombatantState = gc.sim.combatants["guardian"]
	var acrobat: CombatantState = gc.sim.combatants["acrobat"]
	var sneak: CombatantState = gc.sim.combatants["sneak"]
	var tk: CombatantState = gc.sim.combatants["tk"]
	var buddy: CombatantState = gc.sim.combatants["buddy"]
	assert_eq(gc.sim.combatants.size(), 7, "six carried members + the check room's roach on the table")
	assert_true(guardian.guard.is_empty(), "the guard record died with the encounter (batch B)")
	assert_true(guardian.armed_primes.is_empty(), "its PREP substrate died with it (R3/#20)")
	assert_eq(guardian.facing, 0, "the carried W-facing did NOT leak — staging re-derived it (R30/#33)")
	assert_eq(hero.free_actions_used, 0,
		"the carried free-action budget did NOT leak — staging erased it (R34, the facing precedent)")
	assert_true(hero.has_free_action(), "the next room opens with the whole budget")
	assert_true(buddy.iron_stance.is_empty(), "the stance died with the encounter (batch B)")
	assert_true(acrobat.forced_save.is_empty(), "the armed save died with the encounter (batch C)")
	assert_eq(int(acrobat.charges.get("bandage_charge", -1)), 1,
		"the STAGED member holds exactly the unspent bandage (Q29 — the sanitizer no longer wipes charges)")
	assert_true(hero.pattern_reads.is_empty(), "the intel died with the encounter's Clock (batch C)")
	assert_eq(hero.last_action_target, "", "the chain same-target gate never crosses encounters (batch A)")
	assert_eq(hero.last_action_key, "", "nor does the chain key (R3/#20)")
	assert_false(sneak.stealthed, "the next room re-sees you (R20)")
	assert_true(sneak.conceal.is_empty(), "the camouflage modifier never outlives its stealth (batch D)")
	assert_true(tk.channeling.is_empty(), "the channel died with the encounter (batch D)")
	assert_false(tk.exposed_cache, "and its Exposed shadow died with it")
	assert_eq(buddy.held_by, "", "the partner did not follow you out (the grapple-link rule)")
	# The persists side of the same hand-off: the treated (delayed) condition
	# rides, everyone is alive, and the staging plan's add specs still carry
	# the roster-layer absorb annotation for the forge to consume.
	assert_eq(guardian.condition_tier("torso", "chilled"), 1, "the treated chilled T1 rode across (B11)")
	for row: Dictionary in staged_plan.get("adds", []) as Array:
		if String(row.get("id", "")) == "hero":
			assert_eq(String(((row["skills"] as Array)[0] as Dictionary).get("absorbed", "")), "quick_slash",
				"the staging plan re-stages the spec verbatim, absorb marker included")
	# Close the run honestly.
	_declare(gc, "hero", attack_action("crushed", 3, "roach_b", "carapace", {"attack_range": 2}))
	gc.apply_command({"type": "advance_tick"})
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "end_run"})
	assert_eq(String(gc.run.outcome), "WIN", "the loaded run closes clean")
	gc.free()


# ---------------- (2) determinism with the new fields in the logged captures

func test_save_restore_and_bare_replay_with_new_fields_present() -> void:
	var gc_live: Node = _controller()
	_start_run(gc_live)
	_drive_loaded_encounter(gc_live)
	gc_live.apply_run_command({"type": "end_encounter"})
	# Between-encounters checkpoint: the sanitized carry (spent bandage
	# included) must round-trip the public serialization path.
	var checkpoint: Dictionary = gc_live.run.to_dict()
	assert_eq(RunState.from_dict(checkpoint).state_hash(), gc_live.run.state_hash(),
		"the between-encounters round trip is state-hash faithful with the new-field carry ingested")
	gc_live.apply_run_command({"type": "begin_encounter"})
	deliberate_enter(gc_live)  # R34 deliberate ENTER (the room opens free-form)
	var live_staged_hash: String = gc_live.sim.state_hash()
	_declare(gc_live, "hero", attack_action("crushed", 3, "roach_b", "carapace", {"attack_range": 2}))
	gc_live.apply_command({"type": "advance_tick"})
	gc_live.apply_run_command({"type": "end_encounter"})
	gc_live.apply_run_command({"type": "end_run"})
	var live_hash: String = gc_live.run.state_hash()
	assert_eq(String(gc_live.run.outcome), "WIN", "precondition: the live continuation wins the run")
	# Restore from the checkpoint alone -> the staged encounter-2 sim is
	# hash-identical (the splice is deterministic over serialized state) and
	# the identical continuation lands the identical final run hash.
	var gc_restored: Node = _controller()
	gc_restored.restore_run(checkpoint, {}, load_static_data())
	assert_eq(((_roster_row(gc_restored, "acrobat")["carried"] as Dictionary).get("charges", {}) as Dictionary)
		.get("bandage_charge", -1), 1, "the restored roster carries the spent-bandage count")
	gc_restored.apply_run_command({"type": "begin_encounter"})
	deliberate_enter(gc_restored)  # R34 deliberate ENTER (the room opens free-form)
	assert_eq(gc_restored.sim.state_hash(), live_staged_hash,
		"save/restore between encounters stages a hash-identical encounter 2")
	_declare(gc_restored, "hero", attack_action("crushed", 3, "roach_b", "carapace", {"attack_range": 2}))
	gc_restored.apply_command({"type": "advance_tick"})
	gc_restored.apply_run_command({"type": "end_encounter"})
	gc_restored.apply_run_command({"type": "end_run"})
	assert_eq(gc_restored.run.state_hash(), live_hash,
		"identical continuation from the restore -> identical final run hash")
	# Bare-reducer replay: the LOGGED end_encounter commands carry the RAW
	# captures (guard/save/read/conceal/channel/held_by all present) — a bare
	# RunState replaying the run log alone re-sanitizes to the same hash.
	var bare := RunState.new()
	for cmd: Dictionary in gc_live.run_command_log:
		bare.apply_command(cmd)
	assert_eq(bare.state_hash(), live_hash,
		"a bare RunState replay of the run log re-sanitizes the raw captures identically")
	assert_eq((((bare.roster[2] as Dictionary)["carried"] as Dictionary).get("charges", {}) as Dictionary)
		.get("bandage_charge", -1), 1, "the bare replay lands the same persisted charge count")
	gc_live.free()
	gc_restored.free()


# ------------------- (3) the reducer-level disposition table, exhaustively

func test_sanitizer_dispositions_over_a_fully_loaded_capture() -> void:
	# The enriched-command idiom (RunState consumes the capture directly): a
	# hand-built carried dict holding EVERY audited field non-default — the
	# only reachable staging for rolled_this_window, which a live capture can
	# never hold (reset_tick_flags runs before any over-state exists).
	var run := RunState.new()
	run.apply_command({"type": "start_run", "seed": 4,
		"party": [{"id": "ava", "name": "Ava"}],
		"encounters": [{"key": "e1", "kind": "combat"}, {"key": "e2", "kind": "combat"}]})
	run.apply_command({"type": "begin_encounter"})
	var capture: Dictionary = {
		"alive": true,
		# PERSISTS:
		"parts": {"torso": {"hp": 2, "base_max_hp": 5, "lethal": true,
			"disabled": false, "destroyed": false}},
		"conditions": {"torso": {"bleeding": {"tier": 2, "delayed": false,
			"reapplied_this_clock": true, "last_attack_advance_tick": 6}}},
		"charges": {"bandage_charge": 2, "focus": 1},
		"items": {"medkit": {"key": "medkit", "uses": 1}},
		"facing": 2,
		# RESETS — the post-sanitizer fields this story closes:
		"last_action_target": "foe",
		"rolled_this_window": true,
		"guard": {"ally": "bo", "range": 1, "reduction": 0},
		"iron_stance": {"anchor": [0, 0], "radius": 1, "reduction": 1, "types": ["crushed"]},
		"forced_save": {"dice": 1},
		"pattern_reads": {"foe": {"actions": 1}},
		"conceal": {"radius": 6, "anchor": [2, 2]},
		"channeling": {"key": "telekinesis", "target": "bo", "range": 10, "sustained_tick": 4},
		"held_by": "bo",
		"stealthed": true,
		# Tier-2 wave 4 (the_long_con): the con record, the mark-side mirror
		# and the banked step — all combat-scoped, all erased.
		"con": {"targets": {"bo": "tool"}, "dice": 1, "hype": 0},
		"conned_by": "bo",
		"con_steps": 2,
	}
	run.apply_command({"type": "end_encounter", "outcome": "WIN",
		"carried": {"ava": capture}, "hype_meter": 0})
	var carry: Dictionary = (run.roster[0] as Dictionary)["carried"]
	# RESET — every only-when-set key erased (the stealthed idiom), the R25
	# marker zeroed with its per-tick family.
	for gone: String in NEW_FIELD_KEYS:
		assert_false(carry.has(gone), "'%s' is combat-scoped — erased by _sanitize_carry" % gone)
	assert_eq(bool(carry.get("rolled_this_window", true)), false,
		"the R25 roll marker is a per-tick flag — reset with its family")
	# PERSISTS — wounds, conditions (bookkeeping sanitized), the consumable
	# economy, item uses, and the facing the CONTROLLER re-derives at staging.
	assert_eq(int((carry["parts"]["torso"] as Dictionary)["hp"]), 2, "wounds persist (R11/#27)")
	var instance: Dictionary = (carry["conditions"]["torso"] as Dictionary)["bleeding"]
	assert_eq(int(instance["tier"]), 2, "the condition rides (B11)")
	assert_eq(bool(instance["reapplied_this_clock"]), false, "fresh Clock lap (instance bookkeeping sanitized)")
	assert_eq(int(instance["last_attack_advance_tick"]), -1, "no attack has advanced it this combat")
	assert_eq(carry.get("charges", {}), {"bandage_charge": 2, "focus": 1},
		"the STACK counter persists VERBATIM — B11/Q29: consumed stays consumed, unspent stays held")
	assert_eq(int((carry["items"]["medkit"] as Dictionary)["uses"]), 1, "item uses ride items (B11)")
	assert_eq(int(carry.get("facing", -1)), 2,
		"facing rides the carry UNSANITIZED — the controller splice re-derives it at staging (R30/#33)")
	# And the sanitized carry still serializes/replays cleanly.
	assert_eq(RunState.from_dict(run.to_dict()).state_hash(), run.state_hash(),
		"the loaded carry round-trips the run serialization")
