from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, value: str) -> None:
    (ROOT / path).write_text(value, encoding="utf-8")


def replace_once(path: str, old: str, new: str) -> None:
    value = read(path)
    count = value.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected one anchor, found {count}: {old[:80]!r}")
    write(path, value.replace(old, new, 1))


def replace_all(path: str, old: str, new: str, expected: int) -> None:
    value = read(path)
    count = value.count(old)
    if count != expected:
        raise RuntimeError(f"{path}: expected {expected} anchors, found {count}: {old[:80]!r}")
    write(path, value.replace(old, new))


def splice(path: str, start_anchor: str, end_anchor: str, replacement: str) -> None:
    value = read(path)
    start = value.find(start_anchor)
    end = value.find(end_anchor, start)
    if start < 0 or end < 0 or value.find(start_anchor, start + 1) >= 0:
        raise RuntimeError(f"{path}: could not uniquely splice {start_anchor!r}")
    write(path, value[:start] + replacement + value[end:])


repo = "lib/shared/repositories/content_repository.dart"
replace_once(
    repo,
    """  String _cacheItemKey(ContentKind kind, String id) {
    return 'content_item_${kind.name}_$id';
  }

""",
    """  String _cacheItemKey(ContentKind kind, String id) {
    return 'content_item_${kind.name}_$id';
  }

  String _administrationCacheItemKey(ContentKind kind, String id) {
    if (kind == ContentKind.lesson) {
      return 'content_admin_item_${kind.name}_$id';
    }
    return _cacheItemKey(kind, id);
  }

  Future<void> _cacheAdministrationItem(ContentItem item) async {
    await CacheService.set(
      _administrationCacheItemKey(item.kind, item.id),
      item.toJson(),
    );
    if (item.kind == ContentKind.lesson) {
      // Remove the pre-cutover body cache. Learner reads never consult either
      // item cache, but deleting the legacy key prevents accidental reuse.
      await CacheService.delete(_cacheItemKey(item.kind, item.id));
    }
  }

""",
)
replace_once(
    repo,
    "    normalized['isPremium'] = normalized['isLocked'] == true;\n",
    "    normalized['isPremium'] = normalized['isPremium'] == true;\n",
)
replace_once(
    repo,
    """        final lessonMap = Map<String, dynamic>.from(data['lesson'] as Map);
        final lessonId = lessonMap['id'];
""",
    """        final lessonMap = Map<String, dynamic>.from(data['lesson'] as Map);
        lessonMap['isLocked'] ??= data['locked'] == true;
        lessonMap['accessReason'] ??= data['accessReason'] ?? data['reason'];
        final lessonId = lessonMap['id'];
""",
)
replace_once(
    repo,
    """        final mergedItems = _mergeContentItems(bundledItems, remoteItems);
        final cachedData = mergedItems.map((item) => item.toJson()).toList();
        await CacheService.set(cacheKey, cachedData);

        for (final item in mergedItems) {
          await CacheService.set(_cacheItemKey(kind, item.id), item.toJson());
        }

        return right(mergedItems);
""",
    """        final mergedItems = _mergeContentItems(bundledItems, remoteItems);
        if (kind != ContentKind.lesson) {
          final cachedData = mergedItems.map((item) => item.toJson()).toList();
          await CacheService.set(cacheKey, cachedData);
          for (final item in mergedItems) {
            await CacheService.set(_cacheItemKey(kind, item.id), item.toJson());
          }
        }

        return right(mergedItems);
""",
)
splice(
    repo,
    "  Future<Either<Failure, List<ContentItem>>> _getCachedList(\n",
    "  /// Gets a single content item by ID.\n",
    """  Future<Either<Failure, List<ContentItem>>> _getCachedList(
    ContentKind kind,
    String? categoryId, {
    List<ContentItem>? fallback,
  }) async {
    try {
      final bundled = fallback ?? await _loadBundledSeedItems(kind, categoryId);

      if (kind == ContentKind.lesson) {
        // Legacy lesson caches were account-agnostic and could contain paid
        // bodies or another account's lock decision. Bundled assets are part
        // of the application binary and therefore already public; they are the
        // only safe offline lesson fallback.
        if (bundled.isNotEmpty) return right(bundled);
        return left(
          const CacheFailure(
            message: 'No safely bundled lesson content is available offline.',
          ),
        );
      }

      final cached = await CacheService.getList<ContentItem>(
        _cacheListKey(kind, categoryId),
        (data) => ContentItem.fromJson(data, null, kind),
      );
      if (cached != null && cached.isNotEmpty) {
        return right(_mergeContentItems(bundled, cached));
      }
      if (bundled.isNotEmpty) return right(bundled);
      return left(
        CacheFailure(message: 'No offline content available for ${kind.name}.'),
      );
    } catch (e) {
      final bundled = fallback ?? await _loadBundledSeedItems(kind, categoryId);
      if (bundled.isNotEmpty) return right(bundled);
      return left(
        CacheFailure(
          message: 'Offline content unavailable for ${kind.name}: $e',
        ),
      );
    }
  }

""",
)
replace_once(
    repo,
    """    final collectionId = _getCollectionId(kind);
    final cacheKey = _cacheItemKey(kind, id);

    if (await _networkInfo.isConnected) {
""",
    """    final collectionId = _getCollectionId(kind);

    if (await _networkInfo.isConnected) {
""",
)
replace_once(
    repo,
    """        final item = ContentItem.fromJson(doc.data, doc.$id, kind);
        await CacheService.set(cacheKey, item.toJson());

        return right(item);
""",
    """        final item = ContentItem.fromJson(doc.data, doc.$id, kind);
        await _cacheAdministrationItem(item);

        return right(item);
""",
)
replace_once(
    repo,
    "      final cacheKey = _cacheItemKey(kind, id);\n",
    "      final cacheKey = _administrationCacheItemKey(kind, id);\n",
)
replace_once(
    repo,
    """    final collectionId = _getCollectionId(item.kind);
    final itemCacheKey = _cacheItemKey(item.kind, item.id);

    if (await _networkInfo.isConnected) {
""",
    """    final collectionId = _getCollectionId(item.kind);

    if (await _networkInfo.isConnected) {
""",
)
replace_once(
    repo,
    "        await CacheService.set(itemCacheKey, resultItem.toJson());\n",
    "        await _cacheAdministrationItem(resultItem);\n",
)
replace_once(
    repo,
    "        await CacheService.set(itemCacheKey, item.toJson());\n",
    "        await _cacheAdministrationItem(item);\n",
)
replace_once(
    repo,
    "    final itemCacheKey = _cacheItemKey(kind, id);\n",
    "    final itemCacheKey = _administrationCacheItemKey(kind, id);\n",
)
replace_once(
    repo,
    """        await CacheService.delete(itemCacheKey);
        if (categoryId != null) {
""",
    """        await CacheService.delete(itemCacheKey);
        if (kind == ContentKind.lesson) {
          await CacheService.delete(_cacheItemKey(kind, id));
        }
        if (categoryId != null) {
""",
)

