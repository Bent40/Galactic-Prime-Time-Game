# Review 4 — Potential Estimate & Verdict

**Synthesizes:** Review 1 (TTRPG), Review 2 (conversion), Review 3 (game repo), plus a
web-researched market-comparables study (July 2026; Steam review counts used as unit proxies,
hard figures flagged in the comparables section below).

---

## The verdict in four lines

1. **The material has real potential** — the mechanical core is top-decile convertible and
   the audience-as-mechanic layer is genuinely novel. Ceiling: cult hit. Median: beloved
   niche release. Floor: the best campaign tool your table ever had. It is worth building.
2. **Continue the existing game repo — do not start anew.** Its design docs and schema are
   the most valuable assets in all three repos; its code is 95% unstarted, so there is no
   sunk-cost trap either way. Amend, don't restart.
3. **Stay in Godot**, single-player first with co-op-shaped bones; keep the LLM-GM MMO as a
   north star behind a swappable "director" interface, not a v1 bet.
4. **The binding constraint is not design or market — it's solo-dev scope.** The GDD's full
   vision (3 floors, 40+ hours, NG+, race meta) is a multi-year full-time project. The next
   milestone must be a brutally small vertical slice, and the ambition bar should be decided
   *after* strangers react to it.

---

## 1. Ceiling grade — what the market evidence actually says

The honest read of the comparables (full data in the table below):

- **The reality-TV death-show theme, by itself, does not sell.** It is 0-for-3 as a headline
  feature: *Showgunners* (2023 — almost exactly this theme, 40+ veteran devs, a publisher,
  93% positive reviews) commercially flopped; *The Crush House* (2024, Devolver-published,
  audience-pleasing as the core loop) flopped; *DEATHRUN TV* (2022, game-show roguelite with
  literal Twitch-audience integration) was dead on arrival. Budget zero commercial value for
  the premise alone.
- **Simultaneous tick-combat is a retention feature, not an acquisition feature.** Since
  *Frozen Synapse* (2011), every attempt to lead with it has underperformed (*Frozen Cortex* —
  the devs' own post-mortem called it a conceptual failure; *Atlas Reactor* — shut down;
  *Phantom Brigade* — modest). Keep the Moment clock — it's excellent — but the store page
  and trailer must sell spectacle, body-part brutality, and audience chaos in ten seconds,
  never "no turns, a shared 10-tick clock."
- **The realistic success template is Fear & Hunger, not Darkest Dungeon.** A solo dev with
  per-body-part damage and an aesthetically extreme, streamable identity earned ~300–600k
  units (~$2M est.) over years, purely via YouTube essayists and word of mouth. Darkest
  Dungeon's 6M+ units took a 6-person team, singular art/VO identity, and a 2015-era market.
  Treat DD as ceiling, F&H as the plan-shaped path.
- **The one open lane — and it is time-limited — is the litRPG/Dungeon Crawler Carl
  audience.** 10M+ books sold, a ~$10M tabletop crowdfunding raise, a Peacock TV series in
  production — and **no video game serving the "broadcast dungeon run with audience and
  sponsors" fantasy exists or is announced** (as of July 2026). GPT is precisely that
  fantasy, independently invented. A solo dev cannot outspend anyone, but can be *first and
  findable* ("the Dungeon Crawler Carl-like") — if the game visibly speaks litRPG (stat
  screens, loot boxes, snarky announcer, patron messages) and ships something before or near
  the show's airing. This is the strongest potential-multiplier in the entire assessment,
  and it argues for **smaller and sooner** over grander and later.

**Grade:** ceiling = cult hit (F&H-scale, six figures of units over years); median = a
well-reviewed niche title in the low tens of thousands of units; floor = a polished game
your table and the litRPG subreddits genuinely love, plus the strongest portfolio piece a
full-stack developer could ask for. None of those outcomes are a waste — which is what
"worth building" means.

### Comparables table (research summary)

| Game | Year | Team | Signal | Verdict |
|---|---|---|---|---|
| Showgunners | 2023 | 40+ devs + publisher | ~1.6k reviews, 93% | Flopped despite quality — closest theme comp |
| The Crush House | 2024 | small + Devolver | ~470 reviews | Flopped — audience-as-mechanic comp |
| DEATHRUN TV | 2022 | tiny | ~55 reviews | DOA — game-show + Twitch integration |
| Darkest Dungeon | 2016 | 6 at EA launch | 6M+ units (confirmed) | Ceiling, not plan |
| Fear & Hunger 1+2 | 2018/22 | solo | ~22k + ~15k reviews, ~$2M est. | **The realistic template** |
| Frozen Synapse / Cortex | 2011/15 | ~4 | 300k in 5mo / dev-admitted failure | Tick-combat sells once, in 2011 |
| Phantom Brigade | 2023 | funded studio | ~3–4k reviews | Modest |
| For The King | 2018 | started ~3–4 | 3M units (confirmed) | Co-op works when drop-in simple |
| Wildermyth | 2021 | 6 FTE | ~18k reviews | Small-team tactics hit — solo-adjacent ceiling |
| Brotato / Dome Keeper / Halls of Torment | 2022–23 | 1–2, Godot | $3–11M each | Solo Godot succeeds at tight-loop scope |
| Dungeon Crawler Carl (books) | 2020– | 1 author | 10M+ copies, $10M crowdfund, Peacock series | **Unserved audience, no video game** |

## 2. Ambition bar — the honest recommendation

