import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../../features/lessons/presentation/widgets/platform_view_stub.dart'
    if (dart.library.js_interop) '../../features/lessons/presentation/widgets/platform_view_web.dart';

class AnimatedSvgDisplay extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AnimatedSvgDisplay({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<AnimatedSvgDisplay> createState() => _AnimatedSvgDisplayState();
}

class _AnimatedSvgDisplayState extends State<AnimatedSvgDisplay> {
  static final Map<String, String> _svgCache = {};
  Future<String>? _loadFuture;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _loadFuture = _loadSvg();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedSvgDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && kIsWeb) {
      setState(() {
        _loadFuture = _loadSvg();
      });
    }
  }

  Future<String> _loadSvg() async {
    final cached = _svgCache[widget.url];
    if (cached != null) {
      return cached;
    }

    int attempt = 0;
    const maxAttempts = 3;
    final delays = [
      const Duration(milliseconds: 500),
      const Duration(seconds: 1),
      const Duration(seconds: 2),
    ];

    while (attempt < maxAttempts) {
      try {
        final response = await http.get(Uri.parse(widget.url));
        if (response.statusCode == 200) {
          final svgText = response.body;
          if (svgText.isEmpty) {
            throw Exception('Empty SVG response');
          }
          _svgCache[widget.url] = svgText;
          return svgText;
        } else {
          throw Exception('HTTP status ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(delays[attempt - 1]);
      }
    }
    throw Exception('Failed after $maxAttempts attempts');
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return SvgPicture.network(
        widget.url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholderBuilder: widget.placeholder != null
            ? (_) => widget.placeholder!
            : null,
        errorBuilder: widget.errorWidget != null
            ? (context, error, stackTrace) => widget.errorWidget!
            : null,
      );
    }

    return FutureBuilder<String>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ?? _buildLoadingPlaceholder();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return widget.errorWidget ?? _buildErrorPlaceholder();
        }

        final svgText = snapshot.data!;
        // viewId derived from a hash of (url + svgText length)
        final viewId = 'svg-view-${widget.url.hashCode}-${svgText.length}';
        registerSvgHtmlView(viewId, svgText);

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: HtmlElementView(viewType: viewId),
        );
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      width: widget.width ?? 48,
      height: widget.height ?? 48,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 140,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.grey, size: 36),
            SizedBox(height: 6),
            Text(
              'Failed to load SVG animation',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
