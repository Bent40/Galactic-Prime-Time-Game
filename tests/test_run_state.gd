extends SimTestBase
## KAN-4 — the RUN engine (decision-log #31, engine only): RunState + the
## GameController run wiring, driven headlessly over the canonical authored
## data/demo_run.json (wave 3c, THREE encounters: encounter 1 = the brood
## skirmish where the party meets Sasha, staged as a party-side ally;
## encounter 2 = the KENNEL — the war-hound pair, the second authored enemy;
## encounter 3 = the Incine-Dile den finale).
##
## What these tests pin:
##   * the demo-run DATA contract (specs verbatim from the loadout files — the
##     drift gate; recruit_offer maps to the staged ally id; the kennel mid
##     room fields the war_hound pair; the finale stays the boss);
##   * full 3-encounter determinism: same run seed + same run+combat command log
##     twice -> identical final run hash, AND a bare RunState replaying the
##     controller's run-command log alone (no sims) lands on the same hash —
##     run state is a pure function of (run seed, ordered run-command log);
##   * the carry policy ACROSS BOTH HAND-OFFS: wounded torso numbers and
##     conditions survive encounter 1 -> 2 AND 2 -> 3 (the end-of-kennel
##     capture stages VERBATIM into the finale); Shock (R13), primes/stance
##     (R3), breach and the Clock reset with each new combat; the B9 spent
##     Camera Call stack stays spent for the run; treating a carried wound
##     resolves the condition but never regenerates HP (Q29/B11);
##   * recruitment beats: accept -> roster 3 with the recruit's encounter-1
##     damage present in the LATER encounters (PROVISIONAL #31 as-is default);
##     decline -> STORY-DRIVEN (decision #32, supersedes #31's global
##     decline-final): the recruit's authored on_decline decides —
##     gone_for_run bars any re-offer (the #31 behavior), may_reoffer lets a
##     LATER encounter's recruit_offer open a FRESH beat (Sasha's authored
##     story; declining again re-honors the data) — encounter 2 staged
##     without her either way;
##   * hype chains (decision #32, supersedes the per-encounter hype reset):
##     chained encounters open at floor(retention% x the previous ending
##     meter), laddered 40/60/80 then 100% — exact floor math pinned on a
##     synthetic run, and the LIVE ladder pinned through the controller over
##     the authored run: the kennel OPENS at floor(40% x encounter 1's ending
##     meter), the finale at floor(60% x the kennel's ending meter); the
##     chain index pinned through serialization;
##   * save/restore BETWEEN encounters and MID-encounter-2 (the kennel fight,
##     serialized state only — the new enemy rides CombatSim serialization)
##     -> identical continuations;
##   * run outcomes: win all three -> WIN; party wipe in encounter 1 -> LOSS
##     and the later encounters never start; early extraction -> ABANDONED
##     (PROVISIONAL).
##
## Fights are REAL command streams (declares + ai_decide via run_enemy_turn +
## advance_tick through the controller funnel) in the compact scripted style the
## sim tests use — every drive is guarded off live state, so identical state
## always re-issues identical commands (the lockstep property the save/restore
## tests lean on).

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


func _advance_until_over(gc: Node, max_ticks: int) -> void:
	for _i: int in range(max_ticks):
		if bool(gc.combat_status().get("over", false)):
			return
		gc.apply_command({"type": "advance_tick"})


## Encounter 1 (brood_landing) — the recruit fights as an ally.
func _drive_encounter_one(gc: Node) -> void:
	gc.apply_run_command({"type": "begin_encounter"})
	_drive_encounter_one_after_begin(gc)


## The encounter-1 fight body (the gating test opens the encounter itself to
## probe mid-fight rejections first, hence the split). Two staged brood strikes
## give DETERMINISTIC carried-damage numbers (R14 hand-math in place); the rest
## is a guarded real fight: party declares, roach_dog_3's live ai_decide via
## run_enemy_turn, ticks until the fight resolves.
func _drive_encounter_one_after_begin(gc: Node) -> void:
	# Staged brood wounds (tick 0, resolve with everything else at the tick — R2):
	#   roach_dog_1 -> imani torso: Force 4 + floor(1/2)=0, Robustness floor(5/2)=2
	#     -> net 2: torso 5 -> 3 + crushed T1.
	#   roach_dog_2 -> sasha torso: Force 3, Robustness floor(3/2)=1
	#     -> net 2: torso 5 -> 3 + crushed T1 (the damage she carries if recruited).
	_declare(gc, "roach_dog_1", attack_action("crushed", 4, "imani", "torso"))
	_declare(gc, "roach_dog_2", attack_action("crushed", 3, "sasha", "torso"))
	# Broadcast/priming staging for the carry-policy assertions: Dario spends his
	# ONE Camera Call stack (B9: session = the deployment — it must stay spent in
	# encounter 2), arms a prime + stance (R3 — must reset), and takes Shock T1
	# (R13 — must reset at combat end).
	gc.apply_command({"type": "camera_call", "actor": "dario", "target": "imani"})
	gc.apply_command({"type": "prime", "actor": "dario", "key": "wind_up"})
	gc.apply_command({"type": "set_stance", "actor": "dario", "stance": "guarded"})
	gc.apply_command({"type": "apply_condition", "target": "dario", "part": "torso", "condition": "shock", "tier": 1})
	# The real fight: each ready party member puts down its assigned roach (any
	# net >= 1 kills a 1-HP carapace); the undeclared roach acts through the live
	# enemy-turn path every tick.
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


## The between-fights treatment beat (Q29/B11: healing items treat CONDITIONS,
## never HP — the direct treat command is the test-side stand-in for the item):
## resolves the carried crushed wounds so the clock-reset advancement does not
## destroy a torso mid-boss-fight. Guarded — the decline path has no sasha.
func _treat_carried_wounds(gc: Node) -> void:
	for id: String in ["imani", "sasha"]:
		if gc.sim.combatants.has(id):
			gc.apply_command({"type": "treat", "target": id, "part": "torso", "condition": "crushed", "mode": "resolve"})


## Kennel staging (wave 3c, the enc-1 staged-strike idiom): two hound bites at
## tick 0 with the REAL rending_bite numbers, for DETERMINISTIC hand-off pins:
##   war_hound_1 -> imani torso: Force 1 + floor(3/2) = 2 vs Robustness
##     floor(5/2) = 2 -> NOT > -> BLOCKED (attack_no_wound): the tank shrugs a
##     lone hound (the authored bite-note math, live).
##   war_hound_2 -> sasha torso: Force 2 vs Robustness 1 -> net 1: her carried
##     torso 3 -> 2 + bleeding T1 (the wound she carries into the finale).
## Guarded — the decline path has no sasha (her bite is skipped).
func _stage_hound_bites(gc: Node) -> void:
	_declare(gc, "war_hound_1", attack_action("bleeding", 1, "imani", "torso"))
	if gc.sim.combatants.has("sasha"):
		_declare(gc, "war_hound_2", attack_action("bleeding", 1, "sasha", "torso"))


