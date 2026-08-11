# v2 material has moved to the TTRPG repo

**Moved 2026-08-11.** Everything that was in `docs/versions/` — the v1/v2 fork spec, the
decision record, the three-way consistency guard, the seven research passes — plus the
floor arcs from `docs/narrative/`, now lives in:

> **`Galactic-Prime-Time/v2/`**

## Why

**D-06 ruled that v2 is "a new edition of the game book so I can run the game to a group"**
— a tabletop edition. Its material therefore belongs beside the tabletop rulebook, not
inside a Godot project.

The governing rule is **content lives where it is consumed**:

| Consumer | Needs | Repo |
|---|---|---|
| A GM running v2 at a table | v2 rulebook, floor arcs, cast sheets | **`Galactic-Prime-Time/v2/`** |
| The Godot sim | mythology corpus, seed data, architecture, GDD | **this repo** |
| Both | setting canon, the design record | canonical **here**, snapshotted into `v2/canon/` |

## What stayed here, and why

`data/mythology/`, `data/patron_roster.json` and the setting canon under `docs/` stay in
this repo because **tooling here consumes them** — `scripts/validate_seeds.py` validates the
corpus and `scripts/generate_patron_roster.py` generates the roster *from* it. Moving them
would break both.

The TTRPG repo carries a **provenance-stamped snapshot** of that material in `v2/canon/`,
refreshed by `Galactic-Prime-Time/v2/sync-canon.sh`. **If the snapshot and this repo
disagree, this repo is right.**

## Where to look now

| For | Go to |
|---|---|
| What v2 changes from v1 | `Galactic-Prime-Time/v2/design/v1-v2-fork-spec.md` |
| Every owner ruling | `Galactic-Prime-Time/v2/design/v2-decisions.md` |
| Floors 1–3 (design complete) | `Galactic-Prime-Time/v2/floors/floors-1-3-arc.md` |
| Floors 4–6 (proposal) | `Galactic-Prime-Time/v2/floors/floors-4-6-proposal.md` |
| Book ↔ app ↔ addendum drift | `Galactic-Prime-Time/v2/design/three-way-consistency.md` |
