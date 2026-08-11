extends Node
## GameController — the single gateway between presentation and the sim (KAN3-S1).
##
## MVC contract (architecture doc + docs/architecture/architecture.md):
## - Owns the CombatSim instance; scenes NEVER touch simulation/ classes.
## - Every command funnels through apply_command(); every event the sim returns
##   is re-emitted as a signal: a typed signal for the catalog's combat events
##   plus the generic sim_event for everything (scenes may subscribe to either).
## - Constructor-friendly: no _ready dependency, so headless tests can drive it.
## - Owns the COMMAND LOG (the sim is the reducer; the caller owns the log) and
##   the save/load flow via SaveManager (KAN3-S2). Static data comes exclusively
##   from the DAL.

signal sim_event(event: Dictionary)
signal combatant_added(event: Dictionary)
signal combatant_died(event: Dictionary)
signal damage_applied(event: Dictionary)
signal condition_applied(event: Dictionary)
signal condition_advanced(event: Dictionary)
signal action_resolved(event: Dictionary)
signal forced_action_triggered(event: Dictionary)
signal breach_opened(event: Dictionary)
signal clock_moment_changed(event: Dictionary)
signal clock_reset(event: Dictionary)
signal hype_band_changed(event: Dictionary)
signal hype_spike(event: Dictionary)
signal ai_decision(event: Dictionary)
signal boss_phase_changed(event: Dictionary)
signal attack_dodged(event: Dictionary)
signal command_rejected(event: Dictionary)
## Fired ONCE when the fight first resolves (win/loss detected after a tick). The
## payload is a synthetic {"type":"combat_ended","outcome":"WIN"|"LOSS"} event; it
## also flows on the generic sim_event, like every other event (see _emit_event).
signal combat_ended(event: Dictionary)
## RUN-level events (KAN-4, decision #31): every event the RunState reducer
## returns from apply_run_command flows here — run_started, run_encounter_started,
## run_encounter_ended, run_recruit_available/offered/joined/declined, run_ended,
## run_command_rejected. Separate from sim_event on purpose: run events are not
## sim events, and combat listeners keep their exact current traffic.
signal run_event(event: Dictionary)

## event type -> typed signal name (generic sim_event fires for every event).
const TYPED: Dictionary = {
	"combatant_added": "combatant_added",
	"combatant_died": "combatant_died",
	"damage_applied": "damage_applied",
	"condition_applied": "condition_applied",
	"condition_advanced": "condition_advanced",
	"action_resolved": "action_resolved",
	"forced_action_triggered": "forced_action_triggered",
	"breach_opened": "breach_opened",
	"clock_moment_changed": "clock_moment_changed",
	"clock_reset": "clock_reset",
	"hype_band_changed": "hype_band_changed",
	"hype_spike": "hype_spike",
	"ai_decision": "ai_decision",
	"boss_phase_changed": "boss_phase_changed",
	"attack_dodged": "attack_dodged",
	"command_rejected": "command_rejected",
	"combat_ended": "combat_ended",
}

var sim: CombatSim
var dal: Dal = Dal.new()
var saves: SaveManager = SaveManager.new()
var command_log: Array[Dictionary] = []

## RUN engine state (KAN-4, decision #31 — engine only). The controller owns the
## RUN-COMMAND LOG exactly as it owns the combat one: RunState is the reducer,
## the caller owns the log (run state = pure function of (run seed, run log) —
## see simulation/run_state.gd's header for the command set + carry policy).
var run: RunState = null
var run_command_log: Array[Dictionary] = []
## Static data bundle pinned at start_run so every encounter of the run stages
## from the same tables ({} = load through the DAL, like start_combat).
var _run_static_data: Dictionary = {}

## Latch so combat_ended fires EXACTLY ONCE per fight (reset by start_combat). The
## fight-over check runs after each tick; without this latch it would re-fire on
## every subsequent tick while the corpse stays down.
var _combat_ended_emitted: bool = false

## Optional clock driver (KAN3-S4). The scene attaches a PausedClockDriver so END
## TURN routes through the slice gate (advance_moment); null in headless tests,
## which advance the tick directly through apply_command.
var clock_driver = null


func set_clock_driver(d) -> void:
	clock_driver = d


## Creates a fresh sim. Passing static_data overrides the DAL load (tests).
func start_combat(sim_seed: int, static_data: Dictionary = {}) -> void:
	if static_data.is_empty():
		static_data = dal.static_data_for_sim()
	sim = CombatSim.new(sim_seed, static_data)
	command_log = []
	_combat_ended_emitted = false


## The one command funnel: logs the command, applies it, re-emits every event.
func apply_command(cmd: Dictionary) -> Array[Dictionary]:
	if sim == null:
		push_error("GameController.apply_command before start_combat")
		return []
	command_log.append(cmd.duplicate(true))
	var events: Array[Dictionary] = sim.apply_command(cmd)
	for event: Dictionary in events:
		_emit_event(event)
	# Fight-over detection (R0): a tick is the only moment condition/timer death can
	# land, so we check the win/loss hinge right after each advance_tick — the one
	# spot both the direct headless path and the driver path funnel through. This
	# reads state only; it never mutates the sim, so replay stays deterministic.
	if String(cmd.get("type", "")) == "advance_tick":
		_maybe_emit_combat_ended()
	return events


## Re-emits one event on the generic sim_event plus its typed signal (if any). The
## single emit path for BOTH real sim events and the controller's synthetic
## combat_ended, so every listener sees them the same way.
func _emit_event(event: Dictionary) -> void:
	sim_event.emit(event)
	var event_type := String(event.get("type", ""))
	if TYPED.has(event_type):
		emit_signal(StringName(TYPED[event_type]), event)


## Read-only fight resolution (KAN-7 run loop): is the fight over, and who won?
## outcome is "ONGOING" | "WIN" | "LOSS". A combatant is LIVE when alive and not
## removed_from_play. WIN = combatants exist but no live enemy remains; LOSS = no
## live party remains (both-empty prefers LOSS, since live_party==0 is tested
## first). Reads the same sim.combatants view_combatants() projects — pure, no
## mutation, so it is safe to poll and stays deterministic on replay.
func combat_status() -> Dictionary:
	var live_party: int = 0
	var live_enemies: int = 0
	var has_party: bool = false    # any party combatant on the roster (alive or fallen)
	var has_enemies: bool = false  # any enemy combatant on the roster (alive or fallen)
	if sim != null:
		for id: Variant in sim.combatants.keys():
			var c: CombatantState = sim.combatants[id]
			if c.team == "party":
				has_party = true
			elif c.team == "enemies":
				has_enemies = true
			if not (c.alive and not c.removed_from_play):
				continue
			if c.team == "party":
				live_party += 1
			elif c.team == "enemies":
				live_enemies += 1
	# Only a staged party-vs-enemies fight can resolve. With neither side on the
	# roster (pre-staging, or a team-less test fixture) there is nothing to win or
	# lose, so the fight stays ONGOING.
	if not has_party and not has_enemies:
		return {"over": false, "outcome": "ONGOING"}
	# live_party checked first, so a mutual wipe (both sides emptied in one tick)
	# resolves LOSS — the "prefer LOSS when both are empty" tie-break.
	var outcome := "ONGOING"
	if live_party == 0:
		outcome = "LOSS"
	elif live_enemies == 0:
		outcome = "WIN"
	return {"over": outcome != "ONGOING", "outcome": outcome}


