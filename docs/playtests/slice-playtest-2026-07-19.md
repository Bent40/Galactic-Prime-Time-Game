# Slice playtest — headless broadcast trace (2026-07-19)

**Driver:** `scripts/slice_playtest.gd` (run: `bash scripts/run_slice_playtest.sh`). Deterministic
(seed 14), runs the demo slice through the real `GameController` — so the trace is exactly what the
combat HUD will consume via `sim_event`. All numbers are **PLACEHOLDER (R14)**; this trace exists to
*feel* them. The suite is unaffected (133/133).

## Encounter
Incinedile (mycelium puppet — hidden lethal `network` part, hp 50) vs. Imani "The Door" + Dario
"Encore" (demo loadouts). Win = discover the breach (bleed→T2 anywhere, or a burst-7 single hit),
then destroy the exposed network.

## FEEL READOUT (the pacing numbers to judge)
| metric | value |
|---|---|
| Moments to FIRST breach | 5 (C1 M06) |
| Moments to KILL | 14 (C2 M07, 1.4 Clocks) |
| Kill mechanism | `crushed_vital` (network T3 lethal), **not** HP-pool depletion |
| Breach re-discoveries | 1 (one per pressure valve) |
| Peak hype / band | 989 · ON FIRE (`on_fire`) |
| Crowd goals offered / completed | 1 / 1 ("OVERKILL!") |
| MVP | Dario (172 spectacle) |
| Tags earned | Imani: formation · Dario: formation, scene_stealer, the_bit |

The audience economy moves well: cold→warm→hot→on_fire inside Clock 1, driven by Camera Call +
escalating The Bit + the combined-strike breach. Band display names per owner: COLD OPEN / WARMING
UP / ELECTRIC / ON FIRE.

## Findings (surfaced by the driver; verified against the code)

### F2 — DESIGN DECISION NEEDED: condition-tier death bypasses the discoverable win condition
The Incinedile's identity is "pre-breach damage is cosmetic; you must discover the breach and kill
the hidden network." But **a condition (crushed/bleeding) on ANY cosmetic limb, left to advance, reaches
tier 4 and kills the boss unconditionally** — no breach required. Verified:
- `data/conditions.json` crushed/bleeding T4 = effect `["death"]`; T3 = `["part_destroyed","lethal_if_vital"]`.
- `simulation/condition_engine.gd:567` — the `death` effect calls `_kill()` with **no lethal-part gate**
  (unlike `lethal_if_vital` at :557, which checks `lethal`).
- Both conditions `advance_on_clock_reset`, so a limb goes T1→T2→T3→T4 over four Clocks and kills.
- The tier's OWN description says "torso/head only" — so the unconditional `death` effect contradicts
  documented intent (addendum R4 territory). This turns the boss into a condition-grind race, violating
  the hard rule "bosses need discoverable win conditions, never raw damage races."

**Recommended fix (awaiting owner ruling — it changes shared combat mechanics for ALL combatants):**
gate the T4 `death` effect to lethal/vital parts (data: T4 → `["lethal_if_vital"]`, or engine: `death`
checks part lethality), matching the documented torso/head-only intent. Then the only path to end the
Incinedile is the (hidden, post-breach) lethal network — the intended discoverable win.

### F1 — no path to grant the loadout's Camera Call stacks
`camera_call_stacks` is derived ONLY from Charm over-cap (`combatant.gd:193`, `over_cap(charm,20)` →
needs Charm 30 for 1). The demo loadouts declare `camera_call_stacks: 1` as a system-testing override
(RULED, decision #13) that currently can't be expressed to the sim; the driver set Dario's Charm to 30
to realize it. Fix: let a combatant spec seed `camera_call_stacks` directly (a granted stat, distinct
from the Charm-derived amount).

### F3 — no broadcast/boss view projection for the HUD (the concrete next build)
`GameController.view_combatants()` exposes parts (hp/max/lethal/disabled/conditions) but NOT: hype
meter/band, active crowd goal + progress, spotlight, tags, or each part's `hidden`/breach state — so a
HUD can't render the audience economy or "hide the network" without reaching into `sim.hype`/`sim.tags`/
raw combatants (which the driver does, and flags). **A `view_broadcast()` + `view_boss()` projection is
the prerequisite before the .tscn HUD is authored.**

### F4 — boss under-threatens: pressure-valve/explosion phases are v1 stubs
The Incinedile's phases 2/4/6 (the eruptions after each pressure valve) are unimplemented — the AI
reaches them and idles (`phase_not_implemented`), letting the party re-breach and finish unopposed. A
full-cadence phase-1 boss instead TPKs the party (torso 5 HP vs flamethrower + condition escalation);
the driver uses a controlled boss cadence. Both are numbers/AI-completeness work for the tuning pass.
