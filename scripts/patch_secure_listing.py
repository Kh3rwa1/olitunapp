#!/usr/bin/env python3
"""Temporary deterministic patcher for the complete secure lesson-read cutover."""
from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    source = target.read_text()
    if source.count(old) != 1:
        raise SystemExit(f'Unexpected anchor count in {path}: {old[:80]!r}')
    target.write_text(source.replace(old, new, 1))


def replace_all_expected(path: str, old: str, new: str, count: int) -> None:
    target = Path(path)
    source = target.read_text()
    if source.count(old) != count:
        raise SystemExit(
            f'Unexpected anchor count in {path}: expected {count}, found {source.count(old)}'
        )
    target.write_text(source.replace(old, new))


model = 'lib/shared/models/content_item/content_item_model.dart'
replace_once(
    model,
    "  final bool isPublished;\n  final bool isPremium;\n  final List<String> tags;",
    "  final bool isPublished;\n  final bool isPremium;\n  final bool isPreview;\n  final bool isLocked;\n  final String? accessReason;\n  final List<String> tags;",
)
replace_once(
    model,
    "    this.isPublished = false,\n    this.isPremium = false,\n    this.tags = const [],",
    "    this.isPublished = false,\n    this.isPremium = false,\n    this.isPreview = false,\n    this.isLocked = false,\n    this.accessReason,\n    this.tags = const [],",
)
replace_once(
    model,
    "      'isPublished': isPublished,\n      'isPremium': isPremium,\n      'tags': tags,",
    "      'isPublished': isPublished,\n      'isPremium': isPremium,\n      'isPreview': isPreview,\n      'isLocked': isLocked,\n      if (accessReason != null) 'accessReason': accessReason,\n      'tags': tags,",
)
replace_once(
    model,
    "    bool? isPublished,\n    bool? isPremium,\n    List<String>? tags,",
    "    bool? isPublished,\n    bool? isPremium,\n    bool? isPreview,\n    bool? isLocked,\n    String? accessReason,\n    List<String>? tags,",
)
replace_once(
    model,
    "      isPublished: isPublished ?? this.isPublished,\n      isPremium: isPremium ?? this.isPremium,\n      tags: tags ?? this.tags,",
    "      isPublished: isPublished ?? this.isPublished,\n      isPremium: isPremium ?? this.isPremium,\n      isPreview: isPreview ?? this.isPreview,\n      isLocked: isLocked ?? this.isLocked,\n      accessReason: accessReason ?? this.accessReason,\n      tags: tags ?? this.tags,",
)
replace_once(
    model,
    "    isPublished,\n    isPremium,\n    tags,",
    "    isPublished,\n    isPremium,\n    isPreview,\n    isLocked,\n    accessReason,\n    tags,",
)

serialization = 'lib/shared/models/content_item/content_item_serialization.dart'
replace_once(
    serialization,
    "      isPremium:\n          json['is_premium'] as bool? ?? json['isPremium'] as bool? ?? false,\n      tags: parsedTags,",
    "      isPremium:\n          json['is_premium'] as bool? ?? json['isPremium'] as bool? ?? false,\n      isPreview: json['isPreview'] as bool? ?? false,\n      isLocked: json['isLocked'] as bool? ?? false,\n      accessReason: json['accessReason'] as String?,\n      tags: parsedTags,",
)
replace_once(
    serialization,
    "          'isActive': item.isPublished,\n          'isPremium': item.isPremium,",
    "          'isActive': item.isPublished,\n          'isPremium': item.isPremium,\n          'isPreview': item.isPreview,",
)

extensions = 'lib/shared/models/content_item_extensions.dart'
replace_once(
    extensions,
    "      titleLatin: title,\n      order: order,\n      estimatedMinutes: durationSeconds != null",
    "      titleLatin: title,\n      level: difficulty ?? 'beginner',\n      description: subtitle,\n      order: order,\n      estimatedMinutes: durationSeconds != null",
)
replace_once(
    extensions,
    "          : 5,\n      blocks: blocks.map((b) => b.toLessonBlockEntity()).toList(),",
    "          : 5,\n      isActive: isPublished,\n      isPreview: isPreview,\n      isLocked: isLocked,\n      blocks: blocks.map((b) => b.toLessonBlockEntity()).toList(),",
)

