import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

test('For Rosa manifest declares a stable, standalone installable app', () => {
  const manifest = JSON.parse(fs.readFileSync('web/manifest.json', 'utf8'));
  assert.equal(manifest.name, 'For Rosa');
  assert.equal(manifest.short_name, 'For Rosa');
  assert.equal(manifest.display, 'standalone');
  assert.equal(manifest.scope, './');
  assert.equal(manifest.id, './');
  for (const size of ['192x192', '512x512']) {
    assert(manifest.icons.some(icon => icon.sizes === size && fs.existsSync(`web/${icon.src}`)));
  }
});

test('Install action handles manual instructions, a user prompt and standalone mode', async () => {
  const listeners = {};
  let isStandalone = false, prompted = 0;
  const window = { addEventListener: (event, fn) => { listeners[event] = fn; }, matchMedia: () => ({ matches: isStandalone }) };
  vm.runInNewContext(fs.readFileSync('web/pwa.js', 'utf8'), { window, navigator: {} });
  assert.equal(await window.forRosaInstall(), 'manual');
  let prevented = false;
  listeners.beforeinstallprompt({ preventDefault() { prevented = true; }, async prompt() { prompted++; }, userChoice: Promise.resolve({ outcome: 'accepted' }) });
  assert(prevented);
  assert.equal(prompted, 0, 'Prompt must wait for the student to request installation');
  assert.equal(await window.forRosaInstall(), 'accepted');
  assert.equal(prompted, 1);
  assert.equal(await window.forRosaInstall(), 'manual', 'A used prompt cannot be reused');
  isStandalone = true;
  assert.equal(await window.forRosaInstall(), 'installed');
});

function workerHarness() {
  const handlers = {}, entries = new Map(), deleted = [], scope = 'https://study.test/DLS_app/';
  let online = true;
  const fetchOptions = [], precacheRequests = [];
  const cache = {
    async addAll(requests) { precacheRequests.push(...requests); },
    async put(request, response) { entries.set(typeof request === 'string' ? request : request.url, response); },
    async match(request) { return entries.get(typeof request === 'string' ? request : request.url)?.clone(); },
  };
  const self = { registration: { scope }, location: { origin: 'https://study.test' }, addEventListener: (name, fn) => { handlers[name] = fn; }, async skipWaiting() {}, clients: { async claim() {} } };
  const caches = { async open() { return cache; }, async keys() { return ['for-rosa-old', 'another-app-cache', 'for-rosa-__BUILD_ID__']; }, async delete(name) { deleted.push(name); } };
  const fetch = async (_request, options) => { fetchOptions.push(options); if (!online) throw Error('offline'); return new Response('fresh resource', { status: 200 }); };
  const workerSource = fs.readFileSync('web/sw.js', 'utf8').replace('/*__PRECACHE__*/ []', '["./main.dart.js"]');
  vm.runInNewContext(workerSource, { self, caches, fetch, Request, Response, URL, Promise });
  async function request(url, options) {
    const pending = []; let response;
    handlers.fetch({ request: new Request(url, options), respondWith(promise) { response = promise; }, waitUntil(promise) { pending.push(promise); } });
    const result = await response;
    await Promise.all(pending);
    return result;
  }
  return { handlers, entries, deleted, scope, request, fetchOptions, precacheRequests, offline() { online = false; } };
}

test('A new release refreshes stable asset URLs and online requests revalidate the HTTP cache', async () => {
  const worker = workerHarness();
  let installation;
  worker.handlers.install({ waitUntil(promise) { installation = promise; } });
  await installation;
  assert.equal(worker.precacheRequests[0].url, `${worker.scope}main.dart.js`);
  assert.equal(worker.precacheRequests[0].cache, 'reload');
  await worker.request(`${worker.scope}main.dart.js`);
  assert.equal(worker.fetchOptions[0].cache, 'no-cache');
});

test('Offline cache returns previously opened PDFs and leaves unrelated app caches alone', async () => {
  const worker = workerHarness();
  const pdf = `${worker.scope}assets/assets/papers/example.pdf`;
  assert.equal(await (await worker.request(pdf)).text(), 'fresh resource');
  worker.offline();
  assert.equal(await (await worker.request(pdf)).text(), 'fresh resource');
  assert.equal((await worker.request(`${worker.scope}assets/assets/papers/missing.pdf`)).status, 503);
  let completion;
  worker.handlers.activate({ waitUntil(promise) { completion = promise; } });
  await completion;
  assert.deepEqual(worker.deleted, ['for-rosa-old']);
});

test('Offline reader navigation can reuse its cached shell despite query parameters', async () => {
  const worker = workerHarness();
  worker.entries.set(`${worker.scope}reader.html`, new Response('reader shell'));
  worker.offline();
  assert.equal(await (await worker.request(`${worker.scope}reader.html?file=paper.pdf&page=4`)).text(), 'reader shell');
  assert.equal(await worker.request('https://other.test/file.pdf'), undefined, 'Other origins must not be intercepted');
});
