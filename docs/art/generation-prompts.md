# Art generation test — prompt kits (fidelity-ladder comparison)

*Purpose (owner, 2026-07-16): compare generator routes BEFORE committing to an art
pipeline. Same three subjects across every method so results are comparable. Technique
under test: **hybrid fidelity** — high-detail key poses ("64-bit") + lower-detail
in-motion frames ("48-bit") — motion masks detail loss; key poses carry the beauty.*

## The three standard subjects (identical across all methods)

- **A — Nikita, two-posture sprite** (the acid test): same character, two stances —
  OLD: stooped old man in a long worn coat, scarf, gentle tired face · WAR: the same
  man squared and terrifying, coat like a uniform, stoop gone. If a method can't make
  these read as the SAME person transformed, it fails.
- **B — Combat vignette**: 2.5D three-quarter top-down hex arena slice with broadcast
  chrome (odds board, lower-third caption bar, hype meter as an on-air graphic).
- **C — Sasha sprite**: small cat, steel claw coverings glinting, low stance, big
  expressive ears, vent-shadow colors.

## Kit 1 — ChatGPT image generation

Paste as-is; generate each subject separately. Ask for PNG, request a plain background.

**A (key pose, high fidelity):**
> High-quality pixel art character sprite sheet, two poses side by side of the SAME
> elderly man, 96px tall character on transparent-style flat background. LEFT pose:
> frail old soldier, stooped posture, long worn olive coat, red scarf, kind tired face,
> leaning slightly on nothing, gentle. RIGHT pose: the same man transformed — standing
> at full height, shoulders squared, coat sitting like a 1940s military uniform, cold
> commanding expression, same red scarf. Same palette both poses (muted olives, warm
> browns, one red accent). Clean readable silhouette, dark single-pixel outline, modern
> HD pixel-art style like Eastward or CrossCode, side-lit, no text, no watermark.

**B (scene):**
> Modern HD pixel art game scene, 2.5D three-quarter top-down view of a hexagonal-grid
> arena inside a garish game-show dungeon: dark stone floor with glowing hex tiles,
> three small character sprites mid-battle, a giant crocodile-like boss with fire
> along its back. Broadcast TV overlay graphics ON TOP of the scene: a neon odds board
> in the corner showing "1:259", a lower-third caption bar reading like sports TV, a
> vertical hype meter glowing from cold blue to hot pink. Reality-show-meets-casino
> lighting: magenta and gold spotlights over grim dungeon stone. No real text beyond
> the odds numbers, no watermark, 16:9.

**C (small sprite):**
> Pixel art game sprite of a small grey-brown cat, 48px, low prowling stance, steel
> claw covers glinting on its front paws, large expressive ears, tail low, single-pixel
> dark outline, muted palette with one steel-blue accent, flat plain background,
> modern indie pixel-art style, no text.

**Motion-frame test (the 48-rung):** after A generates, follow up with:
> Now the RIGHT pose figure mid-action: a lunging hammer swing, motion smear on the
> arms, HALF the pixel detail of the previous image (chunkier pixels, simplified
> shading) but identical palette and silhouette weight. Same style.

## Kit 2 — Claude (honest note + the code-gen route)

Claude has **no native raster image generator** — if "Claude design" in your toolchain
wraps one, the Kit-1 prompts work verbatim there too. The genuinely Claude-native
route is **code-generated pixel art** (deterministic, version-controlled, animation
frames as transformations): I build subjects A/B/C as programmatic sprites in-container
(PIL/SVG → PNG). That entry in the comparison is produced by me on request — its
strengths are consistency and editability, its ceiling is stylization rather than
painterly detail.

## Kit 3 — ComfyUI (local box)

Suggested graph: SDXL checkpoint + a pixel-art LoRA (or a dedicated pixel-art
checkpoint), then the classic pixelization pass: generate at 1024², nearest-neighbor
downscale to 128–192px, optional palette-quantize (16–32 colors), nearest-neighbor
upscale back for viewing.

**Positive (subject A):**
> pixel art, sprite sheet, two poses of the same elderly soldier, left: stooped frail
> old man, long olive coat, red scarf, kind tired face; right: same man standing tall,
> squared shoulders, 1940s military bearing, cold expression, same coat and scarf,
> consistent palette, clean silhouette, dark outline, flat background, high quality,
> detailed pixel shading

**Negative:**
> photo, 3d render, blur, text, watermark, extra limbs, different characters, gradient
> background, anti-aliasing artifacts

Settings to start: CFG 6–7, 28–32 steps, DPM++ 2M Karras; batch 4 and pick. For the
**animation-consistency test**: take the chosen A frame into img2img at denoise
0.35–0.45 with the pose changed in the prompt ("mid hammer swing, motion smear") — the
low denoise preserves identity; this is the workflow's weak point we're probing.
Subjects B/C: adapt the Kit-1 texts into tag form the same way.

## Judging rubric (fill after generation)

| Criterion | ChatGPT | Claude code-gen | ComfyUI |
|---|---|---|---|
| Same-person test (A: two poses read as one man) | | | |
| Style consistency across subjects | | | |
| Silhouette/readability at game size | | | |
| Motion-frame identity survival (the 48-rung test) | | | |
| Rework cost (can we edit the result?) | | | |
| Volume cost (what does 50 more assets cost?) | | | |

**Decision rule (GDD, canon):** the ceiling is set by ANIMATION cost, not still-frame
beauty. The hybrid 64/48 technique is approved for testing: key poses at full fidelity,
in-betweens simplified — anchored so the first/last frame of every action is a key pose
and palette/silhouette never change mid-action.
