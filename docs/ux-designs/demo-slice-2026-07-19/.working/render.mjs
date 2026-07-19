// Headless render of the demo-slice mockups to PNG.
// Uses the globally-installed playwright (node) + the pre-installed Chromium
// under PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers. No network, no install.
// Resolve playwright whether or not a local node_modules exists:
// try the bare specifier first, then fall back to the global install.
// (CJS interop: named exports may live under .default on dynamic import.)
let pw;
try {
  pw = await import('playwright');
} catch {
  pw = await import('/opt/node22/lib/node_modules/playwright/index.js');
}
const chromium = pw.chromium ?? pw.default?.chromium;
if (!chromium) throw new Error('could not resolve playwright.chromium');
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { existsSync } from 'fs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const base = join(__dirname, '..');
const workdir = __dirname;
const outdir = join(base, 'renders');

const jobs = [
  ['key-combat-hud.html',  'combat-hud.png'],
  ['key-bid-screen.html',  'bid-screen.png'],
  ['key-verdict-card.html','verdict-card.png'],
];

// Locate the pre-installed chromium if playwright's own resolution fails.
function findChromium() {
  const root = process.env.PLAYWRIGHT_BROWSERS_PATH || '/opt/pw-browsers';
  const candidates = [
    join(root, 'chromium', 'chrome-linux', 'chrome'),
    join(root, 'chromium-1194', 'chrome-linux', 'chrome'),
    join(root, 'chromium_headless_shell-1194', 'chrome-linux', 'headless_shell'),
  ];
  return candidates.find(p => existsSync(p));
}

const launchOpts = { args: ['--no-sandbox', '--force-color-profile=srgb', '--hide-scrollbars'] };
let browser;
try {
  browser = await chromium.launch(launchOpts);
} catch (e) {
  const exe = findChromium();
  if (!exe) throw e;
  console.log('Falling back to executablePath:', exe);
  browser = await chromium.launch({ ...launchOpts, executablePath: exe });
}

const ctx = await browser.newContext({
  viewport: { width: 1600, height: 1000 },
  deviceScaleFactor: 2,
});
const page = await ctx.newPage();

for (const [html, png] of jobs) {
  const src = join(workdir, html);
  if (!existsSync(src)) { console.log('SKIP (missing):', html); continue; }
  await page.goto('file://' + src, { waitUntil: 'networkidle' });
  await page.emulateMedia({ colorScheme: 'dark' });
  await page.waitForTimeout(150);
  const out = join(outdir, png);
  await page.screenshot({ path: out, fullPage: true });
  console.log('rendered', html, '->', out);
}

await browser.close();
console.log('DONE');
