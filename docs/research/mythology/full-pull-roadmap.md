# Full-extraction roadmap — the path to "extract everything" (2026-07-18)

The census found **957 candidates** across 26 traditions; we've extracted **210** (14
traditions, capped at 15 each) + Wave 2b (~14 referenced figures). This is the staged path
to the rest, if/when the owner wants it. It is **NOT required for the MVP** — the 210 cover
the 24-god roster with room to spare — so treat this as expansion/Stage-2 content work.

## The key distinction (owner note 2026-07-18): interactable vs story-only

**Not every entity should be a patron / boss / interactable.** Many exist only to give the
world depth — we need the *information* for context, but they never appear as a playable
patron or an enemy. The schema now supports this: `casino_roles: ["story_only"]` +
`patron_capable: false` marks a **research-for-context** entity. Every extraction wave from
here tags each figure as one of:
- **interactable** — a patron / dealer / Forsaken host / table_boss / artifact / messenger
  the player meets or fights.
- **story_only** — lore/context (a supreme off-screen creator, a genealogical ancestor, a
  cosmological abstraction, a referenced-but-unseen figure). Researched, never staged.

This keeps the roster/boss pools clean while still capturing the connective tissue the
narrative leans on. The Wave-5 generator draws the roster ONLY from interactable entities.

## The remaining ~747, in priority tiers

**Tier A — deeper picks in the 14 done traditions (~349).** Beyond the 15-cap: the benched
household names (Poseidon/Apollo already pulled in Wave 2b; still out: Thor, Freyr, Horus,
Isis, Vishnu, Guanyin-extras, more orishas, etc.). HIGHEST value-per-token — same rich
sources, same calibration, and these are the most recognizable. Run as one agent per
tradition, "next 15," reusing the Wave-2 prompt. **Recommended first if expanding.**

**Tier B — the 6 straightforward un-extracted traditions (~232).** slavic (40),
finnish_baltic (40), korean (40), andean (36), zoroastrian (37), global_folklore (39).
Ordinary extraction, decent sources; run exactly like Wave 2 (one agent/tradition, up to 15,
then optionally deeper). No special handling.

**Tier C — the SENSITIVE 4 (~100), per-entity screening required.** vodou (25 — living,
historically maligned; avoid horror-movie tropes), native_north_american (33 — 13 flagged
restricted; many closed ceremonial stories), aboriginal_australian (18 — mostly closed
sacred lore; the census's job there was to REPORT what's closed, not collect it), inuit (24).
These are **NOT a bulk sweep** — each figure needs the depiction/closed-material screen from
spec §3.3, and much of the material is correctly *excluded* (report-only). Expect small,
honest yields, not full 15s.

**Tier D — the DEFERRED ◊ families (~66), IP-gated.** cosmic_horror (37 — Lovecraft PD vs
Derleth-era `modern_ip_flagged`) and internet_folklore (29 — SCP = `cc_licensed` CC BY-SA,
Slenderman = `modern_ip_flagged`). Owner already ruled these `ship_status: deferred` —
researched now, added per-entity only on a clearance decision. Extract with the per-entity
IP map; nothing ships without a separate call.

## Cost & sequencing

- **Rough total:** ~50 entity-agents + a Wave-3-myths re-run + a Wave-4 re-link ≈ **~15M
  subagent tokens**, across **many usage-limit windows** (the 210+294 we have already tripped
  the limit ~4×). Realistically several sessions.
- **Recommended order if greenlit:** Tier A → Tier B → (Tier D with IP map) → Tier C last and
  most carefully. Each tier is independently committable; stop any time.
- **Alternative (recommended default):** don't bulk it. Pull **per-need** — when a stage or
  story beat wants a specific figure or tradition, extract that slice on demand (cheap,
  targeted, always in-context). The dataset grows with the game instead of ahead of it.
