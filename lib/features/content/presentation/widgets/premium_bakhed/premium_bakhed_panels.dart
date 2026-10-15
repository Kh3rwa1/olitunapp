import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/theme/app_typography.dart';

import '../../../../../core/storage/worker_media_api.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/models/content_item.dart';
import '../../../../../shared/providers/bakhed_content_provider.dart';
import '../../../../rhymes/presentation/providers/rhyme_audio_provider.dart';
import '../../providers/audio_playback_providers.dart';
import 'premium_bakhed_view_data.dart';

/// Resolves the requested sub-tab to one that actually has content.
int effectiveBakhedSubTab(
  int activeSubTab, {
  required bool hasLyrics,
  required bool hasVocab,
  required bool hasNotes,
}) {
  if (activeSubTab == 0 && hasLyrics) return 0;
  if (activeSubTab == 1 && hasVocab) return 1;
  if (activeSubTab == 2 && hasNotes) return 2;
  if (hasLyrics) return 0;
  if (hasVocab) return 1;
  if (hasNotes) return 2;
  return 0;
}

/// Learning surface: loading / error / empty states, then the active panel.
class PremiumBakhedContentSurface extends StatelessWidget {
  const PremiumBakhedContentSurface({
    super.key,
    required this.learning,
    required this.item,
    required this.positionMs,
    required this.accentColor,
  });

  final PremiumBakhedLearningView learning;
  final ContentItem item;
  final int positionMs;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return learning.learningContentAsync.when(
      data: (content) {
        if (content == null) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noLearningContent,
              style: AppTypography.inter(color: Colors.white38, fontSize: 14),
            ),
          );
        }
        final subTab = effectiveBakhedSubTab(
          learning.activeSubTab,
          hasLyrics: learning.hasLyrics,
          hasVocab: learning.hasVocab,
          hasNotes: learning.hasNotes,
        );
        switch (subTab) {
          case 0:
            return PremiumBakhedSyncedLyrics(
              lyrics: content.lyrics,
              item: item,
              positionMs: positionMs,
              accentColor: accentColor,
              lyricScroll: learning.lyricScroll,
            );
          case 1:
            return PremiumBakhedVocabularyList(
              vocabulary: content.vocabulary,
              accentColor: accentColor,
            );
          case 2:
            return PremiumBakhedCulturalNotes(notes: content.culturalNotes);
          default:
            return const SizedBox.shrink();
        }
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            AppLocalizations.of(context)!.errorLoadingDetails(err.toString()),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

/// Published cultural notes rendered as markdown cards.
class PremiumBakhedCulturalNotes extends StatelessWidget {
  const PremiumBakhedCulturalNotes({super.key, required this.notes});

  final List<BakhedCulturalNote> notes;

  @override
  Widget build(BuildContext context) {
    final publishedNotes = notes.where((n) => n.isPublished).toList();
    if (publishedNotes.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.culturalNotesPreparing,
          style: AppTypography.inter(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: publishedNotes.length,
      itemBuilder: (context, index) {
        final note = publishedNotes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_added_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: AppTypography.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MarkdownBody(
                data: note.body,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (note.source.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.culturalNoteSource(note.source),
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: Colors.white38,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Vocabulary cards with optional per-word audio.
class PremiumBakhedVocabularyList extends ConsumerWidget {
  const PremiumBakhedVocabularyList({
    super.key,
    required this.vocabulary,
    required this.accentColor,
  });

  final List<BakhedVocabularyItem> vocabulary;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vocabulary.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noVocabularyItems,
          style: AppTypography.inter(color: Colors.white38, fontSize: 15),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: vocabulary.length,
      itemBuilder: (context, index) {
        final item = vocabulary[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.olChiki,
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.latin,
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (item.meaning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.meaning,
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.audioFileId.isNotEmpty)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.volume_up_rounded, color: accentColor),
                      tooltip: 'Play audio',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final url = workerAssetUrl('audio', item.audioFileId);
                        ref
                            .read(playbackControllerProvider)
                            .playSingle(
                              id: url,
                              contentKind: 'rhyme',
                              contentId: item.id,
                              trackType: 'targetNormal',
                              languageCode: 'sat',
                            );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Time-synced lyrics that auto-scroll to the active line (falls back to the
/// item's text blocks when no synced lyrics exist).
class PremiumBakhedSyncedLyrics extends ConsumerWidget {
  const PremiumBakhedSyncedLyrics({
    super.key,
    required this.lyrics,
    required this.item,
    required this.positionMs,
    required this.accentColor,
    required this.lyricScroll,
  });

  final List<BakhedLyricLine> lyrics;
  final ContentItem item;
  final int positionMs;
  final Color accentColor;
  final PremiumBakhedLyricScroll lyricScroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lyrics.isEmpty) {
      // Fallback: render the item's standard blocks (e.g. text/translation) in a premium way
      final textBlocks = item.blocks.whereType<TextBlock>().toList();
      if (textBlocks.isEmpty) {
        return Center(
          child: Text(
            AppLocalizations.of(context)!.lyricsBeingAdded,
            style: AppTypography.inter(color: Colors.white38, fontSize: 15),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: textBlocks.length,
        itemBuilder: (context, index) {
          final block = textBlocks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.textOlChiki != null &&
                    block.textOlChiki!.isNotEmpty) ...[
                  Text(
                    block.textOlChiki!,
                    style: const TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  block.textLatin ?? block.markdown,
                  style: AppTypography.inter(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Find the active lyric line index
    int activeIndex = -1;
    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      if (positionMs >= line.startMs && positionMs <= line.endMs) {
        activeIndex = i;
        break;
      }
    }
    if (activeIndex == -1) {
      for (int i = lyrics.length - 1; i >= 0; i--) {
        if (positionMs >= lyrics[i].endMs) {
          activeIndex = i;
          break;
        }
      }
    }

    // Smooth auto-scroll to center
    if (activeIndex != lyricScroll.lastActiveIndex) {
      lyricScroll.lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (lyricScroll.controller.hasClients && activeIndex >= 0) {
          final targetOffset = (activeIndex * 105.0) - 100.0;
          lyricScroll.controller.animateTo(
            targetOffset.clamp(
              0.0,
              lyricScroll.controller.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }

    return ListView.builder(
      controller: lyricScroll.controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final line = lyrics[index];
        final isActive = index == activeIndex;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref
                  .read(rhymeAudioProvider.notifier)
                  .seek(Duration(milliseconds: line.startMs));
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isActive ? 1.0 : 0.45,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.04),
                    width: isActive ? 1.2 : 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            blurRadius: 18,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.olChiki,
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: isActive ? 26 : 22,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.primary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      line.latin,
                      style: AppTypography.inter(
                        fontSize: isActive ? 16 : 14.5,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isActive ? Colors.white : Colors.white70,
                      ),
                    ),
                    if (line.meaning.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        line.meaning,
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: Colors.white38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
