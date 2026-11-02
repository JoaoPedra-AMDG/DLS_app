// The release build replaces these two placeholders with a revision and URLs.
const CACHE_NAME = 'for-rosa-__BUILD_ID__';
const PRECACHE = /*__PRECACHE__*/ [];
const local = path => new URL(path, self.registration.scope).href;

self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key.startsWith('for-rosa-') && key !== CACHE_NAME).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin || !url.href.startsWith(self.registration.scope)) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    try {
      const response = await fetch(request);
      if (response.ok && response.status === 200 && !request.headers.has('range')) {
        // Full PDFs are cached only when opened; do not pre-download the library.
        event.waitUntil(cache.put(request, response.clone()).catch(() => {}));
      }
      return response;
    } catch (_) {
      const cached = await cache.match(request);
      if (cached) return cached;
      if (url.pathname.endsWith('/reader.html')) {
        const reader = await cache.match(local('reader.html'));
        if (reader) return reader;
      }
      if (request.mode === 'navigate' && !url.pathname.toLowerCase().endsWith('.pdf')) {
        const shell = await cache.match(local('index.html'));
        if (shell) return shell;
      }
      return new Response('This resource is not saved offline. Reconnect to open it.', { status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
    }
  })());
});
