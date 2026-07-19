# Week 0 — Setup & Familiarization Checklist (Art + Music)

*Companion to `docs/making-art-and-music.md`. Windows · Aseprite · FL Studio. This is the
"install it, then poke at it" phase — like a learn-to-code todo list, each task is one small
win that teaches one mechanic of the program. Tick them off. Don't aim for good art/music
yet; aim to know where every button is.*

---

# PART A — ART (Aseprite)

## A0 · Downloads

- [ ] **Aseprite** — $19.99 one-time, Steam or aseprite.org. *(Try-free option: use
  **piskelapp.com** in a browser for a day first, or **LibreSprite** free if you want $0.
  But Aseprite is worth it — every tutorial uses it.)*
- [ ] **A palette** — go to **lospec.com/palette-list**, pick one (**Endesga-32** or any
  ~32-color palette — matches what `spritify.py` outputs), download the **`.gpl`** or the
  palette **`.png`**. Save it somewhere you'll find it.
- [ ] *(optional, for later)* **Kenney.nl** — bookmark it. Free CC0 placeholder art for when
  you need a whole scene before you can draw one.

## A1 · Familiarization todo (do these in order)

Each is a ~10–20 min "hello world." Open Aseprite and:

- [ ] **1. Make marks.** `Ctrl+N` → 32×32 canvas. Learn the 6 tools you'll use 90% of the
  time: **Pencil (B)**, **Eraser (E)**, **Bucket fill (G)**, **Eyedropper (hold Alt)**,
  **zoom (mouse wheel)**, **pan (Space+drag)**, **undo (Ctrl+Z)**. Scribble. *Goal: the
  canvas + tools feel like a pencil.*
- [ ] **2. Load your palette.** Palette panel (left) → the small **folder/Options icon →
  "Load palette"** → pick your `.gpl`/`.png`. Click swatches to draw with them. *Goal: you
  never pick random colors again.*
- [ ] **3. Draw one clean object.** A potion or apple: a solid **dark outline** first, then
  **flat fill** inside with the bucket. *Goal: outline discipline + fills.*
- [ ] **4. Shade a ball** (the important one). Draw a circle, pick a **light direction
  (top-left)**, and shade it with 3–4 shades — but **hue-shift**: highlight warmer, shadow
  cooler, not just darker. *Goal: this is the single skill all pixel art rests on.*
- [ ] **5. Animate a 2-frame bob.** Bottom **timeline** → **New Frame (Alt+N)** → nudge your
  object up 1px → toggle **onion skin** → press **Enter/Play**. *Goal: the animation
  timeline — the thing that makes Aseprite special.*
- [ ] **6. Export three ways.** `File → Export Sprite Sheet` (spritesheet PNG for the
  engine), `File → Save As → .gif` (to share), and a plain `.png`. *Goal: getting art OUT —
  you'll need spritesheet + PNG for Godot.*

**✅ Setup done when:** you can open Aseprite, load your palette, draw+shade a small thing,
make it wiggle in 2 frames, and export a PNG — without googling which button.

**Then the first real task:** a 3/4-view sprite of a contestant (start ~32px, scale up to
your 96px project size later). That's milestone 5 in the main guide.

---

# PART B — MUSIC (FL Studio)

## B0 · Downloads

- [ ] **FL Studio** — the **free trial** at **image-line.com/fl-studio-download** (Windows,
  native). It's **fully featured with no time limit** — the only catch is you can't *reopen*
  a saved project until you buy (**Fruity $99** / **Producer $199** when you commit). Perfect
  for learning.
- [ ] **Magical 8bit Plug 2** — free chip VST, **ymck.net** (this is your 8-bit sound).
  Download the **VST3**, run the installer.
- [ ] **Spitfire LABS** — free instruments, **labs.spitfireaudio.com** (free account needed).
  Install a couple (e.g. **Strings**, **Soft Piano**) — this is your "orchestral" tier.
