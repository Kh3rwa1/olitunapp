#!/usr/bin/env python3
"""One-shot, exact-match patch; used only on the isolated review branch."""
from pathlib import Path
import json

changed = set()
def edit(path, old, new, count=1):
    p = Path(path)
    text = p.read_text()
    actual = text.count(old)
    if actual != count:
        raise RuntimeError(f'{path}: expected {count} matches, got {actual}: {old[:90]!r}')
    p.write_text(text.replace(old, new))
    changed.add(path)

def write(path, content):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    changed.add(path)

# 1. Consent: eligibility is fail-closed and checked at every SDK request boundary.
p = 'lib/core/ads/consent_manager.dart'
edit(p, '  final SharedPreferences? _prefs;', '''  final SharedPreferences? _prefs;
  final ValueNotifier<bool> adsAllowed = ValueNotifier(false);
  bool get requestsAllowed => adsAllowed.value;''')
edit(p, '          await _saveConsentStatus(status);', '          await canRequestAds();\n          await _saveConsentStatus(status);')
edit(p, '        await _saveConsentStatus(status);', '        await canRequestAds();\n        await _saveConsentStatus(status);', count=2)
edit(p, '      (FormError error) {', '      (FormError error) {\n        adsAllowed.value = false;')
edit(p, '      if (formError != null) {', '      if (formError != null) {\n        adsAllowed.value = false;')
edit(p, "          AppLogger.debug('ConsentManager: Failed to read consent status: $e');", "          adsAllowed.value = false;\n          AppLogger.debug('ConsentManager: Failed to read consent status: $e');")
edit(p, '    if (kIsWeb) return false;\n    try {\n      return await ConsentInformation.instance.canRequestAds();\n    } catch (_) {\n      // UMP unavailable (e.g. before initialisation) — do not block ad\n      // serving; consent enforcement still happens at form level.\n      return true;\n    }', '''    if (kIsWeb) return false;
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      final allowed =
          (status == ConsentStatus.obtained || status == ConsentStatus.notRequired) &&
          await ConsentInformation.instance.canRequestAds();
      adsAllowed.value = allowed;
      return allowed;
    } catch (_) {
      adsAllowed.value = false;
      return false;
    }''')
edit(p, '  Future<void> reset() async {\n    if (kIsWeb) return;', '  Future<void> reset() async {\n    adsAllowed.value = false;\n    if (kIsWeb) return;')
p = 'lib/core/ads/ad_service.dart'
edit(p, '  bool get isInitialized => _isInitialized;', '''  bool get isInitialized => _isInitialized;
  bool get canServeAds => _isInitialized && consentManager.requestsAllowed;''')
edit(p, '    if (kIsWeb) return null;', '    if (kIsWeb || !canServeAds) return null;', count=2)
for kind in ['Interstitial', 'Rewarded']:
    old = f"    final unitId = AdConfig.{kind.lower()}AdUnitId;"
    edit(p, old, f'''    if (!canServeAds) {{
      return left<AdError, {kind}Ad>(
        AdConsentError('Ad consent is not available.', 'consent_unavailable'),
      );
    }}

{old}''')
p = 'lib/core/ads/ad_state.dart'
edit(p, "import 'ad_service.dart';", "import 'ad_service.dart';") if "import 'ad_service.dart';" in Path(p).read_text() else edit(p, "import '../logging/app_logger.dart';", "import '../logging/app_logger.dart';\nimport 'ad_service.dart';")
edit(p, '  final ConsentStatus consentStatus;', '  final ConsentStatus consentStatus;\n  final bool consentAllowsAds;')
edit(p, '    this.consentStatus = ConsentStatus.unknown,', '    this.consentStatus = ConsentStatus.unknown,\n    this.consentAllowsAds = false,')
edit(p, 'bool get shouldShowAds => isAdsEnabledGlobally && !isAdFreeUser;', 'bool get shouldShowAds =>\n      consentAllowsAds && isAdsEnabledGlobally && !isAdFreeUser;')
edit(p, '    if (!isAdsEnabledGlobally) return true;\n    if (lastRewardedShownAt == null)', '    if (!isAdsEnabledGlobally) return true;\n    if (!consentAllowsAds) return false;\n    if (lastRewardedShownAt == null)')
edit(p, '    ConsentStatus? consentStatus,', '    ConsentStatus? consentStatus,\n    bool? consentAllowsAds,')
edit(p, '      consentStatus: consentStatus ?? this.consentStatus,', '      consentStatus: consentStatus ?? this.consentStatus,\n      consentAllowsAds: consentAllowsAds ?? this.consentAllowsAds,')
edit(p, '    consentStatus,\n    isAdFreeUser,', '    consentStatus,\n    consentAllowsAds,\n    isAdFreeUser,')
edit(p, '    return const AdState();', '''    final consent = ref.watch(adServiceProvider).consentManager;
    void onConsentChanged() {
      state = state.copyWith(consentAllowsAds: consent.requestsAllowed);
    }
    consent.adsAllowed.addListener(onConsentChanged);
    ref.onDispose(() => consent.adsAllowed.removeListener(onConsentChanged));
    return AdState(consentAllowsAds: consent.requestsAllowed);''')
