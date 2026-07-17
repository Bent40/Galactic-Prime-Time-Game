# Decision log — architecture consolidation (2026-07-16, headless)

1. **Degraded-mode disclosure:** gds-game-architecture is an interactive micro-file
   workflow; run here as a headless consolidation because the architecture already
   exists in three authoritative layers (PDF base, DIRECTION deltas, live tested code).
   The template shaped the output; the engine knowledge fragment was skipped — the live
   codebase is the stronger Godot source of truth for this repo.
2. **Nothing re-decided.** Every decision row cites its source and date; the PDF stays
   authoritative where unamended (MVC, signal catalog, KAN order — deliberately NOT
   restated wholesale to avoid drift; pointers instead).
3. **⟨PROPOSED⟩ introduced:** patron/verdict stores join the hashed-derived-state
   discipline (hype precedent) · sim-tick < 1 ms budget note · no telemetry in v1 ·
   sorted-key iteration named as a binding consistency rule (it was implicit practice).
4. **ADR index style** chosen over long-form ADRs — the sources carry the context;
   duplicating them would rot (right-sizing, small project).
5. **OPEN carried:** R14 force-gate, priming vocabulary, R13, co-op transport, SQLite
   re-entry trigger.