## The kennel fight body (guarded, lockstep like the enc-1 drive): imani puts
## down hound 1 as soon as she is ready; sasha holds one Moment so hound 2 gets
## ONE LIVE ai_decide through the run funnel (run_enemy_turn — the real elite
## policy acts inside the run) before she puts it down at tick 1.
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
				continue  # hound 2 gets its one live decide before she strikes
			if not attacker.can_act(tick) or tick < attacker.next_action_tick or attacker.windup_pending:
				continue
			if CombatantState.hex_distance(attacker.position, target.position) > 2:
				continue
			_declare(gc, attacker.id, attack_action("crushed", 9, target.id, "torso", {"attack_range": 2}))
		gc.run_enemy_turn()
		gc.apply_command({"type": "advance_tick"})


## The finale's treatment beat: resolve every bleeding the kennel left (the
## staged bite + wherever hound 2's live decide landed) so bleed advancement
## does not add Forced-Action noise to the boss drive. Guarded off live state.
func _treat_hound_wounds(gc: Node) -> void:
	for id: String in ["imani", "dario", "sasha"]:
		var c: CombatantState = gc.sim.combatants.get(id)
		if c == null:
			continue
		var part_keys: Array = c.parts.keys()
		part_keys.sort()
		for part_key: Variant in part_keys:
			if c.condition_tier(String(part_key), "bleeding") > 0:
				gc.apply_command({"type": "treat", "target": id, "part": String(part_key),
					"condition": "bleeding", "mode": "resolve"})


## Finale fight: breach the surface with one heavy strike (net 10+2-3 = 9
## >= 7, dodge-retried — the REAL template keeps its R22 dodge), then put the
## exposed network down. Fully guarded off live state; the boss fights back
## through the live enemy-turn path every tick.
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


## The accept-path continuation from the between-encounters checkpoint (after
## the recruit joined): the kennel, then the finale, to the end of the run.
## Shared by the live drive and both restore tests so continuations are
## command-identical.
func _finish_from_between(gc: Node) -> void:
	gc.apply_run_command({"type": "begin_encounter"})
	_treat_carried_wounds(gc)
	_stage_hound_bites(gc)
	_fight_hounds(gc, MAX_FIGHT_TICKS)
	gc.apply_run_command({"type": "end_encounter"})
	_finish_finale(gc)


## The finale (encounter 3) from the post-kennel between checkpoint, to the
## end of the run — shared so every continuation is command-identical.
func _finish_finale(gc: Node) -> void:
	gc.apply_run_command({"type": "begin_encounter"})
	_treat_hound_wounds(gc)
	_fight_boss(gc, MAX_FIGHT_TICKS)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "end_run"})


## The full accept-path demo run, end to end. Returns the final run hash +
## outcome for the determinism assertions.
func _drive_full_run(gc: Node) -> Dictionary:
	_start_demo_run(gc)
	_drive_encounter_one(gc)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	gc.apply_run_command({"type": "accept_recruit"})
	_finish_from_between(gc)
	return {"hash": gc.run.state_hash(), "outcome": String(gc.run.outcome)}


# ------------------------------------------------- (0) the demo-run data contract

