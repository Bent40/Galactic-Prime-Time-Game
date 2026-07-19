# Owner onboarding — where we are & how to run it (2026-07-18)

A catch-up map: what to read to understand the project, and what to set up on your PC to
run the game and see the current state. (This file is durable — updated as things move.)

## Where we are in one paragraph

The headless combat **simulation is real and tested** (95 passing tests under Godot 4.5.2):
the deterministic Moment-clock engine (KAN-2), the scaffolding that boots it and renders a
hex field (KAN-3), the **spectacle/hype engine** (crowd goals + camera-call), and **enemy
AI v1** (mob/elite policies + the Incinedile Phase-1 boss with its dodge-threshold and
discoverable breach win-condition). Content-wise: the **tag catalog is complete** (100 tags
with descriptions), **two demo loadouts** (Imani, Dario) exist as test fixtures, and a
**14-tradition mythology dataset** (210 gods/heroes/beasts + 294 myths) is researched and
cross-linked, ready to become the patron-god roster. Not yet built: the vertical slice
assembly (arena + the two contestants + boss + broadcast win/lose), character creation
(KAN-4), and the UI chrome (KAN-6).

---

## Reading list — go through these to "figure it all out"

**Start here (the spine, ~30 min):**
1. `CLAUDE.md` (repo root) — the hard rules + orientation order.
2. `docs/DIRECTION.md` — the decided product direction (the shared-world ladder, the sim
   contract, the 2.5D tactical frame).
3. `docs/cosmic-casino-canon.md` — the world: gods wager on contestants; the divinity
   economy; who runs the games; **§4 the depiction register + modern-life attributions**.
4. `docs/gdd/decision-log.md` — **every ruling you've made, numbered** (#1–#14). This is
   the fastest way to see "what's been decided."

**The rules the sim actually implements:**
5. `docs/rules-addendum.md` — the canonical digital rulings. Skim R11 (the engine
   interpretation log #1–#18), R14 (numbers rework — everything's PLACEHOLDER until this),
   R16 (races/background skills), R18/R19 (Charm=presentability; the skill 0–10 ladder).

**The slice (what we're building toward):**
6. `docs/review/review-4-verdict.md` §5 — the vertical-slice definition.
7. `docs/design/slice-contestants-proposal.md` — the two demo contestants (RULED at bottom).
8. `docs/design/slice-tags-proposal.md` — the 10 slice tags (RULED at bottom).
9. `docs/design/skills-r19-ladders-FINAL.md` — the finalized skill 6–10 ladders (in progress).

**The mythology dataset (the biggest new content mass):**
10. `docs/research/mythology/census-summary.md` — the map + how it was built.
11. `docs/research/mythology/wave4-crosslink-report.md` — data health, syncretic merges,
    what's still un-extracted (Wave-2b candidates).
12. The data itself: `data/mythology/entities.jsonl` (210 gods), `data/mythology/myths.jsonl`
    (294 myths), and the per-tradition dossiers in `docs/research/mythology/*.md`
    (Greek, Norse, Egyptian, Hindu, Abrahamic, Arthurian, …). Best browsed with `jq`
    (below) or just opened — each line is one record.

**If you want the deep source of truth:** `docs/GPT_Master_Compendium.md` (your consolidated
design record) and the PDFs (`docs/GPT_ARCHITECTURE.pdf` for code structure).

**Always-current status:** `memory/next-actions.md` — the by-angle tracker (done / running /
your decision queue). If you read one file to know "what now," read that.

---

## Run it on your PC — see what we've got

### A. The game simulation (the main event) — needs **Godot 4.5+**

1. **Install Godot 4.5** (the standard editor build) from https://godotengine.org/download —
   it's a single executable, no installer needed. Put it on your PATH as `godot`, or set
   `$GODOT_BIN` to its path. (On a Linux box you can instead run `bash scripts/setup_godot.sh`,
   which fetches 4.5.2 from a mirror.)
2. **Get the code:** clone the repo and check out this branch:
   ```
   git clone <repo-url> gpt-game && cd gpt-game
   git checkout claude/session-continuation-next-steps-mpycyj
   ```
3. **Run the test suite** (proves the engine works — 95 tests):
   ```
   bash scripts/run_sim_tests.sh          # exit 0 = pass; exit 3 = SKIPPED (Godot missing)
   ```
4. **See it render:** open the project in the Godot editor (`godot` in the repo folder opens
   it; then press **Play** / F5), OR run headless:
   ```
   godot --headless --quit-after 3        # boots the controller, prints engine status
   ```
   The main scene boots the GameController wiring and draws the **hex field** with
   placeholder shapes (the KAN-3 renderer). It's a technical spike, not the styled game yet
   — no combat UI, no art. What you're confirming is that the sim runs and renders.
5. **Validate the seed data:**
   ```
   python3 scripts/validate_seeds.py      # checks all data/*.json (races, skills, tags, …)
   ```

> Honest expectation: right now "running the game" shows a **hex grid + a booting sim**, not
> a playable arena. The playable vertical slice (arena, the two contestants, the Incinedile
> fight, hype meter, broadcast win/lose) is the next assembly milestone — the *pieces* all
> exist and pass tests; they're not wired into a scene you can play yet.

### B. Browse the mythology data (no game needed)

Install `jq` (https://jqlang.github.io/jq/) then, from the repo:
```
# every god's name + tradition + influence/recognition:
jq -r 'select(.entity_class=="god") | "\(.tradition)  \(.names.primary)  inf=\(.influence) rec=\(.recognition)"' data/mythology/entities.jsonl | sort

# all the luck/gambling deities (casino nobility):
jq -r 'select(.domains|index("luck_gambling")) | .names.primary' data/mythology/entities.jsonl

# a tradition's myths:
jq -r 'select(.tradition=="norse_germanic") | "\(.grade): \(.title)"' data/mythology/myths.jsonl
```
Or just open the dossiers in `docs/research/mythology/` — they're readable prose with
citations.

### C. The character-sheet web app (the LIVE campaign tool — separate repo `Galactic-Prime-Time`)

This is your existing tabletop tool, not the game. To run it you need **Node.js** and
**MongoDB** running locally:
```
cd server && npm install && node server.js      # Express API on :3001 (needs MongoDB up)
cd client && npm install && npm run dev          # Vite dev server; proxies /api to :3001
```
Then open the Vite URL it prints. (One pending item there: a `cd client && npm run build`
would refresh the committed production bundle, which predates the May-07 skill-render fix.)
