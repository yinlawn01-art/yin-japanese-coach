'use strict';

var CACHE = 'yin-japanese-coach-offline-v1';

self.addEventListener('install', function (event) {
  event.waitUntil(self.skipWaiting());
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
  if (data.type !== 'cache-urls' || !Array.isArray(data.urls)) return;
  event.waitUntil(
    caches.open(CACHE).then(function (cache) {
      return Promise.all(
        data.urls.map(function (url) {
          return fetch(url, { cache: 'reload' })
            .then(function (response) {
              if (response && response.ok) return cache.put(url, response);
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

  event.respondWith(
    fetch(request)
      .then(function (response) {
        if (response && response.ok && response.type !== 'opaque') {
          var copy = response.clone();
          caches.open(CACHE).then(function (cache) {
            cache.put(request, copy);
          });
        }
        return response;
      })
      .catch(function () {
        return caches.open(CACHE).then(function (cache) {
          return cache.match(request).then(function (cached) {
            if (cached) return cached;
            if (request.mode === 'navigate') {
              return cache.match(new URL('index.html', self.location).href);
            }
          });
        });
      }),
  );
});
