import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/shared/widgets/state_widgets.dart';
import 'package:itun/core/motion/pressable_scale.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/core/logging/app_logger.dart';

class ContentGridScreen extends ConsumerStatefulWidget {
  final ContentKind kind;
  final String? subcategoryId;

  const ContentGridScreen({super.key, required this.kind, this.subcategoryId});

  @override
  ConsumerState<ContentGridScreen> createState() => _ContentGridScreenState();
}

class _ContentGridScreenState extends ConsumerState<ContentGridScreen>
    with WidgetsBindingObserver {
  late final AudioService _audioService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioService = ref.read(audioServiceProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _audioService.stop();
    }
  }

  void _handleTilePlay(ContentItem item) {
    if (item.audioUrl == null || item.audioUrl!.isEmpty) {
      // Fail-silently (no logs, no haptics, no-op)
      return;
    }
    try {
      HapticFeedback.lightImpact();
      _audioService.playUrl(item.audioUrl!);
    } catch (e) {
      AppLogger.debug('Warning playing audio in grid tile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(
      contentListProvider((widget.kind, widget.subcategoryId)),
    );

    final categories = ref.watch(categoryNotifierProvider).valueOrNull ?? [];
    CategoryEntity? category;
    if (widget.subcategoryId != null) {
      for (final cat in categories) {
        if (cat.id == widget.subcategoryId) {
          category = cat;
          break;
        }
      }
    }

    final categoryTitle = category?.titleLatin;

    final String defaultTitle = widget.kind == ContentKind.letter
        ? 'Alphabets'
        : 'Numbers';
    final String appBarTitle = categoryTitle != null
        ? '$categoryTitle - $defaultTitle'
        : defaultTitle;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          appBarTitle,
          style: GoogleFonts.fredoka(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: listAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return AppEmptyState(
              title: 'No items found',
              description:
                  'We couldn\'t find any ${widget.kind.name}s in this section.',
            );
          }

          final width = MediaQuery.of(context).size.width;
          final int crossAxisCount = width >= 600 ? 6 : 4;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ContentGridTile(
                item: item,
                onTap: () => _handleTilePlay(item),
              );
            },
          );
        },
        loading: () => const AppLoadingState(type: AppLoadingType.page),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () {
            ref.invalidate(
              contentListProvider((widget.kind, widget.subcategoryId)),
            );
          },
        ),
      ),
    );
  }
}

class _ContentGridTile extends ConsumerWidget {
  final ContentItem item;
  final VoidCallback onTap;

  const _ContentGridTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showTraceIcon = item.tracing != null && item.olChiki != null;

    final String glyphText = item.olChiki ?? item.title;

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Center Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    glyphText,
                    style: TextStyle(
                      fontSize: item.olChiki != null ? 36 : 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                      fontFamily: 'OlChiki',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: GoogleFonts.fredoka(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Top-right conditional tracing icon
            if (showTraceIcon)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    // Navigate to practice screen in trace mode
                    context.push(
                      '/practice/${Uri.encodeComponent(item.olChiki!)}/${Uri.encodeComponent(item.title)}?mode=trace',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gesture_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
