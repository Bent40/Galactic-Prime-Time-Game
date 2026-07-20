# Sprite Tester (dev tool)

A standalone **animation previewer**. Judge "does this walk cycle read? does this hit react
feel right?" with the game's **exact nearest-neighbor rendering** — without wiring the art
into an `AnimatedSprite2D`, attaching it to a scene, and running the whole game.

It is NOT part of the game: not referenced by `scenes/main.tscn`, no `simulation/`
dependencies, uses only Godot built-ins.

## Run it

Open `tools/sprite_tester/sprite_tester.tscn` in the Godot editor and press **F6**
(Run Current Scene).

## Two ways to load art (auto-detected)

- **A single spritesheet PNG** — *Load Sheet…* or drag one PNG in. Set **Frame W / H** to your
  cell size (e.g. `32`×`32`, or `96`×`96` for a key-pose sheet); it auto-slices row-major.
- **A folder of frame PNGs, or several PNGs dropped at once** — *Load Folder…*, drag a folder
  in, or drag-select all the frame files and drop them together. They play in **filename
  order**. This is exactly what Krita's **Render Animation → Image Sequence** produces — use
  zero-padded names (`frame_0000.png`, `frame_0001.png`, …) so they sort correctly.

Either way it plays immediately — tune **FPS** to taste.

## Controls

| input | action |
|---|---|
| **Space** | play / pause |
| **← →** | step one frame (pauses playback) |
| **↑ ↓** | FPS up / down |
| **Q / E** | previous / next PNG in the folder (spritesheet mode — review a whole cast fast) |
| **S** | silhouette test — fills the frame black so you can check readability |
| **B** | cycle background (checker / white / black / magenta) |
| **mouse wheel** | zoom |

## Notes

- Spritesheet frames are read left-to-right, top-to-bottom. If your sheet's cell size doesn't
  divide evenly, extra edge pixels are ignored (set Frame W/H to the true cell size).
- In frame-sequence mode the Frame W/H boxes are disabled — each PNG is one whole frame.
- The status bar shows the current source, frame index, detected grid / frame size, FPS,
  and zoom.
