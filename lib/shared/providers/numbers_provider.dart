import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

final numbersProvider =
    StateNotifierProvider<NumbersNotifier, AsyncValue<List<NumberModel>>>(
      (ref) => NumbersNotifier(ref),
    );

class NumbersNotifier extends StateNotifier<AsyncValue<List<NumberModel>>> {
  NumbersNotifier(this.ref) : super(AsyncValue.data(_seedNumbers)) {
    _loadNumbers();
  }

  final Ref ref;

  static final List<NumberModel> _seedNumbers = [
    NumberModel(id: '1', numeral: '᱑', value: 1, nameOlChiki: 'ᱢᱤᱫ', nameLatin: 'Mit'),
    NumberModel(id: '2', numeral: '᱒', value: 2, nameOlChiki: 'ᱵᱟᱨ', nameLatin: 'Bar'),
    NumberModel(id: '3', numeral: '᱓', value: 3, nameOlChiki: 'ᱯᱮ', nameLatin: 'Pe'),
    NumberModel(id: '4', numeral: '᱔', value: 4, nameOlChiki: 'ᱯᱩᱱ', nameLatin: 'Pun'),
    NumberModel(id: '5', numeral: '᱕', value: 5, nameOlChiki: 'ᱢᱚᱬᱮ', nameLatin: 'Mone'),
  ];

  Future<void> _loadNumbers() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'numbers',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      state = AsyncValue.data(data.map((e) => NumberModel.fromJson(e)).toList());
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

  Future<void> seed() async => _loadNumbers();
}
