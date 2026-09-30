import 'package:latlong2/latlong.dart';

enum WeatherSafetyLevel { good, caution, avoid }

class SpotWeatherSnapshot {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final String icon;
  final int? precipitation;

  const SpotWeatherSnapshot({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.precipitation,
  });
}

class ActivitySafetyAdvice {
  final WeatherSafetyLevel level;
  final String label;
  final String explanation;

  const ActivitySafetyAdvice({
    required this.level,
    required this.label,
    required this.explanation,
  });
}

class RecommendedSpotModel {
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final List<String> categories;
  final List<String> displayTags;
  final String category;
  final String activity;
  final double distanceMeters;
  final String distanceLabel;
  final String? description;
  final String source;
  final String? placeId;
  final SpotWeatherSnapshot? weather;
  final ActivitySafetyAdvice? safetyAdvice;

  const RecommendedSpotModel({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.displayTags,
    required this.category,
    required this.activity,
    required this.distanceMeters,
    required this.distanceLabel,
    required this.description,
    required this.source,
    required this.placeId,
    required this.weather,
    required this.safetyAdvice,
  });

  LatLng get coordinates => LatLng(latitude, longitude);

  double get distanceKm => distanceMeters / 1000.0;

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;

  RecommendedSpotModel copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    List<String>? categories,
    List<String>? displayTags,
    String? category,
    String? activity,
    double? distanceMeters,
    String? distanceLabel,
    String? description,
    String? source,
    String? placeId,
    SpotWeatherSnapshot? weather,
    ActivitySafetyAdvice? safetyAdvice,
  }) {
    return RecommendedSpotModel(
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      categories: categories ?? this.categories,
      displayTags: displayTags ?? this.displayTags,
      category: category ?? this.category,
      activity: activity ?? this.activity,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      description: description ?? this.description,
      source: source ?? this.source,
      placeId: placeId ?? this.placeId,
      weather: weather ?? this.weather,
      safetyAdvice: safetyAdvice ?? this.safetyAdvice,
    );
  }
}

enum OutdoorSpotActionType { visit, route }

class OutdoorSpotActionResult {
  final OutdoorSpotActionType type;
  final RecommendedSpotModel spot;

  const OutdoorSpotActionResult({required this.type, required this.spot});
}