for name, load, field in [('banner_ad_widget.dart', '_loadAd', '_bannerAd'), ('native_ad_widget.dart', '_loadNativeAd', '_nativeAd')]:
    p = 'lib/core/ads/widgets/' + name
    edit(p, '    final adState = ref.watch(adStateProvider);', f'''    ref.listen<AdState>(adStateProvider, (previous, next) {{
      if (previous?.shouldShowAds != next.shouldShowAds) {{
        WidgetsBinding.instance.addPostFrameCallback((_) {{
          if (!mounted) return;
          if (next.shouldShowAds) {{
            {load}();
          }} else {{
            {field}?.dispose();
            {field} = null;
            setState(() => _isLoaded = false);
          }}
        }});
      }}
    }});
    final adState = ref.watch(adStateProvider);''')
p = 'lib/core/ads/rewarded_ad_manager.dart'
edit(p, 'if (adState.isAdFreeUser || _isLoading || _rewardedAd != null)', 'if (!adState.shouldShowAds || _isLoading || _rewardedAd != null)')
for name, marker, field in [('interstitial_ad_manager.dart', '    final completer = Completer<bool>();', '_interstitialAd'), ('rewarded_ad_manager.dart', '    final completer = Completer<bool>();', '_rewardedAd')]:
    p = 'lib/core/ads/' + name
    edit(p, marker, f'''    if (!await _ref.read(adServiceProvider).consentManager.canRequestAds()) {{
      {field}?.dispose();
      {field} = null;
      return false;
    }}

{marker}''')
    edit(p, '  Future.microtask(manager.preload);', '''  Future.microtask(manager.preload);
  ref.listen<AdState>(adStateProvider, (previous, next) {
    if (next.shouldShowAds && previous?.shouldShowAds != true) {
      Future.microtask(manager.preload);
    } else if (!next.shouldShowAds) {
      manager.dispose();
    }
  });''')
