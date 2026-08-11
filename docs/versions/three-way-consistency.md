# Three-Way Consistency Guard — book ↔ app ↔ addendum

**Status:** LIVE — this is the standing guard, not a research note · **Written:** 2026-08-10
(owner-approved as **D-26**) · **Last verified against the files:** 2026-08-11, against
game repo `0159e3d` (+ round 9 `2ae0f90`) and v1 repo `d9c3638`

## What this is

`docs/ttrpg-update-plan.md:208-211` (Phase 4) requires *"a three-way consistency table
(book ↔ app ↔ digital addendum) committed as an appendix"*, and `:219-221` states the rule
it exists to enforce:

> **"Divergence creep:** book and digital addendum will now share ~80% of rules text with
> deliberate differences (D-1 damage model, races, tags). The Phase-4 divergence table is
> the guard — **every difference is either listed there or is a bug.**"

That artifact was never written (`GAME:docs/versions/v1-v2-fork-spec.md:86-89`). Its
absence is why a contradiction lived from 2026-07-16 to 2026-08-10 unnoticed. This file
closes it.

**The rule, restated so it cannot be missed:**

> ### Any difference between the three canons that is NOT listed in §1 or §2 of this document is a BUG.
>
> Finding one is not an invitation to re-litigate the design. It is a defect report:
> either the divergence is intended and belongs in §1/§2, or one of the three canons is
> wrong and belongs in §3.

## The three canons

| Canon | Artifact | Holds | Who owns it |
|---|---|---|---|
| **TTRPG book (v1)** — FROZEN | `BOOK:rulebook/gpt-system-v1.0.md` (v1.1, 2026-08-04) | Table rules, the original reality-TV / **The Corporation™** / alien-broadcast setting, the live campaign's races, characters and tags | The owner — it is his live table |
| **The app** | `APP:client/` + `APP:server/` | The live campaign tool. It models **the book**, full stop (`GAME:docs/ttrpg-update-plan.md:190-195`) | The campaign; changes ride the book |
| **Digital rules (v2)** | `GAME:docs/rules-addendum.md` (**R0–R25**) | Engine rulings; the sim implements the addendum wherever the book is silent or broken | This repo |

**Citation roots** — every `file:line` below is relative to one of these:

| prefix | absolute root |
|---|---|
| `BOOK:` / `APP:` | `/home/user/Galactic-Prime-Time/` — the char-sheet repo; the book *and* the app live here |
| `GAME:` | `/home/user/Galactic-Prime-Time-Game/` — this repo |

> ⚠️ **Line numbers drift.** Both repos are edited frequently — the book shifted +3 lines
> and the addendum +15 during the single pass that wrote this file. Every anchor is quoted
> by its distinctive text as well as its line, and §4 gives content-based greps that
> re-derive every number. **Re-run §4 before trusting a line here.**

## Governing ruling — D-V2

**`GAME:docs/versions/v1-v2-fork-spec.md:39-50` — v1 is FROZEN; v2 bends.** Where the two
premises conflict, the live campaign does not change; v2 absorbs every change. The live
TTRPG table does **not** re-skin to the Cosmic Casino
(`GAME:docs/setting-rebrand-options.md:155-161`, now carrying the SUPERSEDED marker per D-21).

Its operative test, from `GAME:docs/ttrpg-update-plan.md:27-28`:

> **"Any sentence that needs the word 'god' does not belong in the book."**

Verified: `god`, `gods`, `casino`, `divinity`, `epithet` and `wager` occur **zero** times in
`BOOK:rulebook/gpt-system-v1.0.md`. The only near-hits are the loot tier names *Mythic* and
*Godly* (`BOOK:...:686`, `:936`, `:953`, `:1171`), which predate the frame and are v1-native.
**The firewall currently holds.**

---

## How to use this document

### The THEME vs IMPLEMENTATION test — the distinction this file exists to enforce

Conflating these two kinds of difference is what caused the original mess. Apply the test
in this order:

1. **Does the difference exist because v1 is an alien broadcast and v2 is a gods' casino?**
   → **THEME.** Expected and correct. It goes in **§1**. It is *never* a bug, and it must
   *never* be "fixed" by porting v2 vocabulary into the book. The `god` test above is the
   fast check.
2. **Does the difference exist because a computer needs a number, a tie-break, or a
   procedure where a GM improvises?** → **IMPLEMENTATION.** It goes in **§2**. Legitimate,
   but this is the only kind that can *become* a bug — both sides are modelling the same
   fiction, so drift here is real drift.
3. **Neither?** → It is a **bug or a pending decision.** It goes in **§3**, with an owner
   action.

A useful sharpener: a THEME divergence would still exist if both canons were written by the
same person on the same day. An IMPLEMENTATION divergence would not.

A second sharpener, learned the hard way from **D-25** (see §5): before filing a
contradiction as a divergence, check whether **one canon's wording is simply wrong**. D-25
looked like a v1-vs-v2 stat-mapping fork; it was a too-narrow *definition* in both canons,
and the fix was one shared-spine wording change with no fork at all.

### When to update this document

Update it in the same commit as the change, never afterwards:

- Any new addendum ruling (`Rn`) touching a rule the book also states → add a §2 row, or
  confirm convergence in the list at the end of §2.
- Any book edit (v1 errata, a passover worksheet ruling) → re-check the §2 rows it touches
  **and re-derive the line numbers** (§4).
- Any v2 setting decision that re-skins a shared mechanic → add a §1 row.
- Any app schema/vocabulary migration → re-check the app conformance snapshot.
- Any §3 row that gets ruled → move it into §1 or §2, or delete it, and log it in §5.

### Precedence, when two canons genuinely disagree

- **Inside this repo (v2 / the sim):** `DIRECTION.md` > `rules-addendum.md` >
  `GPT_Master_Compendium.md` > the GDD/architecture PDFs > the rulebook
  (`GAME:docs/DIRECTION.md:206-213`).
- **Inside the book and the app (v1):** the book is the master (D-8); the app models the
  book (`GAME:docs/ttrpg-update-plan.md:190-195`).
