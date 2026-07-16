# Review 5 — Master Compendium Delta

**What this is:** on 2026-07-14 the owner supplied `docs/GPT_Master_Compendium.md` — a
consolidated record of all design conversations up to ~May 5 (system v0.91 + GDD v0.1
decisions + boss/item/modifier design + campaign story + app history). The original reviews
(0–4) were written without it. This document records what it **changes, confirms, and
contradicts**. The reviews stay as written (they're dated artifacts); live documents
(DIRECTION, rules-addendum, questionnaire, seeds) were amended.

## What the compendium changes in the reviews' conclusions

### Review 1 (TTRPG) — several "undefined" findings were already answered in sessions
- **F5 (cooldowns undefined): superseded by a design decision — "cooldowns removed from the
  system entirely" `[EXECUTED]`.** BUT: the July DB export still carries cooldown text
  (Tactical Roll, Acrobatic Save; threshold text "-4 Moment cooldown", "twice per cooldown
  Rotation") — the decision and the live content disagree. → new question NQ1.
- **B1 (advancement undefined):** still true for the *book*, but the compendium confirms the
  creation math (7 across Body + 7 across Core — the level-6 party's creation stats sum
  exactly 7+7) and the app's unified level-point pool as the executed rule. Q1 narrowed.
- **C3 (stat-cap arithmetic):** compendium repeats the doc thresholds and flags the one
  discrepancy itself (psychic: doc 15 vs app 10) — **verified today: the app is /15; the
  compendium's `[OPEN]` flag is stale. Resolved: 15.**
- **Review-1's "the defects live in the text, not the design" verdict is strengthened** —
  a large fraction of the gaps have session-designed answers that never reached the doc.

### Review 2 (conversion) — the owner already made several conversion calls in GDD v0.1
- **Noise/absorption mechanic (new to us):** noisy combat attracts nearby encounters — after
  a Clock completes, other area encounters can be absorbed into the fight. Kills grinding,
  makes stealth/social relevant, extends spectacle-over-safety into exploration, and the
  audience clock and absorption clock can be one system. This is a *strong* answer to
  review-2's "content pacing without GM" problem and is adopted into DIRECTION.
- **Two-mode structure confirmed** (overworld semi-real-time with one-way zone locks à la
  Salt & Sanctuary + discrete clock-combat arenas) — matches the combat-fields sketch.
- **Death model confirmed:** checkpoint rewind, full world-state reset, character + Lounge
  upgrades persist. Party: fully custom; non-PC members can permanently die.
- **Translation debts list** matches review-2 §2 almost exactly (deterministic Forced
  Actions, Narrative Token rebuild/cut, no GM-discretion language, internalize the
  TVTropes tag-sourcing dependency, Lounge downtime pacing) — independent convergence.
- **Exposure loop sketch:** Viewers = hype momentum on a rolling performance curve;
  Followers = stabilized reward floor; viewer spikes from achievement hunts, hard clears,
  clear times. Seeds the spectacle engine design.

### Review 3 (repo) — unchanged
The repo assessment stands; the compendium explains *where the two-day burst came from*
(KAN-8/9/10 executed against these session designs) and adds no code.

### Review 4 (verdict) — unchanged, slightly reinforced
Same direction, same risks. The compendium adds evidence the design layer is deeper than
the docs showed (boss internals, modifier economy, story routes for 3 floors ×3 routes +
floors 4–6), which *raises* the content-readiness grade and *does not change* the scope
warning — if anything the story ambitions (Nikita continent-merge arc) reinforce it.

## Major additions now in canon (were invisible to the reviews)

1. **Incineradile full design** (§3.1): mycelium-puppet concept, surface immunity =
   pre-breach damage is cosmetic, breach = Bleed T2 **or 7+ damage in a single hit**
   (the DB notes said "single turn" — compendium wording adopted, flagged NQ2), Crush 2
   disables parts, **disabling the Left Hand permanently removes the Flamethrower**,
   fire/Burn HEALS it, trash cans explode at Burn 5, explosion phases with **1-Moment steam
   telegraph** and **breach-threshold reset after Pressure Valve I**, Reflexes-gated
   auto-dodge counters (Reflexes 7 dodge+move / 9 dodge+counter / else roll 4+), 41×60 hex
   arena, cinematic band intro. → `data/enemies.json` enriched.
2. **Weapon/modifier economy** (§3.2): tier→slot table (Crude 0/0 → Exceptional 2/2),
   modifier-tier *access* gating by weapon tier, extraction friction by tier (Lesser/Normal
   safe-ish → Legendary+ destroys the weapon), Lesser modifier working list + flagged
   rebalances (Padded/Reinforced out; cap Draining once per Clock/target). → addendum R12.
3. **Designed rules:** enemy mental resistance is FLAT and exceeding it by a wide margin
   grants a bonus (viewer spike / secondary effect); tank-kit drafts (Intercept, Iron
   Stance); Sasha/Filipe/XQUEZ-T skill rework notes. → addendum R12 + questionnaire.
4. **Campaign story canon** (§4): three-route floor structure with time skips, Easy/Medium/
   Hard route beats, demonic-nobility Dissolution encounters (personal songs, embrace=ghoul,
   escape=emotion-amplification scar), Nikita (Old/War oscillation, reversion skill, scarf),
   Sasha's F1 demon maze. This is the game's narrative source material (KAN-5+ content).
5. **Live-party ground truth** (§5): creation stats (7+7 confirmed), Sasha's cat torso = 3 HP
   (Animal morphology precedent), roles, the Filipe/Mario naming reconciliation, and
   character-exclusive skills (Full Potential/Heroic Punch → schema needs a lock flag).
   Note: a 5th player (Frod, Human) joined after the compendium was compiled.
6. **Session recorder pipeline** (§8): per-player mics → WhisperX → local LLM criteria
   matching for achievement/skill-unlock detection. Directly relevant to the digital game's
   tag/achievement detectors AND a future Stage-2 ingestion path for table data.

## Contradictions requiring an owner ruling (added to the questionnaire as NQ1–NQ4)

| # | Conflict | Sources |
|---|---|---|
| NQ1 | **Cooldowns**: "removed entirely" `[EXECUTED]` vs July skill/threshold text still using them | compendium §2.4/§7.2 vs live DB |
| NQ2 | Incineradile breach B: "7+ damage in a single **hit**" vs DB notes "single **turn**" | compendium §3.1 vs DB enemy notes |
| NQ3 | Incineradile phases: compendium has 4 (ends at Pressure Valve II, network exposed) vs DB has 6 (adds Threshold 3 + 19-space lethal Explosion 3 at death) | compendium §3.1 vs DB phases |
| NQ4 | Party size: compendium party of 4 vs 5 live characters (Frod joined later) — affects encounter budgets | compendium §5 vs DB |

## Stale compendium items (already resolved since May 5)

- Psychic-resistance threshold `[OPEN]` → app verified /15 today; matches doc. Closed.
- "Skill enrichment render bug" `[OPEN]` → char-sheet repo's later commits show skill
  template lookup fixes; needs a 2-minute confirmation in the app, not a design decision.
- Tags "moved to DB-backed collection" — confirmed; but all 100 live tag records have empty
  effect/conditions fields (the compendium's tag list is names + vibes; effects remain
  undesigned → questionnaire Q42 stands).
