extends SimTestBase
## R24 — feint-read: the Mind counter to feints (decision-log #30, owner
## 2026-07-25). The feint's read threshold (SkillBook spec data, 4 + level —
## PLACEHOLDER R14, spec-overridable via read_threshold) asks the DEFENDER's
## Mind through the R22 threshold machinery (EnemyAI.check_feint_read):
##   Mind >= threshold            -> auto-read, NO rng consumed.
##   Mind + threshold die >= t    -> roll the stat's die (default 1d4, per-stat
##                                   upgradeable) off the salted ai_rng.
##   Mind + die max < threshold   -> IMPOSSIBLE: no rng, no event.
## A READ feint is WASTED: nothing arms on the reader, the feinter's Moment is
## spent normally, the R22-shaped feint_read event fires, and the reader adds
## mock-grudge (R23: passing the Mind gate IS getting the insult) even when
## authored mock-INsensitive. A LANDED feint keeps the existing mock_sensitive
## path unchanged. The gate is stats, never category — contestants read too.
##
## RNG-consumption pins use a TWIN RandomNumberGenerator seeded to the live
## stream's state (the test_reflexes_dodge idiom): exactly-one-draw and
## zero-draw claims are proven against the twin, not inferred from events.


func add_enemy(sim: CombatSim, id: String, enemy_key: String, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": enemy_key,
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


## A durable AI reader: mob tier, one big carapace, authored Mind per test — it
## never acts (no ai_decide), so the only rng in play is the read check's own.
func add_reader(sim: CombatSim, id: String, mind: int, overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"body_parts": [{"key": "carapace", "name": "Carapace", "hp": 40, "lethal": true}],
		"traits": {"physique": 1, "reflexes": 2, "mind": mind, "charm": 0},
	}
	spec.merge(overrides, true)
	return add_enemy(sim, id, "roach_dog", spec)


## Default L3 = Dario's granted level — read threshold 4 + 3 = 7.
func feint(sim: CombatSim, actor: String, target: String, level: int = 3) -> Array[Dictionary]:
	declare(sim, actor, {
		"kind": "skill", "key": "feint", "level": level, "attack_range": 1,
		"targets": [{"id": target, "part": "torso"}],
	})
	return advance(sim, 1)


# ---------------------------------------------------------------- the unified check

func test_auto_read_at_mind_threshold_consumes_no_rng() -> void:
	# Boundary pin: L3 threshold 7 == the reader's Mind 7 -> auto-read.
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_reader(sim, "sage", 7)
	assert_eq(int(SkillBook.mechanics("feint", 3).get("read_threshold", 0)), 7,
		"the L3 feint spec carries read threshold 4 + level = 7 (PLACEHOLDER R14)")
	var state_before: int = sim.ai.ai_rng.state
	var resolved: Array[Dictionary] = feint(sim, "trick", "sage")
	var read: Dictionary = assert_event(resolved, "feint_read", "Mind 7 >= threshold 7 auto-reads")
	assert_true(bool(read.get("auto", false)), "auto flag set")
	assert_eq(int(read.get("roll", -1)), 0, "auto-read carries roll 0")
	assert_eq(int(read.get("mind", 0)), 7, "reader Mind emitted")
	assert_eq(int(read.get("die", 0)), 4, "default d4 die size emitted")
	assert_eq(int(read.get("threshold", 0)), 7, "threshold emitted")
	assert_eq(String(read.get("reader", "")), "sage", "the reader is attributed")
	assert_eq(String(read.get("feinter", "")), "trick", "the feinter is attributed")
	assert_eq(sim.ai.ai_rng.state, state_before, "an auto-read consumes NO rng")
	# WASTED: nothing arms on the reader.
	var sage: CombatantState = sim.combatants["sage"]
	assert_false(sage.feint_forced, "nothing armed on the reader")
	assert_eq(sage.feint_by, "", "no attribution armed either")
	assert_no_event(resolved, "feint_applied", "a read feint never applies")
	# The feinter's Moment is SPENT normally — a read, not a rejection.
	var ok: Dictionary = assert_event(resolved, "action_resolved", "the action still resolves")
	assert_eq(String(ok.get("result", "")), "ok", "resolved ok — a read, not a rejection")
	assert_eq(int((sim.combatants["trick"] as CombatantState).next_action_tick), 1,
		"the feinter's Moment is spent (cost 1: ready again at tick 1)")


func test_feint_read_event_shape() -> void:
	# R22-shaped payload contract for the broadcast layer: exactly the R24
	# fields plus the tick/moment stamp the sim adds to every emitted event.
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_reader(sim, "sage", 7)
	var read: Dictionary = first_event(feint(sim, "trick", "sage"), "feint_read")
	var keys: Array = read.keys()
	keys.sort()
	assert_eq(keys, ["auto", "die", "feinter", "mind", "moment", "reader", "roll", "threshold", "tick", "type"],
		"the event carries exactly the R24 payload (+ the standard clock stamp)")


func test_rolled_read_consumes_exactly_one_draw_both_ways() -> void:
	# Mind 4 < threshold 7, 4 + d4 covers it: every feint rolls the d4 exactly
	# once; 4 + roll >= 7 reads (3+), a 1-2 lands the feint. The twin RNG proves
	# the draw count AND the drawn value per round.
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_reader(sim, "elite", 4)
	var elite: CombatantState = sim.combatants["elite"]
	var reads_seen: bool = false
	var lands_seen: bool = false
	for i: int in range(10):
		var armed_before: bool = elite.feint_forced
		var pre: int = sim.ai.ai_rng.state
		var resolved: Array[Dictionary] = feint(sim, "trick", "elite")
		var twin := RandomNumberGenerator.new()
		twin.state = pre
		var expected_roll: int = twin.randi_range(1, 4)
		assert_eq(sim.ai.ai_rng.state, twin.state, "round %d: exactly ONE draw consumed" % i)
		if 4 + expected_roll >= 7:
			var read: Dictionary = assert_event(resolved, "feint_read", "round %d: 4 + %d >= 7 reads" % [i, expected_roll])
			assert_eq(int(read.get("roll", -1)), expected_roll, "round %d: the emitted roll IS the stream's next d4" % i)
			assert_false(bool(read.get("auto", true)), "round %d: a rolled read is not auto" % i)
			assert_no_event(resolved, "feint_applied", "round %d: the read feint is wasted" % i)
			assert_eq(elite.feint_forced, armed_before, "round %d: a read arms NOTHING new" % i)
			reads_seen = true
		else:
			assert_event(resolved, "feint_applied", "round %d: 4 + %d < 7 — the feint ARMS normally" % [i, expected_roll])
			assert_no_event(resolved, "feint_read", "round %d: a failed read emits no read event" % i)
			assert_true(elite.feint_forced, "round %d: feint_forced armed on the failed read" % i)
			assert_eq(elite.feint_by, "trick", "round %d: attribution armed with it" % i)
			lands_seen = true
	assert_true(reads_seen, "seed 1234 actually read at least once")
	assert_true(lands_seen, "seed 1234 actually landed at least once")


func test_impossible_read_is_the_incinedile_case() -> void:
	# The R24 recorded consequence, pinned EXACTLY: Incinedile Mind 1 + d4 max
	# = 5 < 7 (Dario's L3 feint) — the read is impossible, no rng is consumed,
	# and the feint always lands. The slice fight and the balance WIN are
	# untouched: intelligence, not stats-frozen tuning, is the counter.
	var sim: CombatSim = make_sim()
	add_human(sim, "dario", {"team": "party", "position": [1, 0]})
	add_enemy(sim, "boss", "incinedile")
	var boss: CombatantState = sim.combatants["boss"]
	assert_eq(boss.trait_total("mind"), 1, "the seeded boss Mind is exactly 1")
	assert_eq(boss.threshold_die("mind"), 4, "no authored mind die — the default d4 (max 5)")
	assert_eq(int(SkillBook.mechanics("feint", 3).get("read_threshold", 0)), 7,
		"the L3 read threshold is exactly 7")
	var state_before: int = sim.ai.ai_rng.state
	var resolved: Array[Dictionary] = feint(sim, "dario", "boss")
	assert_no_event(resolved, "feint_read", "an impossible read emits nothing")
	assert_event(resolved, "feint_applied", "the feint lands — the dim boss stays feintable")
	assert_true(boss.feint_forced, "feint_forced armed")
	assert_eq(sim.ai.ai_rng.state, state_before, "an impossible read consumes NO rng")
	assert_no_event(resolved, "antagonism_changed", "no grudge either: mock_sensitive false, no read")


# ---------------------------------------------------------------- grudge + category

func test_read_adds_mock_grudge_even_for_mock_insensitive_readers() -> void:
	# R23 via R24: passing the Mind gate IS getting the insult — the read
	# replaces the mock_sensitive gate for readers. An authored-INsensitive
	# high-Mind mob still grudges the feinter it reads.
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_reader(sim, "proud", 7, {"personality": {"mock_sensitive": false, "mock_grudge": 5.0}})
	var proud: CombatantState = sim.combatants["proud"]
	assert_false(proud.personality_mock_sensitive(), "authored mock-INsensitive")
	var resolved: Array[Dictionary] = feint(sim, "trick", "proud")
	assert_event(resolved, "feint_read", "Mind 7 auto-reads")
	var changed: Dictionary = assert_event(resolved, "antagonism_changed", "the read builds grudge anyway")
	assert_eq(String(changed.get("source", "")), "mockery", "source tagged mockery")
	assert_eq(float(changed.get("delta", 0.0)), 5.0, "authored mock_grudge honored on the read")
	assert_eq(float(proud.antagonism.get("trick", 0.0)), 5.0, "the insult landed on the ledger")


func test_contestants_read_too_but_keep_no_ledger() -> void:
	# The gate is stats, never category: a Mind-7 CONTESTANT auto-reads a feint
	# (nothing arms on them), but only AI combatants keep an antagonism ledger
	# (add_antagonism's own gate — R23, unchanged).
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_human(sim, "prof", {"team": "blue", "position": [0, 1],
		"traits": {"physique": 3, "reflexes": 3, "mind": 7, "charm": 3}})
	var state_before: int = sim.ai.ai_rng.state
	var resolved: Array[Dictionary] = feint(sim, "trick", "prof")
	assert_event(resolved, "feint_read", "the contestant reads by the same ladder")
	assert_eq(sim.ai.ai_rng.state, state_before, "auto-read: no rng")
	assert_false((sim.combatants["prof"] as CombatantState).feint_forced, "nothing armed")
	assert_no_event(resolved, "antagonism_changed", "contestants keep no grudge ledger")
	assert_true((sim.combatants["prof"] as CombatantState).antagonism.is_empty(), "ledger empty")


func test_landed_feint_on_mock_sensitive_target_unchanged() -> void:
	# The pre-R24 grudge path holds verbatim when no read happens: a Mind-0
	# authored-sensitive mob (read impossible by construction) takes the landed
	# insult exactly as before.
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_reader(sim, "mob", 0, {"personality": {"mock_sensitive": true}})
	var state_before: int = sim.ai.ai_rng.state
	var resolved: Array[Dictionary] = feint(sim, "trick", "mob")
	assert_event(resolved, "feint_applied", "the feint lands")
	var changed: Dictionary = assert_event(resolved, "antagonism_changed", "landed mockery still builds grudge")
	assert_eq(String(changed.get("source", "")), "mockery", "source mockery")
	assert_eq(float(changed.get("delta", 0.0)), 2.0, "default mock_grudge 2.0 — unchanged")
	assert_true((sim.combatants["mob"] as CombatantState).feint_forced, "and the feint armed")
	assert_eq(sim.ai.ai_rng.state, state_before, "no rng on the impossible read")


# ---------------------------------------------------------------- die upgrade + serialization

func test_mind_die_upgrade_granted_and_used() -> void:
	# Grant a d6 Mind threshold die via the add_combatant spec (the R22 grant
	# pattern). L4 threshold 8 vs Mind 3: impossible on the default d4 (max 7),
	# possible on the granted d6 (needs a 5+). Every feint rolls the d6 —
	# twin-proven size and value.
	var sim: CombatSim = make_sim()
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_reader(sim, "sharp", 3, {"threshold_dice": {"mind": 6}})
	var sharp: CombatantState = sim.combatants["sharp"]
	assert_eq(sharp.threshold_die("mind"), 6, "the granted d6 is on the combatant")
	assert_eq(sharp.threshold_die("reflexes"), 4, "ungranted stats keep the default d4")
	var reads_seen: bool = false
	var lands_seen: bool = false
	for i: int in range(8):
		var pre: int = sim.ai.ai_rng.state
		var resolved: Array[Dictionary] = feint(sim, "trick", "sharp", 4)
		var twin := RandomNumberGenerator.new()
		twin.state = pre
		var expected_roll: int = twin.randi_range(1, 6)
		assert_eq(sim.ai.ai_rng.state, twin.state, "round %d: the d6 ask rolls exactly once" % i)
		if 3 + expected_roll >= 8:
			var read: Dictionary = assert_event(resolved, "feint_read", "round %d: 3 + %d >= 8 reads" % [i, expected_roll])
			assert_eq(int(read.get("die", 0)), 6, "the emitted die size is the granted d6")
			assert_eq(int(read.get("roll", -1)), expected_roll, "the roll IS the stream's next d6")
			reads_seen = true
		else:
			assert_event(resolved, "feint_applied", "round %d: below the ask — the feint lands" % i)
			lands_seen = true
	assert_true(reads_seen, "seed 1234's d6 stream actually read at least once")
	assert_true(lands_seen, "seed 1234's d6 stream actually landed at least once")


func test_serialization_roundtrip_mid_fight_after_a_read() -> void:
	# A ROLLED read in the log (the salted stream is mid-consumed), then
	# save/restore: identical hash, and lockstep tails replay identically.
	var sim: CombatSim = make_sim(4242)
	add_human(sim, "trick", {"team": "party", "position": [1, 0]})
	add_reader(sim, "elite", 4)
	var read_seen: bool = false
	for i: int in range(6):
		if has_event(feint(sim, "trick", "elite"), "feint_read"):
			read_seen = true
			break
	assert_true(read_seen, "a rolled read actually happened mid-fight (seed 4242)")
	var restored: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical after the read")
	for i: int in range(4):
		feint(sim, "trick", "elite")
		feint(restored, "trick", "elite")
	assert_eq(restored.state_hash(), sim.state_hash(), "lockstep tails end on the same hash")
