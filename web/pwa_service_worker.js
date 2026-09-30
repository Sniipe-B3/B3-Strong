// Cache the small app shell so the installed app can open without a connection.
// Fetches remain network-first, allowing new deployments to replace cached files.
// The Firebase predeploy hook replaces this build ID with a content hash.
// A new worker is then installed whenever the published app changes.
const CACHE_NAME = 'petit-depart-shell-__APP_BUILD_ID__';
const BASE_URL = new URL('./', self.registration.scope);
const SHELL_FILES = [
  '',
  'index.html',
  'flutter.js',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/shaders/ink_sparkle.frag',
  'assets/shaders/stretch_effect.frag',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) =>
      cache.addAll(SHELL_FILES.map((path) => new URL(path, BASE_URL).toString())),
    ),
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then(async (names) => {
      await Promise.all(
        names
          .filter((name) => name.startsWith('petit-depart-shell-') && name !== CACHE_NAME)
          .map((name) => caches.delete(name)),
      );
      await self.clients.claim();
    }),
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (request.method !== 'GET' || url.origin !== self.location.origin) return;

  event.respondWith(
    fetch(request)
      .then((response) => {
        if (response.ok && response.type === 'basic') {
          const copy = response.clone();
          event.waitUntil(
            caches.open(CACHE_NAME).then((cache) => cache.put(request, copy)),
          );
        }
        return response;
      })
      .catch(async () => {
        const cache = await caches.open(CACHE_NAME);
        const cached = await cache.match(request, {ignoreSearch: true});
        if (cached) return cached;
        if (request.mode === 'navigate') {
          const shell = await cache.match(BASE_URL.toString());
          if (shell) return shell;
        }
        return Response.error();
      }),
  );
});
