import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Debug-only logging for map / pin / weather flows (no PII beyond coordinates).
class WeatherMapDebugLog {
  WeatherMapDebugLog._();

  static void mapTapped(LatLng point, double? zoomBefore) {
    if (!kDebugMode) return;
    debugPrint(
      '[WindifyMap] map_tapped lat=${point.latitude} lng=${point.longitude} '
      'zoom_before=$zoomBefore',
    );
  }

  static void panApplied(LatLng target, double zoom, String reason) {
    if (!kDebugMode) return;
    debugPrint(
      '[WindifyMap] camera_pan lat=${target.latitude} lng=${target.longitude} '
      'zoom=$zoom reason=$reason',
    );
  }

  static void panSkipped(String reason, String because) {
    if (!kDebugMode) return;
    debugPrint(
      '[WindifyMap] camera_pan_skipped reason=$reason because=$because',
    );
  }

  static void selectedPinSet(LatLng point, String? label) {
    if (!kDebugMode) return;
    debugPrint(
      '[WindifyMap] selected_pin_set lat=${point.latitude} lng=${point.longitude} '
      'label=${label ?? '(null)'}',
    );
  }

  static void selectedPinCleared(String reason) {
    if (!kDebugMode) return;
    debugPrint('[WindifyMap] selected_pin_cleared reason=$reason');
  }

  static void sidebarRefreshPressed() {
    if (!kDebugMode) return;
    debugPrint('[WindifyMap] refresh_sidebar_pressed');
  }

  static void reloadWeatherOnlyPressed() {
    if (!kDebugMode) return;
    debugPrint('[WindifyMap] reload_weather_only (error retry)');
  }

  static void activeWeatherTarget(LatLng coords, String label) {
    if (!kDebugMode) return;
    debugPrint(
      '[WindifyMap] active_weather_location lat=${coords.latitude} '
      'lng=${coords.longitude} label=$label',
    );
  }

  static void routeGenerated({
    required int points,
    required double distanceKm,
    required double durationMinutes,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[WindifyMap] route_generated points=$points distance_km=$distanceKm duration_min=$durationMinutes',
    );
  }

  static void routeGenerationFailed(String reason) {
    if (!kDebugMode) return;
    debugPrint('[WindifyMap] route_generation_failed reason=$reason');
  }
}
