extends SimTestBase
## R14 (rules-addendum R14, decision-log #22): the force-vs-robustness damage gate.
##
##   damage     = max(0, Force − Robustness)
##   Force      = weapon/skill force + floor(attacker physique / 2)
##   Robustness = floor(target physique / 2) + per-part armor
##                + flat physical resistance
##
## A hit LANDS (opens a real wound) only when Force > Robustness. These tests pin:
## the identity with the old model (equal physique + no armor → amount − flat
## resistance), the physique gradient, armor/physique robustness reduction and
## zeroing, the blocked-hit "no wound → no bleed" rule (D3), and determinism across
## a save/resume (including that per-part armor round-trips).


## An inert Contestant target (never AI-driven, never acts): one big torso so it
## survives every probe except the explicit blocked-hit HP check. `armor` < 0
## leaves the field absent (default-0 path); `resistance` sets flat Physical
## resistance.
func add_target(sim: CombatSim, id: String, phys: int, armor: int = -1, resistance: int = 0) -> void:
	var part: Dictionary = {"key": "torso", "name": "Torso", "hp": 100, "lethal": true}
	if armor >= 0:
		part["armor"] = armor
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "team": "targets", "category": "Contestant",
		"position": [0, 0],
		"traits": {"physique": phys, "reflexes": 3, "mind": 3, "charm": 3},
		"resistances": {"Physical": resistance},
		"body_parts": [part],
	}})


func add_attacker(sim: CombatSim, id: String, phys: int) -> void:
	add_human(sim, id, {"team": "party", "position": [1, 0],
		"traits": {"physique": phys, "reflexes": 3, "mind": 3, "charm": 3}})


## Fires one `amount`-force `condition` strike from `atk_id` onto `tgt_id`'s torso
## and returns that tick's events.
func strike(sim: CombatSim, atk_id: String, tgt_id: String, condition: String, amount: int) -> Array[Dictionary]:
	declare(sim, atk_id, attack_action(condition, amount, tgt_id, "torso"))
	return advance(sim, 1)


func net_damage(events: Array[Dictionary]) -> int:
	return int(first_event(events, "damage_applied").get("amount", -999))


# ---------------------------------------------------------------- identity

func test_equal_physique_no_armor_reproduces_amount_minus_resistance() -> void:
	# No resistance: Force = 4 + floor(3/2) = 5, Robustness = floor(3/2) = 1,
	# net = 5 − 1 = 4 = amount.
	var a: CombatSim = make_sim()
	add_attacker(a, "atk", 3)
	add_target(a, "tgt", 3)
	assert_eq(net_damage(strike(a, "atk", "tgt", "bleeding", 4)), 4,
		"equal physique, no armor, no resistance -> net = amount")
	# Flat Physical resistance 2: Robustness = 1 + 2 = 3, net = 5 − 3 = 2 =
	# amount − resistance — exactly the pre-R14 reduce_damage model.
	var b: CombatSim = make_sim()
	add_attacker(b, "atk", 3)
	add_target(b, "tgt", 3, -1, 2)
	assert_eq(net_damage(strike(b, "atk", "tgt", "bleeding", 4)), 2,
		"equal physique -> net = amount − flat resistance (identity with old model)")


# ---------------------------------------------------------------- physique gradient

func test_stronger_attacker_deals_more() -> void:
	var weak: CombatSim = make_sim()
	add_attacker(weak, "atk", 3)
	add_target(weak, "tgt", 3)
	var base: int = net_damage(strike(weak, "atk", "tgt", "bleeding", 4))
	var strong: CombatSim = make_sim()
	add_attacker(strong, "atk", 9)
	add_target(strong, "tgt", 3)
	var boosted: int = net_damage(strike(strong, "atk", "tgt", "bleeding", 4))
	# Force = 4 + floor(9/2) = 8, Robustness = 1, net = 7 > baseline 4.
	assert_eq(base, 4, "phys-3 vs phys-3 baseline net")
	assert_eq(boosted, 7, "phys-9 attacker: Force 8 − Robustness 1 = 7")
	assert_true(boosted > base, "a stronger attacker deals more")


# ---------------------------------------------------------------- robustness

