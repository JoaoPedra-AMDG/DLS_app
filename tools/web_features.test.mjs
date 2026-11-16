import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import { attachReaderGestures } from '../web/reader-touch.mjs';
import { createPageQueue, nearbyPages } from '../web/reader-page-queue.mjs';

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

function gestureHarness({ width = 360, contentWidth = 360, left = 0 } = {}) {
  const listeners = {}, moves = [], zooms = [];
  let zoom = 1, renders = 0, scrollLeft = left, scrollTop = 0, frameId = 0;
  const frames = new Map();
  const viewport = {
    clientWidth: width, scrollWidth: contentWidth,
    get scrollLeft() { return scrollLeft; },
    set scrollLeft(value) { scrollLeft = Math.max(0, Math.min(contentWidth - width, value)); },
    get scrollTop() { return scrollTop; },
    set scrollTop(value) { scrollTop = Math.max(0, value); },
    addEventListener(name, listener) { listeners[name] = listener; },
    setPointerCapture() {},
  };
  attachReaderGestures(viewport, {
    getZoom: () => zoom,
    setZoom(value, x, y) { zoom = Math.max(1, Math.min(4, value)); zooms.push({ zoom, x, y }); },
    move(amount) { moves.push(amount); },
    render() { renders++; },
    requestFrame(callback) { frames.set(++frameId, callback); return frameId; },
    cancelFrame(id) { frames.delete(id); },
  });
  const pointer = (type, x, y, id = 1, extra = {}) => listeners[type]({ pointerId: id, clientX: x, clientY: y, button: 0, ...extra });
  return { viewport, moves, zooms, pointer, listeners, frames,
    frame(time) { const pending = [...frames.values()]; frames.clear(); pending.forEach(callback => callback(time)); },
    get zoom() { return zoom; }, get renders() { return renders; } };
}

test('Reader exposes only Back and Download, with accessible page text', () => {
  const html = fs.readFileSync('web/reader.html', 'utf8');
  assert.equal((html.match(/<a\s/g) || []).length, 2);
  assert(!/<button|<input|<form|<details/.test(html));
  assert(html.includes('← Back'));
  assert(html.includes('id="download" download'));
  assert(html.includes('id="page-text"'));
  assert(html.includes('touch-action:none'));
});

test('Vertical drags scroll the document and horizontal drags never turn pages', () => {
  const reader = gestureHarness();
  reader.pointer('pointerdown', 280, 200);
  reader.pointer('pointermove', 140, 205);
  reader.pointer('pointerup', 140, 205);
  reader.pointer('pointerdown', 80, 200);
  reader.pointer('pointerup', 220, 205);
  assert.deepEqual(reader.moves, []);
  reader.pointer('pointerdown', 120, 250);
  reader.pointer('pointerup', 120, 250);
  reader.pointer('pointerdown', 120, 250);
  reader.pointer('pointerup', 140, 250);
  reader.pointer('pointerdown', 120, 250);
  reader.pointer('pointermove', 150, 100);
  reader.pointer('pointerup', 150, 100);
  assert.equal(reader.viewport.scrollTop, 150);
  assert.deepEqual(reader.moves, []);
  reader.pointer('pointerdown', 120, 100);
  reader.pointer('pointermove', 120, 200);
  reader.pointer('pointerup', 120, 200);
  assert.equal(reader.viewport.scrollTop, 50, 'The same document scrolls back up');
});

test('Zoomed document drags pan without jumping pages even at an edge', () => {
  const reader = gestureHarness({ contentWidth: 900, left: 120 });
  reader.pointer('pointerdown', 250, 250);
  reader.pointer('pointermove', 100, 150);
  reader.pointer('pointerup', 100, 150);
  assert.equal(reader.viewport.scrollLeft, 270);
  assert.equal(reader.viewport.scrollTop, 100);
  assert.deepEqual(reader.moves, []);
  reader.viewport.scrollLeft = 540;
  reader.pointer('pointerdown', 250, 250);
  reader.pointer('pointerup', 100, 250);
  reader.viewport.scrollLeft = 0;
  reader.pointer('pointerdown', 100, 250);
  reader.pointer('pointerup', 250, 250);
  assert.deepEqual(reader.moves, []);
});

test('Two-finger pinch zooms in and out without accidentally changing pages', () => {
  const reader = gestureHarness();
  reader.pointer('pointerdown', 100, 250, 1);
  reader.pointer('pointerdown', 200, 250, 2);
  reader.pointer('pointermove', 300, 250, 2);
  assert.equal(reader.zoom, 2);
  assert.deepEqual(reader.zooms[0], { zoom: 2, x: 150, y: 250 });
  reader.pointer('pointermove', 200, 250, 2);
  assert.equal(reader.zoom, 1);
  reader.pointer('pointerup', 100, 250, 1);
  reader.pointer('pointermove', 20, 250, 2);
  reader.pointer('pointerup', 20, 250, 2);
  assert.deepEqual(reader.moves, []);
  assert.equal(reader.renders, 1, 'Render sharply after releasing the last finger');
});

test('Cancelled touches and lost capture cannot turn a page or poison the next gesture', () => {
  const reader = gestureHarness();
  for (const cancelled of ['pointercancel', 'lostpointercapture']) {
    reader.pointer('pointerdown', 280, 200);
    reader.pointer('pointermove', 100, 200);
    reader.pointer(cancelled, 100, 200);
    reader.pointer('pointerup', 100, 200);
  }
  assert.deepEqual(reader.moves, []);
  reader.pointer('pointerdown', 280, 200);
  reader.pointer('pointerup', 100, 200);
  assert.deepEqual(reader.moves, []);
});

