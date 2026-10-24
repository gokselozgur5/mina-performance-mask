// Fake camera only: never opens a physical camera or saves image frames.
const fs = require('node:fs');
const path = require('node:path');
const args = process.argv.slice(2);
function option(name, fallback) {
  const index = args.indexOf(name);
  return index < 0 ? fallback : args[index + 1];
}
if (args.includes('--help')) {
  console.log('Usage: node tests/browser-smoke.cjs --fake-camera PUBLIC_SAMPLE.y4m [--url http://127.0.0.1:18765] [--output runtime/browser-smoke.json]');
  process.exit(0);
}
const sample = option('--fake-camera');
if (!sample || !fs.existsSync(sample)) {
  console.error('A public Y4M fake-camera sample is required; no physical-camera fallback.');
  process.exit(2);
}
const url = option('--url', 'http://127.0.0.1:18765');
const output = option('--output');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async () => {
  const browser = await chromium.launch({
    headless: true, channel: 'chrome',
    args: ['--autoplay-policy=no-user-gesture-required', '--use-fake-device-for-media-stream',
      `--use-file-for-fake-video-capture=${path.resolve(sample)}`],
  });
  try {
    const context = await browser.newContext({ permissions: ['camera'] });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    await page.goto(url);
    await page.waitForFunction(() => !document.querySelector('#camera').disabled);
    await page.click('#camera');
    await page.waitForFunction(() => window.timings.length >= 20, {}, { timeout: 60000 });
    const result = await page.evaluate(() => ({
      summary: window.latencySummary(), state: window.testState,
      output: { width: document.querySelector('#output').width, height: document.querySelector('#output').height },
      tracks: document.querySelector('#input').srcObject.getVideoTracks().map(track => track.readyState),
    }));
    await page.click('#stop');
    result.stoppedTracks = await page.evaluate(() =>
      document.querySelector('#input').srcObject.getVideoTracks().map(track => track.readyState));
    if (!result.tracks.length || result.tracks.some(state => state !== 'live')) throw Error('No live fake-camera track');
    if (result.stoppedTracks.some(state => state !== 'ended')) throw Error('Stop did not release camera');
    if (errors.length || result.state.errors) throw Error('Browser/frame errors occurred');
    result.pageErrors = errors;
    result.input = 'Public prerecorded sample through Chrome fake camera; not a physical-camera latency measurement';
    if (output) fs.writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
    console.log(JSON.stringify(result, null, 2));
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
