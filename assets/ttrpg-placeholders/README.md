# TTRPG placeholder assets (owner-provided 2026-07-18)

The owner's live-campaign art, dropped in as **placeholders** — reference/first-pass
visuals for the slice and KAN-6 chrome. Not final; freely replaceable.

**`.gdignore` is present on purpose:** Godot skips this directory, so these 14 MB of
images never enter the headless import path (they'd slow the sim test suite and clutter
`.godot/`). When KAN-6 wires real scene art, copy the chosen files into a Godot-scanned
`res://` path (e.g. `art/`) deliberately — don't just remove the `.gdignore`.

## Mapping to seed data (placeholders for what)

| Asset | Slice / seed entity |
|---|---|
| `Tokens and portraits/Mobs/Boss/Incine-Dile.webp` | **Incinedile** boss (`data/enemies.json`) — the slice boss |
| `Tokens and portraits/Mobs/Boss/Incinerator Room Boss.jpg` | Incinedile alt / arena portrait |
| `Tokens and portraits/Mobs/Elite/Little brother Roach.*` | elite `little_brother_roach` (`data/enemies.json`) |
| `Tokens and portraits/Mobs/Elite/Middle*/Big Brother Roach.*` | elite tier variants (future roach brothers) |
| `Tokens and portraits/Mobs/Normal/Trash Roach*.*` | mob tier (the `roach_dog` mob analogue) |
| `Tokens and portraits/NPC/Mycelius Chrom*.webp` | NPC — **RULED: a SERVANT figure, not a god.** A fungal servitor/attendant in the retinue of a death-and-harvest deity (Osiris is the natural liege — green decay-and-regrowth, the mycelial-network resonance), i.e. a `spirit`/servant NPC, NOT a patron god. NOT slice-critical (the slice uses Incinedile + roaches); reuse this art for that servant role later. |
| `Tokens and portraits/PC/*` | Filipe, Mario Marcus, Sasha, Xquezit — live-campaign PCs; **parked per the IP ruling** (not the game's original cast). Usable as demo-loadout portrait stand-ins only. |
| `Maps/Tutorial Floor/Playtest Incinerator Boss Room.jpg` | the slice arena reference |
| `Maps/Tutorial Floor/Playtest *.jpg` | tutorial-floor room references (Compactor, Sludge Hatchery, Sorting, Brothers, Tutorial) |

Note: the demo loadouts (`data/demo_loadouts.json`) are original (Imani, Dario) — the
PC portraits here are the *parked* campaign characters, usable only as neutral stand-ins.
