import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:windify_v2/core/config/env_config.dart';
import 'package:windify_v2/features/outdoor_recommendations/domain/entities/recommended_spot_model.dart';

class GeoapifyService {
  GeoapifyService({Dio? dio})
      : _dio = dio ?? Dio(),
        _apiKey = EnvConfig.geoapifyApiKey,
        _baseUrl = EnvConfig.geoapifyBaseUrl;

  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;

  static const int _defaultLimit = 20;
  static const int _defaultRadiusMeters = 15000;

  String _mapActivityToGeoapifyCategories(String activity) {
    final normalized = activity.toLowerCase().trim();

    switch (normalized) {
      case 'swimming':
        return 'sport.swimming_pool,natural.water,beach';

      case 'camping':
        return 'camping.camp_site,camping.camp_pitch,camping';

      case 'surfing':
        return 'beach,natural.water,natural';

      case 'skateboarding':
        return 'activity.sport_club,leisure.park,sport';

      case 'falls':
      case 'waterfall':
      case 'waterfalls':
        return 'natural.water,tourism.attraction,natural';

      case 'beach':
      case 'beaches':
        return 'beach,beach.beach_resort,tourism.attraction,natural';

      case 'park':
      case 'parks':
        return 'leisure.park,natural,tourism.attraction';

      case 'hiking':
        return 'tourism.attraction,natural,national_park';

      case 'fishing':
        return 'natural.water,beach';

      default:
        return 'tourism.attraction,natural,leisure.park';
    }
  }

  Future<List<RecommendedSpotModel>> searchNearby({
    required String activity,
    required LatLng center,
    int limit = _defaultLimit,
  }) async {
    final categories = _mapActivityToGeoapifyCategories(activity);
    debugPrint('[OutdoorSpots] selected_activity=$activity');
    debugPrint('[OutdoorSpots] mapped_categories=$categories');
    return _fetchByCategories(
      activity: activity,
      center: center,
      categories: categories,
      limit: limit,
    );
  }

