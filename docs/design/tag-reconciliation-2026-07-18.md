# Tag reconciliation — authoritative rulebook list → `data/tags.json` (I-8)

*Date: 2026-07-18. Source of truth: `docs/rulebook-tag-descriptions.md` (owner-provided,
100 tags). Target: `data/tags.json` (was 84 rows, now 100). Matching is by name
(case-insensitive slug), with the `[renamed from …]` note used to resolve the 7 rows the
owner renamed on 2026-07-17.*

**Result:** every one of the 84 existing rows matched an authoritative entry — **0 genuine
orphans**. Descriptions were filled verbatim from the rulebook (the punchy lead-in *and*
the earn-it instruction). The 16 authoritative-only tags were added as new rows. Only
`description` was touched/added; `effect`, `unlock_conditions`, and `goal_modifier_weights`
stay empty pending design (I-13 / I-27). `scripts/validate_seeds.py` → **OK, exit 0**.

## Counts

| bucket | count |
|---|---|
| Matched (description filled) | **84** (77 direct name match + 7 via rename note) |
| New (authoritative-only, added as rows) | **16** |
| Genuine orphans (in tags.json, no authoritative match) | **0** |
| Near-miss name mismatches resolved | **7** (the renames — see below) |
| **Final total tag rows** | **100** |

## ⚠️ Two things the main session must action

1. **DAL count test needs a bump.** `tests/test_dal_saves.gd:18` asserts
   `assert_eq(dal.tags().size(), 84, "tags")`. Row count is now **100**. I did **not**
   edit `tests/` (out of scope) — the main session must change `84` → `100` on that line.
2. **New-row id scheme is a flagged decision (see "ID decision" below).** I filled the
   reserved id gaps rather than appending 101–116. Trivial to renumber if the owner
   prefers append-style ids.

## ID decision — gap-fill, not 101–116 (flagged for review)

The task said "fresh sequential ids." I deviated **deliberately**, because the existing
id scheme is unmistakably **position-indexed**: the 84 existing ids run 1–100 with exactly
16 gaps, and those 16 gaps line up **1:1** with the 16 authoritative-only tags by their
position in the rulebook list. i.e. the seed data was generated as `id = list position`,
with the 16 un-ported tags' ids left reserved.

I therefore assigned each new tag `id = its 1-based position in the rulebook list`, filling
the gaps. Post-port, ids are contiguous 1..100 and `id == authoritative list position` — a
clean, meaningful invariant. New rows are **appended** at the end of the array (existing
row order untouched, per "preserve existing … order exactly"), so file order is
existing-1..100 then the 16 gap-fillers in ascending-id order.

No downstream code depends on tag id values (the DAL test checks only *count*;
`validate_seeds.py` never checks tag ids; `demo_loadouts.json` references tags by **key**,
not id) — so this choice is functionally safe either way. If the owner/main session
prefers literal append ids (101–116), renumbering the 16 new rows is a one-line change to
the port and breaks nothing.

## New rows added (authoritative-only — 16)

`effect` / `unlock_conditions` / `goal_modifier_weights` left empty pending design.

| id | key | name |
|---|---|---|
| 10 | `unkillable` | Unkillable |
| 12 | `vengeful` | Vengeful |
| 18 | `bolivian_army_ending` | Bolivian Army Ending |
| 20 | `coconut_superpowers` | Coconut Superpowers |
| 24 | `incorrigible` | Incorrigible |
| 27 | `little_dead_rising_hood` | Little Dead Rising Hood |
| 29 | `butcher` | Butcher |
| 60 | `nine_lives` | Nine Lives |
| 71 | `main_vocalist` | Main Vocalist |
| 73 | `maknae` | Maknae |
| 74 | `rap_line` | Rap Line |
| 76 | `comeback_stage` | Comeback Stage |
| 84 | `legacy_code` | Legacy Code |
| 85 | `corrupted_file` | Corrupted File |
| 90 | `null_pointer` | Null Pointer |
| 92 | `peer_review` | Peer Review |

## Near-miss name mismatches resolved (7 renames) — ⚠️ owner review

These 7 rows were renamed by the owner on 2026-07-17 (per each row's `notes`). Their
**current** names are **not** in the rulebook list, but each corresponds to an
authoritative entry via its `[renamed from …]` note (the note's original key slugifies to
the authoritative name). I matched them that way and filled the description **from the
authoritative (old-name) entry**. I did **not** change the current name/key — the rename
is a committed owner decision.

| id | current name / key | rulebook (authoritative) name | description sourced from |
|---|---|---|---|
| 6 | Reckless / `reckless` | **LEEROY JENKINS** | LEEROY JENKINS |
| 14 | What a Beaut / `what_a_beaut` | **Animal Planet** | Animal Planet |
| 16 | Shill / `shill` | **Corporate Asset** | Corporate Asset |
| 19 | Gorefest / `gorefest` | **Chunky Salsa Rule** | Chunky Salsa Rule |
| 42 | Heart Melter / `heart_melter` | **Certified Fresh** | Certified Fresh |
| 43 | Not My Job / `not_my_job` | **SAG Dispute** | SAG Dispute |
| 57 | Winter Sheep / `winter_sheep` | **Sea World Reject** | Sea World Reject |

**Divergence to flag for the owner:** `docs/rulebook-tag-descriptions.md` (dated
2026-07-18) still uses the **pre-rename** names for these 7 — the descriptions doc appears
to have been authored from a list predating the 2026-07-17 renames. Live seed data and the
slice proposal (`slice-tags-proposal.md` §RULED — Reckless, Gorefest are approved slice
tags) use the **new** names. The two are now reconciled *mechanically* (each renamed row
carries the correct authoritative description), but the **names still disagree**. The owner
should confirm the new names win and, ideally, update the rulebook descriptions doc to
match (so the detector-spec text and the tag name agree). Two of these (Reckless #6,
Gorefest #19) are live slice tags — keeping their names stable matters most there.

Note the descriptions still fit the new names well (Reckless ← "Plan? I don't need a plan!
Charge into a situation solo…"; Gorefest ← "Pop goes the goblin! Kill something in a way
that requires cleanup.") — no re-authoring needed, only a name-vs-doc confirmation.

## Genuine orphans

**None.** All 84 pre-existing rows resolved to an authoritative entry (77 by direct name,
7 by rename note). Nothing in `tags.json` is a candidate for cut.

## Method / integrity notes

- Descriptions were parsed **verbatim** from the markdown (not retyped), so apostrophes,
  internal em-dashes, and the one leading ellipsis (Blue Screen) are exact.
- Serialization preserved the existing style exactly: `indent=2`, `ensure_ascii=True` (so
  em-dashes render as `—`, matching the existing `notes` fields), no trailing newline.
  A self-check confirmed re-serializing the untouched input reproduced the original file
  byte-for-byte before any change was written.
- `scripts/validate_seeds.py` does **not** validate tag row shape (it only reads
  `tags.json` to build the key set for `demo_loadouts` checks) and does **not** check tag
  id/key uniqueness — so the new rows required **no validator change**. It still passes
  (exit 0). New keys/ids were asserted collision-free in the port anyway.
- Godot suite not run: this is a pure-data change and no Godot binary is available in the
  container; the only Godot-side impact is the DAL count assertion noted above.
