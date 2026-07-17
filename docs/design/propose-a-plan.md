# Propose-a-Plan — party planning system (design sketch)

*Status: **PROPOSED** (owner-directed 2026-07-16; shape drafted for review). Owner's
intent, verbatim gist: propose a plan to X teammates who choose to participate; the plan
is a flowchart of things about to happen; people propose what they want to do; each
votes y/n per step; the result is a **prefired actions run that stops when the plan
deviates**; **backup plans** to switch to when parts fail; later, a **Tactician trait**
that lets you propose plans using other people's skills.*

## The idea in one line

Turn the party huddle into a mechanic: agree on a flowchart, let it fire itself — and
let reality interrupt it.

## How it works (player-facing)

1. **Propose.** Any party member opens a plan and invites teammates; joining is opt-in.
2. **Build the flowchart.** Steps are declarations-to-be (moves, attacks, combos (R15),
   item handoffs, waits) with **explicit assumptions** per step ("the roach is still on
   the bridge," "Nikita is primed," "B reaches the ledge"). Participants add/edit steps
   for their own characters; anyone can propose steps for anyone (see Tactician for who
   can *finalize* others' steps).
3. **Vote.** Each participant y/n's each step; a step fires only with the consent of
   its actor (always) plus the plan's vote rule ⟨PROPOSED: simple majority of
   participants; actor veto absolute⟩.
4. **Run.** The plan **auto-declares** each member's agreed actions tick by tick — a
   prefired run. No menus mid-execution; the party performs the choreography.
5. **Deviate → stop.** Before each step fires, its assumptions are checked against live
   state. Any failure **halts the plan** (control instantly back to players) — or, if a
   **backup plan** is linked to that failure point, execution switches to the backup's
   flowchart instead.
6. **Backups.** Any step can carry a fallback edge → an alternate sub-plan ("if the
   breach doesn't open: scatter to marks and re-group"). Backups are built/voted the
   same way, before the run starts.

## Why it fits this game specifically

- **The clock wants it:** in co-op declare-windows, pre-agreed actions declare instantly
  — plans are the pacing answer for coordinated play without voice chat. In solo, a
  lite version is "program the party's next Clock" (ATB-style scripting with deviation
  stops) — useful even for one player controlling three characters.
- **The broadcast wants it:** a plan is a *called shot*. The announcer can show the
  audience the flowchart (dramatic irony — the crowd knows the play; the enemies
  don't); a plan that fires end-to-end earns a hype **choreography multiplier**
  ⟨PROPOSED, stacks with R15's combo bonus⟩; a plan collapsing at step 2 is also
  content. Patron gods with strategy domains can carry plan-shaped favor conditions.
- **The companions want it:** NPC party members can **vote in character** ⟨PROPOSED⟩ —
  Sasha votes no on any step that puts her far from an exit; War Nikita rejects
  defensive steps; affection/trust can widen what they'll agree to. Plan votes become a
  characterization surface, not just UI.

## Architecture (clean, no sim changes)

- **Plans live ENTIRELY in the controller layer** — a plan is data: a DAG of steps
  `{actor, action(declaration payload), assumptions[], vote_state, fallback_edge?}`.
  The **plan runner** sits beside the clock driver: each tick it evaluates the current
  step's assumptions against (state, events), then either feeds the declarations,
  halts, or follows a fallback edge. The sim remains a pure command reducer — same
  pattern as clock drivers and the director.
- **Assumptions = declarative predicates** over the same event/state vocabulary the
  favor conditions and hype engine already read (positions, alive/exposed states,
  primes, condition tiers, item possession). One predicate library serves all three.
- **Determinism/replay:** plan proposal/votes/switches are logged commands
  ⟨PROPOSED: as director-style meta-commands⟩ so replays can render the flowchart and
  the moment it broke — the broadcast overlay falls out for free.
- **Co-op sync:** plans piggyback the command stream; no new net surface.

## The Tactician trait (later, owner-flagged)

Gates the *authoring power*, not the feature: anyone can propose for themselves; a
**Tactician** can propose steps **using other people's skills** (slot allies' abilities
into the flowchart pre-vote, see their requirements/primes while planning) ⟨PROPOSED:
and eventually pre-authorize backup switching without a re-vote — the shot-caller
fantasy⟩. Natural home: the skills passover / traits track (epithet vocabulary already
includes tactician-shaped words). NPC-heavy parties make it a leadership progression.

## Scope & placement ⟨PROPOSED⟩

- **v1 (slice+ / KAN-4):** solo-lite plan runner — script your own party's next Clock
  with assumptions + halt-on-deviation; single linear plan, one backup edge. Proves the
  runner and the UX vocabulary.
- **Co-op (Stage 1.5):** propose/join/vote flow across clients.
- **KAN-6:** the flowchart overlay + broadcast rendering (mockup gate applies).
- **KAN-7:** hype multiplier, patron plan-conditions, NPC in-character voting.

## Open questions (owner)

- **Q1** — Vote rule: majority + absolute actor-veto (recommended), or unanimous?
- **Q2** — Deviation default: halt-everyone (recommended for drama/clarity) or
  halt-only-affected-actors (plans partially survive)?
- **Q3** — Plan authoring cost: free out-of-combat + a Moment cost to (re)plan
  mid-combat ⟨recommended⟩, or always free?
- **Q4** — NPC in-character voting: in from v1 (it's characterization gold) or
  co-op-first?
- **Q5** — Tactician: a trait, a skill line, or an epithet-earned title?