serialization = "lib/shared/models/content_item/content_item_serialization.dart"
replace_once(
    serialization,
    "      isPreview: json['isPreview'] as bool? ?? false,\n",
    "      isPreview:\n          json['isPreview'] as bool? ?? json['is_preview'] as bool? ?? false,\n",
)
replace_once(
    serialization,
    "      difficulty: json['difficulty'] as String?,\n",
    """      difficulty:
          json['difficulty'] as String? ??
          (parsedKind == ContentKind.lesson ? json['level'] as String? : null),
""",
)
replace_once(serialization, "          'level': 'beginner',\n", "          'level': item.difficulty ?? 'beginner',\n")

setup = "scripts/appwrite_setup.mjs"
replace_once(
    setup,
    """      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'integer', key: 'estimatedMinutes', required: false, default: 5 },
""",
    """      { type: 'boolean', key: 'isActive', required: false, default: true },
      { type: 'boolean', key: 'isPreview', required: false, default: false },
      { type: 'integer', key: 'estimatedMinutes', required: false, default: 5 },
""",
)
replace_once(
    "database/schema.sql",
    """  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `estimated_minutes` int(11) DEFAULT 5,
""",
    """  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `is_preview` tinyint(1) NOT NULL DEFAULT 0,
  `estimated_minutes` int(11) DEFAULT 5,
""",
)

