import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:windify_v2/features/notifications/domain/entities/app_notification.dart';
import 'package:windify_v2/features/notifications/presentation/providers/notification_provider.dart';

import '../../application/providers/weather_providers.dart';
import '../../application/services/geocoding_service.dart';
import '../../application/services/geolocation_service.dart';
import '../../application/services/weather_map_service.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/weather_layer.dart';
import '../map/weather_map_debug_log.dart';
import '../states/weather_map_state.dart';

class WeatherMapNotifier extends StateNotifier<WeatherMapState> {
  final Ref _ref;
  final WeatherMapService _weatherMapService;
  final GeolocationService _geolocationService;
  final GeocodingService _geocodingService;

  WeatherMapNotifier(
    this._ref,
    this._weatherMapService,
    this._geolocationService,
    this._geocodingService,
  ) : super(const WeatherMapState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _refreshWeatherForActiveLocation();
    await _resolveDeviceLocationInBackground();
  }

  Future<void> _refreshWeatherForActiveLocation() async {
    final loc = state.activeLocationForWeather;
    state = state.copyWith(isLoadingWeather: true, error: null);
    try {
      final timelineMaps = await _weatherMapService.getForecastTimeline(
        layer: state.selectedLayer,
        location: loc,
      );
      final fallbackMap = await _weatherMapService.getForecastMap(
        layer: state.selectedLayer,
        location: loc,
      );
      final frames = timelineMaps.isEmpty ? [fallbackMap] : timelineMaps;
      final index = state.selectedTimelineIndex.clamp(0, frames.length - 1);
      final map = frames[index];
      state = state.copyWith(
        isLoadingWeather: false,
        currentMap: map,
        timelineMaps: frames,
        selectedTimelineIndex: index,
        isTimelinePlaying: false,
        error: null,
      );
      WeatherMapDebugLog.activeWeatherTarget(
        state.activeLocationForWeather,
        state.activeLocationLabel,
      );
      await _maybeGenerateWeatherNotifications();
    } catch (e) {
      state = state.copyWith(isLoadingWeather: false, error: e.toString());
    }
  }

  Future<void> _maybeGenerateWeatherNotifications() async {
    final weather = state.currentMap?.currentWeather;
    if (weather == null) {
      return;
    }

    final notificationNotifier = _ref.read(notificationsProvider.notifier);
    final lowerDescription = weather.description.toLowerCase();
    final locationLabel = state.activeLocationLabel;

    if (lowerDescription.contains('thunder') || lowerDescription.contains('storm')) {
      await notificationNotifier.addNotification(
        title: 'Strong weather alert',
        message: 'Strong wind or storm detected near your area.',
        type: NotificationType.weather,
        latitude: state.activeLocationForWeather.latitude,
        longitude: state.activeLocationForWeather.longitude,
      );
    } else if (lowerDescription.contains('rain') ||
        lowerDescription.contains('drizzle') ||
        lowerDescription.contains('shower')) {
      await notificationNotifier.addNotification(
        title: 'Rain expected',
        message: 'Rain expected near $locationLabel.',
        type: NotificationType.weather,
        latitude: state.activeLocationForWeather.latitude,
        longitude: state.activeLocationForWeather.longitude,
      );
    }

    if (weather.windSpeed >= 12) {
      await notificationNotifier.addNotification(
        title: 'Strong wind detected',
        message: 'Outdoor activities may not be safe in this area right now.',
        type: NotificationType.weather,
        latitude: state.activeLocationForWeather.latitude,
        longitude: state.activeLocationForWeather.longitude,
      );
    }

    if (_isGoodOutdoorWeather(weather.temperature, weather.windSpeed, weather.precipitation, lowerDescription)) {
      await notificationNotifier.addNotification(
        title: 'Good outdoor weather',
        message: 'Good weather for hiking and outdoor activities near $locationLabel.',
        type: NotificationType.recommendation,
        latitude: state.activeLocationForWeather.latitude,
        longitude: state.activeLocationForWeather.longitude,
      );
    }
  }

  bool _isGoodOutdoorWeather(
    double temperature,
    double windSpeed,
    int? precipitation,
    String description,
  ) {
    final hasBadCondition =
        description.contains('rain') ||
        description.contains('storm') ||
        description.contains('thunder');
    final hasLowRainRisk = (precipitation ?? 0) <= 0;
    return !hasBadCondition &&
        hasLowRainRisk &&
        windSpeed <= 8 &&
        temperature >= 18 &&
        temperature <= 31;
  }