func test_demo_run_data_contract() -> void:
	# The authored run must stay verbatim-true to its loadout sources (the drift
	# gate the file's _meta promises) and structurally consumable by RunState.
	var data: Dictionary = SimTestBase.load_json(DEMO_RUN_PATH)
	assert_true(String((data.get("_meta", {}) as Dictionary).get("note", "")).contains("PROVISIONAL"),
		"demo_run.json is marked PROVISIONAL in _meta.note")
	var def: Dictionary = demo_run_def()
	assert_eq((def.get("party", []) as Array).size(), 2, "the demo party is the two slice contestants")
	assert_eq((def.get("encounters", []) as Array).size(), 3, "the canonical run is 3 encounters (wave 3c)")

	# Party specs verbatim from demo_loadouts.json via the documented loadout-id
	# rule (combat id = loadout key's first '_'-token).
	var demo_loadouts: Dictionary = SimTestBase.load_json("res://data/demo_loadouts.json")
	var by_key: Dictionary = {}
	for lo: Variant in demo_loadouts.get("loadouts", []) as Array:
		by_key[String((lo as Dictionary).get("key", ""))] = lo
	for spec: Variant in def.get("party", []) as Array:
		var row: Dictionary = spec
		var loadout: Dictionary = by_key.get(String(row.get("loadout_key", "")), {})
		assert_false(loadout.is_empty(), "%s: loadout_key resolves in demo_loadouts.json" % String(row.get("id", "?")))
		assert_eq(String(row.get("id", "")), String(loadout.get("key", "")).get_slice("_", 0),
			"%s: combat id is the loadout key's first token" % String(row.get("id", "?")))
		for trait_key: String in ["physique", "reflexes", "mind", "charm"]:
			assert_eq(int((row.get("traits", {}) as Dictionary).get(trait_key, -1)),
				int((loadout.get("traits", {}) as Dictionary).get(trait_key, -2)),
				"%s: %s verbatim from the loadout" % [String(row.get("id", "?")), trait_key])
		assert_eq((row.get("skills", []) as Array).size(), (loadout.get("skills", []) as Array).size(),
			"%s: full skill kit carried" % String(row.get("id", "?")))
		for i: int in range((row.get("skills", []) as Array).size()):
			var got: Dictionary = (row.get("skills", []) as Array)[i]
			var want: Dictionary = (loadout.get("skills", []) as Array)[i]
			assert_eq(String(got.get("key", "")), String(want.get("key", "?")),
				"%s: skill %d key verbatim" % [String(row.get("id", "?")), i])
			assert_eq(int(got.get("level", -1)), int(want.get("level", -2)),
				"%s: skill %d level verbatim" % [String(row.get("id", "?")), i])
		assert_eq(int(row.get("camera_call_stacks", -1)), int(loadout.get("camera_call_stacks", -2)),
			"%s: camera_call_stacks verbatim" % String(row.get("id", "?")))
		assert_eq(row.has("bit"), loadout.has("bit"),
			"%s: authored-bit presence matches the loadout (decision #25)" % String(row.get("id", "?")))

	# The staged ally IS Sasha's recruit premade, verbatim; the offer key maps to
	# her staged id; the second encounter is the real boss template.
	var enc1: Dictionary = (def.get("encounters", []) as Array)[0]
	assert_eq(String(enc1.get("recruit_offer", "")), "sasha_the_tell", "encounter 1 offers Sasha (the Mind-gap pick)")
	var ally: Dictionary = ((enc1.get("allies", []) as Array)[0] as Dictionary).get("spec", {})
	assert_eq(String(ally.get("id", "")), "sasha", "the offer key's first token is the staged ally id")
	var recruits: Dictionary = SimTestBase.load_json("res://data/recruit_loadouts.json")
	var sasha_loadout: Dictionary = {}
	for lo: Variant in recruits.get("loadouts", []) as Array:
		if String((lo as Dictionary).get("key", "")) == "sasha_the_tell":
			sasha_loadout = lo
	assert_false(sasha_loadout.is_empty(), "sasha_the_tell exists in recruit_loadouts.json")
	for trait_key: String in ["physique", "reflexes", "mind", "charm"]:
		assert_eq(int((ally.get("traits", {}) as Dictionary).get(trait_key, -1)),
			int((sasha_loadout.get("traits", {}) as Dictionary).get(trait_key, -2)),
			"ally sasha: %s verbatim from the recruit premade" % trait_key)
	assert_false(ally.has("bit"), "Sasha has NO authored bit (decision #25 — she never performs)")
	# Decision #32 drift gates: the epithet renames + the authored decline
	# stories, verbatim between the loadout file and the staged ally spec.
	assert_eq(String(ally.get("name", "")), String(sasha_loadout.get("display_name", "?")),
		"ally sasha: display name verbatim from the recruit premade")
	assert_true(String(sasha_loadout.get("display_name", "")).contains("Little shadow"),
		"Sasha's epithet is 'Little shadow' (decision #32 rename)")
	assert_eq(String(ally.get("on_decline", "")), String(sasha_loadout.get("on_decline", "?")),
		"ally sasha: on_decline verbatim from the recruit premade (#32 story-driven declines)")
	assert_eq(String(sasha_loadout.get("on_decline", "")), "may_reoffer",
		"Sasha's authored decline story: the little shadow keeps showing up (PROVISIONAL #32)")
	var nikita_loadout: Dictionary = {}
	for lo: Variant in recruits.get("loadouts", []) as Array:
		if String((lo as Dictionary).get("key", "")) == "nikita_headliner":
			nikita_loadout = lo
	assert_false(nikita_loadout.is_empty(), "nikita_headliner exists in recruit_loadouts.json")
	assert_true(String(nikita_loadout.get("display_name", "")).contains("The lonely"),
		"Nikita's epithet is 'The lonely' (decision #32 rename)")
	assert_eq(String(nikita_loadout.get("on_decline", "")), "gone_for_run",
		"Nikita's authored decline story: pride wounded, he walks for good (PROVISIONAL #32)")
	assert_eq(String((nikita_loadout.get("bit", {}) as Dictionary).get("key", "")), "the_pose",
		"Nikita keeps his authored bit 'The Pose' through the rename")
	var enemy_keys: Dictionary = {}
	for entry: Variant in SimTestBase.load_json("res://data/enemies.json") as Array:
		enemy_keys[String((entry as Dictionary).get("key", ""))] = true
	for enc: Variant in def.get("encounters", []) as Array:
		for row: Variant in (enc as Dictionary).get("enemies", []) as Array:
			assert_true(enemy_keys.has(String((row as Dictionary).get("enemy_key", ""))),
				"%s: enemy_key '%s' is a real template" % [String((enc as Dictionary).get("key", "?")),
					String((row as Dictionary).get("enemy_key", ""))])
	# Wave 3c: the mid room is the KENNEL — the second authored enemy, staged
	# as the pair its data authors (the deeper template pins live in
	# tests/test_second_enemy.gd) — and the finale stays the boss.
	var enc2: Dictionary = (def.get("encounters", []) as Array)[1]
	assert_eq(String(enc2.get("key", "")), "kennel_gauntlet", "encounter 2 is the kennel mid room")
	var hound_row: Dictionary = (enc2.get("enemies", []) as Array)[0]
	assert_eq(String(hound_row.get("enemy_key", "")), "war_hound", "the mid room fields the war hound")
	assert_eq(int(hound_row.get("count", 0)), 2, "staged as the R15 pack PAIR")
	var enc3: Dictionary = (def.get("encounters", []) as Array)[2]
	assert_eq(String(((enc3.get("enemies", []) as Array)[0] as Dictionary).get("enemy_key", "")), "incinedile",
		"the finale is the Incine-Dile fight")


# --------------------------------------------- (1) full-run determinism + purity

func test_full_run_deterministic_and_replayable_from_run_log() -> void:
	var gc_a: Node = _controller()
	var first: Dictionary = _drive_full_run(gc_a)
	assert_eq(String(first["outcome"]), "WIN", "the demo run resolves WIN (all three encounters cleared)")
	assert_eq(gc_a.run.records.size(), 3, "three encounter records on the run")
	for record: Dictionary in gc_a.run.records:
		assert_eq(String(record.get("outcome", "")), "WIN", "encounter %d recorded WIN" % int(record.get("index", -1)))
	assert_eq(gc_a.run.roster.size(), 3, "the roster grew to 3 (accept path)")
	var h := String(first["hash"])
	assert_eq(h.length(), 64, "run hash is a full sha256 hex digest")
	# Pure function of (run seed, ordered run-command log): the identical drive
	# replays to the identical final run hash.
	var gc_b: Node = _controller()
	var second: Dictionary = _drive_full_run(gc_b)
	assert_eq(String(second["hash"]), h, "same run seed + same run+combat command log = same final run hash")
	# And a BARE RunState replaying the controller's run-command log ALONE (no
	# sims, no controller) lands on the same hash — the log carries everything.
	var bare: RunState = RunState.new()
	for cmd: Dictionary in gc_a.run_command_log:
		bare.apply_command(cmd)
	assert_eq(bare.state_hash(), h, "a bare RunState replay of the run log alone reproduces the run state")
	gc_a.free()
	gc_b.free()


# ------------------------------------- (2) the carry policy across the hand-off

