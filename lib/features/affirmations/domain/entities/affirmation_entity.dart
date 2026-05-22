import 'package:equatable/equatable.dart';

class AffirmationEntity extends Equatable {
  final String id;
  final String olChikiText;
  final String santaliPhonetic;
  final String englishMeaning;
  final String? audioUrl;
  final String category;
  final bool isPremium;
  final int order;
  final String publishedAt;

  const AffirmationEntity({
    required this.id,
    required this.olChikiText,
    required this.santaliPhonetic,
    required this.englishMeaning,
    this.audioUrl,
    required this.category,
    this.isPremium = false,
    required this.order,
    required this.publishedAt,
  });

  @override
  List<Object?> get props => [
    id,
    olChikiText,
    santaliPhonetic,
    englishMeaning,
    audioUrl,
    category,
    isPremium,
    order,
    publishedAt,
  ];
}
