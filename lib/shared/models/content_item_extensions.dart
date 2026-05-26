import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/rhymes/domain/rhyme_model.dart';
import 'package:itun/shared/models/content_models.dart';

extension ContentBlockToLegacy on ContentBlock {
  LessonBlockEntity toLessonBlockEntity() {
    String? textLatin;
    String? textOlChiki;
    String? imageUrl;
    String? audioUrl;
    Map<String, dynamic>? blockData;

    final self = this;
        if (self is TextBlock) {
      textLatin = self.textLatin ?? self.markdown;
      textOlChiki = self.textOlChiki;
    } else if (self is ImageBlock) {
      imageUrl = self.media.url;
      textLatin = self.caption;
    } else if (self is VideoBlock) {
      imageUrl = self.posterUrl;
      audioUrl = self.media.url;
      textLatin = self.media.caption;
      blockData = {
        'autoplay': self.autoplay,
        'durationSeconds': self.durationSeconds,
      };
    } else if (self is AudioBlock) {
      audioUrl = self.media.url;
      textLatin = self.media.caption;
      blockData = {'transcript': self.transcript};
    } else if (self is LottieBlock) {
      imageUrl = self.media.url;
      blockData = {'loop': self.loop};
    } else if (self is QuizBlock) {
      blockData = {'quizId': self.quizId};
    } else if (self is GlyphBlock) {
      textOlChiki = self.olChiki;
      textLatin = self.latin;
      audioUrl = self.audioUrl;
    } else if (self is CalloutBlock) {
      textLatin = self.text;
      blockData = {'style': self.variant.name};
    } else if (self is TracingBlock) {
      blockData = self.config.toJson();
    }

    return LessonBlockEntity(
      type: type,
      textLatin: textLatin,
      textOlChiki: textOlChiki,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      data: blockData,
    );
  }
}

extension LessonBlockEntityToContentBlock on LessonBlockEntity {
  /// Converts a legacy [LessonBlockEntity] back to a universal [ContentBlock].
  ContentBlock toContentBlock(int index) {
    final blockId = 'block_${type}_$index';
    switch (type) {
      case 'text':
        return TextBlock(
          id: blockId,
          order: index,
          markdown: textLatin ?? textOlChiki ?? '',
          textOlChiki: textOlChiki,
          textLatin: textLatin,
        );
      case 'image':
      case 'svg':
        return ImageBlock(
          id: blockId,
          order: index,
          media: ContentMedia(
            url: imageUrl ?? '',
            fileId: '',
            kind: type == 'svg' ? ContentMediaKind.svg : ContentMediaKind.image,
          ),
          caption: textLatin,
        );
      case 'video':
        return VideoBlock(
          id: blockId,
          order: index,
          media: ContentMedia(
            url: audioUrl ?? '',
            fileId: '',
            kind: ContentMediaKind.video,
            caption: textLatin,
          ),
          posterUrl: imageUrl,
          autoplay: data?['autoplay'] as bool? ?? false,
          durationSeconds: data?['durationSeconds'] as int?,
        );
      case 'audio':
        return AudioBlock(
          id: blockId,
          order: index,
          media: ContentMedia(
            url: audioUrl ?? '',
            fileId: '',
            kind: ContentMediaKind.audio,
            caption: textLatin,
          ),
          transcript: data?['transcript'] as String?,
        );
      case 'lottie':
        return LottieBlock(
          id: blockId,
          order: index,
          media: ContentMedia(
            url: imageUrl ?? '',
            fileId: '',
            kind: ContentMediaKind.lottie,
          ),
          loop: data?['loop'] as bool? ?? true,
        );
      case 'quiz':
        return QuizBlock(
          id: blockId,
          order: index,
          quizId: data?['quizId'] as String? ?? '',
        );
      case 'glyph':
        return GlyphBlock(
          id: blockId,
          order: index,
          olChiki: textOlChiki ?? '',
          latin: textLatin ?? '',
          audioUrl: audioUrl,
        );
      case 'callout':
        return CalloutBlock(
          id: blockId,
          order: index,
          text: textLatin ?? '',
          variant: CalloutVariant.fromString(
            data?['style'] as String? ?? 'note',
          ),
        );
      case 'tracing':
        return TracingBlock(
          id: blockId,
          order: index,
          config: data != null
              ? TracingConfig.fromJson(data!)
              : const TracingConfig(glyph: '', strokes: []),
        );
      default:
        // Fallback: treat unknown types as text blocks
        return TextBlock(
          id: blockId,
          order: index,
          markdown: textLatin ?? textOlChiki ?? '',
        );
    }
  }
}

