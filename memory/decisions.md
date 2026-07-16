# Decisions

<!-- wf memory: required sections below; keep the headings. -->

## Decisions

- **D1 (2026-07-13, owner):** North star = shared-world ladder (Stage 0 command-stream sim
  → Stage 1 slice + friends co-op → Stage 2 async global show → Stage 3 shared space).
  Literal-MMO pivot and single-player-only both rejected. Full record: `docs/DIRECTION.md`.
- **D2 (2026-07-13, owner):** 2.5D tactical presentation; 3D reconsidered only at Stage 3.
- **Sim contract (2026-07-13):** state = pure function of (seed, ordered command log);
  pluggable clock drivers (paused / declare-window / wall-clock); sim never self-advances.
- **Engine:** Godot 4 / GDScript (review-4 §4). Web stack reserved for the Stage-2 service.
- **Workflow adoption (2026-07-13):** partial `wf start` — memory/learn/context/validation/
  traces + activation block + boot receipt YES; `wf install` pack materialization NO
  (skills come from the Workflow repo in session scope; avoids adapter drift).
- **Vocabulary:** rulebook condition taxonomy + this repo's seed enums are canonical;
  char-sheet app DMG_TYPES/RACES are NOT imported (drift documented in review-1).
- **SKETCH (not decided):** combat fields with real-time tick clock drivers — in
  `docs/DIRECTION.md`, pending rules-addendum tick rulings.
- **Compendium adopted (2026-07-14):** `docs/GPT_Master_Compendium.md` = design record
  through ~May 5; precedence DIRECTION > addendum > compendium > PDFs > docx. Adopted from
  it: modifier economy (R12), noise/absorption, flat enemy mental resistance, death model,
  Reflexes-gated boss counters, Incinedile enrichment. Conflicts awaiting rulings: NQ1–NQ7
  (cooldowns removed-vs-present is the big one). See review-5-compendium-delta.md.