func test_damage_carries_and_per_combat_state_resets() -> void:
	var gc: Node = _controller()
	_start_demo_run(gc)
	_drive_encounter_one(gc)
	# Preconditions the carry assertions lean on (post-fight, pre-hand-off).
	assert_eq(int((gc.sim.combatants["imani"] as CombatantState).parts["torso"]["hp"]), 3,
		"precondition: imani's torso took the staged net-2 wound (5 -> 3)")
	assert_eq(int((gc.sim.combatants["sasha"] as CombatantState).parts["torso"]["hp"]), 3,
		"precondition: sasha's torso took the staged net-2 wound (5 -> 3)")
	assert_true((gc.sim.combatants["dario"] as CombatantState).shock >= 1,
		"precondition: dario carries Shock into the combat end")
	assert_true((gc.sim.combatants["dario"] as CombatantState).armed_primes.has("wind_up"),
		"precondition: dario's prime is armed")
	var ended: Array[Dictionary] = gc.apply_run_command({"type": "end_encounter"})
	assert_event(ended, "run_encounter_ended", "encounter 1 closed through the run funnel")
	assert_event(ended, "run_recruit_available", "the def's recruit offer surfaced")
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	var joined: Array[Dictionary] = gc.apply_run_command({"type": "accept_recruit"})
	assert_event(joined, "run_recruit_joined", "accept_recruit joins the roster")
	assert_eq(gc.run.roster.size(), 3, "roster is 3 after the accept")

	gc.apply_run_command({"type": "begin_encounter"})
	# --- PERSISTS into the KENNEL: wounds + conditions (no field HP regen) ----
	var imani: CombatantState = gc.sim.combatants["imani"]
	var sasha: CombatantState = gc.sim.combatants["sasha"]
	var dario: CombatantState = gc.sim.combatants["dario"]
	assert_eq(int(imani.parts["torso"]["hp"]), 3, "imani's wounded torso number survived the hand-off (5-max, 3 left)")
	assert_eq(int(imani.parts["torso"]["base_max_hp"]), 5, "the torso MAX did not drift in the hand-off")
	assert_eq(imani.condition_tier("torso", "crushed"), 1, "imani's crushed T1 rode across the encounters")
	assert_eq(int(sasha.parts["torso"]["hp"]), 3, "the RECRUIT's encounter-1 damage is present in encounter 2 (#31 as-is)")
	assert_eq(sasha.condition_tier("torso", "crushed"), 1, "the recruit's condition carried too")
	assert_true(gc.sim.combatants.has("war_hound_1") and gc.sim.combatants.has("war_hound_2"),
		"the kennel stages the war-hound pair from the def")
	# --- RESETS: per-combat state dies with the encounter ---------------------
	assert_eq(dario.shock, 0, "Shock reset fully at combat end (R13)")
	assert_true(dario.armed_primes.is_empty(), "primes reset with the new combat (R3)")
	assert_eq(dario.stance, "", "stance reset with the new combat")
	assert_eq(gc.sim.clock.tick, 0, "the new encounter runs its own fresh Clock")
	assert_eq(imani.next_action_tick, 0, "scheduling reset with the new Clock")
	# --- B9: the spent Camera Call stack stays spent for the RUN --------------
	assert_eq(int(gc.sim.hype.camera_calls_used.get("dario", 0)), 1,
		"the spent-stack ledger crossed the hand-off (B9: session = one deployment)")
	assert_rejected(gc.apply_command({"type": "camera_call", "actor": "dario", "target": "imani"}),
		"no_camera_call_stacks", "dario's one stack stays spent in encounter 2")
	# --- the EXISTING views keep working mid-encounter ------------------------
	var imani_row: Dictionary = {}
	for row: Variant in gc.view_combatants():
		if String((row as Dictionary).get("id", "")) == "imani":
			imani_row = row
	var torso_row: Dictionary = {}
	for part: Variant in imani_row.get("parts", []) as Array:
		if String((part as Dictionary).get("key", "")) == "torso":
			torso_row = part
	assert_eq(int(torso_row.get("hp", -1)), 3, "view_combatants shows the carried wound mid-encounter")
	assert_eq(int(torso_row.get("max_hp", -1)), 5, "view_combatants shows the honest max")
	var run_view: Dictionary = gc.view_run()
	assert_eq(String(run_view.get("phase", "")), "combat", "view_run reports the active encounter")
	assert_eq(int((run_view.get("encounter", {}) as Dictionary).get("active_index", -1)), 1, "encounter 2 is the active one")
	# --- Q29: treating the carried wound resolves the CONDITION, never HP -----
	var treated: Array[Dictionary] = gc.apply_command(
		{"type": "treat", "target": "imani", "part": "torso", "condition": "crushed", "mode": "resolve"})
	assert_event(treated, "condition_resolved", "the carried crushed wound is treatable in the next fight")
	assert_eq(int(imani.parts["torso"]["hp"]), 3, "treatment resolves conditions but NEVER regenerates HP (Q29/B11)")
	# --- the SECOND hand-off (wave 3c): kennel wounds ride into the finale ----
	gc.apply_command({"type": "treat", "target": "sasha", "part": "torso", "condition": "crushed", "mode": "resolve"})
	_stage_hound_bites(gc)
	# The staged tick-0 bites are deterministic hand math (no live AI yet):
	# a lone hound's Force 2 is blocked by the tank; sasha takes net 1.
	var staged: Array[Dictionary] = gc.apply_command({"type": "advance_tick"})
	var blocked: Dictionary = assert_event(staged, "attack_no_wound", "the tank Robustness-blocks the lone bite")
	assert_eq(String(blocked.get("combatant", "")), "imani", "imani shrugs the lone hound (Force 2 vs Robustness 2)")
	assert_eq(int(imani.parts["torso"]["hp"]), 3, "imani's torso number is untouched by the blocked bite")
	assert_eq(int(sasha.parts["torso"]["hp"]), 2, "sasha's carried torso 3 took the staged net-1 bite (-> 2)")
	assert_true(sasha.condition_tier("torso", "bleeding") >= 1, "the bite's bleeding rider landed on her")
	_fight_hounds(gc, MAX_FIGHT_TICKS)
	assert_eq(String(gc.combat_status().get("outcome", "")), "WIN", "the kennel falls")
	# Capture the EXACT post-kennel wounds (the live hound decide may have added
	# to them — captured, not assumed), then verify the finale stages them
	# VERBATIM: the run's wounds-persist policy holds across BOTH hand-offs.
	var post_kennel: Dictionary = {}
	for id: String in ["imani", "dario", "sasha"]:
		var member: CombatantState = gc.sim.combatants[id]
		var hp_by_part: Dictionary = {}
		var member_part_keys: Array = member.parts.keys()
		member_part_keys.sort()
		for part_key: Variant in member_part_keys:
			hp_by_part[String(part_key)] = int((member.parts[part_key] as Dictionary).get("hp", 0))
		post_kennel[id] = hp_by_part
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "begin_encounter"})
	for id: String in ["imani", "dario", "sasha"]:
		var member: CombatantState = gc.sim.combatants[id]
		for part_key: Variant in (post_kennel[id] as Dictionary):
			assert_eq(int((member.parts[part_key] as Dictionary).get("hp", -1)),
				int((post_kennel[id] as Dictionary)[part_key]),
				"%s/%s: the kennel wound number stages VERBATIM into the finale" % [id, String(part_key)])
	assert_true((gc.sim.combatants["sasha"] as CombatantState).condition_tier("torso", "bleeding") >= 1,
		"sasha's untreated bleeding rode the second hand-off too (B11)")
	# The finale's boss starts its own fresh discovery (per-combat state).
	var boss: CombatantState = gc.sim.combatants["boss"]
	assert_false(boss.breached, "breach state does NOT persist — the finale starts surface-immune")
	assert_true(bool(boss.parts["network"]["hidden"]), "the network starts hidden (per-combat discovery)")
	assert_eq(gc.sim.clock.tick, 0, "the finale runs its own fresh Clock")
	assert_eq(int((gc.view_run().get("encounter", {}) as Dictionary).get("active_index", -1)), 2,
		"the finale is the active encounter")
	gc.free()


