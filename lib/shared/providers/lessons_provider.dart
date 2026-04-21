import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

final lessonsProvider =
    StateNotifierProvider<LessonsNotifier, AsyncValue<List<LessonModel>>>(
      (ref) => LessonsNotifier(ref),
    );

final lessonsByCategoryProvider =
    Provider.family<AsyncValue<List<LessonModel>>, String>((ref, categoryId) {
      final lessonsAsync = ref.watch(lessonsProvider);
      return lessonsAsync.when(
        data: (lessons) => AsyncValue.data(
          lessons.where((l) => l.categoryId == categoryId).toList(),
        ),
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
      );
    });

class LessonsNotifier extends StateNotifier<AsyncValue<List<LessonModel>>> {
  LessonsNotifier(this.ref) : super(AsyncValue.data(_seedLessons)) {
    _loadLessons();
  }

  final Ref ref;

  static final List<LessonModel> _seedLessons = [
    LessonModel(
      id: 'seed_lesson_a1', categoryId: 'seed_alphabet',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱹᱲᱟᱝ', titleLatin: 'Vowels (Part 1)',
      description: 'Learn the first 3 Ol Chiki vowels', order: 0, estimatedMinutes: 5,
      blocks: [
        LessonBlock(type: 'text', textOlChiki: 'ᱚ', textLatin: 'O'),
        LessonBlock(type: 'text', textOlChiki: 'ᱟ', textLatin: 'A'),
        LessonBlock(type: 'text', textOlChiki: 'ᱤ', textLatin: 'I'),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_a2', categoryId: 'seed_alphabet',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱟᱹᱲᱟᱝ', titleLatin: 'Vowels (Part 2)',
      description: 'Learn the next 3 Ol Chiki vowels', order: 1, estimatedMinutes: 5,
      blocks: [
        LessonBlock(type: 'text', textOlChiki: 'ᱩ', textLatin: 'U'),
        LessonBlock(type: 'text', textOlChiki: 'ᱮ', textLatin: 'E'),
        LessonBlock(type: 'text', textOlChiki: 'ᱳ', textLatin: 'Oh'),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_a3', categoryId: 'seed_alphabet',
      titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ ᱠᱚ', titleLatin: 'Consonants (Part 1)',
      description: 'Learn K, G, C', order: 2, estimatedMinutes: 7,
      blocks: [
        LessonBlock(type: 'text', textOlChiki: 'ᱠ', textLatin: 'Ko'),
        LessonBlock(type: 'text', textOlChiki: 'ᱜ', textLatin: 'Ga'),
        LessonBlock(type: 'text', textOlChiki: 'ᱪ', textLatin: 'Ca'),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_n1', categoryId: 'seed_numbers',
      titleOlChiki: 'ᱮᱞᱠᱷᱟ ᱑-᱕', titleLatin: 'Numbers 1-5',
      description: 'Count from one to five', order: 0, estimatedMinutes: 5,
      blocks: [
        LessonBlock(type: 'text', textOlChiki: '᱑ – ᱢᱤᱫ', textLatin: '1 – Mid'),
        LessonBlock(type: 'text', textOlChiki: '᱒ – ᱵᱟᱨ', textLatin: '2 – Bar'),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_w1', categoryId: 'seed_words',
      titleOlChiki: 'ᱡᱤᱱᱤᱥ ᱨᱚᱲ', titleLatin: 'Common Objects',
      description: 'Everyday object names', order: 0, estimatedMinutes: 5,
      blocks: [
        LessonBlock(type: 'text', textOlChiki: 'ᱫᱟᱠᱟ', textLatin: 'Daka – Food'),
        LessonBlock(type: 'text', textOlChiki: 'ᱫᱟᱠ', textLatin: 'Dak – Water'),
      ],
    ),
    LessonModel(
      id: 'seed_lesson_s1', categoryId: 'seed_sentences',
      titleOlChiki: 'ᱡᱚᱦᱟᱨ ᱣᱟᱠᱭ', titleLatin: 'Greetings',
      description: 'Basic Santali greetings', order: 0, estimatedMinutes: 5,
      blocks: [
        LessonBlock(type: 'text', textOlChiki: 'ᱡᱚᱦᱟᱨ!', textLatin: 'Johar!'),
        LessonBlock(type: 'text', textOlChiki: 'ᱪᱮᱫ ᱠᱟᱱᱟ?', textLatin: 'Ced kana?'),
      ],
    ),
  ];

  Future<void> _loadLessons() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'lessons', queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      final list = data.map((e) {
        if (e['blocks'] is String && (e['blocks'] as String).isNotEmpty) {
          e['blocks'] = jsonDecode(e['blocks'] as String);
        } else if (e['blocks'] is! List) {
          e['blocks'] = [];
        }
        return LessonModel.fromJson(e);
      }).toList();
      // Only replace seed data if real data was fetched
      if (list.isNotEmpty) {
        state = AsyncValue.data(list);
      }
    } catch (e) {
      debugPrint('❌ _loadLessons FAILED: $e');
      // Keep existing data (seed or previously loaded) on failure
      if (!state.hasValue || state.value!.isEmpty) {
        state = AsyncValue.data(_seedLessons);
      }
    }
  }

  Future<void> refresh() async => _loadLessons();

  Future<void> add(LessonModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final json = item.toJson();
      json['blocks'] = jsonEncode(json['blocks']);
      await db.createDocument('lessons', item.id, json);
      await _loadLessons();
    } catch (e) { debugPrint('❌ add lesson FAILED: $e'); }
  }

  Future<void> update(LessonModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final json = item.toJson();
      json['blocks'] = jsonEncode(json['blocks']);
      await db.updateDocument('lessons', item.id, json);
      await _loadLessons();
    } catch (e) { debugPrint('❌ update lesson FAILED: $e'); }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('lessons', id);
      await _loadLessons();
    } catch (e) { debugPrint('❌ delete lesson FAILED: $e'); }
  }

  Future<void> addLesson(LessonModel item) async => add(item);
  Future<void> updateLesson(LessonModel item) async => update(item);
  Future<void> deleteLesson(String id) async => delete(id);

  Future<void> seed() async {
    state = const AsyncValue.loading();
    _loadLessons();
  }
}
