---
title: "Game Brief — Galactic Prime Time (working title)"
status: APPROVED (owner, 2026-07-16) — with one note: dual-prose brand presentation is set aside as post-MVP
created: 2026-07-16
updated: 2026-07-16
---

# Game Brief: Galactic Prime Time ⟨working title — open decision⟩

## Executive Summary

Galactic Prime Time is a **2.5D tactical RPG about being entertainment**. You are a
contestant on a dungeon gameshow that is secretly a table in the **Cosmic Casino** — the
framework where gods wager on mortals every quarter-millennium, and where whatever they
found interesting about humanity gets turned into a game. What they found interesting was
our reality TV. So the dungeon has an announcer, a hype meter, sponsor gifts, and an
audience of divinities betting on whether you break.

Combat is turnless and diceless — a shared Moment clock where actions auto-succeed if
their requirements hold and failure rolls on a consequence table instead of whiffing —
over per-body-part HP and escalating condition clocks, so every wound is a story beat the
crowd can see. Around the fights runs the real game: audience attention as an economy
(viewers → followers → patron gods), a patron god who escorts your run and bends the odds,
and floor-sets that each stage one moral question. The campaign's spine: **"How much can
we break your essence down in the name of entertainment?"** At the end, the show hands
down a **verdict** — what kind of person you were, and what kind of **ruler** you'll be —
because winning doesn't free you; it makes you one of *them*.

It ships by a ladder, never a big bang: a headless deterministic engine (done, with a
green headless test suite), a vertical slice, friends co-op, then an async global show where every party's
runs push the same floors. The fiction is multiplayer-native — spectators are diegetic —
but every rung is a complete game.

## Vision

- **Core fantasy (one sentence):** *Survive a dungeon gameshow the gods are betting on —
  get famous, get dangerous, and decide what's left of you when the cameras stop.*
- **Elevator pitch:** A co-op tactical RPG where the audience is a game system: gods tip
  the dealer to buff or curse you, your deeds earn divine affection and epithets, and the
  campaign ends with a verdict on who you became — crowned by the casino that broke you.
- **Walk-away feeling:** being *watched* — thrilling and violating at once. The comedy of
  the broadcast, the grief underneath it, and the discomfort that your best moments were
  someone else's entertainment.

## Target Players & Market

- **Primary:** the litRPG / Dungeon Crawler Carl readership (large, proven, and starved
  for games that respect the fantasy — review-4 §1: the reality-show dungeon lane has
  huge book comps and almost no games) who also play PC tactics/roguelites. Expect
  20–60 minute sessions, permadeath tolerance, build-craft appetite.
- **Secondary:** tactics players (Into the Breach, Darkest Dungeon) drawn by deterministic
  combat and body-part attrition; later, co-op friend groups (Stage 1+) and the
  spectate/patron crowd (Stage 2).
- **Market moment:** DCC's TV adaptation is raising the lane's profile; no incumbent
  game owns "audience-as-mechanic." ⟨ASSUMPTION: timing claim — cheap to re-verify
  before any public beat.⟩

## Core Fundamentals

**Genre:** 2.5D tactical RPG, single-player-first with a co-op → shared-world ladder
(DIRECTION D1–D2). **Platform:** PC (Godot 4.7).

**Core loop (moment to moment):** enter a combat *field* → the shared Moment clock binds
everyone in it → declare actions whose requirements auto-succeed (no to-hit); unmet
requirements and wounds trigger d6 **Forced Actions** — the drama generator → wounds land
on body parts and start condition clocks (bleed, crush, burn…) → spectacle moves the
**hype meter**, the crowd reacts, gods tip → loot, recruitment, and floor progress feed
the next run. **Session loop:** floor-set → moral question staged as content → route
unlocks are path-dependent → time skips between floors. **Campaign loop:** tags (what the
audience calls you) drift apart from essence (what your choices reveal) → the verdict.

**Pillars (load-bearing):**
1. **Everything is on air.** Two information planes — the audience hears the announcer,
   contestants live the world — and audience attention is a real economy (hype, camera
   calls, patron tips, epithets).
2. **No dice to hit — requirements and consequences.** Deterministic tactics on a shared
   clock; failure never whiffs, it *cascades* (Forced Action tables). Command-stream sim
   makes every fight replayable as a broadcast.
3. **The body is the resource.** Per-part HP, condition clocks, priming instead of
   cooldowns (R3), damage that means something (R14). Healing is triage, not top-ups.
4. **Your choices are the scoreboard.** Floor-set questions, essence vs. label, and a
   verdict ending that tells you what kind of ruler you'll be.

## References & Differentiation

