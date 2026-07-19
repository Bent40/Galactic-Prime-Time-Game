extends SimTestBase
## Condition-death routing (F2 rework, owner ruling 2026-07-19). Death must only
## ever come through a LETHAL part: crushing/burning a limb caps at destroyed, a
## systemic bleed-out drains the body until a lethal part empties, and the boss's
## mycelium network is bleed-immune (a separate organism with no blood). Together
## these close the breach-bypass the slice playtest surfaced (docs/playtests/
## slice-playtest-2026-07-19.md) — a boss can no longer be killed on cosmetic parts.


func add_boss(sim: CombatSim, id: String = "boss") -> void:
	sim.apply_command({"type": "add_combatant", "combatant": {
		"id": id, "name": id, "enemy": "incinedile", "team": "enemies", "position": [0, 0],
	}})


func died_within_clocks(sim: CombatSim, id: String, clocks: int) -> bool:
	for i: int in range(clocks):
		var ev: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
		for e: Dictionary in ev:
			if String(e.get("type", "")) == "combatant_died" and String(e.get("combatant", "")) == id:
				return true
	return false


# ---------------------------------------------------------------- crushed / burn lethal-gate

func test_crushed_limb_caps_at_destroyed_never_kills() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "left_leg", "condition": "crushed", "tier": 1})
	assert_false(died_within_clocks(sim, "h", 6), "crushing a non-lethal limb never kills (R4: death is torso/head-only)")
	assert_true(sim.combatants["h"].alive, "the contestant survives a fully-crushed leg")
	assert_true(bool(sim.combatants["h"].parts["left_leg"].get("destroyed", false)), "the limb is destroyed — permanent loss, not death")


func test_burn_limb_caps_never_kills() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "left_leg", "condition": "burn", "tier": 1})
	assert_false(died_within_clocks(sim, "h", 6), "burning a non-lethal limb never kills (F2 fix — same gate as crushed)")
	assert_true(sim.combatants["h"].alive, "the contestant survives a burned-off leg")


func test_crushed_torso_still_kills() -> void:
	# The gate protects limbs, NOT vital parts — a crushed torso is still lethal.
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "torso", "condition": "crushed", "tier": 1})
	assert_true(died_within_clocks(sim, "h", 6), "crushing a lethal part (torso) still kills")


# ---------------------------------------------------------------- systemic bleed-out drain

func test_systemic_bleed_out_drains_body_and_kills_via_lethal_part() -> void:
	# A bled-out limb drains HP off the whole body each Clock; death arrives when
	# the drain empties a LETHAL part (not from the limb itself).
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "left_arm", "condition": "bleeding", "tier": 1})
	var saw_drain := false
	var died := false
	for i: int in range(12):
		var ev: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
		for e: Dictionary in ev:
			if String(e.get("type", "")) == "bleed_out_draining":
				saw_drain = true
			if String(e.get("type", "")) == "combatant_died":
				died = true
		if died:
			break
	assert_true(saw_drain, "the systemic bleed-out drain actually ran")
	assert_true(died, "the drain empties a lethal part -> death")
	assert_false(sim.combatants["h"].alive, "the contestant bled out")


func test_bleed_out_drain_scales_with_tier() -> void:
	# The drain amount reported each Clock is hp_per_tier * worst bleed tier.
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	var cfg: Dictionary = sim.cond.def_for("bleeding").get("bleed_out_drain", {})
	var per_tier: int = int(cfg.get("hp_per_tier", 0))
	var from_tier: int = int(cfg.get("from_tier", 3))
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "left_arm", "condition": "bleeding", "tier": 1})
	var first_drain: int = -1
	for i: int in range(6):
		var ev: Array[Dictionary] = advance(sim, Clock.TICKS_PER_CLOCK)
		for e: Dictionary in ev:
			if String(e.get("type", "")) == "bleed_out_draining" and first_drain < 0:
				first_drain = int(e.get("amount", 0))
				assert_eq(int(e.get("tier", 0)), from_tier, "the drain kicks in at the from_tier")
		if first_drain >= 0:
			break
	assert_eq(first_drain, per_tier * from_tier, "drain scales as hp_per_tier * bleed tier")


# ---------------------------------------------------------------- boss: only the network is lethal

