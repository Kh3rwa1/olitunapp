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

const SW_VERSION = '1.3.1-30';
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
  '/flutter_bootstrap.js',
  '/flutter.js',
  '/main.dart.js',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
  '/icons/apple-touch-icon.png',
];

// Prefixes that are safe to cache long-term (immutable-ish build output).
const CACHE_FIRST_PREFIXES = [
  '/assets/',
  '/canvaskit/',
  '/icons/',
  '/screenshots/',
];

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
  const host = url.hostname;
  if (!host.endsWith('appwrite.io') && !host.endsWith('appwrite.run')) {
    return false;
  }
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

function isNetworkOnly(url) {
  if (url.origin !== self.location.origin) {
    // Allow caching same-origin only; third-party goes to network, except
    // the immutable CDN prefixes handled above (fonts use browser cache).
    if (NETWORK_ONLY_HOSTS.some((h) => url.hostname.endsWith(h))) return true;
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
    pathname === '/flutter.js'
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
  if (event.data && event.data.action === 'skipWaiting') {
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
    const cached =
      (await cache.match('/index.html')) ||
      (await cache.match('/')) ||
      (await cache.match('/offline.html'));
    if (cached) return cached;
    // Last resort: any cached runtime document.
    const runtime = await caches.open(RUNTIME_CACHE);
    return (
      (await runtime.match('/index.html')) ||
      Response.error()
    );
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
    const cached = await cache.match(request);
    if (cached) return cached;
    // Bootstrap / engine must never 404 offline if the precache missed.
    const shell = await caches.open(STATIC_CACHE);
    return (await shell.match(request)) || Response.error();
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
        const cache = await caches.open(RUNTIME_CACHE);
        const cached = await cache.match(request);
        if (cached) {
          event.waitUntil(
            fetch(request)
              .then((res) => {
                if (res && res.ok) cache.put(request, res).catch(() => {});
              })
              .catch(() => {}),
          );
          return cached;
        }
        try {
          const network = await fetch(request);
          if (network && network.ok) {
            cache.put(request, network.clone()).catch(() => {});
          }
          return network;
        } catch (_) {
          // Assets missing offline: fall back to the static precache copy.
          const shell = await caches.open(STATIC_CACHE);
          return (await shell.match(request)) || Response.error();
        }
      })(),
    );
    return;
  }

  // Default for same-origin GET (version.json, build-info.json, etc.):
  // network-first, cache fallback.
  event.respondWith(networkFirstWithCacheFallback(request, RUNTIME_CACHE));
});
