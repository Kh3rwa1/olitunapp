import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/content_models.dart';
import 'seeded_content_list_notifier.dart';

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final numbersProvider =
    NotifierProvider<NumbersNotifier, AsyncValue<List<NumberModel>>>(
      NumbersNotifier.new,
    );

final List<NumberModel> _seedNumbers = [
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