func test_bleeding_cosmetic_limb_cannot_kill_the_boss() -> void:
	var sim: CombatSim = make_sim()
	add_boss(sim)
	# Bleed a cosmetic leg out and let the systemic drain run for many Clocks.
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "left_leg", "condition": "bleeding", "tier": 1})
	assert_false(died_within_clocks(sim, "boss", 15),
		"cosmetic bleed-out can NEVER kill the boss — only the network is lethal, and it is bleed-immune")
	assert_true(sim.combatants["boss"].alive, "the puppet still stands")
	assert_eq(int(sim.combatants["boss"].parts["network"]["hp"]), 50, "the network is never bled or drained (mycelium doesn't bleed)")


func test_bleeding_still_breaches_the_boss() -> void:
	# The fix must NOT close the bleed->T2 breach door — bleeding a cosmetic part
	# still opens the breach; it just can't finish the boss on its own.
	var sim: CombatSim = make_sim()
	add_boss(sim)
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "left_leg", "condition": "bleeding", "tier": 1})
	var breached := false
	for i: int in range(4):
		for e: Dictionary in advance(sim, Clock.TICKS_PER_CLOCK):
			if String(e.get("type", "")) == "breach_opened":
				breached = true
		if breached:
			break
	assert_true(breached, "bleeding to T2 still opens the breach (the door still works)")
	assert_true(sim.combatants["boss"].breached, "breached flag set")


func test_network_is_bleed_immune() -> void:
	var sim: CombatSim = make_sim()
	add_boss(sim)
	# Breach via the deterministic bleeding->T2 door so the network is exposed
	# (avoids the boss dodge d6 that a burst hit would roll against).
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "right_hand", "condition": "bleeding", "tier": 1})
	for i: int in range(4):
		advance(sim, Clock.TICKS_PER_CLOCK)
		if sim.combatants["boss"].breached:
			break
	assert_true(sim.combatants["boss"].breached, "precondition: breached")
	# Now try to bleed the exposed network — it has no blood.
	var ev: Array[Dictionary] = sim.apply_command({"type": "apply_condition", "target": "boss", "part": "network", "condition": "bleeding", "tier": 1})
	var resisted: Dictionary = {}
	for e: Dictionary in ev:
		if String(e.get("type", "")) == "condition_resisted":
			resisted = e
	assert_false(resisted.is_empty(), "bleeding is resisted on the mycelium network")
	assert_eq(String(resisted.get("reason", "")), "bleed_immune", "resisted specifically for bleed immunity")
	assert_false((sim.combatants["boss"].conditions.get("network", {}) as Dictionary).has("bleeding"), "no bleeding instance on the network")


func test_crushing_the_boss_head_cannot_kill_it() -> void:
	# lethal_if_head (crushed T2) must respect the part's lethal flag — the boss's
	# puppet head is lethal:false, so crushing it is cosmetic. Only the network kills.
	var sim: CombatSim = make_sim()
	add_boss(sim)
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "head", "condition": "crushed", "tier": 1})
	assert_false(died_within_clocks(sim, "boss", 6), "crushing the non-lethal puppet head never kills the boss")
	assert_true(sim.combatants["boss"].alive, "only the network is lethal")


# ---------------------------------------------------------------- timer/terminal death paths (F2 audit)

func test_suffocation_cannot_defeat_the_boss() -> void:
	# Suffocation targets torso; the boss has none, so it remaps onto the hidden
	# network — where the surface-immunity source gate resists it.
	var sim: CombatSim = make_sim()
	add_boss(sim)
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "torso", "condition": "suffocation"})
	assert_false(died_within_clocks(sim, "boss", 8), "suffocation cannot kill the un-breached boss")
	assert_true(sim.combatants["boss"].alive and not sim.combatants["boss"].removed_from_play, "boss stands, not removed")
	assert_false(sim.combatants["boss"].breached, "and it never breached")


func test_dissolution_cannot_defeat_the_boss() -> void:
	# Dissolution lands on the cosmetic (lethal:false) puppet head; the terminal
	# gate refuses to mind-collapse a non-lethal part.
	var sim: CombatSim = make_sim()
	add_boss(sim)
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "head", "condition": "dissolution"})
	died_within_clocks(sim, "boss", 10)  # run the timer out
	assert_true(sim.combatants["boss"].alive, "boss still alive")
	assert_false(sim.combatants["boss"].removed_from_play, "dissolution can't mind-collapse the puppet off its cosmetic head")