p = 'test/core/ads/ad_state_test.dart'
s = Path(p).read_text().replace('AdState(', 'AdState(consentAllowsAds: true, ')
s = s.replace('const state = AdState(consentAllowsAds: true, );', 'const state = AdState();')
s = s.replace('default state requires ads for free users and allows initial interstitial/rewarded', 'unknown consent fails closed for free users')
s = s.replace('expect(state.shouldShowAds, isTrue);', 'expect(state.shouldShowAds, isFalse);', 1).replace('expect(state.canShowInterstitial(), isTrue);', 'expect(state.canShowInterstitial(), isFalse);', 1).replace('expect(state.canShowRewarded(), isTrue);', 'expect(state.canShowRewarded(), isFalse);', 1)
write(p, s)
write('test/core/ads/consent_fail_closed_test.dart', '''import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/ads/consent_manager.dart';
import 'package:itun/core/ads/ad_state.dart';
import 'package:itun/core/ads/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('missing UMP platform and reset cannot authorize ad requests', () async {
    final consent = ConsentManager();
    expect(consent.requestsAllowed, isFalse);
    expect(await consent.canRequestAds(), isFalse);
    expect(consent.requestsAllowed, isFalse);
    await consent.reset();
    expect(consent.requestsAllowed, isFalse);
    expect(AdService.instance.canServeAds, isFalse);
  });
  test('eligibility changes preserve free rewards without requesting ads', () {
    const initial = AdState();
    expect(initial.shouldShowAds, isFalse);
    final allowed = initial.copyWith(consentAllowsAds: true);
    expect(allowed.shouldShowAds, isTrue);
    expect(allowed.copyWith(consentAllowsAds: false).canShowInterstitial(), isFalse);
    expect(allowed.copyWith(consentAllowsAds: false).canShowRewarded(), isFalse);
    expect(initial.copyWith(isAdFreeUser: true).canShowRewarded(), isTrue);
    expect(allowed.copyWith(isAdsEnabledGlobally: false).shouldShowAds, isFalse);
  });
}
''')

# 2. Offline success means durable queue commit, never best-effort enqueue.
p = 'lib/shared/repositories/content_repository.dart'
edit(p, 'Future<Either<Failure, ContentItem>> upsert(ContentItem item) async {', 'Future<Either<Failure, ContentItem>> upsert(\n    ContentItem item, {bool allowOfflineQueue = true}\n  ) async {')
edit(p, '''      try {
        await CacheService.set(itemCacheKey, item.toJson());
        await CacheService.delete(_cacheListKey(item.kind, item.categoryId));
        await CacheService.delete(_cacheListKey(item.kind, null));
        await _enqueueOfflineMutation(item);''', '''      if (!allowOfflineQueue) {
        return left(const NetworkFailure(message: 'Connection lost during replay.'));
      }
      try {
        // The outbox is authoritative. Cache writes are only an optimistic view.
        await _enqueueOfflineMutation(item);
        await CacheService.set(itemCacheKey, item.toJson());
        await CacheService.delete(_cacheListKey(item.kind, item.categoryId));
        await CacheService.delete(_cacheListKey(item.kind, null));''')
edit(p, '    if (outbox == null) return;', "    if (outbox == null) throw StateError('Durable offline storage unavailable');")
edit(p, '''      // Queueing is best-effort: the local cache already holds the edit.
      AppLogger.debug('[Content] Failed to queue offline mutation: $e');''', '''      AppLogger.debug('[Content] Failed to queue offline mutation: $e');
      rethrow;''')
p = 'lib/shared/offline/content_mutation_replay.dart'
edit(p, "import 'package:connectivity_plus/connectivity_plus.dart';", "import 'dart:async';\nimport 'package:connectivity_plus/connectivity_plus.dart';")
edit(p, '  Future<ReplaySummary> replayPending() async {', '''  Future<ReplaySummary>? _activeReplay;

  Future<ReplaySummary> replayPending() {
    return _activeReplay ??= _replayPending().whenComplete(() {
      _activeReplay = null;
    });
  }

  Future<ReplaySummary> _replayPending() async {''')
edit(p, '      if (mutation.status == MutationStatus.deadLetter) {', '      if (mutation.status == MutationStatus.deadLetter ||\n          mutation.nextRetryAt.isAfter(DateTime.now())) {')
start = Path(p).read_text().index('        result.fold(')
end = Path(p).read_text().index('\n    }\n\n    if (replayed', start)
old = Path(p).read_text()[start:end]
edit(p, old, '''        await result.fold<Future<void>>(
          (failure) async {
            failed++;
            await _outbox.recordAttemptFailed(
              mutation.userId, mutation.operationId, failure.message,
            );
          },
          (_) async {
            await _outbox.markCompleted(mutation.userId, mutation.operationId);
            replayed++;
          },
        );
      } catch (e) {
        failed++;
        await _outbox.recordAttemptFailed(
          mutation.userId, mutation.operationId, e.toString(),
        );
      }''')