func test_robust_target_reduces_or_zeroes() -> void:
	# Higher physique reduces: attacker phys 3 (Force 5), target phys 9
	# (Robustness floor(9/2) = 4), net = 1.
	var tough: CombatSim = make_sim()
	add_attacker(tough, "atk", 3)
	add_target(tough, "tgt", 9)
	assert_eq(net_damage(strike(tough, "atk", "tgt", "bleeding", 4)), 1,
		"a higher-physique target reduces the hit (net 1)")
	# Per-part armor reduces: target phys 3 + armor 3 -> Robustness 1 + 3 = 4,
	# Force 5, net = 1.
	var armored: CombatSim = make_sim()
	add_attacker(armored, "atk", 3)
	add_target(armored, "tgt", 3, 3)
	assert_eq(net_damage(strike(armored, "atk", "tgt", "bleeding", 4)), 1,
		"per-part armor 3 reduces the hit (net 1)")
	# Armor zeroes: target phys 3 + armor 10 -> Robustness 11, Force 5 <= 11.
	var wall: CombatSim = make_sim()
	add_attacker(wall, "atk", 3)
	add_target(wall, "tgt", 3, 10)
	var blocked: Array[Dictionary] = strike(wall, "atk", "tgt", "bleeding", 4)
	assert_eq(net_damage(blocked), 0, "armor 10 zeroes the hit")
	assert_event(blocked, "attack_no_wound", "a robustness-blocked hit is surfaced")


# ---------------------------------------------------------------- blocked-hit gate (D3)

func test_blocked_hit_deals_zero_hp_and_seeds_no_bleed() -> void:
	# Force 1 (phys-1 attacker, amount 1) <= Robustness 1 (phys-3 target): blocked.
	var block: CombatSim = make_sim()
	add_attacker(block, "atk", 1)
	add_target(block, "tgt", 3)
	var ev: Array[Dictionary] = strike(block, "atk", "tgt", "bleeding", 1)
	assert_eq(net_damage(ev), 0, "a blocked hit deals 0 HP")
	assert_event(ev, "attack_no_wound", "the block is surfaced for transparency")
	assert_no_event(ev, "condition_applied", "no wound -> bleeding does not seed (D3)")
	var blocked_tgt: CombatantState = block.combatants["tgt"]
	assert_eq(int(blocked_tgt.parts["torso"]["hp"]), 100, "torso HP is untouched")
	assert_true(blocked_tgt.conditions.is_empty(), "no bleeding condition on the target")
	# Contrast: a LANDED equivalent (phys-3 attacker, Force 2 > Robustness 1) DOES
	# seed bleeding — the gate blocks only the sub-robustness hit, not the mechanic.
	var land: CombatSim = make_sim()
	add_attacker(land, "atk", 3)
	add_target(land, "tgt", 3)
	var ev2: Array[Dictionary] = strike(land, "atk", "tgt", "bleeding", 1)
	assert_eq(net_damage(ev2), 1, "the landed equivalent nets 1")
	assert_event(ev2, "condition_applied", "a real wound seeds bleeding")


# ---------------------------------------------------------------- determinism

func test_determinism_and_armor_roundtrip() -> void:
	var sim: CombatSim = make_sim(7777)
	add_attacker(sim, "atk", 5)
	add_target(sim, "tgt", 4, 2)   # Robustness = floor(4/2) + armor 2 = 4
	# Force = 6 + floor(5/2) = 8, net = 8 − 4 = 4.
	assert_eq(net_damage(strike(sim, "atk", "tgt", "bleeding", 6)), 4,
		"phys-5 vs phys-4 + armor-2: Force 8 − Robustness 4 = 4")
	var snap: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snap)
	assert_eq(restored.state_hash(), sim.state_hash(), "save/resume hash identical mid-fight")
	assert_eq(int((restored.combatants["tgt"] as CombatantState).parts["torso"].get("armor", -1)), 2,
		"per-part armor survives the round-trip")
	# Lockstep: identical follow-up strikes keep the resumed sim bit-identical.
	for i: int in range(3):
		strike(sim, "atk", "tgt", "bleeding", 6)
		strike(restored, "atk", "tgt", "bleeding", 6)
	assert_eq(restored.state_hash(), sim.state_hash(),
		"lockstep strikes keep the resumed sim identical (determinism holds under R14)")
