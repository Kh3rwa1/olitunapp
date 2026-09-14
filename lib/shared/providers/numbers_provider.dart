import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import '../utils/santali_numbers.dart';
import 'seeded_content_list_notifier.dart';

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final numbersProvider =
    NotifierProvider<NumbersNotifier, AsyncValue<List<NumberModel>>>(
      NumbersNotifier.new,
    );

/// Canonical 0-100 catalog. Single units keep their historic ids/names;
/// 10+ follow Santali counting (Gel, Isi, Pe Gel, ..., Say) with Ol Chiki
/// numerals derived from [SantaliNumbers].
final List<NumberModel> _seedNumbers = List<NumberModel>.generate(
  SantaliNumbers.maxValue + 1,
  (value) => NumberModel(
    id: 'n_$value',
    numeral: SantaliNumbers.toOlChikiNumeral(value),
    value: value,
    nameOlChiki: SantaliNumbers.nameOlChiki(value),
    nameLatin: SantaliNumbers.nameLatin(value),
    order: value,
  ),
  growable: false,
);

class NumbersNotifier extends SeededContentListNotifier<NumberModel> {
  @override
  String get collectionId => 'numbers';

  @override
  String get label => 'number';

  @override
  bool get rethrowCrudErrors => false;

  @override
  NumberModel Function(Map<String, dynamic> json) get fromJson =>
      NumberModel.fromJson;

  @override
  String itemId(NumberModel item) => item.id;

  @override
  int itemOrder(NumberModel item) => item.order;

  @override
  Future<List<NumberModel>> loadSeed() async => _seedNumbers;

  /// Remote-only emission with numeral dedupe; bundled seed is the offline
  /// fallback (this list deliberately does not merge seed rows into remote
  /// results, unlike words/sentences).
  @override
  Future<void> loadList() async {
    try {
      final remote = await fetchRemote();
      emit(_deduplicate(remote));
    } catch (_) {
      // Offline or collection unavailable — bundled seed is the
      // documented fallback for this list (see doc comment above).
      emit(_deduplicate(_seedNumbers));
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

  void addNumber(NumberModel item) => add(item);
  void updateNumber(NumberModel item) => update(item);
  void deleteNumber(String id) => delete(id);

  @override
  Future<void> seed() async {
    for (final item in _seedNumbers) {
      await add(item);
    }
    await loadList();
  }
}