# ----------------------------------------------------------- (3) decline path

func test_decline_in_the_demo_run_honors_sashas_may_reoffer_story() -> void:
	# Sasha's authored on_decline is may_reoffer (decision #32, PROVISIONAL
	# reading of "Little shadow"): declining leaves NO gone-for-run mark — but
	# the demo run's second encounter carries no recruit_offer, so she simply
	# is not staged again (the actual RE-offer beats are pinned synthetically
	# in section 9 below).
	var gc: Node = _controller()
	_start_demo_run(gc)
	_drive_encounter_one(gc)
	gc.apply_run_command({"type": "end_encounter"})
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	var declined: Array[Dictionary] = gc.apply_run_command({"type": "decline_recruit"})
	assert_eq(String(assert_event(declined, "run_recruit_declined", "decline_recruit emits its run event")
		.get("on_decline", "")), "may_reoffer", "the event reports Sasha's authored story policy")
	assert_true(gc.run.declined.is_empty(), "a may_reoffer decline leaves no gone-for-run mark (#32)")
	assert_eq(gc.run.roster.size(), 2, "the roster stays 2")
	# The beat is SPENT — nothing is available to re-ask between encounters
	# (only a later encounter's recruit_offer could open a fresh beat).
	var reoffer: Array[Dictionary] = gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	assert_eq(String(first_event(reoffer, "run_command_rejected").get("reason", "")), "no_such_offer",
		"no beat is open between encounters — a re-offer needs a later encounter's recruit_offer")
	gc.apply_run_command({"type": "begin_encounter"})
	assert_false(gc.sim.combatants.has("sasha"), "encounter 2 is staged WITHOUT the declined recruit")
	assert_eq(gc.sim.combatants.size(), 4, "imani + dario + the kennel pair on the table")
	var run_view: Dictionary = gc.view_run()
	assert_eq((run_view.get("roster", []) as Array).size(), 2, "view_run's roster stays the founding pair")
	gc.free()


# ------------------------------------------------- (4) run outcomes / the wipe

func test_party_wipe_in_encounter_one_ends_the_run_as_loss() -> void:
	var gc: Node = _controller()
	_start_demo_run(gc)
	gc.apply_run_command({"type": "begin_encounter"})
	# Deterministic wipe: lethal suffocation on every party torso (the
	# test_run_loop idiom); the brood is left alone — no enemy turns needed.
	for id: String in ["imani", "dario", "sasha"]:
		gc.apply_command({"type": "apply_condition", "target": id, "part": "torso", "condition": "suffocation"})
	_advance_until_over(gc, 150)
	assert_eq(String(gc.combat_status().get("outcome", "")), "LOSS", "precondition: the party wiped")
	var ended: Array[Dictionary] = gc.apply_run_command({"type": "end_encounter"})
	var run_ended: Dictionary = assert_event(ended, "run_ended", "a wipe finishes the run on the spot")
	assert_eq(String(run_ended.get("outcome", "")), "LOSS", "the run outcome is LOSS")
	assert_no_event(ended, "run_recruit_available", "no offer beat on a wipe — nobody made it out")
	assert_eq(String(gc.run.outcome), "LOSS", "run state carries the LOSS")
	var blocked: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	assert_eq(String(first_event(blocked, "run_command_rejected").get("reason", "")), "run_finished",
		"encounter 2 never starts after the wipe")
	assert_eq(gc.run.records.size(), 1, "only the one encounter is on the record")
	gc.free()


# -------------------------------------- (5) save/restore BETWEEN encounters

func test_save_restore_between_encounters_identical_continuation() -> void:
	var gc_live: Node = _controller()
	_start_demo_run(gc_live)
	_drive_encounter_one(gc_live)
	gc_live.apply_run_command({"type": "end_encounter"})
	gc_live.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	gc_live.apply_run_command({"type": "accept_recruit"})
	# The between-encounters checkpoint: run state ONLY (no sim is live-relevant
	# between fights — the next one is re-derived from run state).
	var checkpoint: Dictionary = gc_live.run.to_dict()
	_finish_from_between(gc_live)
	var live_hash: String = gc_live.run.state_hash()
	assert_eq(String(gc_live.run.outcome), "WIN", "precondition: the live continuation wins the run")
	# Restore into a FRESH controller from the serialized checkpoint alone and
	# drive the identical continuation.
	var gc_restored: Node = _controller()
	gc_restored.restore_run(checkpoint, {}, load_static_data())
	assert_eq(gc_restored.run.roster.size(), 3, "the restored roster carries the recruit")
	_finish_from_between(gc_restored)
	assert_eq(gc_restored.run.state_hash(), live_hash,
		"save/restore between encounters -> identical continuation (identical final run hash)")
	gc_live.free()
	gc_restored.free()


# ------------------------------------- (6) save/restore MID-encounter-2