## Emits combat_ended the first time the fight resolves. Latched so it fires once.
func _maybe_emit_combat_ended() -> void:
	if _combat_ended_emitted:
		return
	var status: Dictionary = combat_status()
	if not bool(status.get("over", false)):
		return
	_combat_ended_emitted = true
	_emit_event({"type": "combat_ended", "outcome": String(status.get("outcome", "LOSS"))})


func state_hash() -> String:
	return "" if sim == null else sim.state_hash()


## The enemy side of a tick (R11 #15): feeds one ai_decide per ready
## AI-controlled combatant (sorted) into the command log. The driver calls
## this before advancing the tick; each decision recomputes deterministically
## on replay, so the log stays the single source of truth.
func run_enemy_turn() -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if sim == null:
		return events
	for id: String in sim.ai_ready_ids():
		events.append_array(apply_command({"type": "ai_decide", "actor": id}))
	return events


## One END TURN "Moment" from the presentation layer. With NO driver (headless
## tests), this is the unchanged fallback — a bare advance_tick through the command
## funnel. With the slice driver attached, pressing END TURN first ACKNOWLEDGES the
## previous tick's forced-action fallout (which the player has now seen on the
## refreshed HUD), marks the whole party done declaring, then advances — so a
## forced action shows for one beat but never soft-locks the slice. try_advance()
## feeds its commands (run_enemy_turn's ai_decides + the advance_tick) through
## apply_command, so every event already flows out on sim_event; the return here is
## advisory (an empty array) and the HUD refreshes off the signal regardless.
func advance_moment() -> Array[Dictionary]:
	if clock_driver == null:
		return apply_command({"type": "advance_tick"})
	clock_driver.acknowledge_all()
	clock_driver.mark_party_declared()
	clock_driver.try_advance()
	var out: Array[Dictionary] = []
	return out


## Read-only VIEW API (KAN3-S3): plain-Dictionary projections of sim state so
## scenes can render without importing simulation classes. Sorted, primitive,
## and safe to call every frame.
##
## Spectator contract (docs/design/view-api-spectator-contract.md): consumers
## must never reverse-engineer game meaning (e.g. sniffing part names to find
## "the boss"), so each entry carries the MEANING fields directly — team /
## category / is_boss, a stable display `token` for presentation art lookup
## (the enemy template key for template-built enemies, else the combatant id),
## and the contestant's broadcast identity (persona + signed patron key, joined
## from the demo loadouts; "" when nothing matches — never guessed).
func view_combatants() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if sim == null:
		return out
	var ids: Array = sim.combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = sim.combatants[id]
		var identity: Dictionary = {"persona": "", "patron": ""}
		if not EnemyAI.AI_CATEGORIES.has(c.category):
			identity = _loadout_identity(String(id))
		var parts: Array[Dictionary] = []
		var part_keys: Array = c.parts.keys()
		part_keys.sort()
		for part_key: Variant in part_keys:
			var part: Dictionary = c.parts[part_key]
			var conds: Dictionary = {}
			var on_part: Dictionary = c.conditions.get(part_key, {})
			for cond_id: Variant in on_part:
				conds[String(cond_id)] = int((on_part[cond_id] as Dictionary).get("tier", 1))
			parts.append({
				"key": String(part_key),
				"hp": int(part.get("hp", 0)),
				"max_hp": c.max_hp(String(part_key)),
				"lethal": bool(part.get("lethal", false)),
				"disabled": bool(part.get("disabled", false)),
				"destroyed": bool(part.get("destroyed", false)),
				# A part hidden_until_breach reads hidden=true until this combatant
				# is breached — the HUD keeps the boss's mycelium network off-screen
				# until the party discovers it (breached flips it visible).
				"hidden": bool(part.get("hidden", false)) and not c.breached,
				"conditions": conds,
			})
		out.append({
			"id": String(id),
			"name": c.display_name,
			"team": c.team,
			"category": c.category,
			"is_boss": c.category == "Boss",
			# Stable presentation-art key: the enemy template this combatant was
			# built from, else its own id (contestants are race-built, no template).
			"token": c.template_key if c.template_key != "" else String(id),
			"persona": String(identity["persona"]),
			"patron": String(identity["patron"]),
			# Authored bit (decision log #25): the actor's bit dict verbatim
			# ({key, name, line}), {} for the many combatants with none — the UI
			# offers The Bit only to characters who actually have one.
			"bit": c.bit.duplicate(true),
			# Granted loadout skills (the last fixture holdover removed): one row
			# per grant, {key, level, name, cost, self} — see _view_skills. [] for
			# enemies / anyone with no grants, never guessed.
			"skills": _view_skills(c),
			"position": [c.position.x, c.position.y],
			"alive": c.alive,
			"shock": c.shock,
			"exposed": c.exposed_cache,
			# Status-prominence widening (ADDITIVE, meaning-over-internals): the two
			# at-a-glance states the view did not carry yet. `helpless` is the live
			# is_helpless read at the current tick (bleed-out / helpless window /
			# incapacitated — the HUD never re-derives the rule); `prone` is the
			# knocked-down status flag (forced-action fallout).
			"helpless": c.is_helpless(sim.clock.tick),
			"prone": bool(c.statuses.get("prone", false)),
			# Skill-feel widening (ADDITIVE): the feint debuff is ARMED on this
			# combatant — its next resolved action will collapse. The HUD's
			# FEINTED badge reads this; attribution rides the feint_fallout event.
			"feint_forced": c.feint_forced,
			"breached": c.breached,
			# R3 free-action economy (anti-spam ruling): true once this combatant
			# has spent its one free (0-Moment) action this tick — The Bit, the
			# free move, the first inventory use and 0-cost reactions all consume
			# it. Straight off the state so UIs can gate 0-cost entries honestly.
			"free_action_used": c.free_action_used,
			# R23 (ADDITIVE): an AI combatant's antagonism map (opponent id ->
			# grudge score, plain copy) so the HUD/inspector can show who the
			# boss hates. {} for contestants — they never hold grudges here.
			"antagonism": c.antagonism.duplicate(true) if EnemyAI.AI_CATEGORIES.has(c.category) else {},
			# Wave 3a (ADDITIVE): the AI stance substrate for `aura_reading` —
			# the actor's last-decide intent read (aggressive / hunting /
			# defensive / building; the table lives in EnemyAI's header).
			# "unknown" for an AI that has not decided yet; "" for contestants
			# (stances are AI-only — the skill reads ENEMY intent).
			"ai_stance": (String(sim.ai.stances.get(String(id), "unknown"))
					if EnemyAI.AI_CATEGORIES.has(c.category) else ""),
			"parts": parts,
		})
	return out


