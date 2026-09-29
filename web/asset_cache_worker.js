// Cache immutable, commit-addressed binaries only. HTML/build.json always use network.
const PREFIX = 'inc-immutable-v1-';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  const match = url.pathname.match(/\/(game-[a-zA-Z0-9_-]+)\.(pck|wasm|js)$/);
  if (event.request.method !== 'GET' || url.origin !== self.location.origin || !match || event.request.headers.has('range')) return;
  event.respondWith((async () => {
    let cache;
    try {
      cache = await caches.open(PREFIX + match[1]);
      const hit = await cache.match(event.request);
      if (hit) return hit;
    } catch (_) {
      // Private-mode/storage-policy failures can also reject opening/reading.
      cache = undefined;
    }
    const response = await fetch(event.request);
    if (cache && response.ok && response.status === 200 && response.type !== 'opaque') {
      // Quota/private browsing failures must never prevent launching the game.
      // Keep only the build being played; each release is ~146 MB of storage.
      event.waitUntil(cache.put(event.request, response.clone()).then(async () => {
        const old = (await caches.keys()).filter(key => key.startsWith(PREFIX) && key !== PREFIX + match[1]);
        await Promise.all(old.map(key => caches.delete(key)));
      }).catch(() => {}));
    }
    return response;
  })());
});