  Future<List<RecommendedSpotModel>> _fetchByCategories({
    required String activity,
    required LatLng center,
    required String categories,
    required int limit,
  }) async {
    if (categories.isEmpty) return [];
    final filter =
        'circle:${center.longitude},${center.latitude},$_defaultRadiusMeters';
    final endpoint = '$_baseUrl/places';
    _debug(
        'geoapify_request endpoint=/places categories=$categories center=${center.longitude},${center.latitude}',
    );

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: {
          'categories': categories,
          'filter': filter,
          'bias': 'proximity:${center.longitude},${center.latitude}',
          'limit': limit,
          'apiKey': _apiKey,
        },
      );
      if (response.statusCode != 200) {
        final errorMsg = 'Geoapify request failed with status ${response.statusCode}: ${response.data}';
        _debug(errorMsg);
        throw StateError(errorMsg);
      }
      return _parseFeatureResponse(
        response.data,
        activity: activity,
        center: center,
      );
    } on DioException catch (e) {
      _throwGeoapifyError(e, endpoint, categories);
    }
  }

  List<RecommendedSpotModel> _parseFeatureResponse(
      Map<String, dynamic>? json, {
        required String activity,
        required LatLng center,
      }) {
    if (json == null) return [];
    final features = json['features'];
    if (features is! List) return [];

    final mappedSpots = <RecommendedSpotModel>[];
    for (final raw in features) {
      if (raw is! Map) continue;
      final feature = Map<String, dynamic>.from(raw);
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'];
      if (coordinates is! List || coordinates.length < 2) continue;

      final lon = (coordinates[0] as num?)?.toDouble();
      final lat = (coordinates[1] as num?)?.toDouble();
      if (lon == null || lat == null) continue;

      final properties = (feature['properties'] as Map?)
          ?.cast<String, dynamic>();
      final name = properties?['name']?.toString().trim();
      if (name == null || name.isEmpty) continue;
      final address = properties?['formatted']?.toString();
      final categories = _extractCategories(properties);
      final placeId = properties?['place_id']?.toString();
      final distanceFromApi = (properties?['distance'] as num?)?.toDouble();
      final computedDistance =
          distanceFromApi ??
          _haversineMeters(center.latitude, center.longitude, lat, lon);
      final description =
          properties?['details']?.toString() ??
          _extractDatasourceDescription(properties);
      final displayTags = _cleanDisplayTags(categories, activity);

      mappedSpots.add(
        RecommendedSpotModel(
          name: name,
          address: address,
          latitude: lat,
          longitude: lon,
          categories: categories,
          displayTags: displayTags,
          category: displayTags.join(', '),
          activity: activity,
          distanceMeters: computedDistance,
          distanceLabel: _formatDistance(computedDistance),
          description: description,
          source: 'geoapify',
          placeId: placeId,
          weather: null,
          safetyAdvice: null,
        ),
      );
    }

    final matchedSpots = mappedSpots
        .where((spot) => _matchesSelectedActivity(spot, activity))
        .toList();

    debugPrint('[OutdoorSpots] selected_activity=$activity');
    debugPrint('[OutdoorSpots] raw_results=${mappedSpots.length}');
    debugPrint('[OutdoorSpots] matched_results=${matchedSpots.length}');

    final matchedSet = matchedSpots.toSet();
    for (final spot in mappedSpots) {
      if (matchedSet.contains(spot)) continue;
      debugPrint(
        '[OutdoorSpots] filtered_out name=${spot.name} categories=${spot.categories}',
      );
    }

    final enrichedMatchedSpots = _addFishingTagIfMatched(
      spots: matchedSpots,
      activity: activity,
    );

    if (enrichedMatchedSpots.isNotEmpty) {
      _debug('geoapify_results count=${enrichedMatchedSpots.length}');
      return enrichedMatchedSpots;
    }

    if (_isStrictActivity(activity)) {
      _debug('geoapify_results count=0 strict_activity=$activity');
      return [];
    }

    _debug('geoapify_results count=${mappedSpots.length} fallback=non_strict');
    return mappedSpots;
  }

  List<RecommendedSpotModel> _addFishingTagIfMatched({
    required List<RecommendedSpotModel> spots,
    required String activity,
  }) {
    final normalizedActivity = activity.toLowerCase().trim();
    if (normalizedActivity != 'fishing') return spots;

    return spots.map((spot) {
      if (!_matchesSelectedActivity(spot, activity)) return spot;
      final tags = <String>{...spot.displayTags, 'Fishing'}.take(3).toList();
      return spot.copyWith(displayTags: tags, category: tags.join(', '));
    }).toList();
  }

  List<String> _extractCategories(Map<String, dynamic>? properties) {
    final categories = <String>[];
    final rawCategories = properties?['categories'];
    if (rawCategories is List) {
      for (final category in rawCategories) {
        final normalized = _sanitizeCategoryToken(category.toString());
        if (normalized.isNotEmpty) categories.add(normalized);
      }
    }

    if (categories.isNotEmpty) return categories;

    final singleCategory = properties?['category']?.toString().trim() ?? '';
    if (singleCategory.isEmpty) return const [];

    return singleCategory
        .split(',')
        .map((entry) => _sanitizeCategoryToken(entry))
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  String _sanitizeCategoryToken(String token) {
    final cleaned = token.replaceAll('[', '').replaceAll(']', '').trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.toLowerCase() == 'details') return '';
    return cleaned;
  }

  bool _matchesSelectedActivity(RecommendedSpotModel spot, String activity) {
    final normalizedActivity = activity.toLowerCase().trim();
    final searchableText = [
      spot.name,
      spot.address ?? '',
      spot.description ?? '',
      ...spot.categories,
    ].join(' ').toLowerCase();

    switch (normalizedActivity) {
      case 'fishing':
        return searchableText.contains('fish') ||
            searchableText.contains('fishing') ||
            searchableText.contains('water') ||
            searchableText.contains('river') ||
            searchableText.contains('lake') ||
            searchableText.contains('sea') ||
            searchableText.contains('beach') ||
            searchableText.contains('bay') ||
            searchableText.contains('coast') ||
            searchableText.contains('pier') ||
            searchableText.contains('harbor') ||
            searchableText.contains('port') ||
            searchableText.contains('wharf');
      case 'beach':
      case 'beaches':
        return searchableText.contains('beach') ||
            searchableText.contains('coast') ||
            searchableText.contains('shore') ||
            searchableText.contains('sea') ||
            searchableText.contains('bay') ||
            searchableText.contains('resort') ||
            searchableText.contains('tourism.attraction') ||
            searchableText.contains('natural');
      case 'swimming':
        return searchableText.contains('swimming') ||
            searchableText.contains('pool') ||
            searchableText.contains('water') ||
            searchableText.contains('beach') ||
            searchableText.contains('resort');
      case 'camping':
        return searchableText.contains('camp') ||
            searchableText.contains('camping') ||
            searchableText.contains('camp_site') ||
            searchableText.contains('camp_pitch');
      case 'hiking':
        return searchableText.contains('hiking') ||
            searchableText.contains('trail') ||
            searchableText.contains('mountain') ||
            searchableText.contains('forest') ||
            searchableText.contains('park') ||
            searchableText.contains('nature') ||
            searchableText.contains('tourism.attraction') ||
            searchableText.contains('natural');
      case 'falls':
      case 'waterfall':
      case 'waterfalls':
        return searchableText.contains('falls') ||
            searchableText.contains('waterfall') ||
            searchableText.contains('water') ||
            searchableText.contains('spring') ||
            searchableText.contains('river');
      default:
        return true;
    }
  }

  bool _isStrictActivity(String activity) {
    switch (activity.toLowerCase().trim()) {
      case 'fishing':
        return true;
      default:
        return false;
    }
  }

  List<String> _cleanDisplayTags(List<String> categories, String selectedActivity) {
    final tags = <String>{};

    for (final category in categories) {
      final lower = category.toLowerCase();
      if (lower.contains('beach')) {
        tags.add('Beach');
      } else if (lower.contains('water')) {
        tags.add('Water');
      } else if (lower.contains('camp')) {
        tags.add('Camping');
      } else if (lower.contains('park')) {
        tags.add('Park');
      } else if (lower.contains('tourism')) {
        tags.add('Attraction');
      } else if (lower.contains('natural')) {
        tags.add('Nature');
      } else if (lower.contains('sport')) {
        tags.add('Sport');
      } else if (lower.contains('leisure')) {
        tags.add('Leisure');
      }
    }

    if (tags.isEmpty) {
      tags.add(_formatActivity(selectedActivity));
    }

    return tags.take(3).toList();
  }

  String _formatActivity(String activity) {
    final trimmed = activity.trim();
    if (trimmed.isEmpty) return 'Outdoor';
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  String _formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double value) => value * pi / 180.0;

  Never _throwGeoapifyError(DioException e, String endpoint, String categories) {
    final status = e.response?.statusCode;
    final requestUrl = '$endpoint?categories=$categories&filter=circle:LONG,LAT,RADIUS&bias=proximity:LONG,LAT&limit=20&apiKey=***';
    if (status == 429) {
      throw StateError(
          'Geoapify request limit reached. Please try again later.',
      );
    }
    if (status == 401 || status == 403) {
      throw StateError(
          'Geoapify API key invalid or unauthorized. Please check your GEOAPIFY_API_KEY.',
      );
    }
    if (status == 400) {
      _debug('Geoapify 400 Bad Request. URL (sanitized): $requestUrl');
      _debug('Response body: ${e.response?.data}');
      throw StateError(
          'Invalid activity category. Please try another outdoor activity.',
      );
    }
    throw StateError(
        'Geoapify request failed (HTTP $status). Please check your connection and API key.',
    );
  }

  String? _extractDatasourceDescription(Map<String, dynamic>? properties) {
    final datasource = properties?['datasource'];
    if (datasource is! Map) return null;
    final raw = datasource['raw'];
    if (raw is! Map) return null;
    return raw['description']?.toString();
  }

  void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint('[OutdoorSpots] $message');
  }
}