func test_save_restore_mid_encounter_two_identical_continuation() -> void:
	# Mid-KENNEL (wave 3c): the save lands one tick into the hound fight —
	# hound 1 down, hound 2 alive — so the SECOND AUTHORED ENEMY itself rides
	# CombatSim serialization mid-fight.
	var gc_live: Node = _controller()
	_start_demo_run(gc_live)
	_drive_encounter_one(gc_live)
	gc_live.apply_run_command({"type": "end_encounter"})
	gc_live.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	gc_live.apply_run_command({"type": "accept_recruit"})
	gc_live.apply_run_command({"type": "begin_encounter"})
	_treat_carried_wounds(gc_live)
	_stage_hound_bites(gc_live)
	_fight_hounds(gc_live, 1)  # one real fight tick in — genuinely mid-encounter
	assert_false(bool(gc_live.combat_status().get("over", false)), "precondition: the fight is NOT over at the save")
	assert_true((gc_live.sim.combatants["war_hound_2"] as CombatantState).alive,
		"precondition: a live war hound is mid-fight at the save")
	var run_snapshot: Dictionary = gc_live.run.to_dict()
	var sim_snapshot: Dictionary = gc_live.sim.to_dict()
	_fight_hounds(gc_live, MAX_FIGHT_TICKS)
	gc_live.apply_run_command({"type": "end_encounter"})
	_finish_finale(gc_live)
	var live_run_hash: String = gc_live.run.state_hash()
	var live_sim_hash: String = gc_live.sim.state_hash()
	assert_eq(String(gc_live.run.outcome), "WIN", "precondition: the live continuation wins the run")
	# Restore run + mid-fight sim into a fresh controller; the recruited member
	# must be mid-fight with her carried state, the hound with its wave-3c
	# template state, and the identical guarded continuation must land on
	# identical hashes.
	var gc_restored: Node = _controller()
	gc_restored.restore_run(run_snapshot, sim_snapshot, load_static_data())
	assert_true(gc_restored.sim.combatants.has("sasha"), "the recruited member is in the restored mid-fight sim")
	assert_eq(int((gc_restored.sim.combatants["sasha"] as CombatantState).parts["torso"]["hp"]), 2,
		"her carried encounter-1 wound + the staged kennel bite are in the restored fight")
	assert_true((gc_restored.sim.combatants["war_hound_2"] as CombatantState).alive,
		"the live war hound is in the restored fight")
	_fight_hounds(gc_restored, MAX_FIGHT_TICKS)
	gc_restored.apply_run_command({"type": "end_encounter"})
	_finish_finale(gc_restored)
	assert_eq(gc_restored.run.state_hash(), live_run_hash,
		"mid-encounter-2 save/restore -> identical final run hash")
	assert_eq(gc_restored.sim.state_hash(), live_sim_hash,
		"and the final combat states match hash-for-hash")
	gc_live.free()
	gc_restored.free()


# ----------------------------------------------------- (7) run-command gating

func test_run_command_gating_and_abandon() -> void:
	var gc: Node = _controller()
	_start_demo_run(gc)
	# end_encounter with no fight staged / begin twice / accept with no offer.
	var no_fight: Array[Dictionary] = gc.apply_run_command({"type": "end_encounter"})
	assert_eq(String(first_event(no_fight, "run_command_rejected").get("reason", "")), "no_active_combat",
		"end_encounter with no staged fight rejects")
	gc.apply_run_command({"type": "begin_encounter"})
	var mid_fight: Array[Dictionary] = gc.apply_run_command({"type": "end_encounter"})
	assert_eq(String(first_event(mid_fight, "run_command_rejected").get("reason", "")), "encounter_not_resolved",
		"the run never records an outcome the sim does not show (honesty gate)")
	assert_eq(String(gc.run.phase), "combat", "the rejected end left the encounter live")
	var double_begin: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	assert_eq(String(first_event(double_begin, "run_command_rejected").get("reason", "")), "encounter_active",
		"begin_encounter while one is live rejects")
	_drive_encounter_one_after_begin(gc)
	gc.apply_run_command({"type": "end_encounter"})
	# The offer beat is unmissable: begin/end_run reject while it is unresolved,
	# accept rejects before the beat is opened.
	var skip_offer: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	assert_eq(String(first_event(skip_offer, "run_command_rejected").get("reason", "")), "offer_unresolved",
		"the run cannot roll past an unresolved recruit offer")
	var early_accept: Array[Dictionary] = gc.apply_run_command({"type": "accept_recruit"})
	assert_eq(String(first_event(early_accept, "run_command_rejected").get("reason", "")), "no_open_offer",
		"accept_recruit needs the beat opened by offer_recruit")
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	var begin_in_offer: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	assert_eq(String(first_event(begin_in_offer, "run_command_rejected").get("reason", "")), "offer_pending",
		"begin_encounter rejects while the offer beat is open")
	gc.apply_run_command({"type": "decline_recruit"})
	# Early extraction (PROVISIONAL): ending the run with encounters left is an
	# ABANDONED outcome, not a WIN.
	var ended: Array[Dictionary] = gc.apply_run_command({"type": "end_run"})
	assert_eq(String(assert_event(ended, "run_ended", "end_run closes the run").get("outcome", "")), "ABANDONED",
		"1 of 3 encounters cleared -> ABANDONED (PROVISIONAL)")
	var again: Array[Dictionary] = gc.apply_run_command({"type": "end_run"})
	assert_eq(String(first_event(again, "run_command_rejected").get("reason", "")), "run_already_ended",
		"a finished run rejects further run commands")
	gc.free()


# ------------------------- (8) hype chains across encounters (decision #32)
# Synthetic bare-reducer runs (the replay idiom — RunState consumes ENRICHED
# commands directly, no sims), so the retention arithmetic pins exactly.

static func _plain_defs(count: int) -> Array:
	var defs: Array = []
	for i: int in range(count):
		defs.append({"key": "enc_%d" % (i + 1), "kind": "combat"})
	return defs


static func _start_synthetic(run: RunState, defs: Array) -> void:
	run.apply_command({"type": "start_run", "seed": 9,
		"party": [{"id": "ava", "name": "Ava"}], "encounters": defs})


## An enriched WIN end_encounter (what the controller would log): the founder
## survives; extra_carried adds staged-ally captures (the recruit beats).
static func _win_cmd(hype: int, extra_carried: Dictionary = {}) -> Dictionary:
	var carried: Dictionary = {"ava": {"alive": true}}
	carried.merge(extra_carried, true)
	return {"type": "end_encounter", "outcome": "WIN", "carried": carried, "hype_meter": hype}


func test_hype_chain_retention_ladder_exact_math() -> void:
	# Decision #32 over a 6-encounter synthetic chain, floor rounding pinned:
	# links open at 0%, 40%, 60%, 80%, 100%, then 100% for all further links.
	var run := RunState.new()
	_start_synthetic(run, _plain_defs(6))
	var expectations: Array = [
		# [ending meter fed to end_encounter, the NEXT link's expected opening meter]
		[137, 54],   # 40%: floor(137 * 0.40) = floor(54.8) -> 54
		[47, 28],    # 60%: floor(47 * 0.60) = floor(28.2) -> 28
		[21, 16],    # 80%: floor(21 * 0.80) = floor(16.8) -> 16
		[9, 9],      # 100%: link 4 retains everything
		[200, 200],  # 100% HOLDS for every further link
	]
	var started: Array[Dictionary] = run.apply_command({"type": "begin_encounter"})
	assert_eq(int(assert_event(started, "run_encounter_started", "encounter 1 starts").get("hype_start", -1)), 0,
		"a chain-opening encounter starts at meter 0")
	assert_eq(int(run.staging().get("hype_start", -1)), 0, "staging agrees for the chain opener")
	for i: int in range(expectations.size()):
		var ending: int = int((expectations[i] as Array)[0])
		var want: int = int((expectations[i] as Array)[1])
		run.apply_command(_win_cmd(ending))
		assert_eq(run.hype_chain_index, i + 1, "link count advanced with completed encounter %d" % (i + 1))
		assert_eq(run.chain_hype_start(), want, "link %d opens at the pinned floor" % (i + 2))
		started = run.apply_command({"type": "begin_encounter"})
		assert_eq(int(assert_event(started, "run_encounter_started", "the next link starts").get("hype_start", -1)),
			want, "run_encounter_started carries the retained meter for link %d" % (i + 2))
		assert_eq(int(run.staging().get("hype_start", -1)), want,
			"staging carries the retained meter for link %d" % (i + 2))
	run.apply_command(_win_cmd(5))
	run.apply_command({"type": "end_run"})
	assert_eq(String(run.outcome), "WIN", "the synthetic chain cleared cleanly")


