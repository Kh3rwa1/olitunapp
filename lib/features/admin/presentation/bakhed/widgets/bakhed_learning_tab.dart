import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../controllers/bakhed_editor_controller.dart';

import '../../widgets/media_picker_field.dart';

/// Learning tab of the Bakhed editor: vocabulary and cultural notes.
class BakhedLearningTab extends ConsumerWidget {
  final String bakhedId;
  const BakhedLearningTab({super.key, required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabState = ref.watch(bakhedVocabularyEditorProvider(bakhedId));
    final notesState = ref.watch(bakhedNotesEditorProvider(bakhedId));

    if (!vocabState.isLoaded || !notesState.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // Vocabulary list section
        BakhedVocabularyCard(bakhedId: bakhedId),
        const SizedBox(height: 24),

        // Cultural Notes list section
        BakhedCulturalNotesCard(bakhedId: bakhedId),
      ],
    );
  }
}

class BakhedVocabularyCard extends ConsumerWidget {
  final String bakhedId;
  const BakhedVocabularyCard({super.key, required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(bakhedVocabularyEditorProvider(bakhedId));
    final notifier = ref.read(
      bakhedVocabularyEditorProvider(bakhedId).notifier,
    );

    return Card(
      color: AdminTokens.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        side: BorderSide(color: AdminTokens.border(isDark)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vocabulary List',
                  style: AdminTokens.sectionTitle(isDark),
                ),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Add Word',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    final newIdx = state.currentItems.length;
                    final newItem = BakhedVocabularyItem(
                      id: '',
                      olChiki: '',
                      latin: '',
                      meaning: '',
                      audioFileId: '',
                      sortOrder: newIdx,
                    );
                    notifier.addItem(newItem);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (state.currentItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No vocabulary words added yet.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.currentItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.currentItems[index];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminTokens.base(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Row(
                      children: [
                        // Index
                        Text(
                          '${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),

                        // Ol Chiki field
                        Expanded(
                          child: TextFormField(
                            initialValue: item.olChiki,
                            decoration: const InputDecoration(
                              labelText: 'Ol Chiki',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final items = List<BakhedVocabularyItem>.from(
                                state.currentItems,
                              );
                              items[index] = items[index].copyWith(
                                olChiki: val,
                              );
                              notifier.updateItems(items);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Latin transliteration
                        Expanded(
                          child: TextFormField(
                            initialValue: item.latin,
                            decoration: const InputDecoration(
                              labelText: 'Latin',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final items = List<BakhedVocabularyItem>.from(
                                state.currentItems,
                              );
                              items[index] = items[index].copyWith(latin: val);
                              notifier.updateItems(items);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Meaning
                        Expanded(
                          child: TextFormField(
                            initialValue: item.meaning,
                            decoration: const InputDecoration(
                              labelText: 'Meaning',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final items = List<BakhedVocabularyItem>.from(
                                state.currentItems,
                              );
                              items[index] = items[index].copyWith(
                                meaning: val,
                              );
                              notifier.updateItems(items);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Audio file picker / field (pronunciation)
                        SizedBox(
                          width: 150,
                          child: MediaPickerField(
                            label: 'Pronunciation',
                            kind: ContentMediaKind.audio,
                            value: item.audioFileId.isNotEmpty
                                // Using a simplified wrapper
                                ? ContentMedia(
                                    url: '',
                                    fileId: item.audioFileId,
                                    kind: ContentMediaKind.audio,
                                  )
                                : null,
                            onRemove: (fileId) {
                              ref
                                  .read(
                                    bakhedEditorControllerProvider(
                                      bakhedId,
                                    ).notifier,
                                  )
                                  .markForDeletion(fileId);
                            },
                            onChanged: (media) {
                              final items = List<BakhedVocabularyItem>.from(
                                state.currentItems,
                              );
                              items[index] = items[index].copyWith(
                                audioFileId: media?.fileId ?? '',
                              );
                              notifier.updateItems(items);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Delete
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              notifier.removeItem(item.id, item.sortOrder),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class BakhedCulturalNotesCard extends ConsumerWidget {
  final String bakhedId;
  const BakhedCulturalNotesCard({super.key, required this.bakhedId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(bakhedNotesEditorProvider(bakhedId));
    final notifier = ref.read(bakhedNotesEditorProvider(bakhedId).notifier);

    return Card(
      color: AdminTokens.raised(isDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        side: BorderSide(color: AdminTokens.border(isDark)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cultural Notes & Context',
                  style: AdminTokens.sectionTitle(isDark),
                ),
                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Add Note',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    const newNote = BakhedCulturalNote(
                      noteId: '',
                      title: '',
                      body: '',
                      source: '',
                      isPublished: true,
                    );
                    notifier.addNote(newNote);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (state.currentNotes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No cultural notes added yet.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.currentNotes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final note = state.currentNotes[index];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AdminTokens.base(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      border: Border.all(color: AdminTokens.border(isDark)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Index
                            Text(
                              'Note #${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),

                            // Publish Switch
                            Row(
                              children: [
                                Switch(
                                  value: note.isPublished,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: (val) {
                                    final notes = List<BakhedCulturalNote>.from(
                                      state.currentNotes,
                                    );
                                    notes[index] = notes[index].copyWith(
                                      isPublished: val,
                                    );
                                    notifier.updateNotes(notes);
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Published',
                                  style: AdminTokens.label(isDark),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Delete note
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                              onPressed: () => notifier.removeNote(note.noteId),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title field
                        TextFormField(
                          initialValue: note.title,
                          decoration: const InputDecoration(
                            labelText: 'Note Title*',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final notes = List<BakhedCulturalNote>.from(
                              state.currentNotes,
                            );
                            notes[index] = notes[index].copyWith(title: val);
                            notifier.updateNotes(notes);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Source field
                        TextFormField(
                          initialValue: note.source,
                          decoration: const InputDecoration(
                            labelText: 'Source / Author',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            final notes = List<BakhedCulturalNote>.from(
                              state.currentNotes,
                            );
                            notes[index] = notes[index].copyWith(source: val);
                            notifier.updateNotes(notes);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Body field (markdown rich text)
                        TextFormField(
                          initialValue: note.body,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Note Body (Markdown Support)*',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (val) {
                            final notes = List<BakhedCulturalNote>.from(
                              state.currentNotes,
                            );
                            notes[index] = notes[index].copyWith(body: val);
                            notifier.updateNotes(notes);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
