# Galactic Prime Time — v1 / v2 Fork Spec

**What v2 (mythology) needs changed from v1 (aliens), inside the TTRPG system.**

**Status:** RESEARCH COMPLETE · **Date:** 2026-08-10 · **Method:** 7 parallel research
passes over the TTRPG rulebook, the live campaign data, and the full v2 canon set.
**≈211 graded findings + 461 data records classified + ~90 prior decisions catalogued.**
Every finding is cited to `§section` or `file:line`. Full inventories in
[`research/`](research/) (A–G).

**Naming used throughout:**
**v1** = the alien premise — abducted humans, The Corporation™, alien-broadcast dungeon
runs. The live tabletop campaign. Master: `Galactic-Prime-Time/rulebook/gpt-system-v1.0.md` (v1.1, 2026-08-04).
**v2** = the mythology premise — the Cosmic Casino, gods wagering on contestants, the
divinity economy. Master: this repo's `docs/` setting layer.

---

## 0. The two rulings that govern this document

Both given by the owner on 2026-08-10, at the start of this pass.

### D-V1 — "stages 4–9" means **dungeon floors 4–9**
The next authoring phase is floor-sets 4 through 9, not new rungs on DIRECTION.md's
product ladder. See §7 for the handoff.

### D-V2 — **v1 is FROZEN; v2 bends**
Where the two premises genuinely conflict, the live campaign does not change. v2 absorbs
every change.

**Four consequences, and they shape everything below:**

1. Every FORK resolves in one direction only — **v1 keeps its form; v2 authors a new one.**
2. Shared-spine work is **additive in v2**. Nothing here proposes renaming Camera Call,
   Directives or Viewers *in v1*.
3. Cost lands asymmetrically. This document is a **v2 build budget**, not a migration plan.
4. `gpt-system-v1.0.md` stays the v1 master. **v2 needs its own artifact** — see §8, D-06.

---

## 1. D-V2 settles a contradiction that has been live since July

This is the most important housekeeping outcome of the pass. **Three independent research
slices (A, F, G) found the same conflict from three different document sets.**

| Doc | Date | Status | Says |
|---|---|---|---|
| `setting-rebrand-options.md:155-156` | 2026-07-16 | **RULED** | *"Does the live TTRPG campaign re-skin too? — **RULED: RE-SKIN TO CASINO** — the live table adopts the casino frame alongside the game."* |
| `ttrpg-update-plan.md:5-9` | 2026-07-23 | **PROPOSED**, never approved | *"The TTRPG keeps its ORIGINAL setting — reality-TV dungeon crawler, The Corporation™, alien broadcast… Everything Cosmic-Casino-flavored is video-game-only and stays out of the book and the app."* |

The July-23 plan contradicted the July-16 ruling but was never signed off, so the re-skin
ruling remained nominally live while the project behaved as though the opposite were true —
three divergences are already shipped under the fork reading (races, tags, "Patrons are
never gods"). Meanwhile the live rulebook, revised as recently as 2026-08-04, still opens
with *"You were abducted by an alien conglomerate. The Corporation™…"* (`gpt-system-v1.0.md:9-13`).

> **D-V2 resolves this in favour of the July-23 position.** Record it as superseding
> `setting-rebrand-options.md:155-156`.

`ttrpg-update-plan.md:12-45` already ships the enforcement machinery — the **"no-mix-ups
guard: three canons, kept separate"**:

| Canon | Artifact | Holds |
|---|---|---|
| **TTRPG book** | `gpt-system-v1.0.md` | Table rules, original reality-show setting, live campaign's races/characters/tags |
| **Digital rules** | `docs/rules-addendum.md` R0–R23 | Engine rulings where the book is silent |
| **Video-game setting layer** — *never ported to the TTRPG* | `cosmic-casino-canon.md`, `design/patron-gods.md`, DIRECTION D3–D5 | Cosmic Casino, patron gods, divinity economy, Forsaken runs, epithets, verdict/spine |

Its operative test — **"any sentence that needs the word 'god' does not belong in the
book"** (`ttrpg-update-plan.md:27-28`) — is now the governing rule for v1.

**Two things follow.** First, `ttrpg-update-plan.md:21-45`'s hard-exclusion list, **read in
reverse, is a ready-made import manifest for a v2 artifact** — it already enumerates
exactly what v2 has and v1 must not. Second, the plan's own Phase-4 divergence guard (a
committed three-way consistency appendix, `ttrpg-update-plan.md:207-221`) **was never
written**, which is precisely why this drift accumulated unnoticed. This document plus
[`research/F-v2-canon-ledger.md`](research/F-v2-canon-ledger.md) §3 is the current stand-in.