repository_path = Path('lib/shared/repositories/content_repository.dart')
repository = repository_path.read_text()
import_anchor = "import 'package:itun/core/api/appwrite_databases_pagination.dart';"
functions_import = "import 'package:itun/core/api/appwrite_functions_service.dart';"
if repository.count(import_anchor) != 1 or functions_import in repository:
    raise SystemExit('Unexpected ContentRepository import anchors')
repository = repository.replace(import_anchor, f'{import_anchor}\n{functions_import}', 1)
repository = repository.replace(
    "class ContentRepository {\n  final Databases _databases;\n  final NetworkInfo _networkInfo;\n  final MutationOutboxService? _mutationOutbox;",
    "class ContentRepository {\n  static const int _authorizedLessonListPageSize = 100;\n  static const int _maxAuthorizedLessonListPages = 100;\n\n  final Databases _databases;\n  final NetworkInfo _networkInfo;\n  final MutationOutboxService? _mutationOutbox;\n  final AppwriteFunctionsService? _functionsService;",
    1,
)
constructor_old = """    required NetworkInfo networkInfo,
    MutationOutboxService? mutationOutbox,
  }) : _databases = databases,
       _networkInfo = networkInfo,
       _mutationOutbox = mutationOutbox;"""
constructor_new = """    required NetworkInfo networkInfo,
    MutationOutboxService? mutationOutbox,
    AppwriteFunctionsService? functionsService,
  }) : _databases = databases,
       _networkInfo = networkInfo,
       _mutationOutbox = mutationOutbox,
       _functionsService = functionsService;"""
if repository.count(constructor_old) != 1:
    raise SystemExit('Unexpected ContentRepository constructor anchor')
repository = repository.replace(constructor_old, constructor_new, 1)

helper_anchor = "  /// Reads bundled/cached content without checking connectivity or contacting\n"
if repository.count(helper_anchor) != 1:
    raise SystemExit('Unexpected ContentRepository helper insertion anchor')
helpers = """  ContentItem _parseAuthorizedLesson(
    Map<String, dynamic> rawLesson,
    String lessonId,
  ) {
    final normalized = Map<String, dynamic>.from(rawLesson);
    normalized['difficulty'] = normalized['level'];
    final estimatedMinutes = normalized['estimatedMinutes'];
    if (estimatedMinutes is num) {
      normalized['durationSeconds'] = (estimatedMinutes * 60).round();
    }
    normalized['isPublished'] = normalized['isActive'] != false;
    normalized['isPremium'] = normalized['isLocked'] == true;
    return ContentItem.fromJson(normalized, lessonId, ContentKind.lesson);
  }

  Future<List<ContentItem>> _listAuthorizedLessons(String? categoryId) async {
    final functionsService = _functionsService;
    if (functionsService == null) {
      throw StateError('Lesson authorization service unavailable');
    }

    final lessons = <ContentItem>[];
    final seenLessonIds = <String>{};
    final seenCursors = <String>{};
    String? cursor;

    for (var page = 0; page < _maxAuthorizedLessonListPages; page++) {
      final result = await functionsService.execute(
        'getAuthorizedLesson',
        body: {
          'action': 'list_lessons',
          'limit': _authorizedLessonListPageSize,
          'categoryId': ?categoryId,
          'cursor': ?cursor,
        },
        usePost: true,
      );
      final data = result.bodyJson;
      if (!result.isCompleted ||
          result.statusCode != 200 ||
          data == null ||
          data['ok'] != true ||
          data['lessons'] is! List) {
        throw StateError(
          data?['message'] as String? ??
              'Failed to load authorized lesson metadata',
        );
      }

      for (final rawLesson in data['lessons'] as List) {
        if (rawLesson is! Map) {
          throw const FormatException('Malformed authorized lesson metadata');
        }
        final lessonMap = Map<String, dynamic>.from(rawLesson);
        final lessonId = lessonMap['id'];
        if (lessonId is! String ||
            lessonId.isEmpty ||
            !seenLessonIds.add(lessonId)) {
          throw const FormatException(
            'Malformed or duplicate authorized lesson metadata',
          );
        }
        lessons.add(_parseAuthorizedLesson(lessonMap, lessonId));
      }

      if (data['hasMore'] != true) return lessons;
      final nextCursor = data['nextCursor'];
      if (nextCursor is! String ||
          nextCursor.isEmpty ||
          !seenCursors.add(nextCursor)) {
        throw const FormatException(
          'Malformed authorized lesson pagination cursor',
        );
      }
      cursor = nextCursor;
    }

    throw const FormatException(
      'Authorized lesson list exceeded the safe pagination bound',
    );
  }

  Future<Either<Failure, ContentItem>> _getAuthorizedLesson(String id) async {
    final functionsService = _functionsService;
    if (functionsService == null) {
      return left(
        const ServerFailure(message: 'Lesson authorization service unavailable'),
      );
    }

    try {
      final result = await functionsService.execute(
        'getAuthorizedLesson',
        body: {'action': 'get_lesson', 'lessonId': id},
        usePost: true,
      );
      final data = result.bodyJson;
      if (result.isCompleted &&
          result.statusCode == 200 &&
          data != null &&
          data['ok'] == true &&
          data['lesson'] is Map) {
        final lessonMap = Map<String, dynamic>.from(data['lesson'] as Map);
        final lessonId = lessonMap['id'];
        if (lessonId is! String || lessonId.isEmpty || lessonId != id) {
          return left(
            const ServerFailure(
              message: 'Malformed authorized lesson response',
            ),
          );
        }
        return right(_parseAuthorizedLesson(lessonMap, lessonId));
      }
      if (result.statusCode == 404) {
        return left(ServerFailure(message: 'Lesson "$id" was not found.'));
      }
      return left(
        ServerFailure(
          message:
              data?['message'] as String? ??
              'Failed to retrieve authorized lesson',
        ),
      );
    } catch (error) {
      return left(
        ServerFailure(message: 'Failed to retrieve authorized lesson: $error'),
      );
    }
  }

"""
repository = repository.replace(helper_anchor, helpers + helper_anchor, 1)