## Per-combatant granted-skill projection for view_combatants: one plain row per
## GRANTED loadout skill, in grant order (deterministic — the grant array is
## command-stream state). Per row:
##   key:   the skill key (state)
##   level: the GRANTED level (state — what the HUD's declares now send)
##   name:  skills.json display name via the DAL; fallback: title-cased key
##          (an un-catalogued key still reads honestly, never guessed)
##   cost:  the honest Moment cost from SkillBook.mechanics at the granted level
##   self:  SkillBook.is_self_skill — self-buff vs targeted (the HUD's flyout tag)
## Read-only over static authorities; [] for enemies / skill-less combatants.
func _view_skills(c: CombatantState) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for sk: Dictionary in c.skills:
		var key := String(sk.get("key", ""))
		var level: int = int(sk.get("level", 1))
		var display := String(dal.skill(key).get("name", ""))
		if display == "":
			display = _titlecase(key)
		rows.append({
			"key": key,
			"level": level,
			"name": display,
			"cost": int(SkillBook.mechanics(key, level).get("cost", 1)),
			"self": SkillBook.is_self_skill(key),
		})
	return rows


## Broadcast identity join for view_combatants: the demo loadout matching this
## combat id, projected to {persona, patron} (persona = broadcast_persona;
## patron = the signed patron KEY via chosen_patron -> patron_gods, exactly the
## join view_bid already does). JOIN WRINKLE (verified against the data): loadout
## keys are namespaced ("imani_the_door" / "dario_encore") while combat ids are
## the bare first name ("imani" / "dario"), so the honest rule is: a loadout
## matches the combatant whose id equals the loadout key's FIRST "_"-separated
## token. Holds for both demo loadouts; no match -> empty strings, never guessed.
func _loadout_identity(id: String) -> Dictionary:
	for lo: Variant in dal.demo_loadouts().get("loadouts", []):
		var loadout: Dictionary = lo
		if String(loadout.get("key", "")).split("_")[0] != id:
			continue
		var patron_key: String = ""
		for g: Variant in dal.patron_gods():
			if int((g as Dictionary).get("id", -1)) == int(loadout.get("chosen_patron", -2)):
				patron_key = String((g as Dictionary).get("key", ""))
				break
		return {
			"persona": String(loadout.get("broadcast_persona", "")),
			"patron": patron_key,
		}
	return {"persona": "", "patron": ""}


## Read-only ENCOUNTER-LEVEL probe (spectator contract —
## docs/design/view-api-spectator-contract.md): one plain Dictionary a
## spectator/replay/highlights consumer (or the HUD) can poll for the fight's
## meaning without sniffing internals — overall status, the boss beat, and the
## slice objective. Reads LIVE sim state only (combat_status + the same boss
## lookup view_verdict uses); deterministic — same state, same output — and
## never cached, so "probe at tick N" is just re-sim to N and call this.
##   status:    combat_status() verbatim ({over, outcome}).
##   boss:      {id, name, phase, breached, network_exposed} or {} when no boss.
##              phase is the _verdict_boss PLACEHOLDER (breach = Phase 2, F2);
##              network_exposed mirrors the live breached flag (a breach is what
##              exposes the network; a pressure-valve reset re-hides it).
##   objective: {kind, discovered, text} — the slice's discoverable win
##              condition; `text` is one PLACEHOLDER (R14) line of copy.
func view_encounter() -> Dictionary:
	if sim == null:
		return {}
	var boss: Dictionary = {}
	var c: CombatantState = _boss_combatant()
	if c != null:
		boss = {
			"id": c.id,
			"name": c.display_name,
			"phase": (2 if c.breached else 1),  # PLACEHOLDER: breach = Phase 2 (F2)
			"breached": c.breached,
			"network_exposed": c.breached,
		}
	return {
		"status": combat_status(),
		"boss": boss,
		"objective": {
			"kind": "breach_network",
			"discovered": bool(boss.get("breached", false)),
			# PLACEHOLDER (R14) broadcast copy — the objective's one-line card text.
			"text": "Find & breach the hidden network — force Phase 2",
		},
	}


## Read-only ARENA probe (KAN-5 wave 3d — ADDITIVE, spectator contract): the
## OPT-IN arena's bounds, walls and environment objects as plain sorted
## primitives, so a renderer can draw the room and its props without touching
## simulation classes. {} before start_combat AND for every no-arena combat
## (the unbounded legacy default — the harnesses, all pre-arena saves), so
## existing consumers see nothing new unless an encounter authors an arena.
##   bounds:  {"kind": "rect", "origin": [q, r], "width", "height"}
##            | {"kind": "hexes", "hexes": [[q, r], ...] sorted}
##   walls:   [[q, r], ...] sorted
##   objects: [{"key", "position": [q, r], "burn"}, ...] in store order —
##            a destroyed can simply disappears from the list (its hex
##            unblocks); "burn" is the live accumulation toward the pop at 5.
func view_arena() -> Dictionary:
	if sim == null or sim.arena == null:
		return {}
	return sim.arena.view()


func view_clock() -> Dictionary:
	if sim == null:
		return {}
	return {"tick": sim.clock.tick, "moment": sim.clock.moment()}


## Read-only SCHEDULE probe (spectator contract — HUD v2 Phase 2): one plain
## row per PENDING scheduled entry, seq-ordered, deep-copied — the declared-
## action bars + the End-Turn "what resolves next" telegraph read this. Never
## mutates; deterministic (same state, same rows).
##   actor:         combatant id
##   kind:          the action dict's kind ("attack"/"skill"/"move"/...)
##   key:           the action's identity — skill key, else item, else the kind
##   declared_tick: resolve_tick − window when window > 0, else resolve_tick
##   resolve_tick:  the tick the entry resolves on
##   windup:        window > 0 (a committed multi-Moment declare/resolve gap)
##   combo_id:      present only on R15 combined-action members
##   undodgable:    present (true) only when the declared action carries the
##                  R26 data-driven flag — declared loudly so the schedule
##                  never hides that no dodge-shaped escape exists (additive)
func view_schedule() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if sim == null:
		return out
	for entry: Dictionary in sim.clock.scheduled_entries():
		var action: Dictionary = entry.get("action", {})
		var window: int = int(entry.get("window", 0))
		var resolve_tick: int = int(entry.get("tick", 0))
		var kind := String(action.get("kind", "attack"))
		var key := String(action.get("key", ""))
		if key == "":
			key = String(action.get("item", ""))
		if key == "":
			key = kind
		var row: Dictionary = {
			"actor": String(entry.get("actor", "")),
			"kind": kind,
			"key": key,
			"declared_tick": (resolve_tick - window) if window > 0 else resolve_tick,
			"resolve_tick": resolve_tick,
			"windup": window > 0,
		}
		if action.has("combo_id"):
			row["combo_id"] = String(action.get("combo_id", ""))
		if bool(action.get("undodgable", false)):
			row["undodgable"] = true
		out.append(row)
	return out


