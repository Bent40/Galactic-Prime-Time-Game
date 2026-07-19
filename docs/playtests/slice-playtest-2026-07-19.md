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

### F2 — RESOLVED (owner ruling 2026-07-19): condition/damage death now routes only through a lethal, exposed part
The Incinedile's identity is "pre-breach damage is cosmetic; discover the breach and kill the hidden
network." The playtest found **nine** off-network kill routes that violated that (the "raw damage race"
the hard rule forbids). All nine are now closed under one enforced principle — **HP damage never touches
a hidden part; death/removal routes only through a lethal, exposed part** — verified DRY by an
independent adversarial pass (finds converged 4 → 1 → 0). Commits 4377fa2 / ecb867e / 6155e29.

| # | Route | Close |
|---|---|---|
| 1 | bleeding limb → T4 unconditional death | systemic bleed-out drain; death only when a lethal part empties |
| 2–3 | crushed T4 / burn T4 `death` on any part | gated to lethal parts (matches R4 "torso/head only") |
| 4 | `lethal_if_head` on the boss's `lethal:false` head | respects the part's lethal flag |
| 5 | suffocation → remaps onto hidden network | source gate: no condition applies to a hidden part |
| 6 | dissolution → mind-collapse off the puppet head | timer terminal gated on `_lethal_exposed` |
| 7–8 | poison T3 / infected T3 ungated death-timer | `death`/`death_timer_clocks:` gated on a lethal part |
| 9 | forced-action **collateral** → hidden network via `damage_part` | central HP sink blocks damage to hidden parts; `default_part` skips them |

Owner design calls baked in: the network is **bleed-immune** ("mycelium doesn't bleed"); bleed-out drain
**scales with tier**. Regression-safe (humans still die to suffocation/dissolution/crushed torso on their
lethal parts; determinism/serialization intact). Numbers (drain rate) PLACEHOLDER (R14). Open owner nit
(not a bypass): post-breach, a lethal *condition* on the *exposed* network is currently an acceptable
finisher — decide later whether "destroy the network" must strictly mean HP→0.

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
