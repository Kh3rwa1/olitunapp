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
      textLatin = self.markdown;
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
