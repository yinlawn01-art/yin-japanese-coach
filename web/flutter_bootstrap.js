{{flutter_js}}
{{flutter_build_config}}

(function () {
  var builds =
    (window._flutter &&
      window._flutter.buildConfig &&
      window._flutter.buildConfig.builds) ||
    [];
  var release = builds.some(function (build) {
    return build.compileTarget === 'dart2js';
  });

  function start() {
    _flutter.loader.load({
      config: {
        fontFallbackBaseUrl: new URL('assets/font-fallback/', document.baseURI)
          .href,
      },
    });
  }

  if (!release || !('serviceWorker' in navigator)) {
    start();
    return;
  }

  var controlled = new Promise(function (resolve) {
    if (navigator.serviceWorker.controller) {
      resolve();
      return;
    }
    navigator.serviceWorker.addEventListener('controllerchange', function () {
      resolve();
    });
  });

  navigator.serviceWorker.register('app-offline.js').catch(function () {});

  Promise.race([
    controlled,
    new Promise(function (resolve) {
      setTimeout(resolve, 4000);
    }),
  ]).then(function () {
    var controller = navigator.serviceWorker.controller;
    if (controller) {
      var page = location.href.split('#')[0];
      var indexUrl = new URL('index.html', document.baseURI).href;
      controller.postMessage({ type: 'precache-shell' });
      controller.postMessage({
        type: 'cache-urls',
        urls: [page, indexUrl],
      });
    }
    start();
  });
})();
