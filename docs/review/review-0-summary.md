# Galactic Prime Time — Review Summary (Index)

**Date:** 2026-07-13 · **Scope:** the TTRPG (rulebook docs + live campaign DB + character-sheet
app), the TTRPG→video-game conversion idea, and the Godot game repo. Four review jobs,
one verdict.

---

## TL;DR verdict

**Worth building. Continue this repo (don't start anew). Stay in Godot. Single-player
first, co-op-shaped bones, LLM-GM as a swappable north star. Next milestone: a brutally
small vertical slice — headless combat engine first, then one arena, two contestants,
Incineradile Phase 1, and a visible audience meter.**

The strongest asset: a play-tested, genuinely original core loop (Moment clock +
per-body-part conditions + audience metagame) with a live table proving it's fun.
The strongest market fact: the litRPG/Dungeon Crawler Carl audience (10M+ books, no video
game serving it) is an open, time-limited lane. The binding risk: solo-dev scope — the
GDD's full vision is a multi-year full-time project, and the repo's own history (a two-day
burst, then stall at the first hard epic) is the evidence to respect.

## The four reviews

| Doc | Question | One-line answer |
|---|---|---|
| [review-1-ttrpg.md](review-1-ttrpg.md) | Is the RPG good *as a TTRPG*? | Original, professional-grade combat core; identity/audience layer inspired but GM-leaning; economy/progression are sketches; ~40 verified rules defects catalogued (8 would block a cold table) — none block the *video game*, they're its requirements backlog. |
| [review-2-conversion.md](review-2-conversion.md) | Does it convert to a no-GM co-op video game? | Top-decile convertibility (deterministic, no dice, no GM in the damage path); the hard 20% is the audience/director layer, which is design work, not research; GDD says single-player while the stated target is co-op — decide consciously (recommendation: single-player first). |
| [review-3-game-repo.md](review-3-game-repo.md) | What is the Godot repo worth? | Architecture-complete, implementation-not-started: excellent GDD + architecture doc + real SQLite schema/migration runner, and 12 empty scripts + 16 empty scenes. Opens to an empty window. Keep the docs/schema; the code imposes zero lock-in. |
| [review-4-verdict.md](review-4-verdict.md) | Potential? Start anew? | Ceiling = cult hit (Fear & Hunger path); median = beloved niche; floor = the best tool your table ever had. Continue the repo with five recorded amendments; ambition bar: table-first now, public free slice as the commercial test. |

## Action list distilled (in order)

1. **Write the digital rules addendum** — answer Review 1's fix-first five (tick order &
   clock-reset wrap, declare/resolve timing + reactions, universal condition engine +
   missing tiers, advancement curve, RPM/reload economy + grapple rules). These are KAN-2's
   requirements.
2. **Record the amendments** to the architecture doc (single-player v1 reaffirmed; director
   module behind an interface; seed data must include per-part HP, condition/shock tiers,
   skill thresholds).
3. **Repo hygiene:** vendor godot-sqlite, set main scene, stubs → `RefCounted`.
4. **Build KAN-2 headless with unit tests** (the architecture doc already demands this).
5. **Vertical slice** (Review 4 §5) → put it in front of your table, then r/litrpg.
6. Only then: ambition/pricing decision, informed by real external signal.

## Source material reviewed

- `DCC esque System (1).docx` (full ruleset, ~1,150 lines converted), `Items.docx`,
  `Skill List.docx`
- MongoDB export: 5 live characters, 44 skill templates, 28 item templates, 100 tags,
  27 affixes, 3 enemies (incl. the 6-phase Incinedile boss)
- `Galactic-Prime-Time` (character-sheet app): full rules-encoding survey
- `Galactic-Prime-Time-Game`: full inventory, both design PDFs read, all claims verified
  first-hand
- Market comparables: web research with sources, July 2026 (see Review 4)
