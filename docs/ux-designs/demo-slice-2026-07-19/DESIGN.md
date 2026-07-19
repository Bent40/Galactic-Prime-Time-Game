---
# GPT — Visual Identity Spine (demo-slice, KAN-6 mockup gate)
# Source of truth for the sister web app's palette, extended for the game HUD.
# Every NUMBER shown in the mockups is PLACEHOLDER (R14).
meta:
  product: "Galactic Prime Time — Game (Godot)"
  screen: "vertical-slice demo — Incine-Dile Phase 1"
  frame: "Cosmic Casino broadcast · Momus hosts"
  canvas: { width: 1600, height: 1000, note: "landscape, game-screen proportions; renders @2x" }

color:
  # extends the character-sheet app palette EXACTLY (sister product)
  bg:      "#04050d"   # near-black navy — deepest space
  panel:   "#090c1a"   # base panel
  panel2:  "#0d1020"   # inset panel / control fill
  cyan:    "#00d4ff"   # primary accent — player / active / MOMENT / grid
  gold:    "#c8a84b"   # secondary accent — hype / patron / spectacle / CTA
  danger:  "#ff2255"   # LIVE dot · lethal HP · bleeding · outbid tension
  success: "#00ff88"   # steady · payouts · positive deltas
  text:    "#b8c8e0"   # body text
  muted:   "#3a4560"   # labels, hairlines, dormant
  border:  "#1a2540"   # 1px panel borders
  purple:  "#a855f7"   # CLOCK · crowd-goal timer · network/mycelium
  mythic:  "#ec4899"   # Momus / Enyo / heel register
  bronze:  "#cd7f32"   # tier
  silver:  "#c0c0c0"   # tier
  # semantic HP ramp (over base tokens)
  hp_full: "#00ff88"  # success
  hp_hurt: "#c8a84b"  # gold
  hp_crit: "#ff2255"  # danger
  # fire hazard (arena only, not a brand token — derived warm)
  fire:    "#ff7a2f"

typography:
  body_font:   "system-ui, -apple-system, sans-serif"
  number_font: "'Courier New', monospace"   # ALL stats/HP/counts/timers/multipliers
  title:       { weight: 900, tracking: "5–8px", glow: "cyan/gold text-shadow" }
  label:       { case: "UPPERCASE", size: "7–11px", tracking: "2–5px", color: "muted or accent" }
  scale:       { screen_title: 22-30, hero_verb: 70, section_h: 14-18, stat: 12-26, micro_label: 7-9 }

spacing:
  unit: 4          # 4px base rhythm
  panel_pad: "11–15px"
  gap: "9–16px"    # inter-panel gutters
  radius: { pill: "3–4px", panel: "5–7px", token: "9–22px", chip: "12–20px (rounded)" }
  border: "1px solid --border (accent-tinted when active)"

effect:
  neon_glow:  "text-shadow 0 0 20px rgba(accent,.7) — cyan & gold titles only"
  panel_glow: "box-shadow 0 0 22px rgba(accent,.3) for active/CTA panels"
  live_dot:   "@keyframes blink 1.1s — red ● at 1 / .15 opacity"
  broadcast_feed: "arena only — scanlines (repeating-linear-gradient 1px/3px) + radial vignette + corner cam marks"
  glow_rule:  "glow is RARE and load-bearing — accents only; never on --text, never on --muted"

component_tokens:
  broadcast_bar: "full-width; LIVE pill + REC(mono) · center brand(cyan glow)+gold sub · watching(mono)+MOMUS chip"
  pill:          "rgba-tinted bg + 1px accent border + radius 3–4px; number in --number_font"
  clock_pill:    "purple — CLOCK n"
  moment_pill:   "cyan — MOMENT nn"
  turn_token:    "34px face; current actor = cyan border+glow; boss carries WINDUP marker"
  hex:           "clip-path hexagon; dark-metal gradient; --fire variant; --cone telegraph variant"
  unit_token:    "billboard disc over tilted floor; cyan=player-anchor, gold=player-heel, orange=boss, muted=trash"
  hp_part_cell:  "6-up grid — HEAD/TORSO/L-ARM/R-ARM/L-LEG/R-LEG; mono value + ramp bar"
  condition_chip: "rounded pill, danger-tinted (🩸 BLEEDING T1)"
  hype_bar:      "gold gradient fill + inner glow; band label + delta pill"
  crowd_goal_card: "cyan-bordered; title + payout(success) + timer(purple) chips"
  camera_call_btn: "gold glow CTA; Charm-gated; doubles gains AND losses"
  patron_badge:  "⬡ sigil + god name; hestia=gold, enyo=mythic"
  chyron:        "mythic lower-third; MOMUS badge + italic quote"
  watermark:     "PLACEHOLDER NUMBERS · R14 — faint, rotated, bottom-right, every screen"
---

# Galactic Prime Time — Visual Identity Spine

The design spine for the vertical-slice demo HUD. It **extends the sister character-sheet
web app's palette exactly** (same repo family, same tokens) so the two products read as one
franchise, then adds the game-only vocabulary the broadcast HUD needs (arena, hype, patrons,
verdict). Rendered proofs: `renders/combat-hud.png`, `renders/bid-screen.png`,
`renders/verdict-card.png`. Sources: `.working/*.html`.