- **Across the fork:** D-V2 — v1 never bends.

---

## App conformance snapshot

The app is the third canon and the easiest to drift, because it is edited during live
campaign weeks. Everything below was read directly.

| Check | Book says | App state (file:line) | Verdict |
|---|---|---|---|
| Races | Human / Animal / Robot / AI — `BOOK:...:71`, machines sidebar `:77-83` | `RACES = ['Human', 'Animal', 'Robot / AI']` — `APP:client/src/constants.js:22` | ✅ matches book (D-4) |
| Damage types | The 7 resistance keys incl. Dissolution (§8, §10) | `DMG_TYPES = ['Bleed','Crush','Burn','Chill','Poison','Infection','Dissolution']` — `APP:client/src/constants.js:24` | ✅ matches book |
| Currencies | Upgrade / Patron / Narrative; Boss Tokens retired — `BOOK:...:1129-1135` | `tokens: { narrative, upgrade, patronTokens }` — `APP:client/src/constants.js:84`; `BOSS_TIERS` retired with a comment at `:26-28` | ✅ matches book |
| Token exchange | 25 UT → 1 PT, one-way — `BOOK:...:1150-1151` | Not automated; the GM adjusts balances by hand — `APP:client/src/components/admin/PlayerPanel.jsx:353-361` | ✅ acceptable (GM-adjudicated); see **I-2** |
| v2 leakage | — | Zero hits for `epithet`, `cosmic casino`, `patron god`, `divinity`, `robustness` across `APP:client/src` + `APP:server` | ✅ firewall holds |
| Tag corpus | 100 authoritative tags — `BOOK:...:1022-1121` | 100 in the campaign DB (`APP:CLAUDE.md` backlog §2, seeded 2026-07-25) | ✅ matches book |

---

## 1. THEME divergences — expected, by design (v1 vs v2)

These exist because v1 is an alien broadcast and v2 is a gods' casino. **None of these is a
bug. None of them may be ported into the book or the app.**