edit(p, '    executeUpsert: repo.upsert,', '    executeUpsert: (item) => repo.upsert(item, allowOfflineQueue: false),')
edit(p, '  Future<void>.microtask(safeReplay);', '''  Future<void>.microtask(safeReplay);
  final retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    unawaited(safeReplay());
  });
  ref.onDispose(retryTimer.cancel);''')
p = 'lib/core/offline/mutation_outbox_service.dart'
edit(p, "      AppLogger.debug('Outbox: Failed to record failure for $operationId: $e');", "      AppLogger.debug('Outbox: Failed to record failure for $operationId: $e');\n      rethrow;")

# 3. Entitlement refresh publishes changes; authorization failures never grant stale access.
p = 'lib/core/payments/purchase_repository.dart'
edit(p, 'class PurchaseRepository {', '''final entitlementRevisionProvider = StateProvider.family<int, String>((ref, userId) => 0);

class PurchaseRepository {''')
edit(p, '  PurchaseRepository(this.ref);', '''  PurchaseRepository(this.ref);
  final Set<String> _revokedUsers = {};
  final Map<String, int> _generations = {};
  bool _disposed = false;
  static const offlineEntitlementGrace = Duration(hours: 24);

  void dispose() { _disposed = true; }
  void _notify(String userId) {
    if (!_disposed) ref.read(entitlementRevisionProvider(userId).notifier).state++;
  }''')
edit(p, '    if (cached != null) {', '    if (cached != null && meta != null && !meta.isExpired && !_revokedUsers.contains(userId)) {')
edit(p, '''  ) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);''', '''  ) async {
    final generation = _generations[userId] ?? 0;
    try {
      final db = ref.read(appwriteDbServiceProvider);''')
edit(p, '      // Save user-scoped cache with 5 minute TTL', '''      if (_disposed || generation != (_generations[userId] ?? 0)) {
        return const EntitlementResult(categoryIds: {}, status: EntitlementStatus.unauthenticated);
      }
      _revokedUsers.remove(userId);
      // Save user-scoped cache with 5 minute TTL''')
start = Path(p).read_text().index('      // Attempt to recover stale cache entry if server request fails')
end = Path(p).read_text().index('\n      return const EntitlementResult(\n        categoryIds: {},\n        status: EntitlementStatus.serverError', start)
edit(p, Path(p).read_text()[start:end], '''      if (_disposed || generation != (_generations[userId] ?? 0)) {
        return const EntitlementResult(categoryIds: {}, status: EntitlementStatus.unauthenticated);
      }
      final errorStr = e.toString().toLowerCase();
      final denied = e is appwrite.AppwriteException && (e.code == 401 || e.code == 403) ||
          errorStr.contains('401') || errorStr.contains('403') || errorStr.contains('unauthorized') || errorStr.contains('permission');
      if (denied) {
        final firstDenial = _revokedUsers.add(userId);
        await CacheService.delete(userCacheKey);
        if (firstDenial) _notify(userId);
        return const EntitlementResult(categoryIds: {}, status: EntitlementStatus.permissionDenied,
          sanitizedErrorMessage: 'Access denied to purchase records.');
      }
      final isNetworkFailure = e is TimeoutException ||
          (e is appwrite.AppwriteException && (e.code == 0 || e.type == 'network_failure')) ||
          errorStr.contains('socketexception') || errorStr.contains('network') || errorStr.contains('connection');
      if (isNetworkFailure && !_revokedUsers.contains(userId)) {
        final meta = await CacheService.getMeta(userCacheKey);
        final age = meta == null ? null : DateTime.now().millisecondsSinceEpoch - meta.lastSyncAtMs;
        if (age != null && age >= 0 && age <= offlineEntitlementGrace.inMilliseconds) {
          final stale = await CacheService.getIgnoringTtl(userCacheKey, (json) => Set<String>.from(json['ids'] as List));
          if (stale != null) return EntitlementResult(categoryIds: stale, status: EntitlementStatus.staleCached,
            isFromCache: true, sanitizedErrorMessage: 'Offline access is limited to 24 hours since verification.');
        }
        return const EntitlementResult(categoryIds: {}, status: EntitlementStatus.networkUnavailable,
          sanitizedErrorMessage: 'Reconnect to verify your purchases.');
      }
''')
start = Path(p).read_text().index('  void _triggerRevalidation(')
end = Path(p).read_text().index('  /// Purge user-scoped', start)
edit(p, Path(p).read_text()[start:end], '''  void _triggerRevalidation(String userId, String userCacheKey, Set<String> currentCached) {
    unawaited(Future<void>(() async {
      if (_disposed) return;
      final fresh = await _fetchFromServer(userId, userCacheKey);
      if (_disposed) return;
      if (fresh.status == EntitlementStatus.verified &&
          (fresh.categoryIds.length != currentCached.length || !fresh.categoryIds.containsAll(currentCached))) {
        _notify(userId);
      }
    }));
  }

''')
edit(p, "      await CacheService.delete(_getCacheKey(userId));", "      _generations[userId] = (_generations[userId] ?? 0) + 1;\n      await CacheService.delete(_getCacheKey(userId));\n      _notify(userId);")
edit(p, '  return PurchaseRepository(ref);', '  final repo = PurchaseRepository(ref);\n  ref.onDispose(repo.dispose);\n  return repo;')
p = 'lib/shared/providers/purchases_provider.dart'
edit(p, '  final repo = ref.watch(purchaseRepositoryProvider);', '  ref.watch(entitlementRevisionProvider(user.id));\n  final repo = ref.watch(purchaseRepositoryProvider);')

