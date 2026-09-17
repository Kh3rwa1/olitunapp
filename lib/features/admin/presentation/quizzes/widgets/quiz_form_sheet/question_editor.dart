import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/models/content_models.dart' hide CategoryModel;
import '../../../../../quiz/domain/quiz_identity_validation.dart';
import '../../../../../review/domain/review_corpus_identity.dart';
import '../../../../../review/domain/review_item.dart';
import '../../../widgets/admin_form_widgets.dart';
import 'option_editor.dart';
import 'quiz_validation.dart';

/// Full question editor supporting MCQ and Fill-in-the-blank
class QuestionEditorSheet extends ConsumerStatefulWidget {
  final QuizQuestion? question;
  final ValueChanged<QuizQuestion> onSave;
  const QuestionEditorSheet({super.key, this.question, required this.onSave});

  @override
  ConsumerState<QuestionEditorSheet> createState() =>
      _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends ConsumerState<QuestionEditorSheet> {
  String _type = 'mcq';

  // MCQ fields
  late final TextEditingController _promptOlChiki;
  late final TextEditingController _promptLatin;
  late final TextEditingController _explanation;
  late final List<TextEditingController> _optOlChikiCtrls;
  late final List<TextEditingController> _optLatinCtrls;
  int _correctIndex = 0;

  // Fill-in-blank fields
  late final TextEditingController _blankOlChiki;
  late final TextEditingController _blankLatin;
  late final TextEditingController _correctAnswer;
  late final List<TextEditingController> _distractorCtrls;

  // Canonical learning item attribution
  late final TextEditingController _sourceWordId;
  late final TextEditingController _sourceSentenceId;
  late bool _isNonMemory;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _type = q?.type ?? 'mcq';
    _promptOlChiki = TextEditingController(text: q?.promptOlChiki ?? '');
    _promptLatin = TextEditingController(text: q?.promptLatin ?? '');
    _explanation = TextEditingController(text: q?.explanation ?? '');
    _correctIndex = q?.correctIndex ?? 0;

    _optOlChikiCtrls = List.generate(
      4,
      (i) => TextEditingController(
        text: i < (q?.optionsOlChiki.length ?? 0) ? q!.optionsOlChiki[i] : '',
      ),
    );
    _optLatinCtrls = List.generate(
      4,
      (i) => TextEditingController(
        text: i < (q?.optionsLatin.length ?? 0) ? q!.optionsLatin[i] : '',
      ),
    );

    _blankOlChiki = TextEditingController(text: q?.blankSentenceOlChiki ?? '');
    _blankLatin = TextEditingController(text: q?.blankSentenceLatin ?? '');
    _correctAnswer = TextEditingController(text: q?.correctAnswer ?? '');
    _distractorCtrls = List.generate(
      3,
      (i) => TextEditingController(
        text: i < (q?.distractors.length ?? 0) ? q!.distractors[i] : '',
      ),
    );

    _sourceWordId = TextEditingController(text: q?.sourceWordId ?? '');
    _sourceSentenceId = TextEditingController(text: q?.sourceSentenceId ?? '');
    _isNonMemory =
        q?.isNonMemory ??
        (q?.sourceWordId == null && q?.sourceSentenceId == null);
    // Refresh the live attribution status line while typing.
    _sourceWordId.addListener(_onAttributionChanged);
    _sourceSentenceId.addListener(_onAttributionChanged);
  }