| # | Topic | Book (file:line) | Game / addendum (file:line) | Why it diverges | Correct? |
|---|---|---|---|---|---|
| **T-1** | **Who runs the show** — the root divergence; nearly everything below descends from it | *"You were abducted by an alien conglomerate. The Corporation™ films you running its dungeons to prove… colonizing Earth is beneficial"* — `BOOK:...:9-13`; *"a contestant: an abducted human — or animal, or machine — competing in alien-broadcast dungeon runs"* — `:25-26` | The show is a **VIP table in the gods' Cosmic Casino**, run by a fallen/bankrupt god — `GAME:docs/DIRECTION.md:170-175` (D3). Corporation-as-power and the colonization motive are **dead canon** — `GAME:docs/audits/campaign-residuals-audit.md:351` | The entire v2 premise. D-V2 rules that v1 keeps its own | ✅ yes |
| **T-2** | **"Patrons"** | **One-time large donors** (the $5,000-tier watcher); the Patron roster is **permanent** — `BOOK:...:885-888`. Patron Tokens = the skill-cap currency — `:893-896` | **Patrons tier = donator gods**, with **THE patron god** as a singular escort slot above it — `GAME:docs/design/patron-gods.md:14-23`, mapping at `:79` | The plan states it explicitly: *"Patrons in the TTRPG remain paying audience members, never gods"* — `GAME:docs/ttrpg-update-plan.md:25-28` | ✅ yes |
| **T-3** | **Followers / the exposure ladder** — *ruled 2026-08-10; not in any prior register* | **Abstract decaying count** of paying watchers at phone-vote money, billions-scale — `BOOK:...:880-884` | **Followers = reverence = divinity**: a roster of **named, individual living beings** (dozens, not millions). Viewers stay abstract billions — `GAME:docs/versions/v2-decisions-round2.md:604`, `:627-631` (Q-18/Q-26) | v2 needed a divinity currency; the round-5 pass found Followers already were one. The round-2 doc itself calls this *"a mechanical fork, not a re-skin"* — `:615-618` | ✅ yes — but it **forks a shared mechanic**, so it must stay listed here |
| **T-4** | **Camera Call** — *broke convergence 2026-08-10* | Gains **AND** losses from the spotlit contestant are **doubled**; self-calls legal; one spotlight; ends with that contestant's current-or-next action — `BOOK:...:898-909` | **Double or nothing on a declared action** — the table gambles on the *specific act* the player names; a failed call **burns earned reverence** (named Followers walk away) — `GAME:docs/versions/v2-decisions-round2.md:932` (D-10), `:1115-1120` (Q-32) | v2 needed the broadcast plane and the wager plane to fire together (Frame-C); a passive multiplier is variance, a declared bet is agency — `:943-953` | ✅ yes as a v2 fork — **but the addendum has not absorbed it: see U-4** |
| **T-5** | **Epithets** | **Do not exist** — zero occurrences of "epithet" in the book | A second identity track: traits → myth recreation → epithets, graded ORV-style — `GAME:docs/design/patron-gods.md:126-150` | Pure v2 addition; pantheon-native. Excluded from the book by `GAME:docs/ttrpg-update-plan.md:22-24` | ✅ yes |
| **T-6** | **Tag vocabulary — the 7 renames** | The authoritative 100-tag list with the owner's descriptions — `BOOK:...:1017-1121` | Same 100 tags, 7 renamed — `GAME:data/tags.json`. Verified by id-aligned name diff (tag ids are book-list positions): **6** LEEROY JENKINS→**Reckless** · **14** Animal Planet→**What a Beaut** · **16** Corporate Asset→**Shill** · **19** Chunky Salsa Rule→**Gorefest** · **42** Certified Fresh→**Heart Melter** · **43** SAG Dispute→**Not My Job** · **57** Sea World Reject→**Winter Sheep**. The other **93 are identical** | Real-world trademark/IP exposure (`Animal Planet` = Discovery; `LEEROY JENKINS` = WoW meme) plus dead canon (`Corporate Asset` → the house). Per-row rationale at `GAME:docs/audits/campaign-residuals-audit.md:47`, `:55`, `:57`, `:60` — note the audit *proposed* different replacements ("The Charge", "Nature Special", "House Asset", "Splatter Reel"); the owner's 2026-07-17 list is what landed | ✅ yes — and the **count** is now reconciled at 100 on both sides (D-23, `GAME:docs/versions/v2-decisions-round2.md:935`) |
| **T-7** | **Tag sourcing channel** | *"Player-proposed tags must appear on TVTropes.org"* — `BOOK:...:972` | TVTropes is **not** an authority; the dependency is internalized (seeded in-game vocabulary + the separate epithet track) — `GAME:docs/audits/campaign-residuals-audit.md:357`; `GAME:docs/setting-rebrand-options.md:38` | A table can consult a wiki mid-session; a shipped game cannot depend on a third-party site for its identity vocabulary. Also an IP posture | ✅ yes |
| **T-8** | **Directives / the house voice** | *"Directives (corporate quests) — Issued by The Corporation and its subsidiaries… Consequences are the Corporation's to write"* — `BOOK:...:920-928` | Directives are the **house** (the fallen god running the table) speaking; System messages are the house channel; Goals = side bets from the gallery — `GAME:docs/audits/campaign-residuals-audit.md:358`; `GAME:docs/design/patron-gods.md:80-82` | **Mechanics identical, voice re-skinned.** Nothing here changes what a Directive does | ✅ yes |
| **T-9** | **The Lounge's voice** | *"The party's corporate-controlled modular base"*; the Golden Cage pillar — *"the Corporation profits either way"* — `BOOK:...:1179-1194` | **The comp suite** — the house comps your room; surveillance = the house watching its assets — `GAME:docs/audits/campaign-residuals-audit.md:359`; `GAME:docs/setting-rebrand-options.md:36` | Voice only. (The *walkable hub* half is implementation — see **I-11**) | ✅ yes (MIXED with I-11) |
| **T-10** | **Divine intervention in stealth** | Stealth / detection / cover with GM adjudication; **no god lever** — `BOOK:...:822-847` | The diegetic destealth lever is **rival gods** — a rival patron can *curse you unstealthy / out you* — `GAME:docs/rules-addendum.md:671-675` | Excluded from the book by `GAME:docs/ttrpg-update-plan.md:103` (A-25: *"the god-based destealth lever stays game-only"*) | ✅ yes |
| **T-11** | **Forsaken runs** | No analogue | **God-initiated all-in**, never a refusal; tip channel sealed for every god; hardcore by nature — `GAME:docs/design/patron-gods.md:204-215`; `GAME:docs/rules-addendum.md:618-627` | "All help sealed" needs a help channel to seal — it only exists once tips/boons exist. Excluded by `GAME:docs/ttrpg-update-plan.md:22-24`. (Run *types* are implementation — see **I-10**) | ✅ yes (MIXED with I-10) |
| **T-12** | **Mind-collapse epilogue** | *"Completion = the mind collapses: the contestant is permanently removed from play. No revival. Whether what remains is a husk, a puppet, or something worse is the story's to tell"* — `BOOK:...:565-570` | The collapsed character becomes, **forever, a puppet of the one who collapsed it** — an enemy asset the party may meet again — `GAME:docs/rules-addendum.md:144-149` | The *mechanic* ports (A-13, `GAME:docs/ttrpg-update-plan.md:91`); the book deliberately keeps the fiction open with **no god framing** (exclusion `:30`) | ✅ yes (MIXED — the book's openness is a table choice, the game's specificity is content) |
| **T-13** | **Ascension / the divinity economy** | The Ascension analogue is a Lounge/NG+ idea; the audience economy is three counters — `BOOK:...:873-896` | Winners take wagered currency → gain divinity → **join the table as gamblers**; the final winner decides how 250 years of history are remembered — `GAME:docs/cosmic-casino-canon.md:41-46` | Needs a currency the gods also spend. Nothing in v1 has a slot for it | ✅ yes |
| **T-14** | **Enemy provenance & arenas** | The enemy chapter is a statting guide with no cosmology — `BOOK:...:1251-1301` | Monsters are **followers of gods** in three states; arenas are shaped by the judge god's psyche — `GAME:docs/cosmic-casino-canon.md:76-77`, `:148-155` | Licence-free content pool + the v2 spine. Zero mechanical effect on the book's statting guide | ✅ yes |
| **T-15** | **Boss / Super Boss naming ladder** | Mobs / Elites / **Bosses** (Neighbourhood → District → City) / **Super Bosses** (Precinct → Country → Stage) — `BOOK:...:1253-1259` | Bosses **Shrine → Temple → Pantheon**; supers **Legend → Age-Ender → The House** — `GAME:docs/versions/v2-decisions-round2.md:783` (D-15), adopted at `:993` | The v1 names are geographic (a colonized Earth); the v2 names are theological. Categories, counts and doctrine are unchanged | ✅ yes |
| **T-16** | **The mycelium → puppeteering** | Not book content (campaign boss material); v1 keeps the mycelium unchanged | **Dropped in v2**; **Q-34 ruled 2026-08-10: puppeteering replaces it** — the Floor-0 god is a puppeteer and the party finds *strings* in the boss — `GAME:docs/versions/v2-decisions-round2.md:1015` (drop), `:1160-1180` (Q-34) | Ruled v2-only under D-V2. Mechanically a drop-in: network-as-body-part, breach paths and sever points map onto strings one-for-one, so nothing play-tested is lost | ✅ yes — v2-side re-authoring of 3 records + 1 NPC is pending, and **Q-35** (is the Incinedile the Floor-0 boss?) is open at `:1189` |
| **T-17** | **Data-layer voice** | The Corporation issues Directives (T-8) | `patron_goals.source_type` CHECK enum now reads `('Patron', 'House', 'Crowd')` — `GAME:data/migrations/001_initial_schema.sql:212` | This was the last Corporation residue enforced by a SQL constraint; **D-28 applied 2026-08-10** — `GAME:docs/versions/v2-decisions-round2.md:997-1000` | ✅ yes — **corrects the prior register, which still lists this as pending** |