# 4. One authoritative function deployment list; scheduled privileged jobs are not public RPCs.
a = json.loads(Path('appwrite.json').read_text())
for f in a['functions']:
    if f['$id'] in ['reconcileOrphanedDeletions', 'reconcilePaymentAttempts']:
        f['execute'] = []
    if f['$id'] == 'reconcileOrphanedDeletions':
        f['scopes'] = sorted(set(f['scopes'] + ['users.write']))
b = json.loads(Path('appwrite.config.json').read_text())
b['functions'] = a['functions']
write('appwrite.json', json.dumps(a, indent=2) + '\n')
write('appwrite.config.json', json.dumps(b, indent=2) + '\n')
write('scripts/verify_function_deployment.mjs', '''import fs from 'node:fs';
import assert from 'node:assert/strict';
const read = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const canonical = read('appwrite.json').functions;
assert.deepEqual(read('appwrite.config.json').functions, canonical, 'Function deployment manifests have drifted');
for (const id of ['reconcileOrphanedDeletions', 'reconcilePaymentAttempts']) {
  const fn = canonical.find(f => f.$id === id);
  assert.ok(fn && fn.enabled && fn.schedule, `${id} must be enabled and scheduled`);
  assert.deepEqual(fn.execute, [], `${id} must not be callable by ordinary users`);
  assert.ok(fs.existsSync(`${fn.path}/${fn.entrypoint}`));
  if (id === 'reconcileOrphanedDeletions') {
    for (const scope of ['users.read', 'users.write', 'documents.read', 'documents.write'])
      assert.ok(fn.scopes.includes(scope), `${id} missing ${scope}`);
  }
}
console.log('Function manifests, schedules, execution roles and deletion scopes verified.');
''')
edit('.github/workflows/flutter-ci.yml', '      - name: Verify Node Dependency Alignment', '      - name: Verify function deployment contract\n        run: node scripts/verify_function_deployment.mjs\n      - name: Verify Node Dependency Alignment')

# 5. Accurate smoke-test naming and mandatory live staging evidence before release.
p = 'integration_test/journeys_integration_test.dart'
for old, new in [
 ('Full Application User Journeys Integration Suite', 'Screen rendering smoke suite (not backend E2E)'),
 ('2. Purchase Callback Journey: Handles callback parameters gracefully', '2. Home screen renders with purchase query parameters (no payment verification)'),
 ('3. Offline Restart Journey: Initializing app offline loads cached state', '3. Home screen renders with mock local preferences (no restart simulation)'),
 ('4. Account Deletion Journey: Renders deletion confirmation sheet options', '4. Welcome screen renders (does not exercise account deletion)'),
 ('7. OAuth Callback Sanitization: Strips sensitive query params upon routing', '7. Welcome screen renders with OAuth query parameters (no sanitization assertion)')]:
    edit(p, old, new)
