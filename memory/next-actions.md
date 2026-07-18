# Next Actions

<!-- wf memory: required sections below; keep the headings. -->
<!-- OWNER-FACING BY-ANGLE TRACKER (2026-07-18): every report mirrors this list;
     refresh whenever an item moves. -->

## Next actions

### ⏸️ Owner decision queue

1. **Hype + boss PROVISIONALs** — all in `docs/rules-addendum.md` §R11 (starts line
   ~233): entry #14 (friendly-death takedown payout · same-batch goal
   offer→instant-completion) · entry #18 (does the boss's phase-retreat purge its
   conditions, or do limb wounds persist?).
2. **Paste rulebook tag text** into `docs/rulebook-tag-descriptions.md` (84 headings
   scaffolded from tags.json; a raw dump at the bottom works too) → agent ports it
   (I-8). Note: seed export has 84 tags, not the 100 the old docs claimed.
3. **Bigger sittings** (pick any, each ~30–90 min of your answers):
   - **R19 skills passover** — re-express all seeded skills in the R19 template
     (priming vocabulary, upgrade-vs-mutate). Owner-flagged "biggest unlock":
     gates full I-11 priming + KAN-4 kit authoring.
   - **R14 force-gate co-design** — the numbers rework (damage quantization,
     force-vs-robustness). Turns every PLACEHOLDER number real.
   - **R2–R10 + R13 PROVISIONAL batch** — sign off the digital rulings (dodge model,
     caps, Burn-Shock, RPM, grapple, requirements-halving, shock recovery).
   - **Q58 stealth** — stealth/detection model (KAN-5 exploration gate).
   - **Animal-parts sitting** — non-human body-part layouts (gates animal
     OCs/loadouts — "we can make animals later" = this).
   - **GDD / narrative / architecture markups** — the drafted planning docs await
     your red pen.
   - **Sprites drop** — art samples into `docs/art/samples/gpt/` → `spritify.py`.
4. **Char-sheet `client/dist` rebuild** (your side, optional): committed bundle
   predates the May-07 fix; `cd client && npm run build` when convenient.

### 🔄 Running now (agent)

- **Wave 2 extraction** — 14 traditions × up to 15 entities. ~2 concurrent (container
  CPU cap): slow burn, alive. Then Wave 3 myths → Wave 4 dedup → Wave 5 mapping.
- **I-16 enemy AI v1** — review gates 1+2 → adjudication → fix loop → merge (94/94).
- **Demo loadouts build** — Imani/Dario as `data/demo_loadouts.json` + archetype god
  stubs + validator coverage (per decision log #13).

### ▶️ Queued (agent)

- **Slice tag implementation** (after I-16 merges — same engine surface): TagEngine +
  `tag_effects.json` + 3 goal rows + The Bit as a mechanically-NULL flavor action.
- **S2.5 combined actions (R15) · S2.4 tick audit · I-11 priming** (partial until R19).
- **KAN-4 party stories** (S4.1 OC creation → S4.2 recruitment → S4.4 permadeath →
  S4.5 plan-runner) — creation flow is the product path; demo loadouts are the shortcut.
- **Bid-screen slice story** (ruled IN, decision #13) — rides KAN-6 mockup gate.
- **I-8 tag-description port** (on your paste, item 2).
- **Then:** KAN-6 mockup gate → slice readiness re-run → W3 vertical slice assembly.

### ✅ Landed 2026-07-18 (this session)

- Wave 0 calibration · Wave 1 census 26/26 (957 candidates) · Wave 2 launched.
- I-9 spectacle engine MERGED (66/66, two gates + mutation-proofed fix round).
- I-16 enemy AI built 94/94 (in review) incl. real pre-existing burst-breach bug fix.
- Rulings recorded + propagated: depiction v2 + carve-outs · Wave-2 shortlist
  (14×15) · slice cast = demo loadouts (build them) · tag slice approved (The Bit
  mechanically-null constraint) · char-sheet commit approved · decision log #10–#13.
- Proposals: contestants + slice tags both RULED in-doc.
- I-14 verified FIXED; `passive` one-liner approved for commit.
- Tag-description paste scaffold committed (84 headings).
