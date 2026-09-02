// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/accessibility/learning_semantics.dart';
import 'package:itun/core/motion/confetti_overlay.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/models/content_item.dart';

part 'tracing_canvas_painters.dart';

class TracingCanvas extends ConsumerStatefulWidget {
  final TracingConfig config;
  final ValueChanged<int>? onCompleted;
  final Color accentColor;

  const TracingCanvas({
    super.key,
    required this.config,
    this.onCompleted,
    this.accentColor = AppColors.primary,
  });

  @override
  ConsumerState<TracingCanvas> createState() => _TracingCanvasState();
}

class _TracingCanvasState extends ConsumerState<TracingCanvas>
    with TickerProviderStateMixin {
  int _activeStrokeIndex = 0;
  int _currentCompletions = 0;
  bool _showConfetti = false;

  // Active user points for current stroke (raw canvas offsets)
  final List<Offset> _currentRawPoints = [];
  // History of completed strokes (normalized points)
  final List<List<Offset>> _completedStrokes = [];

  // Example animation controllers
  late AnimationController _exampleController;
  bool _isPlayingExample = false;
  int _exampleStrokeIndex = 0;

  @override
  void initState() {
    super.initState();
    _exampleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exampleController.addListener(() {
      setState(() {});
    });
    _exampleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _playNextExampleStroke();
      }
    });
  }

  @override
  void dispose() {
    _exampleController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _activeStrokeIndex = 0;
      _currentRawPoints.clear();
      _completedStrokes.clear();
      _isPlayingExample = false;
      _exampleController.stop();
    });
  }

  void _showExample() {
    _reset();
    setState(() {
      _isPlayingExample = true;
      _exampleStrokeIndex = 0;
    });
    _playNextExampleStroke();
  }

  void _playNextExampleStroke() {
    if (!_isPlayingExample) return;
    if (_exampleStrokeIndex < widget.config.strokes.length) {
      _exampleController.reset();
      _exampleController.forward();
      setState(() {});
      _exampleStrokeIndex++;
    } else {
      setState(() {
        _isPlayingExample = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Column(
              children: [
                // Header Panel
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tracing practice — ${widget.config.glyph}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Trace the character guidelines accurately',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Mastery: $_currentCompletions/${widget.config.requiredCompletions}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Canvas Area
                AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );

                      return Semantics(
                        container: true,
                        image: true,
                        label: LearningSemantics.tracingPrompt(
                          glyph: widget.config.glyph,
                        ),
                        hint: 'Double-tap to replay example stroke order',
                        onTap: _showExample,
                        customSemanticsActions:
                            <CustomSemanticsAction, VoidCallback>{
                              const CustomSemanticsAction(
                                label: 'Replay example stroke order',
                              ): _showExample,
                            },
                        child: GestureDetector(
                          onPanStart: _isPlayingExample
                              ? null
                              : (details) => _onPanStart(details, size),
                          onPanUpdate: _isPlayingExample
                              ? null
                              : (details) => _onPanUpdate(details, size),
                          onPanEnd: _isPlayingExample
                              ? null
                              : (details) => _onPanEnd(details, size),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _TracingPainter(
                              config: widget.config,
                              activeStrokeIndex: _activeStrokeIndex,
                              currentRawPoints: _currentRawPoints,
                              completedStrokes: _completedStrokes,
                              accentColor: widget.accentColor,
                              isDark: isDark,
                              exampleProgress: _isPlayingExample
                                  ? _exampleController.value
                                  : 0.0,
                              exampleStrokeIndex: _isPlayingExample
                                  ? _exampleStrokeIndex - 1
                                  : -1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 1),
                // Footer buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _showExample,
                        icon: const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 20,
                        ),
                        label: const Text('Show example'),
                        style: TextButton.styleFrom(
                          foregroundColor: widget.accentColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Reset',
                        style: IconButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Confettiburst trigger overlay
            if (_showConfetti)
              const Positioned.fill(
                child: AbsorbPointer(child: ConfettiBurst(particleCount: 60)),
              ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details, Size size) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentRawPoints.clear();
      _currentRawPoints.add(details.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      _currentRawPoints.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    if (_currentRawPoints.length < 2) {
      setState(_currentRawPoints.clear);
      return;
    }

    // Current expected target stroke
    if (_activeStrokeIndex >= widget.config.strokes.length) return;
    final expectedStroke = widget.config.strokes[_activeStrokeIndex];

    // Normalize user drawn points relative to canvas dimensions
    final normalizedUserPoints = _currentRawPoints.map((p) {
      return Offset(
        (p.dx / size.width).clamp(0.0, 1.0),
        (p.dy / size.height).clamp(0.0, 1.0),
      );
    }).toList();

    // Sample expectations vs user drawn path
    const int sampleCount = 30;
    final userSampled = _sampleUserPoints(normalizedUserPoints, sampleCount);
    final expectedSampled = _sampleStroke(expectedStroke, sampleCount);

    final avgDist = _calculateAverageDistance(userSampled, expectedSampled);

    // Check match criteria (scale threshold relative to tolerance)
    final double threshold = 0.15 * (1.0 + (1.0 - widget.config.tolerance));

    if (avgDist < threshold) {
      // Successful match
      HapticFeedback.mediumImpact();
      setState(() {
        _completedStrokes.add(normalizedUserPoints);
        _currentRawPoints.clear();
        _activeStrokeIndex++;

        // Verify if full character is successfully traced
        if (_activeStrokeIndex >= widget.config.strokes.length) {
          _currentCompletions++;
          widget.onCompleted?.call(_currentCompletions);

          if (_currentCompletions >= widget.config.requiredCompletions) {
            _showConfetti = true;

            // Trigger success audio
            if (widget.config.playAudioOnComplete &&
                widget.config.audioOnCompleteUrl != null) {
              ref
                  .read(playbackControllerProvider)
                  .playSingle(
                    id: widget.config.audioOnCompleteUrl!,
                    contentKind: 'letter',
                    contentId: widget.config.glyph,
                    trackType: 'targetNormal',
                    languageCode: 'sat',
                  );
            }

            // Fire learning analytics completion event
            ref
                .read(learningAnalyticsServiceProvider)
                .track(
                  'tracing_completed',
                  source: 'tracing_canvas',
                  sourceId: widget.config.glyph,
                  metadata: {
                    'glyph': widget.config.glyph,
                    'completions': _currentCompletions,
                  },
                );

            // Turn off confetti after a delay
            Timer(const Duration(milliseconds: 2000), () {
              if (mounted) {
                setState(() {
                  _showConfetti = false;
                });
              }
            });
          } else {
            // Clean active strokes for next mastery repetition
            _activeStrokeIndex = 0;
            _completedStrokes.clear();
          }
        }
      });
    } else {
      // Rejection
      setState(_currentRawPoints.clear);
    }
  }

  List<Offset> _sampleStroke(TracingStroke stroke, int count) {
    final List<Offset> points = [];
    if (stroke.path.length < 2) return points;

    final bool hasControlPoints = stroke.path.any((p) => p.isControlPoint);

    if (hasControlPoints && stroke.path.length >= 4) {
      final p0 = Offset(stroke.path[0].x, stroke.path[0].y);
      final p1 = Offset(stroke.path[1].x, stroke.path[1].y);
      final p2 = Offset(stroke.path[2].x, stroke.path[2].y);
      final p3 = Offset(stroke.path[3].x, stroke.path[3].y);

      for (int i = 0; i < count; i++) {
        final t = i / (count - 1);
        final mt = 1.0 - t;
        final x =
            mt * mt * mt * p0.dx +
            3.0 * mt * mt * t * p1.dx +
            3.0 * mt * t * t * p2.dx +
            t * t * t * p3.dx;
        final y =
            mt * mt * mt * p0.dy +
            3.0 * mt * mt * t * p1.dy +
            3.0 * mt * t * t * p2.dy +
            t * t * t * p3.dy;
        points.add(Offset(x, y));
      }
    } else {
      for (int s = 0; s < stroke.path.length - 1; s++) {
        final p0 = Offset(stroke.path[s].x, stroke.path[s].y);
        final p1 = Offset(stroke.path[s + 1].x, stroke.path[s + 1].y);
        final stepCount = count ~/ (stroke.path.length - 1);

        for (int i = 0; i < stepCount; i++) {
          final t = i / (stepCount - 1);
          final x = p0.dx + t * (p1.dx - p0.dx);
          final y = p0.dy + t * (p1.dy - p0.dy);
          points.add(Offset(x, y));
        }
      }
    }
    return points;
  }

  List<Offset> _sampleUserPoints(List<Offset> userPoints, int count) {
    final List<Offset> sampled = [];
    if (userPoints.length < 2) return userPoints;

    for (int i = 0; i < count; i++) {
      final double t = i / (count - 1);
      final double indexFloat = t * (userPoints.length - 1);
      final int index = indexFloat.floor();
      final double frac = indexFloat - index;

      if (index >= userPoints.length - 1) {
        sampled.add(userPoints.last);
      } else {
        final p0 = userPoints[index];
        final p1 = userPoints[index + 1];
        final x = p0.dx + frac * (p1.dx - p0.dx);
        final y = p0.dy + frac * (p1.dy - p0.dy);
        sampled.add(Offset(x, y));
      }
    }
    return sampled;
  }

  double _calculateAverageDistance(List<Offset> pathA, List<Offset> pathB) {
    if (pathA.length != pathB.length || pathA.isEmpty) return 1.0;
    double totalDistance = 0.0;
    for (int i = 0; i < pathA.length; i++) {
      final diff = pathA[i] - pathB[i];
      totalDistance += diff.distance;
    }
    return totalDistance / pathA.length;
  }
}
