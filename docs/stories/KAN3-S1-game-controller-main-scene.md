# Story KAN3-S1 — GameController autoload + main scene

**Epic:** KAN-3 Scaffolding · **Status:** ready · **Depends on:** — (KAN-2 core ✅)
**Sources:** `../architecture/architecture.md` (structure, consistency rules),
docs/archive/GPT_ARCHITECTURE.pdf §signal catalog.

## Context
The repo currently opens to an empty window. This story stands up the MVC skeleton:
a main scene, the `GameController` autoload that owns a `CombatSim` instance, and the
signal fabric scenes will consume. No gameplay yet — the deliverable is the wiring.

## Acceptance criteria (EARS)
1. WHEN the project is launched from a clean clone (README steps only), THE SYSTEM
   SHALL open to the main scene with zero script errors in the console.
2. WHEN `GameController.apply_command(cmd)` is called, THE SYSTEM SHALL forward it to
   the sim and re-emit every returned event as the matching typed signal from the PDF
   signal catalog (one signal per event `type`; unknown types via a generic
   `sim_event(event)` signal).
3. WHILE the game runs, scenes SHALL interact with game state ONLY via GameController
   signals/calls — IF any scene script references a `simulation/` class directly, THE
   review gate SHALL fail the story.
4. WHEN the sim is (re)created, THE GameController SHALL load static data exclusively
   through the DAL (S2 dependency may stub with direct JSON until S2 merges, marked
   TODO-S2).

## Tasks
- [ ] `scenes/main.tscn` + minimal boot script; project.godot main scene set.
- [ ] `controller/game_controller.gd` autoload: sim ownership, command funnel, event→
      signal re-emit (typed for the catalog's combat signals; generic fallback).
- [ ] Headless smoke test `tests/test_game_controller.gd`: instantiate controller,
      apply add_combatant + advance_tick, assert signals fired in order (SceneTree test
      or signal-capture helper).
- [ ] README run instructions updated (runs-from-clean-clone gate).

## Definition of done
Suite green including the new smoke test (real run, exit 0); launch verified from a
clean clone; no direct sim imports in scenes/ (grep gate).
