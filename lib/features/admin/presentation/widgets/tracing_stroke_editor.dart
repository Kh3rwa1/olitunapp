// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/admin/data/tracing_templates.dart';
import 'package:itun/features/admin/presentation/widgets/admin_media_field.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/widgets/tracing_canvas.dart';
import 'package:file_picker/file_picker.dart';

class TracingStrokeEditor extends StatefulWidget {
  final String glyph;
  final TracingConfig? initial;
  final ValueChanged<TracingConfig?> onChanged;

  const TracingStrokeEditor({
    super.key,
    required this.glyph,
    this.initial,
    required this.onChanged,
  });

  @override
  State<TracingStrokeEditor> createState() => _TracingStrokeEditorState();
}

class _TracingStrokeEditorState extends State<TracingStrokeEditor> {
  final List<TracingStroke> _strokes = [];
  double _strokeWidth = 12.0;
  double _tolerance = 0.6;
  int _requiredCompletions = 1;
  TracingGuide _guide = TracingGuide.dotted;
  String? _audioOnCompleteUrl;

  // Drawing dynamic custom strokes state
  bool _isDrawingCustom = false;
  final List<Offset> _drawnRawPoints = [];

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _strokes.addAll(widget.initial!.strokes);
      _strokeWidth = widget.initial!.strokeWidth;
      _tolerance = widget.initial!.tolerance;
      _requiredCompletions = widget.initial!.requiredCompletions;
      _guide = widget.initial!.guide;
      _audioOnCompleteUrl = widget.initial!.audioOnCompleteUrl;
    } else {
      // Pre-fill with template if exists
      final template = tracingTemplates[widget.glyph];
      if (template != null) {
        _strokes.addAll(template.strokes);
        _strokeWidth = template.strokeWidth;
        _tolerance = template.tolerance;
        _requiredCompletions = template.requiredCompletions;
        _guide = template.guide;
        _audioOnCompleteUrl = template.audioOnCompleteUrl;
      }
    }
  }

  void _notifyChanges() {
    final config = TracingConfig(
      glyph: widget.glyph,
      strokes: List.unmodifiable(_strokes),
      guide: _guide,
      strokeWidth: _strokeWidth,
      tolerance: _tolerance,
      audioOnCompleteUrl: _audioOnCompleteUrl,
      requiredCompletions: _requiredCompletions,
    );
    widget.onChanged(config);
  }

  void _applyTemplate(String glyphChar) {
    final template =
        tracingTemplates[glyphChar] ?? getFallbackTemplate(glyphChar);
    setState(() {
      _strokes.clear();
      _strokes.addAll(template.strokes);
      _strokeWidth = template.strokeWidth;
      _tolerance = template.tolerance;
      _requiredCompletions = template.requiredCompletions;
      _guide = template.guide;
      _audioOnCompleteUrl = template.audioOnCompleteUrl;
    });
    _notifyChanges();
  }

  void _addCustomStroke() {
    if (_drawnRawPoints.length < 2) return;

    final path = _drawnRawPoints.map((p) {
      return TracingPoint(
        x: (p.dx / 300.0).clamp(0.0, 1.0),
        y: (p.dy / 300.0).clamp(0.0, 1.0),
      );
    }).toList();

    final newStroke = TracingStroke(
      id: 'stroke_${widget.glyph}_custom_${DateTime.now().millisecondsSinceEpoch}',
      order: _strokes.length,
      path: path,
      hintText: 'Custom Stroke ${_strokes.length + 1}',
    );

    setState(() {
      _strokes.add(newStroke);
      _drawnRawPoints.clear();
      _isDrawingCustom = false;
    });
    _notifyChanges();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presets Picker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tracing Configuration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              onSelected: _applyTemplate,
              itemBuilder: (context) {
                return [
                  ...tracingTemplates.keys.map((k) {
                    return PopupMenuItem(
                      value: k,
                      child: Text('Prefill Preset: $k'),
                    );
                  }),
                  PopupMenuItem(
                    value: widget.glyph,
                    child: Text('Fallback Box for ${widget.glyph}'),
                  ),
                ];
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? AppColors.textSecondaryLight
                        : AppColors.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Load Template',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : AppColors.darkSurfaceElevated,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sliders & Setup Controls
        Card(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Stroke Width
                Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text(
                        'Stroke Width:',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _strokeWidth,
                        min: 5.0,
                        max: 25.0,
                        divisions: 20,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() => _strokeWidth = val);
                          _notifyChanges();
                        },
                      ),
                    ),
                    Text(
                      '${_strokeWidth.toInt()}px',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),

                // Matching Tolerance
                Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text('Tolerance:', style: TextStyle(fontSize: 13)),
                    ),
                    Expanded(
                      child: Slider(
                        value: _tolerance,
                        min: 0.1,
                        divisions: 18,
                        activeColor: AppColors.brandBlue,
                        onChanged: (val) {
                          setState(() => _tolerance = val);
                          _notifyChanges();
                        },
                      ),
                    ),
                    Text(
                      _tolerance.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),

                // Mastery Repetitions
                Row(
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text(
                        'Completions:',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _requiredCompletions.toDouble(),
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        activeColor: AppColors.warning,
                        onChanged: (val) {
                          setState(() => _requiredCompletions = val.toInt());
                          _notifyChanges();
                        },
                      ),
                    ),
                    Text(
                      '$_requiredCompletions',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),

                // Guide style
                DropdownButtonFormField<TracingGuide>(
                  value: _guide,
                  items: TracingGuide.values.map((g) {
                    return DropdownMenuItem(
                      value: g,
                      child: Text(g.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _guide = val);
                      _notifyChanges();
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Guide Layout Style',
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Completed Strokes / Reorderable strokes
        if (_strokes.isNotEmpty) ...[
          const Text(
            'Stroke Order & Directions (Drag to reorder)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ReorderableListView(
              shrinkWrap: true,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _strokes.removeAt(oldIndex);
                  _strokes.insert(newIndex, item);
                });
                _notifyChanges();
              },
              children: [
                for (int idx = 0; idx < _strokes.length; idx++)
                  ListTile(
                    key: Key(_strokes[idx].id),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: AppColors.elevatedButtonFg),
                      ),
                    ),
                    title: Text(_strokes[idx].hintText ?? 'Stroke ${idx + 1}'),
                    subtitle: Text(
                      '${_strokes[idx].path.length} control points',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.drag_handle),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete stroke',
                          onPressed: () {
                            setState(() {
                              _strokes.removeAt(idx);
                            });
                            _notifyChanges();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Custom stroke drawer sheet
        if (_isDrawingCustom) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2.0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Draw your stroke inside the green canvas below:',
                  ),
                ),
                GestureDetector(
                  onPanStart: (details) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _drawnRawPoints.clear();
                      _drawnRawPoints.add(details.localPosition);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _drawnRawPoints.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) {},
                  child: Container(
                    width: 300,
                    height: 300,
                    color: isDark
                        ? AppColors.softBlack
                        : AppColors.lightSurfaceVariant,
                    child: CustomPaint(
                      painter: _DrawStrokePainter(
                        points: _drawnRawPoints,
                        color: AppColors.primary,
                        strokeWidth: _strokeWidth,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _addCustomStroke,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.elevatedButtonFg,
                        ),
                        child: const Text('Save Stroke'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _drawnRawPoints.clear();
                            _isDrawingCustom = false;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _drawnRawPoints.clear();
                _isDrawingCustom = true;
              });
            },
            icon: const Icon(Icons.gesture_rounded),
            label: const Text('Draw Custom Stroke'),
          ),
        ],

        const SizedBox(height: 16),

        // Completion Audio
        AdminMediaField(
          label: 'Completion Audio Success celebration',
          icon: Icons.audiotrack_rounded,
          accent: AppColors.primary,
          currentUrl: _audioOnCompleteUrl,
          uploadFolder: 'tracing-success-audio',
          fileType: FileType.audio,
          onUploaded: (url) {
            setState(() => _audioOnCompleteUrl = url);
            _notifyChanges();
          },
        ),

        const SizedBox(height: 24),

        // Live Preview of Tracing Canvas
        if (_strokes.isNotEmpty) ...[
          const Text(
            'Live Preview (Test your tracing matches here):',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TracingCanvas(
            config: TracingConfig(
              glyph: widget.glyph,
              strokes: _strokes,
              guide: _guide,
              strokeWidth: _strokeWidth,
              tolerance: _tolerance,
              requiredCompletions: _requiredCompletions,
            ),
          ),
        ],
      ],
    );
  }
}

class _DrawStrokePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  _DrawStrokePainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawStrokePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