p = '.github/workflows/staging-health.yml'
edit(p, '  workflow_dispatch:', '  workflow_dispatch:\n  workflow_call:')
edit(p, 'jobs:\n', 'permissions:\n  contents: read\n\njobs:\n')
edit(p, '            echo "⚠️ NOTICE: STAGING_APPWRITE_API_KEY is not provisioned in GitHub repository secrets. Live cluster-level concurrency execution is skipped until provisioned."', '            echo "::error::STAGING_APPWRITE_API_KEY is required for live concurrency verification."\n            exit 1')
edit(p, '          APPWRITE_API_KEY: ${{ secrets.APPWRITE_API_KEY }}', '''          APPWRITE_API_KEY: ${{ secrets.STAGING_APPWRITE_API_KEY }}
          APPWRITE_ENDPOINT: ${{ secrets.STAGING_APPWRITE_ENDPOINT }}
          APPWRITE_PROJECT_ID: ${{ secrets.STAGING_APPWRITE_PROJECT_ID }}''')
edit(p, '            echo "ℹ️ OPTIONAL: APPWRITE_API_KEY not configured; skipping optional schema snapshot comparison."\n            exit 0', '            echo "::error::Staging API key is required for schema verification."\n            exit 1')
edit(p, 'Appwrite Schema Drift Detection (Optional Staging Audit)', 'Appwrite Schema Drift Detection (Required Staging Audit)')
p = '.github/workflows/release-checklist.yml'
edit(p, 'jobs:\n', '''jobs:
  staging-acceptance:
    name: Required live staging verification
    uses: ./.github/workflows/staging-health.yml
    secrets: inherit
''')
edit(p, '    needs: env-validation', '    needs: [env-validation, staging-acceptance]')
edit(p, '    needs: [env-validation, build-test, smoke-deploy]', '    needs: [env-validation, staging-acceptance, build-test, smoke-deploy]')
edit(p, "      needs.env-validation.result == 'success' &&", "      needs.env-validation.result == 'success' &&\n      needs.staging-acceptance.result == 'success' &&")

# 6. Free public translation with distributed resource budgets, kill switch and circuit breaker.
write('functions/translator/src/resource_budget.js', '''import { enforceWindowRateLimit } from './shared/rate_limiter.js';

export function positiveLimit(value, fallback) {
  if (value === undefined || value === '') return fallback;
  if (!/^\\d+$/.test(String(value))) throw new Error('Invalid translation resource limit');
  const n = Number(value);
  if (!Number.isSafeInteger(n) || n < 1 || n > 500) throw new Error('Translation resource limit must be 1..500');
  return n;
}

export function createTranslationBudget({ reserve = enforceWindowRateLimit, now = Date.now, env = process.env } = {}) {
  let failures = 0;
  let openUntil = 0;
  return {
    async acquire(databases, { upstream = false } = {}) {
      if (env.TRANSLATION_ENABLED === 'false') return { allowed: false, reason: 'disabled', retryAfterSeconds: 60 };
      if (upstream && now() < openUntil) return { allowed: false, reason: 'circuit_open', retryAfterSeconds: Math.ceil((openUntil - now()) / 1000) };
      let limit;
      try { limit = positiveLimit(upstream ? env.TRANSLATION_UPSTREAM_PER_MINUTE : env.TRANSLATION_REQUESTS_PER_MINUTE, upstream ? 30 : 120); }
      catch { return { allowed: false, reason: 'configuration_error', retryAfterSeconds: 60 }; }
      const result = await reserve({ databases, dbId: 'olitun_db', collectionId: 'rate_limits',
        identifier: upstream ? 'translation_upstream_global_v1' : 'translation_requests_global_v1',
        windowType: 'm', windowMs: 60000, limit, now: now() });
      return result;
    },
    failed() { if (++failures >= 5) openUntil = now() + 30000; },
    succeeded() { failures = 0; openUntil = 0; },
  };
}
''')
p = 'functions/translator/src/main.js'
edit(p, "import { getTranslationProvider } from './providers/translation_provider.js';", "import { getTranslationProvider } from './providers/translation_provider.js';\nimport { createTranslationBudget } from './resource_budget.js';\nconst resourceBudget = createTranslationBudget();")
edit(p, '// Translation is a free, unlimited service: identity verification and rate\n// limiting were intentionally removed (see README + SECURITY.md §C).', '// Translation remains free and public. Distributed budgets bound resource use.\n// Limits apply per deployment, not a subscription or payment tier.')
edit(p, '  const startTime = Date.now();', '''  const startTime = Date.now();
  if (process.env.TRANSLATION_ENABLED === 'false') {
    return res.json(err('Translation is temporarily unavailable', 'SERVICE_PAUSED', 60), 503);
  }''')
