import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final numbersProvider =
    NotifierProvider<NumbersNotifier, AsyncValue<List<NumberModel>>>(
      NumbersNotifier.new,
    );

class NumbersNotifier extends Notifier<AsyncValue<List<NumberModel>>> {
  bool _disposed = false;

  @override
  AsyncValue<List<NumberModel>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(_loadNumbers);
    return const AsyncValue.loading();
  }

  // IDEMPOTENT: safe to re-run, will not create duplicates.
  static final List<NumberModel> _seedNumbers = [
    NumberModel(
      id: 'n_0',
      numeral: '᱐',
      value: 0,
      nameOlChiki: 'ᱥᱩᱱᱭᱟ',
      nameLatin: 'Sunya',
    ),
    NumberModel(
      id: 'n_1',
      numeral: '᱑',
      value: 1,
      nameOlChiki: 'ᱢᱤᱫ',
      nameLatin: 'Mit',
      order: 1,
    ),
    NumberModel(
      id: 'n_2',
      numeral: '᱒',
      value: 2,
      nameOlChiki: 'ᱵᱟᱨ',
      nameLatin: 'Bar',
      order: 2,
    ),
    NumberModel(
      id: 'n_3',
      numeral: '᱓',
      value: 3,
      nameOlChiki: 'ᱯᱮ',
      nameLatin: 'Pe',
      order: 3,
    ),
    NumberModel(
      id: 'n_4',
      numeral: '᱔',
      value: 4,
      nameOlChiki: 'ᱯᱩᱱ',
      nameLatin: 'Pun',
      order: 4,
    ),
    NumberModel(
      id: 'n_5',
      numeral: '᱕',
      value: 5,
      nameOlChiki: 'ᱢᱚᱬᱮ',
      nameLatin: 'Mone',
      order: 5,
    ),
    NumberModel(
      id: 'n_6',
      numeral: '᱖',
      value: 6,
      nameOlChiki: 'ᱛᱩᱨᱩᱭ',
      nameLatin: 'Turui',
      order: 6,
    ),
    NumberModel(
      id: 'n_7',
      numeral: '᱗',
      value: 7,
      nameOlChiki: 'ᱮᱭᱟᱭ',
      nameLatin: 'Eae',
      order: 7,
    ),
    NumberModel(
      id: 'n_8',
      numeral: '᱘',
      value: 8,
      nameOlChiki: 'ᱤᱨᱟᱹᱞ',
      nameLatin: 'Iral',
      order: 8,
    ),
    NumberModel(
      id: 'n_9',
      numeral: '᱙',
      value: 9,
      nameOlChiki: 'ᱟᱨᱮ',
      nameLatin: 'Are',
      order: 9,
    ),
  ];

  Future<void> _loadNumbers() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'numbers',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      if (_disposed) return;
      state = AsyncValue.data(
        _deduplicate(data.map(NumberModel.fromJson).toList()),
      );
    } catch (e) {
      if (_disposed) return;
      state = AsyncValue.data(_deduplicate(_seedNumbers));
    }
  }

  List<NumberModel> _deduplicate(List<NumberModel> list) {
    final seenIds = <String>{};
    final seenNums = <String>{};
    final unique = <NumberModel>[];

    for (final item in list) {
      if (seenIds.contains(item.id)) continue;
      if (seenNums.contains(item.numeral)) continue;
      seenIds.add(item.id);
      seenNums.add(item.numeral);
      unique.add(item);
    }
    return unique;
  }

  Future<void> add(NumberModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('numbers', item.id, item.toJson());
      await _loadNumbers();
    } catch (e) {
      AppLogger.debug('❌ add number FAILED: $e');
    }
  }

  Future<void> update(NumberModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('numbers', item.id, item.toJson());
      await _loadNumbers();
    } catch (e) {
      AppLogger.debug('❌ update number FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('numbers', id);
      await _loadNumbers();
    } catch (e) {
      AppLogger.debug('❌ delete number FAILED: $e');
    }
  }

  void addNumber(NumberModel item) => add(item);
  void updateNumber(NumberModel item) => update(item);
  void deleteNumber(String id) => delete(id);

  Future<void> seed() async {
    for (final item in _seedNumbers) {
      try {
        final db = ref.read(appwriteDbServiceProvider);
        await db.createDocument('numbers', item.id, item.toJson());
      } catch (e) {
        AppLogger.debug('Number already exists or error: $e');
      }
    }
    await _loadNumbers();
  }
}
