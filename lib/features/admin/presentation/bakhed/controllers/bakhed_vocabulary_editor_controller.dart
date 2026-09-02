import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../admin/data/bakhed_repository.dart';
import '../../../../../shared/providers/bakhed_content_provider.dart';
import 'bakhed_editor_controller.dart';

class BakhedVocabularyState {
  final List<BakhedVocabularyItem> originalItems;
  final List<BakhedVocabularyItem> currentItems;
  final bool isLoaded;
  final bool isLoading;
  final String? error;

  const BakhedVocabularyState({
    this.originalItems = const [],
    this.currentItems = const [],
    this.isLoaded = false,
    this.isLoading = false,
    this.error,
  });

  bool get isDirty {
    if (!isLoaded) return false;
    if (originalItems.length != currentItems.length) return true;
    for (int i = 0; i < originalItems.length; i++) {
      if (originalItems[i] != currentItems[i]) return true;
    }
    return false;
  }

  BakhedVocabularyState copyWith({
    List<BakhedVocabularyItem>? originalItems,
    List<BakhedVocabularyItem>? currentItems,
    bool? isLoaded,
    bool? isLoading,
    String? error,
  }) {
    return BakhedVocabularyState(
      originalItems: originalItems ?? this.originalItems,
      currentItems: currentItems ?? this.currentItems,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BakhedVocabularyEditorNotifier
    extends FamilyNotifier<BakhedVocabularyState, String> {
  late String bakhedId;

  BakhedRepository get _repository => ref.read(bakhedRepositoryProvider);

  @override
  BakhedVocabularyState build(String arg) {
    bakhedId = arg;
    return const BakhedVocabularyState();
  }

  Future<void> ensureLoaded() async {
    if (state.isLoaded || state.isLoading) return;
    state = BakhedVocabularyState(
      originalItems: state.originalItems,
      currentItems: state.currentItems,
      isLoaded: state.isLoaded,
      isLoading: true,
    );

    final res = await _repository.getVocabulary(bakhedId);
    res.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (items) {
        state = BakhedVocabularyState(
          originalItems: List.from(items),
          currentItems: List.from(items),
          isLoaded: true,
        );
      },
    );
  }

  void updateItems(List<BakhedVocabularyItem> items) {
    // Standardize sortOrder values sequentially
    final updated = List.generate(items.length, (index) {
      return items[index].copyWith(sortOrder: index);
    });
    state = state.copyWith(currentItems: updated);
    ref.read(bakhedEditorControllerProvider(bakhedId).notifier).markDirty();
  }

  void addItem(BakhedVocabularyItem item) {
    updateItems([...state.currentItems, item]);
  }

  void removeItem(String id, int sortOrder) {
    final removedItem = state.currentItems.firstWhere(
      (e) =>
          (id.isNotEmpty && e.id == id) ||
          (id.isEmpty && e.sortOrder == sortOrder),
      orElse: () => const BakhedVocabularyItem(
        id: '',
        olChiki: '',
        latin: '',
        meaning: '',
        audioFileId: '',
        sortOrder: -1,
      ),
    );
    if (removedItem.audioFileId.isNotEmpty) {
      ref
          .read(bakhedEditorControllerProvider(bakhedId).notifier)
          .markForDeletion(removedItem.audioFileId);
    }

    final updated = state.currentItems.where((e) {
      if (id.isNotEmpty && e.id == id) return false;
      return e.sortOrder != sortOrder;
    }).toList();
    updateItems(updated);
  }

  void markClean() {
    state = state.copyWith(originalItems: List.from(state.currentItems));
  }
}

final bakhedVocabularyEditorProvider =
    NotifierProvider.family<
      BakhedVocabularyEditorNotifier,
      BakhedVocabularyState,
      String
    >(BakhedVocabularyEditorNotifier.new);

// ==========================================
// 4. Cultural Notes Editor Controller
// ==========================================
