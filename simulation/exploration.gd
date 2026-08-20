class_name Exploration
extends RefCounted
## R34 — FREE-FORM EXPLORATION + CONTACT DETECTION (owner rulings 2026-08-19;
## the ruling text lives in docs/rules-addendum.md R34 + the R29 amendment).
## Pure, static, stateless (MODEL — no Godot node deps, no rng, no state);
## CombatSim owns the phase field, every mutation and the per-command sweep.
## The split mirrors simulation/stealth.gd: pure queries here, policy there.
##
## THE RULED MODEL and exactly what ships of it:
##  * "Exploration is FREE-FORM, not turn-based. Out of combat there is no
##    Clock, no Moment order, and no turn to end — the party walks freely;
##    movement costs nothing; the clock starts on contact." -> the sim carries
##    an explicit PHASE ("combat" | "exploration"). DEFAULT = combat, and the
##    key serializes only while it is NOT combat, so every legacy save, hash
##    and CI harness is byte-identical to the pre-exploration engine.
##    FREE-FORM means "no Moment/Clock accounting", NOT "outside the command
##    stream": an exploration phase is still a sequence of LOGGED commands and
##    state stays a pure function of (seed, ordered command log). The clock
##    simply never advances while it runs (advance_tick is rejected).
##  * "exploration-time actions (opening doors, picking locks, voicebox
##    throws, scouting) are free out of combat and only regain their Moment
##    costs once the clock is running" -> in exploration the move / door /
##    stealth commands charge NO free-action slot, NO Moments and NO tick.
##    The v1 permitted set is exactly those three (CombatSim documents the
##    reject list + the named gaps: the voicebox throw and the lockpick are
##    resolver-scheduled declares and stay out of this slice).
##  * "CONTACT IS SIGHT OR HEARING. The clock starts the moment either sense
##    lands: an enemy sees a contestant (R20 sight, R30 front arc, concealment
##    respected) or hears one (R20 hearing/loudness)." -> first_contact()
##    below IS that predicate, composed entirely out of the R20/R30 substrates
##    (Stealth.sees / Stealth.derive_noises / Stealth.hears — nothing about
##    detection is re-implemented here) and rng-FREE (neither ruled sense
##    authors a roll, so none was invented).
##  * "The mockup's 'ENTER > <route>' remains the deliberate way in; contact is
##    the involuntary one." -> the phase command's combat side is the
##    deliberate entry: it emits combat_started {reason: "deliberate"} and NO
##    contact event.
##
## THE DIRECTION OF CONTACT (a documented reading, flagged not hidden). R34's
## own examples are both ENEMY-detects-contestant ("a contestant walking into
## a mob's cone and a mob hearing a smashed door are the same event"), so the
## DETECTOR is always the AI-controlled side and the DETECTED is always a
## player-controlled body. A contestant who SEES a mob does not start the
## fight — that is the stealth design space R20 pays for (you may watch a
## guard and walk around him). If the owner rules the mirror direction later,
## it is one loop in first_contact().
##
## WHY HEARING DOES NOT REUSE THE COMBAT NOISE FILTER (the one real seam
## decision). CombatSim._noise_checks consumes a noise row only while its
## source is still HIDDEN, because inside combat everyone is DEFAULT-DETECTED
## and a visible actor's noise is redundant with detection itself. Out of
## combat that premise is FALSE — detection is precisely the open question —
## and R34 names the case verbatim: "a door heard through a wall can pull a
## room onto you before you enter it" (nobody smashing a door in exploration
## is stealthed). So contact consumes EVERY derived row from a hostile
## player-side source, hidden or not. The alerted/investigate machinery is
## untouched: it keeps its own combat discipline and runs alongside.
##
## NUMBERS: none authored here. Sight range, the front arc, conceal radius and
## the loudness table are all R20/R30 values (PLACEHOLDER, R14 family) read
## straight off simulation/stealth.gd.

const PHASE_COMBAT: String = "combat"
const PHASE_EXPLORATION: String = "exploration"

## The free-form walk's routing budget (see CombatSim._explore_move). R34
## prices exploration movement at NOTHING, so the only job left for a budget
## is to bound the planner: Pathing's own expansion cap is the honest ceiling
## — past it the planner falls back to the greedy walk and an unreachable ask
## is rejected honestly rather than hanging. Not a game number.
const WALK_BUDGET: int = Pathing.MAX_EXPANSIONS


## THE CONTACT PREDICATE (R34). Returns {} when nobody has made contact, else
## {"by": detector_id, "target": detected_id, "sense": "sight"|"hearing"}.
##
## Verbatim: for each AI-controlled combatant D in sorted-id order that can
## act (dead / removed / helpless makes no contact — the Stealth.sees gate,
## mirrored for hearing so a fainted guard neither watches nor listens):
##   SIGHT   — the first non-AI combatant T in sorted-id order with
##             Stealth.sees(D, T, arena, tick): hostility, the R30 FRONT ARC,
##             2 x Mind range, the R20/S8 conceal radius cap and hex-line LOS
##             through walls + CLOSED doors are all that query's own gates.
##   HEARING — else the first noise row N of THIS command's batch (batch
##             order — the freshest sound loses to the earliest here on
##             purpose: contact is a threshold, not a tracked sound, and the
##             earliest audible row is the one that actually landed first)
##             whose source is a non-AI combatant hostile to D, with
##             Stealth.hears(D.position, N.position, N.loudness).
## Sight is tested before hearing for the same detector because sight is the
## stronger sense (it LOCATES the contestant; hearing only places a sound).
## Deterministic — sorted ids throughout, first match wins. ZERO rng.
static func first_contact(combatants: Dictionary, arena: Arena, tick: int, noises: Array[Dictionary]) -> Dictionary:
	var ids: Array = combatants.keys()
	ids.sort()
	for detector_id: Variant in ids:
		var detector: CombatantState = combatants[detector_id]
		if not EnemyAI.is_ai_controlled(detector):
			continue
		if not detector.can_act(tick):
			continue
		for target_id: Variant in ids:
			var target: CombatantState = combatants[target_id]
			if EnemyAI.is_ai_controlled(target):
				continue
			if Stealth.sees(detector, target, arena, tick):
				return {"by": detector.id, "target": target.id, "sense": "sight"}
		for noise: Dictionary in noises:
			var source: CombatantState = combatants.get(String(noise.get("source", "")))
			if source == null or EnemyAI.is_ai_controlled(source):
				continue
			if detector.team == "" or detector.team == source.team:
				continue  # hostile sources only (the Stealth.sees team predicate)
			if Stealth.hears(detector.position, noise.get("position", Vector2i.ZERO), int(noise.get("loudness", 0))):
				return {"by": detector.id, "target": source.id, "sense": "hearing"}
	return {}
