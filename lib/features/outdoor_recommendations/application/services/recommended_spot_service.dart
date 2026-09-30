import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:windify_v2/features/outdoor_recommendations/application/services/activity_weather_advisor.dart';
import 'package:windify_v2/features/outdoor_recommendations/domain/entities/recommended_spot_model.dart';
import 'package:windify_v2/features/outdoor_recommendations/infrastructure/services/geoapify_service.dart';
import 'package:windify_v2/features/weather_map/infrastructure/services/weather_api_service.dart';

class RecommendedSpotService {
  RecommendedSpotService({
    GeoapifyService? geoapifyService,
    WeatherApiService? weatherApiService,
    ActivityWeatherAdvisor? activityWeatherAdvisor,
  }) : _geoapifyService = geoapifyService ?? GeoapifyService(),
       _weatherApiService = weatherApiService ?? WeatherApiService(),
       _activityWeatherAdvisor =
           activityWeatherAdvisor ?? const ActivityWeatherAdvisor();

  final GeoapifyService _geoapifyService;
  final WeatherApiService _weatherApiService;
  final ActivityWeatherAdvisor _activityWeatherAdvisor;

  Future<List<RecommendedSpotModel>> recommend({
    required String activity,
    required LatLng center,
  }) async {
    if (activity.trim().isEmpty) return [];
    _debug(
      'active_location_used lat=${center.latitude} lon=${center.longitude} activity=$activity',
    );
    final spots = await _geoapifyService.searchNearby(
      activity: activity,
      center: center,
    );
    spots.sort((a, b) {
      final byDistance = a.distanceMeters.compareTo(b.distanceMeters);
      if (byDistance != 0) return byDistance;
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) return byName;
      return (a.placeId ?? '').compareTo(b.placeId ?? '');
    });

    final enriched = <RecommendedSpotModel>[];
    final maxWeatherRequests = spots.length > 8 ? 8 : spots.length;
    for (var index = 0; index < spots.length; index++) {
      final spot = spots[index];
      if (index >= maxWeatherRequests) {
        enriched.add(spot);
        continue;
      }
      try {
        _debug('weather_request lat=${spot.latitude} lon=${spot.longitude}');
        final weather = await _weatherApiService.getCurrentWeatherByCoords(
          lat: spot.latitude,
          lon: spot.longitude,
        );
        final snapshot = SpotWeatherSnapshot(
          temperature: weather.temperature,
          condition: weather.description,
          humidity: weather.humidity,
          windSpeed: weather.windSpeed,
          icon: weather.icon,
          precipitation: weather.precipitation,
        );
        final advice = _activityWeatherAdvisor.evaluate(
          activity: activity,
          weather: snapshot,
        );
        enriched.add(spot.copyWith(weather: snapshot, safetyAdvice: advice));
      } catch (_) {
        enriched.add(spot);
      }
    }
    _debug('recommendation_result_count count=${enriched.length}');
    return enriched;
  }

  void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint('[OutdoorSpots] $message');
  }
}