list_method_start = repository.index(
    "  Future<Either<Failure, List<ContentItem>>> list(\n"
)
network_start = repository.index(
    "    if (await _networkInfo.isConnected) {", list_method_start
)
network_end_marker = "    } else {\n      return _getCachedList(kind, categoryId, fallback: bundledItems);\n    }"
network_end = repository.index(network_end_marker, network_start) + len(network_end_marker)
network_replacement = """    if (await _networkInfo.isConnected) {
      try {
        final List<ContentItem> remoteItems;
        if (kind == ContentKind.lesson) {
          remoteItems = await _listAuthorizedLessons(categoryId);
        } else {
          final categoryAttribute = _categoryAttribute(kind);
          final List<String> queries = [
            if (categoryAttribute != null &&
                categoryId != null &&
                categoryId.isNotEmpty)
              Query.equal(categoryAttribute, categoryId),
            if (_hasOrderAttribute(kind)) Query.orderAsc('order'),
            Query.limit(500),
          ];

          final response = await AppwriteDatabasesPagination.listDocuments(
            _databases,
            databaseId: AppwriteConfig.databaseId,
            collectionId: collectionId,
            queries: queries,
          );
          remoteItems = response
              .map((doc) => ContentItem.fromJson(doc.data, doc.$id, kind))
              .toList();
        }

        // Authorized lesson metadata intentionally overrides bundled lesson
        // bodies with body-free, server-authoritative lock state.
        final mergedItems = _mergeContentItems(bundledItems, remoteItems);
        final cachedData = mergedItems.map((item) => item.toJson()).toList();
        await CacheService.set(cacheKey, cachedData);

        for (final item in mergedItems) {
          await CacheService.set(_cacheItemKey(kind, item.id), item.toJson());
        }

        return right(mergedItems);
      } catch (_) {
        // Never fall back to a direct lesson collection read. A safe local
        // catalog remains usable while the authorization service is offline.
        return _getCachedList(kind, categoryId, fallback: bundledItems);
      }
    } else {
      return _getCachedList(kind, categoryId, fallback: bundledItems);
    }"""
repository = repository[:network_start] + network_replacement + repository[network_end:]

