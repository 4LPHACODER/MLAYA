import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/added_spot.dart';
import '../../domain/entities/captured_moment.dart';

class CommunityRepository {
  CommunityRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _addedSpotsTable = 'added_spots';
  static const String _capturedMomentsTable = 'captured_moments';
  static const Uuid _uuid = Uuid();

  Future<String> uploadWatermarkedImage({
    required String bucket,
    required String folderPrefix,
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = _uuid.v4();
    final path = '$folderPrefix/$timestamp-$uniqueFileName.$fileExtension';

    await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  Future<void> createAddedSpot({
    required String spotName,
    required String category,
    required String? description,
    required String? location,
    required String imageUrl,
    required String userId,
    required String uploaderName,
  }) async {
    await _client.from(_addedSpotsTable).insert({
      'spot_name': spotName,
      'category': category,
      'description': description,
      'location': location,
      'image_url': imageUrl,
      'user_id': userId,
      'uploader_name': uploaderName,
    });
  }

  Future<void> createCapturedMoment({
    required String? caption,
    required String imageUrl,
    required String userId,
    required String uploaderName,
  }) async {
    await _client.from(_capturedMomentsTable).insert({
      'caption': caption,
      'image_url': imageUrl,
      'user_id': userId,
      'uploader_name': uploaderName,
    });
  }

  Future<List<AddedSpot>> fetchMyAddedSpots(String userId) async {
    final response = await _client
        .from(_addedSpotsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => AddedSpot.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<AddedSpot>> fetchPublicAddedSpots({int limit = 100}) async {
    final response = await _client
        .from(_addedSpotsTable)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((e) => AddedSpot.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<CapturedMoment>> fetchMyCapturedMoments(String userId) async {
    final response = await _client
        .from(_capturedMomentsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((e) => CapturedMoment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
