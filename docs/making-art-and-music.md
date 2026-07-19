# Making Art & Music for *Galactic Prime Time* — A Starter Guide (from zero)

*Written 2026-07-19 for the owner. Goal: get you from "zero art experience, some music
background" to actually **making** sprites and music for this game yourself — and
understanding the programs, not just the theory. Everything here is tailored to **this**
project's setting and direction.*

> **How to use this doc:** it's long because it's a reference, not a lecture. Read
> **§0** first (it reframes your whole goal), then jump to whichever Part you want. The
> **§7 "first two weeks"** plan at the end tells you exactly what to open on day one.

---

## §0 — Read this first: how this fits *your* project

A few things are already true about this project that shape how you should learn:

1. **You want to make the art yourself — that's the better path, and a realistic one.** You
   said you'd rather hand-make sprites than generate them. Good. Hand-made art is more
   consistent, wholly yours to change, and — crucially for *this* game — lets you
   **deliberately control fidelity**, which turns out to be a design weapon here (next
   section). Part 1 is written for hand-making from scratch. *(The repo does hold an
   optional generation shortcut — `scripts/spritify.py`, which turns a GPT still into a
   game-ready sprite. I cover it in §1.2 as a **fallback/accelerator only** — e.g. a rough
   frame to paint over on a low-energy day. You never have to touch it. Make them yourself.)*

2. **Your reference style is already named: *Eastward* and *CrossCode* — "modern HD pixel
   art."** That's your north star, and it's a real, learnable target.

3. **Your "8-bit/64-bit" instinct is a deliberate art direction, not a beginner's shortcut
   — and a smart one.** You already know these labels "sound easier than real sprite art";
   you also want the *outside-looking-in* feeling and the option to shock the player later
   by contrast. All three are legit reasons. The next sections give you the accurate
   vocabulary (so tutorials make sense) and show why low-fi genuinely *fits* this game.

### "8-bit → 64-bit": the accurate vocabulary (so you can talk to tutorials and artists)

The low-fi look is the *goal*, not a mistake — but the "bit" labels will trip you up when
you search for tutorials, so here's the honest mapping:

- **"Bit" numbers describe consoles' CPUs, not an art style.** 8-bit = NES, 16-bit =
  SNES/Genesis, 32-bit = PS1, **64-bit = Nintendo 64.**
- **The 64-bit era (N64) is exactly where games *left 2D behind* for early, blurry,
  low-poly 3D.** So there's no "64-bit pixel-art look" to search for — type "64-bit sprite"
  and you'll get N64 3D, not the rich pixel art you mean. Use the words below and every
  tutorial lines up.

| You say | The style you actually mean | Search for / reference |
|---|---|---|
| "8-bit" (starter) | Simple, chunky, few-color sprites | "NES pixel art"; Zelda 1, Mario |
| (middle) | Rich shading, bigger palettes ("the golden age") | "16-bit / SNES pixel art"; Chrono Trigger, FFVI |
| "64-bit" (your "final") | **HD / "hi-bit" pixel art** — big sprites, huge palettes, sub-pixel animation | "HD pixel art"; **FFT, Eastward, CrossCode, Octopath** |

So the label to carry in your head is **"simple SNES-style sprites now → HD pixel art
(Eastward/CrossCode) later"** — the same low-fi family throughout, just better-shaded over
time. Your internal **"64/48 hybrid"** vocabulary is genuinely correct too — it just means
*key poses at full detail (96px) + in-between motion frames simplified (48px)*, a real
animation technique, not a console spec.

### Why low-fi is *right* for this game (the two reasons you were already sensing)

Your instinct to keep it low-fi isn't laziness — it's serving the fiction two ways:

1. **"Watching something unfold from the outside."** The Cosmic Casino frame is an
   audience — and literal gods — watching contestants on a broadcast, pieces on a game-show
   board. **Low-fi pixel sprites read as figures being *moved on a board*, seen from
   outside** — exactly that diegetic distance. Cranking fidelity would pull the player
   *into* the characters and fight the "we're all just watching the show" frame. Your gut is
   right; the restraint is the style.

2. **Contrast as a weapon — the Danganronpa move.** Precisely *because* the baseline is
   low-fi, you can occasionally cut to something fully animated and it lands like a
   gut-punch. Danganronpa does this on purpose: chibi/low-fi presentation for everyday play,
   then the Class Trial *executions* smash-cut to lavish, kinetic, fully-animated
   set-pieces — the gap is the horror. The low baseline is what *buys* the shock; if
   everything were high-fidelity, the execution wouldn't hit. (Undertale pulls a similar
   trick — plain sprites, then sudden bursts of detailed animation at key moments.)

   **This is a real, plannable technique, worth setting up for even though it's far off.**
   You don't build cutscenes now — you just keep the door open:
   - Keep two *separate presentation layers*: the in-engine pixel/sprite layer (everyday
     combat/exploration) and a **cutscene layer** that can hijack the whole screen. In Godot
     that's later a `VideoStreamPlayer` (pre-rendered clip) or a dedicated high-detail
     `AnimationPlayer` scene — see **§3.8**.
   - Spend the contrast on **rare, high-stakes beats** (a boss's true form, a contestant's
     elimination/"execution," a god cashing a contract). Rarity is the whole point — 3–5
     times in the game, not every fight.
   - The **same trick works in audio** (§2.6): if the whole soundtrack is chiptune, one
     sudden fully-orchestrated sting under the "execution" is the musical gut-punch.

### The through-line: fidelity is a *dial you control*, used two ways

Everything above says the same thing — **your fidelity level is a deliberate lever, not a
fixed tech tier.** You'll use that lever two ways:

- **Gradual ramp (a feature):** a contestant's tinny chiptune theme and rough sprite get
  *re-shaded and re-orchestrated* as they rise through the Casino and a god buys their
  contract — the art and music visibly level up *with* the stakes.
- **Sudden contrast (a weapon):** the rare smash-cut from low-fi to a fully-animated
  set-piece (the Danganronpa move above).

Both are the same skill: deciding, on purpose, how much detail a moment gets. **That is
exactly why learning to *hand-make* the art matters — you can't dial fidelity you don't
control.**

---

# PART 1 — PIXEL ART

