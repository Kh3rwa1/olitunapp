import 'dart:collection';

enum BreadcrumbLevel { debug, info, warning, error }

class BreadcrumbEntry {
  final DateTime timestamp;
  final String category;
  final String message;
  final BreadcrumbLevel level;
  final Map<String, dynamic> data;

  BreadcrumbEntry({
    DateTime? timestamp,
    required this.category,
    required this.message,
    this.level = BreadcrumbLevel.info,
    Map<String, dynamic>? data,
  }) : timestamp = timestamp ?? DateTime.now(),
       data = data != null ? Map.unmodifiable(data) : const {};

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'category': category,
    'message': message,
    'level': level.name,
    if (data.isNotEmpty) 'data': data,
  };

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] [$category] [${level.name.toUpperCase()}] $message';
}

class BreadcrumbTracker {
  BreadcrumbTracker({this.maxCapacity = 50});

  final int maxCapacity;
  final Queue<BreadcrumbEntry> _buffer = Queue<BreadcrumbEntry>();

  static final BreadcrumbTracker instance = BreadcrumbTracker();

  static const _sensitiveKeys = <String>{
    'password',
    'token',
    'secret',
    'auth',
    'authorization',
    'key',
    'api_key',
    'apikey',
    'email',
    'phone',
    'credential',
    'cookie',
  };

  void add({
    required String category,
    required String message,
    BreadcrumbLevel level = BreadcrumbLevel.info,
    Map<String, dynamic>? data,
  }) {
    final sanitizedData = data != null ? sanitizeData(data) : null;
    final entry = BreadcrumbEntry(
      category: category,
      message: message,
      level: level,
      data: sanitizedData,
    );

    if (_buffer.length >= maxCapacity) {
      _buffer.removeFirst();
    }
    _buffer.addLast(entry);
  }

  List<BreadcrumbEntry> getRecent([int? limit]) {
    final list = _buffer.toList(growable: false);
    if (limit == null || limit >= list.length) {
      return list;
    }
    return list.sublist(list.length - limit);
  }

  void clear() {
    _buffer.clear();
  }

  int get count => _buffer.length;

  static Map<String, dynamic> sanitizeData(Map<String, dynamic> input) {
    final sanitized = <String, dynamic>{};
    for (final entry in input.entries) {
      final keyLower = entry.key.toLowerCase();
      if (_sensitiveKeys.any(keyLower.contains)) {
        sanitized[entry.key] = '[REDACTED]';
      } else if (entry.value is Map) {
        sanitized[entry.key] = sanitizeData(
          Map<String, dynamic>.from(entry.value as Map),
        );
      } else if (entry.value is String &&
          _looksSensitive(entry.value as String)) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  static bool _looksSensitive(String value) {
    // Basic JWT check
    if (value.startsWith('eyJ') && value.split('.').length == 3) {
      return true;
    }
    return false;
  }
}