main_js = "functions/getAuthorizedLesson/src/main.js"
replace_once(
    main_js,
    """    const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
    const paidMediaBucketId = process.env.PAID_MEDIA_BUCKET_ID || 'paid_media';
""",
    """    const databaseId = process.env.APPWRITE_DATABASE_ID || 'olitun_db';
    const lessonsCollectionId = process.env.LESSONS_COLLECTION_ID || 'lessons';
    const purchasesCollectionId =
      process.env.COURSE_PURCHASES_COLLECTION_ID || 'course_purchases';
    const paidMediaBucketId = process.env.PAID_MEDIA_BUCKET_ID || 'paid_media';
""",
)
replace_once(
    main_js,
    """          callerUserId,
          body,
          evaluateAccess: evaluateLessonAccess,
""",
    """          callerUserId,
          body,
          lessonsCollectionId,
          purchasesCollectionId,
          evaluateAccess: evaluateLessonAccess,
""",
)
replace_once(
    main_js,
    "lessonDoc = await databases.getDocument(databaseId, 'lessons', lessonId);",
    "lessonDoc = await databases.getDocument(databaseId, lessonsCollectionId, lessonId);",
)
replace_once(
    main_js,
    """        const purchaseResult = await databases.listDocuments(databaseId, 'course_purchases', [
""",
    """        const purchaseResult = await databases.listDocuments(databaseId, purchasesCollectionId, [
""",
)
replace_all(
    main_js,
    "          isLocked: true,\n",
    "          isLocked: true,\n          accessReason: accessDecision.reason,\n",
    1,
)
replace_all(
    main_js,
    "        isLocked: false,\n",
    "        isLocked: false,\n        accessReason: accessDecision.reason,\n",
    1,
)

listing = "functions/getAuthorizedLesson/src/list-lessons.js"
replace_once(
    listing,
    """async function loadPurchasesByCategory({ databases, databaseId, callerUserId }) {
""",
    """async function loadPurchasesByCategory({
  databases,
  databaseId,
  callerUserId,
  purchasesCollectionId,
}) {
""",
)
replace_once(
    listing,
    "    collectionId: 'course_purchases',\n",
    "    collectionId: purchasesCollectionId,\n",
)
replace_once(
    listing,
    """  body,
  evaluateAccess,
  onEntitlementError = () => {},
}) {
""",
    """  body,
  lessonsCollectionId = 'lessons',
  purchasesCollectionId = 'course_purchases',
  evaluateAccess,
  onEntitlementError = () => {},
}) {
""",
)
replace_once(
    listing,
    "    databases.listDocuments(databaseId, 'lessons', queries),\n",
    "    databases.listDocuments(databaseId, lessonsCollectionId, queries),\n",
)
replace_once(
    listing,
    """        callerUserId,
      });
""",
    """        callerUserId,
        purchasesCollectionId,
      });
""",
)