---

## 2. Executive summary — the shape of the conversion

### The headline finding

> **The content converts nearly for free. The *mechanisms* do not.**

**449 of 461 authored records (97.4%) copy into v2 verbatim** — every skill, every affix,
every material, almost every item and tag. The whole authored-content re-skin is **12
records**.

But **28 MECHANICAL + 13 FORK findings** sit almost entirely in two places: **§17 The
Audience** and **the story's stakes**. That is the real project.

**Why the content is nearly free:** v2 does *not* delete the broadcast. `setting-rebrand-options.md:113-119`
(RULED 2026-07-16) makes GPT a **VIP table whose in-fiction skin is a human reality show** —
*"Every broadcast mechanic (announcer, tags, camera calls, ratings) survives untouched — the
DCC separation comes from who runs it and why."* Only the **Corporation / alien-abduction
power** is dead canon. The pop-culture texture isn't tolerated in v2; it's *licensed* by it,
because the gods built a reality show after binge-watching us.

### Verdict distribution (sum of the five inventory slices)

| Verdict | Count | Meaning |
|---|---:|---|
| **KEEP** | 76 | Theme-neutral. Works in both, unchanged. |
| **RESKIN** | 61 | Name/flavour only. Mechanics identical. |
| **MECHANICAL** | 28 | The mechanic itself must change. |
| **FORK** | 13 | v1 and v2 cannot share it. |
| **CUT** | 9 | Dead in v2. |
| **NEW** | 22 | v2 needs machinery v1 never had. |

*(Per-slice counts as reported by each pass; see §5.)*

### Where the difficulty actually is

| Slice | MECHANICAL + FORK | Read |
|---|---:|---|
| **B — Audience & Tags** | **23** | The conversion, essentially. |
| A — Framing & contestant | 6 | Thin; mostly front-matter. |
| G — Story & encounters | 7 | One real fork; the rest is the stakes problem. |
| C — Economy, Lounge, items | 3 | **Zero forks.** 19 Lounge modules, 0 breaks. |
| D — Combat, skills, enemies | 2 | **The engine is premise-blind.** |

### The five things that genuinely fork

1. **§17.1 Exposure** — v1's audience is a *fluid* (billions of Viewers); v2's is a *graph*
   (24 named gods). Not reskinnable.
2. **Followers** — the most orphaned mechanic in the book. "Phone-vote money" has no god
   analogue; canon moves money as *tips to the dealer* (`cosmic-casino-canon.md:33-34`).
3. **Directives** — one issuer is a script; many competing gods are a market, with
   conflicting demands, hostile quests and cheap refusal.
4. **Tags → Epithets** — *not* a rename. The **source** changes: tags are performable crowd
   labels, epithets are earned myth-recreation. Already ruled (see §3).
5. **The contestant's stake** — v1's "get home" has no v2 equivalent. See §6.

### The three cheapest wins

- **§12 Materials** (§12.7) was already authored *from this repo's own mythology library* —
  155 entries, 14 traditions. **Zero renames.** It also answers the story bible's demand
  that loot feel like remnants of belief.
- **Damage types need no addition.** `domain_condition_map.json` already maps 26 god-domains
  onto the 9 conditions; 13 are deliberately empty and **0 demand a new one**. Dissolution
  (ex-"Psychic") already *is* v2's soul-damage.
