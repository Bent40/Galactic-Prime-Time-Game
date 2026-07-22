# HUD v2 — adoption record (owner 2026-07-22)

`ARCHITECTURE.md` (owner-supplied structural UX spec + a rich concept mockup shown
in-session) is the BUILD TARGET for the front rework — the "Rework Visuals
Properly" epic is now OPEN for the HUD's structure. The spec is structural, not a
visual lock; placeholder styling continues until the art pass.

## Owner corrections recorded with the adoption
- **The Bit is authored, per-character content** (decision-log #25) — not a generic
  button. Not everyone has one.
- **Skills are not capped at 4** — the skills menu must scroll/grid.
- **Non-mob allies (individual persons) have PART-BASED HP** — party cards show
  urgent part flags; the ally inspector shows full anatomy, never just a bar.

## Phasing (v1 ships only what real systems back — content freeze otherwise holds)
- **Phase 1 (building now):** the shell + component decomposition (§8 subset),
  new layout (§2), focus/inspection model, action launcher + flyouts (Move /
  Attack / Skills / Free Actions / End Turn), Moment timeline strip, crowd panel,
  entity inspector with known-anatomy masking, Momus ticker + event-log overlay,
  party rail (the real roster). Feature parity with the old HUD is a hard gate.
- **Deferred with their systems:** live odds/top bidder (patron economy), chat
  (multiplayer), Wagers/Divine Status/Social/Encyclopedia/Achievements/Quests
  popups, party-of-6/recruits (KAN-4), Focus resource, controller support pass.

## Vocabulary — RULED (owner 2026-07-22)
**Engine vocabulary stands:** **Clock** = the 10-tick lap, **Moment** = the tick
(costs are "Moment costs"; the HUD shows "CLOCK 3 · MOMENT 07"). The spec/mockup's
inverted usage ("MOMENT 17" / "cost: 2 Clocks") was incidental — read any such
wording in ARCHITECTURE.md through the engine vocabulary when building.
