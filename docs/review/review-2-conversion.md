# Review 2 — The Idea as a TTRPG → Video-Game Conversion

**Target graded against:** the stated near-term goal — a **co-op RPG with no GM** — with the
LLM-driven MMO treated as a north star, not a requirement.
**Sources:** the full rulebook (`DCC esque System`), Items/Skill List docs, the live campaign
database, the character-sheet app's encoded rules, and the game repo's GDD v0.2 +
Architecture doc.

---

## Verdict

**This TTRPG is unusually convertible — top-decile among tabletop systems — because its
resolution core is already deterministic.** Most TTRPG conversions die translating dice +
GM-fiat adjudication into code. Galactic Prime Time has no to-hit rolls and no GM in the
damage path: *if requirements are met, the action succeeds and its printed effect happens;
if not, a d6 Forced-Action table fires.* That is a rules engine specification, not a
conversation. Roughly 80% of the combat game is directly implementable from the book.

The remaining ~20% is where the GM currently *is* the game — and it is concentrated in
exactly the systems that make the game special (audience, Tags, spectacle). The conversion
succeeds or fails on whether the "show director" layer can be rebuilt as systems. It can —
but it is genuine design work, not translation, and it should be built as a swappable module
(deterministic first, LLM-assisted later).

---

## 1. What converts cleanly (the deterministic 80%)

| TTRPG system | Video-game shape | Difficulty |
|---|---|---|
| Moment Clock (10 counting down, shared timeline, overlap not interruption) | Priority queue keyed by Moment — the architecture doc already specs `clock.gd` exactly this way | Low |
| Requirements-not-dice resolution | Predicate check over stats/equipment/tags/position | Low |
| Per-body-part HP + lethal parts + disable states | `CombatantState` dict; already spec'd | Low |
| Conditions as tiered state machines advancing per Clock (all 9) | Condition engine with tier tables + delay flags | Low-Med |
| Forced Action d6 Body/Tool tables | Literal table lookup; the two tables are fully enumerated in the book *and* in the char-sheet UI | Low |
| Resistances (flat physical, tiered affliction/psychic) | Arithmetic + tier gate | Low |
| Skills with caps 5→10, Patron-Token cap raises, per-trait skill points | Already fully encoded (and battle-tested) in the character-sheet app | Low |
| Weapons/RPM/reload, item tiers + affixes | Data + a few rules; affix system already exists in the DB | Low-Med |
| Boss phases keyed to HP thresholds, surface immunity / breach conditions | Standard boss scripting; Incineradile is fully designed and was actually run at the table | Med |
| Loot tiers, achievements, directives/goals *as reward plumbing* | Standard quest/achievement systems | Low |

Two things deserve emphasis:

- **The Moment clock is a real differentiator that happens to be video-game-native.** It
  plays like a simultaneous-turn tactics system (Frozen Synapse pacing with Darkest Dungeon
  presentation) and eliminates the classic "wait for your turn" co-op problem — everyone
  plans and commits on the shared timeline. The GDD's claim "clock combat is genuinely novel
  and video-game-ready" survives scrutiny.
- **The system has already survived contact with real players.** Five live characters at
  level 6 with full inventories, a 6-phase boss actually fought — the mechanical loops are
  play-tested, which is more validation than most conversion projects ever have.

## 2. The hard 20% — where the GM currently is the game

Rated by GM-dependence, with the concrete replacement pattern for a no-GM co-op game:

| System | GM-dependence | Replacement pattern |
|---|---|---|
| **Freeform requirements** ("Tag: Flashy", "Steady ground", "1 adjacent empty radius", "the fiction prevents it") | High | Close the vocabulary: every requirement becomes an enum the simulation can evaluate (terrain flags, tag IDs, stance flags). The data is already 90% structured in the DB; the long tail gets cut or hard-coded per item. |
| **Tags earned by table consensus / hidden conditions** ("the table agrees X is their thing") | High | Detector systems per tag (the 100-tag list already ships behavior descriptions that read like achievement triggers — "survive three lethal instances", "deal most damage while smallest"). Ship 20–30 detectable tags at launch, not 100. |
| **Goals (crowd challenges)** | Medium | Procedural director: template goals (Finish Fast / Overkill / While Exposed / Solo Action are already parameterizable) selected by audience-state + Tag weights. The GDD's Patron-Tag goal-modifier design already answers this. |
| **Directives (corporate quests)** | Medium | Authored quest pool with procedural triggers; the book's directive taxonomy is already a quest-type enum. |
| **Audience simulation (Viewers/Followers/Patrons reacting "in real time")** | High — and this is the flagship feature | A spectacle-scoring engine: events emit hype (overkill, near-death, style, tag-consistency), viewers flow on hype momentum, followers/patrons convert on thresholds. This is *the* new system a video game must add. Nothing in the book blocks it; the book's structure (numeric counters + defined conversion events) is already halfway there. |
| **Narrative Tokens ("significant narrative shift, DM discretion")** | Total | Redesign or cut for v1. The GDD's risk register already flags this honestly. Candidates: reroll/undo a Moment, force a boss reposition, spawn environmental opportunity. |
| **Enemy improvisation / reorganization at narrative beats** | Medium | Behavior trees + scripted phase logic; boss "win conditions that aren't damage" are authored per boss (the architecture doc already mandates this: "Do not design encounters where the win condition is just 'deal enough damage'"). |
| **Lounge economy, bartering, downtime** | Medium | Standard base-building/economy design; numbers must be invented (the book has structure, not prices). |