---

## 2. IMPLEMENTATION divergences — tabletop vs digital

These exist because an engine needs a number, a tie-break or a procedure where a GM
improvises. **These are the only differences that can turn into bugs**, because both sides
are modelling the same fiction.

| # | Topic | Book (file:line) | Addendum / sim (file:line) | Why the engine needs it | Reconcile? |
|---|---|---|---|---|---|
| **I-1** | **Damage model** | *"Deal the attack's **listed damage** to that part, minus flat resistance (floor 0)"* — `BOOK:...:429-434` | **`damage = max(0, Force − Robustness)`** — the force gate and the number are one subtraction; a blocked hit can still land Shock but seeds no conditions — `GAME:docs/rules-addendum.md:536-545` (R14) | Ruled as a deliberate split: **D-1**, *"book keeps the listed-damage model; R14 stays digital-only"* — `GAME:docs/ttrpg-update-plan.md:111`, rationale `:47-52` | **No** — permanent by ruling. Revisit for a table edition only if the digital playtest proves the feel |
| **I-2** | **Patron-Token exchange** | Kept and priced: **25 Upgrade Tokens → 1 Patron Token**, one-way — `BOOK:...:1148-1151` | **CUT from the digital game** — Patron Tokens come only from the audience loop — `GAME:docs/rules-addendum.md:234-236` (R10/D7) | The exchange bypasses the flagship audience system and ignored token tiers; at a table the GM prices it by feel | **No.** ⚠️ The book has moved **twice** since the plan: plan D-2's tier-aware ladder (Bronze 5:1 … Godly 1:2, `GAME:docs/ttrpg-update-plan.md:112`) is **superseded book-side** by the flat 25:1 |
| **I-3** | **Races** | **Human / Animal / Robot / AI** — `BOOK:...:71`, machines-and-conditions sidebar `:77-83`, GM-shaped non-standard bodies `:416` | **Robot removed entirely** — playable = any living thing on Earth (Humans + Animals) — `GAME:docs/rules-addendum.md:576-582` (R16); data `GAME:data/races.json` = 2 rows (`human`, `animal`) | Not required by the casino frame — the book-side reason is **campaign continuity** (XQUEZ/T is a live table character). D-4 + exclusion `GAME:docs/ttrpg-update-plan.md:31-33` | **No** — permanent by ruling. The app correctly follows the book (`APP:client/src/constants.js:22`) |
| **I-4** | **Body composition** | Non-standard bodies get **GM-shaped part layouts** — `BOOK:...:415-417` | **R21 Lego-style typed-part library** — base parts + an animal-parts library, each part with a size range — `GAME:docs/rules-addendum.md:685-708` | A GM invents a sea lion's part layout in ten seconds; a creation UI needs a typed catalog. Exclusion `GAME:docs/ttrpg-update-plan.md:43-45` | **No.** Book-side sitting deferred (animal-parts sitting, Q61) |
| **I-5** | **Enemy attention / targeting** | GM decides (an optional sidebar was suggested, never written) | **R23 Antagonism engine** — a serialized weighted-random draw per opponent, proximity base × grudge/mockery/mercy, 50/50 anchor, personality types — `GAME:docs/rules-addendum.md:777-801` | The GM *is* the table's version of this. Exclusion `GAME:docs/ttrpg-update-plan.md:40-42` | **No** — the plan offers an optional one-paragraph GM sidebar as the only book-side echo |
| **I-6** | **Feints** | Feint appears only as a CHAIN-prime example (*"Feint → Pressure Strike"*) — `BOOK:...:244`; no read/counter rule | **R24 feint-read**: smart mobs read feints by **Mind** through the R22 threshold machinery; a read feint is wasted and adds mock-grudge — `GAME:docs/rules-addendum.md:803-824` | A balance finding from digital play (feint dominance) that a GM answers by judgement | **No** — but if the table ever finds the same dominance, this is the ready-made book patch |
| **I-7** | **Hype / crowd goals / attribution** | The audience chapter gives structure, not rates — `BOOK:...:871-961` | Deterministic hype engine with per-event weights; ONE active crowd goal offered at Clock resets from a salted RNG stream; `completed_by` attribution; *takedown = a kill YOU caused* — `GAME:docs/rules-addendum.md:281-310` | A GM feels crowd response; an engine must compute it, and must not perturb the Forced-Action RNG stream. Exclusion `GAME:docs/ttrpg-update-plan.md:40-42` | **No** |
| **I-8** | **Boss explosion beats / KO** | No such choreography (the GM narrates) — doctrine only, at `BOOK:...:1282-1292` | Telegraph → escape window → blast → caught = **Helpless 2 Clocks** → retreat → next Threshold; wounds persist across the valve — `GAME:docs/rules-addendum.md:386-404` | A scripted phase machine needs exact beat boundaries; the book names the *pattern* (`:1282-1286`) and leaves the beats to the GM | **No** — the book's doctrine and the engine's machine agree in substance |
| **I-9** | **Boss death routing** | Doctrine prose: *"Most bosses' win condition is reaching the position where a killing hit is even possible… Raw damage races are anti-design"* — `BOOK:...:1280-1281` | A hard engine invariant (F2): **HP damage never touches a hidden part; death/removal routes ONLY through a lethal, EXPOSED part** — `GAME:docs/gdd/decision-log.md:190-201` | A GM enforces doctrine by refusing a move; an engine must close every bypass (nine were found and closed) | **No** — same rule, one advisory and one enforced |
| **I-10** | **Run types & death** | One campaign, one GM: death rules are §7.5's — `BOOK:...:451-464` | **Run types** decide death: softcore respawn / hardcore permadeath / Forsaken — `GAME:docs/rules-addendum.md:618-627` (R17) | A shipped game needs a difficulty surface without a difficulty menu. Exclusion `GAME:docs/ttrpg-update-plan.md:34-35`. (Forsaken itself is THEME — **T-11**) | **No** |
| **I-11** | **The Lounge as a place** | A GM chapter: house rules, downtime actions, module tree, Upgrade-Token sinks — `BOOK:...:1179-1250` | A **walkable hub** you physically enter; the exclusive place for loot-opening / contract review / tinkering; entering it **resets roaming monsters** — `GAME:docs/gdd/gdd.md:237-245` | A tabletop Lounge is a conversation; a video-game Lounge is a scene with a spatial cost, and roaming resets are the price of retreating | **No.** (Voice half is **T-9**) |
| **I-12** | **Vocabulary firewall** | The book's condition taxonomy and race list are canon for the book *and* the app | The sim uses the rulebook condition vocabulary **plus this repo's own seed enums**, and `GAME:CLAUDE.md` forbids importing the app's `DMG_TYPES`/`RACES` | The game removed the Robot race (I-3), so the app's `RACES` is wrong *for the sim* even though it is right for the book | **No** — but ⚠️ the CLAUDE.md rule's stated *reason* is stale; see **U-7** |
| **I-13** | **Determinism contract** | No analogue — a table has dice and a GM | State is a pure function of (seed, ordered command log); no wall-clock reads, no unlogged randomness; saves = snapshot + log offset — `GAME:docs/DIRECTION.md:62-79` (TECH-1, core at `:64-68`) | Replay, spectate, co-op sync and Stage-2 broadcast all fall out of this one property | **No** — this constraint is the reason several §2 rows exist at all |
| **I-14** | **Where the rules math lives** | The GM computes; the sheet records | The app performs **no rules math server-side** — `state` is a Mixed blob and every formula lives client-side (`GAME:docs/ttrpg-update-plan.md:130-133`); the sim is authoritative in v2 | The app is a *sheet*, the sim is a *referee*. Shared helpers (`traitTotal`/`capBonus`/`effectiveMaxHp` in `APP:client/src/constants.js`) are the app's answer to formula drift | **Partly** — the plan's B-3 hardening (server-side spend guards) is recommended and not done. Not a divergence *from the book*, but the reason app↔sim drift is cheap to create |