func test_hype_chain_survives_save_restore_between_encounters() -> void:
	# The chain index SERIALIZES: a between-encounters to_dict/from_dict round
	# trip must stage the same retained meter as the uninterrupted run.
	var live := RunState.new()
	_start_synthetic(live, _plain_defs(3))
	live.apply_command({"type": "begin_encounter"})
	live.apply_command(_win_cmd(137))
	live.apply_command({"type": "begin_encounter"})
	live.apply_command(_win_cmd(50))
	var snapshot: Dictionary = live.to_dict()
	assert_eq(int(snapshot.get("hype_chain_index", -1)), 2, "hype_chain_index is in the serialized run state")
	var restored: RunState = RunState.from_dict(snapshot)
	assert_eq(restored.hype_chain_index, 2, "the chain index survived the round trip")
	assert_eq(restored.state_hash(), live.state_hash(), "the round trip is state-hash faithful")
	assert_eq(restored.chain_hype_start(), 30, "the restored link 3 opens at floor(50 * 0.60) = 30")
	# Identical continuations (retention path included) land identical hashes.
	for run: RunState in ([live, restored] as Array):
		run.apply_command({"type": "begin_encounter"})
		run.apply_command(_win_cmd(80))
		run.apply_command({"type": "end_run"})
	assert_eq(restored.state_hash(), live.state_hash(), "identical continuations land identical hashes")
	# Mutation teeth: a tampered chain index must change the hash.
	var tampered: Dictionary = live.to_dict()
	tampered["hype_chain_index"] = 7
	assert_ne(RunState.from_dict(tampered).state_hash(), live.state_hash(),
		"hype_chain_index is covered by the run state hash")


func test_chained_encounter_opens_with_retained_meter_in_the_live_sim() -> void:
	# Decision #32 end to end through the controller — the FULLY LIVE ladder
	# over the authored 3-encounter run (wave 3c): the kennel OPENS with
	# floor(40% x encounter 1's recorded ending meter) on the LIVE HypeEngine,
	# and the finale with floor(60% x the kennel's recorded ending meter).
	var gc: Node = _controller()
	_start_demo_run(gc)
	_drive_encounter_one(gc)
	gc.apply_run_command({"type": "end_encounter"})
	var ending: int = int((gc.run.records[0] as Dictionary).get("hype_meter", -1))
	assert_true(ending > 0, "honesty precondition: the brood fight actually generated hype (got %d)" % ending)
	var expected: int = int(floor(ending * 40 / 100.0))
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	gc.apply_run_command({"type": "accept_recruit"})
	var started: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	assert_eq(int(assert_event(started, "run_encounter_started", "encounter 2 starts").get("hype_start", -1)),
		expected, "the run event announces the retained meter")
	assert_eq(int(gc.sim.hype.meter), expected, "the staged sim's HypeEngine OPENS at the retained meter")
	var want_band := "cold"
	for entry: Variant in HypeEngine.BANDS:
		if expected >= int((entry as Array)[1]):
			want_band = String((entry as Array)[0])
			break
	assert_eq(String(gc.sim.hype.band), want_band, "the opening band matches the engine's own floors")
	var chain_view: Dictionary = gc.view_run().get("hype_chain", {})
	assert_eq(int(chain_view.get("index", -1)), 1, "view_run exposes the chain link count")
	assert_eq(int(chain_view.get("hype_start", -1)), expected, "view_run exposes the retained opening meter")
	# Link 2 (the finale) opens at 60% of the KENNEL's ending meter.
	_treat_carried_wounds(gc)
	_stage_hound_bites(gc)
	_fight_hounds(gc, MAX_FIGHT_TICKS)
	gc.apply_run_command({"type": "end_encounter"})
	var kennel_ending: int = int((gc.run.records[1] as Dictionary).get("hype_meter", -1))
	assert_true(kennel_ending > 0, "honesty precondition: the kennel fight actually generated hype (got %d)" % kennel_ending)
	var expected_finale: int = int(floor(kennel_ending * 60 / 100.0))
	var finale_started: Array[Dictionary] = gc.apply_run_command({"type": "begin_encounter"})
	assert_eq(int(assert_event(finale_started, "run_encounter_started", "the finale starts").get("hype_start", -1)),
		expected_finale, "the finale opens at floor(60% x the kennel's ending meter)")
	assert_eq(int(gc.sim.hype.meter), expected_finale, "the finale's LIVE HypeEngine opens retained")
	var finale_chain: Dictionary = gc.view_run().get("hype_chain", {})
	assert_eq(int(finale_chain.get("index", -1)), 2, "the chain is two links deep at the finale")
	assert_eq(int(finale_chain.get("hype_start", -1)), expected_finale, "view_run carries the finale's retained meter")
	gc.free()


# --------------------- (9) story-driven declines (decision #32, synthetic)
# Three-encounter synthetic runs where EVERY encounter stages the same recruit
# as an ally and offers them — the shape the demo run cannot exercise yet.

static func _recruit_defs(count: int, recruit_key: String, on_decline: String) -> Array:
	var defs: Array = []
	for i: int in range(count):
		defs.append({
			"key": "enc_%d" % (i + 1), "kind": "combat",
			"allies": [{"spec": {"id": recruit_key.get_slice("_", 0), "name": "Rex",
				"team": "party", "on_decline": on_decline}}],
			"recruit_offer": recruit_key,
		})
	return defs


