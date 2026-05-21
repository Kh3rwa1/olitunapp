import '../../../lessons/domain/entities/lesson_entity.dart';

class AdminLessonBlockText {
  const AdminLessonBlockText({
    required this.index,
    required this.olChiki,
    required this.latin,
    required this.meaning,
    this.imageUrl,
    this.audioUrl,
    this.animationUrl,
  });

  final int index;
  final String olChiki;
  final String latin;
  final String meaning;
  final String? imageUrl;
  final String? audioUrl;
  final String? animationUrl;
}

List<AdminLessonBlockText> adminTextRowsFromLessonBlocks(LessonEntity lesson) {
  final rows = <AdminLessonBlockText>[];
  for (var index = 0; index < lesson.blocks.length; index++) {
    final block = lesson.blocks[index];
    final row = adminTextRowFromLessonBlock(block, index);
    if (row != null) rows.add(row);
  }
  return rows;
}

AdminLessonBlockText? adminTextRowFromLessonBlock(
  LessonBlockEntity block,
  int index,
) {
  final data = block.data ?? const <String, dynamic>{};
  final olChiki = _firstText([
    block.textOlChiki,
    data['textOlChiki'],
    data['wordOlChiki'],
    data['sentenceOlChiki'],
    data['titleOlChiki'],
    data['olChiki'],
    data['olchiki'],
    data['nativeText'],
  ]);
  final rawLatin = _firstText([
    block.textLatin,
    data['textLatin'],
    data['wordLatin'],
    data['sentenceLatin'],
    data['titleLatin'],
    data['latin'],
    data['roman'],
    data['transliteration'],
    data['subtitle'],
    data['label'],
    data['text'],
  ]);
  final explicitMeaning = _firstText([
    data['meaning'],
    data['english'],
    data['translation'],
    data['description'],
  ]);

  final latin = explicitMeaning.isEmpty ? _latinPart(rawLatin) : rawLatin;
  final meaning = explicitMeaning.isEmpty
      ? _meaningPart(rawLatin)
      : explicitMeaning;

  if (olChiki.isEmpty && latin.isEmpty && meaning.isEmpty) return null;

  return AdminLessonBlockText(
    index: index,
    olChiki: olChiki,
    latin: latin,
    meaning: meaning.isEmpty ? latin : meaning,
    imageUrl: _firstText([
      block.imageUrl,
      data['imageUrl'],
      data['thumbnailUrl'],
    ]),
    audioUrl: _firstText([block.audioUrl, data['audioUrl']]),
    animationUrl: _firstText([
      data['animationUrl'],
      data['lottieUrl'],
      data['videoUrl'],
    ]),
  );
}

String _firstText(Iterable<dynamic> values) {
  for (final value in values) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String _latinPart(String value) {
  if (value.isEmpty) return '';
  return value.split(RegExp(r'\s+[–-]\s+')).first.trim();
}

String _meaningPart(String value) {
  if (value.isEmpty) return '';
  final parts = value.split(RegExp(r'\s+[–-]\s+'));
  return parts.length > 1 ? parts.sublist(1).join(' - ').trim() : '';
}
