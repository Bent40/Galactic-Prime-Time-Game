extends SimTestBase
## Incinedile (I-16) — Phase-1 boss policy, the dodge-threshold ability, and
## the breach win-condition wiring through the existing hooks (rules-addendum
## R11 #17/#18). The discoverable-win-condition structure is the point: raw
## damage does nothing until the party breaches, and the phase-2 beat resets
## the breach exactly as the live table ran it.


func add_boss(sim: CombatSim, id: String = "boss", overrides: Dictionary = {}) -> Array[Dictionary]:
	var spec: Dictionary = {
		"id": id, "name": id, "enemy": "incinedile",
		"team": "enemies", "position": [0, 0],
	}
	spec.merge(overrides, true)
	return sim.apply_command({"type": "add_combatant", "combatant": spec})


func ai_decide(sim: CombatSim, id: String) -> Array[Dictionary]:
	return sim.apply_command({"type": "ai_decide", "actor": id})


## The seeded Incinedile trait block minus the dodge threshold — breach/phase
## tests stay pin-exact without consuming the AI d6 stream.
func traits_without_dodge() -> Dictionary:
	var enemies: Array = SimTestBase.load_json("res://data/enemies.json")
	for entry: Variant in enemies:
		var e: Dictionary = entry
		if String(e.get("key", "")) == "incinedile":
			var boss_traits: Dictionary = (e.get("traits", {}) as Dictionary).duplicate(true)
			boss_traits.erase("dodge_threshold")
			boss_traits.erase("dodge_threshold_note")
			return boss_traits
	return {}


func boss_state(sim: CombatSim, id: String = "boss") -> CombatantState:
	return sim.combatants.get(id)


func _fa_rolls(events: Array[Dictionary]) -> Array[int]:
	var rolls: Array[int] = []
	for event: Dictionary in events_of(events, "forced_action_triggered"):
		rolls.append(int(event.get("roll", 0)))
	return rolls


# ---------------------------------------------------------------- P1 policy

func test_boss_dashes_a_lone_target() -> void:
	# R22: the target's Reflexes 2 + d4 max = 6 < the dash's threshold 7 — the
	# dodge is IMPOSSIBLE (the intended Imani texture), so the dash connects
	# deterministically and consumes NO rng (pin-exact damage stays possible).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [3, 0],
		"traits": {"physique": 3, "reflexes": 2, "mind": 3, "charm": 3}})
	add_boss(sim)
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = assert_event(events, "ai_decision", "boss decided")
	assert_eq(String(decision.get("tier", "")), "boss", "boss tier")
	assert_eq(String(decision.get("choice", "")), "attack", "target in reach -> attack")
	assert_eq(String(decision.get("ability", "")), "dash", "one target -> the line charge, not the cone")
	# R22: dash moment_cost 1 -> 2 — the charge is a WINDUP telegraph now:
	# declared this tick, resolving two ticks later through the schedule the
	# HUD's declared-action bars read.
	var declared: Dictionary = assert_event(events, "action_declared", "the dash is declared through the resolver")
	assert_eq(int(declared.get("cost", 0)), 2, "R22: the dash costs 2 Moments (windup telegraph)")
	assert_true(bool(declared.get("windup", false)), "the dash winds up — the party sees it coming")
	assert_no_event(advance(sim, 2), "damage_applied", "nothing lands during the windup")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var damage: Dictionary = assert_event(resolved, "damage_applied", "dash landed")
	assert_eq(String(damage.get("part", "")), "torso", "dash honors its torso part_bias")
	# R14 TUNING (2026-07-20): dash crushed 3->2 (data/enemies.json). Dash Force =
	# 2 + floor(boss physique 6 / 2) = 5; the fresh human's Robustness =
	# floor(physique 3 / 2) = 1 (no armor), so the dash nets 5 − 1 = 4 — the 5-HP
	# torso drops to 1, NOT 0. The from-full-to-0 one-shot the 3-amount dash was is
	# GONE (no-one-shot invariant): a lethal part now survives one dash and takes
	# >=2 hits to destroy. Because the hit LANDED (Force 5 > Robustness 1) it seeds
	# crushed T1 (no longer preempted by a kill).
	assert_eq(int(damage.get("amount", -1)), 4, "R14 tuning dash: Force 5 − Robustness 1 = 4")
	assert_no_event(resolved, "attack_dodged", "Reflexes 2 cannot dodge the dash (R22 impossible)")
	assert_no_event(resolved, "dodge_failed", "an impossible dodge consumes no rng and emits nothing")
	assert_no_event(resolved, "combatant_died", "the tuned dash no longer one-shots a fresh 5-HP torso")
	assert_eq(int((sim.combatants["h"] as CombatantState).parts["torso"]["hp"]), 1, "the 5-HP torso survives the dash at 1 HP")
	assert_event(resolved, "condition_applied", "the landed dash seeds crushed T1 (a survivor, not a corpse)")


