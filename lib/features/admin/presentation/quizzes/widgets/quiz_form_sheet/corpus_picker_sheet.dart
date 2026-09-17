// Verified-corpus picker for quiz attribution: searchable, type-filtered,
// alias/tombstone-aware, with an explicit non-memory option. Educators pick
// verified items instead of typing raw IDs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../quiz/domain/quiz_identity_validation.dart';
import '../../../../../review/domain/review_corpus_identity.dart';
import '../../../../../review/domain/review_item.dart';
import '../../../../../../shared/models/content_models.dart' hide CategoryModel;

Future<CorpusPick?> showCorpusPickerSheet(BuildContext context) {
  return showModalBottomSheet<CorpusPick>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => const CorpusPickerSheet(),
  );
}

class CorpusPick {
  final String itemId;
  final ReviewItemType itemType;
  final bool isNonMemory;
  const CorpusPick({required this.itemId, required this.itemType})
    : isNonMemory = false;
  const CorpusPick.nonMemory()
    : itemId = '',
      itemType = ReviewItemType.word,
      isNonMemory = true;
}

/// Live attribution status under the ID fields: structural errors, alias
/// resolution warnings, and retired-ID warnings — before save is attempted.
class CorpusAttributionStatus extends ConsumerWidget {
  final String wordId;
  final String sentenceId;
  const CorpusAttributionStatus({
    super.key,
    required this.wordId,
    required this.sentenceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = wordId.trim();
    final s = sentenceId.trim();
    if (w.isNotEmpty && s.isNotEmpty) {
      return const _StatusLine(
        Icons.error_rounded,
        'Both IDs set — keep exactly one.',
        Colors.red,
      );
    }
    if (w.isEmpty && s.isEmpty) {
      return const _StatusLine(
        Icons.info_outline_rounded,
        'No corpus link. Pick an item or mark Non-memory.',
        Colors.orange,
      );
    }
    final corpusMap = ref.watch(corpusIdentityMapProvider).valueOrNull;
    if (corpusMap == null) {
      return const _StatusLine(
        Icons.cloud_off_rounded,
        'Corpus unavailable — ID will be verified at publish.',
        Colors.orange,
      );
    }
    final probe = QuizQuestion(
      promptOlChiki: '',
      sourceWordId: w.isNotEmpty ? w : null,
      sourceSentenceId: s.isNotEmpty ? s : null,
    );
    final v = validateQuestionIdentity(probe, corpusMap: corpusMap);
    switch (v.status) {
      case QuizIdentityStatus.valid:
        if (v.resolvedViaAlias) {
          return _StatusLine(
            Icons.swap_horiz_rounded,
            'Alias → canonical "${v.canonicalId}".',
            Colors.blue,
          );
        }
        return _StatusLine(
          Icons.check_circle_rounded,
          'Verified ${v.canonicalType?.name} "${v.canonicalId}".',
          Colors.green,
        );
      case QuizIdentityStatus.tombstonedId:
        return const _StatusLine(
          Icons.delete_forever_rounded,
          'Retired ID — pick another item.',
          Colors.red,
        );
      case QuizIdentityStatus.unknownId:
        return const _StatusLine(
          Icons.help_outline_rounded,
          'ID not in verified corpus.',
          Colors.red,
        );
      case QuizIdentityStatus.typeMismatch:
        return const _StatusLine(
          Icons.swap_horiz_rounded,
          'ID type does not match its field.',
          Colors.red,
        );
      case QuizIdentityStatus.aliasCycle:
        return const _StatusLine(
          Icons.loop_rounded,
          'Broken alias chain — relink.',
          Colors.red,
        );
      default:
        return _StatusLine(
          Icons.info_outline_rounded,
          v.message ?? v.status.name,
          Colors.orange,
        );
    }
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _StatusLine(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    );
  }
}

/// Searchable verified-corpus picker: type filter, text search, alias and
/// retired badges, and an explicit "Non-memory assessment" option.
/// Educators never need to type raw IDs.
class CorpusPickerSheet extends ConsumerStatefulWidget {
  const CorpusPickerSheet({super.key});

  @override
  ConsumerState<CorpusPickerSheet> createState() => _CorpusPickerSheetState();
}

class _CorpusPickerSheetState extends ConsumerState<CorpusPickerSheet> {
  String _query = '';
  int _typeFilter = 0; // 0 all, 1 words, 2 sentences
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corpusAsync = ref.watch(corpusIdentityMapProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Pick verified corpus item',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search by ID…',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _typeFilter == 0,
                    onSelected: (_) => setState(() => _typeFilter = 0),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Words'),
                    selected: _typeFilter == 1,
                    onSelected: (_) => setState(() => _typeFilter = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sentences'),
                    selected: _typeFilter == 2,
                    onSelected: (_) => setState(() => _typeFilter = 2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: corpusAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Corpus error: $e')),
                  data: (map) => _ItemList(
                    map: map,
                    query: _query,
                    typeFilter: _typeFilter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, const CorpusPick.nonMemory()),
                    icon: const Icon(Icons.block_rounded),
                    label: const Text('Non-memory assessment (no tracking)'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final ReviewCorpusIdentityMap map;
  final String query;
  final int typeFilter;
  const _ItemList({
    required this.map,
    required this.query,
    required this.typeFilter,
  });

  @override
  Widget build(BuildContext context) {
    final entries =
        <({String id, ReviewItemType type})>[
              if (typeFilter != 2)
                for (final id in map.activeWordIds)
                  (id: id, type: ReviewItemType.word),
              if (typeFilter != 1)
                for (final id in map.activeSentenceIds)
                  (id: id, type: ReviewItemType.sentence),
            ]
            .where((e) => query.isEmpty || e.id.toLowerCase().contains(query))
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    if (entries.isEmpty) {
      return const Center(child: Text('No matching corpus items.'));
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final alias = map.aliasFor(e.id);
        final tombstoned = map.isTombstoned(e.id);
        return ListTile(
          dense: true,
          leading: Icon(
            e.type == ReviewItemType.word
                ? Icons.text_fields_rounded
                : Icons.notes_rounded,
            size: 20,
          ),
          title: Text(e.id, style: const TextStyle(fontSize: 13)),
          subtitle: alias != null
              ? Text(
                  'alias → ${alias.to}',
                  style: const TextStyle(fontSize: 11),
                )
              : (tombstoned
                    ? const Text('retired', style: TextStyle(fontSize: 11))
                    : null),
          trailing: tombstoned
              ? const Icon(Icons.delete_forever_rounded, color: Colors.red)
              : const Icon(Icons.chevron_right_rounded),
          enabled: !tombstoned,
          onTap: tombstoned
              ? null
              : () => Navigator.pop(
                  context,
                  CorpusPick(itemId: e.id, itemType: e.type),
                ),
        );
      },
    );
  }
}