## Read-only ACTION PREVIEW probe (spectator contract — HUD v2 Phase 2):
## forwards to ActionResolver.preview_action. Plain dicts, deterministic, ZERO
## mutation and ZERO rng consumption (dodge is reported as uncertainty, never
## rolled). {} for an unknown actor or before start_combat. A combined preview
## passes action["combo_members"] and reads the members' own actor ids.
func preview_action(actor_id: String, action: Dictionary) -> Dictionary:
	if sim == null:
		return {}
	var actor: CombatantState = sim.combatants.get(actor_id)
	if actor == null and not action.has("combo_members"):
		return {}
	return sim.resolver.preview_action(actor, action)


## Owner-blessed band display names (2026-07-19): the sim enum -> broadcast copy.
const BAND_DISPLAY: Dictionary = {
	"cold": "COLD OPEN", "warm": "WARMING UP", "hot": "ELECTRIC", "on_fire": "ON FIRE",
}


## Broadcast/audience projection for the combat HUD. view_combatants covers the
## fighters; this covers the audience economy the mockup shows — hype meter+band,
## the active crowd goal, the camera spotlight, and per-contestant tags — none of
## which lived in a view before (slice playtest finding F3). Read-only over the
## sim's HypeEngine + TagEngine; presentation only, never mutates.
func view_broadcast() -> Dictionary:
	if sim == null:
		return {}
	var hype: HypeEngine = sim.hype
	var band := String(hype.band)
	var goal: Dictionary = {}
	if not hype.active_goal.is_empty():
		var g: Dictionary = hype.active_goal
		goal = {
			"id": String(g.get("id", "")),
			"name": String(g.get("name", "")),
			"kind": String(g.get("kind", "")),
			"payout": int(g.get("payout", 0)),
			"clocks_left": int(g.get("clocks_left", 0)),
			"progress": int(g.get("progress", 0)),
			"params": (g.get("params", {}) as Dictionary).duplicate(true),
		}
	var spotlight: Dictionary = {}
	if not hype.spotlight.is_empty():
		spotlight = {
			"caller": String(hype.spotlight.get("caller", "")),
			"target": String(hype.spotlight.get("target", "")),
			"clocks_left": int(hype.spotlight.get("clocks_left", 0)),
		}
	# Per-contestant tags (held + in-progress) for the tag feed / unit tokens.
	var tags: Dictionary = {}
	var tag_ids: Array = sim.tags.held.keys()
	for pid: Variant in sim.tags.progress.keys():
		if not tag_ids.has(pid):
			tag_ids.append(pid)
	tag_ids.sort()
	for pid: Variant in tag_ids:
		var held_keys: Array = (sim.tags.held.get(pid, {}) as Dictionary).keys()
		held_keys.sort()
		tags[String(pid)] = {
			"held": held_keys,
			"progress": (sim.tags.progress.get(pid, {}) as Dictionary).duplicate(true),
		}
	return {
		"hype": {
			"meter": int(hype.meter),
			"band": band,
			"band_display": String(BAND_DISPLAY.get(band, band.to_upper())),
		},
		"goal": goal,
		"spotlight": spotlight,
		"tags": tags,
	}


## Pre-run PATRON BID projection (demo slice — "The Bidding" screen). Unlike the
## other views this reads STATIC data only (the DAL), never the live sim: the 5
## Greek patron gods (data/patron_gods.json) and the two demo contestants + their
## pre-signed patron (data/demo_loadouts.json). Presentation-only; no RNG — every
## number is DERIVED deterministically from the god's own fields so the rendered
## screen is stable. Every value here is PLACEHOLDER (R14); a real bidding/economy
## system replaces the derivations later (see the report's stub list).
func view_bid() -> Dictionary:
	var patrons: Array = dal.patron_gods()
	var by_id: Dictionary = {}
	for g: Variant in patrons:
		by_id[int((g as Dictionary).get("id", -1))] = g
	var loadouts: Array = dal.demo_loadouts().get("loadouts", [])

	var contestants: Array = []
	var table_pot: int = 0
	for lo: Variant in loadouts:
		var loadout: Dictionary = lo
		var signed: Dictionary = by_id.get(int(loadout.get("chosen_patron", -1)), {})
		var signed_key: String = String(signed.get("key", ""))

		# Rivals: the other patrons, highest influence first (deterministic key
		# tie-break), take 2 — "the signed patron + 2 more of the 5 (stable pick)".
		var rivals: Array = []
		for g: Variant in patrons:
			if String((g as Dictionary).get("key", "")) != signed_key:
				rivals.append(g)
		rivals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if int(a.get("influence", 0)) != int(b.get("influence", 0)):
				return int(a.get("influence", 0)) > int(b.get("influence", 0))
			return String(a.get("key", "")) < String(b.get("key", "")))
		rivals = rivals.slice(0, 2)
		# Exactly ONE non-signed high-influence god is flagged OUTBIDDING (the top
		# rival after the influence sort — visually the loudest rival bid).
		var outbid_key: String = String((rivals[0] as Dictionary).get("key", "")) if not rivals.is_empty() else ""

		var cards: Array = []
		if not signed.is_empty():
			cards.append(_bid_card(signed, true, false))
		for r: Variant in rivals:
			cards.append(_bid_card(r, false, String((r as Dictionary).get("key", "")) == outbid_key))
		for c: Variant in cards:
			table_pot += int((c as Dictionary).get("bid", 0))

		contestants.append({
			"id": String(loadout.get("key", "")),
			"name": String(loadout.get("display_name", "")),
			"persona": String(loadout.get("broadcast_persona", "")),
			"signed_patron": signed_key,
			"patrons": cards,
		})

	return {"table_pot": table_pot, "contestants": contestants}


