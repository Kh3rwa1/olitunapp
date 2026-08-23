import 'dart:convert';

import '../../../../../shared/models/content_item.dart';

/// Builds and downloads a CSV export of admin content lists.
String buildContentListCsv(ContentKind kind, List<ContentItem> items) {
  final isSentence = kind == ContentKind.sentence;
  final isLessonOrRhyme =
      kind == ContentKind.lesson || kind == ContentKind.rhyme;

  final String csvHeader;
  if (isSentence) {
    csvHeader =
        'ID,Kind,Title,Title Ol Chiki,Ol Chiki,Subtitle,Category,Published,Premium,Order,Tags,Meaning Block,Usage Block,Audio Block URL,Audio Block Transcript,Blocks JSON,Updated At\n';
  } else if (isLessonOrRhyme) {
    csvHeader =
        'ID,Kind,Title,Title Ol Chiki,Ol Chiki,Subtitle,Category,Published,Premium,Order,Tags,Blocks JSON,Updated At\n';
  } else {
    csvHeader =
        'ID,Kind,Title,Title Ol Chiki,Ol Chiki,Subtitle,Category,Published,Premium,Order,Tags,Updated At\n';
  }

  final csvRows = items
      .map((item) {
        String meaningBlock = '';
        String usageBlock = '';
        String audioUrlBlock = '';
        String audioTranscriptBlock = '';

        if (isSentence) {
          // Try fetching by block IDs first
          for (final block in item.blocks) {
            if (block is TextBlock) {
              if (block.id == 'meaning') {
                meaningBlock = block.markdown;
              } else if (block.id == 'usage') {
                usageBlock = block.markdown;
              }
            } else if (block is AudioBlock) {
              if (block.id == 'pronunciation_audio') {
                audioUrlBlock = block.media.url;
                audioTranscriptBlock = block.transcript ?? '';
              }
            }
          }
          // Fallback to order if IDs not matches
          if (meaningBlock.isEmpty) {
            final textBlocks = item.blocks.whereType<TextBlock>().toList();
            if (textBlocks.isNotEmpty) {
              meaningBlock = textBlocks[0].markdown;
              if (textBlocks.length > 1 && usageBlock.isEmpty) {
                usageBlock = textBlocks[1].markdown;
              }
            }
          }
          if (audioUrlBlock.isEmpty) {
            final audioBlocks = item.blocks.whereType<AudioBlock>().toList();
            if (audioBlocks.isNotEmpty) {
              audioUrlBlock = audioBlocks[0].media.url;
              audioTranscriptBlock = audioBlocks[0].transcript ?? '';
            }
          }
        }

        final row = [
          item.id,
          item.kind.name,
          item.title,
          item.titleOlChiki ?? '',
          item.olChiki ?? '',
          item.subtitle ?? '',
          item.categoryId,
          item.isPublished.toString(),
          item.isPremium.toString(),
          item.order.toString(),
          item.tags.join('; '),
        ];

        if (isSentence) {
          row.addAll([
            meaningBlock,
            usageBlock,
            audioUrlBlock,
            audioTranscriptBlock,
          ]);
        }

        if (isSentence || isLessonOrRhyme) {
          final blocksJson = jsonEncode(
            item.blocks.map((e) => e.toJson()).toList(),
          );
          row.add(blocksJson);
        }

        row.add(item.updatedAt.toIso8601String());

        return row
            .map((val) {
              final escaped = val.replaceAll('"', '""');
              return '"$escaped"';
            })
            .join(',');
      })
      .join('\n');

  return csvHeader + csvRows;
}
