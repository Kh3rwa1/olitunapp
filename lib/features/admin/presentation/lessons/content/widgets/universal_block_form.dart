import 'package:flutter/widgets.dart';

import '../../../../../../core/languages/ol_chiki_multilingual_helper.dart';
import '../../../../../../shared/models/catalog/lesson_entity.dart';
import '../../../../../../shared/utils/media_type_resolver.dart';

/// Form state for [UniversalBlockSheet]: the text controllers, the picked
/// media/options, and the mapping to and from [LessonBlockEntity]. The block
/// "type" is inferred from what is filled in ([resolveType]).
class UniversalBlockForm {
  final olChikiCtrl = TextEditingController();
  final latinCtrl = TextEditingController();
  final meaningEnCtrl = TextEditingController();
  final meaningBnCtrl = TextEditingController();
  final meaningHiCtrl = TextEditingController();
  final meaningOrCtrl = TextEditingController();
  final textBengaliCtrl = TextEditingController();
  final textHindiCtrl = TextEditingController();
  final textOdiaCtrl = TextEditingController();
  final pronCtrl = TextEditingController();
  final quizRefCtrl = TextEditingController();

  String? mediaUrl;
  String? posterUrl;
  String? audioUrl;
  String? calloutVariant;
  bool tracingEnabled = false;
  String? themeColor;

  /// Populates the form from an existing block (legacy keys included).
  void load(LessonBlockEntity b) {
    olChikiCtrl.text = b.textOlChiki ?? '';
    latinCtrl.text = b.textLatin ?? '';
    audioUrl = b.audioUrl;
    final data = b.data ?? const {};
    pronCtrl.text = (data['pronunciation'] as String?) ?? '';

    final parsed = OlChikiMultilingualHelper.parseCompositeLatin(
      b.textLatin ?? '',
    );
    meaningEnCtrl.text =
        (data['meaning_en'] as String?) ??
        (data['meaning'] as String?) ??
        parsed.meaningEnglish;
    meaningBnCtrl.text = (data['meaning_bn'] as String?) ?? '';
    meaningHiCtrl.text = (data['meaning_hi'] as String?) ?? '';
    meaningOrCtrl.text = (data['meaning_or'] as String?) ?? '';

    textBengaliCtrl.text =
        b.textBengali ??
        (data['textBengali'] as String?) ??
        (data['pronunciation_bn'] as String?) ??
        (data['transliteration_bn'] as String?) ??
        '';
    textHindiCtrl.text =
        b.textHindi ??
        (data['textHindi'] as String?) ??
        (data['pronunciation_hi'] as String?) ??
        (data['transliteration_hi'] as String?) ??
        '';
    textOdiaCtrl.text =
        b.textOdia ??
        (data['textOdia'] as String?) ??
        (data['pronunciation_or'] as String?) ??
        (data['transliteration_or'] as String?) ??
        '';

    quizRefCtrl.text =
        (data['quizId'] as String?) ?? (data['quizRefId'] as String?) ?? '';
    posterUrl = data['posterUrl'] as String?;
    calloutVariant = data['calloutVariant'] as String?;
    tracingEnabled = b.type == 'tracing';
    themeColor = data['themeColor'] as String?;

    // Canonical media URL — prefer nested media map, then legacy fields
    final mediaMap = data['media'];
    if (mediaMap is Map && mediaMap['url'] is String) {
      mediaUrl = mediaMap['url'] as String;
    } else {
      mediaUrl =
          b.imageUrl ??
          (data['mediaUrl'] as String?) ??
          (data['videoUrl'] as String?) ??
          (data['animationUrl'] as String?) ??
          (data['heroMediaUrl'] as String?);
    }
  }

  // ── Type inference ─────────────────────────────────────────────────────────