## One patron's bid card (view_bid helper). bid / multiplier / traits are DERIVED
## deterministically from the god's static fields (influence, generosity, power,
## buff_multiplier) — no RNG — so the rendered screen never shifts. PLACEHOLDER (R14).
func _bid_card(g: Dictionary, is_signed: bool, is_outbidding: bool) -> Dictionary:
	var gen: int = int(g.get("generosity", 3))
	var power: int = int(g.get("power", 3))
	var influence: int = clampi(int(g.get("influence", 3)), 1, 5)
	var buff: float = float(g.get("buff_multiplier", 0.1))
	var domain_titles: Array = []
	for d: Variant in g.get("domains", []):
		domain_titles.append(_titlecase(String(d)))
	var boons: Array = []
	for b: Variant in (g.get("boon_table", []) as Array).slice(0, 2):
		boons.append(_titlecase(String(b)))
	var favor_conditions: Array = g.get("favor_conditions", [])
	var taboos: Array = g.get("taboos", [])
	return {
		"key": String(g.get("key", "")),
		"name": String(g.get("name", "")),
		"pantheon": "%s Pantheon" % String(g.get("origin", "")),
		"domain": " & ".join(PackedStringArray(domain_titles)),
		"influence": influence,
		"favor": String(favor_conditions[0]) if not favor_conditions.is_empty() else "",
		"taboo": String(taboos[0]) if not taboos.is_empty() else "",
		"boons": boons,
		"traits": _bid_traits(gen, power),
		# influence dominates the bid so the flagged (highest-influence) rival reads
		# as the top number; generosity*power is a secondary sweetener. PLACEHOLDER.
		"bid": influence * 2000 + gen * power * 100,
		"multiplier": snappedf(1.0 + power * 0.4 + buff * 5.0, 0.1),
		"signed": is_signed,
		"outbidding": is_outbidding,
	}


## Two personality words derived from a god's generosity (warmth axis) and power
## (intensity axis). Deterministic; PLACEHOLDER flavor until real patron voice copy.
func _bid_traits(gen: int, power: int) -> Array:
	var warmth: String = "Cold"
	if gen >= 5: warmth = "Doting"
	elif gen == 4: warmth = "Warm"
	elif gen == 3: warmth = "Even"
	elif gen == 2: warmth = "Aloof"
	var intensity: String = "Meek"
	if power >= 4: intensity = "Relentless"
	elif power == 3: intensity = "Assertive"
	elif power == 2: intensity = "Patient"
	return [warmth, intensity]


## "healing_comp" / "war" -> "Healing Comp" / "War" (view_bid helper).
func _titlecase(s: String) -> String:
	var out: Array = []
	for w: String in s.replace("_", " ").split(" ", false):
		if not w.is_empty():
			out.append(w.substr(0, 1).to_upper() + w.substr(1))
	return " ".join(PackedStringArray(out))


## Turn-order projection (KAN-6): live combatants ordered by when they next act
## (next_action_tick, soonest first; deterministic id tie-break). Drives the HUD
## tick-order rail and the on-the-clock highlight. `ready` = can act at the current
## tick and not still winding up; `windup_pending` marks a committed multi-Moment
## action mid-resolution.
func view_turn_order() -> Array[Dictionary]:
	var order: Array[Dictionary] = []
	if sim == null:
		return order
	var ids: Array = sim.combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = sim.combatants[id]
		if not c.alive or c.removed_from_play:
			continue
		order.append({
			"id": String(id),
			"name": c.display_name,
			"category": c.category,
			"is_contestant": not EnemyAI.AI_CATEGORIES.has(c.category),
			"next_action_tick": c.next_action_tick,
			"ready": c.can_act(sim.clock.tick) and not c.windup_pending and c.next_action_tick <= sim.clock.tick,
			"windup_pending": c.windup_pending,
		})
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["next_action_tick"]) != int(b["next_action_tick"]):
			return int(a["next_action_tick"]) < int(b["next_action_tick"])
		return String(a["id"]) < String(b["id"]))
	return order


## Epithet unlocked from a held slice-tag (I-13 TagEngine). One tag -> one earned
## title; PLACEHOLDER broadcast copy (R14).
const EPITHET_BY_TAG: Dictionary = {
	"survivor":       {"name": "THE UNBROKEN",   "note": "essence held · zero shock tiers taken"},
	"gorefest":       {"name": "THE BUTCHER",    "note": "left the arena painted red"},
	"reckless":       {"name": "THE DAREDEVIL",  "note": "fought from the exposed edge"},
	"scene_stealer":  {"name": "THE HEADLINER",  "note": "stole every camera in the room"},
	"the_bit":        {"name": "THE SHOWSTOPPER","note": "pure spectacle, right on cue"},
	"blooper_reel":   {"name": "THE PRATFALL",   "note": "comedy is content"},
	"craft_services": {"name": "THE GUARDIAN",   "note": "took the hit for the team"},
	"formation":      {"name": "THE ANCHOR",     "note": "held the line together"},
	"3am_energy":     {"name": "THE BLUR",       "note": "never once stopped moving"},
	"fan_favorite":   {"name": "THE DARLING",    "note": "the crowd's chosen one"},
}
## Priority when a contestant holds several tags (deterministic epithet pick).
const EPITHET_PRIORITY: Array = [
	"survivor", "gorefest", "reckless", "scene_stealer", "the_bit",
	"craft_services", "formation", "3am_energy", "blooper_reel", "fan_favorite",
]
## Crowd-verdict headline from a held slice-tag; PLACEHOLDER copy (R14).
const CROWD_VERDICT_BY_TAG: Dictionary = {
	"fan_favorite":   "FAN FAVORITE",
	"scene_stealer":  "SCENE STEALER",
	"gorefest":       "BLOODTHIRSTY DELIGHT",
	"reckless":       "EDGE OF THE SEAT",
	"the_bit":        "COMIC RELIEF",
	"survivor":       "IRON DARLING",
	"craft_services": "TEAM PLAYER",
	"3am_energy":     "LIVE WIRE",
	"blooper_reel":   "GUILTY PLEASURE",
	"formation":      "SQUAD GOALS",
}
## Crowd-verdict pick priority (kept distinct-leaning from the epithet order so the
## two cards read differently when a contestant holds both tags).
const CROWD_VERDICT_PRIORITY: Array = [
	"fan_favorite", "scene_stealer", "gorefest", "reckless", "the_bit",
	"survivor", "craft_services", "3am_energy", "blooper_reel", "formation",
]
## Star rating derived from the peak hype band (PLACEHOLDER derivation, R14).
const STARS_BY_BAND: Dictionary = {"cold": 1, "warm": 2, "hot": 4, "on_fire": 5}