func test_boss_flamethrowers_a_crowd_and_is_exposed_during_windup() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [2, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 2]})
	add_boss(sim)
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = first_event(events, "ai_decision")
	assert_eq(String(decision.get("ability", "")), "flamethrower", "two targets in the cone -> sweep")
	var declared: Dictionary = assert_event(events, "action_declared", "declared through the resolver")
	assert_eq(int(declared.get("cost", 0)), 2, "seeded 2-Moment cost")
	assert_true(bool(declared.get("windup", false)), "the sweep is a dodgeable windup (R2)")
	assert_eq(sim.ai_ready_ids(), [], "a winding-up boss is not ready")
	advance(sim, 2)
	# On the resolution tick, before the tick advances: still committed.
	assert_rejected(ai_decide(sim, "boss"), "winding_up", "no re-decision mid-windup")
	var resolved: Array[Dictionary] = advance(sim, 1)
	var hits: Array[Dictionary] = events_of(resolved, "damage_applied")
	assert_eq(hits.size(), 2, "one round per swept target (v1 cone model)")
	var burned: Dictionary = {}
	for hit: Dictionary in hits:
		burned[String(hit.get("combatant", ""))] = int(hit.get("amount", -1))
	# R14 TUNING (2026-07-20): flamethrower burn 2->1 (data/enemies.json). Burn
	# Force = 1 + floor(boss physique 6 / 2) = 4; each human's Robustness =
	# floor(physique 3 / 2) = 1 (no armor), so each nets 4 − 1 = 3 — an AoE chip
	# that no longer near-one-shots a 5-HP torso (2 hits to fell it, and burn stacks).
	assert_eq(burned.get("ha", -1), 3, "R14 tuning burn: Force 4 − Robustness 1 = 3")
	assert_eq(burned.get("hb", -1), 3, "R14 tuning burn: Force 4 − Robustness 1 = 3")


func test_boss_closes_distance_when_nothing_in_reach() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [15, 0]})
	add_boss(sim)
	var events: Array[Dictionary] = ai_decide(sim, "boss")
	var decision: Dictionary = first_event(events, "ai_decision")
	assert_eq(String(decision.get("choice", "")), "move", "out of reach -> close distance")
	var moved: Dictionary = assert_event(events, "moved", "the free move executed")
	assert_eq(moved.get("to", []), [3, 0], "greedy hex steps toward the party")


func test_phase_behavior_list_filters_the_ability_set() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "ha", {"team": "party", "position": [2, 0]})
	add_human(sim, "hb", {"team": "party", "position": [0, 2]})
	add_boss(sim, "boss", {"phases": [
		{"phase_number": 1, "name": "T1", "trigger_condition": "test", "behavior": {"abilities": ["dash"]}},
		{"phase_number": 2, "name": "X1", "trigger_condition": "test", "hp_at_or_below": 35,
			"behavior": {"explosion": {"radius": 5}}},
	]})
	var decision: Dictionary = first_event(ai_decide(sim, "boss"), "ai_decision")
	assert_eq(String(decision.get("ability", "")), "dash",
		"cone not in the phase's behavior list -> filtered out despite two targets")
	assert_eq(String(decision.get("target", "")), "ha", "mob-priority target (distance tie -> id)")


# ---------------------------------------------------------------- dodge (R22)

