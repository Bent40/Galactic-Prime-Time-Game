extends SimTestBase
## The Bit is AUTHORED, per-character content (decision log #25, owner
## 2026-07-22): a bit is a specific thing a character canonically does — not a
## generic button — and NOT everyone has one. The character spec carries
## `bit {key, name, line}`; the sim REJECTS the_bit from an actor with no
## authored bit; bit_performed names WHICH bit; view_combatants exposes the bit
## so the UI offers it only to characters who have one. Mechanically The Bit
## stays NULL (decision #15's byte-identical combat guarantee — see
## test_tag_engine's nullity fingerprints, which still hold).

## Dario's canonical authored bit, verbatim from data/demo_loadouts.json.
const DARIO_BIT: Dictionary = {
	"key": "the_bow", "name": "The Bow",
	"line": "Dario bows mid-combat — the applause is the point.",
}


# ---------------------------------------------------------------- (a) no bit -> rejected

func test_bitless_actor_is_rejected_no_bit() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "imani", {"team": "party"})  # canonical: Imani has NO bit
	add_human(sim, "m", {"team": "enemies", "position": [1, 0]})
	var before: String = sim.state_hash()
	var events: Array[Dictionary] = sim.apply_command({"type": "bit", "actor": "imani"})
	assert_rejected(events, "no_bit", "an actor with no authored bit cannot perform the_bit")
	assert_no_event(events, "bit_performed", "no bit_performed rides the rejection")
	assert_eq(sim.state_hash(), before, "the rejection mutates NOTHING (full state hash identical)")
	assert_eq(sim.hype.meter, 0, "no spectacle was scored")
	assert_false(sim.tags.progress.has("imani"), "no the_bit tag progress accrued")


func test_no_bit_gate_sits_after_the_actor_gates() -> void:
	# Rejection vocabulary ordering: unknown_actor / not_a_contestant /
	# actor_dead still fire first — no_bit is the LAST gate, so a dead bitless
	# actor still reads actor_dead (the pre-#25 vocabulary is unchanged).
	var sim: CombatSim = make_sim()
	add_human(sim, "a", {"team": "party"})
	assert_rejected(sim.apply_command({"type": "bit", "actor": "zz"}), "unknown_actor", "unknown actor first")
	sim.combatants["a"].alive = false
	assert_rejected(sim.apply_command({"type": "bit", "actor": "a"}), "actor_dead",
		"a dead bitless actor rejects actor_dead, not no_bit")


# ---------------------------------------------------------------- (b) authored bit performs

func test_authored_bit_performs_and_names_the_bit() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "dario", {"team": "party", "bit": DARIO_BIT})
	var events: Array[Dictionary] = sim.apply_command({"type": "bit", "actor": "dario", "key": "encore_bow"})
	var bit: Dictionary = assert_event(events, "bit_performed", "an authored bit performs")
	assert_eq(String(bit.get("bit", "")), "the_bow", "the event names WHICH authored bit (bit = key)")
	assert_eq(String(bit.get("bit_name", "")), "The Bow", "and its display name")
	# Compatibility: the pre-#25 fields are still there, verbatim.
	assert_eq(String(bit.get("key", "")), "encore_bow", "the command's key echo is unchanged")
	assert_true(int(bit.get("spectacle_points", 0)) > 0, "spectacle_points still pays out")
	assert_eq(int((sim.tags.progress.get("dario", {}) as Dictionary).get("the_bit", 0)), 1,
		"the performance still counts toward The Bit tag")


func test_bit_stays_mechanically_null_with_authored_bit() -> void:
	# Decision #15 guarantee restated under #25: granting the bit is static spec
	# data; PERFORMING it still touches nothing outside the broadcast plane.
	var plain: CombatSim = make_sim(909)
	var bitten: CombatSim = make_sim(909)
	for sim: CombatSim in [plain, bitten]:
		add_human(sim, "dario", {"team": "party", "bit": DARIO_BIT})
		add_human(sim, "m", {"team": "enemies", "position": [1, 0]})
		declare(sim, "dario", attack_action("crushed", 2, "m", "torso"))
		advance(sim, 1)
	bitten.apply_command({"type": "bit", "actor": "dario"})
	for sim: CombatSim in [plain, bitten]:
		advance(sim, 2)
	var strip := func(sim: CombatSim) -> String:
		var d: Dictionary = sim.to_dict()
		d.erase("hype")
		d.erase("tags")
		d.erase("evidence")
		return CombatSim.canonical_serialize(d)
	assert_eq(strip.call(bitten), strip.call(plain),
		"performing an authored bit leaves combat state bit-for-bit identical")
	assert_true(bitten.hype.meter > plain.hype.meter, "only the broadcast plane diverged")


# ---------------------------------------------------------------- (c) serialization

func test_bit_survives_serialization_roundtrip() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "dario", {"team": "party", "bit": DARIO_BIT})
	add_human(sim, "imani", {"team": "party", "position": [1, 0]})
	# Combatant-level round-trip.
	var d: Dictionary = sim.combatants["dario"].to_dict()
	assert_eq(d.get("bit", {}), DARIO_BIT, "to_dict carries the authored bit verbatim")
	var restored: CombatantState = CombatantState.from_dict(d)
	assert_eq(restored.bit, DARIO_BIT, "from_dict restores it")
	assert_eq((sim.combatants["imani"].to_dict() as Dictionary).get("bit", {"missing": true}), {},
		"a bitless combatant serializes bit = {}")
	# Full-sim round-trip: the resumed run still performs (and still refuses).
	var resumed: CombatSim = CombatSim.from_dict(sim.to_dict())
	assert_eq(resumed.state_hash(), sim.state_hash(), "hash identical after round-trip")
	var ev: Array[Dictionary] = resumed.apply_command({"type": "bit", "actor": "dario"})
	assert_eq(String(assert_event(ev, "bit_performed", "resumed Dario still performs").get("bit", "")),
		"the_bow", "the restored bit is the same authored bit")
	assert_rejected(resumed.apply_command({"type": "bit", "actor": "imani"}), "no_bit",
		"the restored bitless actor is still refused")


# ---------------------------------------------------------------- (d) view API

func test_view_combatants_exposes_the_bit() -> void:
	var game: Node = (load("res://controller/game_controller.gd") as GDScript).new()
	game.start_combat(7, load_static_data())
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "dario", "name": "Dario", "race": "human", "team": "party",
		"position": [0, 1], "traits": {"physique": 2, "reflexes": 5, "mind": 2, "charm": 5},
		"bit": DARIO_BIT}})
	game.apply_command({"type": "add_combatant", "combatant": {
		"id": "imani", "name": "Imani", "race": "human", "team": "party",
		"position": [1, 0], "traits": {"physique": 5, "reflexes": 2, "mind": 4, "charm": 3}}})
	var dario: Dictionary = {}
	var imani: Dictionary = {}
	for cv: Dictionary in game.view_combatants():
		match String(cv.get("id", "")):
			"dario": dario = cv
			"imani": imani = cv
	assert_eq(dario.get("bit", {}), DARIO_BIT,
		"view_combatants exposes the authored bit dict verbatim")
	assert_true(imani.has("bit"), "the bit field is always present in the view")
	assert_eq(imani.get("bit", {"missing": true}), {},
		"a character with no bit reads bit = {} — the UI offers The Bit to nobody it shouldn't")
	game.free()
