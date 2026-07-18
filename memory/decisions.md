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
- **D3–D5 (2026-07-16, owner):** Cosmic Casino frame adopted GAME-FIRST — world rules yes,
  novel story no, gameplay stays GPT-shaped; reality-show skin survives diegetically.
  Full canon: `docs/cosmic-casino-canon.md` + `docs/story-canon.md`.
- **Patron gods (2026-07-16→18, owner):** two-tier (donator Patrons / THE patron-god
  escort); background-keyword bidding; deal sheets (favor_conditions + taboos);
  multiplier boon economy; buy-outs w/ notice of replacement; Forsaken = god-initiated
  all-in, hardcore opt-in — **ANY god can all-in, existence can be the stake, a loss can
  unlock new stages (2026-07-18).** Full record: `docs/design/patron-gods.md`.
- **Rules addendum closed through R19 (2026-07-17):** R0 tick ≈ 0.5s in-game · R3 priming
  replaces cooldowns · R5 mind collapse permanent (puppet of collapser) · R15 combined
  actions · R16 races Earth-life only, background grants 4 skills · R17 run-type death ·
  R18 Charm = presentability · R19 skill levels 0–10. Open: R14 numbers gate, Q58 stealth,
  skills passover, animal-parts sitting. Full record: `docs/rules-addendum.md`.
- **Art route (2026-07-18, owner):** GPT generation wins; ComfyUI shelved; Claude Design
  eliminated; free placeholders interim; spritify pipeline; hybrid 64/48 fidelity; all
  look decisions belong to the KAN-6 mockup gate.
- **Mythology research spec RULED (2026-07-18, owner):** dual-axis rating
  (influence=worship wealth / recognition=audience draw); depiction policy w/ messenger
  carve-out (Metatron/Gabriel-tier as corporate staff of investor institutions; sacred
  core never depicted); Abrahamic holding-company lore approved; cosmic horror + internet
  folklore researched but `ship_status: deferred`; historical figures excluded; 24-god MVP
  roster target. Full record: `docs/design/mythology-research-spec.md` + decision-log #10.
