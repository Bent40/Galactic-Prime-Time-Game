# Next Actions

<!-- wf memory: required sections below; keep the headings. -->
<!-- OWNER-FACING BY-ANGLE TRACKER (2026-07-18, owner-requested format): every report
     mirrors this list; refresh whenever an item moves. Supersedes the 0..5 list from
     the morning refresh — all its items are folded in below. -->

## Next actions

### ⏸️ Owner decision queue (rough priority order)

1. ~~Wave-2 shortlist~~ **RULED: GO, 14 traditions × up to 15 entities** (decision
   log #12) — Wave 2 extraction fan-out launched.
2. ~~Depiction v2 carve-outs~~ **RULED: confirmed as recommended** — prophets OUT,
   closed-material exclusion stands.
3. **Slice cast shape (reframed by owner's OC correction):** OC = player-created
   character (KAN-4 S4.1). Pick the slice's cast model: (a) Imani/Dario demoted to
   demo/quick-start loadouts + test fixtures (recommended — slice doesn't wait on
   KAN-4 + R19), or (b) creation-first slice (pulls S4.1 + skills passover forward,
   delays slice). The 8 open questions in the proposal doc apply only if (a).
4. **Slice tag set** — approve/edit the 10 tags
   (`docs/design/slice-tags-proposal.md`, 9 open questions; zero new sim events).
5. **Camera Call base-stack** — R6 needs charm ≥30 for stack 1; slice premades can't
   press the button. Base-stack ruling or content decision.
6. **Hype PROVISIONALs** (R11 #14): friendly-death takedown payout · same-batch goal
   offer→instant-completion.
7. **Boss PROVISIONAL** (R11 #18): phase-retreat purges boss conditions vs limb wounds
   persisting across the valve.
8. **Char-sheet app**: permission for the one-line `passive` projection commit
   (classifier blocks git there), or commit it yourself; optionally rebuild
   `client/dist` (bundle predates the May-07 fix).
9. **Rulebook docx** into a repo → unblocks I-8 tag-description port.
10. **Skills passover (R19 template)** — owner-flagged "biggest unlock"; also feeds
    priming vocabulary (I-15, Q7/Q8).
11. Standing sittings batch: R13 nod · R2/R3/R4/R8/R9/R10 PROVISIONAL batch ·
    R14 force-gate co-design · 3-stat schema call (I-7) · Q58 stealth ·
    animal-parts sitting · SessionStart Godot hook approval (I-21) ·
    GDD/narrative/architecture review markups · sprites → `docs/art/samples/gpt/`
    (then `scripts/spritify.py`).

### 🔄 Running now (agent)

- **I-16 enemy AI v1 + Incinedile P1**: built 94/94 (verified live) — two review
  gates running → strict-side adjudication → fix loop → `--no-ff` merge.

### ▶️ Ready when unblocked (agent)

- **Wave 2 extraction fan-out** (on decision 1) → Wave 3 myths → Wave 4 dedup →
  **Wave 5 game mapping** (extend `validate_seeds.py` for `data/mythology/`,
  domain→tag/condition/affix map, patron-roster generator superseding the three
  Greek stubs).
- **Slice tag implementation** (on decision 4): TagEngine + `tag_effects.json`.
- **Contestant seed data** (on decision 3).
- **Engine remainder (no ruling needed):** S2.5 combined actions (R15, acceptance
  criterion 21) · S2.4 actions-per-tick audit · I-11 priming implementation (after
  I-16 merges; full pass wants decision 10's vocabulary).
- **Dev track — KAN-4 (party):** S4.1 OC creation (7/7 spread, race, background →
  4 skills, patron bidding with deal sheets) → S4.2 recruitment flow → S4.4 recruit
  permadeath (R17) → S4.5 plan-runner solo-lite.
- **Then:** KAN-6 mockup gate (broadcast chrome; renderer readability notes in
  `docs/stories/notes/KAN3-S3/notes.md`) → slice-scope readiness re-run → W3
  vertical slice assembly.
- **I-8 tag-description port** (on decision 9).

### ✅ Landed 2026-07-18 (this session)

- Wave 0 calibration frozen · Wave 1 census 26/26 traditions, 957 candidates,
  committed + shortlist proposal.
- I-9 spectacle/hype engine v1 MERGED (66/66; dev → 2 gates → adjudicated fix round,
  mutation-proofed).
- I-16 enemy AI v1 built (94/94, in review) — includes a real pre-existing
  engine-bug fix (burst-breach on scheduled resolutions).
- I-3 contestants + I-13 slice-tags proposals drafted, claim-verified, pushed.
- I-14 char-sheet enrichment bug verified FIXED (code-trace); passive-badge residual
  staged, commit-blocked.
- Depiction policy v2 ruled + propagated (spec §3.3 v2, canon §4, decision log #11).