## Read-only END-OF-RUN VERDICT projection (KAN-7 demo slice) — summarizes the
## FINAL combat state for the Verdict card ("a verdict, not a victory screen" —
## DIRECTION.md). Presentation-only, like the other view_* methods: it reads the
## live sim + the SAME engines the combat views use (view_broadcast()'s HypeEngine
## meter/band + TagEngine held tags) and authors NO state.
##
## DERIVED LIVE: outcome (contestant.alive), hype_earned (hype.meter), peak_band
## (hype.band_display), epithet + crowd_verdict.name (held slice-tags), boss
## breached/phase (the boss combatant's `breached` + its `network` part),
## slice_win (boss breached), evidence (the EvidenceEngine ledger — the real
## decisions the card quotes against the crowd's labels), endured (survival
## state derived here at view time: parts destroyed/disabled, not an event).
## PLACEHOLDER (R14, flagged — no backing system yet): patron_standing (no
## patron-favor ledger), tagline (templated flavor), crowd_verdict.stars
## (band-derived proxy), peak_band (final band stands in — no peak tracking),
## every evidence "line" (structure/truth are real; the copy awaits the
## visuals/writing epic).
func view_verdict(contestant_id: String) -> Dictionary:
	if sim == null or not sim.combatants.has(contestant_id):
		return {}
	var c: CombatantState = sim.combatants[contestant_id]
	var alive: bool = c.alive and not c.removed_from_play
	var outcome := "SURVIVED" if alive else "DIED"

	var bc: Dictionary = view_broadcast()
	var hype: Dictionary = bc.get("hype", {})
	var band := String(hype.get("band", "cold"))
	var held: Array = ((bc.get("tags", {}) as Dictionary).get(contestant_id, {}) as Dictionary).get("held", [])

	var boss: Dictionary = _verdict_boss()
	var slice_win: bool = bool(boss.get("breached", false))

	return {
		"contestant": c.display_name,
		"outcome": outcome,
		"hype_earned": int(hype.get("meter", 0)),
		"peak_band": String(hype.get("band_display", "")),  # PLACEHOLDER: final band as peak proxy
		"epithet": _epithet_for(held),                       # from a held slice-tag
		"patron_standing": {                                 # PLACEHOLDER: no patron-favor ledger yet
			"name": "HESTIA", "state": "PLEASED",
			"note": "+ BLESSING banked for next run",
		},
		"crowd_verdict": _crowd_verdict_for(held, band),     # tag headline + band-derived stars
		"boss": boss,
		"slice_win": slice_win,
		"tagline": _verdict_tagline(outcome),                # PLACEHOLDER templated flavor
		"evidence": _verdict_evidence(contestant_id),        # the record: real logged deeds
		"endured": _verdict_endured(c, alive),               # view-derived survival detail
	}


## The contestant's slice of the evidence ledger, chronological (the ledger is
## append-only): their own actor entries + party-level ("") entries, each with a
## PLACEHOLDER "line" composed from the entry's real fields.
func _verdict_evidence(contestant_id: String) -> Array:
	var out: Array = []
	for entry: Dictionary in sim.evidence.ledger:
		var actor := String(entry.get("actor", ""))
		if actor != contestant_id and actor != "":
			continue
		var e: Dictionary = entry.duplicate(true)
		e["line"] = _evidence_line(entry)
		out.append(e)
	return out


## PLACEHOLDER copy (R14): one broadcast-caption line per evidence entry. The
## FACTS in the line come from the entry; only the phrasing is placeholder.
func _evidence_line(entry: Dictionary) -> String:
	var d: Dictionary = entry.get("detail", {})
	var prefix := "C%d M%02d — " % [int(entry.get("clock", 1)), int(entry.get("moment", 10))]
	match String(entry.get("type", "")):
		"breach_risk":
			var line := "took the hit that cracked the network open"
			if bool(d.get("windup", false)):
				line += " — committed through the windup, wide open"
			return prefix + line
		"goal_answered":
			return prefix + "answered the crowd's %s demand (+%d hype)" \
				% [_goal_shout(String(d.get("goal", ""))), int(d.get("payout", 0))]
		"goal_unanswered":
			return prefix + "let the crowd's %s demand die un-answered" \
				% _goal_shout(String(d.get("goal", "")))
		"bit_under_fire":
			var line := "did The Bit"
			if d.has("wounded_part"):
				line += " with a %s %s" % [
					"bleeding" if bool(d.get("bleeding", false)) else "wounded",
					String(d.get("wounded_part", "")).replace("_", " ")]
				if d.has("enemy_adjacent"):
					line += " and %s in reach" % _combatant_name(String(d.get("enemy_adjacent", "")))
			elif d.has("enemy_adjacent"):
				line += " with %s in reach" % _combatant_name(String(d.get("enemy_adjacent", "")))
			return prefix + line
		"spotlight_gamble":
			return prefix + "called the cameras in on a wounded %s — losses doubled too" \
				% String(d.get("wounded_part", "")).replace("_", " ")
		"stabilized":
			return prefix + "pulled %s back from bleeding out" % _combatant_name(String(d.get("saved", "")))
		"takedown":
			# R11 #14 v2 additive detail: friendly-fire and self-kills read
			# distinctly (the ruling counts them — "it's cinema"); the facts
			# (victim, friendly_fire, cause) come from the ledger entry.
			var victim_id := String(d.get("victim", ""))
			if victim_id == String(entry.get("actor", "")):
				return prefix + "took themselves out — their own killing blow"
			var line := "put %s down" % _combatant_name(victim_id)
			if bool(d.get("friendly_fire", false)):
				line += " — friendly fire, and the cameras loved it"
			return prefix + line
	return prefix + String(entry.get("type", ""))


## "finish_them" -> "FINISH THEM!" (the goal id is the only field the expiry
## event carries; the shout styling is PLACEHOLDER broadcast copy).
func _goal_shout(goal_id: String) -> String:
	return goal_id.replace("_", " ").to_upper() + "!"


func _combatant_name(id: String) -> String:
	var c: CombatantState = sim.combatants.get(id)
	return c.display_name if c != null else id


## Evidence type 8, "endured" — NOT event-based: derived here from final state.
## The survivor's body is the record: parts destroyed/disabled at verdict time.
func _verdict_endured(c: CombatantState, alive: bool) -> Dictionary:
	var lost: Array = []
	var part_keys: Array = c.parts.keys()
	part_keys.sort()
	for part_key: Variant in part_keys:
		var part: Dictionary = c.parts[part_key]
		if bool(part.get("destroyed", false)) or bool(part.get("disabled", false)):
			lost.append(String(part_key))
	var endured: Dictionary = {"survived": alive, "parts_lost": lost.size(), "parts": lost}
	if alive and lost.size() > 0:
		endured["line"] = "walked out carrying %d broken part%s: %s" % [
			lost.size(), "" if lost.size() == 1 else "s",
			", ".join(PackedStringArray(lost)).replace("_", " ")]
	return endured


