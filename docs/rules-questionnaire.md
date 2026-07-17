# Rules Questionnaire — every fact that lives in the owner's head

**How to use:** for each question, fill the two lines under it (edit this file directly, or
answer in chat by number — e.g. "Q7: app rule is right; as-is").
- **TTRPG:** how your table actually runs it today.
- **Decision:** `as-is` (digital copies the table) / `tailor: <how>` (digital diverges
  deliberately) / `dump` (doesn't exist in the digital game).

Where the sim already guessed, the assumption is noted as `[assumed: …]` with its ruling id
(`docs/rules-addendum.md`). An answer that contradicts an assumption wins — I'll update the
addendum + engine. Questions marked ⚙ are already implemented one way, so answering them
early prevents rework.

---

## A. Character creation & advancement

**Q1.** ~~7 vs 5 points~~ **Mostly answered by the compendium:** 7 across Body + 7 across
Core is confirmed (the party's creation stats sum exactly 7+7). Remaining sliver: why does
the app default `bonusPoints {body: 5, core: 5}` — stale default to fix, or does base-1 per
trait + 5 = the same 7-point math in different clothes?
- TTRPG:
- Decision:

**Q2.** What actually triggers a level-up at your table? (All five characters are level 6 —
what were the six occasions?) `[assumed R6: game-awarded at authored milestones]` ⚙
- TTRPG:
- Decision:

**Q3.** What does one level grant besides 1 level point — HP, skill unlocks, anything?
`[assumed R6: exactly 1 level point, nothing else]` ⚙
- TTRPG:
- Decision:

**Q4.** Achievement rewards can give "+1 to stat": does that add to `base`, `bonus`, or
`levelBonus`, and is it capped?
- TTRPG:
- Decision:

**Q5.** What trait totals do you *intend* endgame characters to reach? (Stat caps trigger at
10/12/15/20+ — reachable by design, or aspirational?)
- TTRPG:
- Decision:

**Q6.** Can players respec — unlearn a skill and refund points outside of level-down?
- TTRPG:
- Decision:

## B. Skills — effects & growth (you flagged an unfinished passover)

**Q7.** Skill levels 1–4: most exported skills only define effects at levels 5–6. What does
raising a skill from 1→4 actually change at your table (nothing? reliability/scope by GM
feel? a default numeric bump)?
- TTRPG:
- Decision: **RULED 2026-07-17 (R19): skills 0-10; 0 untrained, 1 effect works, 1-5 stat scaling, 6-10 generalize the function (Explosion example in addendum R19).**

**Q8.** At a level-5+ threshold, does the player **choose** between "upgrade" and "mutate"?
Where do mutation options come from (GM-authored per skill, player pitch, list)?
- TTRPG:
- Decision:

**Q9.** Skill **consuming** (merging skills at the Skill Gemstone): give one real example of
how it worked or should work — inputs, output, what's lost.
- TTRPG:
- Decision:

**Q10.** Obtaining requirements ("unlock by doing X"): in the digital game, should skills
auto-reveal when the sim detects the deed (achievement-style), or stay GM/director-granted?
`[leaning: auto-detect for the ~30 detectable ones]`
- TTRPG:
- Decision:

**Q11.** Passive skills (7 in the export): always-on, or do any need activation/upkeep?
- TTRPG:
- Decision:

**Q12.** Strong Strike's stat is "Weapon Dependant": which trait funds and levels it?
`[the app resolved it to physique]`
- TTRPG:
- Decision:

**Q13.** ~~Capacity vs cap~~ **Answered by the compendium** (§7.2 instance model): same
concept. Closed — `as-is`.

**Q14.** Camouflage lists **three** stats (reflexes/mind/charm). Is 3-stat a real pattern
the schema must support, or a data quirk? `[port dropped the third stat — charm]` ⚙
- TTRPG:
- Decision:

**Q15.** For multi-stat skills, is the skill's max level bound by the *lowest* contributing
trait, or can one high trait carry it?
- TTRPG:
- Decision:

**Q16.** ~~cooldowns~~ **RULED (2026-07-14, = NQ1): no cooldowns — priming instead.**
Skills gate on preparation conditions (channels, stacks, stances); high-tier items may skip
specific primes. Cooldown-texted skills (Tactical Roll, Acrobatic Save, "-4 Moment
cooldown" thresholds) get re-expressed as primes during your skill passover. Closed at the
rules level; content pass open.

## C. Combat timing — validating the PROVISIONAL rulings ⚙

**Q17.** When someone declares a normal 1-Moment attack at your table, can the target do
anything about it before it lands? `[assumed R2: no — instants resolve same tick; only
windups (2+ Moments) are dodgeable by moving away]`
- TTRPG:
- Decision:

**Q18.** The Incinedile notes show a d6 **Dodge Threshold** — was that boss-only, or do
other enemies/players dodge somehow? `[assumed R2: boss-ability pattern, not universal]`
- TTRPG:
- Decision:

**Q19.** How much can one character actually do within a single Moment at your table?
`[assumed R3: one scheduled action + one 0-cost action + one reaction]`
- TTRPG:
- Decision:

**Q20.** Reactions (Counter-Surge, Tactical Roll, Brace): when one fires, what does it cost
the reactor? `[assumed R2: resolves immediately, its Moment cost delays their next
scheduled action; max one reaction per tick]`
- TTRPG:
- Decision:

**Q21.** How does **Shock go down**? The book defines tiers 1–4 but no recovery. (Gap found
after the addendum — the engine currently never decays Shock within a combat.)
- TTRPG:
- Decision: **RULED 2026-07-17: no shock decay in combat; combat-end reset only. R13 approved.**

**Q22.** Exhausted's Moment-cost increase: by how much, at your table? `[assumed R4
PROVISIONAL: T1 +1 on 2+-cost actions, T2 +1 on all, T3 all actions Forced-Body]`
- TTRPG:
- Decision:

**Q23.** Does **Prone** exist at your table (several skills reference it)? What does
standing up cost? `[assumed R7: Exposed while prone, 1 Moment to stand]`
- TTRPG:
- Decision:

**Q24.** Grapples: how did Pressure Hold's "inflict Suffocation" actually play out — did
anything limit it against big enemies? `[assumed R9: Physique-gated initiate, 2-Moment
escape, bosses immune to grapple-Suffocation]`
- TTRPG:
- Decision:

**Q25.** Ranged weapons at the table: does anyone actually track magazines/ammo counts and
reload Moments, and what does firing a 3-RPM weapon cost/deal in practice? `[assumed R8:
1 Moment fires up to RPM rounds, listed damage per round, magazine field, reload 2 Moments]`
- TTRPG:
- Decision:

**Q26.** When requirements are NOT met and someone swings anyway: at your table is the
result just the Forced-Action roll, or is the action also weaker? `[assumed R10
PROVISIONAL: effect halved + Forced Action]`
- TTRPG:
- Decision:

## D. Conditions & healing

**Q27.** How does HP actually come back at your table — between fights, overnight, at the
Lounge, via items? (The book only says in-combat recovery is rare.) `[assumed R10: none in
the field except explicit items/skills; full at Lounge]` ⚙
- TTRPG:
- Decision:

**Q28.** Do you really advance **every** active condition at each Clock reset, or in
practice just Bleeding? `[assumed R4: universal advancement]` ⚙
- TTRPG:
- Decision:

**Q29.** Treatments (bandages, antitoxins): limited uses per item? Moment cost to apply to
self vs ally?
- TTRPG:
- Decision: **RULED 2026-07-17: healing items cost a Moment to apply; NO item regenerates HP (items treat/delay conditions only); HP recovery deliberately scarce.**

**Q30.** Has anyone self-cauterized (Burn T1 to stop bleeding)? What did it cost them?
`[assumed R4 PROVISIONAL: HP damage + Shock T1]`
- TTRPG:
- Decision:

**Q31.** The five poison **types** (neuro/hemo/myo/pneumo/cyto): what mechanically differs
between them at your table?
- TTRPG:
- Decision:

**Q32.** How is **Infected** cured in practice (besides Burn T2)?
- TTRPG:
- Decision:

**Q33.** ~~Dissolution~~ **Answered by the compendium** (§2.8): sources = explicit only
(demonic-noble presence, environment); embrace = ghoul (persists in story), escape = scar
(one emotion amplified near demons). Matches R5's removed-from-play model. Closed — `as-is`.

## E. Exposure, audience & the metagame (feeds the spectacle engine + Stage-2 design)

**Q34.** Viewers: which concrete events move the number at your table, by roughly how much,
and does it decay?
- TTRPG:
- Decision:

**Q35.** What converts a Viewer into a **Follower** in practice?
- TTRPG:
- Decision:

**Q36.** How many **Patrons** have players earned so far, and what specifically converted
each one?
- TTRPG:
- Decision:

**Q37.** Camera Call: exact scope of "Viewership, Followers, and Patrons gained or lost
from the called upon target are doubled" — and is calling the camera on *yourself* legal?
- TTRPG:
- Decision:

**Q38.** Goals (crowd challenges): how often do they appear, who invents them at the table,
and what's a typical reward?
- TTRPG:
- Decision:

**Q39.** Directives: frequency, and what actually happens when players refuse one (the SAG
Dispute tag implies refusal is playable)?
- TTRPG:
- Decision:

**Q40.** Confirm the reward split `[assumed R10 PROVISIONAL: Directives pay loot;
only Goals that convert Patrons pay Patron Tokens; Boss-Token→Patron-Token exchange cut]`.
- TTRPG:
- Decision:

**Q41.** Narrative Tokens: 2–3 real examples of how they were spent at your table (this
designs their digital replacement — currently slated for redesign/cut in v1).
- TTRPG:
- Decision:

**Q42.** Tags: all 100 have empty effect fields in the DB. Do tags currently DO anything
mechanical at your table (loot bias? triggers?), or are they identity markers the GM plays
by feel? What SHOULD a tag do in the digital game?
- TTRPG:
- Decision:

**Q43.** What does audience size materially change for the players — reward frequency,
loot quality, anything numeric you've been running?
- TTRPG:
- Decision:

## F. Enemies & encounter design (feeds content pipeline + KAN-4 AI)

**Q44.** When you stat a new enemy, what's your internal heuristic for body-part HP and
damage numbers? (Roach-dog=1HP bite-1; roach elite parts 5–15 dmg 2; boss parts 7–50 dmg
2-3 — is there a budget rule, or feel?)
- TTRPG:
- Decision:

**Q45.** Do enemies obey Moment costs strictly (schedule on the same clock), and how many
actions does a boss get per Clock in practice?
- TTRPG:
- Decision:

**Q46.** Mobs "die in a single meaningful blow": literally 1 HP, or any-hit-kills
regardless of damage?  `[seeded Roach-dog at 1 HP]` ⚙
- TTRPG:
- Decision:

**Q47.** Typical encounter shape: how many mobs/elites per fight for your party of 5, and
should the digital slice (2 contestants) scale that down linearly?
- TTRPG:
- Decision: **RULED 2026-07-17: table party of 5 handled 12/room easily; assume party of 3 handles ~12/room as tuning baseline.**

**Q48.** What makes a **Super Boss** mechanically different from a Boss beyond bigger
numbers?
- TTRPG:
- Decision:

## G. Items & economy

**Q49.** Is there currency? How does the store ("Sup, nerds!") actually transact — what do
players pay with?
- TTRPG:
- Decision:

**Q50.** Loot boxes: when one opens, how do you generate contents (roll table, curated,
vibes)? What does each tier (Bronze→Godly) roughly contain?
- TTRPG:
- Decision:

**Q51.** Equipment slots: how many worn pieces can one character have (seen: Hands, Legs,
Face, Torso, Mouth, Utility) — is there a slot list, and can two same-slot items stack?
- TTRPG:
- Decision:

**Q52.** ~~Item tiers~~ **Answered by the compendium** (§3.2): tier = modifier slots
(Crude 0/0 → Exceptional 2/2 prefix/suffix) + modifier-tier ACCESS gating. Closed — `as-is`
unless you've changed it since May.

**Q53.** ~~Affixes~~ **Mostly answered** (§3.2): slots per tier, access gating, extraction
friction ladder. Remaining sliver: do dropped/looted items ever come pre-affixed, or is the
Enchantment Altar the only application path?
- TTRPG:
- Decision:

**Q54.** Item uses/charges: do used-up items refill (where/cost) or vanish?
- TTRPG:
- Decision:

**Q55.** Hands accounting: whip + shield? Two one-handed weapons? What have you allowed?
- TTRPG:
- Decision:

## H. World, exploration & environment (KAN-5 prep)

**Q56.** Outside combat, does the Clock run at all — do conditions tick while exploring?
`[assumed DIRECTION sketch: coarse ambient clock, conditions keep ticking]` ⚙
- TTRPG:
- Decision:

**Q57.** Terrain effects you've actually used: Sludge, Flammable, water, difficult terrain,
smoke — the full list and what each does mechanically.
- TTRPG:
- Decision:

**Q58.** Stealth: how does sneaking work at your table (detection, breaking stealth, what
Reflexes gates)?
- TTRPG:
- Decision:

**Q59.** Fall damage / environmental damage numbers — any precedent?
- TTRPG:
- Decision:

**Q60.** Typical room/zone size in spaces, and how far apart encounters are (for hex-map
scale).
- TTRPG:
- Decision:

## I. Races & bodies

**Q61.** Filipe the sea lion: what body parts + HP did you actually give him? (Real example
= the Animal-race template for the digital game.)
- TTRPG:
- Decision: **DEFERRED 2026-07-17: animal part layouts need a dedicated sitting.**

**Q62.** XQUEZ/T is race "AI": what body did it get, and does an AI/robot take Shock,
bleed, get infected — which conditions apply to machines?
- TTRPG:
- Decision: **OBSOLETE 2026-07-16 (R16): robot race removed.**

**Q63.** Severed/destroyed parts: what's the recovery path (Surgeon's Table? prosthetics?
permanent)?
- TTRPG:
- Decision:

**Q64.** Besides Physique-over-10, does anything raise a body part's max HP (armor, race,
achievements)?
- TTRPG:
- Decision:

## J. Lounge & downtime (KAN-7 prep)

**Q65.** Which Lounge modules have DEFINED effects at your table today (what does the
Kitchen/Farm/Forge actually do mechanically)?
- TTRPG:
- Decision:

**Q66.** Upgrade Tokens: what do they actually buy (every listed unlock costs Boss Tokens)?
- TTRPG:
- Decision:

**Q67.** Downtime structure between runs: fixed activities/slots, freeform, time limits?
- TTRPG:
- Decision:

## K. Digital-only decisions (no table precedent needed — your call)

**Q68.** Slice party: 2 premade contestants controlled by one player `[per review-4 §5]` —
OK, or do you want your five campaign characters as the premades?
- Decision: **RULED 2026-07-17: slice + premades approved (player OC + Sasha & Nikita recruitment, party of 3). (Owner wrote '58' — content unambiguously matches this question.)**

**Q69.** Friendly fire: on (spectacle!) or off?
- Decision: **RULED 2026-07-17: friendly fire ON.**

**Q70.** Death in digital co-op: full permadeath + Ascension (as designed) from day one, or
softer for the slice (restart at checkpoint only)?
- Decision: **RULED 2026-07-16 (R17): run types — softcore respawn / hardcore permadeath / Forsaken hardcore.**

**Q71.** Declare-window length for the co-op tick driver (DIRECTION sketch suggests
3–5s/Moment): starting value?
- Decision:

**Q72.** The addendum's remaining PROVISIONAL bundle — R2 miss model, R3 cap numbers, R4
Burn-Shock, R8 RPM defaults, R9 grapple gates, R10 requirements-halving, R11 items 1–12:
approve wholesale pending playtest, or itemized review? (Answering the C/D questions above
already covers most of them.)
- Decision:

---

## L. New questions raised by the Master Compendium (2026-07-14)

**NQ1.** ~~cooldowns~~ **RULED (2026-07-14): no cooldowns — priming instead.** Powerful
skills require preparation conditions (channels, stacks, stances) before use, not
wait-after-use timers; high-tier items may skip specific primes. Priming vocabulary gets
designed during the owner's skill passover (cooldown-texted skills re-expressed then).
Recorded in addendum R3 + DIRECTION. Closed at the rules level; content pass open.

**NQ2.** ~~breach wording~~ **RULED (2026-07-14): single hit.** The DB's "single turn" was
tuning wording. Seeded accordingly. Closed.

**NQ3.** ~~phase count~~ **RULED (2026-07-14): DB is correct — 6 phases** (fight,
explosion, fight, explosion, fight, large explosion). Seeded accordingly. Closed.

**NQ4.** ~~party size~~ **RULED (2026-07-14): no max party in the video game.** Live-party
count is a TTRPG concern only. Recruitment is the economy: better allies are a hassle to
recruit, worse ones are short-lived — "a thousand grunts if you can use them well."
Per-fight bounds come from arena deployment + exhaustion, never a cap. Recorded in
DIRECTION. Closed.

**NQ5.** Tutorial HP tuning (compendium open item #7): you were weighing boosting all
body-part HP vs easier max-HP acquisition, because it's "hard to hurt without killing."
Any decision since? (This directly affects the digital slice's damage feel — 2-damage
weapons one-shot 2-HP arms.)
- Ruling:

**NQ6.** XQUEZ/T tank kit: finalize Intercept / Iron Stance as written in §3.3, or revise?
(They'd become seed skills + the first reaction-skill test cases.)
- Ruling:

**NQ7.** Affliction-resistance sourcing was "deliberately parked" — park it in the digital
game too, or want a proposal?
- Ruling:

---

*When answered: I fold every answer into `docs/rules-addendum.md` (promoting/demoting
rulings), update the engine + tests to match, and log durable facts into
`_workflow/learnings.jsonl`. Partial answers are fine — answer what's quick, mark the rest
"later".*