get_start = repository.index(
    "  /// Gets a single content item by ID.\n  Future<Either<Failure, ContentItem>> get("
)
get_body_start = repository.index("  Future<Either<Failure, ContentItem>> get(", get_start)
get_end = repository.index(
    "\n  Future<Either<Failure, ContentItem>> _getCachedItem(", get_body_start
)
existing_get = repository[get_body_start:get_end]
direct_get = existing_get.replace(
    "Future<Either<Failure, ContentItem>> get(",
    "Future<Either<Failure, ContentItem>> getForAdministration(",
    1,
)
secure_get = """  Future<Either<Failure, ContentItem>> get(
    ContentKind kind,
    String id,
  ) async {
    if (kind == ContentKind.lesson) return _getAuthorizedLesson(id);
    return getForAdministration(kind, id);
  }

  /// Full-body CMS read. Appwrite team/row permissions are authoritative;
  /// learner-facing code must use [get] instead.
"""
repository = repository[:get_body_start] + secure_get + direct_get + repository[get_end:]
if repository.count("final itemRes = await get(kind, id);") != 1:
    raise SystemExit('Unexpected delete pre-read anchor')
repository = repository.replace(
    "final itemRes = await get(kind, id);",
    "final itemRes = await getForAdministration(kind, id);",
    1,
)
repository_path.write_text(repository)

providers = 'lib/shared/providers/content_providers.dart'
replace_once(
    providers,
    "import 'package:itun/core/auth/appwrite_auth_service.dart';",
    "import 'package:itun/core/api/appwrite_functions_service.dart';\nimport 'package:itun/core/auth/appwrite_auth_service.dart';",
)
replace_once(
    providers,
    "    mutationOutbox: ref.watch(mutationOutboxProvider),\n  );",
    "    mutationOutbox: ref.watch(mutationOutboxProvider),\n    functionsService: ref.watch(appwriteFunctionsServiceProvider),\n  );",
)

replace_all_expected(
    'lib/features/admin/presentation/lessons/content/admin_lesson_content_screen.dart',
    'repo.get(ContentKind.lesson,',
    'repo.getForAdministration(ContentKind.lesson,',
    1,
)
replace_all_expected(
    'lib/features/admin/presentation/lessons/widgets/lesson_form_sheet.dart',
    'repo.get(ContentKind.lesson,',
    'repo.getForAdministration(ContentKind.lesson,',
    1,
)
replace_all_expected(
    'lib/features/admin/presentation/translations/widgets/translation_edit_dialog_inputs.dart',
    'repo.get(ContentKind.lesson,',
    'repo.getForAdministration(ContentKind.lesson,',
    2,
)

js_test = Path('functions/test/authorized_lesson_listing.test.js')
js_source = js_test.read_text()
insert_anchor = "test('Authorized Lesson List: supports bounded cursor pagination', async () => {"
if js_source.count(insert_anchor) != 1:
    raise SystemExit('Unexpected authorized lesson-list test insertion anchor')
revocation_test = """test('Authorized Lesson List: refunded, revoked, and disputed grants stay locked', async () => {
  const categories = [
    'cat_refunded',
    'cat_revoked',
    'cat_disputed',
    'cat_full_refund',
    'cat_verified',
  ].map((id) => paidCategory(id));
  const lessons = categories.map((category, index) =>
    lesson(`lesson_${index}`, category.$id, index + 1));
  const purchases = [
    { userId: 'buyer', categoryId: 'cat_refunded', status: 'refunded' },
    { userId: 'buyer', categoryId: 'cat_revoked', status: 'revoked' },
    { userId: 'buyer', categoryId: 'cat_disputed', status: 'disputed' },
    {
      userId: 'buyer',
      categoryId: 'cat_full_refund',
      status: 'verified',
      expectedAmount: 499,
      refundedAmountPaise: 49900,
    },
    {
      userId: 'buyer',
      categoryId: 'cat_verified',
      status: 'verified',
      expectedAmount: 499,
      refundedAmountPaise: 0,
    },
  ];
  const handler = createGetAuthorizedLessonHandler({
    databases: makeFakeDatabases({ lessons, categories, purchases }),
  });
  const res = mockRes();

  await handler({
    req: request({ action: 'list_lessons' }, { 'x-appwrite-user-id': 'buyer' }),
    res,
  });

  assert.equal(res.statusCode, 200);
  assert.deepEqual(
    res.body.lessons.map((item) => item.isLocked),
    [true, true, true, true, false],
  );
});

"""
js_test.write_text(js_source.replace(insert_anchor, revocation_test + insert_anchor, 1))
