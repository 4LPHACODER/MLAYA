class CapturedMoment {
  final String id;
  final String? caption;
  final String imageUrl;
  final String userId;
  final String uploaderName;
  final DateTime createdAt;

  const CapturedMoment({
    required this.id,
    required this.caption,
    required this.imageUrl,
    required this.userId,
    required this.uploaderName,
    required this.createdAt,
  });

  factory CapturedMoment.fromJson(Map<String, dynamic> json) {
    return CapturedMoment(
      id: json['id']?.toString() ?? '',
      caption: json['caption']?.toString(),
      imageUrl: json['image_url']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      uploaderName: json['uploader_name']?.toString() ?? 'Malaya user',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