test('Touch flicks keep scrolling and a new touch stops momentum', () => {
  const reader = gestureHarness();
  reader.pointer('pointerdown', 150, 400, 1, { pointerType: 'touch', timeStamp: 0 });
  reader.pointer('pointermove', 150, 300, 1, { pointerType: 'touch', timeStamp: 30 });
  reader.pointer('pointerup', 150, 300, 1, { pointerType: 'touch', timeStamp: 35 });
  const releasedAt = reader.viewport.scrollTop;
  reader.frame(51);
  assert(reader.viewport.scrollTop > releasedAt, 'The document coasts after a flick');
  reader.pointer('pointerdown', 150, 300, 1, { pointerType: 'touch', timeStamp: 60 });
  const stoppedAt = reader.viewport.scrollTop;
  reader.frame(76);
  assert.equal(reader.viewport.scrollTop, stoppedAt);
  reader.pointer('pointercancel', 150, 100, 1, { pointerType: 'touch', timeStamp: 80 });
  assert.equal(reader.frames.size, 0, 'Cancelled touches do not start momentum');
});

test('Trackpad pinch zooms and debounces rendering; normal wheel scrolling is preserved', async () => {
  const reader = gestureHarness();
  let prevented = 0;
  const wheel = { ctrlKey: true, deltaY: -50, clientX: 160, clientY: 300, preventDefault() { prevented++; } };
  reader.listeners.wheel({ ...wheel, ctrlKey: false });
  assert.equal(reader.zooms.length, 0);
  reader.listeners.wheel(wheel);
  reader.listeners.wheel(wheel);
  assert.equal(prevented, 2);
  assert(reader.zoom > 2);
  await new Promise(resolve => setTimeout(resolve, 160));
  assert.equal(reader.renders, 1);
  assert.deepEqual(reader.moves, []);
});

const flushPages = () => new Promise(resolve => setImmediate(resolve));

test('Continuous reader buffers visible pages, ahead and behind, including document ends', () => {
  assert.deepEqual(nearbyPages(1, 24), [1, 2, 3]);
  assert.deepEqual(nearbyPages(10, 24), [10, 11, 9, 12]);
  assert.deepEqual(nearbyPages(24, 24), [24, 23]);
  assert.deepEqual(nearbyPages(1, 1), [1]);
  const landscape = nearbyPages(3, 24, 1, 5);
  assert.deepEqual(landscape, [3, 1, 2, 4, 5, 6, 7], 'All visible short pages load before the buffer');
});

test('Background loading prioritises the reading page, limits concurrency and frees distant pages', async () => {
  const started = [], released = [], pending = new Map();
  const queue = createPageQueue({
    load(key) { started.push(key); return new Promise(resolve => pending.set(key, resolve)); },
    release(key) { released.push(key); },
  });
  queue.setWanted(nearbyPages(4, 24));
  await flushPages();
  assert.deepEqual(started, [4, 5], 'Reading page and next page start first');
  pending.get(5)();
  await flushPages();
  assert.deepEqual(started, [4, 5, 3], 'Only two pages render at once');
  pending.get(4)();
  await flushPages();
  assert.deepEqual(started, [4, 5, 3, 6]);
  pending.get(3)(); pending.get(6)();
  await flushPages();
  queue.setWanted(nearbyPages(5, 24));
  await flushPages();
  assert.deepEqual(released, [3], 'Only the distant canvas is released; the page space remains');
  assert.deepEqual(started, [4, 5, 3, 6, 7], 'Already buffered pages are reused while scrolling');
  pending.get(7)();
  await flushPages();
});

test('A fast scroll cancels stale pages and loads the new reading position', async () => {
  const started = [], released = [], pending = new Map();
  const queue = createPageQueue({
    load(key, signal) { started.push(key); return new Promise(resolve => pending.set(key, { resolve, signal })); },
    release(key) { released.push(key); },
  });
  queue.setWanted(['1:0', '2:0', '3:0']);
  await flushPages();
  queue.setWanted(['18:0', '19:0', '17:0']);
  assert(pending.get('1:0').signal.aborted);
  assert(pending.get('2:0').signal.aborted);
  pending.get('1:0').resolve(); pending.get('2:0').resolve();
  await flushPages();
  assert.deepEqual(started, ['1:0', '2:0', '18:0', '19:0']);
  assert.deepEqual(released, ['1:0', '2:0']);
  pending.get('18:0').resolve(); pending.get('19:0').resolve();
  await flushPages();
  pending.get('17:0').resolve();
  await flushPages();
});

test('Zoom replaces old page renders and rendering failures can retry on a later visit', async () => {
  const started = [], released = [], errors = [], pending = new Map();
  const queue = createPageQueue({
    concurrency: 1,
    load(key, signal) { started.push(key); return new Promise((resolve, reject) => pending.set(key, { resolve, reject, signal })); },
    release(key) { released.push(key); },
    onError(key) { errors.push(key); },
  });
  queue.setWanted(['5:0']);
  await flushPages();
  queue.setWanted(['5:1']);
  assert(pending.get('5:0').signal.aborted);
  pending.get('5:0').resolve();
  await flushPages();
  assert.deepEqual(started, ['5:0', '5:1']);
  pending.get('5:1').reject(Error('Temporary rendering failure'));
  await flushPages();
  queue.setWanted(['5:1']);
  await flushPages();
  assert.equal(started.length, 2, 'Failures must not create an infinite retry loop');
  assert.deepEqual(errors, ['5:1']);
  assert.deepEqual(released, ['5:0', '5:1']);
  queue.setWanted([]);
  queue.setWanted(['5:1']);
  await flushPages();
  assert.equal(started.length, 3);
  pending.get('5:1').resolve();
  await flushPages();
});
