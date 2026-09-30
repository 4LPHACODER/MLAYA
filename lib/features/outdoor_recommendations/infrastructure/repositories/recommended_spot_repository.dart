import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:windify_v2/features/outdoor_recommendations/domain/entities/recommended_spot_model.dart';

class RecommendedSpotRepository {
  RecommendedSpotRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _table = 'recommended_saved_spots';

  Future<void> saveSpot({
    required String userId,
    required RecommendedSpotModel spot,
  }) async {
    try {
      final duplicate = await _findDuplicate(userId: userId, spot: spot);
      if (duplicate) {
        throw const RecommendedSpotSaveException.duplicate();
      }

      await _client.from(_table).insert({
        'user_id': userId,
        'name': spot.name,
        'activity': spot.activity,
        'description': spot.description,
        'address': spot.address,
        'latitude': spot.latitude,
        'longitude': spot.longitude,
        'distance_km': spot.distanceKm,
        'source': spot.source,
        'place_id': spot.placeId,
      });
      _debug('save_spot_success name=${spot.name}');
    } on RecommendedSpotSaveException {
      rethrow;
    } on PostgrestException catch (e) {
      _debug('save_spot_failure code=${e.code}');
      if (e.code == '23505') {
        throw const RecommendedSpotSaveException.duplicate();
      }
      throw const RecommendedSpotSaveException.failed();
    } catch (_) {
      throw const RecommendedSpotSaveException.failed();
    }
  }

  Future<bool> _findDuplicate({
    required String userId,
    required RecommendedSpotModel spot,
  }) async {
    if (spot.placeId != null && spot.placeId!.isNotEmpty) {
      final byPlaceId = await _client
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('place_id', spot.placeId!)
          .limit(1);
      if ((byPlaceId as List).isNotEmpty) return true;
    }

    final byCoordsAndName = await _client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .eq('name', spot.name)
        .eq('latitude', spot.latitude)
        .eq('longitude', spot.longitude)
        .limit(1);
    return (byCoordsAndName as List).isNotEmpty;
  }

  void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint('[OutdoorSpots] $message');
  }
}

class RecommendedSpotSaveException implements Exception {
  final String message;

  const RecommendedSpotSaveException._(this.message);

  const RecommendedSpotSaveException.duplicate()
    : this._('This spot is already saved.');

  const RecommendedSpotSaveException.failed()
    : this._('Could not save spot right now.');

  @override
  String toString() => message;
}