| Title | Taking | Deliberately NOT taking |
|---|---|---|
| *Dungeon Crawler Carl* (books) | broadcast-dungeon comedy, loot-box absurdity | the alien-corporation TV frame (our runner is a gods' casino), prose pacing |
| *Omniscient Reader's Viewpoint* | sponsor/patron drama, constellation-style bidding | the metatextual reader premise |
| *Hades* | god-boon economy, run-based intimacy with a pantheon | action combat, Greek-only cast |
| *Into the Breach* | deterministic, information-forward tactics | puzzle-box scale; we want drama, not solvability |
| *Darkest Dungeon* | party attrition, stress-as-content | its hopelessness; our tone is showbiz over grief |
| *Fear & Hunger* | body-part consequence horror | obtuse cruelty; our rules are legible on air |
| *Dofus / Wizard101* | field-bound, clock-shared combat in a shared world | subscription-MMO scope before it's earned |

**Differentiators (genuine):** the audience as a first-class game system (patron gods
bidding, buy-outs, affection ledgers); a verdict ending where winning = deification and
judgment; the essence/label duality made mechanical; a command-stream sim that turns
replays, spectating, and async multiplayer into nearly-free features. The edge is design
coherence + the owner's own IP world (novel-shared cosmology), not a technical moat.

## Scope & MVP

- **Team:** solo owner-designer + AI agents; professional web stack available for the
  Stage-2 service. **Budget:** hobby. **Engine:** Godot 4.7, headless-tested sim (KAN-2:
  a green headless test suite).
- **MVP (the W3 vertical slice, unchanged from DIRECTION):** one arena, a created-or-default
  player contestant, Sasha & Nikita as recruitment encounters, Incinedile Phase 1, visible
  hype meter, broadcast-framed win/lose. **It validates the hypothesis:** *deterministic
  clock combat + audience reaction is fun for a stranger for 20 minutes and produces a
  clip-worthy moment.*
- **Stage gates (honesty rule):** each ladder rung needs external evidence before the next
  is funded with time. No dates promised; the KAN epic order is the build order.

## Content & Direction

- **World:** the Cosmic Casino frame, game-first (D3–D5): a VIP table skinned as a human
  reality show; fallen gods run the games; patron gods escort champions; divinity is the
  currency; the final winner shapes how history remembers the apocalypse.
- **Narrative:** floors ~20 in question-sets (design paused at 6); recruitable NPCs with
  authored arcs (Nikita's Reversion is the priming showcase; Sasha the recognition-
  asymmetry thread); the brand contract (mercy earns the songs; branded characters read a
  drier world). Player character is an OC.
- **Content scale (rough):** slice = 1 arena / 3 contestants / 1 boss phase; campaign
  v1 target = floor-sets 1–6 with existing bestiary (roach family, Incinedile, demons,
  Loong) + mythology-sourced additions. Replayability from route exclusivity, patron
  variety, and the verdict axes.
- **Art:** 2.5D — readable tactical sprites, two-posture character silhouettes
  (Nikita's stoop/square is the transformation VFX); broadcast UI framing (odds boards,
  lower-thirds) carries the theme cheaply. ⟨PROPOSED⟩
- **Audio:** announcer VO is the flagship want (host voice pending the Momus decision);
  crowd as diegetic ambience; UI stingers for tips/achievements. ⟨PROPOSED⟩

## Risks & Open Questions

- **Design risks:** floor-content volume at 20 floors (mitigation: director interface +
  question-set structure; LLM augmentation later); hybrid audience risk — tactics players
  vs litRPG readers may want different pacing (slice will tell). ~~Two-plane authoring
  cost (dual prose for branded characters)~~ — **RULED post-MVP, set aside (owner,
  2026-07-16)**: stays canon as design direction, out of MVP scope entirely.
- **Technical risks:** co-op netcode at Stage 1.5 (mitigated by command-stream design);
  LLM director cost/safety at Stage 2+ (schema-bound commands, deterministic v1 first).
- **Open owner decisions:** title (this working title is TV-frame); Momus vs sibling host;
  does the live TTRPG table re-skin; the timer (season mechanic vs starving-pantheon
  cosmology); R13 shock model confirm; R14 force-gate co-design; skills passover (priming
  vocabulary).
- **Assumptions to validate in the slice:** the Moment clock reads at a glance; Forced
  Actions feel like drama, not punishment; the hype meter changes player behavior.

---
*Sources: DIRECTION.md (D1–D5 + contracts), story-canon.md, cosmic-casino-canon.md,
design/patron-gods.md, rules-addendum.md, review-4-verdict.md (market), GDD v0.2 PDF
(superseded where in conflict). Next: `gds-gdd` builds the full design on this brief.*
