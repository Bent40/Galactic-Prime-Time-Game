# Story KAN3-S4 — Paused-on-decision clock driver (solo)

**Epic:** KAN-3 Scaffolding · **Status:** ready · **Depends on:** KAN3-S1
**Sources:** `../architecture/architecture.md` (clocking decision), DIRECTION §fields/
clock drivers, R0 (sim never self-advances).

## Context
The solo driver: the sim waits while the player thinks (ATB wait-mode feel). Drivers
live OUTSIDE `simulation/` and are the only source of `advance_tick` commands.

## Acceptance criteria (EARS)
1. WHILE any player-controlled combatant has an available declaration this tick and has
   neither declared nor passed, THE driver SHALL NOT advance the tick.
2. WHEN all player-controlled combatants have declared or passed, THE driver SHALL feed
   exactly one `advance_tick` command, then re-enter the wait state.
3. THE `simulation/` tree SHALL contain no timers, no `_process`, and no self-advance
   path — IF the driver is disconnected, THE sim state SHALL remain frozen indefinitely
   (test-asserted).
4. WHEN the driver is later swapped for the declare-window (co-op) or wall-clock
   (broadcast) driver, THE sim and GameController SHALL require zero changes (driver
   interface documented; swap is registration-only).
5. WHEN a Forced Action interrupts a declared plan, THE driver SHALL surface the
   re-decision to the player before the next advance (no silent auto-advance through
   drama).

## Tasks
- [ ] `controller/drivers/clock_driver.gd` (interface) + `paused_driver.gd`.
- [ ] GameController integration: driver registration, declare/pass tracking.
- [ ] Tests `tests/test_clock_driver.gd`: EARS 1–3 headless (driver logic is
      node-free where possible for testability).
- [ ] Driver interface doc block (the swap contract for co-op/broadcast later).

## Definition of done
Suite green (real run) including the frozen-without-driver assertion; a scripted solo
exchange (declare → advance → forced-action → re-decision) runs end-to-end headless.