test_path = "test/shared/repositories/content_repository_authorized_lesson_test.dart"
test_value = read(test_path)
insert = r'''

  test('authorized lesson metadata is never persisted in legacy caches', () async {
    when(
      () => functions.execute(
        'getAuthorizedLesson',
        body: {
          'action': 'list_lessons',
          'limit': 100,
          'categoryId': 'cat_secure_remote_only',
        },
        usePost: true,
      ),
    ).thenAnswer(
      (_) async => _execution({
        'ok': true,
        'lessons': [_lessonMetadata(locked: false)],
        'hasMore': false,
        'nextCursor': null,
      }),
    );
    final repository = ContentRepository(
      databases: databases,
      networkInfo: _OnlineNetworkInfo(),
      functionsService: functions,
    );

    final result = await repository.list(
      ContentKind.lesson,
      categoryId: 'cat_secure_remote_only',
    );
    expect(result.isRight(), isTrue);
    final cached = await CacheService.getList<ContentItem>(
      'content_list_lesson_cat_secure_remote_only',
      (data) => ContentItem.fromJson(data, null, ContentKind.lesson),
    );
    expect(cached, isNull);
    expect(
      await CacheService.get<ContentItem>(
        'content_item_lesson_secure_shared_lesson',
        (data) => ContentItem.fromJson(data, null, ContentKind.lesson),
      ),
      isNull,
    );
  });

  test('legacy cached lesson bodies cannot satisfy learner lists', () async {
    await CacheService.set('content_list_lesson_cat_secure_remote_only', [
      {
        'id': 'cached_paid_body',
        'kind': 'lesson',
        'categoryId': 'cat_secure_remote_only',
        'title': 'Legacy premium body',
        'blocks': [
          {'id': 'body', 'type': 'text', 'order': 0, 'markdown': 'secret'},
        ],
      },
    ]);
    when(
      () => functions.execute(
        'getAuthorizedLesson',
        body: {
          'action': 'list_lessons',
          'limit': 100,
          'categoryId': 'cat_secure_remote_only',
        },
        usePost: true,
      ),
    ).thenThrow(StateError('authorization unavailable'));
    final repository = ContentRepository(
      databases: databases,
      networkInfo: _OnlineNetworkInfo(),
      functionsService: functions,
    );

    final result = await repository.list(
      ContentKind.lesson,
      categoryId: 'cat_secure_remote_only',
    );
    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(databases);
  });

  test('legacy cached lesson detail cannot bypass authorization', () async {
    await CacheService.set('content_item_lesson_secure_shared_lesson', {
      'id': 'secure_shared_lesson',
      'kind': 'lesson',
      'categoryId': 'cat_secure_remote_only',
      'title': 'Legacy premium detail',
      'blocks': [
        {'id': 'body', 'type': 'text', 'order': 0, 'markdown': 'secret'},
      ],
    });
    final repository = ContentRepository(
      databases: databases,
      networkInfo: _OnlineNetworkInfo(),
    );

    final result = await repository.get(
      ContentKind.lesson,
      'secure_shared_lesson',
    );
    expect(result.isLeft(), isTrue);
    verifyZeroInteractions(databases);
  });

  test('lesson level and preview survive Appwrite round trips', () {
    final item = ContentItem.fromJson(
      {
        'id': 'lesson_round_trip',
        'categoryId': 'cat_round_trip',
        'titleOlChiki': 'ᱚᱞ',
        'titleLatin': 'Round trip',
        'level': 'advanced',
        'isPreview': true,
      },
      'lesson_round_trip',
      ContentKind.lesson,
    );

    expect(item.difficulty, 'advanced');
    expect(item.isPreview, isTrue);
    final attributes = item.toAppwriteAttributes();
    expect(attributes['level'], 'advanced');
    expect(attributes['isPreview'], isTrue);
  });
'''
last = test_value.rfind("\n}")
if last < 0:
    raise RuntimeError(f"{test_path}: no main closing brace")
write(test_path, test_value[:last] + insert + test_value[last:])
replace_once(
    test_path,
    """        expect(lesson.isLocked, isTrue);
        expect(lesson.blocks, isEmpty);
""",
    """        expect(lesson.isLocked, isTrue);
        expect(lesson.accessReason, 'purchase_required');
        expect(lesson.blocks, isEmpty);
""",
)
replace_once(
    test_path,
    """        'ok': true,
        'locked': true,
        'lesson': {..._lessonMetadata(), 'blocks': <Map<String, dynamic>>[]},
""",
    """        'ok': true,
        'locked': true,
        'reason': 'purchase_required',
        'lesson': {..._lessonMetadata(), 'blocks': <Map<String, dynamic>>[]},
""",
)

