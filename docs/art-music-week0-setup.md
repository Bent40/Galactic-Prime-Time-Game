# Week 0 — Setup & Familiarization Checklist (Art + Music)

*Companion to `docs/making-art-and-music.md`. Windows · Krita · FL Studio. This is the
"install it, then poke at it" phase — like a learn-to-code todo list, each task is one small
win that teaches one mechanic of the program. Tick them off. Don't aim for good art/music
yet; aim to know where every button is.*

---

# PART A — ART (Krita)

*Why Krita, not Aseprite: it's free and does **both** — your pixel sprites **and** the
high-fidelity cutscene/portrait art you'll want later (the Danganronpa-contrast idea). The
one thing Aseprite was better at — a fast animation-feedback loop — is now covered by the
repo's **sprite tester** (`tools/sprite_tester/`), which previews in the game's exact look.*

## A0 · Downloads

- [ ] **Krita** — free, **krita.org** (Windows installer). One program for pixel sprites
  *and* painted cutscene art.
- [ ] **A palette** — go to **lospec.com/palette-list**, pick one (**Endesga-32** or any
  ~32-color palette — matches what `spritify.py` outputs), download the **`.gpl`** (Krita
  imports it directly).
- [ ] *(already in the repo — nothing to download)* the **sprite tester** at
  `tools/sprite_tester/` — for previewing animations in the game's real rendering.
- [ ] *(optional, later)* **Kenney.nl** — bookmark it. Free CC0 placeholder art for when you
  need a whole scene before you can draw one.

## A1 · Familiarization todo (do these in order)

- [ ] **1. Make Krita behave like a pixel tool (one-time setup).** Krita is a big painting
  app, so tune it once so it *acts* like a pixel editor on demand:
  - **New document**, small — e.g. **64×64**.
  - **Brush:** in the **Brush Presets** docker, choose the **"Pixel Art"** preset tag → a
    hard 1px pencil (or set any brush to **size 1, no anti-aliasing, no pressure**).
  - **Palette:** open the **Palette docker** (Settings → Dockers → Palette), **import your
    `.gpl`** (docker menu → Import Palette), and pick your colors from it.
  - **Pixel grid:** work at **1:1** and **zoom to view** (Ctrl + mouse wheel) — the pixel
    grid appears when you zoom in.
  - **Save the setup:** **File → Create Template From Image** (so "new pixel sprite" is one
    click) and save a **"Pixel" workspace** (top-right workspace selector → New Workspace).
    Your full painting setup stays separate for cutscene art.
  *Goal: Krita is a pixel tool when you want it, a painting suite when you don't.*
- [ ] **2. Make marks.** Learn the essentials: **Brush (B)**, **Eraser (E)**, **Fill tool**
  (left toolbox), **pick a color (hold Ctrl)**, **zoom (Ctrl+wheel)**, **pan (Space+drag)**,
  **undo (Ctrl+Z)**. Scribble. *Goal: the canvas feels like a pencil.*
- [ ] **3. Draw one clean object.** A potion or apple: a solid **dark outline** first, then
  **flat fill** inside — colors from your palette. *Goal: outline discipline + fills.*
- [ ] **4. Shade a ball** (the important one). Draw a circle, pick a **light direction
  (top-left)**, shade with 3–4 shades — but **hue-shift**: highlight warmer, shadow cooler,
  not just darker. *Goal: the single skill all pixel art rests on.*
- [ ] **5. Animate a 2-frame bob.** Switch to the **Animation** workspace (or add the
  **Timeline** + **Onion Skins** dockers via Settings → Dockers). Add a 2nd frame, nudge your
  object up 1px, turn on **onion skin**, and press **Play** on the timeline. *Goal: Krita's
  animation timeline — and its built-in playback is your fast in-tool loop.*
- [ ] **6. Export + preview in the game's look.** **File → Export** a **PNG**. For the
  animation, either **Render Animation → Image Sequence** (a folder of frames) or draw the
  frames **side by side on one wide canvas** (e.g. `128×32` = four `32×32` frames). Then open
  the **sprite tester** (`tools/sprite_tester/sprite_tester.tscn`, press **F6**) and **drag
  the folder (or the sheet) in** — it plays with the game's exact nearest-neighbor rendering.
  *Goal: getting art OUT + the fast judge-it loop, with zero game wiring.*

**✅ Setup done when:** you can one-click into your pixel workspace, draw+shade a small thing
from your palette, animate a 2-frame bob and play it in Krita, export a PNG, and preview it in
the sprite tester — without googling.

**Then the first real task:** a 3/4-view sprite of a contestant (start ~32px, scale up to your
96px project size later). That's milestone 5 in the main guide.

> **Krita → game:** for finished animations, Krita exports a **frame sequence** (File →
> Render Animation → Image Sequence — use zero-padded names). **Drag that whole folder, or all
> the frame PNGs, onto the sprite tester and it plays them in order** — and Godot's
> `SpriteFrames` takes those individual frames directly too. Prefer a single file? Draw frames
> side-by-side on one wide canvas and export that spritesheet — the tester loads that as well.

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

1. **Day 1:** Bosca Ceoil tune (B1.1) — instant win. Install Krita + FL + plugins.
2. **Day 2:** Art A1.1–A1.3 (pixel workspace setup, marks, one object).
3. **Day 3:** Art A1.4 (the shaded ball — the big one).
4. **Day 4:** FL B1.2–B1.4 (orientation, beat, first melody).
5. **Day 5:** FL B1.5–B1.7 (LABS swap, arrange, export).
6. **Weekend:** Art A1.5–A1.6 (animate, export, and preview it in the sprite tester). You've
   now touched every core mechanic of both programs plus the preview loop.

Don't chase quality yet — chase *coverage*. Once every button is familiar, the main guide's
milestone ladders (`docs/making-art-and-music.md` §1.10 and §2) turn familiarity into real
game assets.