  void _onAttributionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sourceWordId.removeListener(_onAttributionChanged);
    _sourceSentenceId.removeListener(_onAttributionChanged);
    _promptOlChiki.dispose();
    _promptLatin.dispose();
    _explanation.dispose();
    for (final c in _optOlChikiCtrls) {
      c.dispose();
    }
    for (final c in _optLatinCtrls) {
      c.dispose();
    }
    _blankOlChiki.dispose();
    _blankLatin.dispose();
    _correctAnswer.dispose();
    for (final c in _distractorCtrls) {
      c.dispose();
    }
    _sourceWordId.dispose();
    _sourceSentenceId.dispose();
    super.dispose();
  }

  void _save() {
    HapticFeedback.lightImpact();
    final wordId = _sourceWordId.text.trim().isNotEmpty
        ? _sourceWordId.text.trim()
        : null;
    final sentenceId = _sourceSentenceId.text.trim().isNotEmpty
        ? _sourceSentenceId.text.trim()
        : null;
    final QuizQuestion questionToSave;
    if (_type == 'fill_blank') {
      questionToSave = QuizQuestion(
        type: 'fill_blank',
        promptOlChiki: _promptOlChiki.text.trim(),
        promptLatin: _promptLatin.text.trim().isNotEmpty
            ? _promptLatin.text.trim()
            : null,
        blankSentenceOlChiki: _blankOlChiki.text.trim(),
        blankSentenceLatin: _blankLatin.text.trim(),
        correctAnswer: _correctAnswer.text.trim(),
        distractors: _distractorCtrls
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        explanation: _explanation.text.trim().isNotEmpty
            ? _explanation.text.trim()
            : null,
        sourceWordId: wordId,
        sourceSentenceId: sentenceId,
        isNonMemory: _isNonMemory,
      );
    } else {
      questionToSave = QuizQuestion(
        promptOlChiki: _promptOlChiki.text.trim(),
        promptLatin: _promptLatin.text.trim().isNotEmpty
            ? _promptLatin.text.trim()
            : null,
        optionsOlChiki: _optOlChikiCtrls.map((c) => c.text.trim()).toList(),
        optionsLatin: _optLatinCtrls.map((c) => c.text.trim()).toList(),
        correctIndex: _correctIndex,
        explanation: _explanation.text.trim().isNotEmpty
            ? _explanation.text.trim()
            : null,
        sourceWordId: wordId,
        sourceSentenceId: sentenceId,
        isNonMemory: _isNonMemory,
      );
    }

    // Structural gate (always enforced, offline-safe).
    final error = QuizValidation.validateQuestionIdentity(questionToSave);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Corpus gate (enforced when the verified map is available; otherwise
    // the publish boundary fails closed and this save carries an explicit
    // unverified note).
    final corpusMap = ref.read(corpusIdentityMapProvider).valueOrNull;
    if (corpusMap != null &&
        corpusMap.availabilityState !=
            CorpusAvailabilityState.corpusUnavailable) {
      final strict = validateQuestionIdentity(
        questionToSave,
        corpusMap: corpusMap,
      );
      if (!strict.isPublishable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strict.message ?? 'Invalid corpus identity.')),
        );
        return;
      }
      if (strict.resolvedViaAlias) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Note: ID resolves via alias to canonical '
              '"${strict.canonicalId}". Saved with the canonical link.',
            ),
          ),
        );
      }
    }

    widget.onSave(questionToSave);
    Navigator.pop(context);
  }

  Future<void> _browseCorpus() async {
    final picked = await showModalBottomSheet<_CorpusPick>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CorpusPickerSheet(),
    );
    if (picked == null) return;
    setState(() {
      if (picked.isNonMemory) {
        _isNonMemory = true;
        _sourceWordId.clear();
        _sourceSentenceId.clear();
      } else if (picked.itemType == ReviewItemType.word) {
        _isNonMemory = false;
        _sourceWordId.text = picked.itemId;
        _sourceSentenceId.clear();
      } else {
        _isNonMemory = false;
        _sourceSentenceId.text = picked.itemId;
        _sourceWordId.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AdminTokens.overlay(isDark),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AdminTokens.radius2xl),
        ),
        boxShadow: AdminTokens.overlayShadow(isDark),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AdminTokens.borderStrong(isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: AppColors.premiumCyan,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  widget.question != null ? 'Edit Question' : 'Add Question',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close question editor',
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AdminTokens.divider(isDark)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Type selector
                Text('Question Type', style: AdminTokens.label(isDark)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TypeChip(
                        label: 'Multiple Choice',
                        icon: Icons.radio_button_checked_rounded,
                        selected: _type == 'mcq',
                        onTap: () => setState(() => _type = 'mcq'),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TypeChip(
                        label: 'Fill in Blank',
                        icon: Icons.text_fields_rounded,
                        selected: _type == 'fill_blank',
                        onTap: () => setState(() => _type = 'fill_blank'),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AdminTextField(
                  controller: _promptOlChiki,
                  label: _type == 'fill_blank'
                      ? 'Instruction (Ol Chiki)'
                      : 'Prompt (Ol Chiki)',
                  hint: _type == 'fill_blank'
                      ? 'e.g., Fill the blank:'
                      : 'e.g., ᱚ',
                ),
                const SizedBox(height: 14),
                AdminTextField(
                  controller: _promptLatin,
                  label: _type == 'fill_blank'
                      ? 'Instruction (Latin)'
                      : 'Prompt (Latin)',
                  hint: _type == 'fill_blank'
                      ? 'e.g., Complete the sentence:'
                      : 'Which sound does this letter make?',
                ),
                const SizedBox(height: 20),
                if (_type == 'mcq')
                  McqOptionEditor(
                    isDark: isDark,
                    correctIndex: _correctIndex,
                    onCorrectIndexChanged: (i) =>
                        setState(() => _correctIndex = i),
                    optOlChikiCtrls: _optOlChikiCtrls,
                    optLatinCtrls: _optLatinCtrls,
                  )
                else
                  FillBlankOptionEditor(
                    isDark: isDark,
                    blankOlChiki: _blankOlChiki,
                    blankLatin: _blankLatin,
                    correctAnswer: _correctAnswer,
                    distractorCtrls: _distractorCtrls,
                  ),
                const SizedBox(height: 14),
                AdminTextField(
                  controller: _explanation,
                  label: 'Explanation (optional)',
                  hint: 'Why this is correct',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile.adaptive(
                    value: _isNonMemory,
                    onChanged: (v) => setState(() => _isNonMemory = v),
                    title: Text(
                      'Non-Memory Question',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AdminTokens.textPrimary(isDark),
                      ),
                    ),
                    subtitle: Text(
                      'Exclude from spaced repetition memory scheduler',
                      style: TextStyle(
                        fontSize: 12,
                        color: AdminTokens.textTertiary(isDark),
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (!_isNonMemory) ...[
                  const SizedBox(height: 8),
                  _CorpusAttributionStatus(
                    wordId: _sourceWordId.text,
                    sentenceId: _sourceSentenceId.text,
                  ),
                  const SizedBox(height: 8),
                  AdminTextField(
                    controller: _sourceWordId,
                    label: 'Source Word ID (optional)',
                    hint: 'e.g. w_ol_chiki_1',
                  ),
                  const SizedBox(height: 10),
                  AdminTextField(
                    controller: _sourceSentenceId,
                    label: 'Source Sentence ID (optional)',
                    hint: 'e.g. s_daily_life_1',
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _browseCorpus,
                      icon: const Icon(Icons.library_books_rounded, size: 18),
                      label: const Text('Browse verified corpus'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick exactly one verified item instead of typing a raw ID. '
                    'Aliases resolve with a warning; retired IDs are blocked.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AdminTokens.textTertiary(isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: AdminTokens.baseTint(isDark),
              border: Border(
                top: BorderSide(color: AdminTokens.divider(isDark)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: AdminSecondaryButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AdminPrimaryButton(
                      label: 'Save Question',
                      icon: Icons.check_rounded,
                      onTap: _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const TypeChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AdminTokens.sunken(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AdminTokens.border(isDark),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? AppColors.primary
                  : AdminTokens.textTertiary(isDark),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : AdminTokens.textSecondary(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Result of the corpus picker: either a verified item or an explicit
/// non-memory decision.
class _CorpusPick {
  final String itemId;
  final ReviewItemType itemType;
  final bool isNonMemory;
  const _CorpusPick({required this.itemId, required this.itemType})
    : isNonMemory = false;
  const _CorpusPick.nonMemory()
    : itemId = '',
      itemType = ReviewItemType.word,
      isNonMemory = true;
}

/// Live attribution status under the ID fields: structural errors, alias
/// resolution warnings, and retired-ID warnings — before save is attempted.
class _CorpusAttributionStatus extends ConsumerWidget {
  final String wordId;
  final String sentenceId;
  const _CorpusAttributionStatus({
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
class _CorpusPickerSheet extends ConsumerStatefulWidget {
  const _CorpusPickerSheet();

  @override
  ConsumerState<_CorpusPickerSheet> createState() => _CorpusPickerSheetState();
}

class _CorpusPickerSheetState extends ConsumerState<_CorpusPickerSheet> {
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
                        Navigator.pop(context, const _CorpusPick.nonMemory()),
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
                  _CorpusPick(itemId: e.id, itemType: e.type),
                ),
        );
      },
    );
  }
}
