# Story KAN3-S2 — JSON-first DAL + save manager

**Epic:** KAN-3 Scaffolding · **Status:** ready · **Depends on:** KAN3-S1
**Sources:** `../architecture/architecture.md` (ADR 3, data architecture, saves delta),
DIRECTION.md delta 5.

## Context
Static data currently loads ad-hoc (tests read JSON directly). This story creates the
single data owner (`controller/dal.gd`, JSON-backed, SQLite-shaped API) and the single
save owner (`controller/save_manager.gd`, snapshot + command-log offset).

## Acceptance criteria (EARS)
1. WHEN any runtime code needs static data, THE SYSTEM SHALL serve it exclusively
   through `dal.gd` — IF any non-DAL runtime file reads `data/*.json` directly, THE
   review gate SHALL fail the story (tests exempt via SimTestBase only).
2. THE DAL API SHALL be shaped so the deferred SQLite backend can replace the JSON
   backend with zero caller changes (query-by-key/id + typed collection getters; no
   caller ever sees file paths).
3. WHEN a save is written, THE save_manager SHALL persist {state snapshot, command-log
   offset, seed}; WHEN that save is loaded, THE restored sim's `state_hash()` SHALL
   equal the hash captured at save time.
4. WHEN a snapshot is deleted but the command log retained, THE SYSTEM SHALL rebuild
   identical state by replay from (seed, log) — verified by hash equality.
5. IF a save file is corrupt/unreadable, THE save_manager SHALL fail soft (error signal,
   no crash, original file untouched).

## Tasks
- [ ] `controller/dal.gd` (autoload or controller-owned): load-once, typed getters
      (races/enemies/conditions/skills/thresholds/items/tags/modifiers/patron_gods).
- [ ] `controller/save_manager.gd`: write/read/list saves under `user://saves/`;
      snapshot+offset+seed envelope; corruption guard.
- [ ] Tests `tests/test_dal_saves.gd`: DAL getters vs validator counts; save/load hash
      equality; replay-from-log equality; corrupt-file soft-fail.
- [ ] Wire GameController's TODO-S2 stub to the DAL.

## Definition of done
Suite green (real run); grep gate for direct JSON reads passes; save round-trip hashes
equal in the committed test run.
