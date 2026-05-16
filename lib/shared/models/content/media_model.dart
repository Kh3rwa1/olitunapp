// ============== MEDIA FILE MODEL ==============
class MediaFileModel {
  final String id;
  final String name;
  final String url;
  final String type; // image, audio, video
  final int size;
  final DateTime uploadedAt;

  MediaFileModel({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    this.size = 0,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  factory MediaFileModel.fromJson(Map<String, dynamic> data, [String? docId]) {
    return MediaFileModel(
      id: docId ?? data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      url: data['url'] as String? ?? '',
      type: data['type'] as String? ?? 'image',
      size: data['size'] as int? ?? 0,
      uploadedAt: data['uploadedAt'] != null
          ? DateTime.parse(data['uploadedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}