func test_decline_gone_for_run_bars_reoffer_for_the_run() -> void:
	# on_decline "gone_for_run" = the #31 behavior, now authored per #32.
	var run := RunState.new()
	_start_synthetic(run, _recruit_defs(2, "rex_solo", "gone_for_run"))
	run.apply_command({"type": "begin_encounter"})
	run.apply_command(_win_cmd(0, {"rex": {"alive": true}}))
	run.apply_command({"type": "offer_recruit", "recruit_key": "rex_solo"})
	var declined_events: Array[Dictionary] = run.apply_command({"type": "decline_recruit"})
	assert_eq(String(assert_event(declined_events, "run_recruit_declined", "the decline resolves")
		.get("on_decline", "")), "gone_for_run", "the event reports the honored policy")
	assert_true(run.declined.has("rex_solo"), "a gone_for_run decline marks the recruit gone")
	# The LATER encounter stages him again and he survives — still no offer.
	run.apply_command({"type": "begin_encounter"})
	var ended: Array[Dictionary] = run.apply_command(_win_cmd(0, {"rex": {"alive": true}}))
	assert_no_event(ended, "run_recruit_available", "a gone recruit is never re-offered by a later encounter")
	var reoffer: Array[Dictionary] = run.apply_command({"type": "offer_recruit", "recruit_key": "rex_solo"})
	assert_eq(String(first_event(reoffer, "run_command_rejected").get("reason", "")), "recruit_declined_for_run",
		"the explicit re-ask rejects exactly like #31 always did")
	assert_true(RunState.from_dict(run.to_dict()).declined.has("rex_solo"),
		"the gone-mark survives a serialization round trip")


func test_decline_may_reoffer_allows_a_later_fresh_offer_and_accept() -> void:
	var run := RunState.new()
	_start_synthetic(run, _recruit_defs(3, "rex_shadow", "may_reoffer"))
	run.apply_command({"type": "begin_encounter"})
	run.apply_command(_win_cmd(0, {"rex": {"alive": true}}))
	run.apply_command({"type": "offer_recruit", "recruit_key": "rex_shadow"})
	var declined_events: Array[Dictionary] = run.apply_command({"type": "decline_recruit"})
	assert_eq(String(assert_event(declined_events, "run_recruit_declined", "the decline resolves")
		.get("on_decline", "")), "may_reoffer", "the event reports the honored policy")
	assert_true(run.declined.is_empty(), "a may_reoffer decline leaves NO gone-mark")
	assert_eq(run.roster.size(), 1, "and the roster does not grow")
	# A LATER encounter's recruit_offer finds him eligible again — a FRESH beat.
	run.apply_command({"type": "begin_encounter"})
	var ended: Array[Dictionary] = run.apply_command(_win_cmd(0, {"rex": {"alive": true}}))
	assert_event(ended, "run_recruit_available", "the later encounter re-offers the may_reoffer recruit")
	var offered: Array[Dictionary] = run.apply_command({"type": "offer_recruit", "recruit_key": "rex_shadow"})
	assert_event(offered, "run_recruit_offered", "the fresh offer beat opens")
	var joined: Array[Dictionary] = run.apply_command({"type": "accept_recruit"})
	assert_event(joined, "run_recruit_joined", "accept works on the second ask")
	assert_eq(run.roster.size(), 2, "the roster grew on the second ask")
	var rex_row: Dictionary = {}
	for row: Dictionary in run.roster:
		if String(row["id"]) == "rex":
			rex_row = row
	assert_eq(int(rex_row.get("joined_encounter", -9)), 1, "he joined at the SECOND encounter (index 1)")
	# Already on the roster: the third encounter must NOT offer him again.
	run.apply_command({"type": "begin_encounter"})
	var third: Array[Dictionary] = run.apply_command(_win_cmd(0, {"rex": {"alive": true}}))
	assert_no_event(third, "run_recruit_available", "a rostered recruit is never offered again")
	run.apply_command({"type": "end_run"})
	assert_eq(String(run.outcome), "WIN", "the synthetic run closes clean")


func test_declining_a_may_reoffer_recruit_again_re_honors_the_data() -> void:
	var run := RunState.new()
	_start_synthetic(run, _recruit_defs(3, "rex_shadow", "may_reoffer"))
	for round_i: int in range(2):
		run.apply_command({"type": "begin_encounter"})
		run.apply_command(_win_cmd(0, {"rex": {"alive": true}}))
		run.apply_command({"type": "offer_recruit", "recruit_key": "rex_shadow"})
		var declined_events: Array[Dictionary] = run.apply_command({"type": "decline_recruit"})
		assert_eq(String(assert_event(declined_events, "run_recruit_declined", "decline resolves")
			.get("on_decline", "")), "may_reoffer", "decline %d re-honors the recruit's data" % (round_i + 1))
		assert_true(run.declined.is_empty(), "still no gone-mark after decline %d" % (round_i + 1))
	# Third encounter: STILL offerable — the story data holds indefinitely.
	run.apply_command({"type": "begin_encounter"})
	var ended: Array[Dictionary] = run.apply_command(_win_cmd(0, {"rex": {"alive": true}}))
	assert_event(ended, "run_recruit_available", "the recruit keeps showing up (may_reoffer honored again)")
	run.apply_command({"type": "offer_recruit", "recruit_key": "rex_shadow"})
	run.apply_command({"type": "accept_recruit"})
	assert_eq(run.roster.size(), 2, "and can still finally be accepted")


# --------------------------- (10) the #32 epithets surface on the run views

func test_epithets_surface_on_the_run_views() -> void:
	# Decision #32 renames flow wherever the loadout personas flow: the offer
	# beats, the view_run roster and view_combatants all carry the ally spec's
	# display name (copied verbatim from recruit_loadouts.json).
	var gc: Node = _controller()
	_start_demo_run(gc)
	_drive_encounter_one(gc)
	gc.apply_run_command({"type": "end_encounter"})
	var available: Dictionary = gc.view_run().get("available_offer", {})
	assert_true(String(available.get("name", "")).contains("Little shadow"),
		"the available offer surfaces Sasha's #32 epithet (got '%s')" % String(available.get("name", "")))
	gc.apply_run_command({"type": "offer_recruit", "recruit_key": "sasha_the_tell"})
	var pending: Dictionary = gc.view_run().get("pending_offer", {})
	assert_true(String(pending.get("name", "")).contains("Little shadow"), "the open beat surfaces it too")
	gc.apply_run_command({"type": "accept_recruit"})
	var sasha_row: Dictionary = {}
	for row: Variant in gc.view_run().get("roster", []) as Array:
		if String((row as Dictionary).get("id", "")) == "sasha":
			sasha_row = row
	assert_true(String(sasha_row.get("name", "")).contains("Little shadow"),
		"the view_run roster row carries the renamed epithet")
	gc.apply_run_command({"type": "begin_encounter"})
	var combatant_row: Dictionary = {}
	for row: Variant in gc.view_combatants():
		if String((row as Dictionary).get("id", "")) == "sasha":
			combatant_row = row
	assert_true(String(combatant_row.get("name", "")).contains("Little shadow"),
		"view_combatants shows the staged recruit under her renamed epithet")
	gc.free()
