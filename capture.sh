#!/usr/bin/env bash
# Capture desktop + mobile screenshots of the exact $CAPTURE_URL into $CAPTURE_DIR.
# Exit 75 = temporary navigation/browser infrastructure failure (retryable).
# Exit 1  = script usage error or rendering defect (deterministic).
set -euo pipefail
cd "$(dirname "$0")"
/usr/bin/time -p test -n "${CAPTURE_URL:-}"
/usr/bin/time -p test -n "${CAPTURE_DIR:-}"
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p cat > /tmp/cod-capture-final.mjs <<'NODE_EOF'
import { createRequire } from 'node:module';
import { mkdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
const runtime = join(process.env.HOME, '.local/share/omgithub-playwright');
const require = createRequire(join(runtime, 'package.json'));
const { chromium } = require('playwright');
const { readFileSync } = await import('node:fs');
const cfg = JSON.parse(readFileSync(join(runtime, process.platform === 'darwin' ? 'metal.json' : 'linux.json'), 'utf8'));
if (process.platform === 'linux') process.env.DISPLAY ||= ':' + readFileSync(join(runtime, 'display'), 'utf8').trim();
const url = process.env.CAPTURE_URL, output = process.env.CAPTURE_DIR;
if (!url || !output) { console.error('Set CAPTURE_URL and CAPTURE_DIR.'); process.exit(1); }
mkdirSync(output, { recursive: true });
const transient = (err) => { throw Object.assign(err instanceof Error ? err : new Error(String(err)), { exitCode: 75 }); };
const fail = (msg) => { throw Object.assign(new Error(msg), { exitCode: 1 }); };
let browser;
try {
  browser = await chromium.launch({ ...cfg.browser.launchOptions, timeout: 30000 }).catch(transient);
  for (const view of [
    { name: 'desktop', width: 1440, height: 900, mobile: false },
    { name: 'mobile', width: 390, height: 844, mobile: true },
  ]) {
    const page = await browser.newPage({
      viewport: { width: view.width, height: view.height },
      hasTouch: view.mobile,
      isMobile: view.mobile,
    }).catch(transient);
    page.setDefaultTimeout(60000);
    const errors = [];
    page.on('pageerror', (e) => errors.push(String(e?.message ?? e)));
    page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text().slice(0, 300)); });
    const response = await page.goto(url, { waitUntil: 'load', timeout: 60000 }).catch(transient);
    if (!response?.ok()) {
      const s = response?.status();
      throw Object.assign(new Error(`HTTP ${s} loading preview`),
        { exitCode: !response || [408, 429, 500, 502, 503, 504].includes(s) ? 75 : 1 });
    }
    try {
      await page.locator('#game').waitFor({ state: 'visible', timeout: 30000 });
    } catch (e) {
      const body = await page.content().catch(() => '');
      if (/BOOT FAILURE/i.test(body)) fail(`rendering defect: boot failure on ${view.name}: ${errors.join(' | ').slice(0, 500)}`);
      throw Object.assign(e, { exitCode: 1 });
    }
    try {
      await page.waitForFunction(() => window.__READY__ === true, { timeout: 120000, polling: 1000 });
    } catch (e) {
      const body = await page.content().catch(() => '');
      if (/BOOT FAILURE/i.test(body)) fail(`rendering defect: boot failure on ${view.name}: ${errors.join(' | ').slice(0, 500)}`);
      fail(`rendering defect: game never signalled ready on ${view.name} (120s): ${errors.join(' | ').slice(0, 500)}`);
    }
    await page.waitForTimeout(2500);
    const path = join(output, `final-${view.name}.png`);
    await page.screenshot({ path, timeout: 30000 }).catch((error) => {
      if (error.name === 'TimeoutError' || !browser.isConnected()) transient(error);
      throw error;
    });
    const size = statSync(path).size;
    console.log(`Capture ${view.name}: ${path} (${size} bytes)`);
    if (size < 10000) fail(`rendering defect: screenshot too small on ${view.name} (${size} bytes)`);
    await page.close();
  }
} catch (error) { console.error(error); process.exitCode = error.exitCode || 1; }
finally { await browser?.close().catch((error) => { console.error(error); process.exitCode ||= 75; }); }
NODE_EOF
/usr/bin/time -p node /tmp/cod-capture-final.mjs
/usr/bin/time -p ls -la "$CAPTURE_DIR"