## Highest-priority held tag mapped to an earned epithet (safe default if none).
func _epithet_for(held: Array) -> Dictionary:
	for key: String in EPITHET_PRIORITY:
		if held.has(key):
			return (EPITHET_BY_TAG[key] as Dictionary).duplicate(true)
	return {"name": "THE CONTENDER", "note": "earned a place on the wall"}


## Highest-priority held tag mapped to a crowd headline; stars from the peak band.
func _crowd_verdict_for(held: Array, band: String) -> Dictionary:
	var verdict_name := "THE UNDECIDED"
	for key: String in CROWD_VERDICT_PRIORITY:
		if held.has(key):
			verdict_name = String(CROWD_VERDICT_BY_TAG[key])
			break
	return {"name": verdict_name, "stars": int(STARS_BY_BAND.get(band, 1))}


## The boss = the combatant carrying a `network` part (the Incine-Dile's mycelium
## core; the key holds "network" stable pre- AND post-breach). The ONE boss
## lookup both view_verdict and view_encounter derive from — null when no boss.
## (This scan is controller-internal; consumers get the meaning via the views'
## is_boss / boss fields and never sniff part names themselves.)
func _boss_combatant() -> CombatantState:
	var ids: Array = sim.combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = sim.combatants[id]
		for part_key: Variant in c.parts.keys():
			if String(part_key).contains("network"):
				return c
	return null


## The verdict card's boss block. Reads the live `breached` flag off the shared
## _boss_combatant() lookup; PLACEHOLDER phase (breach = Phase 2 reached, F2).
func _verdict_boss() -> Dictionary:
	var c: CombatantState = _boss_combatant()
	if c == null:
		return {"name": "", "breached": false, "phase": 0, "note": "no boss on the table"}
	var breached: bool = c.breached
	return {
		"name": c.display_name,
		"breached": breached,
		"phase": (2 if breached else 1),  # PLACEHOLDER: breach = Phase 2
		"note": ("network exposed" if breached else "surface immune — no breach yet"),
	}


## Templated closing flavor keyed off outcome. PLACEHOLDER (R14) — the real line
## is a content/narrative concern once the whole-run win/lose system exists.
func _verdict_tagline(outcome: String) -> String:
	if outcome == "SURVIVED":
		return "CARRIED THREE OUT · BURNED FOR NONE · THE DOOR HELD"
	return "THE ESSENCE BROKE · THE CROWD GOT WHAT IT CAME FOR"


func save_game(save_name: String) -> bool:
	if sim == null:
		return false
	return saves.save_game(save_name, sim, command_log)


## Restores sim + log from a save. Returns false (soft) on missing/corrupt file.
func load_game(save_name: String) -> bool:
	var envelope: Dictionary = saves.load_game(save_name)
	if envelope.is_empty():
		return false
	sim = CombatSim.from_dict(envelope["snapshot"])
	command_log.assign(envelope.get("command_log", []))
	return true


# ------------------------------------------------------------------ RUN engine
# KAN-4 core (decision #31 — engine only, no scenes). The run walks ordered
# encounters; each encounter is its own CombatSim staged through the EXISTING
# start_combat/apply_command path, so every current view/signal keeps working
# mid-encounter untouched. Party state crosses encounters ONLY as serialized
# dictionaries (to_dict/from_dict splice — never live objects). Full model,
# command set and the persists/resets policy: simulation/run_state.gd.


## Starts a run: fresh RunState + run log, then the start_run command through
## the one run funnel. `party` = add_combatant specs (the roster); `encounters` =
## encounter defs (see RunState's header; data/demo_run.json is the canonical
## authored example). Passing static_data pins the tables for every encounter
## of the run (tests); {} loads through the DAL per encounter.
func start_run(run_seed: int, party: Array, encounters: Array, static_data: Dictionary = {}) -> Array[Dictionary]:
	run = RunState.new()
	run_command_log = []
	_run_static_data = static_data.duplicate(true)
	return apply_run_command({
		"type": "start_run", "seed": run_seed, "party": party, "encounters": encounters,
	})


## The one RUN-command funnel (mirror of apply_command): enriches end_encounter
## from the live sim, logs the FULL command (so a bare RunState can replay the
## run log with no sims), applies it to the reducer, re-emits every event on
## run_event, and executes the one side effect — staging the CombatSim when an
## encounter starts.
func apply_run_command(cmd: Dictionary) -> Array[Dictionary]:
	if run == null:
		push_error("GameController.apply_run_command before start_run")
		return []
	var full: Dictionary = cmd.duplicate(true)
	if String(cmd.get("type", "")) == "end_encounter":
		var payload: Dictionary = _end_encounter_payload()
		if payload.has("rejected"):
			var rejection: Dictionary = {
				"type": "run_command_rejected", "reason": String(payload["rejected"]),
			}
			run_event.emit(rejection)
			var rejected: Array[Dictionary] = [rejection]
			return rejected
		full.merge(payload, true)
	run_command_log.append(full.duplicate(true))
	var events: Array[Dictionary] = run.apply_command(full)
	for event: Dictionary in events:
		run_event.emit(event)
	for event: Dictionary in events:
		if String(event.get("type", "")) == "run_encounter_started":
			_stage_encounter(run.staging())
			break
	return events


## Read-only RUN view (mirror of the view_* family): RunState.view() — run seed,
## phase/outcome, encounter list state, roster with carried-damage summaries,
## offer beats, records — plus the LIVE combat_status() while an encounter is on.
func view_run() -> Dictionary:
	if run == null:
		return {}
	var out: Dictionary = run.view()
	if run.phase == "combat" and sim != null:
		out["combat"] = combat_status()
	return out


## Restores a run from serialized state (in-memory resume — the test/driver
## counterpart of load_game): run_snapshot = RunState.to_dict(); sim_snapshot =
## the mid-encounter CombatSim.to_dict() when resuming inside a fight ({}
## between encounters). Logs restart at the checkpoint — the history before it
## lives with the earlier save (DIRECTION #5: snapshot + log offset).
func restore_run(run_snapshot: Dictionary, sim_snapshot: Dictionary = {}, static_data: Dictionary = {}) -> void:
	run = RunState.from_dict(run_snapshot)
	run_command_log = []
	_run_static_data = static_data.duplicate(true)
	if not sim_snapshot.is_empty():
		sim = CombatSim.from_dict(sim_snapshot)
		command_log = []
		_combat_ended_emitted = bool(combat_status().get("over", false))


