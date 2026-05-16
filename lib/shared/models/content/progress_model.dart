// ============== USER PROGRESS MODEL ==============
class UserProgressModel {
  final String categoryId;
  final double percent;
  final DateTime updatedAt;
  final int completedLessons;
  final int totalLessons;

  UserProgressModel({
    required this.categoryId,
    this.percent = 0,
    required this.updatedAt,
    this.completedLessons = 0,
    this.totalLessons = 0,
  });

  factory UserProgressModel.fromJson(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return UserProgressModel(
      categoryId: docId ?? data['categoryId'] as String? ?? '',
      percent: (data['percent'] as num?)?.toDouble() ?? 0,
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
      completedLessons: data['completedLessons'] as int? ?? 0,
      totalLessons: data['totalLessons'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'percent': percent,
      'updatedAt': updatedAt.toIso8601String(),
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
    };
  }
}
