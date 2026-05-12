import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

final numbersProvider =
    StateNotifierProvider<NumbersNotifier, AsyncValue<List<NumberModel>>>(
      NumbersNotifier.new,
    );

class NumbersNotifier extends StateNotifier<AsyncValue<List<NumberModel>>> {
  NumbersNotifier(this.ref) : super(AsyncValue.data(_seedNumbers)) {
    _loadNumbers();
  }

  final Ref ref;

  static final List<NumberModel> _seedNumbers = [
    NumberModel(
      id: 'n0',
      numeral: '᱐',
      value: 0,
      nameOlChiki: 'ᱥᱩᱱᱭᱟ',
      nameLatin: 'Sunya',
      order: 0,
    ),
    NumberModel(
      id: 'n1',
      numeral: '᱑',
      value: 1,
      nameOlChiki: 'ᱢᱤᱫ',
      nameLatin: 'Mit',
      order: 1,
    ),
    NumberModel(
      id: 'n2',
      numeral: '᱒',
      value: 2,
      nameOlChiki: 'ᱵᱟᱨ',
      nameLatin: 'Bar',
      order: 2,
    ),
    NumberModel(
      id: 'n3',
      numeral: '᱓',
      value: 3,
      nameOlChiki: 'ᱯᱮ',
      nameLatin: 'Pe',
      order: 3,
    ),
    NumberModel(
      id: 'n4',
      numeral: '᱔',
      value: 4,
      nameOlChiki: 'ᱯᱩᱱ',
      nameLatin: 'Pun',
      order: 4,
    ),
    NumberModel(
      id: 'n5',
      numeral: '᱕',
      value: 5,
      nameOlChiki: 'ᱢᱚᱬᱮ',
      nameLatin: 'Mone',
      order: 5,
    ),
    NumberModel(
      id: 'n6',
      numeral: '᱖',
      value: 6,
      nameOlChiki: 'ᱛᱩᱨᱩᱤ',
      nameLatin: 'Turui',
      order: 6,
    ),
    NumberModel(
      id: 'n7',
      numeral: '᱗',
      value: 7,
      nameOlChiki: 'ᱮᱭᱟᱭ',
      nameLatin: 'Eyay',
      order: 7,
    ),
    NumberModel(
      id: 'n8',
      numeral: '᱘',
      value: 8,
      nameOlChiki: 'ᱤᱨᱟᱹᱞ',
      nameLatin: 'Iral',
      order: 8,
    ),
    NumberModel(
      id: 'n9',
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
      state = AsyncValue.data(data.map(NumberModel.fromJson).toList());
    } catch (e) {
      state = AsyncValue.data(_seedNumbers);
    }
  }

  Future<void> add(NumberModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('numbers', item.id, item.toJson());
      await _loadNumbers();
    } catch (e) {
      debugPrint('❌ add number FAILED: $e');
    }
  }

  Future<void> update(NumberModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('numbers', item.id, item.toJson());
      await _loadNumbers();
    } catch (e) {
      debugPrint('❌ update number FAILED: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('numbers', id);
      await _loadNumbers();
    } catch (e) {
      debugPrint('❌ delete number FAILED: $e');
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
        debugPrint('Number already exists or error: $e');
      }
    }
    await _loadNumbers();
  }
}