## §1.1 — The core mental model (what pixel art actually is)

Pixel art isn't "low-res drawing." It's **deliberately placing every pixel** so the image
reads clearly at small size with few colors. Two dials control "fidelity":

1. **Resolution** — how big the canvas is (16×16 vs 96×96).
2. **Color + shading skill** — how many colors and how well you use light.

*Not* bits. A beautifully shaded 32-color 48px sprite beats a sloppy 200-color one every
time. **Good news for a beginner:** constraints (small canvas, few colors) do a lot of the
"looking good" for you — and they're the same constraints your deliberate low-fi look wants.

## §1.2 — How to actually start (hand-making first; generation is an optional crutch)

You want to make these yourself — so here's the honest path, and it's the same one every
pixel artist walks:

**Primary path — hand-make, small to large.** Start tiny (32×32) where every pixel is a
quick decision, learn the techniques in §1.5 on throwaway practice pieces (§1.10), then
scale the same skills up to your project's HD sizes. Authoring from a blank canvas is a
*skill you build*, not a wall — the §1.10 ladder is designed so you're making real-looking
assets within a couple of weeks. **Don't skip the small stuff:** a well-made 32px sprite
teaches you more than a struggled-over 96px one, and everything transfers straight up.

**Optional accelerator — cleaning up a generated frame.** The repo's `scripts/spritify.py`
can turn a GPT still into a **96px, ~32-color PNG with alpha** — an editable pixel canvas.
If you ever want a *head start* on a hard pose (or you're low on energy and just want to
paint over a rough base), open that PNG in Aseprite and **finish it by hand**:
- fix the **jaggy edges** the downscale leaves (§1.5d),
- kill **orphan pixels** and alpha-fringe halos (§1.5e, §1.5h),
- **re-shade** muddy areas with the hue-shift trick (§1.5f),
- tighten the **silhouette** (§1.5i).

That's a legitimate on-ramp *if you want it* — but it's a crutch, not the goal. Cleaning up
someone else's frame teaches you less than drawing your own, so treat it as an occasional
accelerator and wean off it. **Your real skill comes from the primary path.**

> **A note on the two sizes:** practice at **32×32** (fast, forgiving — the right way to
> *learn*); your finished *project* sprites are **96px HD-pixel scale** (Eastward-ish).
> Bridge the gap by learning small and scaling the same skills up. If 96px-from-scratch
> feels daunting early, that's exactly when the optional paint-over base earns its keep.

## §1.3 — Tools (what to install)

**Primary recommendation: Aseprite ($19.99, one-time).** It's the industry standard for
game pixel art, has the best animation timeline and tilemap tools, and — critically for a
beginner — **almost every tutorial you'll watch uses it.** Cross-platform (Win/Mac/Linux).
Buy it on Steam or aseprite.org and stop overthinking it.

- *$0 route:* Aseprite is source-available; its license lets you **compile it free from
  source for personal use** (github.com/aseprite/aseprite). Compiling is a real chore, so
  most people just pay the $20.

| Tool | Price | Platforms | When to use it |
|---|---|---|---|
| **Aseprite** ⭐ | $19.99 once | Win/Mac/Linux | The answer. Buy it. |
| **LibreSprite** | Free | Win/Mac/Linux | Best free *desktop* option; near-identical classic workflow (Aseprite tutorials mostly transfer). Missing tilemaps. |
| **Piskel** | Free | Browser | Fastest possible day-1 start — piskelapp.com, no install. Outgrow it quickly. |
| **Lospec Pixel Editor** | Free | Browser | Modern in-browser editor, good Piskel alt. |
| **Krita** | Free | Win/Mac/Linux/Android | Full painting suite w/ pixel brushes; good if you also want to *paint* (handy for later cutscene art). |
| **GraphicsGale** | Free | Windows only | Fine free fallback, dated UI. |
| **Photoshop** | $22.99/mo | Win/Mac | **Not recommended** — subscription, not pixel-first. Only if you already own it. |
| **Pixquare** | ~$10 once | iPad only | Best pick *if you work on an iPad + Apple Pencil.* |

**Recommended:** buy **Aseprite** today. To try before paying, start in **Piskel** (browser)
for an afternoon, then commit to Aseprite.

## §1.4 — Palettes (do this before you draw anything)

Don't pick colors freely — you'll make mud. **Download a ready-made palette** and work
within it. This single habit makes a beginner's work look cohesive instantly.

- Grab one from **lospec.com/palette-list** (2,500+ free palettes). Good starters:
  **PICO-8** (16 colors), **Endesga-32**, **AAP-64**.
- **Use ONE global palette across the whole game.** Consistency of palette + grid + outline
  style is what makes assets look like they belong together — more than any single sprite's
  quality. (If you ever use the `spritify.py` accelerator, it quantizes to ~32 colors, so a
  ~32-color global palette keeps hand-made and cleaned-up sprites consistent.)
- Per sprite, a good starting structure is **3–6 colors**: 1 dark (outline), 1–2 mid
  (base), 1–2 light (highlights), 1 accent.

## §1.5 — Core techniques, in the order you should learn them

This is the actual curriculum. Each concept is one skill; learn them roughly in order.

**a. Canvas & resolution.** Work at 1:1 and *zoom to view* (the editor scales with
nearest-neighbor so pixels stay crisp). Start practice at **32×32**. Never scale finished
art by non-integer amounts — only ×2, ×3, ×4, or it goes blurry/broken.

**b. Color ramps.** A *ramp* is an ordered chain of shades for one material (e.g. 4 skin
tones dark→light). You shade by moving along a ramp, not by randomly darkening.

**c. Outlines — pick one convention and never mix:**
- **Solid dark outline** (near-black or a very dark version of the fill) — clearest, most
  beginner-friendly. **Start here.** (It also reinforces the "pieces on a board" readable
  look you want.)
- **Colored outline** — a dark shade of the adjacent color instead of black; softer/modern.
- **Selective outlining** — outline only where the shape meets the background; drop it on
  lit interior edges. The advanced 16-bit+ look. Graduate to this later.

**d. Clean lines vs jaggies.** A good pixel line steps in a *consistent rhythm* (runs of
2-2-2 or 1-1-1). A **jaggy** is a break in that rhythm — one pixel jutting out of an
otherwise smooth run. **This is the #1 beginner mistake.** Fix by making each segment of a
diagonal the same length.

