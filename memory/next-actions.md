# Next Actions

<!-- wf memory: required sections below; keep the headings. -->
<!-- OWNER-FACING BY-ANGLE TRACKER (2026-07-18): every report mirrors this list;
     refresh whenever an item moves. -->

## Next actions

### 🔀 main = integration branch (owner-ruled 2026-07-18)
Session work fast-forwards to `origin/main` at milestones (last sync: e6c2bd7). Keep
developing on `claude/session-continuation-next-steps-mpycyj`; re-FF main periodically.

### ⏸️ Owner decision queue (nothing below blocks running work)

1. **Telepathy — does it fit?** The one open skill (of 43): owner unsure it belongs, since
   the player CHAT function already covers mind-to-mind comms. Cut, or repurpose to reading
   enemy/NPC hidden intent (rec: repurpose). Re-anchor Mind Burst's "Req Telepathy Lv 3" if cut.
2. **Extract-everything?** ~747 more entities (349 deeper in the 14 done + 398 in the 12
   un-extracted traditions), ~15M tokens over many limit-windows. REC: don't bulk it — the
   210 cover the MVP roster; the un-extracted 12 are the sensitive/deferred ones needing
   per-entity screening. A cheap Wave-2b (~14 most-referenced) is the good-value slice.
3. **Wave 5 roster shape** — which 24 gods for the MVP patron roster, tier placement.
   Wave 5 also wants the tag effects designed (dep on the I-13 build).
4. **Caishen flag** — influence auto-corrected 5→4 (rubric); revert if a deliberate outlier.
5. **Bigger sittings** (any time): R14 force-gate numbers · R2–R10+R13 batch · Q58 stealth
   · animal parts · GDD/narrative/arch markups · sprites → `docs/art/samples/gpt/`.
6. **Char-sheet `client/dist` rebuild** (your side, optional; bundle predates the fix).

### ✅ RULED this session (no longer open)
- Skill framework: all 10 defaults · skill ladders 42/43 FINAL (Telepathy the one open).
- Tag names: 2026-07-17 renames stand (pasted descriptions kept).
- Mycelius = a servant (not a god), Osiris's retinue; not slice-critical.
- R11 #14: same-batch insta-win allowed · friendly takedown counts iff you killed them
  (attribution-v2 impl QUEUED — task #13).
- Depiction v2 + carve-outs · Wave-2 shortlist · slice cast = demo loadouts · tag slice.

### 🔄 Running now (agent)

- Nothing. All background waves/agents complete and committed.

### ✅ Mythology pipeline — WAVES 0–4 COMPLETE
- Wave 0 calibration ✓ · Wave 1 census 26/26 (957 candidates) ✓ · **Wave 2 extraction
  14/14, 210 entities, 114 patron-capable** (all influence tiers; 54 luck_gambling,
  56 forsaken hosts, 36 vvip) ✓ · **Wave 3 myths: 294** (all 250 declared refs + 44
  top-ups; 120 heroic/74 world/70 legend/30 folk) ✓ · **Wave 4 cross-link: 4 syncretic
  merges + 15 reciprocities applied, data health excellent** ✓.
- **Wave 5 (game mapping) REMAINS** — dev-session task, gated on tag effects + roster
  shape (#5): extend `validate_seeds.py` for `data/mythology/`, domain→tag/condition/affix
  map, patron-roster generator superseding the greek `patron_gods.json` stubs.
- Data files: `data/mythology/{traditions.json, census_candidates.jsonl, calibration.json,
  entities.jsonl (210), myths.jsonl (294)}` + 14 dossiers + wave summaries in
  `docs/research/mythology/`.

### ▶️ Queued (agent) — unblocks on the matching decision

- **I-13 TagEngine build** (on #2 tag names): TagEngine + `tag_effects.json` + 3 goal
  rows + The Bit as a mechanically-NULL flavor action. Via nexus-dev-story-pipeline.
- **Skill ladders** (on #1): drive the 43 R19 ladders in stat-group chunks.
- **Wave 5 game mapping** (on #5).
- **S2.5 combined actions (R15) · S2.4 tick audit · I-11 priming** (I-11 full pass wants R19).
- **KAN-4 party stories** (S4.1 OC creation → recruitment → permadeath → plan-runner).
- **Bid-screen slice story** (ruled IN) → **KAN-6 mockup gate** → slice readiness re-run
  → **W3 vertical slice assembly**.

### ✅ Landed 2026-07-18 (this session)

- **Mythology Waves 0–4** (above) — 210 entities, 294 myths, cross-linked, committed.
- **I-9 spectacle/hype engine MERGED** (66/66; two gates + mutation-proofed fix round).
- **I-16 enemy AI MERGED** (95/95; two gates + adjudicated salt-teeth fix; incl. a real
  pre-existing burst-breach engine-bug fix).
- **Demo loadouts** (Imani/Dario) built + committed (patron stubs, validator, 66/66).
- **R11 #18 RULED**: wounds persist on boss retreat (verified no instant re-breach).
- **I-8 tag port**: 84→100 tags, descriptions ported, 95/95.
- **Skill-passover worksheet**: 43 draft R19 ladders + 10 framework Qs.
- **Assets staged**: owner's TTRPG art (Incine-Dile, roach brothers, maps) as
  `.gdignore`'d placeholders mapped to seed entities.
- **I-14** verified FIXED + `passive` residual fix committed to char-sheet repo.
- Rulings recorded/propagated: depiction v2 + carve-outs · Wave-2 shortlist (14×15) ·
  slice cast = demo loadouts · tag slice approved (The Bit null constraint) ·
  decision log #10–#13.