extension ContentItemToLegacy on ContentItem {
  WordModel toWordModel() {
    final firstAudio = blocks.whereType<AudioBlock>().firstOrNull?.media.url;
    final firstImage = blocks.whereType<ImageBlock>().firstOrNull?.media.url;
    final firstText = blocks.whereType<TextBlock>().firstOrNull?.markdown;

    return WordModel(
      id: id,
      wordOlChiki: olChiki ?? titleOlChiki ?? '',
      wordLatin: title,
      meaning: subtitle ?? '',
      category: categoryId,
      order: order,
      audioUrl: heroMedia?.url ?? firstAudio,
      imageUrl: heroMedia?.url ?? firstImage,
      themeColor: firstText,
    );
  }

  LetterModel toLetterModel() {
    final firstAudio = blocks.whereType<AudioBlock>().firstOrNull?.media.url;
    final firstImage = blocks.whereType<ImageBlock>().firstOrNull?.media.url;
    final firstText = blocks.whereType<TextBlock>().firstOrNull?.markdown;

    return LetterModel(
      id: id,
      charOlChiki: olChiki ?? titleOlChiki ?? '',
      transliterationLatin: title,
      audioUrl: heroMedia?.url ?? firstAudio,
      imageUrl: heroMedia?.url ?? firstImage,
      order: order,
      themeColor: firstText,
    );
  }

  NumberModel toNumberModel() {
    final firstAudio = blocks.whereType<AudioBlock>().firstOrNull?.media.url;
    final firstImage = blocks.whereType<ImageBlock>().firstOrNull?.media.url;
    final firstText = blocks.whereType<TextBlock>().firstOrNull?.markdown;
    final parsedValue =
        int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), '')) ?? order;

    return NumberModel(
      id: id,
      numeral: olChiki ?? '',
      value: parsedValue,
      nameOlChiki: titleOlChiki ?? '',
      nameLatin: title,
      audioUrl: heroMedia?.url ?? firstAudio,
      imageUrl: heroMedia?.url ?? firstImage,
      order: order,
      themeColor: firstText,
    );
  }

  SentenceModel toSentenceModel() {
    final firstAudio = blocks.whereType<AudioBlock>().firstOrNull?.media.url;
    final firstImage = blocks.whereType<ImageBlock>().firstOrNull?.media.url;
    final firstText = blocks.whereType<TextBlock>().firstOrNull?.markdown;

    return SentenceModel(
      id: id,
      sentenceOlChiki: olChiki ?? titleOlChiki ?? '',
      sentenceLatin: title,
      meaning: subtitle ?? '',
      category: categoryId,
      order: order,
      audioUrl: heroMedia?.url ?? firstAudio,
      imageUrl: heroMedia?.url ?? firstImage,
      themeColor: firstText,
    );
  }

  LessonEntity toLessonEntity() {
    return LessonEntity(
      id: id,
      categoryId: categoryId,
      titleOlChiki: titleOlChiki ?? '',
      titleLatin: title,
      order: order,
      estimatedMinutes: durationSeconds != null
          ? (durationSeconds! / 60).round()
          : 5,
      blocks: blocks.map((b) => b.toLessonBlockEntity()).toList(),
    );
  }

  RhymeModel toRhymeModel() {
    final firstAudio = blocks.whereType<AudioBlock>().firstOrNull?.media.url;
    final firstImage = blocks.whereType<ImageBlock>().firstOrNull?.media.url;

    return RhymeModel(
      id: id,
      titleOlChiki: titleOlChiki ?? '',
      titleLatin: title,
      contentOlChiki: olChiki ?? '',
      contentLatin: subtitle ?? '',
      audioUrl: heroMedia?.url ?? firstAudio,
      thumbnailUrl: heroMedia?.url ?? firstImage,
      categoryId: categoryId,
      category: categoryId,
      tags: tags,
    );
  }
}
