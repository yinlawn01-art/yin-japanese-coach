'use strict';

// Saves the whole app on this site, then serves that copy with no network.
var CACHE = 'yin-japanese-coach-offline-v5';

var REQUIRED = [
  'index.html',
  'manifest.json',
  'version.json',
  'favicon.png',
  'flutter.js',
  'flutter_bootstrap.js',
  'main.dart.js',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/fonts/LXGWWenKai-Regular.ttf',
  'assets/fonts/AppText-Regular.ttf',
  'assets/fonts/AppJapanese-Regular.ttf',
  'assets/fonts/AppEmoji-Regular.ttf',
  'assets/fonts/fallback/Roboto-Regular.ttf',
  'assets/assets/homepage_shinkai.jpg',
  'assets/assets/home_title.png',
  'assets/assets/n5_adjectives.json',
  'assets/assets/n5_nouns.json',
  'assets/assets/n5_verbs.json',
  'assets/assets/example_patterns/01.json',
  'assets/assets/example_patterns/02.json',
  'assets/assets/example_patterns/03.json',
  'assets/assets/example_patterns/04.json',
  'assets/assets/example_patterns/05.json',
  'assets/assets/example_patterns/06.json',
  'assets/assets/example_patterns/07.json',
  'assets/assets/example_patterns/08.json',
  'assets/assets/example_patterns/09.json',
  'assets/assets/example_patterns/10.json',
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
];

var OPTIONAL = [
  'assets/NOTICES',
  'assets/shaders/ink_sparkle.frag',
  'assets/shaders/stretch_effect.frag',
  'canvaskit/webparagraph/canvaskit.js',
  'canvaskit/webparagraph/canvaskit.wasm',
];

function abs(path) {
  return new URL(path, self.location).href;
}

function store(cache, url, response) {
  var writes = [cache.put(url, response.clone())];
  if (url === abs('index.html')) {
    writes.push(cache.put(new URL('./', self.location).href, response.clone()));
  }
  return Promise.all(writes);
}

function precache(paths, required) {
  return caches.open(CACHE).then(function (cache) {
    return Promise.all(
      paths.map(function (path) {
        var url = abs(path);
        return fetch(url)
          .then(function (response) {
            if (response && response.ok) return store(cache, url, response);
            if (required) throw new Error(path);
          })
          .catch(function (error) {
            if (required) throw error;
          });
      }),
    );
  });
}

self.addEventListener('install', function (event) {
  event.waitUntil(
    precache(REQUIRED, true)
      .then(function () {
        return precache(OPTIONAL, false);
      })
      .then(function () {
        return self.skipWaiting();
      }),
  );
});

self.addEventListener('activate', function (event) {
  event.waitUntil(
    caches
      .keys()
      .then(function (keys) {
        return Promise.all(
          keys
            .filter(function (key) {
              return key !== CACHE;
            })
            .map(function (key) {
              return caches.delete(key);
            }),
        );
      })
      .then(function () {
        return self.clients.claim();
      }),
  );
});

function sameOrigin(request) {
  try {
    return new URL(request.url).origin === self.location.origin;
  } catch (e) {
    return false;
  }
}

self.addEventListener('message', function (event) {
  var data = event.data || {};
  if (data.type === 'precache-shell') {
    event.waitUntil(precache(REQUIRED, false).then(function () {
      return precache(OPTIONAL, false);
    }));
    return;
  }
  if (data.type !== 'cache-urls' || !Array.isArray(data.urls)) return;
  event.waitUntil(
    caches.open(CACHE).then(function (cache) {
      return Promise.all(
        data.urls.map(function (url) {
          return fetch(url)
            .then(function (response) {
              if (response && response.ok) return store(cache, url, response);
            })
            .catch(function () {});
        }),
      );
    }),
  );
});

self.addEventListener('fetch', function (event) {
  var request = event.request;
  if (request.method !== 'GET' || !sameOrigin(request)) return;

  var indexUrl = abs('index.html');
  var cacheReady = caches.open(CACHE);
  var update = cacheReady.then(function (cache) {
    return fetch(request)
      .then(function (response) {
        if (response && response.ok && response.type !== 'opaque') {
          return store(cache, request.url, response).then(function () {
            return response;
          });
        }
        return response;
      })
      .catch(function () {
        return null;
      });
  });
  event.waitUntil(update);

  event.respondWith(
    cacheReady.then(function (cache) {
      return cache.match(request, { ignoreSearch: true }).then(function (cached) {
        if (cached) return cached;
        return update.then(function (response) {
          if (response) return response;
          if (request.mode === 'navigate') {
            return cache.match(indexUrl).then(function (fallback) {
              return fallback || Response.error();
            });
          }
          return Response.error();
        });
      });
    }),
  );
});