  Future<void> _resolveDeviceLocationInBackground() async {
    state = state.copyWith(isRequestingLocation: true);

    var perm = await _geolocationService.checkPermission();
    state = state.copyWith(locationPermissionStatus: perm);

    if (perm == LocationPermission.denied) {
      perm = await _geolocationService.requestPermission();
    }

    state = state.copyWith(locationPermissionStatus: perm);

    if (perm != LocationPermission.always &&
        perm != LocationPermission.whileInUse) {
      state = state.copyWith(
        isRequestingLocation: false,
        error:
            'Location unavailable. Showing ${WeatherMapState.fallbackLabel}.',
      );
      return;
    }

    try {
      final location = await _geolocationService.getCurrentLocation();
      state = state.copyWith(
        userLocation: location.coordinates,
        userLocationLabel: location.name,
        isRequestingLocation: false,
        error: null,
      );
      if (state.selectedLocation == null) {
        await _refreshWeatherForActiveLocation();
      }
    } catch (e) {
      state = state.copyWith(
        isRequestingLocation: false,
        error: 'Could not read GPS ($e). Map location unchanged.',
      );
    }
  }

  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isRequestingLocation: true, error: null);
    var perm = await _geolocationService.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await _geolocationService.requestPermission();
    }
    state = state.copyWith(locationPermissionStatus: perm);

    if (perm != LocationPermission.always &&
        perm != LocationPermission.whileInUse) {
      state = state.copyWith(
        isRequestingLocation: false,
        error:
            'Location permission denied. Showing ${WeatherMapState.fallbackLabel}.',
      );
      return;
    }

    try {
      final location = await _geolocationService.getCurrentLocation();
      state = state.copyWith(
        userLocation: location.coordinates,
        userLocationLabel: location.name,
        isRequestingLocation: false,
        error: null,
      );
      if (state.selectedLocation == null) {
        await _refreshWeatherForActiveLocation();
      }
    } catch (e) {
      state = state.copyWith(
        isRequestingLocation: false,
        error: 'Could not get location: $e',
      );
    }
  }

  Future<List<Location>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return _geocodingService.searchPlaces(query);
  }

  Future<void> selectSearchResult(Location location) async {
    state = state.copyWith(
      selectedLocation: location.coordinates,
      selectedLocationLabel:
          location.name ?? location.address ?? 'Selected place',
    );
    WeatherMapDebugLog.selectedPinSet(
      location.coordinates,
      state.selectedLocationLabel,
    );
    await _refreshWeatherForActiveLocation();
  }

  Future<void> pinLocation(LatLng coordinates) async {
    var label = 'Pinned';
    try {
      final loc = await _geocodingService.reverseGeocode(coordinates);
      label = loc.name ?? loc.address ?? 'Pinned';
    } catch (_) {}
    state = state.copyWith(
      selectedLocation: coordinates,
      selectedLocationLabel: label,
    );
    WeatherMapDebugLog.selectedPinSet(coordinates, label);
    await _refreshWeatherForActiveLocation();
  }

  /// Apply a saved place: selected pin + label, refresh forecast for current layer (radar/wind/wave).
  Future<void> visitSavedLocation(
    LatLng coordinates,
    String locationName,
  ) async {
    state = state.copyWith(
      selectedLocation: coordinates,
      selectedLocationLabel: locationName,
    );
    WeatherMapDebugLog.selectedPinSet(coordinates, locationName);
    await _refreshWeatherForActiveLocation();
  }

  Future<void> visitOutdoorSpot(LatLng coordinates, String locationName) async {
    // #region agent log
    unawaited(
      _agentLog(
        runId: 'route-bug-investigation',
        hypothesisId: 'H4',
        location: 'weather_map_controller.dart:visitOutdoorSpot',
        message: 'outdoor_spot_selected_for_map',
        data: {
          'locationName': locationName,
          'lat': coordinates.latitude,
          'lon': coordinates.longitude,
        },
      ),
    );
    // #endregion
    state = state.copyWith(
      selectedLocation: coordinates,
      selectedLocationLabel: locationName,
    );
    WeatherMapDebugLog.selectedPinSet(coordinates, locationName);
    await _refreshWeatherForActiveLocation();
  }

  void setRoute({
    required List<LatLng> points,
    required double distanceKm,
    required double durationMinutes,
    required String mode,
  }) {
    // #region agent log
    unawaited(
      _agentLog(
        runId: 'route-bug-investigation',
        hypothesisId: 'H5',
        location: 'weather_map_controller.dart:setRoute',
        message: 'route_committed_to_state',
        data: {
          'pointCount': points.length,
          'firstPoint': {
            'lat': points.isNotEmpty ? points.first.latitude : null,
            'lon': points.isNotEmpty ? points.first.longitude : null,
          },
          'lastPoint': {
            'lat': points.isNotEmpty ? points.last.latitude : null,
            'lon': points.isNotEmpty ? points.last.longitude : null,
          },
          'distanceKm': distanceKm,
          'durationMinutes': durationMinutes,
          'mode': mode,
        },
      ),
    );
    // #endregion
    state = state.copyWith(
      routePoints: points,
      routeDistanceKm: distanceKm,
      routeDurationMinutes: durationMinutes,
      routeMode: mode,
    );
  }

  void clearRoute() {
    state = state.copyWith(
      routePoints: const [],
      routeDistanceKm: null,
      routeDurationMinutes: null,
      routeMode: null,
    );
  }

  Future<void> selectLayer(WeatherLayer layer) async {
    if (layer == state.selectedLayer) return;

    state = state.copyWith(
      selectedLayer: layer,
      isLoadingWeather: true,
      selectedTimelineIndex: 0,
      isTimelinePlaying: false,
      error: null,
    );

    await _refreshWeatherForActiveLocation();
  }

  /// Sidebar "Refresh": clear selected pin, use GPS or fallback for weather, keep map camera (no logic here).
  Future<void> refresh() async {
    WeatherMapDebugLog.sidebarRefreshPressed();
    state = state.copyWith(selectedLocation: null, selectedLocationLabel: null);
    WeatherMapDebugLog.selectedPinCleared('sidebar_refresh');
    await _refreshWeatherForActiveLocation();
  }

  /// Error-banner retry: refetch weather only; keep selected pin and camera.
  Future<void> reloadWeatherOnly() async {
    WeatherMapDebugLog.reloadWeatherOnlyPressed();
    await _refreshWeatherForActiveLocation();
  }

  void toggleInfoExpanded() {
    state = state.copyWith(isInfoExpanded: !state.isInfoExpanded);
  }

  void dismissError() {
    state = state.copyWith(error: null);
  }

  void selectTimelineIndex(int index) {
    if (state.timelineMaps.isEmpty) return;
    final bounded = index.clamp(0, state.timelineMaps.length - 1);
    state = state.copyWith(
      selectedTimelineIndex: bounded,
      currentMap: state.timelineMaps[bounded],
      isTimelinePlaying: false,
      error: null,
    );
  }

  void playNextTimelineStep() {
    if (state.timelineMaps.isEmpty) return;
    final nextIndex =
        (state.selectedTimelineIndex + 1) % state.timelineMaps.length;
    state = state.copyWith(
      selectedTimelineIndex: nextIndex,
      currentMap: state.timelineMaps[nextIndex],
      isTimelinePlaying: true,
      error: null,
    );
  }

  void stopTimelinePlayback() {
    if (!state.isTimelinePlaying) return;
    state = state.copyWith(isTimelinePlaying: false);
  }

  Future<void> _agentLog({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, Object?> data,
  }) async {
    final payload = <String, Object?>{
      'sessionId': 'ede35a',
      'runId': runId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      await Dio().post(
        'http://127.0.0.1:7942/ingest/e2e89654-45f0-4063-87a1-a8bc03b32f26',
        data: payload,
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': 'ede35a',
          },
        ),
      );
    } catch (_) {}
  }
}

final weatherMapNotifierProvider =
    StateNotifierProvider<WeatherMapNotifier, WeatherMapState>((ref) {
      final weatherMapService = ref.watch(weatherMapServiceProvider);
      final geolocationService = GeolocationService();
      final geocodingService = GeocodingService();
      return WeatherMapNotifier(
        ref,
        weatherMapService,
        geolocationService,
        geocodingService,
      );
    });
