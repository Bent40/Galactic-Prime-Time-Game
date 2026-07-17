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

## How it works (owner-concretized 2026-07-16)

1. **Propose.** Any party member opens a plan and invites teammates; joining is opt-in.
2. **Build the flowchart.** Steps are declarations-to-be (moves, attacks, combos (R15),
   item handoffs, waits) with **explicit assumptions** per step. The proposer drafts
   steps — including steps for other characters.
3. **Consent, per step, with written reasons.** Every participant marks each step
   **V / X**. Rejection can be for ANY reason; players write theirs, NPCs generate
   theirs in character. **A rejected step turns red, deletes, and lands on the
   REFUSAL LIST with its reason** — the visible planning aid you replan around.
4. **Veto semantics (RULED):** an acting player or NPC rejecting an action proposed
   *for them* is an absolute veto — "not gonna be done under whatever conditions they
   decide, stated in the reason." The reason carries the conditions (e.g. *"Player
   should stay behind as ranged dealer; npc2 should do this instead"*). A rejection
   from a participant NOT used by the step is a flagged objection ⟨PROPOSED:
   non-binding, visible on the chart⟩.
5. **NPCs never propose — they substitute or reject.** An NPC called to act can
   counter-offer within the call's intent: told "attack melee," it may answer
   *"I'll use skill X instead"* when conditions fit. Approve / reject-with-reason /
   substitute is the complete NPC vocabulary.
6. **Run.** The plan **auto-declares** each member's agreed actions tick by tick — a
   prefired run. No menus mid-execution; the party performs the choreography.
7. **Branch anywhere, reconverge anytime (RULED).** From ANY step you can open a new
   plan diverging from that point — switched to **manually** at will, or
   **automatically** when the previous plan is no longer possible. Any number of
   branches; branches can **reconverge back into previous plans** (the structure is a
   DAG with merge points, not a tree). With no live branch, deviation halts the run
   and returns control.

### Worked example (owner's, verbatim shape — 1 player, 2 NPCs)

| # | Step | Consent | Outcome |
|---|---|---|---|
| 1 | Player: throw a knife | npc1 V · npc2 V | locked |
| 2 | npc1: charge with hammer | player V · npc2 V | locked |
| 3 | Player: hop on npc1, jump attack | **npc1 X** — *"Player should stay behind as ranged dealer; npc2 should do it"* | red → deleted → refusal list |
| 4 | npc2: hop on npc1, jump attack | player V · npc1 V | locked (the replan around the refusal) |

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

Gates the *authoring power*, not the feature. Baseline: NPCs substitute-or-reject and
you plan around them. A **Tactician can select an NPC's skill directly and see its
conditions** while drafting (owner-stated) — skipping the substitution dance, planning
with the whole party's kit visible. ⟨PROPOSED extensions: pre-authorize automatic branch
switching without re-consent; the shot-caller fantasy.⟩ Natural home: the skills
passover / traits track (the epithet vocabulary already includes tactician-shaped
words). NPC-heavy parties make it a leadership progression. Consent still binds: a
Tactician-authored step remains vetoable by its actor (their reason, their conditions).

## Scope & placement ⟨PROPOSED⟩

- **v1 (slice+ / KAN-4):** solo-lite plan runner — script your own party's next Clock
  with assumptions + halt-on-deviation; single linear plan, one backup edge. Proves the
  runner and the UX vocabulary.
- **Co-op (Stage 1.5):** propose/join/vote flow across clients.
- **KAN-6:** the flowchart overlay + broadcast rendering (mockup gate applies).
- **KAN-7:** hype multiplier, patron plan-conditions, NPC in-character voting.

## Question resolutions (ALL CLOSED 2026-07-16)

- **Q1 vote rule** — per-step consent with written reasons; involved-actor rejection =
  absolute conditional veto (red → delete → refusal list). An *uninvolved* participant's
  X is a **non-binding flagged objection** (RULED).
- **Q2 deviation default** — manual divergence anytime; automatic divergence to a linked
  branch when the current plan is no longer possible; halt when no branch (RULED).
- **Q3 planning cost** — **free at the START of combat; mid-combat planning or changes
  cost a Moment** (RULED).
- **Q4 NPC voting** — NPCs participate from the start — approve / reject-with-reason /
  substitute; never propose (RULED).
- **Q5 Tactician** — a **TRAIT** (RULED); capstone: may pre-authorize automatic branch
  switching without re-consent (RULED). Power: direct selection of allies' skills with
  condition visibility; actor veto still binds.
