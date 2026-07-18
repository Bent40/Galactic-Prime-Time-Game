# Current State

<!-- wf memory: required sections below; keep the headings. -->

## Done

- **Setting frame fully designed (2026-07-16→18):** Cosmic Casino adopted game-first
  (DIRECTION.md D3–D5); patron-god system complete (`docs/design/patron-gods.md`, Q1–Q8 +
  slate + Forsaken any-god-all-in amendment); propose-a-plan + combined actions designed;
  Nikita + Sasha sheets APPROVED (`docs/characters/`); rules addendum R0–R19 closed except
  the four gated items below.
- **BMAD artifact chain:** brief APPROVED; GDD (`docs/gdd/gdd.md`, supersedes v0.2 PDF) +
  narrative + architecture + KAN-3 stories + readiness all drafted — GDD sits at the owner
  review gate.
- **Engine (KAN-2): 49/49 green** under Godot 4.5.2 in-container (`scripts/setup_godot.sh`)
  — determinism suite, hype engine v1 (in state_hash), S2.6 part-legality fix.
- **KAN-3 COMPLETE (2026-07-18):** S1 boot scene + GameController autoload · S2 DAL
  (single data owner, reads `data/*.json`) + SaveManager (`var_to_str` envelope; JSON
  doubles corrupt 64-bit RNG state) + controller-owned command log · S4 clock-driver
  contract + PausedClockDriver · S3 read-only view API + placeholder hex renderer, live
  xvfb screenshot at `docs/stories/notes/KAN3-S3/boot-field.png`.
- **Three audits (skills/items/campaign residuals) + fix wave executed**; validator green
  (166 rows). Data: 43 skills, 84 tags, 78 thresholds, patron-god stubs w/ taboos+influence.
- **Art route RULED:** GPT image generation wins; ComfyUI 100% shelved; Claude Design
  eliminated; free/code-drawn placeholders interim; pipeline = canon prompt blocks
  (`docs/art/generation-prompts.md`) → `scripts/spritify.py`; hybrid 64/48 fidelity.
- **Mythology research spec RULED (2026-07-18):**
  `docs/design/mythology-research-spec.md` — executable; all decision points ruled incl.
  messenger carve-out (Metatron/Gabriel-tier as corporate staff), Abrahamic holding-company
  lore, cosmic horror + internet folklore researched-but-`deferred`, historical figures out.

## In progress

- **Mythology research** — owner is booting a dedicated session: read the spec, run
  Wave 0 (calibration set) + Wave 1 (census). Output lands in `data/mythology/` +
  `docs/research/mythology/`.
- **GDD owner review gate** (+ narrative/architecture reviews) — owner reading async.
- **Sprites** — owner produces via GPT pipeline, drops keepers in `docs/art/samples/gpt/`.

## Next

- **KAN-4 (party epic):** S4.1 OC creation (background picks → 4 skills → patron bidding)
  → S4.2 recruitment → S4.4 recruit permadeath → S4.5 plan-runner solo-lite. Then S2.5
  combined-actions engine (criterion 21), enemy AI v1 + Incinedile phases, S2.4
  actions-per-tick audit, KAN-5 exploration.
- **Wave 5 of mythology research** (game mapping: validator extension, domain→tag table,
  patron-roster generator) runs in the DEV session after research Waves 1–4 deliver.

## Blockers

- **Gated on owner:** skills passover (R19 = template; unlocks priming S2.1 + S4.3 kits) ·
  R14 force-vs-robustness co-design (unlocks numbers pass) · Q58 stealth · animal-parts
  sitting (unlocks Sasha's body plan).
