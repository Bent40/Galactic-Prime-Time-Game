# Issue Register — compiled from reviews 1–6 (current state)

**Compiled 2026-07-15.** Every OPEN issue across reviews 1–6, the questionnaire, and the
compendium delta. Items already resolved (the ~40 review-1 rules defects → addendum R0–R12 +
22/22 green tests; NQ1–NQ4; psychic threshold; brand paradox…) are excluded — this register
is what *remains*.

**Scoring:** F = fundamentality 1–5 (how much else depends on it) · B = blocking 1–5 (does
it stop the next piece of work) · T = time cost 1–5 (5 = weeks) ·
**E = (2F+B)/T** — the efficiency grade; higher = more value per hour.
**🔑 = owner-gated** (needs your answer/decision; I can't unilaterally proceed).

## The register, ranked by efficiency

| # | Issue | Source | 🔑 | F | B | T | **E** |
|---|---|---|---|---|---|---|---|
| I-1 | **Shock has no recovery rule** — engine never decays Shock in combat; certainly wrong | Q21 (post-review-1 gap) | 🔑 | 4 | 3 | 1 | **11.0** |
| I-2 | **Spine naming** — adopt "what cures corruption, and what does it cost" (or your version) as the stated theme; audit beats against it | rev-6 §pri-2 | 🔑 | 4 | 1 | 1 | **9.0** |
| I-3 | **Slice premade contestants** — IP split means the slice needs 2 original contestants designed (concept, stats, 3 skills each) | rev-6 IP ruling + rev-4 §5 | 🔑 | 3 | 3 | 1 | **9.0** |
| I-4 | **PROVISIONAL rulings sign-off batch** — R2 dodge, R3 caps, R4 Burn-Shock, R8 RPM, R9 grapple, R10 halving, R11 log; = questionnaire C/D sections in one sitting | rev-1/addendum | 🔑 | 3 | 2 | 1 | **8.0** |
| I-5 | **IP split final call** — are players' characters in the game at all (with buy-in), or game-original cast only? | rev-6 / story-canon | 🔑 | 3 | 2 | 1 | **8.0** |
| I-6 | **Tutorial HP tuning** — "hard to hurt without killing"; 2-dmg weapons one-shot 2-HP arms; decide boost-part-HP vs easier-HP-gain, then reseed numbers | NQ5 / compendium #7 | 🔑 | 5 | 3 | 2 | **6.5** |
| I-7 | **Schema completion pass** — items rpm/magazine fields, skills `exclusive_to` lock, 3-stat support decision (Camouflage), validator updates | rev-5, R8, R12 | 🔑(3-stat) | 2 | 2 | 1 | **6.0** |
| I-8 | **Tag descriptions port** — the rich tag text lives in the rulebook docx; DB/seeds have empty strings | rev-5 stale-items | | 2 | 1 | 1 | **5.0** |
| I-9 | **Spectacle/hype engine v1** — deterministic audience meter, crowd-goal select, camera-call effect; the differentiator; slice-mandatory; Stage-2 foundation | rev-2 §2, rev-4 §5 | | 5 | 4 | 3 | **4.7** |
| I-10 | **KAN-3 scaffolding** — main scene, GameController autoload, hex renderer, SaveManager, DAL. Recommendation: **DAL loads JSON directly in v1, SQLite deferred** (arch doc's own abstraction principle permits; godot-sqlite vendoring still network-blocked) | rev-3 | 🔑(sqlite deferral OK?) | 5 | 4 | 3 | **4.7** |
| I-11 | **Priming implementation** — remove deprecated cooldown code, add prime states/prep actions/item skips; replace acceptance test 9 | NQ1 ruling | | 3 | 2 | 2 | **4.0** |
| I-12 | **Production cast** — named announcer (broadcast plane) + producer/showrunner (diegetic menace); slice's win/lose framing wants the announcer voice | rev-6 §1 | 🔑 | 3 | 2 | 2 | **4.0** |
| I-13 | **Slice tag set** — ~10 detectable tags with real effects + detectors (full 100 deferred, I-27) | rev-2, rev-6 | | 3 | 2 | 2 | **4.0** |
| I-14 | **Char-sheet app: skill-enrichment render bug** — verify if already fixed; if not, fix (LIVE campaign tool) | compendium §7.4 | 🔑(other repo) | 1 | 2 | 1 | **4.0** |
| I-15 | **Priming vocabulary + skill passover** — levels 1–4 semantics (Q7), upgrade-vs-mutate (Q8), re-express cooldown-texted skills as primes; unblocks I-11 fully | NQ1, Q7–Q8 | 🔑 | 4 | 3 | 3 | **3.7** |
| I-16 | **Enemy AI v1** — mob/elite behavior, Incinedile phase machine + dodge-threshold ability (breach hooks already in engine) | rev-3 gaps, seeds | | 4 | 3 | 3 | **3.7** |
| I-17 | **Story patch bundle** — Nullrot motive, mask rules, Medium continuity bug (farm leader's 170 years), faction points definition | rev-6 §3 | 🔑 | 3 | 1 | 2 | **3.5** |
| I-18 | **Finale design** — what the last episode IS; decide before F3 content locks | rev-6 §6 | 🔑 | 3 | 1 | 2 | **3.5** |
| I-19 | **Vertical slice assembly** — arena scene, 2 contestants, Incinedile P1, hype meter, broadcast win/lose (consumes I-3, I-9, I-10, I-16) | rev-4 §5 | | 5 | 3 | 4 | **3.3** |
| I-20 | **Convergence matrix** — routes × offscreen resolutions → capital state; the route system's payoff | rev-6 §pri-1 | 🔑 | 4 | 1 | 3 | **3.0** |
| I-21 | SessionStart hook: auto-install Godot each session (`.claude/settings.json` — needs your approval) | infra | 🔑 | 1 | 1 | 1 | **3.0** |
| I-22 | Song licensing plan — originals/soundalikes for the Dissolution songs (plan only, no production) | rev-6 §4 | | 1 | 1 | 1 | **3.0** |
| I-23 | **Medium refusal forks + brand-breach rules** — genuine refusal paths per beat; contract breach consequences | rev-6 §3, story-canon | 🔑 | 3 | 1 | 3 | **2.3** |
| I-24 | Nikita's two key scenes — War-fight "win" meaning; the recognition scene | rev-6 §5 | 🔑 | 2 | 1 | 2 | **2.5** |
| I-25 | Party completion — Filipe's song, XQUEZ/T's 7 personalities, Mario's arc, anything for Frod | rev-6 §5, compendium | 🔑 | 2 | 1 | 2 | **2.5** |
| I-26 | Engine thin spots — poison spread topology, dissolution cause-tracking (not slice-critical) | R11 notes | | 2 | 1 | 2 | **2.5** |
| I-27 | Full tag effects (remaining ~90 tags) + goal_modifier_weights | rev-2, schema | 🔑(design) | 3 | 1 | 4 | **1.75** |
| I-28 | Modifier lists Normal→Godly tiers (only Lesser exists) | compendium §3.2 | 🔑 | 2 | 1 | 3 | **1.7** |
| I-29 | Loong escort→moving-arena reinvention (KAN-5-era) | rev-6 §3 | | 2 | 1 | 3 | **1.7** |
| I-30 | Remaining questionnaire batches (E audience numbers, F enemy heuristics, G economy, H exploration, I races, J lounge) — each unblocks its epic | questionnaire | 🔑 | 3 | 1 | 3 | **2.3** |

**Staged milestones (not "issues" — the roadmap):** co-op Stage 1 (declare-window driver,
host sync) → async global show Stage 2 → noise/absorption (KAN-5) → Lounge (KAN-7) →
social director / mother brain (Stage 2+).

## Recommended execution: four waves

**Wave 1 — one decision sitting (~an hour of your answers, E 6.5–11):**
I-1 shock recovery · I-6 HP tuning · I-4 PROVISIONAL batch (= questionnaire C/D) ·
I-5 IP call · I-2 spine · I-3 premade concepts (I draft, you approve) · I-7's 3-stat call ·
I-10's SQLite-deferral OK · I-21 hook approval.
*Everything here is cheap, upstream, and gates engine/content work below.*

**Wave 2 — the build block (me, mostly parallel):**
I-7 schema pass · I-8 tag-desc port · I-9 spectacle v1 · I-10 KAN-3 (JSON-first DAL) ·
I-11 priming impl (as far as I-15 allows) · I-13 slice tags · I-16 enemy AI v1 ·
I-14 char-sheet bug (verify first).

**Wave 3 — the milestone:** I-19 vertical slice assembly, then playtest with your table.

**Wave 4 — story track (interleaves anytime, it's your writing with my drafting):**
I-12 production cast → I-17 patches → I-18 finale → I-20 convergence matrix →
I-23 Medium forks → I-24/25 characters. I-15 skill passover rides alongside.

**Backlog (post-slice):** I-22, I-26, I-27, I-28, I-29, I-30-by-epic.
