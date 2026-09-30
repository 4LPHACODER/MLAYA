class AddedSpot {
  final String id;
  final String spotName;
  final String category;
  final String? description;
  final String? location;
  final String imageUrl;
  final String userId;
  final String uploaderName;
  final DateTime createdAt;

  const AddedSpot({
    required this.id,
    required this.spotName,
    required this.category,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.userId,
    required this.uploaderName,
    required this.createdAt,
  });

  factory AddedSpot.fromJson(Map<String, dynamic> json) {
    return AddedSpot(
      id: json['id']?.toString() ?? '',
      spotName: json['spot_name']?.toString() ?? 'Untitled spot',
      category: json['category']?.toString() ?? 'Other',
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      imageUrl: json['image_url']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      uploaderName: json['uploader_name']?.toString() ?? 'Malaya user',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