## Persists the live run to disk (KAN-4 wave 2e — the disk counterpart of
## restore_run; SaveManager owns the file). The envelope carries the RunState +
## the FULL run log, plus the in-flight encounter's CombatSim + its log tail
## when one is live — between-encounters saves carry an empty sim block (the
## next encounter is re-derived from run state, exactly like restore_run).
## false when no run is live (mirror of save_game's sim==null guard).
func save_run(save_name: String) -> bool:
	if run == null:
		return false
	var live: bool = run.phase == "combat" and sim != null
	return saves.save_run(save_name, run, run_command_log,
		sim if live else null, command_log if live else [])


## Restores a run from disk through the EXISTING restore_run path, then
## restores both logs from the envelope so the next save keeps the full
## history (the load_game idiom). Soft fail: false with saves.last_error set
## on a missing/corrupt/non-run/foreign-version file — the live session stays
## untouched, no partial restore. `static_data` pins the tables for the
## restored run's future encounters (tests); {} loads through the DAL.
func load_run(save_name: String, static_data: Dictionary = {}) -> bool:
	var envelope: Dictionary = saves.load_run(save_name)
	if envelope.is_empty():
		return false
	restore_run(envelope["run_snapshot"], envelope.get("sim_snapshot", {}), static_data)
	run_command_log.assign(envelope.get("run_command_log", []))
	command_log.assign(envelope.get("sim_command_log", []))
	return true


## end_encounter enrichment: the honest capture off the LIVE sim. Rejects
## (without logging) when no fight is staged or the fight is not over — the run
## never records an outcome the sim does not actually show.
func _end_encounter_payload() -> Dictionary:
	if sim == null:
		return {"rejected": "no_active_combat"}
	var status: Dictionary = combat_status()
	if not bool(status.get("over", false)):
		return {"rejected": "encounter_not_resolved"}
	var carried: Dictionary = {}
	var camera_used: Dictionary = {}
	var tags_held: Dictionary = {}
	var ids: Array = sim.combatants.keys()
	ids.sort()
	for id: Variant in ids:
		var c: CombatantState = sim.combatants[id]
		if c.team != "party":
			continue
		carried[String(id)] = c.to_dict()
		if int(sim.hype.camera_calls_used.get(String(id), 0)) > 0:
			camera_used[String(id)] = int(sim.hype.camera_calls_used[String(id)])
		if not (sim.tags.held.get(String(id), {}) as Dictionary).is_empty():
			tags_held[String(id)] = (sim.tags.held[String(id)] as Dictionary).duplicate(true)
	return {
		"outcome": String(status.get("outcome", "LOSS")),
		"carried": carried,
		"camera_calls_used": camera_used,
		"tags_held": tags_held,
		"hype_meter": int(sim.hype.meter),
	}


## Executes RunState.staging(): a fresh CombatSim on the derived encounter seed,
## every combatant added through the EXISTING command funnel (combatant_added
## flows to listeners exactly as today), then the serialized-state hand-off —
## carried members, the B9 spent-stack ledger, held tags and the #32
## chain-retained hype meter are spliced into the sim's own to_dict snapshot
## and the sim is rebuilt via from_dict (the public serialization path; no live
## objects cross encounters). The encounter's
## command log restarts empty at the spliced checkpoint: the initial snapshot is
## re-derivable from the RUN log (DIRECTION #5), and in-combat commands append
## from there.
func _stage_encounter(staging: Dictionary) -> void:
	start_combat(int(staging.get("sim_seed", 0)), _run_static_data)
	# KAN-5 (wave 3d): the encounter's authored arena stages FIRST, so every
	# spawn below is validated against its bounds/walls (staging rejection).
	# {} = no arena block on the def = the unbounded legacy combat.
	var arena_cfg: Dictionary = staging.get("arena", {})
	if not arena_cfg.is_empty():
		apply_command({"type": "set_arena", "arena": arena_cfg})
	for spec: Dictionary in staging.get("adds", []) as Array:
		apply_command({"type": "add_combatant", "combatant": spec})
	var carried: Dictionary = staging.get("carried", {})
	var camera_used: Dictionary = staging.get("camera_calls_used", {})
	var tags_held: Dictionary = staging.get("tags_held", {})
	var hype_start: int = int(staging.get("hype_start", 0))
	if not (carried.is_empty() and camera_used.is_empty() and tags_held.is_empty() and hype_start == 0):
		var snapshot: Dictionary = sim.to_dict()
		var ids: Array = carried.keys()
		ids.sort()
		for id: Variant in ids:
			var combatants: Dictionary = snapshot["combatants"]
			if not combatants.has(String(id)):
				continue
			var carry: Dictionary = (carried[id] as Dictionary).duplicate(true)
			# The staging position wins (the carry was position-sanitized).
			carry["position"] = (combatants[String(id)] as Dictionary).get("position", [0, 0])
			combatants[String(id)] = carry
			# Keep the tick-start snapshot honest for the spliced member (the
			# same fields _snapshot_entry derives, computed off the carry).
			(snapshot["tick_snapshot"] as Dictionary)[String(id)] = {
				"position": (carry["position"] as Array).duplicate(),
				"alive": bool(carry.get("alive", true)) and not bool(carry.get("removed_from_play", false)),
				"exposed": false,
				"helpless": not (carry.get("bleed_out", {}) as Dictionary).is_empty() \
					or bool((carry.get("statuses", {}) as Dictionary).get("incapacitated", false)),
				"overwhelmed": false,
			}
		var cam_ids: Array = camera_used.keys()
		cam_ids.sort()
		for id: Variant in cam_ids:
			((snapshot["hype"] as Dictionary)["camera_calls_used"] as Dictionary)[String(id)] = int(camera_used[id])
		var tag_ids: Array = tags_held.keys()
		tag_ids.sort()
		for id: Variant in tag_ids:
			((snapshot["tags"] as Dictionary)["held"] as Dictionary)[String(id)] = (tags_held[id] as Dictionary).duplicate(true)
		# Hype-chain retention (decision #32, supersedes the per-encounter hype
		# reset): a chained encounter OPENS with RunState.staging()'s retained
		# meter, spliced through the same public serialization path as the carry
		# (never a live-object poke). The band is re-derived from HypeEngine's
		# own BANDS floors (highest-first) so views read consistently from tick
		# 0. hype_start is derived purely from LOGGED run state (the previous
		# end_encounter's recorded meter + the serialized chain index), so a
		# replay of the run log stages the identical meter; a chain-opening
		# encounter (hype_start 0) leaves the fresh engine untouched.
		if hype_start > 0:
			var hype_block: Dictionary = snapshot["hype"]
			hype_block["meter"] = hype_start
			for entry: Variant in HypeEngine.BANDS:
				if hype_start >= int((entry as Array)[1]):
					hype_block["band"] = String((entry as Array)[0])
					break
		sim = CombatSim.from_dict(snapshot)
	command_log = []
