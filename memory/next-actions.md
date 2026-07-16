# Next Actions

<!-- wf memory: required sections below; keep the headings. -->

## Next actions

0. **Work from `docs/ISSUES.md`** — the ranked issue register compiled from reviews 1-6
   (F/B/T scoring, efficiency grades, four-wave execution plan). Wave 1 = one owner
   decision sitting; Wave 2 = the build block; Wave 3 = the slice; Wave 4 = story track.

1. Owner morning review: PROVISIONAL rulings (R2/R3/R4/R8/R9/R10) + R11 engine
   interpretation log in `docs/rules-addendum.md`; promote/adjust, then promote the
   combat-fields SKETCH in `docs/DIRECTION.md` if the tick rulings hold.
2. **Run the sim tests on a machine with Godot 4.5** (`bash scripts/run_sim_tests.sh`) —
   fix first-run failures, then re-signal the trace (`wf trace signal --kind tests --exit 0`).
3. Vendor godot-sqlite into addons/ (owner machine; container proxy blocks it), then
   KAN-3: main scene, GameController autoload, DAL seeding from data/*.json.
4. Vertical slice per review-4 §5: one arena, two premade contestants, Incinedile
   Phase 1, hype meter + one crowd Goal, broadcast-framed win/lose.
5. Content pass: tag descriptions from the rulebook docx; rpm/magazine fields on ranged
   items (R8); decide Camouflage third-stat schema question.
