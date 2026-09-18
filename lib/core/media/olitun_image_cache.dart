import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Shared image cache for all remote lesson / Bakhed / cover artwork.
///
/// The default `DefaultCacheManager` keeps only 200 objects for 30 days, so
/// Bakhed thumbnails and lesson covers were evicted within weeks on native —
/// and on web `flutter_cache_manager` is memory-only, so PWA thumbnails
/// vanished on every reload (the service worker in `web/sw.js` mirrors these
/// same Appwrite image responses for true offline).
///
/// This manager keeps up to 1000 images for 90 days on native disk. Pass it
/// as `cacheManager:` to every `CachedNetworkImage` showing CMS artwork.
final CacheManager olitunImageCacheManager = CacheManager(
  Config(
    'olitunImages',
    stalePeriod: const Duration(days: 90),
    maxNrOfCacheObjects: 1000,
  ),
);