func test_poison_t3_cannot_kill_boss_on_a_cosmetic_part() -> void:
	var sim: CombatSim = make_sim()
	add_boss(sim)
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "left_leg", "condition": "poison", "tier": 3, "poison_type": "cytotoxin"})
	assert_false(died_within_clocks(sim, "boss", 8), "poison on a cosmetic leg can't kill the boss (death timer gated to lethal parts)")
	assert_true(sim.combatants["boss"].alive, "boss survives")


func test_infected_t3_cannot_kill_boss_on_a_cosmetic_part() -> void:
	var sim: CombatSim = make_sim()
	add_boss(sim)
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "left_leg", "condition": "infected", "tier": 3})
	assert_false(died_within_clocks(sim, "boss", 8), "infected on a cosmetic leg can't kill the boss")
	assert_true(sim.combatants["boss"].alive, "boss survives")


# Positive controls — the gates protect cosmetic/hidden parts, NOT vital ones.

func test_suffocation_still_kills_a_human() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "torso", "condition": "suffocation"})
	assert_true(died_within_clocks(sim, "h", 8), "suffocating a human (torso is lethal + exposed) still kills")


func test_dissolution_still_removes_a_human() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h")
	sim.apply_command({"type": "apply_condition", "target": "h", "part": "head", "condition": "dissolution"})
	var out := false
	for i: int in range(10):
		advance(sim, Clock.TICKS_PER_CLOCK)
		if sim.combatants["h"].removed_from_play:
			out = true
			break
	assert_true(out, "dissolving a human's head (lethal + exposed) still mind-collapses them")


# ---------------------------------------------------------------- direct-damage sink (forced collateral)

func test_hidden_network_takes_no_damage_from_any_source() -> void:
	# damage_part (the central HP sink) blocks damage to a part hidden behind an
	# un-breached surface immunity — forced collateral / environment can't chip or
	# destroy the undiscovered network pre-breach.
	var sim: CombatSim = make_sim()
	add_boss(sim)
	var ev: Array[Dictionary] = sim.cond.damage_part(sim.combatants["boss"], "network", 50, "forced", "", 0)
	var blocked := false
	for e: Dictionary in ev:
		if String(e.get("type", "")) == "damage_blocked":
			blocked = true
	assert_true(blocked, "damage to the hidden network is blocked by surface immunity")
	assert_true(sim.combatants["boss"].alive, "the boss does not die to raw damage on its undiscovered core")
	assert_eq(int(sim.combatants["boss"].parts["network"]["hp"]), 50, "the network takes no HP damage while hidden")
	assert_false(sim.combatants["boss"].breached, "and it never breached")


func test_forced_collateral_default_part_skips_the_hidden_network() -> void:
	var sim: CombatSim = make_sim()
	add_boss(sim)
	var pk: String = ForcedAction.default_part(sim.combatants["boss"])
	assert_true(pk != "network", "collateral default part skips the hidden network (got '%s')" % pk)
	assert_false(bool(sim.combatants["boss"].parts.get(pk, {}).get("hidden", false)), "and skips any hidden part")


func test_exposed_network_takes_damage_after_breach() -> void:
	# Positive control: the sink gate only blocks HIDDEN parts — after the breach the
	# exposed network takes damage normally (the intended win path).
	var sim: CombatSim = make_sim()
	add_boss(sim)
	sim.apply_command({"type": "apply_condition", "target": "boss", "part": "right_hand", "condition": "bleeding", "tier": 1})
	for i: int in range(4):
		advance(sim, Clock.TICKS_PER_CLOCK)
		if sim.combatants["boss"].breached:
			break
	assert_true(sim.combatants["boss"].breached, "precondition: breached")
	sim.cond.damage_part(sim.combatants["boss"], "network", 10, "weapon", "", sim.clock.tick)
	assert_eq(int(sim.combatants["boss"].parts["network"]["hp"]), 40, "the exposed network takes damage post-breach")