package_path = ROOT / "package.json"
package = json.loads(package_path.read_text(encoding="utf-8"))
needle = "node --test scripts/check_review_corpus_ids.test.mjs"
replacement = (
    "node --test scripts/check_review_corpus_ids.test.mjs "
    "scripts/check_premium_content_permissions.test.mjs"
)
backend = package["scripts"]["test:backend"]
if backend.count(needle) != 1:
    raise RuntimeError("package.json: backend test anchor drift")
package["scripts"]["test:backend"] = backend.replace(needle, replacement, 1)
package_path.write_text(json.dumps(package, indent=2) + "\n", encoding="utf-8")

verifier = "scripts/verify_live_appwrite_system.mjs"
replace_once(
    verifier,
    """import { rowIdFor } from '../functions/mutateReviewState/src/main.js';
""",
    """import { rowIdFor } from '../functions/mutateReviewState/src/main.js';
import {
  assertReleasePreflight,
  createApiClient,
  loadReleasePreflight,
} from './check_premium_content_permissions.mjs';
import { readFileSync } from 'node:fs';
""",
)
replace_once(
    verifier,
    """    console.log(`  ✓ Latest deployment: ${fn.latestDeploymentId} (status: ${fn.latestDeploymentStatus})`);

    // 3. Unauthenticated Execution Rejection
""",
    """    console.log(`  ✓ Latest deployment: ${fn.latestDeploymentId} (status: ${fn.latestDeploymentStatus})`);

    const expectedReleaseCommit = process.env.EXPECTED_RELEASE_COMMIT?.trim();
    if (expectedReleaseCommit) {
      console.log('  • Verifying active authorization-function and site provenance...');
      const manifest = JSON.parse(
        readFileSync(new URL('../appwrite.json', import.meta.url), 'utf8'),
      );
      const preflightApi = createApiClient({
        endpoint: ENDPOINT,
        projectId: PROJECT_ID,
        apiKey,
      });
      const preflight = await loadReleasePreflight(preflightApi, manifest);
      assertReleasePreflight(preflight, manifest, expectedReleaseCommit);
      console.log('  ✓ Active authorization function and Flutter site match the release commit');
    } else {
      console.log('  • Release provenance skipped; set EXPECTED_RELEASE_COMMIT to enforce it');
    }

    // 3. Unauthenticated Execution Rejection
""",
)

readme = "scripts/README.md"
readme_text = read(readme)
section = """

## Premium lesson permission cutover

`check_premium_content_permissions.mjs` is dry-run only unless `--apply` is
provided with an exact project confirmation. Run the phases in order:

1. `node scripts/check_premium_content_permissions.mjs`
2. `node scripts/check_premium_content_permissions.mjs --phase=rows`
3. Re-run phase 2 with `--apply --confirm-project=<project-id>`.
4. After the authorization function and Flutter site are active from the same
   protected-main commit, run `--phase=boundary --expected-release-commit=<sha>`.
5. Apply the boundary only with both exact project and release confirmations.

The boundary phase uses the active `deploymentId` (never a newer inactive
preview), validates function variables and `appwrite.json`, verifies the
private entitlement table and `lessons.isPreview`, then writes a local rollback
record before enabling row security and removing broad table reads.
"""
if "## Premium lesson permission cutover" not in readme_text:
    write(readme, readme_text.rstrip() + section + "\n")

gitignore = ".gitignore"
gitignore_text = read(gitignore)
if ".premium-content-rollback/" not in gitignore_text:
    write(gitignore, gitignore_text.rstrip() + "\n.premium-content-rollback/\n")

print("final secure-listing patch applied")
