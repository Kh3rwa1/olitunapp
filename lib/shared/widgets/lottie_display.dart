import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/logging/app_logger.dart';

class _BoundedLottieCache {
  static const _maxEntries = 20;
  static const _maxBytes = 10 * 1024 * 1024; // 10 MB
  final _store = <String, Uint8List>{};
  int _totalBytes = 0;

  Uint8List? get(String key) {
    final v = _store.remove(key);
    if (v != null) {
      _store[key] = v; // Move to end (most recent)
    }
    return v;
  }

  void put(String key, Uint8List bytes) {
    _store.remove(key);
    _store[key] = bytes;
    _totalBytes += bytes.length;
    while (_store.length > _maxEntries || _totalBytes > _maxBytes) {
      final firstKey = _store.keys.first;
      final removed = _store.remove(firstKey);
      if (removed != null) {
        _totalBytes -= removed.length;
      }
    }
  }
}

/// Reusable widget for rendering Lottie animations from network URLs.
/// Falls back to a placeholder on error or while loading.
class LottieDisplay extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool animate;
  final Widget? placeholder;
  final Widget? errorWidget;
  final AnimationController? controller;
  final void Function(LottieComposition)? onLoaded;

  const LottieDisplay({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
    this.placeholder,
    this.errorWidget,
    this.controller,
    this.onLoaded,
  });

  static final _cache = _BoundedLottieCache();

  @override
  State<LottieDisplay> createState() => _LottieDisplayState();
}

class _LottieDisplayState extends State<LottieDisplay> {
  Future<Uint8List>? _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadBytes();
  }

  @override
  void didUpdateWidget(covariant LottieDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _loadFuture = _loadBytes();
      });
    }
  }

  Future<Uint8List> _fetchBytesWithRetry() async {
    final cached = LottieDisplay._cache.get(widget.url);
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
          final bytes = response.bodyBytes;
          if (bytes.isEmpty) {
            throw Exception('Empty response bytes');
          }

          // Check for ZIP signature (dotLottie format)
          if (bytes.length >= 4 &&
              bytes[0] == 0x50 && // 'P'
              bytes[1] == 0x4B && // 'K'
              bytes[2] == 0x03 &&
              bytes[3] == 0x04) {
            throw Exception(
              'dotLottie format not supported — please re-upload as Lottie JSON',
            );
          }

          // Check for JSON Lottie
          if (bytes[0] == 0x7B) {
            // '{'
            LottieDisplay._cache.put(widget.url, bytes);
            return bytes;
          }

          // Unexpected format
          final prefixHex = bytes
              .take(8)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join();
          final ct = response.headers['content-type'] ?? 'unknown';
          AppLogger.debug(
            '[LottieDisplay] unexpected format url=${widget.url} status=200 contentType=$ct bytesPrefix=0x$prefixHex',
          );
          throw Exception('Unexpected Lottie file format');
        } else {
          throw Exception('HTTP status ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts ||
            e.toString().contains('dotLottie format not supported')) {
          rethrow;
        }
        await Future.delayed(delays[attempt - 1]);
      }
    }
    throw Exception('Failed after $maxAttempts attempts');
  }

  Future<Uint8List> _loadBytes() async {
    try {
      return await _fetchBytesWithRetry();
    } catch (e) {
      String contentType = 'unknown';
      int statusCode = 0;
      try {
        final res = await http
            .head(Uri.parse(widget.url))
            .timeout(const Duration(seconds: 2));
        statusCode = res.statusCode;
        contentType = res.headers['content-type'] ?? 'unknown';
      } catch (_) {}

      AppLogger.debug(
        '[LottieDisplay] failed url=${widget.url} status=$statusCode contentType=$contentType bytesPrefix=none error=$e',
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder ?? _buildLoadingPlaceholder();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final errorStr = snapshot.error?.toString() ?? '';
          if (errorStr.contains('dotLottie format not supported')) {
            return _buildErrorPlaceholder(
              'dotLottie format not supported — please re-upload as Lottie JSON',
            );
          }
          return widget.errorWidget ??
              _buildErrorPlaceholder('Failed to load Lottie animation');
        }

        final bytes = snapshot.data!;
        return Lottie.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          repeat: widget.repeat,
          animate: widget.animate,
          controller: widget.controller,
          onLoaded: widget.onLoaded,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ??
                _buildErrorPlaceholder('Failed to play Lottie animation');
          },
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

  Widget _buildErrorPlaceholder(String message) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image_rounded,
              color: Colors.grey,
              size: 36,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
