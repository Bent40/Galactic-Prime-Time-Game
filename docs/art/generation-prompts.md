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

## Kit 2 — Claude Design (claude.ai/design — HTML/React/SVG route)

Claude Design outputs designs as HTML/React/SVG, not image files. **The pipeline:**
design there → export standalone HTML → hand the file to this session → **the container
rasterizes it via headless Chromium at exact sprite sizes** (96px key pose / 48-rung
motion frames, nearest-neighbor) → judged on the same rubric. Its structural edge:
**component reuse makes consistency free** — both Nikita poses built from the same
parts ARE the same man by construction.

**A (paste into Claude Design):**
> Build an SVG pixel-art-style character sprite sheet as a React component. Define a
> design-token palette first (mutedOlive, wornBrown, scarfRed, skinWarm, outlineDark —
> max 12 colors) and build reusable body-part components: Coat, Scarf, Head, Arms,
> Legs. Compose TWO poses of the SAME elderly man side by side from those SAME
> components: pose 1 "OLD" — stooped, coat hanging loose, tired kind face, leaning
> forward; pose 2 "WAR" — identical parts re-posed: full height, shoulders squared,
> coat sitting like a 1940s uniform, cold stare. Crisp hard-edged shapes only (no
> gradients, no blur), chunky geometry that reads like modern HD pixel art, single
> dark outline. ViewBox sized so each figure is 96 units tall on a transparent
> background. The two poses must obviously be one person transformed.

**B:**
> Design a game HUD mock as an HTML page, 16:9: a dark hexagonal-grid arena floor
> (CSS/SVG hexes, three small character markers, one large boss marker with fire
> accents) with BROADCAST TV chrome layered on top as separate React components: a
> neon odds board showing "1:259", a sports-TV lower-third caption bar, a vertical
> hype meter that transitions cold blue → hot pink, a small "LIVE" bug in the corner.
> Reality-show-meets-casino: magenta/gold spotlights over grim stone. Design tokens
> for the chrome palette so the components stay consistent.

**C:**
> Same design system as the character sheet (reuse outlineDark + palette): an SVG
> sprite of a small grey-brown cat, low prowling stance, steel claw covers on the
> front paws (one steelBlue accent token), large expressive ears, 48 units tall,
> crisp hard-edged pixel-art-style shapes, transparent background.

**Motion-frame test:** ask it to re-pose the WAR components into a mid-swing frame
with simplified detail (drop interior shading, keep silhouette + palette) — component
reuse should make this its strongest event.

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

## Judging rubric (owner-scored as results land)

| Criterion | ChatGPT (scored 2026-07-17) | Claude Design | ComfyUI |
|---|---|---|---|
| Same-person test (A: two poses read as one man) | ✅ yes | | |
| Style consistency across subjects | ✅ consistent — but NO memory across images: consistency only holds if every prompt restates the canon block | | |
| Silhouette/readability at game size | ✅ readable | | |
| Motion-frame identity survival (the 48-rung test) | ✅ pretty good (smear frame landed) | | |
| Rework cost (can we edit the result?) | ✅ easy via prompt iteration | | |
| Volume cost (what does 50 more assets cost?) | 50 prompts | | |
| **Weakness** | **Output is an image, not a game asset** — no true alpha, arbitrary sizing, not sprite-sheet aligned, not palette-locked | | |

### GPT results — notes & mitigations (2026-07-17)

- Generated set: Nikita two-pose sheet (same-person ✅), War-Nikita smear-frame swing,
  Sasha crouch sprite, arena vignette w/ full broadcast chrome. **The arena frame is
  promoted to KAN-6 style-frame candidate** — Momus booth, odds board, hype meter all
  read.
- **Mitigation 1 (cross-image memory):** each subject gets a CANON BLOCK (fixed
  description paragraph, stored in this file) pasted verbatim into every prompt —
  consistency by discipline since the tool has none.
- **Mitigation 2 (image ≠ asset):** the in-container **asset-ification pass** closes
  the gap — background/checkerboard removal to true alpha, palette quantization,
  nearest-neighbor downscale to game sizes, sprite-sheet alignment (Python/PIL +
  Chromium). GPT-route = GPT stills + this pass. Drop source PNGs in
  `docs/art/samples/gpt/` when convenient.

**Decision rule (GDD, canon):** the ceiling is set by ANIMATION cost, not still-frame
beauty. The hybrid 64/48 technique is approved for testing: key poses at full fidelity,
in-betweens simplified — anchored so the first/last frame of every action is a key pose
and palette/silhouette never change mid-action.