Asked to grade honestly: **build to the table-first bar now, with free-release positioning
as the test, and treat commercial as an option that has to earn itself.**

The evidence for this isn't the market — it's the repo. The game attempt was a two-day burst
that stopped exactly where the first hard implementation work begins (Review 3), while the
TTRPG campaign — the thing with a live audience of five friends — has months of sustained,
high-quality output (Review 1's live data). That pattern says: motivation flows where the
audience already is. So put the audience inside the loop:

- **Milestone 1 (table-first):** the vertical slice below. Your players are the playtesters;
  the campaign is the content pipeline (Incineradile is already a designed digital boss).
- **Milestone 2 (public signal):** a free itch.io / Steam-demo release of the slice aimed
  squarely at r/litrpg and Dungeon Crawler Carl fans. Their reaction — not anyone's
  intuition, including this review's — decides whether the commercial path exists.
- **Commercial only after signal.** If the slice resonates (wishlists, an essayist bites,
  the subreddit cares), *then* price it in the F&H band ($8–15) and scope a "Season 1"
  (one floor done excellently — not three).

## 3. Start anew or continue? — **Continue.**

Review 3's finding makes this nearly a false choice: ~450 lines of real code/SQL plus four
strong documents, zero gameplay code. There is nothing to escape from and much to keep:

- **Keep authoritative:** `GPT_ARCHITECTURE.pdf` (headless sim, MVC, serialization contract,
  KAN order), `GPT_GDD_v02.pdf` (vision, loop, Ascension/Patron NG+), the SQLite schema,
  `run_migrations.gd`, and the Jira epic structure.
- **Amend (these are decisions, record them, don't drift):**
  1. **Single-player first** (see §4) — reaffirm the architecture doc's offline assumption
     for v1; require the simulation to stay deterministic and command-driven so
     host-authoritative co-op remains a v2 door, not a rewrite.
  2. **Adopt a "digital rules addendum"** answering Review 1's fix-first list (tick order at
     Clock reset, declare/resolve timing, condition application tiers, free-action caps, RPM
     economy, grapple rules, advancement curve). The book's gaps are KAN-2's requirements
     backlog — write the answers down *before* coding the engine.
  3. **Complete the seed data:** per-body-part HP values, `condition_tiers` (incl. shock),
     `skill_thresholds` — port from the rulebook + char-sheet app, which already encode most
     of it.
  4. **Director behind an interface** (goals/directives/audience reactions): procedural in
     v1, LLM-augmentable later — the north-star insurance policy.
  5. Mechanical hygiene: stubs → `RefCounted` per the doc, vendor godot-sqlite, set the main
     scene, and start KAN-2 with the unit tests the architecture doc already demands.

## 4. Engine — **stay in Godot** (engine was open; here's the reasoning)

- The product is a 2.5D tactical game with animation, shaders, juice, and a Steam
  destination — a game engine's home turf; a web stack would fight the presentation layer
  for years and forfeit the Steam/litRPG discoverability that §1 identifies as the one open
  lane.
- The two best documents in the project target Godot 4 specifically; switching stacks
  orphans them.
- The solo-Godot success cohort (Brotato, Dome Keeper, Halls of Torment) proves the engine
  is not the risk — scope is. GDScript is a low-friction jump from JS.
- Co-op later: Godot's high-level multiplayer (host-authoritative ENet) is adequate for
  friends-join-host co-op, which is the only co-op topology worth considering here. The MMO
  north star does not change the v1 engine choice — a deterministic headless sim is the
  correct substrate for every future (single-player, co-op, or LLM-directed).
- The web stack keeps its job: the char-sheet app remains the live campaign's tool (and its
  battle-tested skill/item/affix data seeds the game's SQLite content).

## 5. The next milestone — smallest honest vertical slice

Regardless of every other decision (and per the architecture doc's own order — KAN-2 before
any scene):

1. **Headless combat engine + unit tests** (KAN-2): Clock priority queue; 2 combatants;
   Bleed/Crush/Burn + Shock; Forced Action tables; per-part HP with disable/death; the
   digital-rules-addendum decisions implemented.
2. **One arena** (single hex map), **2 premade contestants** (player controls both — party
   of two, no character creation), **one mob pack + Incineradile Phase 1** (already
   designed, already play-tested at your table).
3. **One audience system, shallow but visible:** a hype meter that reacts to spectacle
   events, one active crowd Goal, Camera Call as a button — because it's the differentiator
   and it must be in the first playable thing anyone sees.
4. **Win/lose screen framed as a broadcast** ("ratings" recap).

**Success bar:** a stranger plays 20 minutes, understands the clock without being told
twice, produces one clip-worthy moment, and asks for another run. Cut anything that doesn't
serve that (no Lounge, no exploration, no saves beyond restart, no co-op, no LLM).

## 6. Answer to the question as asked

> *"Estimate how much potential the whole thing has, and whether we should start anew or not."*

**Potential: real, and above the hobby-project baseline** — an original, play-tested system
whose hardest-to-fake asset (a fun core loop with a live table) already exists; a
conversion target that is unusually mechanical; and an identified, unserved, time-limited
audience. **The risks are equally real:** the theme doesn't sell by itself, the flagship
audience mechanic is commercially unproven, and the sole evidenced threat to the project is
scope-versus-stamina — visible in the repo's own history.

**Start anew? No.** Continue the existing repo with the five amendments in §3, in Godot,
single-player first, and make the next commit KAN-2's first unit test.