- [ ] *(optional)* **Vital** — free synth, **vital.audio**, for modern/synth sounds.
- [ ] **⚠️ Make FL see your VSTs:** after installing plugins, in FL do
  **Options → Manage plugins → "Find installed plugins"** (scan). Otherwise they won't show
  up in the plugin picker. *This trips everyone up once.*
- [ ] *(instant-win option, no install)* **Bosca Ceoil Blue** — **yurisizov.itch.io/boscaceoil-blue**
  (browser or download). Use it for task B1 below to make a tune *today* before the FL
  learning curve.
- [ ] *(bookmark)* **jsfxr — sfxr.me** — browser retro sound-effect maker, nothing to install.

## B1 · Familiarization todo (do these in order)

- [ ] **1. Make a tune today (outside FL).** Open **Bosca Ceoil**, do its 5-min built-in
  tutorial, make a 30-second casino-glitzy loop, **export a WAV**. *Goal: you've made game
  music before touching FL's learning curve — momentum.*
- [ ] **2. FL orientation.** Open FL. Learn the 4 windows and the transport:
  **Play/Stop = Spacebar**, **Playlist (F5)**, **Channel Rack (F6)**, **Piano Roll (F7)**,
  **Mixer (F9)**. Just open/close each. *Goal: know the four rooms of the house.*
- [ ] **3. Step-sequencer beat.** In the **Channel Rack (F6)**, click steps on the default
  **kick / snare / hat** to make a 1-bar beat. Press Space. *Goal: FL's signature "make
  sound in 60 seconds" workflow.*
- [ ] **4. A melody in the Piano Roll.** Add **Magical 8bit Plug 2** (click the **+** in the
  Channel Rack → find it), select it, open **Piano Roll (F7)**, and draw a short melody
  (**paint = hold and drag**). Here's where your music theory pays off. *Goal: the piano
  roll — your main tool.*
- [ ] **5. Swap the instrument (the fidelity ladder, live).** Load **Spitfire LABS Strings**
  on a new channel, copy the same melody onto it. Same notes, chiptune → orchestral. *Goal:
  adding real VST instruments + hearing "8-bit → 64-bit" in one click.*
- [ ] **6. Arrange a loop.** Drag your beat + melody **patterns** into the **Playlist (F5)**
  to build a simple **intro → loop** (~30–60s). *Goal: turning loops into a track.*
- [ ] **7. Set levels + export.** Route channels to the **Mixer (F9)**, pull volumes so
  nothing clips (stay under 0 dB), then **File → Export → WAV** (and try **MP3**). *Goal:
  getting music OUT — you'll export **OGG with looping** for Godot later.*

**✅ Setup done when:** you can start FL, make a beat, write a melody in the piano roll,
swap in a LABS instrument, arrange a short loop, and export a WAV — without googling.

**Then the first real task:** one **leitmotif** for a contestant — write it as chiptune
(Magical 8bit), then re-voice it with LABS. That's your Week-2 music goal in the main guide.

---

## Suggested rhythm for the week

Alternate — art when your ears are tired, music when your eyes are. A sane order:

1. **Day 1:** Bosca Ceoil tune (B1.1) — instant win. Install Aseprite + FL + plugins.
2. **Day 2:** Art A1.1–A1.3 (tools, palette, one object).
3. **Day 3:** Art A1.4 (the shaded ball — the big one).
4. **Day 4:** FL B1.2–B1.4 (orientation, beat, first melody).
5. **Day 5:** FL B1.5–B1.7 (LABS swap, arrange, export).
6. **Weekend:** Art A1.5–A1.6 (animate + export). You've now touched every core mechanic of
   both programs.

Don't chase quality yet — chase *coverage*. Once every button is familiar, the main guide's
milestone ladders (`docs/making-art-and-music.md` §1.10 and §2) turn familiarity into real
game assets.
