/* Olitun offline-first service worker.
 *
 * Flutter no longer ships an offline service worker (flutter_service_worker.js
 * is a stub that unregisters itself), so this file owns the PWA app shell.
 * Scope: "/" — served as "/sw.js".
 *
 * Strategy:
 * - Navigations (/, /?source=pwa, /#/bakhed, /#/profile, ...): network-first,
 *   fall back to cached index.html, then offline.html. Query params are
 *   normalized so installed-PWA launches work offline.
 * - App shell bootstrap (flutter_bootstrap.js, main.dart.js, flutter.js):
 *   network-first with cache fallback so updates land fast but offline works.
 * - Static assets (assets/, canvaskit/, icons/, screenshots/, fonts):
 *   cache-first with background revalidation.
 * - Appwrite artwork (images/animations bucket view/preview renditions):
 *   cache-first in an UNVERSIONED media cache so Bakhed thumbnails, lesson
 *   covers and banners survive reloads, offline opens and app updates.
 *   Paid/lease media (audio, videos, paid_media, signed URLs) is never
 *   cached — those must always revalidate entitlement.
 * - API / external origins: network-only, never cached.
 */

'use strict';

const SW_VERSION = '1.3.1-31';
const STATIC_CACHE = `olitun-static-${SW_VERSION}`;
const RUNTIME_CACHE = `olitun-runtime-${SW_VERSION}`;
// Unversioned on purpose: artwork must survive app updates, otherwise every
// deploy would wipe the offline thumbnails users just built up.
const MEDIA_CACHE = 'olitun-media-v1';
const MEDIA_CACHE_MAX_ENTRIES = 300;
const MEDIA_CACHE_TRIM_TO = 220;

// Core shell — must all be cacheable for an offline cold start.
const APP_SHELL = [
  '/',
  '/index.html',
  '/offline.html',
  '/manifest.json',
  '/favicon.png',
  '/flutter_bootstrap.js',
  '/flutter.js',
  '/main.dart.js',
  '/pwa_runtime.js',
  '/pwa_install.js',
  '/canvaskit/canvaskit.js',
  '/canvaskit/canvaskit.wasm',
  '/canvaskit/chromium/canvaskit.js',
  '/canvaskit/chromium/canvaskit.wasm',
  '/canvaskit/webparagraph/canvaskit.js',
  '/canvaskit/webparagraph/canvaskit.wasm',
  '/assets/FontManifest.json',
  '/assets/AssetManifest.bin',
  '/assets/AssetManifest.bin.json',
  '/assets/fonts/MaterialIcons-Regular.otf',
  '/assets/fonts/fallback/Roboto-Regular.ttf',
  '/assets/assets/fonts/Inter-Variable.ttf',
  '/assets/assets/fonts/OlChiki.ttf',
  '/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  '/assets/assets/seed/lessons.json',
  '/assets/assets/seed/categories.json',
  '/assets/assets/seed/vocab_lessons.json',
  '/assets/assets/seed/alphabet_lessons.json',
  '/assets/assets/seed/numbers.json',
  '/assets/assets/seed/sentences.json',
  '/assets/assets/seed/sentence_lessons.json',
  '/assets/assets/seed/words.json',
  '/assets/assets/seed/letters.json',
  '/assets/assets/seed/rhymes.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
  '/icons/apple-touch-icon.png',
  '/assets/assets/icons/app_icon.png',
  '/assets/assets/icons/olitun_logo.png',
  '/assets/assets/images/olitun_mascot.png',
];

// Prefixes that are safe to cache long-term (immutable-ish build output).
const CACHE_FIRST_PREFIXES = [
  '/assets/',
  '/canvaskit/',
  '/icons/',
  '/screenshots/',
];

// Exact-or-subdomain host match. A bare endsWith('appwrite.io') would also
// match attacker domains like evilappwrite.io, letting them plant cached
// artwork responses.
function isTrustedHost(hostname, suffix) {
  return hostname === suffix || hostname.endsWith(`.${suffix}`);
}