> Every number on screen is **PLACEHOLDER (R14)** — the watermark is on every frame. Shapes,
> hierarchy, and mood are the deliverable; values are not.

## Brand & Style

**Deep-space casino, shot as a live broadcast.** Near-black navy void (`bg`), panels a touch
lighter (`panel`/`panel2`), thin cyan/gold hairlines (`border`). The mood is *premium
control-room*, not arcade: restraint, monospace stats, a single blinking red `● LIVE`, and
neon reserved for the two things that matter — the player (`cyan`) and the spectacle
(`gold`). The host plane (Momus, `mythic`) and the divine plane (`purple` clock / patrons)
are the two "other worlds" leaning into the frame. One diegetic conceit governs everything:
**the player is always watching a show that is watching them back.**

## Colors

- **`cyan` = you / now.** Player-anchor tokens, the active actor, MOMENT, the hex grid edge,
  epithet unlocks. The eye's home color.
- **`gold` = spectacle / stakes.** Hype, patron favor, Camera Call, the SURVIVED verb, every
  primary CTA. Gold is *value on the table*.
- **`mythic` (pink) = the show's voice.** Momus, the heel register (Dario/Enyo), chyrons.
- **`purple` = the divine clock.** CLOCK pill, crowd-goal timers, the hidden network/mycelium.
- **`danger` = essence at risk.** LIVE dot, lethal parts, bleeding, and the *outbid* tension
  on the bid screen (a rival god crowding the signed patron).
- **`success` = held / earned.** STEADY status, payouts, positive hype deltas.
- **HP ramp** is `success → gold → danger` by damage; never invent new hues for it.
- **`fire` (#ff7a2f)** is an **arena hazard color only** — not a brand token. It marks
  fire-hazard tiles, the flamethrower cone, and the boss. It deliberately reads as *wrong* /
  dangerous against the cool palette, and ties to the "Fire Heals It" trap.

Do the whole UI in `bg`/`panel`/`text`/`muted` first; add an accent **only** where it earns
meaning. A screen that is 90% quiet makes the 10% of neon land.

## Typography

- **Body:** `system-ui`. **Every number** (HP, HYPE, MOMENT, multipliers, viewer counts,
  timers, bids) is **`'Courier New', monospace`** — the mono is the "instrument readout" cue
  that separates live telemetry from prose.
- **Labels** are UPPERCASE, 7–11px, letter-spacing 2–5px, `muted` or accent-colored — they
  frame data without competing with it.
- **Titles** are weight 900 with wide tracking and a neon `text-shadow`. The hero verb
  ("SURVIVED", 70px gold) is the loudest type on any screen and appears **once**.

## Layout

- **Fixed 1600×1000 broadcast frame.** A persistent **broadcast bar** on top (LIVE, brand,
  viewers, MOMUS) and, in-run, a **chyron** on the bottom bracket every screen — the show is
  the frame you never leave.
- **Combat HUD** is a three-column body under a clock/turn strip: a **left director rail**
  (~20%: objective, hazard read, god-wager ticker), the **center arena** (~58%, dominant,
  2.5D hex board with broadcast-feed overlay), a **right spectacle column** (~22%: hype,
  crowd goal, Camera Call), and **two contestant panels + an action bar** across the base.
- **Bid screen** is two symmetric contestant columns, each a stack of god cards (one SIGNED,
  rivals outbidding), over a lock-in footer.
- **Verdict card** is a single centered stage — kicker, hero verb, the spine question, and a
  row of "earned" cards — inside the same broadcast bar/chyron bracket.
- Rhythm: 4px base unit, 9–16px gutters, 5–7px panel radius, 1px accent-tinted borders.

## Components (see `component_tokens` in frontmatter)

Broadcast bar · clock/moment pills · turn-order tokens (with boss WINDUP marker) · hex tiles
(base / fire / cone) · billboard unit tokens · 6-part HP grid · condition chips · hype bar +
band + delta · crowd-goal card · Camera Call CTA · patron badge · chyron · R14 watermark.
Each is defined once and reused across all three screens so the demo reads as one system.

## Do's / Don'ts

**Do**
- Keep numbers in mono; keep glow on `cyan`/`gold` accents only.
- Keep exactly one blinking `● LIVE` and one hero focal point per screen.
- Reserve `fire` for arena hazard; reserve `purple` for clock/divine; reserve `mythic` for
  the show's voice.
- Stamp the R14 watermark on every frame while numbers are placeholders.
- Let ~90% of the surface stay quiet so the accents carry meaning.

**Don't**
- Don't import the sister app's `DMG_TYPES` / `RACES` lists (known drift — review-1). Use the
  rulebook conditions + this repo's seed enums.
- Don't glow body text or labels; don't add a second hero focal point.
- Don't use `fire`/`danger` as decoration — they always mean hazard / essence-at-risk.
- Don't present placeholder numbers as final — the watermark stays until the R14 rework.
- Don't add gradients-for-gradients'-sake; the casino is restrained, not neon-soup.