  String resolveType({required bool tracingAllowed}) {
    if (tracingEnabled && tracingAllowed) return 'tracing';
    if (quizRefCtrl.text.trim().isNotEmpty) return 'quiz';
    if (calloutVariant != null) return 'callout';
    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      switch (MediaTypeResolver.resolve(mediaUrl)) {
        case MediaKind.image:
          return 'image';
        case MediaKind.svg:
          return 'svg';
        case MediaKind.lottie:
          return 'lottie';
        case MediaKind.video:
          return 'video';
        case MediaKind.audio:
          return 'audio';
        case MediaKind.html:
          return 'html';
        case MediaKind.unknown:
          return 'image';
      }
    }
    return 'text';
  }

  MediaKind get mediaKind => MediaTypeResolver.resolve(mediaUrl);
  bool get mediaIsVideo => mediaKind == MediaKind.video;

  // ── Save ───────────────────────────────────────────────────────────────────

  /// Builds the block from the form, starting from [existing]'s data so
  /// unknown/future keys are preserved and legacy keys are canonicalised.
  LessonBlockEntity toEntity({
    required LessonBlockEntity? existing,
    required bool tracingAllowed,
  }) {
    final type = resolveType(tracingAllowed: tracingAllowed);

    final media = <String, dynamic>{};
    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      media['url'] = mediaUrl;
      media['kind'] = mediaKind.name;
    }

    // Start from existing data so unknown/future keys aren't lost
    final data = <String, dynamic>{
      ...?existing?.data?.cast<String, dynamic>(),
      if (media.isNotEmpty) 'media': media,
      if (mediaIsVideo && (posterUrl?.isNotEmpty ?? false))
        'posterUrl': posterUrl,
      if (calloutVariant != null) 'calloutVariant': calloutVariant,
      if (themeColor != null) 'themeColor': themeColor,
    };

    if (pronCtrl.text.trim().isNotEmpty) {
      data['pronunciation'] = pronCtrl.text.trim();
    } else {
      data.remove('pronunciation');
    }

    if (meaningEnCtrl.text.trim().isNotEmpty) {
      data['meaning'] = meaningEnCtrl.text.trim();
      data['meaning_en'] = meaningEnCtrl.text.trim();
    } else {
      data.remove('meaning');
      data.remove('meaning_en');
    }

    if (meaningBnCtrl.text.trim().isNotEmpty) {
      data['meaning_bn'] = meaningBnCtrl.text.trim();
    } else {
      data.remove('meaning_bn');
    }

    if (meaningHiCtrl.text.trim().isNotEmpty) {
      data['meaning_hi'] = meaningHiCtrl.text.trim();
    } else {
      data.remove('meaning_hi');
    }

    if (meaningOrCtrl.text.trim().isNotEmpty) {
      data['meaning_or'] = meaningOrCtrl.text.trim();
    } else {
      data.remove('meaning_or');
    }

    if (textBengaliCtrl.text.trim().isNotEmpty) {
      final val = textBengaliCtrl.text.trim();
      data['textBengali'] = val;
      data['pronunciation_bn'] = val;
      data['transliteration_bn'] = val;
    } else {
      data.remove('textBengali');
      data.remove('pronunciation_bn');
      data.remove('transliteration_bn');
    }

    if (textHindiCtrl.text.trim().isNotEmpty) {
      final val = textHindiCtrl.text.trim();
      data['textHindi'] = val;
      data['pronunciation_hi'] = val;
      data['transliteration_hi'] = val;
    } else {
      data.remove('textHindi');
      data.remove('pronunciation_hi');
      data.remove('transliteration_hi');
    }

    if (textOdiaCtrl.text.trim().isNotEmpty) {
      final val = textOdiaCtrl.text.trim();
      data['textOdia'] = val;
      data['pronunciation_or'] = val;
      data['transliteration_or'] = val;
    } else {
      data.remove('textOdia');
      data.remove('pronunciation_or');
      data.remove('transliteration_or');
    }

    if (quizRefCtrl.text.trim().isNotEmpty) {
      data['quizId'] = quizRefCtrl.text.trim();
    } else {
      data.remove('quizId');
    }
    if (audioUrl != null && audioUrl!.isNotEmpty && type != 'audio') {
      data['audioUrl'] = audioUrl;
    } else {
      data.remove('audioUrl');
    }
    // Remove legacy keys we've now canonicalised
    for (final k in const [
      'mediaUrl',
      'videoUrl',
      'animationUrl',
      'imageUrl',
      'heroMediaUrl',
      'quizRefId',
    ]) {
      data.remove(k);
    }

    return LessonBlockEntity(
      type: type,
      textOlChiki: olChikiCtrl.text.trim().isEmpty
          ? null
          : olChikiCtrl.text.trim(),
      textLatin: latinCtrl.text.trim().isEmpty ? null : latinCtrl.text.trim(),
      textBengali: textBengaliCtrl.text.trim().isEmpty
          ? null
          : textBengaliCtrl.text.trim(),
      textHindi: textHindiCtrl.text.trim().isEmpty
          ? null
          : textHindiCtrl.text.trim(),
      textOdia: textOdiaCtrl.text.trim().isEmpty
          ? null
          : textOdiaCtrl.text.trim(),
      imageUrl: (type == 'image' || type == 'svg' || type == 'lottie')
          ? mediaUrl
          : (type == 'video' ? posterUrl : null),
      audioUrl: type == 'audio' ? mediaUrl : audioUrl,
      data: data,
    );
  }

  void dispose() {
    olChikiCtrl.dispose();
    latinCtrl.dispose();
    meaningEnCtrl.dispose();
    meaningBnCtrl.dispose();
    meaningHiCtrl.dispose();
    meaningOrCtrl.dispose();
    textBengaliCtrl.dispose();
    textHindiCtrl.dispose();
    textOdiaCtrl.dispose();
    pronCtrl.dispose();
    quizRefCtrl.dispose();
  }
}