func test_dodge_threshold_negates_the_round() -> void:
	# R22: threshold 1 <= the boss's Reflexes 4 — an AUTO-dodge (roll 0, no rng).
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 1}})
	declare(sim, "h", attack_action("bleeding", 2, "boss", "right_hand"))
	var resolved: Array[Dictionary] = advance(sim, 1)
	var dodge: Dictionary = assert_event(resolved, "attack_dodged", "Reflexes 4 >= threshold 1 always dodges")
	assert_eq(String(dodge.get("part", "")), "right_hand", "the dodged part is reported")
	assert_true(bool(dodge.get("auto", false)), "Reflexes >= threshold -> auto flag set")
	assert_eq(int(dodge.get("roll", -1)), 0, "an auto-dodge emits roll 0 (no die rolled)")
	assert_eq(int(dodge.get("reflexes", 0)), 4, "the dodger's Reflexes is emitted")
	assert_eq(int(dodge.get("die", 0)), 4, "the default d4 threshold die is emitted")
	assert_no_event(resolved, "damage_applied", "a dodged round deals nothing")
	assert_no_event(resolved, "condition_applied", "a dodged round applies nothing (explicit miss, R2)")
	assert_eq(int(boss_state(sim).parts["right_hand"]["hp"]), 8, "HP untouched")


func test_dodge_rolls_once_per_aimed_round_and_can_fail() -> void:
	# R22 rolled fallback: Reflexes 4 < threshold 6, 4 + d4 covers it — every
	# aimed round rolls the d4 once; 4 + roll >= 6 dodges (2+), a 1 fails.
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 6}})
	var events: Array[Dictionary] = []
	for i: int in range(12):
		# Poison without an entry wound: 0 damage, no condition — the dodge
		# roll itself is the observable (keeps 12 ticks free of tier noise).
		declare(sim, "h", attack_action("poison", 0, "boss", "right_hand"))
		events.append_array(advance(sim, 1))
	var dodged: int = events_of(events, "attack_dodged").size()
	var failed: int = events_of(events, "dodge_failed").size()
	assert_eq(dodged + failed, 12, "exactly one dodge roll per aimed round")
	assert_true(dodged >= 1, "Reflexes 4 + d4 vs 6 dodges on a 2+ (got %d)" % dodged)
	assert_true(failed >= 1, "a rolled 1 still fails the ask (got %d)" % failed)
	assert_eq(events_of(events, "damage_applied").size(), failed,
		"every non-dodged round resolved; every dodged round did not")


func test_no_dodge_while_exposed() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 1}})
	sim.apply_command({"type": "set_status", "target": "boss", "status": "prone", "value": true})
	declare(sim, "h", attack_action("bleeding", 2, "boss", "right_hand"))
	var resolved: Array[Dictionary] = advance(sim, 1)
	assert_no_event(resolved, "attack_dodged", "an Exposed boss cannot dodge (punish window)")
	assert_no_event(resolved, "dodge_failed", "no roll is even attempted — the stream is untouched")
	assert_event(resolved, "damage_applied", "the hit lands")


func test_burn_feeds_fire_heals_instead_of_being_dodged() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 1, "fire_heals": true}})
	declare(sim, "h", attack_action("burn", 2, "boss", "right_hand"))
	var resolved: Array[Dictionary] = advance(sim, 1)
	var healed: Dictionary = assert_event(resolved, "healed", "fire is food")
	assert_eq(String(healed.get("source", "")), "fire_heals", "the boss hook fired")
	assert_no_event(resolved, "attack_dodged", "the boss never dodges its meal")
	assert_no_event(resolved, "dodge_failed", "no roll consumed")


func test_dodge_stream_never_perturbs_forced_action_rolls() -> void:
	# Same seed, same commands; the only difference is the dodge trait. The
	# action RNG's Forced-Action roll sequence must be identical — the dodge
	# d6 lives on the salted AI stream (mutation probe target, R11 #15/#17).
	var rolls_with: Array[int] = []
	var rolls_without: Array[int] = []
	var dodge_attempts: int = 0
	for variant: int in range(2):
		var sim: CombatSim = make_sim(4242)
		add_human(sim, "h", {"team": "party", "position": [1, 0]})
		var boss_traits: Dictionary = {"dodge_threshold": 6} if variant == 0 else {}
		add_boss(sim, "boss", {"boss_traits": boss_traits})
		var events: Array[Dictionary] = []
		for i: int in range(8):
			# Unmet requirements: every resolution rolls the Tool d6 (action RNG).
			declare(sim, "h", attack_action("poison", 0, "boss", "right_hand", {"requirements": {"physique": 99}}))
			events.append_array(advance(sim, 1))
		if variant == 0:
			rolls_with = _fa_rolls(events)
			dodge_attempts = events_of(events, "attack_dodged").size() + events_of(events, "dodge_failed").size()
		else:
			rolls_without = _fa_rolls(events)
	assert_true(rolls_with.size() >= 4, "the script actually rolled Forced Actions (%d)" % rolls_with.size())
	assert_true(dodge_attempts >= 1, "the dodge variant actually consumed the AI stream (%d)" % dodge_attempts)
	assert_eq(rolls_with, rolls_without, "Forced-Action rolls identical with and without dodging")