**e. Clusters & banding.**
- **Clusters:** group pixels of one color into clean readable shapes; kill stray single
  "orphan" pixels floating alone (they read as noise). At small size, *one pixel is a real
  decision.*
- **Banding:** an ugly thick zig-zag that appears when a shadow edge runs *parallel to and
  touching* the same staircase as the outline, doubling the jag. Avoid by not letting a
  shade band trace the exact same steps as the line next to it.

**f. Shading (the big one — spend the most time here).**
- **Pick ONE light source and commit** (top-left is the classic default). Everything is lit
  relative to it.
- **Think in forms:** sphere, cylinder, cube. Light side → mid-tone → core shadow (the
  darkest band is often *not* the far edge — real objects catch a little bounce light at the
  far rim).
- **HUE-SHIFT — don't just darken.** Making a shadow by only lowering brightness on the same
  hue = muddy, dead. Instead: as a color goes **into shadow, shift its hue toward cool
  (blue/purple)** and lower brightness; as it goes **into light, shift toward warm
  (yellow/orange)**. *Why:* real light is colored and shadows carry ambient sky color, so
  hue-shifting reads as actual light and makes limited palettes look vivid. **This is the
  single concept that separates flat beginner work from good pixel art.**

**g. Dithering.** Alternating two colors in a checker/pattern to *imply a third shade or a
gradient* without adding a color. Use for gradients (skies, gradual shadows) and texture
(dirt, rust). **Don't** dither everywhere (noise) or on tiny sprites (too busy). Modern HD
pixel art uses it sparingly.

**h. Anti-aliasing (manual AA).** Manually placing an intermediate-color pixel in the inner
corner of a stair-step to soften a jag on curves/diagonals. **Caution:** only AA against a
*known* background — AA'ing the outer edge of a sprite that sits on any map tile creates an
ugly "halo" fringe. **Skip AA until your lines are already clean.**

**i. Readability & silhouette (critical for a tactical RPG).** The sprite must read at
*actual game size* and as a solid black shape. **Test:** fill the whole sprite black — is it
still recognizable? Is the pose clear? On a tactical grid the player sees many small units
and must instantly tell them apart. **Distinct silhouettes beat interior detail.**
> *This is literally your Nikita design language* — the "two-posture silhouettes as
> transformation" (stooped old man ↔ squared-shoulder young soldier). The transformation
> reads because the *silhouettes* differ, not because of interior detail. Practicing
> silhouette directly serves your headline character moment.

## §1.6 — Animation (where your budget goes — and your fidelity ceiling)

Your GDD's rule is exactly right and worth repeating: **"the ceiling is set by animation
cost, not still-frame beauty."** Pick the highest fidelity you can *animate consistently* —
not the prettiest single frame. Practically:

