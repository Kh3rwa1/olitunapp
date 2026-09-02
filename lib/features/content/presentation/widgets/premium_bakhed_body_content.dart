// ignore_for_file: deprecated_member_use
part of 'premium_bakhed_body.dart';

/// Lyrics / vocabulary / cultural-notes panel builders for
/// [_PremiumBakhedBodyState], extracted into this library part.
extension _PremiumBakhedBodyContentPanels on _PremiumBakhedBodyState {
  Widget _buildCulturalNotes(List<BakhedCulturalNote> notes) {
    final publishedNotes = notes.where((n) => n.isPublished).toList();
    if (publishedNotes.isEmpty) {
      return Center(
        child: Text(
          'Cultural notes are being prepared.',
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
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
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
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              if (note.source.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Colors.white10),
                const SizedBox(height: 4),
                Text(
                  'Source: ${note.source}',
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

  Widget _buildVocabularyList(
    List<BakhedVocabularyItem> vocabulary,
    Color accentColor,
  ) {
    if (vocabulary.isEmpty) {
      return Center(
        child: Text(
          'No vocabulary items defined.',
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
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
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
                Container(
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: accentColor),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      final db = ref.read(appwriteDbServiceProvider);
                      final url = db.getFileViewUrl('audio', item.audioFileId);
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildSyncedLyrics(
    List<BakhedLyricLine> lyrics,
    ContentItem item,
    int positionMs,
    Color accentColor,
  ) {
    if (lyrics.isEmpty) {
      // Fallback: render the item's standard blocks (e.g. text/translation) in a premium way
      final textBlocks = item.blocks.whereType<TextBlock>().toList();
      if (textBlocks.isEmpty) {
        return Center(
          child: Text(
            'Lyrics are being added.',
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
    if (activeIndex != _lastActiveIndex) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_lyricScrollController.hasClients && activeIndex >= 0) {
          final targetOffset = (activeIndex * 105.0) - 100.0;
          _lyricScrollController.animateTo(
            targetOffset.clamp(
              0.0,
              _lyricScrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }

    return ListView.builder(
      controller: _lyricScrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final line = lyrics[index];
        final isActive = index == activeIndex;

        return GestureDetector(
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
              margin: const EdgeInsets.only(bottom: 24.0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.03)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isActive
                    ? Border.all(color: Colors.white.withOpacity(0.05))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.olChiki,
                    style: TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: isActive ? 26 : 23,
                      fontWeight: FontWeight.bold,
                      color: isActive ? AppColors.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    line.latin,
                    style: AppTypography.inter(
                      fontSize: isActive ? 16 : 15,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.white70,
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
        );
      },
    );
  }
}