function isAppwriteHost(hostname) {
  return (
    isTrustedHost(hostname, 'appwrite.io') ||
    isTrustedHost(hostname, 'appwrite.run')
  );
}

// Appwrite buckets whose view/preview renditions are plain public artwork.
// Deliberately excludes audio / videos / cover_videos / paid_media: media
// files are too large for the SW cache, and paid_media serves short-lived
// signed lease URLs that must never be served stale.
const MEDIA_CACHE_BUCKETS = ['images', 'animations'];
const MEDIA_VIEW_PATTERN =
  /\/storage\/buckets\/([^/]+)\/files\/[^/]+\/(view|preview)([\/?]|$)/;

// True for cacheable Bakhed thumbnails, lesson covers, banners and remote
// Lottie/SVG artwork. Checked BEFORE the network-only Appwrite rule below.
function isCacheableAppwriteMedia(url, request) {
  if (request.method !== 'GET') return false;
  if (!isAppwriteHost(url.hostname)) return false;
  // Never cache authed or signed responses (paid leases, admin mode).
  if (request.headers.has('authorization')) return false;
  const params = url.searchParams;
  if (params.has('token') || params.has('jwt') || params.has('signature')) {
    return false;
  }
  const match = url.pathname.match(MEDIA_VIEW_PATTERN);
  if (!match) return false;
  return MEDIA_CACHE_BUCKETS.includes(match[1]);
}

// Origins that must never be cached by the SW (auth, data, payments, logs).
const NETWORK_ONLY_HOSTS = [
  'appwrite.io',
  'appwrite.run',
  'sentry.io',
  'razorpay.com',
  'checkout.razorpay.com',
  'api.razorpay.com',
  'fonts.googleapis.com',
  'fonts.gstatic.com',
  'gstatic.com',
];

function isCanvaskitCdn(url) {
  return (
    (url.hostname === 'www.gstatic.com' || url.hostname === 'gstatic.com') &&
    url.pathname.includes('flutter-canvaskit')
  );
}

function isNetworkOnly(url) {
  if (isCanvaskitCdn(url)) return false;
  if (url.origin !== self.location.origin) {
    // Allow caching same-origin only; third-party goes to network, except
    // the immutable CDN prefixes handled above (fonts use browser cache).
    if (NETWORK_ONLY_HOSTS.some((h) => isTrustedHost(url.hostname, h))) {
      return true;
    }
    return true;
  }
  const path = url.pathname;
  if (path.startsWith('/api/') || path.startsWith('/admin-panel')) return true;
  // Auth callbacks carry one-time secrets — never serve stale.
  if (path === '/auth.html') return true;
  return false;
}

function isCacheFirstAsset(pathname) {
  return CACHE_FIRST_PREFIXES.some((p) => pathname.startsWith(p));
}