- **Frame-by-frame.** Pixel art has no auto-tweening; you draw each frame.
- **Key poses first.** Block the extreme poses (e.g. a walk's two contact poses), *then*
  fill in-betweens. This is where your **64/48 hybrid** lives: **key poses at full 96px
  detail, in-between frames simplified at 48px.** Motion masks the detail loss; the poses
  that hold carry the beauty.
- **Sub-pixel animation.** At small sizes you can't move "half a pixel," so you fake small
  motion by *reshaping clusters and shifting shading*, not jumping whole pixels. This gives
  smooth breathing idles.
- **Timing via frame duration.** Hold a frame longer to slow it; "ease" by holding the
  extreme poses slightly longer. Spacing = sense of speed/weight.
- **Frame counts:** idle 2–6, walk 4–8 (classic 4: contact→down→passing→up), attack 3–6.
  FFT-style map sprites often use only 2–4. **Make sure the last frame loops cleanly into
  the first.**
- **Where to actually spend it (per your GDD):** the posture-swap transformations, hit
  reactions, and the crowd's visual temperature. Those sell the show — not idle flourishes.

> **Animation is also the honest limiter on the Danganronpa contrast.** A fully-animated
> execution is *expensive*. That's fine — the whole point is rarity, and low frame counts +
> smart key poses keep even the "big" moments affordable. Plan 3–5 of them, not 30.

## §1.7 — 2.5D tactical specifics (projection, sizes, directions)

**Projection — the most important structural decision.** Options, easiest first:
- **3/4 view (a.k.a. oblique / "JRPG perspective"):** you see the top *and* front at once
  (Pokémon, Zelda: A Link to the Past). **Easiest for a beginner** — no diagonal grid math.
- **Isometric / dimetric:** true diamond tiles (two sides + top). Pixel artists use **2:1
  "pixel isometric"** for clean stair-steps. More work per tile and per direction.

**What FFT actually does (and what you should copy):** FFT renders **maps as rotatable 3D
geometry** at a fixed iso angle, but the **characters are 2D billboard sprites in a
semi-frontal 3/4 view that always turn to face the camera** — *not* true isometric. Disgaea
and Tactics Ogre do the same. **So you do NOT have to draw true-iso characters.** You get
the FFT look with iso/3-4 *tiles* + simpler 3/4-view *character* sprites.

> **Your project is a "2.5D three-quarter top-down hex arena"** (per `generation-prompts.md`
> and DIRECTION D2). So: 3/4-view billboard-style character sprites over a **hex** terrain.
> Godot supports hex `TileMapLayer` grids natively (§3.3), so the engine side is handled —
> optimize your *art* effort by keeping characters 3/4-view.

**Sprite sizes (concrete):**
- **Tiles/hex terrain:** keep to one grid size; **32×32-ish** is the indie sweet spot.
- **Characters:** your project targets **96px key poses / 48px motion frames** (HD-pixel
  scale — matches Eastward). For *practice*, start at **32×32** and scale up.
- **Directions:** budget-friendly ladder is **4 directions** (up/down/left/right, with
  left/right as mirror-flips → really 3 drawings). **8 directions** (adds diagonals) is
  "full FFT" but ~doubles the work. **Start at 4.**
- Camera decision that gates art cost: **decide your camera-rotation freedom before drawing
  sprites.** Full rotation = you must draw every facing (expensive). Fixed/limited camera =
  far fewer directions. (Tactics Ogre shipped with limited rotation *because* the back views
  were never drawn — learn from that.)

## §1.8 — How comparable games actually do it (and proof you can too)

**HD-2D (Square Enix) — the name for what you want.** It's not a filter; it's a
*compositing approach*: **2D pixel sprites are billboarded into a fully 3D environment**,
then lit with modern effects (bloom, depth of field, tilt-shift, real shadows). The result
is a lit *diorama* — which, note, doubles down on your "watching a little staged world from
outside" feel. Origin: *Octopath Traveler* (2018). **The tactical one to study most:
*Triangle Strategy* (2022).** Engine: Unreal — the lighting/post does the heavy lifting.
**Why it matters to you:** you can ship rough sprites early and upgrade *presentation* later
(lighting, glow) *without redrawing every sprite* — that IS your "8-bit → HD" trajectory,
and Godot can do a budget version of it (§3.4).

**Classic sprite sizes (steal these numbers):**
- **FFT:** 64×64 character sprites, 8-direction turnaround, 3D terrain, iso 2:1.
- **GBA Fire Emblem:** map sprites **32×32**, battle sprites **64×64**, chars ~30–38px tall.
  Very achievable.

**Tiny teams shipped tactical RPGs — this genre is normal for solo/small:**

| Game | Team | Lesson for you |
|---|---|---|
| **Into the Breach** | **2 people** | *Clarity beats detail.* Deliberately simple art; every threat reads instantly. |
| **Fell Seal: Arbiter's Mark** | **2 people (a couple)** | The closest "small team made an FFT-like." Large crisp sprites + painted portraits. |
| **Wildermyth** | ~6 | "Papercraft" — flat 2D cut-outs staged in 3D = cheap convincing depth. |
| **Songs of Conquest** | small | Migrated *from* purist pixel *to* pixel-sprites-in-lit-3D — your exact trajectory. |
| **Wargroove** | Chucklefish | ~15,000 anim frames; whole pipeline built on **Aseprite**. |

## §1.9 — Don't make everything: start with placeholder assets

You won't hand-make a full tactical RPG's art before the game is fun. **Grey-box with free
assets, replace with your own later** — this doesn't conflict with "make it yourself," it
just keeps you unblocked while your skills catch up.

- **Kenney.nl** — huge **CC0** (public-domain, no attribution) library. The gold standard
  for placeholders. **kenney.nl**
- **itch.io asset store** — tons of pixel/tactical-RPG packs, free and paid. *Check each
  pack's license.* (itch.io/game-assets, filter Pixel Art + Tactical RPG.)
- **OpenGameArt.org** — big community library; licenses vary per asset — read each one.
- **Lospec** — for **palettes** (grab yours here first).

**Licensing in one breath:** **CC0** = do anything, no credit (safest — prefer it for
anything you'll ship). **CC-BY** = free but you must credit. **CC-BY-SA / GPL** =
"share-alike," can force your derivatives to be the same license — be cautious commercially.
**Keep a `CREDITS.txt` and a per-asset license log from day one**, even for CC0.

**The workflow:** (1) grey-box with CC0 assets; (2) lock your **grid size + global palette**
early; (3) build every asset to a **consistent slot spec** (same dimensions, same
pivot/anchor at the feet, same frame counts) so a replacement is a *texture swap, not a code
change*; (4) replace piece by piece with your own art as your skills grow.

## §1.10 — Your 8-milestone practice ladder

Each step adds exactly one skill and ends with something resembling real assets. Do these in
**Piskel or Aseprite** at **32×32** unless noted.

1. **Tool + first object.** Draw a 32×32 object (potion, apple) using a downloaded 4–5 color
   palette + a clean solid outline. *Goal: the editor, palettes, clean fills.*
2. **The ball with a light source.** Shade a sphere with one top-left light, using a ramp and
   **hue-shifting** (warm highlight, cool core shadow, edge bounce). *Goal: form & light —
   everything rests on this.*
3. **Study by copying.** Recreate a real NES/SNES sprite (a slime, a Chrono Trigger enemy)
   pixel-for-pixel. *Goal: absorb how pros cluster pixels. Not for publishing.*
4. **A seamless tile + tiny set.** Draw a tiling ground tile, tile it to check for seams, add
   2–3 connectors. *Goal: tiling + map-scale readability.*
5. **First character.** A 3/4-view character at project size. Run the **black-silhouette
   test.** *Goal: outline + ramp + shading on a real unit.*
6. **Directional set.** That character facing **4 directions** (mirror L/R). *Goal:
   consistency across views — the tactical-grid requirement.*
7. **Animate it.** A 2–4 frame idle (sub-pixel), then a 4-frame walk (key poses first).
   *Goal: timing, looping.*
8. **A mini-diorama.** Character + a few tiles + a prop under one palette. *Goal: a slice of
   an actual tactical map — your first "real" asset.*

**Then, when the ladder starts feeling comfortable:** apply the same skills to a real project
character at 96px — authored yourself, or (if you want a head start) painted over a
`spritify.py` base per §1.2. The ladder above is your gym; a finished project character is
the match.

**Learn-from resources (named):**
- **AdamCYounis — "Pixel Art Class"** (free YouTube playlist) — the best structured free
  course; use it as your spine.
- **MortMort** — beginner-friendly; his **"Aseprite Guide for Beginners"** is the tool
  onboarding to watch first.
- **Brandon James Greer (BJG)** — sharp technical breakdowns once you're past basics.
- **Saint11 / Pedro Medeiros — saint11.art/blog/pixel-art-tutorials** — ~80 free bite-size
  technique cards from the artist behind *Celeste*. Superb quick reference.
- **Lospec** — palettes + the web's biggest tutorial collection + free editor.
- **Book: "Pixel Logic" by Michael Azzi** — ~242 pages, mostly visual; ~$9 pay-what-you-want
  PDF (michafrar.gumroad.com). The best single paid reference.

---

# PART 2 — MUSIC

*You have music background, so this Part is mostly about **which program to open** and the
game-specific concepts (looping, adaptive layers). The theory you've got; the software is
the gap.*

## §2.1 — The music fidelity ladder (your "8-bit → 64-bit," done right)

Same reframe as the art. There was never a "64-bit music format." Game music went:

| "bit" | Console | Chip | How it makes sound | Voices |
|---|---|---|---|---|
| **8-bit** | NES | 2A03 | pure synthesis (PSG) | 2 pulse + triangle + noise + DPCM = 5 |
| **16-bit (A)** | SNES | SPC700 | **sampled** playback, soft/warm | 8 |
| **16-bit (B)** | Genesis | YM2612 | **FM synthesis**, bright/metallic | 6 FM + 4 PSG |
| **"32/64-bit"** | PS1/N64 | CD / streamed | **recorded/streamed audio** — no chip limits | ∞ |

So **"starter 8-bit → final 64-bit" = start with chip synthesis → sampled 16-bit
instruments → modern produced/orchestral audio.** The endpoint isn't a chip; it's
*unrestricted, produced sound.*

**Make the ladder a feature (fits your Cosmic Casino perfectly):** write your themes as
**leitmotifs** (a short recurring melody per contestant / boss / patron-god), then
**re-orchestrate the same motif up the ladder** as stakes rise — a contestant's tinny
chiptune theme becomes a full orchestral anthem when a god buys their contract. The
soundtrack levels up with the divinity economy — and gives you the audio version of the
low-fi→high-fi contrast on demand.

## §2.2 — Which program to open (route by what you want *today*)

There's no single answer — pick by intent. All three can coexist.

**① "I want to jam a retro tune in ten minutes" → Bosca Ceoil Blue (free).**
Made originally by Terry Cavanagh (*VVVVVV*) *specifically for non-producers*. Built-in
scales/chords so anything sounds good, ~100 presets, learns in **under 5 minutes**, runs on
Win/Mac/Linux **or in a browser**. **Start here this week.** (yurisizov.itch.io/boscaceoil-blue)

**② "I want real, exportable 8-bit NES music" → FamiStudio (free).**
A modern **piano-roll** DAW (no hex tracker pain) that targets the real NES chip and can
**export to actual NES ROM/audio**. The sweet spot of "modern UI, genuine 8-bit output."
Win/Mac/Linux/mobile. (famistudio.org)

**③ "I want one program that grows from chiptune to full orchestral" → FL Studio.**
Buy once; it's your forever-DAW for the whole multi-year project. Why it fits *you*:
- **Pattern / step-sequencer workflow** = fastest path from "idea in my head" → "loop I can
  hear": click steps to build a short loop, then drag patterns around the playlist like LEGO.
  Ideal for composing *structured* RPG cues.
- **Lifetime free updates** — buy once, stays current for the entire project.
- Scales cleanly from chiptune step patterns up to full orchestral/hybrid — one program you
  learn once. Editions: **Fruity $99** (MIDI/VST only, no audio recording — fine for game
  music) / **Producer $199** (adds audio recording — the real entry if you'll record live).
  Windows-native (it started as a Windows app), so it runs great on your setup.
  (image-line.com/fl-studio/pricing)
- **Try it free first (matches your "learn the program" goal):** the FL Studio **trial has
  no time limit and is fully featured** for making *and* exporting music — the only catch is
  you **can't reopen a saved `.flp` project** after closing FL until you buy. For learning
  the software that's a non-issue; upgrade the moment you want to keep a project going.

**Alternative to ③ if *live* jamming is your #1 priority → Ableton Live Intro ($99).**
Ableton's **Session View** is the best "improvise with loops" paradigm ever built — a grid of
clips you trigger live and layer on the fly, all in sync. **Session View is in every edition
including Intro.** If "jam like a live performance" beats "compose structured cues," this is
your pick (mind Intro's track/scene caps). Its **free interactive courses**
(learningmusic.ableton.com, learningsynths.ableton.com) are outstanding for a theory-literate
beginner learning the *software.*

**Free forever-DAW options (by OS)** if you don't want to pay yet:
- **Mac → GarageBand** (already installed, gentlest on-ramp; upgrade path = Logic $199 once).
- **Windows → Cakewalk Sonar** (most powerful free) or **Waveform Free** (cross-platform,
  takes VSTs).
- **Linux / cross-platform → Waveform Free**, or **LMMS** (closest free FL-style pattern jam;
  MIDI/synth only, no audio recording — fine for chiptune/synth).
- **Any machine, instant → BandLab** in a browser.

> **My recommendation for you (Windows + FL Studio, locked in):** jam in **Bosca Ceoil this
> week** for the instant win, and make **FL Studio** your forever-DAW. **Start on the free
> trial** (see ③ below) to learn the program — your actual goal — then buy **Fruity ($99)**
> or **Producer ($199)** when you commit. FL is Windows-native, so it'll run great on your
> machine. Free stopgap if you want one before touching FL: **Cakewalk Sonar** (Windows,
> full-featured, free).

## §2.3 — Chiptune the pro way (trackers vs. piano-roll, and VSTs)

- **Tracker vs piano-roll:** a *tracker* enters notes as a scrolling grid of hex text (one
  row per time-step, one column per channel) — authentic but a steep muscle-memory change. A
  *piano-roll* is the keyboard-vs-time grid you already think in. **Good news: the best
  modern chip tools (FamiStudio, and the VSTs below) give you a piano roll** — you don't have
  to learn hex unless you want hardware-exact authenticity.
- **Best free chip VST (use inside your DAW): Magical 8bit Plug 2** (free, by chiptune
  pioneers YMCK) — classic NES square/triangle/pulse/noise, low CPU. Write chip melodies in
  your familiar piano roll. (ymck.net)
- **For 16-bit / Genesis FM: Furnace** (free) — "the biggest multi-system chiptune tracker
  ever," does the Genesis **YM2612 FM** sound. Carries your 8-bit→16-bit transition.
  (tildearrow.org/furnace)
- Heavyweight paid authenticity (later, optional): **Plogue chipsounds** (~$95, emulates real
  chips), **Plogue chipsynth MD/SFC** (Genesis/SNES per-console).

## §2.4 — Sound effects (free, minutes each)

All descend from `sfxr`: pick "pickup / laser / explosion," tweak sliders, export WAV.
- **jsfxr** (sfxr.me) — pure browser, nothing to install. *Best for quick one-offs.*
- **ChipTone** (sfbgames.itch.io/chiptone) — more visual/hands-on, great characterful hits.
- **rFXGen** (raylibtech.itch.io/rfxgen) — desktop app that saves reusable `.rfx` presets —
  good if you want **version-controllable SFX** alongside the repo.

## §2.5 — Free instruments & samples (for the 16-bit and orchestral tiers)

- **Spitfire LABS** (labs.spitfireaudio.com) — free, excellent, one-knob-simple strings/
  pianos/synths/textures. The best free instrument source for beginners.
- **Spitfire Symphony Orchestra: Discover** (free, Nov 2025) — 44 instruments, full orchestra,
  5.68 GB, runs in free Kontakt Player. A genuinely serious **free orchestral starter for your
  "64-bit" tier** — and for the orchestral contrast sting. (spitfireaudio.com/pages/discover)
- **Vital** (vital.audio) — free wavetable synth ("the free Serum") for modern/hybrid sounds.
- **Soundfonts (.sf2)** — fastest route to 8-bit and 16-bit sampled instruments: **Woolyss
  chipmusic soundfonts** (woolyss.com/chipmusic-soundfonts.php) has curated Game Boy/NES/SNES/
  Genesis fonts — *directly on-target for your fidelity ladder.* Play them with the free
  **sforzando** or **Polyphone**, or your DAW's soundfont player.
- Also free & good: **Surge XT**, **Dexed** (DX7-style FM — great for Genesis flavor),
  **TAL-Noisemaker**.

## §2.6 — Game-music concepts you must know (this is the real "game" part)

Your composing is fine; these make music *work in a game.*

**Seamless looping — the #1 skill.** Author an optional **intro** + a **loop body**: the
intro plays once, then playback jumps to a **loop point** and repeats forever. Make it
seamless by bar-aligning sections and letting the loop's end flow musically into its start
(matching reverb tails, no clipped notes).
- **File mechanics:** export **OGG Vorbis** with loop metadata (`LOOPSTART` / `LOOPLENGTH`
  Vorbis comments, **in samples not seconds**: 7.84 s × 44100 = 345,544). **Godot's OGG
  importer supports loop points** (§3.5). Use **WAV** for short one-shots/SFX/stingers.
- Set tags in **Audacity**, or auto-find clean loop points with **PyMusicLooper**.
- **Typical lengths:** loops ~30 s–2:00; area/exploration themes 2:00–2:30 to avoid fatigue;
  aim ≥1:00–1:30 for anything heard repeatedly.

**Stingers.** Short (1–4 s) cues for discrete events — level-up, item pickup, death,
"objective complete." **Compose them in the same key/tempo as the underlying track so they
layer without clashing.** *Your GDD explicitly wants tip/achievement stingers — this is that.*
(And the rare *big* sting — a full-orchestra hit under an "execution"/boss-reveal — is the
audio half of the §0 contrast move.)

**Adaptive / interactive music — learn both (perfect for a tactical RPG):**
- **Vertical layering:** compose one piece as separate synced **stems** (drums, bass, pads,
  lead); fade layers in/out to change intensity *without changing the section.* **This maps
  directly onto your "crowd temperature" / hype meter and combat intensity:** base loop always
  plays, fade in percussion + brass as the hype bar climbs cold-blue → hot-pink. Godot does
  this natively with `AudioStreamSynchronized` (§3.6).
- **Horizontal resequencing:** pre-compose distinct **blocks** (explore → alert → combat →
  victory) and switch between them on gameplay events, snapping on the next bar so it's
  musical. Godot does this with `AudioStreamInteractive` (§3.6) — ideal for **exploration ↔
  combat** transitions.

**Leitmotifs** (see §2.1) — recurring themes per character/faction/god, re-orchestrated up
the fidelity ladder. Your show-within-a-game frame is *built* for this.

**Middleware (later, name-drop only):** FMOD and Wwise are the industry adaptive-music tools
(free indie tiers, Godot integration exists). **You don't need them** — Godot 4.3+'s built-in
adaptive streams (§3.6) cover you until complexity demands more.

**Learn-the-program resources (named):**
- **FL Studio:** **In The Mix** (youtube.com/inthemix) for beginner FL + mixing; Image-Line's
  official 2025 beginner series.
- **Ableton:** its own free **Learning Music** / **Learning Synths** web courses (excellent).
- **Chiptune:** **FamiStudio's official YouTube tutorials** ("Your First Song"); **Bosca
  Ceoil's in-app 5-minute tutorial.**
- **Game-music composition:** **8-bit Music Theory** (YouTube — analyzes real VGM composition,
  ideal for a theory-literate learner); **Marshall McGee** (sound design); the Game Audio
  Co.'s "vertical layering vs horizontal resequencing" article.

---

# PART 3 — GETTING IT INTO GODOT (4.5)

*Your `simulation/` is headless and command-stream-only; **art and audio live entirely in the
presentation layer** (scenes, talking to `GameController` via signals). Nothing here touches
the sim's purity contract.*

## §3.1 — Make pixel art crisp (the #1 Godot gotcha)

Godot 4 defaults to **Linear** filtering (smooth blending) — which *destroys* pixel art.

> **Outdated-tutorial trap:** in Godot **3** you unchecked a "Filter" box in the Import dock.
> **That box does not exist in Godot 4.** Filtering moved. Ignore any tutorial that says
> "disable Filter in the Import tab" — it's wrong for 4.x (and 4.5).

**Fix (one setting fixes ~95% of cases):**
`Project Settings → Rendering → Textures → Canvas Textures → Default Texture Filter` →
**Nearest**. Every node using the default now renders crisp.
- Per-node override if needed: any `CanvasItem` has a **`Texture Filter`** property → set
  **Nearest**. In code: `sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST`.

**PNG import settings (Import tab → Reimport):** **Compress → Lossless** (docs call Lossless
"recommended for pixel art"; **never VRAM Compressed**). **Mipmaps → off** for 2D.

## §3.2 — Pixel-perfect project setup (stops blur *and* jitter)

In `Project Settings` (enable "Advanced Settings"):
- **Base resolution** — `Display → Window → Size → Viewport Width/Height`: **640×360** is the
  recommended baseline (integer-scales cleanly to 720p/1080p/1440p/4K, no black bars).
- **Stretch** — `Display → Window → Stretch`:
  - **Mode:** **`canvas_items`** (renders at full window res, base res is a coordinate
    reference — sprites stay pixel-perfect *but* you get smooth camera moves + hi-res UI).
    **Recommended for your moving-camera tactical RPG with broadcast UI chrome.** The
    alternative `viewport` gives a purist look where *everything* is equally chunky (incl.
    UI) — present both, pick per taste.
  - **Aspect:** `keep` (simplest, one aspect ratio).
  - **Scale Mode:** **`integer`** (whole-number scaling — stops shimmering/uneven pixels).
- **Snapping** — `Project Settings → Rendering → 2D`: **Snap 2D Transforms to Pixel = On**
  (removes sub-pixel jitter on moving sprites); Snap 2D Vertices usually On too.

**Quick profile:** 640×360 · Filter Nearest · Stretch `canvas_items` · Aspect `keep` · Scale
`integer` · Snap Transforms On.

**Ready to paste into `project.godot`** — these are the exact settings above (your current
`project.godot` has none of them yet):

```ini
[display]

window/size/viewport_width=640
window/size/viewport_height=360
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"

[rendering]

textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```

*(`default_texture_filter=0` means Nearest.)* **Hold before applying, though:** per your GDD
the visual-style call goes through the **KAN-6 style-frame gate**, and base resolution +
stretch mode are part of that decision — so treat this block as *the recommended default to
adopt at KAN-6*, not something to bake in mid-KAN-2. That's why `project.godot` is left
untouched for now; say the word and I'll apply it (plus a Master/Music/SFX bus layout).

## §3.3 — Sprites, animation, tiles, depth

- **Static sprite:** **`Sprite2D`** (drag PNG onto `Texture`). For a spritesheet, set
  **`Hframes`/`Vframes`** + `Frame`, or use `Region`.
- **Animated character:** **`AnimatedSprite2D`** + a **`SpriteFrames`** resource → "Add frames
  from a Sprite Sheet" → set frame counts, name animations, set FPS + Loop → play in code:
  `$AnimatedSprite2D.play("run")`. (Use `Sprite2D` + `AnimationPlayer` instead only when you
  must animate frame *and* position/scale together.)
- **Tile/hex maps:** **`TileMapLayer`** (Godot 4.3+ **replaced the old `TileMap` node** — use
  `TileMapLayer`, one per layer, sharing a `TileSet` `.tres`). Supports hex grids — matches
  your hex arena.
- **Depth (2.5D) via Y-sort:** the old `YSort` node was removed; enable the **`Y Sort
  Enabled`** property on the parent `Node2D`/`TileMapLayer`. Children draw by Y position
  (lower on screen = in front). **Put each character sprite's origin at its feet** so it sorts
  correctly against terrain.

## §3.4 — Two ways to do "2.5D" (pick the simple one first)

- **(a) Pure 2D + Y-sort — recommended to start.** Everything is 2D
  (`Sprite2D`/`AnimatedSprite2D`/`TileMapLayer`), depth = Y-sort. No 3D cameras/lighting/
  materials to learn. Fully delivers the tactical-RPG look. *Start here.*
- **(b) 2D sprites in a 3D scene ("HD-2D" / Octopath).** `Sprite3D` billboards over real 3D
  terrain with a `Camera3D` → real lighting, shadows, depth of field, tilt-shift. Key props:
  **Billboard = `Y-Billboard`**, **Texture Filter = Nearest**, **Alpha Cut = Discard** (clean
  hard edges + correct sorting), tune **Pixel Size**. Also wants a low-res `SubViewport`
  upscaled for pixel-perfect 3D motion — the fiddly part. **Reach for (b) only when you
  specifically want 3D lighting / an orbiting camera / 3D post over your sprites.**

*Given DIRECTION D2 ("2.5D tactical, lowest asset cost, 3D reconsidered only at Stage 3"),
**(a) is the right call now**; keep (b) in your pocket for a later "premium" pass — that's
your art fidelity ladder expressed in the engine.*

## §3.5 — Audio: play, format, loop, buses

- **Music:** **`AudioStreamPlayer`** (non-positional). Set `Stream`, `Bus`, `Volume dB`,
  `Autoplay`; `play()`/`stop()` in code. (Positional world SFX use `AudioStreamPlayer2D`.)
- **Format:** **OGG Vorbis** for music/ambience/VO (compressed); **WAV** for short frequent
  SFX/stingers (uncompressed, cheap).
- **Loop a music track:** select the file → **Import** tab → **OGG/MP3:** tick **`Loop`** (+
  optional `Loop Offset` in seconds) → **Reimport.** **WAV:** `Edit → Loop Mode` = Forward
  with sample-accurate begin/end. Prefer setting loop at import for seamlessness.
- **Buses** (Audio bottom panel): add a **`Music`** and an **`SFX`** bus into Master; set each
  player's `Bus`. Then one slider controls a whole category
  (`AudioServer.set_bus_volume_db()`) — exactly what an options menu needs. Keep Master under
  0 dB.

## §3.6 — Adaptive music, natively (Godot 4.3+, in 4.5)

Assign one of these as the `Stream` on a normal `AudioStreamPlayer` — no FMOD/Wwise needed.
Import each stem with **BPM/Beat/Bar** set so transitions land musically.
- **`AudioStreamSynchronized`** — plays multiple stems **sample-locked**, independent volumes.
  → **Your vertical layering / hype-meter intensity** (fade a "combat"/"crowd" layer in over
  the base loop).
- **`AudioStreamInteractive`** — named clips + a **transition table** (switch immediately / at
  clip end / **on next beat or bar**, with fades). → **Your exploration ↔ combat** switch,
  snapping on a beat so it never sounds jarring.
- **`AudioStreamPlaylist`** — ordered/shuffled list with crossfades. → rotating ambient tracks.

## §3.7 — The 10-minute "first win" (do this to feel it working)

1. `Project Settings → Rendering → Textures → …→ Default Texture Filter` → **Nearest**.
2. `Display → Window → Stretch`: Mode **`canvas_items`**, Aspect **`keep`**.
3. Drag a `.png` into FileSystem → add a **`Sprite2D`** → drag PNG onto `Texture`. *Crisp.*
4. Drag `music.ogg` in → select it → Import tab → check **`Loop`** → **Reimport**.
5. Add an **`AudioStreamPlayer`** → drag the OGG onto `Stream` → tick **`Autoplay`** → press
   Play. *Looping music.*

```gdscript
extends AudioStreamPlayer
func _ready():
    play()   # Stream set in inspector, Loop enabled at import
```

## §3.8 — Leaving room for the contrast cutscene (far-off, cheap to plan for now)

You don't build these yet, but plan so future-you can. The Danganronpa-style smash-cut (§0)
is just a *second presentation layer* that temporarily takes over the screen:
- **Pre-rendered animated clip:** a **`VideoStreamPlayer`** node playing an **Ogg Theora
  (`.ogv`)** file — animate it in any tool later and drop it in.
- **In-engine high-detail scene:** a dedicated `AnimationPlayer` / `AnimatedSprite2D` scene at
  higher fidelity than your gameplay sprites, shown full-screen for the beat.

Either way it's **presentation only** — it reads game state and plays; it never touches the
headless `simulation/`, so nothing about the sim contract blocks it. The *entire* cost of
leaving the door open now is keeping combat art and any future cutscene as **separate
scenes**. Do that, and the shock-cut is available whenever you're ready to animate one.

**Canonical Godot docs:** importing images `/tutorials/assets_pipeline/importing_images.html`
· pixel-perfect/stretch `/tutorials/rendering/multiple_resolutions.html` · sprite animation
`/tutorials/2d/2d_sprite_animation.html` · tilemaps `/tutorials/2d/using_tilemaps.html` ·
audio import `/tutorials/assets_pipeline/importing_audio_samples.html` · audio buses
`/tutorials/audio/audio_buses.html` · video `/tutorials/animation/playing_videos.html` (all
under `https://docs.godotengine.org/en/stable`).

---

# §7 — Your first two weeks (a concrete, do-this plan)

You learn both faster by alternating — art when your ears are tired, music when your eyes are.
Assumes ~1 hr/day; scale to taste.

**Week 1 — get a win in each, cheaply.**
- **Day 1 (music, 20 min):** open **Bosca Ceoil Blue** in a browser, do its built-in tutorial,
  make a 30-second casino-glitzy loop. *You made game music today.*
- **Day 2 (art):** buy/open **Aseprite**, watch MortMort's "Aseprite for Beginners," do
  **milestone 1** (a 32×32 object with a Lospec palette).
- **Day 3 (art):** **milestone 2** — the shaded ball with **hue-shifting.** The most important
  art hour you'll spend.
- **Day 4 (Godot):** do the **§3.7 first-win** — crisp sprite + looping Bosca Ceoil export on
  screen in your actual project. Feel the whole loop close.
- **Day 5 (art):** **milestone 3** (copy a real sprite) — fastest way to level up.
- **Weekend:** **milestone 4** (a seamless tile). *Optional preview:* open a `spritify.py` base
  and try the §1.2 cleanup on one, just to see what 96px HD work feels like — then set it
  aside and keep hand-making.

**Week 2 — start making *your* assets.**
- **Music:** install **FL Studio** (start on the free trial; Producer $199 when you commit),
  add **Spitfire LABS** + **Magical 8bit Plug 2**, and write one **leitmotif** for a
  contestant — first as chiptune, then re-voiced with LABS (your fidelity ladder, in
  miniature).
- **Art:** **milestones 5–6** — your first 3/4-view character and its 4 directions. Run the
  **black-silhouette test** on the character.
- **Integration:** get that character into Godot as an **`AnimatedSprite2D`**, and set up a
  **`Music`/`SFX` bus** split with your leitmotif looping.

By the end you'll have: a crisp custom character you *made*, in-engine; a looping original
theme routed through buses; and the exact hand-making workflow — plus the optional shortcut,
if you ever want it. That's a real foundation for KAN-6.

---

## One-page quick reference

| Need | Reach for |
|---|---|
| Pixel art tool | **Aseprite** ($20) — or Piskel (free browser) to start |
| Palette | **lospec.com/palette-list** — one ~32-color global palette |
| Jam music *today* | **Bosca Ceoil Blue** (free) |
| Real 8-bit NES music | **FamiStudio** (free) |
| Forever-DAW | **FL Studio** (Windows-native; free trial → Fruity $99 / Producer $199) |
| Free chip VST | **Magical 8bit Plug 2** |
| Free orchestral | **Spitfire LABS** + **Symphony Orchestra: Discover** |
| Free synth | **Vital** |
| Retro SFX | **jsfxr** / **ChipTone** |
| Practice sprite size | **32×32** (learn); project = **96px key / 48px motion** |
| Directions | start **4** (mirror L/R), not 8 |
| Godot: crisp pixels | Default Texture Filter → **Nearest** |
| Godot: no jitter | Stretch `canvas_items` + Scale `integer` + Snap Transforms On |
| Godot: character anim | **AnimatedSprite2D** + SpriteFrames |
| Godot: map | **TileMapLayer** (not `TileMap`) |
| Godot: depth | **Y Sort Enabled**, origin at feet |
| Godot: loop music | OGG import → **Loop** on |
| Godot: combat↔explore music | **AudioStreamInteractive** |
| Godot: intensity layers | **AudioStreamSynchronized** |
| Godot: contrast cutscene | **VideoStreamPlayer** (`.ogv`) — separate scene |
| Style north star | **Eastward · CrossCode · Triangle Strategy (HD-2D)** |
| Contrast reference | **Danganronpa** executions (low-fi baseline → animated set-piece) |
| Safest asset license | **CC0** (Kenney.nl) — keep a CREDITS.txt anyway |

*Locked in: **Windows + FL Studio**, and the guide reflects that throughout. The one thing I
**didn't** do is edit your live `project.godot` — the §3.2 pixel-perfect settings (and a
Master/Music/SFX bus layout) are a **KAN-6 presentation decision** your GDD routes through
the style-frame gate, so applying them now would jump ahead of KAN-2. The exact block is in
§3.2, ready to paste. **Say "apply the Godot settings" and I'll drop the `[display]` /
`[rendering]` block and a `default_bus_layout.tres` into the repo for you.***