# ---------------------------------------------------------------- breach + phases (R11 #18)

func test_burst_breach_then_phase_two_resets_it() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	# The network is hidden: aiming at it is rejected pre-breach.
	assert_rejected(declare(sim, "h", attack_action("bleeding", 15, "boss", "network")),
		"part_hidden", "no damage race — the win condition must be discovered")
	# Breach path B: 7+ NET damage in a single hit (canon, owner 2026-07-14).
	# R14: the boss's Robustness = floor(physique 6 / 2) = 3, so to land the same
	# net 8 the party used pre-R14, the raw force is bumped 8 → 10:
	# Force = 10 + floor(3/2) = 11, net = 11 − 3 = 8 ≥ 7 → breach.
	declare(sim, "h", attack_action("bleeding", 10, "boss", "right_hand"))
	var breach_events: Array[Dictionary] = advance(sim, 1)
	assert_event(breach_events, "breach_opened", "a 7+ net single hit punches through")
	assert_true(boss_state(sim).breached, "breached flag set")
	assert_false(bool(boss_state(sim).parts["network"]["hidden"]), "the network is exposed")
	# Hit the network down to the phase-2 threshold (50 -> 35). R14: net 15 needs
	# raw 17 (Force = 17 + 1 = 18, net = 18 − 3 = 15); the network is bleed_immune
	# so only the HP lands.
	declare(sim, "h", attack_action("bleeding", 17, "boss", "network"))
	var phase_events: Array[Dictionary] = advance(sim, 1)
	var changed: Dictionary = assert_event(phase_events, "boss_phase_changed", "network at 35 fires the beat")
	assert_eq(int(changed.get("from_phase", 0)), 1, "left phase 1")
	assert_eq(int(changed.get("to_phase", 0)), 2, "entered the first pressure valve")
	assert_eq(String(changed.get("name", "")), "Explosion 1 (Pressure Valve I)", "seeded phase name")
	# Decision #27: entering the valve no longer retreats — the explosion beat
	# (telegraph -> escape window -> blast) plays first; the retreat rides the blast.
	assert_no_event(phase_events, "breach_reset", "no retreat at phase entry (#27)")
	assert_true(boss_state(sim).breached, "the breach stays open through the beat")
	assert_false(bool(boss_state(sim).parts["network"]["hidden"]), "the network stays exposed until the blast")
	# Play the beat out; the contestant takes the intended counterplay and runs.
	assert_event(ai_decide(sim, "boss"), "explosion_telegraph", "the boss vents steam")
	sim.apply_command({"type": "move", "actor": "h", "to": [4, 0]})
	advance(sim, 1)
	ai_decide(sim, "boss")
	sim.apply_command({"type": "move", "actor": "h", "to": [7, 0]})
	advance(sim, 1)
	ai_decide(sim, "boss")
	advance(sim, 1)
	var blast_events: Array[Dictionary] = ai_decide(sim, "boss")
	assert_event(blast_events, "explosion_blast", "the valve erupts after the escape window")
	assert_event(blast_events, "breach_reset", "the network retreats deeper — breach resets (canon)")
	assert_false(boss_state(sim).breached, "breach closed again")
	assert_true(bool(boss_state(sim).parts["network"]["hidden"]), "the network re-hid")
	# Wounds PERSIST across the valve (owner-ruled 2026-07-18): the bleeding the
	# boss took is still on it after the retreat — only the breach threshold reset.
	assert_false(boss_state(sim).conditions.is_empty(), "wounds persist across the retreat (owner ruling)")
	# The party must re-discover the way in.
	assert_rejected(declare(sim, "h", attack_action("bleeding", 2, "boss", "network")),
		"part_hidden", "the network is unreachable again")
	advance(sim, 1)
	assert_false(boss_state(sim).breached, "the old wound never re-breaches on later ticks")


