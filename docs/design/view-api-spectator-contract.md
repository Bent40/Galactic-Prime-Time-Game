# The view API is the spectator contract (design note — PARKED direction)

**Owner insight (2026-07-20):** a future stream/highlights layer ("show people's
runs on Twitch in highlights") needs "an API that allows you to probe situations."
That is exactly what the view API should be — so we design it that way NOW, at
zero extra cost, instead of retrofitting later.

## Why the architecture already supports this

1. **Every run is a replay for free.** The sim is a pure function of
   (seed, ordered command log) — a run serializes to a few KB. A highlights
   service re-simulates any run server-side, bit-identical, and can stop at any
   tick. No video capture, no state snapshots shipped around.
2. **The view API is the probe layer.** `view_combatants` / `view_clock` /
   `view_broadcast` / `view_turn_order` / `view_verdict` / `view_encounter` are
   read-only, plain-Dictionary projections. Re-sim to tick N, call any probe:
   "who was exposed, what was the hype band, was the network revealed yet."
3. **The EvidenceEngine is a highlight detector.** Its ledger entries are
   tick-stamped meaning ("took the hit that cracked the network open", "did The
   Bit with a bleeding arm") — i.e. clip markers. Highlight reel v1 = seek the
   replay to each evidence tick, render a window around it. Hype spikes, band
   changes, breach/phase events extend the marker set.
4. This is the DIRECTION.md ladder's Stage 2 ("async global show") substrate.

## Design rules for every view (binding now)

- **Consumer-agnostic:** plain Dictionaries/Arrays of primitives; no HUD-specific
  convenience fields; no reaching into scene state. The HUD is merely the FIRST
  consumer; spectator/stream/replay tools are future consumers of the SAME calls.
- **Meaning over internals:** consumers must never reverse-engineer game meaning
  (e.g. detecting "the boss" by sniffing part names). If a consumer needs a
  concept, the view exposes it as a field.
- **Tick-addressable by construction:** views read live sim state only, so
  "probe at tick N" = re-sim to N, then call the view. Never cache derived
  meaning outside the sim.
- **Deterministic:** same state → same view output, always.

## Status

PARKED as direction (content freeze; Stage 2 is not scheduled). The 2026-07-20
view-API widening story adopts the design rules above; nothing else is built yet.