function isAppShellScript(pathname) {
  return (
    pathname === '/flutter_bootstrap.js' ||
    pathname === '/main.dart.js' ||
    pathname === '/flutter.js' ||
    pathname === '/pwa_runtime.js' ||
    pathname === '/pwa_install.js'
  );
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(STATIC_CACHE);
      // `cache: reload` bypasses the HTTP cache so a new SW always snapshots
      // the fresh shell instead of re-caching a 304 / stale copy.
      await Promise.allSettled(
        APP_SHELL.map((url) =>
          cache.add(new Request(url, { cache: 'reload' })),
        ),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys.map((key) => {
          if (
            key !== STATIC_CACHE &&
            key !== RUNTIME_CACHE &&
            key !== MEDIA_CACHE
          ) {
            return caches.delete(key);
          }
          return Promise.resolve(false);
        }),
      );
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('message', (event) => {
  if (!event.data || event.data.action !== 'skipWaiting') return;
  // Only same-origin controlled pages may drive activation: the sender must
  // be a window client of this registration (service workers can only ever
  // control same-origin pages, so this rejects foreign MessagePorts).
  if (event.source instanceof Client) {
    self.skipWaiting();
  }
});

async function networkFirstNavigation(request) {
  const cache = await caches.open(STATIC_CACHE);
  try {
    const network = await fetch(request);
    // Cache a fresh copy of the document for the next offline launch.
    // Only cache successful basic responses to avoid poisoning the shell.
    if (network && network.ok) {
      const copy = network.clone();
      // Normalize every navigation to the canonical shell entry so
      // "/?source=pwa" and "/#/bakhed" all resolve offline.
      cache.put('/index.html', copy).catch(() => {});
      cache.put('/', network.clone()).catch(() => {});
    }
    return network;
  } catch (_) {
    // Offline — try the cached shell in order of preference.
    // ignoreSearch: true ensures launched shortcuts and queries (e.g. /?source=pwa) resolve.
    const cached =
      (await cache.match(request, { ignoreSearch: true })) ||
      (await cache.match('/index.html', { ignoreSearch: true })) ||
      (await cache.match('/', { ignoreSearch: true }));
    if (cached) return cached;

    // Next resort: runtime cache
    const runtime = await caches.open(RUNTIME_CACHE);
    const runtimeCached =
      (await runtime.match(request, { ignoreSearch: true })) ||
      (await runtime.match('/index.html', { ignoreSearch: true })) ||
      (await runtime.match('/', { ignoreSearch: true }));
    if (runtimeCached) return runtimeCached;

    return (await cache.match('/offline.html')) || Response.error();
  }
}

async function networkFirstWithCacheFallback(request, cacheName) {
  const cache = await caches.open(cacheName);
  try {
    const network = await fetch(request);
    if (network && network.ok) {
      cache.put(request, network.clone()).catch(() => {});
    }
    return network;
  } catch (_) {
    let pathname = '';
    try {
      pathname = new URL(request.url).pathname;
    } catch (_) {}
    const cached =
      (await cache.match(request, { ignoreSearch: true })) ||
      (pathname && (await cache.match(pathname, { ignoreSearch: true })));
    if (cached) return cached;
    // Bootstrap / engine must never 404 offline if the precache missed.
    const shell = await caches.open(STATIC_CACHE);
    return (
      (await shell.match(request, { ignoreSearch: true })) ||
      (pathname && (await shell.match(pathname, { ignoreSearch: true }))) ||
      Response.error()
    );
  }
}

function isResponseCacheableArtwork(res) {
  if (!res) return false;
  // <img> requests are no-cors, so responses are opaque with no readable
  // headers. Bucket allowlisting in isCacheableAppwriteMedia is the safety
  // boundary there; when headers ARE readable, verify artwork type + size.
  if (res.type === 'opaque') return true;
  if (!res.ok) return false;
  const contentType = (res.headers.get('content-type') || '').toLowerCase();
  const isArtwork =
    contentType.startsWith('image/') ||
    contentType.includes('json') ||
    contentType.includes('svg');
  if (!isArtwork) return false;
  const length = parseInt(res.headers.get('content-length') || '', 10);
  if (Number.isFinite(length) && length > 10 * 1024 * 1024) return false;
  return true;
}

async function trimMediaCache(cache) {
  try {
    const keys = await cache.keys();
    if (keys.length > MEDIA_CACHE_MAX_ENTRIES) {
      const overflow = keys.slice(0, keys.length - MEDIA_CACHE_TRIM_TO);
      await Promise.all(overflow.map((key) => cache.delete(key)));
    }
  } catch (_) {}
}

// Cache-first with background revalidation: thumbnails render instantly from
// disk on repeat visits and stay available fully offline, while replaced CMS
// artwork still refreshes silently underneath.
async function cacheFirstAppwriteMedia(event) {
  const { request } = event;
  const cache = await caches.open(MEDIA_CACHE);
  const cached = await cache.match(request);
  if (cached) {
    event.waitUntil(
      fetch(request)
        .then((res) => {
          if (isResponseCacheableArtwork(res)) {
            return cache
              .put(request, res.clone())
              .then(() => trimMediaCache(cache))
              .catch(() => {});
          }
        })
        .catch(() => {}),
    );
    return cached;
  }
  const network = await fetch(request);
  if (isResponseCacheableArtwork(network)) {
    event.waitUntil(
      cache
        .put(request, network.clone())
        .then(() => trimMediaCache(cache))
        .catch(() => {}),
    );
  }
  return network;
}

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  let url;
  try {
    url = new URL(request.url);
  } catch (_) {
    return;
  }

  // Appwrite artwork (Bakhed thumbnails, lesson covers, banners): cacheable
  // images bypass the network-only rule below. Paid/lease media never
  // matches isCacheableAppwriteMedia, so entitlement stays server-side.
  if (isCacheableAppwriteMedia(url, request)) {
    event.respondWith(
      cacheFirstAppwriteMedia(event).catch(() => Response.error()),
    );
    return;
  }

  // CanvasKit CDN fallback: if Flutter was loaded from gstatic, intercept it,
  // serve cache-first, and fall back to the bundled local CanvasKit offline.
  if (isCanvaskitCdn(url)) {
    event.respondWith(
      (async () => {
        const runtime = await caches.open(RUNTIME_CACHE);
        const cached = await runtime.match(request);
        if (cached) return cached;
        try {
          const network = await fetch(request);
          if (network && (network.ok || network.type === 'opaque')) {
            runtime.put(request, network.clone()).catch(() => {});
          }
          return network;
        } catch (_) {
          const staticCache = await caches.open(STATIC_CACHE);
          const filename = url.pathname.split('/').pop();
          if (filename) {
            const localFallback =
              (await staticCache.match(`/canvaskit/${filename}`)) ||
              (await staticCache.match(`/canvaskit/chromium/${filename}`)) ||
              (await staticCache.match(`/canvaskit/webparagraph/${filename}`));
            if (localFallback) return localFallback;
          }
          return Response.error();
        }
      })(),
    );
    return;
  }

  if (isNetworkOnly(url)) return;

  // Navigations: includes "/", "/?source=pwa", "/?shortcut=learn",
  // "/#/bakhed", "/#/profile" (hash is not sent, path is "/").
  if (request.mode === 'navigate') {
    event.respondWith(networkFirstNavigation(request));
    return;
  }

  const pathname = url.pathname;

  if (isAppShellScript(pathname)) {
    event.respondWith(networkFirstWithCacheFallback(request, STATIC_CACHE));
    return;
  }

  if (isCacheFirstAsset(pathname)) {
    event.respondWith(
      (async () => {
        const staticCache = await caches.open(STATIC_CACHE);
        const runtimeCache = await caches.open(RUNTIME_CACHE);
        const cached =
          (await runtimeCache.match(request, { ignoreSearch: true })) ||
          (await staticCache.match(request, { ignoreSearch: true })) ||
          (await staticCache.match(pathname, { ignoreSearch: true }));
        if (cached) {
          event.waitUntil(
            fetch(request)
              .then((res) => {
                if (res && res.ok) runtimeCache.put(request, res).catch(() => {});
              })
              .catch(() => {}),
          );
          return cached;
        }
        try {
          const network = await fetch(request);
          if (network && network.ok) {
            runtimeCache.put(request, network.clone()).catch(() => {});
          }
          return network;
        } catch (_) {
          // Assets missing offline: fall back to the static precache copy.
          return (
            (await staticCache.match(request, { ignoreSearch: true })) ||
            (await staticCache.match(pathname, { ignoreSearch: true })) ||
            Response.error()
          );
        }
      })(),
    );
    return;
  }

  // Default for same-origin GET (version.json, build-info.json, etc.):
  // network-first, cache fallback.
  event.respondWith(networkFirstWithCacheFallback(request, RUNTIME_CACHE));
});
