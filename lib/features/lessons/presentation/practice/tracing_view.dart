import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ol_chiki_glyph_guide.dart';
import 'practice_guide.dart';
import '../../data/ol_chiki_strokes.dart';

class TracingView extends StatefulWidget {
  final String letterChar;
  final VoidCallback? onComplete;

  const TracingView({super.key, required this.letterChar, this.onComplete});

  @override
  State<TracingView> createState() => _TracingViewState();
}

class _TracingViewState extends State<TracingView>
    with SingleTickerProviderStateMixin {
  final List<Offset?> _points = [];
  double _progress = 0;
  TraceScore _score = TraceScore.zero;
  bool _showCelebration = false;
  double? _lastBoardSize;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _clearCanvas() {
    HapticFeedback.lightImpact();
    setState(() {
      _points.clear();
      _progress = 0;
      _score = TraceScore.zero;
      _showCelebration = false;
    });
  }

  void _undoLastStroke() {
    if (_points.isEmpty) return;

    HapticFeedback.selectionClick();

    // Find the last null (stroke separator) and remove everything after it
    int lastNullIndex = -1;
    for (int i = _points.length - 2; i >= 0; i--) {
      if (_points[i] == null) {
        lastNullIndex = i;
        break;
      }
    }

    setState(() {
      if (lastNullIndex >= 0) {
        _points.removeRange(lastNullIndex, _points.length);
      } else {
        _points.clear();
      }
      _showCelebration = false;
    });

    // Recalculate progress after undo
    if (_points.isNotEmpty) {
      _recalculateProgressForUndo();
    } else {
      setState(() {
        _progress = 0;
        _score = TraceScore.zero;
      });
    }
  }

  void _recalculateProgressForUndo() {
    final boardSize = _lastBoardSize ?? 300;
    final size = Size.square(boardSize);
    final guidePath = buildPracticeGuidePath(size, widget.letterChar);
    final guidePoints = samplePath(guidePath, samplesPerMetric: 64);

    final score = computeTraceScore(
      guidePoints: guidePoints,
      tracedPoints: _points,
      tolerance: boardSize * 0.09,
    );

    setState(() {
      _score = score;
      _progress = score.overall;
    });
  }

  void _recalculateProgress(double boardSize) {
    _lastBoardSize = boardSize;
    final guidePath = buildPracticeGuidePath(
      Size.square(boardSize),
      widget.letterChar,
    );
    final guidePoints = samplePath(guidePath, samplesPerMetric: 64);

    final score = computeTraceScore(
      guidePoints: guidePoints,
      tracedPoints: _points,
      tolerance: boardSize * 0.09,
    );

    var didComplete = false;
    setState(() {
      _score = score;
      _progress = score.overall;
      if (score.shouldAutoAdvance && !_showCelebration) {
        _showCelebration = true;
        didComplete = true;
      }
    });

    if (didComplete) {
      HapticFeedback.heavyImpact();
      widget.onComplete?.call();
    }
  }

  void _appendTracePoint(Offset localPosition, double boardSize) {
    final point = Offset(
      localPosition.dx.clamp(0.0, boardSize),
      localPosition.dy.clamp(0.0, boardSize),
    );
    final lastPoint = _lastDrawnPoint;
    if (lastPoint != null && (point - lastPoint).distance < boardSize * 0.01) {
      return;
    }

    setState(() => _points.add(point));

    if (_points.length % 6 == 0) {
      _recalculateProgress(boardSize);
    }
  }

  Offset? get _lastDrawnPoint {
    for (var i = _points.length - 1; i >= 0; i--) {
      final point = _points[i];
      if (point != null) {
        return point;
      }
      if (i != _points.length - 1) {
        return null;
      }
    }
    return null;
  }

  String _feedbackText() {
    if (_showCelebration) {
      return 'Great trace. Moving to the next one...';
    }
    if (_points.isEmpty) {
      return 'Tap the start point and trace the shape';
    }
    if (_score.startAccuracy < 0.45) {
      return 'Start closer to the glowing dot, then follow the path';
    }
    if (_score.precision < 0.58) {
      return 'Stay closer to the guide line';
    }
    if (_score.coverage < 0.72) {
      return 'Good start. Keep tracing to finish the shape';
    }
    return 'Nice control. Complete the last bit cleanly';
  }

  Offset? _getStartPoint(double boardSize) {
    final strokeData =
        olChikiStrokes[normalizePracticeCharacter(widget.letterChar)];
    if (strokeData == null || strokeData.isEmpty) return null;

    final firstStroke = strokeData.first;
    if (firstStroke.points.isEmpty) return null;

    final normalizedPoint = firstStroke.points.first;
    return Offset(
      normalizedPoint.dx * boardSize,
      normalizedPoint.dy * boardSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final practiceChar = normalizePracticeCharacter(widget.letterChar);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide.clamp(260.0, 560.0);
        _lastBoardSize = boardSize;
        final startPoint = _getStartPoint(boardSize);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: boardSize,
                        height: boardSize,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF111A28)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: OlChikiGlyphGuidePainter(
                                  character: practiceChar,
                                  fillColor:
                                      (isDark ? Colors.white : Colors.black)
                                          .withValues(
                                            alpha: isDark ? 0.20 : 0.13,
                                          ),
                                  outlineColor: const Color(
                                    0xFF35C7B5,
                                  ).withValues(alpha: 0.24),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _GuidePainter(
                                  letterChar: practiceChar,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.10)
                                      : Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                            // Tracing area
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) {
                                  HapticFeedback.selectionClick();
                                  _appendTracePoint(
                                    details.localPosition,
                                    boardSize,
                                  );
                                },
                                onPanUpdate: (details) {
                                  _appendTracePoint(
                                    details.localPosition,
                                    boardSize,
                                  );
                                },
                                onPanEnd: (_) {
                                  _points.add(null);
                                  _recalculateProgress(boardSize);
                                },
                                child: CustomPaint(
                                  painter: TracingPainter(
                                    points: List<Offset?>.unmodifiable(_points),
                                    color: const Color(0xFF35C7B5),
                                  ),
                                ),
                              ),
                            ),
                            // Start point indicator (only show when no points traced)
                            if (startPoint != null && _points.isEmpty)
                              Positioned(
                                left: startPoint.dx - 16,
                                top: startPoint.dy - 16,
                                child: AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(
                                            0xFF35C7B5,
                                          ).withValues(alpha: 0.3),
                                          border: Border.all(
                                            color: const Color(0xFF35C7B5),
                                            width: 3,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.touch_app_rounded,
                                            color: Color(0xFF35C7B5),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Celebration overlay
                      if (_showCelebration)
                        Positioned.fill(
                          child: _CelebrationOverlay(
                            onContinue: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_feedbackText()}  Accuracy: ${(_progress * 100).round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _showCelebration
                      ? const Color(0xFF35C7B5)
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: _progress,
                  backgroundColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _showCelebration
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF35C7B5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Undo button
                  if (_points.isNotEmpty && !_showCelebration)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilledButton.icon(
                        onPressed: _undoLastStroke,
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Undo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.grey.shade200,
                          foregroundColor: isDark
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
                    ),
                  // Clear button
                  FilledButton.icon(
                    onPressed: _clearCanvas,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(_showCelebration ? 'Try Again' : 'Clear'),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.grey.shade100,
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final VoidCallback onContinue;

  const _CelebrationOverlay({required this.onContinue});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF35C7B5).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌟', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text(
                  'Nice!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF35C7B5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+10 XP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF35C7B5).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GuidePainter extends CustomPainter {
  final String letterChar;
  final Color color;

  _GuidePainter({required this.letterChar, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    final path = buildPracticeGuidePath(size, letterChar);
    canvas.drawPath(path, guidePaint);
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) {
    return oldDelegate.letterChar != letterChar || oldDelegate.color != color;
  }
}

class TracingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  TracingPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.04
      ..isAntiAlias = true;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TracingPainter oldDelegate) {
    return oldDelegate.points.length != points.length ||
        oldDelegate.color != color;
  }
}
