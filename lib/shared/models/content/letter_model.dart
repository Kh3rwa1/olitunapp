import 'dart:convert';

// ============== LETTER MODEL ==============
class LetterModel {
  final String id;
  final String charOlChiki;
  final String transliterationLatin;
  final String? exampleWordOlChiki;
  final String? exampleWordLatin;
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
  final int order;
  final bool isActive;
  final String? pronunciation;
  final String? themeColor;

  LetterModel({
    required this.id,
    required this.charOlChiki,
    required this.transliterationLatin,
    this.exampleWordOlChiki,
    this.exampleWordLatin,
    this.imageUrl,
    this.audioUrl,
    this.animationUrl,
    this.order = 0,
    this.isActive = true,
    this.pronunciation,
    this.themeColor,
  });

  // Convenience getters for backwards compatibility
  String get character => charOlChiki;
  String get romanization => transliterationLatin;

  factory LetterModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    String? resolvedAudioUrl = data['audioUrl'] as String?;
    if (resolvedAudioUrl == null || resolvedAudioUrl.isEmpty) {
      final blocksRaw = data['blocks'];
      if (blocksRaw is String && blocksRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(blocksRaw) as List<dynamic>;
          for (final block in decoded) {
            if (block is Map<String, dynamic>) {
              if (block['type'] == 'audio' && block['media'] is Map) {
                resolvedAudioUrl = block['media']['url'] as String?;
              } else if (block['type'] == 'glyph') {
                resolvedAudioUrl = block['audioUrl'] as String?;
              }
              if (resolvedAudioUrl != null && resolvedAudioUrl.isNotEmpty) {
                break;
              }
            }
          }
        } catch (_) {}
      } else if (blocksRaw is List) {
        for (final block in blocksRaw) {
          if (block is Map) {
            final type = block['type'];
            if (type == 'audio' && block['media'] is Map) {
              resolvedAudioUrl = block['media']['url'] as String?;
            } else if (type == 'glyph') {
              resolvedAudioUrl = block['audioUrl'] as String?;
            }
            if (resolvedAudioUrl != null && resolvedAudioUrl.isNotEmpty) {
              break;
            }
          }
        }
      }
    }

    return LetterModel(
      id: docId ?? data['id'] as String? ?? '',
      charOlChiki:
          data['charOlChiki'] as String? ?? data['character'] as String? ?? '',
      transliterationLatin:
          data['transliterationLatin'] as String? ??
          data['romanization'] as String? ??
          '',
      exampleWordOlChiki: data['exampleWordOlChiki'] as String?,
      exampleWordLatin: data['exampleWordLatin'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: resolvedAudioUrl,
      animationUrl: data['animationUrl'] as String?,
      order: data['order'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      pronunciation: data['pronunciation'] as String?,
      themeColor: data['themeColor'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'charOlChiki': charOlChiki,
      'transliterationLatin': transliterationLatin,
      'exampleWordOlChiki': exampleWordOlChiki,
      'exampleWordLatin': exampleWordLatin,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'animationUrl': animationUrl,
      'order': order,
      'isActive': isActive,
      'pronunciation': pronunciation,
      'themeColor': themeColor,
    };
  }

  LetterModel copyWith({
    String? id,
    String? charOlChiki,
    String? transliterationLatin,
    String? exampleWordOlChiki,
    String? exampleWordLatin,
    String? imageUrl,
    String? audioUrl,
    String? animationUrl,
    int? order,
    bool? isActive,
    String? pronunciation,
    String? themeColor,
  }) {
    return LetterModel(
      id: id ?? this.id,
      charOlChiki: charOlChiki ?? this.charOlChiki,
      transliterationLatin: transliterationLatin ?? this.transliterationLatin,
      exampleWordOlChiki: exampleWordOlChiki ?? this.exampleWordOlChiki,
      exampleWordLatin: exampleWordLatin ?? this.exampleWordLatin,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      animationUrl: animationUrl ?? this.animationUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      pronunciation: pronunciation ?? this.pronunciation,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}