func test_bleeding_tier_two_breach_path() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	# R14: each bleed must LAND (Force > Robustness) to seed the wound. The boss's
	# Robustness = floor(physique 6 / 2) = 3, so bleeding 1 (Force 2) would bounce
	# — bumped 1 → 3: Force = 3 + 1 = 4 > 3 → nets 1 and seeds bleeding T1.
	declare(sim, "h", attack_action("bleeding", 3, "boss", "left_leg"))
	var first: Array[Dictionary] = advance(sim, 1)
	assert_no_event(first, "breach_opened", "T1 is not enough")
	declare(sim, "h", attack_action("bleeding", 3, "boss", "left_leg"))
	var second: Array[Dictionary] = advance(sim, 1)
	assert_event(second, "condition_advanced", "re-application advanced the tier (R4)")
	assert_event(second, "breach_opened", "Bleeding T2 anywhere exposes the network (path A, canon)")


func test_phase_state_serializes_and_resumes() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": traits_without_dodge()})
	# R14: raw force bumped to reproduce the pre-R14 net damage against the boss's
	# Robustness 3 — breach on net 8 (raw 10), then network 50 → 35 on net 15 (raw 17).
	declare(sim, "h", attack_action("bleeding", 10, "boss", "right_hand"))
	advance(sim, 1)
	declare(sim, "h", attack_action("bleeding", 17, "boss", "network"))
	advance(sim, 1)
	assert_eq(sim.ai.current_phase("boss"), 2, "phase advanced in AI state")
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	assert_eq(restored.state_hash(), sim.state_hash(), "roundtrip hash identical mid-boss-fight")
	assert_eq(restored.ai.current_phase("boss"), 2, "phase survives the roundtrip")
	assert_event(ai_decide(restored, "boss"), "explosion_telegraph",
		"restored boss honors its phase — the valve telegraphs (#27)")


func test_ai_rng_state_is_load_bearing_in_saves() -> void:
	var sim: CombatSim = make_sim()
	add_human(sim, "h", {"team": "party", "position": [1, 0]})
	add_boss(sim, "boss", {"boss_traits": {"dodge_threshold": 6}})
	for i: int in range(6):
		declare(sim, "h", attack_action("poison", 0, "boss", "right_hand"))
		advance(sim, 1)
	var snapshot: Dictionary = sim.to_dict()
	var restored: CombatSim = CombatSim.from_dict(snapshot)
	# Lockstep: the restored stream must reproduce the original's future rolls.
	var tail_original: Array[Dictionary] = []
	var tail_restored: Array[Dictionary] = []
	for i: int in range(6):
		declare(sim, "h", attack_action("poison", 0, "boss", "right_hand"))
		declare(restored, "h", attack_action("poison", 0, "boss", "right_hand"))
		tail_original.append_array(advance(sim, 1))
		tail_restored.append_array(advance(restored, 1))
	var fingerprint_original: Array[String] = []
	var fingerprint_restored: Array[String] = []
	for event: Dictionary in tail_original:
		if ["attack_dodged", "dodge_failed"].has(String(event.get("type", ""))):
			fingerprint_original.append("%s:%d" % [String(event.get("type", "")), int(event.get("roll", 0))])
	for event: Dictionary in tail_restored:
		if ["attack_dodged", "dodge_failed"].has(String(event.get("type", ""))):
			fingerprint_restored.append("%s:%d" % [String(event.get("type", "")), int(event.get("roll", 0))])
	assert_true(fingerprint_original.size() >= 1, "the tail rolled dodges (%d)" % fingerprint_original.size())
	assert_eq(fingerprint_restored, fingerprint_original, "restored ai_rng continues the exact roll stream")
	assert_eq(restored.state_hash(), sim.state_hash(), "lockstep tails end on the same hash")
	# Mutation teeth: a tampered ai_rng_state must change the hash.
	var tampered: Dictionary = sim.to_dict()
	(tampered["ai"] as Dictionary)["ai_rng_state"] = int((tampered["ai"] as Dictionary).get("ai_rng_state", 0)) + 12345
	assert_ne(CombatSim.from_dict(tampered).state_hash(), sim.state_hash(),
		"ai_rng_state is covered by the state hash")