edit(p, '  const db = new Databases(client);', '''  const db = new Databases(client);
  const requestBudget = await resourceBudget.acquire(db);
  if (!requestBudget.allowed) {
    log(JSON.stringify({ event: 'translation_budget_rejected', stage: 'request', reason: requestBudget.reason }));
    const unavailable = requestBudget.reason === 'rate_limit_storage_error' || requestBudget.reason === 'configuration_error';
    return res.json(err('Translation is busy. Please try again shortly.', 'RESOURCE_LIMIT', requestBudget.retryAfterSeconds || 60), unavailable ? 503 : 429);
  }''')
edit(p, '  const provider = getTranslationProvider();', '''  const upstreamBudget = await resourceBudget.acquire(db, { upstream: true });
  if (!upstreamBudget.allowed) {
    log(JSON.stringify({ event: 'translation_budget_rejected', stage: 'upstream', reason: upstreamBudget.reason }));
    return res.json(err('Translation is temporarily busy. Please retry.', 'UPSTREAM_RESOURCE_LIMIT', upstreamBudget.retryAfterSeconds || 60), 503);
  }
  if (upstreamBudget.remaining <= 5) {
    log(JSON.stringify({ event: 'translation_budget_low', remaining: upstreamBudget.remaining }));
  }
  const provider = getTranslationProvider();''')
edit(p, '    const translatedText = translationResult.text;', '    resourceBudget.succeeded();\n    const translatedText = translationResult.text;')
edit(p, '  } catch (upstreamErr) {', '  } catch (upstreamErr) {\n    resourceBudget.failed();')
write('functions/translator/test/resource_budget.test.js', '''import test from 'node:test';
import assert from 'node:assert/strict';
import { createTranslationBudget, positiveLimit } from '../src/resource_budget.js';

test('resource configuration rejects invalid and unbounded values', () => {
  for (const n of ['0', '-1', 'NaN', '12x', '501', '1.5']) assert.throws(() => positiveLimit(n, 30));
  assert.equal(positiveLimit(undefined, 30), 30);
  assert.equal(positiveLimit('42', 30), 42);
});
test('disabled service never reserves a slot', async () => {
  const budget = createTranslationBudget({ env: { TRANSLATION_ENABLED: 'false' }, reserve: () => assert.fail('called storage') });
  assert.equal((await budget.acquire({})).allowed, false);
});
test('request and upstream budgets use independent global identities', async () => {
  const calls = [];
  const budget = createTranslationBudget({ env: {}, reserve: async args => { calls.push(args); return { allowed: true }; } });
  await budget.acquire({}); await budget.acquire({}, { upstream: true });
  assert.notEqual(calls[0].identifier, calls[1].identifier);
  assert.equal(calls[0].limit, 120); assert.equal(calls[1].limit, 30);
});
test('storage outage fails closed and repeated failures open the circuit', async () => {
  let time = 1000;
  let reservations = 0;
  const budget = createTranslationBudget({ env: {}, now: () => time, reserve: async () => { reservations++; return { allowed: false, reason: 'rate_limit_storage_error' }; } });
  assert.equal((await budget.acquire({})).allowed, false);
  for (let i = 0; i < 5; i++) budget.failed();
  assert.equal((await budget.acquire({}, { upstream: true })).reason, 'circuit_open');
  assert.equal(reservations, 1);
  time += 30001;
  await budget.acquire({}, { upstream: true });
  assert.equal(reservations, 2);
});
''')

