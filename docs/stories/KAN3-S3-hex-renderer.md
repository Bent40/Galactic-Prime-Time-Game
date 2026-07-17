# Story KAN3-S3 — Hex field renderer (readability spike)

**Epic:** KAN-3 Scaffolding · **Status:** ready · **Depends on:** KAN3-S1
**Sources:** `../architecture/architecture.md` (epic mapping), GDD §Controls ⟨PROPOSED⟩,
mockup gate rule (Workflow working rule 4).

## Context
First presentation surface: draw a combat field (hex grid, axial coords matching the
sim), occupancy, and per-part/condition state at a glance. This is a readability SPIKE —
it feeds the KAN-6 mockup gate; no final art. Placeholder shapes/colors are correct here.

## Acceptance criteria (EARS)
1. WHEN a field is active, THE renderer SHALL draw the hex grid and every combatant at
   its sim position, updating ONLY from GameController signals (no sim imports).
2. WHEN a combatant's part is damaged/disabled or a condition changes tier, THE renderer
   SHALL reflect it within one frame of the signal (badge/tint placeholder).
3. WHEN the Incinedile arena size (41×60) renders with 20 combatants on the dev machine,
   THE frame time SHALL be measured and recorded in the story's dev notes (no assumed
   performance).
4. WHILE this spike is unstyled, THE deliverable SHALL include 2–3 screenshots for the
   KAN-6 mockup discussion — IF styling decisions arise, THEY SHALL be deferred to the
   mockup gate, not decided in code.

## Tasks
- [ ] `scenes/field/field_renderer.gd` + scene: grid draw (axial→pixel), occupancy
      markers, selection highlight.
- [ ] Part/condition badge placeholder component (data-driven from events).
- [ ] Signal subscriptions via GameController only.
- [ ] Frame-time measurement note + screenshots into `docs/stories/notes/KAN3-S3/`.

## Definition of done
Renders the test arena from a scripted command sequence; updates live from events;
measurements + screenshots committed; zero direct sim imports (grep gate).
