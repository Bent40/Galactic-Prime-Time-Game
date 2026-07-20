# Sprite Tester (dev tool)

A standalone spritesheet **animation previewer**. Judge "does this walk cycle
read? does this hit react feel right?" with the game's **exact nearest-neighbor
rendering** — without wiring the sheet into an `AnimatedSprite2D`, attaching it to
a scene, and running the whole game.

It is NOT part of the game: not referenced by `scenes/main.tscn`, no `simulation/`
dependencies, uses only Godot built-ins.

## Run it

Open `tools/sprite_tester/sprite_tester.tscn` in the Godot editor and press **F6**
(Run Current Scene).

## Use it

- **Drag a spritesheet PNG onto the window**, or click **Load…**.
- Set **Frame W / H** to your cell size (e.g. `32`×`32`, or `96`×`96` for a
  key-pose sheet). It auto-slices the sheet into frames, row-major.
- It plays immediately — tune **FPS** to taste.

## Controls

| input | action |
|---|---|
| **Space** | play / pause |
| **← →** | step one frame (pauses playback) |
| **↑ ↓** | FPS up / down |
| **Q / E** | previous / next PNG in the same folder (review a whole cast fast) |
| **S** | silhouette test — fills the frame black so you can check readability |
| **B** | cycle background (checker / white / black / magenta) |
| **mouse wheel** | zoom |

## Notes

- Frames are read left-to-right, top-to-bottom. If your sheet's cell size doesn't
  divide evenly, the extra edge pixels are ignored (set Frame W/H to the true cell
  size).
- The status bar shows the current file, frame index, detected grid, FPS, and zoom.
