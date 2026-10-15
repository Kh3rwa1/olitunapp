import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/models/content_item.dart';
import '../../../../../shared/providers/bakhed_content_provider.dart';

/// Playback-derived values shared by every Premium Bakhed layout.
@immutable
class PremiumBakhedPlaybackView {
  const PremiumBakhedPlaybackView({
    required this.item,
    required this.accentColor,
    required this.speed,
    required this.isPlaying,
    required this.durationMs,
    required this.positionMs,
    required this.hasValidDuration,
    required this.maxSliderVal,
    required this.currentSliderVal,
  });

  final ContentItem item;
  final Color accentColor;
  final double speed;
  final bool isPlaying;
  final int durationMs;
  final int positionMs;
  final bool hasValidDuration;
  final double maxSliderVal;
  final double currentSliderVal;
}

/// Learning-surface inputs (lyrics / vocabulary / notes) plus the sub-tab
/// selection owned by the Premium Bakhed body state.
@immutable
class PremiumBakhedLearningView {
  const PremiumBakhedLearningView({
    required this.learningContentAsync,
    required this.hasLyrics,
    required this.hasVocab,
    required this.hasNotes,
    required this.activeSubTab,
    required this.onSelectSubTab,
    required this.lyricScroll,
  });

  final AsyncValue<BakhedLearningContent?> learningContentAsync;
  final bool hasLyrics;
  final bool hasVocab;
  final bool hasNotes;

  /// 0 = Lyrics, 1 = Vocab, 2 = Cultural Notes.
  final int activeSubTab;
  final ValueChanged<int> onSelectSubTab;
  final PremiumBakhedLyricScroll lyricScroll;
}

/// Synced-lyrics auto-scroll state. Owned (and disposed) by the body state so
/// it survives sub-tab and layout switches.
class PremiumBakhedLyricScroll {
  final ScrollController controller = ScrollController();

  /// Index of the lyric line the list last auto-scrolled to.
  int lastActiveIndex = -1;

  void dispose() => controller.dispose();
}
