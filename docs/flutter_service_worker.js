'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "01c019986270c8e321439e857809c21a",
"assets/AssetManifest.bin.json": "d7e3d7b9eabdf0d92a7c898fd3a44d93",
"assets/AssetManifest.json": "6145c1ad5f41d9b43df53c45e35c98a2",
"assets/assets/fonts/Freesentation-1Thin.ttf": "c42db7a387b7d392cb9079b7cf538ffa",
"assets/assets/fonts/Freesentation-2ExtraLight.ttf": "80ef0ceb8868d24959b3851b9f65dcef",
"assets/assets/fonts/Freesentation-3Light.ttf": "180e8d02298abb08961dcf2ba03fc5e1",
"assets/assets/fonts/Freesentation-4Regular.ttf": "0e3b4b9ab43865658c69bd57db626839",
"assets/assets/fonts/Freesentation-5Medium.ttf": "a0f1f20e266142445cd933f3a3031d67",
"assets/assets/fonts/Freesentation-6SemiBold.ttf": "8f548c57f9a7936acc35168c76f774a3",
"assets/assets/fonts/Freesentation-7Bold.ttf": "7c88a4a74dbad732e5981db5151e3330",
"assets/assets/fonts/Freesentation-8ExtraBold.ttf": "8bdd97fca1d284f9c7babf3e995fba7c",
"assets/assets/fonts/Freesentation-9Black.ttf": "20614a91083b461a8f44e58275ffba34",
"assets/assets/fonts/ShadowsIntoLightTwo-Regular.ttf": "d1d0560ed79f47317d97baab7caea27b",
"assets/assets/images/bubble_tree.jpg": "7a2f0291218166400ea7cc593a0bc1dd",
"assets/assets/images/bubble_tree.svg": "c84d77c2c15265142a3c783372ef90a4",
"assets/assets/images/calendar.svg": "4a6535d95990b1ebe0b45ae45ba22458",
"assets/assets/images/flower_tree.jpg": "6375b2084e7a4091063ba4dcc686cafd",
"assets/assets/images/flower_tree.svg": "43a16027d041cd472093e37f2ec5429c",
"assets/assets/images/Menu.svg": "08aea63b5e09aa7e854760f5b7ba8bd0",
"assets/assets/images/Profile.png": "1651811d2c4a166b5aa65298efec455e",
"assets/assets/images/unWrittenDay.png": "e4d05d6e53a256c3405249b3a9eaac03",
"assets/assets/images/WriteButton.png": "7f55f128049488cd147a1859e5fd5a73",
"assets/assets/images/writtenDay.png": "910c7f9370c62f7b941ec6e60b0abd0d",
"assets/assets/svgs/tree_level_1.svg": "9577428fd027fe97fa09c4e7b5d60f7a",
"assets/assets/svgs/tree_level_2.svg": "c09d5435e2d787bd61e7a19604f600bd",
"assets/assets/svgs/tree_level_3.svg": "2fd6757549e010d0518d75152ff7a02c",
"assets/assets/svgs/tree_level_4.svg": "2dfea9d12a0f2bd112da71d18ece240a",
"assets/FontManifest.json": "4178084be2de877a4bda54ab7e0e4b23",
"assets/fonts/MaterialIcons-Regular.otf": "82220fcf6be5a99b10b20bdefcb2cf20",
"assets/NOTICES": "6472a9d60de9d2d1081847f7bd009103",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "083ffb44f005914ebbab540b50f2ec84",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "f87f77f9fb8741ceaa755dd16eac7a01",
"/": "f87f77f9fb8741ceaa755dd16eac7a01",
"main.dart.js": "7dfa7603a348d3662b35e7a9100576db",
"manifest.json": "1b9dffd866381c540655cb961a05a31b",
"version.json": "b537b8e9df4889870b515a3529fb0dd3"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
