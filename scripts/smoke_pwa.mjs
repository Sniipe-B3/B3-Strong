// Browser-level PWA smoke test. Requires a Chromium binary; no npm dependency.
// CHROME_BIN=/path/to/chromium node scripts/smoke_pwa.mjs https://b3-strong.web.app
import {spawn} from 'node:child_process';
import {mkdtemp, readFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';

const url = process.argv[2] || 'https://b3-strong.web.app';
const chromeBin = process.env.CHROME_BIN;
if (!chromeBin) {
  console.error('Définissez CHROME_BIN avec le chemin du navigateur Chromium.');
  process.exit(2);
}

const profile = await mkdtemp(join(tmpdir(), 'petit-depart-pwa-'));
const browser = spawn(chromeBin, [
  '--headless', '--no-sandbox', '--disable-gpu', '--disable-dev-shm-usage',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank',
], {stdio: 'ignore'});

const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function until(check, label, timeout = 25000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try {
      const result = await check();
      if (result) return result;
    } catch { /* The browser or page may not be ready yet. */ }
    await pause(200);
  }
  throw new Error(`Délai dépassé : ${label}`);
}

let socket;
try {
  const port = await until(async () => {
    const data = await readFile(join(profile, 'DevToolsActivePort'), 'utf8');
    return Number(data.split('\n')[0]) || null;
  }, 'démarrage de Chromium');
  const target = await (await fetch(
    `http://127.0.0.1:${port}/json/new?${encodeURIComponent(url)}`,
    {method: 'PUT'},
  )).json();
  socket = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, {once: true});
    socket.addEventListener('error', reject, {once: true});
  });
  let sequence = 0;
  const pending = new Map();
  socket.addEventListener('message', ({data}) => {
    const message = JSON.parse(data);
    if (!message.id) return;
    const entry = pending.get(message.id);
    if (!entry) return;
    pending.delete(message.id);
    if (message.error) entry.reject(new Error(message.error.message));
    else entry.resolve(message.result);
  });
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++sequence;
    pending.set(id, {resolve, reject});
    socket.send(JSON.stringify({id, method, params}));
  });
  const evaluate = async (expression) => {
    const response = await send('Runtime.evaluate', {
      expression, awaitPromise: true, returnByValue: true,
    });
    if (response.exceptionDetails) {
      throw new Error(response.exceptionDetails.text);
    }
    return response.result.value;
  };

  await send('Page.enable');
  await send('Runtime.enable');
  await send('Network.enable');
  await send('Emulation.setDeviceMetricsOverride', {
    width: 390, height: 844, deviceScaleFactor: 1, mobile: true,
  });
  await send('Page.navigate', {url});
  await until(() => evaluate('document.readyState === "complete" && !!document.querySelector("flutter-view")'), 'affichage mobile');
  const manifest = await evaluate(`(async () => {
    const link = document.querySelector('link[rel="manifest"]');
    if (!link) return null;
    const response = await fetch(link.href);
    return response.ok ? response.json() : null;
  })()`);
  if (manifest?.display !== 'standalone' || !manifest.icons?.some((icon) => icon.sizes === '192x192')) {
    throw new Error('Manifeste PWA incomplet');
  }
  await until(() => evaluate('!!navigator.serviceWorker?.controller'), 'prise de contrôle du service worker');
  console.log('OK : affichage 390 × 844, manifeste et service worker');

  // A true offline reload after an online visit checks the installed app shell.
  await evaluate('window.__pwaSmokeMarker = true');
  await send('Network.emulateNetworkConditions', {
    offline: true, latency: 0, downloadThroughput: 0, uploadThroughput: 0,
  });
  await send('Page.reload');
  await until(() => evaluate('window.__pwaSmokeMarker !== true && document.readyState === "complete" && !!document.querySelector("flutter-view")'), 'redémarrage hors connexion');
  const offline = await evaluate('!navigator.onLine && !!navigator.serviceWorker.controller');
  if (!offline) throw new Error('Le navigateur ne confirme pas le mode hors connexion');
  console.log('OK : rechargement et affichage hors connexion');
} finally {
  socket?.close();
  browser.kill();
  await rm(profile, {recursive: true, force: true});
}