write('docs/PRIORITY_HARDENING_2026_09_05.md', '''# Priority hardening: code and evidence boundaries

## Changes
- Ad SDK requests require positively established UMP eligibility. Errors and unknown consent fail closed; changing eligibility updates visible placements.
- Offline content saves commit the durable outbox before returning success. Replay is single-flight, awaits bookkeeping, respects retry times, and cannot acknowledge a re-queued offline operation as a remote success.
- Entitlement refresh notifies active consumers. Authorization failures clear access; network-only offline grace is bounded to 24 hours since last verification. This is an explicit policy limit, not DRM.
- appwrite.json is authoritative for function deployment entries. CI requires matching entries in appwrite.config.json, scheduled recovery jobs are not user-callable, and deletion recovery has users.write.
- Screen-only tests are labelled smoke tests. The release workflow requires live staging checks; missing credentials are failures, never evidence of a successful backend check.
- Translation remains free/public. Defaults are 120 incoming requests/minute and 30 uncached upstream calls/minute per deployment, configurable within 1..500. A local circuit opens after five upstream failures for 30 seconds. The distributed budget remains authoritative across replicas. TRANSLATION_ENABLED=false pauses translation. Cache hits consume only the request budget.

## Operator setup before release
1. Deploy the function manifest and compare live scopes/schedules. This PR does not change production.
2. Configure STAGING_APPWRITE_ENDPOINT, STAGING_APPWRITE_PROJECT_ID and STAGING_APPWRITE_API_KEY in GitHub connection settings/secrets, not chat. Use a dedicated non-production project and its matching schema snapshot.
3. Provision translator rate_limits access and retention cleanup, then deploy translator. Alert on translation_budget_rejected, translation_budget_low, upstream failures and Appwrite billing. Rate budgets are not monetary spend measurements; external billing alerts remain operator-owned.
4. Run payment capture/refund and deletion/recovery with disposable staging users and Razorpay test mode; retain evidence for this exact commit. No live payment or destructive staging journey was run by the patch author.
5. Exercise offline process restart/reconnect and consent-required/error states on Android and iOS. Unit tests and rendering smoke tests are not substitutes for real-device E2E evidence.

## Rollback
Revert the code commit and redeploy the previous function version if needed. Do not remove users.write from active recovery jobs until their behavior no longer needs it. Translation can be paused independently with the kill switch.
''')
p = 'SECURITY.md'
s = Path(p).read_text()
s = s.replace('**translation is a free, unlimited service** — identity verification and rate limiting were intentionally removed (product decision).', '**translation is free and public**, with deployment-wide request/upstream budgets and a fail-closed resource guard.')
s = s.replace('abuse protection is the cache plus Appwrite\'s per-function execution concurrency.', 'resource safeguards are described in docs/PRIORITY_HARDENING_2026_09_05.md.')
start = s.index('### C. Translator Service Model')
end = s.index('### D.', start)
s = s[:start] + '''### C. Translator Service Model
- Free public access does not imply unbounded infrastructure use. Distributed minute budgets reserve atomic Appwrite slots before requests/upstream work.
- Cache hits avoid the upstream budget. Configuration/storage failures fail closed; responses identify temporary saturation without logging submitted text.
- Five consecutive upstream failures open a per-instance 30-second circuit; deployment-wide budgets still bound aggregate work.
- Operators can pause translation with TRANSLATION_ENABLED=false and should alert on budget events and billing. See docs/PRIORITY_HARDENING_2026_09_05.md.

''' + s[end:]
write(p, s)
Path('/tmp/priority_changed_paths.json').write_text(json.dumps(sorted(changed)))
print('Applied priority hardening to', len(changed), 'files')