### Convergent — listed so they do not raise false alarms

Verified identical in substance and, in several cases, in wording:

| Topic | Book | Addendum |
|---|---|---|
| **Charm = presence** (looks, bearing, voice, facial control, body language; not warmth, not a cosmic pull) — and §2.3's Command / Persuade / Intimidate keying off it is correct under that reading | `BOOK:...:52-59`, action table `:102-104` | `GAME:docs/rules-addendum.md:596-601`, widening errata `:604-618` (**D-25, ruled 2026-08-10 — a shared-spine fix applied to both canons**) |
| Priming replaces cooldowns (5-type vocabulary CHAIN / STANCE / STACK / STATE-POSITION / PREP-CHANNEL) | `BOOK:...:237-251` | `GAME:docs/rules-addendum.md:90-107` — which also records the G1 supersession at `:98-104`, putting the addendum *ahead* of book §4.6 here (see **U-4b**) |
| Combined actions: linked declarations, assists provide requirements, merged damage counts as **ONE hit**, failure degrades and never vetoes | `BOOK:...:341-357`, one-hit rule `:350-352` | `GAME:docs/rules-addendum.md:547-572` (R15) |
| Dodge thresholds ask the dodger's **Reflexes**, with the 1d4 threshold-die fallback, both directions | `BOOK:...:797-803` | `GAME:docs/rules-addendum.md:739-747` (R22) |
| Tactical Roll = declared-hex dodge; no stance, charges or cooldown; movement forfeit is the cost; AREA attacks miss unless the destination hex is the centre | `BOOK:rulebook/skills-passover.md:7-11`, `:16-18` (G1) | `GAME:docs/rules-addendum.md:826-835` (R25 — it cites the book's own G1) |
| Death = head or torso at 0 HP; Dissolution is a tierless 2-Clock Mind timer that pauses, never resets | `BOOK:...:451-464`, `:565-570` | `GAME:docs/rules-addendum.md:150`, `:144-149` |
| Traits have no cap — *"play pushes traits past 5 with no ceiling"* | `BOOK:...:65-68` | `GAME:docs/rules-questionnaire.md:482-483` (Q5 RULED 2026-07-23) |
| The six tag patterns, including **pattern 6 = tags GATE unlocks** | `BOOK:...:976-991` | `GAME:docs/rules-addendum.md:723-726` |

---

## 3. Unreconciled — these are bugs or pending decisions

Everything here is a difference **not** explained by §1 or §2. Each needs an owner action or
a propagation pass.

| # | Topic | Where | What's wrong | Owner action needed |
|---|---|---|---|---|
| **U-1** | **The book never references the addendum** | `BOOK:rulebook/` + `BOOK:docs/` — zero matches for "addendum" anywhere in the v1 repo (`grep -rli addendum` over `.md`/`.js`/`.jsx`/`.json`) | The link is one-way: the addendum cites the book constantly (R25 cites `skills-passover.md` by name), the book cites nothing back. A book reader has no way to know a digital canon exists or that this guard governs it | **Decide:** add a one-line "About the digital edition" note to the book pointing at this file, or accept the one-way link as intentional and record that decision here |
| **U-2** | **Healing at the Lounge — the addendum is pre-GL6** | Book: free rest gives **+1 HP per part per downtime**; the full restore is **INVOICED at the Med Bay** at `Floor × 2^claims` UT — `BOOK:...:855-864` (GL6, `BOOK:rulebook/lounge-passover.md:61-68`, 2026-07-25). Addendum: *"At the Lounge, HP restores fully and resolvable conditions resolve"* — `GAME:docs/rules-addendum.md:244-247` (B11, PROVISIONAL, from R10 ≈ 2026-07-14) | The addendum's rule predates the book's Lounge ruling by ~11 days and was never updated. **Not a theme divergence and not an engine necessity** — it is stale text. The field half (no regeneration, no item restores HP, a Moment to apply a treatment) still matches — `BOOK:...:851` | **Propagate GL6 into the addendum** (free rest = trickle; full restore = priced), or rule the free restore a deliberate digital simplification and move the row to §2 |
| **U-3** | **The 2026-07-23 → 07-25 book rulings are not absorbed generally** | The book reached v1.0/v1.1 with a fully ruled economy (§19), Lounge (§20), tags chapter (§18) and **Boss Tokens retired into Upgrade Tokens** (`BOOK:...:1129-1135`; `APP:client/src/constants.js:26-28`). The addendum still lists Upgrade Tokens as *"out of engine scope"* — `GAME:docs/rules-addendum.md:248-249` (B14) — and still speaks of a *"Boss-Token → Patron-Token exchange"* at `:234` | The digital canon has not diffed against the book since the book's biggest content pass. **U-2** and **U-4** are two symptoms; §19/§20 likely hold more. (R18 *was* propagated on 2026-08-10, so the channel works when it is used) | **Run one propagation pass** over addendum R10 and the economy lines against book §16, §19, §20 — then re-verify this file |
| **U-4** | **Camera Call D-10/Q-32 are not in the addendum** | Ruled: **double or nothing on a declared action** (`GAME:docs/versions/v2-decisions-round2.md:932`), and a failed call **burns earned reverence** (`:1115-1120`, Q-32). Implemented: the v1 doubling model — *"spectacle points attributed to the spotlit combatant are doubled"* — `GAME:docs/rules-addendum.md:281-289` (R11 #13), with sim tests behind it | The v2 rulings supersede the addendum's implementation and the addendum does not say so. Until it does, the sim implements the **book's** Camera Call while v2 canon says otherwise. **T-4** records the intended fork; this row records that it is unpropagated | **Amend R11 #13** to record D-10 + Q-32 as superseding, then schedule the engine change (it also needs the named-Follower ledger from **T-3**, which does not exist yet) |
| **U-4b** | **Book §4.6's STANCE example is stale** | *"STANCE \| be holding a declared stance \| **defensive footwork enabling Tactical Roll**"* — `BOOK:...:245` | Contradicted by the book's own repo: **G1 RULED — no stance, no charges, no cooldown; the cost is the movement forfeit** (`BOOK:rulebook/skills-passover.md:7-11`), which `GAME:docs/rules-addendum.md:826-835` (R25) adopts verbatim and `:98-104` records. The example line survived the passover edit | **v1 errata** — replace the STANCE example with a skill that actually uses a stance. Read-only from this repo; the book owner applies it |
| **U-5** | **The tag-count ruling and the addendum disagree** | Addendum: *"84 live tags; 5 words moved to the epithet track; K-pop cluster removed"* — `GAME:docs/rules-addendum.md:723-726`. Ruled 2026-08-10: **100 tags stand; the 84-pruning is retired** — `GAME:docs/versions/v2-decisions-round2.md:935` (D-23). Data: `GAME:data/tags.json` = 100 rows including all five epithet words | The *data* is now correct and blessed; the addendum's ruling text was never updated, so the addendum contradicts the newer ruling. The round-8 flavour list also re-homes *Nine Lives* and *Unkillable* to the epithet track (`:1008`) while they remain live tag rows — those two statements need squaring | **Amend `rules-addendum.md:723-726`** to record D-23 as superseding, and state explicitly whether the 5 epithet words are tags, epithets, or both |
| **U-6** | **`GAME:CLAUDE.md`'s drift warning cites a reason that no longer exists** | *"Do NOT import the character-sheet app's DMG_TYPES/RACES lists (known drift — see review-1)"* — `GAME:CLAUDE.md` Hard rules | The app was migrated to the book taxonomy on 2026-07-25: `DMG_TYPES` = the 7 resistance keys incl. Dissolution, `RACES` = Human/Animal/Robot / AI (`APP:client/src/constants.js:22-24`). The **rule still stands** (I-3: the game removed Robot; I-12: the sim owns its enums), but the quoted rationale describes a state that ended two weeks ago | **Reword the CLAUDE.md line** to cite I-3 / I-12 instead of "known drift" |
| **U-7** | **Doc-state: D-26 was recorded as done before it existed** | *"Group D — housekeeping, applied: … D-26 (the three-way consistency guard, **written**)"* — `GAME:docs/versions/v2-decisions-round2.md:997-998` | `docs/versions/three-way-consistency.md` did not exist when that line was written. A completion claim outran the artifact — exactly the failure mode this guard exists to catch | **None beyond this file existing** — the claim is now true. Logged so the pattern stays visible |
| **U-8** | **Both planning docs describe the addendum as "R0–R23"** | `GAME:docs/ttrpg-update-plan.md:18` and `GAME:docs/versions/v1-v2-fork-spec.md:78` both say *"`docs/rules-addendum.md` R0–R23"*. It actually runs **R0–R25** (26 `## Rn` headings; R24 at `:803`, R25 at `:826`) | Cosmetic, but it is a canon-inventory statement inside the two documents that *define* the canon inventory. R24 (feint-read) and R25 (Tactical Roll) are exactly the kind of shared-spine rulings this guard tracks | **Update both lines to R0–R25** when either doc is next touched |
| **U-9** | **Tag effects: 100 rows, 10 effects** | `GAME:data/tags.json` — `effect`, `unlock_conditions` and `goal_modifier_weights` are **empty on all 100 rows** (verified). Only the 10 slice tags in `GAME:data/tag_effects.json` carry mechanics | Not a book divergence — the book's §18.1 six patterns and §18.2 ten flagship riders are the design both sides share. It is an unfinished v2 implementation of a book chapter (tracked as I-27 / R-20) | **None here** — noted so the empty fields are not mistaken for drift from the book |
| **U-10** | **The Phase-4 anchor test does not use real campaign data** | The plan names the KAN-2 criterion-16 fixture test as *"the anchor that all three agree on the advancement math"* — `GAME:docs/ttrpg-update-plan.md:208-211`; criterion text at `GAME:docs/rules-addendum.md:913-914` (*"app-identical derived stats for the five live characters' sheets (fixture test against **real campaign data**)"*) | The test exists (`GAME:tests/test_kan2_acceptance.gd:363-398`) but its fixtures are **hand-derived from the R6 formulas**, and its own comment says *"all of the campaign's level-6 sheets sit below every over-10 threshold → zeros"* (`:360-362`). Four of five rows are synthetic values chosen to exercise the branches, so the over-10 formulas are tested against the formulas, not against the app | **Decide:** export the five live sheets into a committed fixture and assert against those, or amend criterion 16 to drop the "real campaign data" claim. As written, the criterion overstates what it proves |
| **U-11** | **T-16's re-authoring is outstanding** | Q-34 ruled puppeteering replaces the mycelium — `GAME:docs/versions/v2-decisions-round2.md:1160-1180`. Records still to re-author (v2 only): the Incinedile · Mycelium Core · Mycelium-Threaded Hide · the "Mycelius Chrom Production Co" shopkeep | Not a book divergence — v1 keeps the mycelium by ruling. Listed because until the v2 records are re-authored, this repo's *data* still says mycelium while its *canon* says strings, and a future sweep will read that as drift | **Q-35** (is the Incinedile the Floor-0 boss?) and **Q-36** (rename wording) are open at `:1189-1190`; the re-authoring waits on them |

---

## 4. Verification method

Everything above was checked by reading the files. Reproduce it — the greps find anchors by
content, so they survive line drift:

```bash
BOOK=/home/user/Galactic-Prime-Time
GAME=/home/user/Galactic-Prime-Time-Game

# --- the "god test": the v1/v2 firewall. Expect ZERO hits. ---
grep -niE '\bgod\b|\bgods\b|casino|divinity|epithet|wager' $BOOK/rulebook/gpt-system-v1.0.md
#   "Mythic"/"Godly" are loot tiers and do NOT match \bgod\b — that is intentional.

# --- does the book know the addendum exists? Expect ZERO hits (U-1). ---
grep -rli 'addendum' $BOOK --include='*.md' --include='*.js' --include='*.jsx' --include='*.json'

# --- app vocabulary conformance (snapshot table) ---
grep -n 'export const RACES\|export const DMG_TYPES\|tokens:' $BOOK/client/src/constants.js
grep -rniE 'epithet|cosmic casino|patron god|divinity|robustness' $BOOK/client/src $BOOK/server

# --- tag corpus: book list vs game data, id-aligned (T-6, U-5) ---
python3 - <<'PY'
import re, json
book = open('/home/user/Galactic-Prime-Time/rulebook/gpt-system-v1.0.md').read().split('\n')
start = next(i for i, l in enumerate(book) if l.startswith('### 18.3'))
btags = [m.group(1) for l in book[start:start+110]
         if (m := re.match(r'^- \*\*(.+?)\*\* —', l))]
game = {r['id']: r['name'] for r in json.load(
    open('/home/user/Galactic-Prime-Time-Game/data/tags.json'))}
norm = lambda s: re.sub(r'[^a-z0-9]', '', s.lower())
print('book', len(btags), '| game', len(game))
for i, b in enumerate(btags, 1):                    # tag id == book list position
    g = game.get(i)
    if g and norm(g) != norm(b):
        print(f'  id {i:3}: book "{b}" -> game "{g}"')   # expect exactly the 7 renames
PY

# --- the SQL enum (T-17): expect ('Patron', 'House', 'Crowd') ---
grep -n 'CHECK (source_type IN' $GAME/data/migrations/001_initial_schema.sql

# --- addendum ruling inventory (U-8): expect 26 headings, R0..R25 ---
grep -c '^## R[0-9]' $GAME/docs/rules-addendum.md

# --- the anchor test (U-10) ---
sed -n '/func test_16_stat_economy/,/^func /p' $GAME/tests/test_kan2_acceptance.gd

# --- re-derive every book line number in this file after a book edit ---
grep -n '^#\{2,3\} ' $BOOK/rulebook/gpt-system-v1.0.md
```

Distinctive strings used as the content anchors for each row (grep these to re-derive a
line): `You were abducted by an alien conglomerate` · `You are a **contestant**` ·
`**Charm** — **presence**` · `| Command | Charm |` · `Play pushes traits past 5 with no` ·
`Race: **Human**, **Animal**, or **Robot/AI**` · `Sidebar — machines & conditions` ·
`Feint → Pressure Strike` · `defensive footwork enabling Tactical Roll` ·
`count as ONE hit` · `Non-standard bodies (Animals, machines) get GM-shaped` ·
`Deal the attack's **listed damage**` · `Completion = the mind` ·
`The threshold asks the dodger's Reflexes` · `**HP does not regenerate**` ·
`The full medical restore is INVOICED` · `**Followers** — **paying watchers**` ·
`**Patrons** — **one-time large donors**` · `must appear on TVTropes.org` ·
`**25 Upgrade Tokens → 1 Patron Token**` · `corporate-controlled modular base` ·
`Raw damage races are anti-design`. Addendum: `MIND COLLAPSE:` ·
`Boss-Token → Patron-Token exchange (D7` · `Healing & downtime (B11` ·
`13. **Camera Call (spectacle engine v1)` · `FINALIZED FUNCTION (owner 2026-07-20` ·
`RULED: the Robot race is REMOVED entirely` · `WIDENED 2026-08-10 (owner, D-25)` ·
`The diegetic destealth lever is` · `84 live tags; 5 words moved` ·
`16. Level point → +1 levelBonus`.

### What this pass did NOT check — read this before trusting the coverage

- **Both repos moved under this pass.** The game repo advanced `df8d256 → ed4d28d → 2ae0f90
  → 0159e3d` and the v1 repo landed `d9c3638` (the D-25 errata) while the file was being
  written. Every citation was re-derived afterwards, but **anything committed after
  `0159e3d` / `d9c3638` is unreviewed here.**
- **The book was read by section, not end to end.** All 1,318 lines exist; I read the
  chapters backing a row here (§1, §2.1–2.3, §4.6, §5.7, §7, §8.2, §14–§21) plus every
  keyword sweep above. **§3 Advancement, §6 Forced Actions, §9 Shock, §10 Resistances,
  §11 States Glossary, §12 Weapons & Equipment (incl. the 2026-08-04 Item Drafting
  additions §12.6/§12.7) and §13 Grappling were not line-read.** A divergence hiding in
  those chapters would not appear here.
- **The other book worksheets were only spot-read** — `economy-passover.md`,
  `tags-passover.md`, `item-drafting-*.md`. Only `skills-passover.md` (G1) and
  `lounge-passover.md` (GL6) were read for content.
- **The app was checked by targeted grep, not reviewed.** `constants.js` and the token UI
  were read; the character tabs, the admin panel's rules math, the server routes and the
  Mongoose models were **not** audited against the book. The app column of this guard is
  therefore thinner than the other two.
- **Nothing was executed.** No sim run, no `scripts/run_sim_tests.sh`, no seed validator;
  Godot availability was not checked. `test_kan2_acceptance.gd` was **read, not run** — the
  U-10 finding comes from its source and its own comments, not from a failing run.
- **The live campaign DB was not inspected.** The app's 100-tag corpus is taken from
  `APP:CLAUDE.md`'s record of the 2026-07-25 migration, not from the database.
- **Content-level divergence was not swept.** Individual skills, items, affixes, materials
  and enemy statlines were not diffed book↔data. This guard covers **rules and setting**;
  content errata are tracked separately (`GAME:docs/review/review-5-compendium-delta.md`,
  `GAME:docs/audits/`).
- **The v2-side round 6–9 rulings were scanned for shared-spine impact, not read in full.**
  `v2-decisions-round2.md` is 1,200+ lines; T-3, T-4, T-15, T-16, U-4 and U-5 came out of
  that scan. Another shared-mechanic fork could sit in the parts skimmed.

---

## 5. Change log

| Date | Change |
|---|---|
| 2026-08-10 | **Created (D-26).** Promoted from `docs/versions/research/F-v2-canon-ledger.md` §3, with every row re-verified against the files. |
| 2026-08-11 | **Re-verified after two concurrent commits.** Round 9 (`2ae0f90`) and the v1 errata (`d9c3638`) landed mid-pass; all citations re-derived. Book anchors shifted **+3** after line 59, addendum anchors **+15** after line 593. Current counts: **17 THEME · 14 IMPLEMENTATION · 8 convergent · 12 unreconciled** (U-1…U-11 plus U-4b, which is filed under U-4 because both are book↔addendum propagation gaps). |
| 2026-08-11 | **D-25 RESOLVED and removed from §3.** It was filed as an unreconciled contradiction (book §2.3 keys Command/Persuade to Charm while §2.1 and R18 define Charm as pure photogenics). **The owner's ruling inverted the fix**: the *definition* was too narrow, not the mappings. Charm is now **presence** (looks, bearing, voice, facial control, body language); §2.3 is untouched; **no skill-point refunds are owed**. Applied to both canons — `BOOK:...:52-59` and `GAME:docs/rules-addendum.md:596-618`, rationale at `GAME:docs/versions/v2-decisions-round2.md:1086-1113`. It now appears as the first **convergent** row. *This is the model case for the second sharpener in "How to use".* |
| 2026-08-11 | **T-16 updated:** Q-34 ruled — **puppeteering** replaces the mycelium in v2 (not the temple-root option that was recommended); v1 keeps the mycelium. New follow-on row **U-11**. **T-4/U-4 updated:** Q-32 ruled — a failed double-or-nothing **burns earned reverence**. |
| 2026-08-10 | **Corrections made to F's register during promotion.** (a) **T-17** — F listed `patron_goals.source_type` as *"still reads `('Patron','Corporate','Crowd')` … casino re-voice pending"*; the enum already reads `'House'` (D-28 applied). (b) **T-6 / U-5** — F wrote the tag state as an open contradiction (its R-19); D-23 has since ruled **100 stands, the 84-pruning retired**, so the count is reconciled and only the addendum's text is stale. F's claim that the data carries "the 7 tags the audit CUT" is true but incomplete: an id-aligned name diff shows the *only* book↔data difference is the **7 renames** — the 7 CUT tags are present in **both**, and the K-pop cluster is in **neither**. (c) **F's R-1** (does the table re-skin?) is **closed** — `setting-rebrand-options.md:155-161` now carries the SUPERSEDED marker. (d) Book citations re-pinned: Patrons `882-886`→`885-888`, Patron Tokens `892-894`→`893-896`, races sidebar `75`→`77-83`, damage `429`→`432`. |
| 2026-08-10 | **Rows added that F's register did not carry:** **T-3** (Followers → named reverence ledger, Q-18) · **T-4** (Camera Call D-10 — F listed Camera Call as *convergent*, which was true until round 8) · **T-7** (TVTropes sourcing channel) · **T-15** (boss naming ladder, D-15) · **T-16** (mycelium → puppeteering) · **I-13** (determinism contract) · **I-14** (where the rules math lives) · **U-1**…**U-11** (F flagged only the absence of this document itself, as its R-28). |
| 2026-08-10 | **Carried but NOT fully verified — `UNVERIFIED (partial 8/20)`.** F's *"Compendium-era canon"* row (20 catalogued supersessions at `GAME:docs/audits/campaign-residuals-audit.md:347-370` plus the never-re-import list `:481-495`) was **not promoted as a table row**: it is a pointer to another register rather than a single divergence, and I verified only 8 of its 20 rows (#1, 2, 5, 6, 7, 8, 9, 10). It remains valid as a reference — treat `campaign-residuals-audit.md:347-370` as an annex to §1 until someone verifies the remaining 12. |
| — | *(Next editor: add a row here in the same commit as any change to §1–§3.)* |