- **Item/affix naming debt was pre-paid** by the August ruling ID-0.20 ("theme by FLOOR, not
  by Show") — 3 renames across ~147 templates, **zero** across 42 affixes and ~26 materials.

### Costed

| Path | Content re-authoring | Estimate |
|---|---:|---|
| **Frame-A** (ruled) — only the Corporation/alien power forks | **12 records (2.6%)** | **S — ~1 day**, ~70% of it writing the new v2 rules artifact |
| **Frame-B** (unruled) — audience nouns also renamed | **101 records (21.9%)** | **L — ~1 week** |

**D-02 is therefore the single highest-leverage cheap decision in this document**: one
ruling, an 8× swing in content cost. *(Frame-B's +89 is a keyword count carrying a measured
~10% false-positive rate.)*

---

## 3. What is already decided — do not re-litigate

The v2 spine is **far more settled than a brainstorm**. ~90 DECIDED entries across 8 areas
([`research/F`](research/F-v2-canon-ledger.md) §1). Highlights:

| Area | Settled | Cite |
|---|---|---|
| Frame | Casino adopted **game-first**; world rules yes, novel's story no | DIRECTION D3–D5 |
| Coupling | **Hard decoupling** from the novel | `setting-rebrand-options.md:151-154` |
| Patrons | Q1–Q8 all RULED 2026-07-16 | `design/patron-gods.md` |
| Roster | Mythology spec ruled executable **and already executed** — 224 entities, 294 myths, owner-approved **24-god roster** | `data/patron_roster.json` |
| Tags→Epithets | **A fork, not a rename** — the Q2 ruling supersedes the same-day rename proposal | `patron-gods.md:126-150` over `setting-rebrand-options.md:38` |
| Cosmology | Option E **rejected** — the gods are *not* starving; ruin is self-inflicted status-loss | `setting-rebrand-options.md:160-164` |
| Religions | Living religions = investor corporations; messenger-tier only; three Abrahamic brands are one holding company | `cosmic-casino-canon.md:47-56` |
| Title / Host | **Keep "Galactic Prime Time"; Momus is shared host** | `setting-rebrand-options.md:157-159` |
| Forsaken | God-initiated all-in, never the champion's refusal | `cosmic-casino-canon.md:28-30` |
| Ending | The verdict — winning promotes you into the audience | `story-canon.md:74-75` |

Only one v2-adjacent thing is still an explicit SKETCH: **combat fields / clock drivers**
(`DIRECTION.md:83`).

> **Why the Tags→Epithets ruling matters so much:** a straight rename would have destroyed
> the spine. `story-canon.md:83-88` makes Tags (how the audience *labels* you — public,
> performable, fakeable) deliberately separate from and occasionally contradictory to the
> question-axes (what your choices reveal you to *be*). *"The show breaks essence down while
> the audience applauds the label — that tension IS the spine made mechanical."* Collapsing
> tags into god-granted epithets would have merged the two sides of that tension into one.
> **v2 needs both: tags stay the crowd's label, epithets are the earned myth-record.**

---

## 4. The shared spine — proven theme-neutral

Slice D established this by **keyword census, not impression**: grepping ~700 lines of
combat rules for every alien/TV/corporate term returns **6 lines, two of them false
positives** ("crowd" = crowd of *enemies*; "multi-stage" = phase). A second census found 9
economy-coupling lines — **all venue names, never rules**.

**Runs unchanged in both versions:**

> §4.1 skill architecture · §4.3 multi-stat · §4.5 consuming · §4.6 **Priming** · §4.7
> passive/reactive · **all of §5 The Clock** · §6 Forced Actions · §7.1–7.3, §7.5 bodies &
> damage · §8 Conditions · §9 Shock · §10 Resistances · §11 States · §13 Grappling · §14
> Dodge · §15 Stealth · §21.2 construction · §21.5 falling

Corroborated independently by `setting-rebrand-options.md:104` — *"the engine doesn't know
who's watching"* — and by the conditions-data audit's "no corporate language" finding.

**Consequence:** the entire combat engine, the clock, the body/damage/condition model and
the skill architecture are a **single shared codebase and a single shared chapter set**
across both versions. The fork is a *fiction layer plus §17*, not a system rewrite.

Also shared for free: **19 of 19 Lounge modules** (12 clean re-skins, 3 already-v2, 4 needing
only a new justification line) and **42 of 42 affixes**.

---

## 5. The fork surface, ranked

### Tier 1 — premise-critical (v2 cannot ship without these)

| ID | Element | Verdict | Effort | The change |
|---|---|---|---|---|
| **B-01/B-02** | §17.1 Exposure ladder | **FORK** | L | Fluid → graph. Hype stays a broadcast-plane meter and *feeds* per-god affection ledgers, which become the economy. |
| **B-07** | **Followers** | **FORK** | L | No god analogue exists. Standing bets, mortal devotees, or cut. |
| **B-19** | §17.5 Directives | **FORK** | L | One issuer → a market of competing gods. Canon splits on whether a patron's tip *is* a Directive or a separate channel. |
| **G-stakes** | The contestant's want | **FORK** | L | v1's "go home" is deleted, *and* the antagonist is deleted (gods are morally alien by hard rule). See §6. |
| **C-12** | **Ascension / the mortal→god pipeline** | **NEW** | L | The book has **no exit door at all** — `Ascen*` appears **0 times**. v2 isn't preserving this mechanic; it's building it. |
| **A-04** | §1 must state *why* the games exist | **NEW** | M | v1's motive (colonisation propaganda) is dead; v2's (divinity economy) is unstated in-book. |

### Tier 2 — system shape

| ID | Element | Verdict | Effort | The change |
|---|---|---|---|---|
| **B-35** | Tags **and** Epithets as two systems | FORK | M | Keep both; do not merge. Epithets need a rider concept they currently lack. |
| **B-43** | Tag domain vocabulary | MECHANICAL | M | Book's 12 crowd-appetite words vs the shipped 26 mythology jurisdictions. **Only `chaos` overlaps.** Never ruled. |
| **B-10** | Camera Call → the odds board | MECHANICAL | M | What doubles? Spectacle (safe, shipped) / affection swings / the wager itself (most faithful, needs a pot). |
| **C-14/C-15** | The pot ("the handle") | NEW | M | Canon needs "the currency being bet around"; §19 has no pot. A handle track makes Camera Call *literally* an odds mechanic for free. |
| **D-44** | **Divine intervention in combat** | NEW | M | 11 of 24 MVP gods carry `luck_gambling`, which maps to **nothing**; 3 gods have zero combat expression. Precedent: §18.2 Nine Lives was already migrated to the epithet/god track. |
| **D-45** | Curses have no chassis | NEW | S | Proposed **anti-prime** — a curse adds/invalidates a §4.6 prime. Zero new machinery, myth-correct, degrades via §6.2 rather than locking out. |
| **D-32** | Super Boss ladder | RESKIN | S | "Precinct → Country → Stage" is civic/TV-coded. Proposed: bosses **Shrine → Temple → Pantheon**, supers **Legend → Age-Ender → The House**. |
| **G-demons** | Demonic-nobility cosmology | **FORK** | M | v2 offers **three incompatible homes** for demons and rules none. The whole Medium route rides on it. |
| **A-02** | The Corporation™ → the house | RESKIN | M | The fallen (bankrupt) god running the table. **Needs a name** — nothing in canon names it. |
| **A-16** | Background-driven creation | NEW | L | Creation becomes the single surface for 4 skills + epithet seeds + patron bids. v1 has no such step. |

### Tier 3 — vocabulary, voice and content

| Element | Verdict | Effort | Note |
|---|---|---|---|
| Abduction / colonisation / "refusing to join" | **CUT** | S | 6 of 7 alien-coded hits live in the 6-line front-matter blurb. |
| "Contestant" | KEEP | — | Keep; pair with canon's "champion" as a two-plane register split. |
| Book voice pass | RESKIN | **L** | The corporate satire doesn't die — it **re-points** at the investor-religions and casino comps. Largest single writing job in the slice. |
| Skill names | RESKIN | S | 32/44 need no thought. **~4 worth renaming.** The 9 pop-culture quips are *canon-licensed* and get stronger. |
| Item/affix/material names | RESKIN | S | 3 of ~147; **0 of 42 affixes; 0 of ~26 materials.** |
| Tag names | RESKIN | S | 62 media-coded / 32 neutral / 6 myth-friendly — but the 62 survive on the diegetic skin. **1 true break** (Corporate Asset), 6 trademark/IP, 5 insider-jargon. |
| Lounge modules | RESKIN | S | 19 walked, **0 break**. |

### Per-slice detail

| Slice | Findings | K | R | M | F | C | N | Full inventory |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| A — Framing & contestant | 31 | 9 | 8 | 3 | 3 | 3 | 6 | [`research/A-framing.md`](research/A-framing.md) |
| B — Audience & Tags | 46 | 11 | 7 | 18 | 5 | 0 | 5 | [`research/B-audience-tags.md`](research/B-audience-tags.md) |
| C — Economy, Lounge, equipment | 43 | 20 | 13 | 3 | 0 | 0 | 5 | [`research/C-economy-lounge-items.md`](research/C-economy-lounge-items.md) |
| D — Skills, combat, enemies | 46 | 25 | 14 | 2 | 0 | 1 | 4 | [`research/D-combat-skills-enemies.md`](research/D-combat-skills-enemies.md) |
| E — Live content audit | 461 records | 449 | 1 | 9 | 2 | — | — | [`research/E-data-audit.md`](research/E-data-audit.md) |
| F — Canon ledger | ~90 + 31 + 24 | — | — | — | — | — | — | [`research/F-v2-canon-ledger.md`](research/F-v2-canon-ledger.md) |
| G — Story & encounters | 45 | 11 | 19 | 2 | 5 | 5 | 2 | [`research/G-story-encounters.md`](research/G-story-encounters.md) |

---

## 6. The stakes problem — the highest-leverage open item

**v1's stake has three layers:** a **want** (go home), a **pressure** (ratings — "the only
way out is through the ratings"), and a **record** (tags).

**v2 keeps the pressure and the record, deletes the want, and deletes the antagonist** —
because gods are morally alien by hard rule (`cosmic-casino-canon.md` §4), so there is
nothing to beat. Worse, the ending forecloses the want: winning *promotes you into the
audience*, so there is no home to return to. Character creation's proposed
*"what you want back home"* field (`patron-gods.md:240-242`) is already sitting on this
contradiction.

**Three candidate answers:**

| | Proposal | Canon status | Read |
|---|---|---|---|
| **A** | **Divinity is transferable** — you play to decide *who gets remembered* | Needs **one new ruling** | The only one that **replaces what v1 lost**. Fills creation's empty "what you want back home" slot. |
| **B** | **The patron is the stake** — extraction, neglect, buy-out, no contract exit | **Fully RULED** — zero invention | The direct heir to "the only way out is through the ratings". But it is a *pressure*, not a *want*. |
| **C** | **Play for the record** via the epithet/myth track | RULED, never framed as a motive | Needs only a framing pass. |

> **Recommendation: adopt B + C now (both free), and rule on A.** B and C are already
> canon and can be written today; only A closes the hole v1's "go home" left, and it needs
> the owner.

**This blocks:** every floor-set question, the ending, the creation flow, and the pitch.

---

## 7. Story, encounters, and the handoff to floors 4–9

### What survives

Of the **7 must-preserve elements** listed at `setting-rebrand-options.md:20-30`: **5 clean,
2 flagged.**

- **Time skips survive** but open a new hole: does the fast-forward move *Earth*, or only
  the table's set?
- **Ascension is the real flag.** The mechanism maps 1:1 but **the meaning inverts**:
  v1's Ascension is a retirement that lets you **leave**; v2's is a buy-in with **no exit**.
  `setting-rebrand-options.md:40` scores it a clean map — true mechanically, misleading
  narratively. The bible's "become unwagerable" north star was never reconciled against the
  winners→gamblers pipeline (`cosmic-casino-canon.md:190-193`, marked *owner to reconcile*).

### Set pieces under v2

**Exactly one genuinely forks:** the **demonic-nobility cosmology** (three incompatible
homes, none ruled — blocks the entire Medium route, the brand contract, and the
Dissolution-songs framing).

**Four improve:**
- **F4–F6 continent merge** gains a native mechanism — the casino *closing tables* as
  competition narrows. This is a better justification than v1 ever had.
- The **Easy route's two known holes** (mask origin, Nullrot motive) close on the relic canon.
- The **Loong** is already a canon category (Worshipped Creature). *(Its escort-quest
  weakness is a design problem the frame cannot repair.)*
- The **demonic brand contract** becomes an unauthorised second patronage — sharper under gods.

**Untouched:** Sasha's maze, the Incinedile.

### Nikita

He parses, and gets **more** resonant — but only under a **narrow reading** of one sentence.

`cosmic-casino-canon.md:45-46` says the games are *"the source of every legend, idea, and
imagination humanity ever created."*

- **Narrow** (games author the myth-layer and the *memory*, never the events): Nikita gets
  **better**. The machine that turns suffering into story becomes literal, and the scarf is
  the one thing that refuses to be content.
- **Broad** (games author the events): a real genocide becomes downstream of a card game —
  violating the project's own guardrail at `GPT_Master_Compendium.md:430`.

> **The canon as written sits closer to the broad reading. The risk is that sentence, not
> the character.** Recommend ruling it narrow — a one-line fix.

New in v2: real Abrahamic figures played as corporate comedy. Recommended **separation
rule** (Nikita never shares a scene/floor/episode with that satire), not a ban.

### The ending

Claim the **conditional form**, not apotheosis itself. Six table requirements, chiefly: a
**visible ledger with invisible totals**, axes declared up front, and the finale staged as
**your own highlight reel — accurate and unkind**.

**v1 loses nothing** — it has no designed ending — and should take the **colonisation vote**.
Clean split: **v1 political, v2 theological.**

### Floors 4–9 — the direct handoff (D-V1)

The floor-set architecture (`story-canon.md:66-73`) is **substantially theme-neutral**:
each SET asks one question that classifies you, unlocks are path-dependent, the ending is a
verdict.

> **Of 9 candidate floor-set questions: 5 carry both versions unchanged · 1 shares its shape
> and forks in consequence · 3 are exclusive to one version.**

**Recommended method for floors 4–9:** author **once at the question level**, fork **only at
the content level**. F4–F6 already exists and improves under v2 (the closing-tables
mechanism); F7–F9 is greenfield and should be written against the shared question bank.

**Prerequisite:** the shared question bank must be written *before* any floor-7 content, and
§6's stakes ruling gates all of it — a floor-set question only classifies you if there is
something you want.

---

## 8. Decision docket

Deduplicated across all seven slices and ranked. **Tier 1 blocks other work; Tier 3 is
housekeeping that is cheap now and expensive to leave.**

### Tier 1 — blocks downstream design

| # | Decision | Why it blocks | Recommendation |
|---|---|---|---|
| **D-01** | **What is the contestant's personal stake in v2?** | Every floor-set question, the ending, creation, the pitch | Adopt **B + C** (free, already canon); **rule on A** |
| **D-02** | **Frame-A or Frame-B** — do the audience nouns keep their names? | **2.6% vs 21.9% of all content; S vs L effort** | **Frame-A** — the later ruling, stronger fiction, nearly free |
| **D-03** | **Scope of "shapes history for 250 years"** — myth-layer, or the events? | Nikita, the ending's meaning, the epithet catalog's premise | **Narrow — myth-layer only** |
| **D-04** | **May a god's tip touch a die or requirement in combat?** | Decides whether the casino is a *frame* or a *system*; 11 of 24 gods are mechanically empty without it | **Yes — via ASSIST and NUDGE only**, never a to-hit |
| **D-05** | **Ascension's two doors** — divinity buy-in vs the "unwagerable" exit | The ending cannot be staged until ruled | Tie to the Floor-10 victory condition rather than a retirement door |
| **D-06** | **What artifact is v2?** A forked book, a delta layer on v1, or game-only? | Determines whether any of this is ever written down as rules | Delta layer first — `ttrpg-update-plan.md:21-45` read in reverse is the manifest |

### Tier 2 — system shape

| # | Decision | Note |
|---|---|---|
| **D-07** | **The Exposure ladder under gods** — do Viewers stay a spectacle meter with the economy moving to per-god affection, and does the **Follower tier survive at all**? | The single biggest §17 decision |
| **D-08** | **Is a patron's tip a Directive, or a separate channel?** | Canon currently says both |
| **D-09** | **With a finite god roster, does a Goal still convert a Patron?** | If yes, Patron Tokens gain a hard supply cap and §4.2 skill caps need re-pricing |
| **D-10** | **When the odds board turns to you, what doubles?** | Spectacle / affection / the wager itself |
| **D-11** | **Do tags carry crowd domains, god domains, or both?** | 12 vs 26; only `chaos` overlaps. Blocks the §18 content pass |
| **D-12** | **Where do demons live in v2's cosmology?** | Recommend **the house's court**. Blocks the whole Medium route |
| **D-13** | **Name the house / the fallen god running the table** | §17.5's rewrite needs the noun; nothing in canon supplies it |
| **D-14** | **Approve the anti-prime as the curse chassis** | Zero new machinery; unblocks every `trial_table` in the roster |
| **D-15** | **Pick the Super Boss ladder** | Shrine→Temple→Pantheon / Legend→Age-Ender→The House |
| **D-16** | **Does the mycelium theme survive?** Your own rebrand note names *"a mycelium-Corporation with a clear evil motive"* as the problem (`setting-rebrand-options.md:4-5`) — but the mycelium is also the Incinedile's entire discoverable-win-condition design (6 phases, breach paths, network-as-body-part, play-tested) | Recommend **keep the mycelium, drop only the Corporation's ownership of it** — a fungal puppet-god reads *more* casino than corporate, and retiring it costs a play-tested boss its identity for no gain. **Corrects an existing audit:** `campaign-residuals-audit.md:221` says *"No Corporation-flavored text exists in enemies.json"* — true of the word, false of the fiction (the Incinedile is a mycelium puppet; the campaign shopkeep is *"Mycelius Chrom Production Co"*). 3-record cluster |
| **D-17** | **What do contestants believe about the audience?** | Changes Fourth Wall, Fan Service, Parasocial, and the register of the whole broadcast layer |
| **D-18** | **Name the Advanced Fabricator's god** | Sharpest tonal risk in the economy slice; a bankrupt smith-god also fills a flagged gap |
| **D-19** | **Legendary / Mythic / Godly — keep, or free the words?** | "Godly" becoming literal is an upgrade; "Mythic" running four ladders at once is not. Cheapest to decide **before** Legendary affixes and epithet grades ship |
| **D-20** | **Adopt the Nikita adjacency separation rule?** | No shared scene/floor/episode with the Abrahamic-corporate satire |

### Tier 3 — housekeeping (cheap now, expensive later)

| # | Item | Fix |
|---|---|---|
| **D-21** | **Record D-V2 as superseding** `setting-rebrand-options.md:155-156` | One line |
| **D-22** | **Four items are "ruled twice but still listed OPEN"** — Momus, the title, the timer, the Forsaken manual trigger | Reconciliation, not re-decision. Currently generating false open-signals across `DIRECTION.md`, `gdd.md`, `brief.md`, `narrative-design.md` (which also contradicts itself) |
| **D-23** | **`data/tags.json` is back to 100 rows** — the 84-tag pruning + 5 epithet migrations are **not reflected in data** (the I-8 description port re-added 16 rows) | Decide whether 84 or 100 stands, then make data match |
| **D-24** | **Mark `setting-rebrand-options.md:38` SUPERSEDED** | It still reads as the decision that tags *become* epithets, which the same day's Q2 ruling overturned |
| **D-25** | **§2.3's Command/Persuade/Intimidate contradict R18** ("Charm is NOT charisma") — a **v1 bug, not a v2 issue** | The R18 sweep reached skills but never the action table. Note a stat move owes skill-point refunds |
| **D-26** | **The Phase-4 divergence guard was never written** | Write the three-way consistency appendix; the book never references the addendum |
| **D-27** | **Firearms in v2 — confirm the inference** | The chain is strong (VIP table = human pop culture; §12.7 already fuses guns with myth — *"the ammo is the blade"*) but **no v2 doc names guns anywhere.** Carve out the Fabricator's L3 railguns/micro-nukes separately |
| **D-28** | **The `'Corporate'` SQL enum — fix now or at KAN-7?** `source_type TEXT NOT NULL DEFAULT 'Patron' CHECK (source_type IN ('Patron', 'Corporate', 'Crowd'))` at `data/migrations/001_initial_schema.sql:212` | **This is the one piece of v1 fiction the freeze does not protect** — it is CHECK-constrained *in the v2 repo*. ~10 minutes today; a data migration once Stage-1 saves exist. Recommend **now**. Everything else is Mongo blob keys (`exposure.viewers`, `cameraCallUsed`, `objectives.directives`) which are v1-frozen and cost zero; all 11 Mongoose models are v1-clean |
| **D-29** | Archive rather than migrate the `messages` collection | 48/49 rows are OOC chat; 19 are duplicate spam |
| **D-30** | Confirm the **contestant/champion** register split | Broadcast plane vs wager plane — so the two live nouns are deliberate, not drift |

*Slice-local questions not promoted here (Farm justification, Wizard's Tower → Sanctum, the
Goldsmith's "cage", Box Namer HOUSE lane, coupon renames, Med Bay comp-vs-marker) are listed
in full in the research appendices.*

---

## 9. Recommended sequence

1. **Close Tier 1** (D-01 … D-06). Six decisions; they gate everything else.
2. **Write the v2 delta artifact** (D-06) — using `ttrpg-update-plan.md:21-45` reversed as
   the import manifest, and §4 above as the explicitly shared spine.
3. **Redesign §17** — the only chapter needing genuine design work. Everything else is a
   voice pass.
4. **Do the voice pass** — the book's register re-pointed from Corporation satire to
   investor-religion satire. Largest writing job; fully parallelisable.
5. **Write the shared floor-set question bank**, then author **floors 4–9** against it,
   forking only at content level (§7).
6. **Sweep Tier 3 housekeeping** at any point — it is independent of the rest.

---

## Appendices

| File | Contents |
|---|---|
| [`research/A-framing.md`](research/A-framing.md) | §1–§3, §9, §11, §16 · premise, contestant, Charm, book voice, vocabulary sweep |
| [`research/B-audience-tags.md`](research/B-audience-tags.md) | §17–§18 · all 100 tags walked & classified; the mass-audience vs named-gods analysis |
| [`research/C-economy-lounge-items.md`](research/C-economy-lounge-items.md) | §12, §19–§20 · the firearms question, the divinity-economy layering, the 19-module Lounge walk |
| [`research/D-combat-skills-enemies.md`](research/D-combat-skills-enemies.md) | §4–§15, §21 · the theme-neutral census, skill-name classification, the boss ladder, the fate/odds gap |
| [`research/E-data-audit.md`](research/E-data-audit.md) | 461 records classified · Frame-A vs Frame-B costing · schema-level coupling |
| [`research/F-v2-canon-ledger.md`](research/F-v2-canon-ledger.md) | ~90 decided entries · 31 open residuals · 24 divergence rows (THEME vs IMPL) |
| [`research/G-story-encounters.md`](research/G-story-encounters.md) | Story deltas · the stakes problem · floors 1–6 under v2 · Nikita · the ending · the floor spine |

**Method note.** Seven independent passes, no shared drafting, each required to cite
`file:line`. Where slices converged independently — the fork contradiction (A, F, G), the
tag-count drift (B, F), the diegetic-broadcast mechanism (A, C, E) — confidence is high.
Findings marked INFERRED in the appendices are the researcher's reasoning, not canon; the
firearms verdict (D-27) is the most consequential of these.