None of these are research problems. All of them are **content and systems-design work** —
the project's true cost center is here, not in the combat engine.

## 3. Divergence alert: the GDD is a single-player game; the stated target is co-op

This must be decided consciously, because the existing documents and the new answer conflict:

- GDD v0.2: "Players build a custom **party** of abducted human contestants" — a
  single-player party-tactics game (Darkest Dungeon model).
- Architecture doc: "**Network: None. Fully offline.** Zero external dependencies at
  runtime" — and its save/checkpoint design (rewind-on-death) assumes one authoritative
  local state.
- Stated target now: **co-op, no GM**.

Co-op is *mechanically* friendly to this system (shared clock = simultaneous planning; per
player one contestant + camera competition between friends is a natural fit for the
reality-TV frame). But it is *architecturally* expensive: authoritative state sync,
rollback/rewind semantics across clients, connection lifecycle, and it invalidates the
architecture doc's simplest assumptions. Two honest paths:

1. **(Recommended) Build single-player-first with co-op-shaped bones:** keep the headless
   deterministic simulation exactly as spec'd (it is the same architecture you'd need for
   lockstep/rollback co-op later — deterministic sim + command stream is the classic co-op
   substrate), ship the vertical slice single-player with a full party, then add online
   co-op as a v2 once the game is proven fun.
2. **Co-op from day one:** correct only if playing with your existing group *is* the product
   (i.e. the table-first bar). Then accept the netcode tax up front and consider a simpler
   topology (host-authoritative, friends join the host — no matchmaking, no MMO anything).

## 4. The LLM-GM north star — honest feasibility

- **Feasible in the near term (cheap, low-risk, high-flavor):** directive/goal *text*
  generation, announcer commentary, item/lore flavor text, patron chatter, tag adjudication
  for edge cases ("did that count as Stylish?") with a deterministic fallback. All of these
  are advisory — the sim stays authoritative, so a bad LLM output can't corrupt game state.
- **Feasible with real effort:** an LLM "showrunner" that picks which authored content to
  fire when (a director over a hand-built possibility space — the Left 4 Dead AI-director
  pattern with an LLM as the policy).
- **Research-grade / not a plan:** "characters build the world around them, discover items
  never thought of before" as a *mechanically real* MMO. Free-form generated mechanics break
  the deterministic requirement-checking that makes this system convertible at all, and
  balancing user-facing generated mechanics in a persistent shared world is an unsolved
  problem even for funded studios. Keep it as a north star; do not architect v1 around it.
- **Architecture consequence (actionable now):** the "director" — the thing that issues
  goals, directives, audience reactions, and narrative beats — should be **one module behind
  one interface**, deterministic/procedural in v1, LLM-augmented in v2, so the north star
  stays reachable without betting v1 on it. Note this amends the architecture doc's "zero
  external dependencies" rule for any future LLM mode.

## 5. What the conversion must add that the book doesn't provide

1. **Numbers.** Enemy rosters beyond 3, item prices, XP/level pacing, exhaustion rates,
   patron budget formulas — the book supplies structures; a video game needs filled tables.
2. **The spectacle engine** (§2) — the flagship system; design it early, it touches
   everything.
3. **Content volume.** A GM improvises rooms; a game ships them. Three floors × three routes
   of authored encounters is the real multi-year cost if taken at full GDD scope. The
   vertical slice must be cut far smaller (see Review 4).
4. **Onboarding.** The TTRPG's condition/clock vocabulary is heavy; the game needs the HUD
   to teach it (the char-sheet app's Forced-Action reference tables are a good seed).

## Bottom line

The conversion premise is **sound and above-average in feasibility**, the differentiators
(clock combat + audience-as-mechanic) are real and video-game-native, and the existing GDD +
architecture already answer most translation questions correctly. The two decisions that
must be made deliberately rather than inherited: **single-player-first vs co-op-first**
(§3), and **cutting the director layer to a shippable v1 subset** (§2, §4). The MMO/LLM
dream does not change what to build first — it only argues for keeping the simulation
headless and the director swappable, which the architecture doc already does.
