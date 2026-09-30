import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:windify_v2/core/config/env_config.dart';

class RouteService {
  RouteService({Dio? dio})
    : _dio = dio ?? Dio(),
      _mapboxToken = EnvConfig.mapboxAccessToken ?? '';

  final Dio _dio;
  final String _mapboxToken;

  Future<RouteResult> buildRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // #region agent log
    unawaited(
      _agentLog(
        runId: 'route-bug-investigation',
        hypothesisId: 'H1',
        location: 'route_service.dart:buildRoute:entry',
        message: 'route_build_requested',
        data: {
          'originLat': origin.latitude,
          'originLon': origin.longitude,
          'destinationLat': destination.latitude,
          'destinationLon': destination.longitude,
          'tokenConfigured': _mapboxToken.isNotEmpty,
        },
      ),
    );
    // #endregion
    _debug(
      '[MapRoute] destination lat=${destination.latitude} lon=${destination.longitude}',
    );
    if (_mapboxToken.isEmpty) {
      throw StateError('Mapbox token is not configured.');
    }
    final endpoint =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
    // #region agent log
    unawaited(
      _agentLog(
        runId: 'route-bug-investigation',
        hypothesisId: 'H1',
        location: 'route_service.dart:buildRoute:request',
        message: 'mapbox_directions_request_prepared',
        data: {
          'endpoint': endpoint,
          'query': {
            'overview': 'full',
            'geometries': 'polyline',
            'steps': false,
          },
        },
      ),
    );
    // #endregion
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: {
          'overview': 'full',
          'geometries': 'polyline',
          'steps': false,
          'access_token': _mapboxToken,
        },
      );
      final routes = response.data?['routes'];
      if (routes is! List || routes.isEmpty) {
        throw StateError('No route available for this destination.');
      }
      final first = routes.first as Map<String, dynamic>;
      final encoded = first['geometry']?.toString() ?? '';
      if (encoded.isEmpty) {
        throw StateError('Route geometry is unavailable.');
      }
      // #region agent log
      unawaited(
        _agentLog(
          runId: 'route-bug-investigation',
          hypothesisId: 'H2',
          location: 'route_service.dart:buildRoute:response',
          message: 'mapbox_directions_response_received',
          data: {
            'httpStatus': response.statusCode,
            'routeCount': routes.length,
            'geometryType': first['geometry']?.runtimeType.toString(),
            'geometryLength': encoded.length,
            'distanceMeters': (first['distance'] as num?)?.toDouble(),
            'durationSeconds': (first['duration'] as num?)?.toDouble(),
          },
        ),
      );
      // #endregion
      final points = _decodePolyline(encoded);
      if (points.length < 2) {
        throw StateError('Route could not be generated.');
      }
      final firstPoint = points.first;
      final lastPoint = points.last;
      // #region agent log
      unawaited(
        _agentLog(
          runId: 'route-bug-investigation',
          hypothesisId: 'H2',
          location: 'route_service.dart:buildRoute:decoded',
          message: 'mapbox_polyline_decoded',
          data: {
            'decodedCount': points.length,
            'firstPoint': {'lat': firstPoint.latitude, 'lon': firstPoint.longitude},
            'lastPoint': {'lat': lastPoint.latitude, 'lon': lastPoint.longitude},
          },
        ),
      );
      // #endregion
      final distanceMeters = (first['distance'] as num?)?.toDouble() ?? 0;
      final durationSeconds = (first['duration'] as num?)?.toDouble() ?? 0;
      _debug(
        'route_generation_success points=${points.length} distance=$distanceMeters duration=$durationSeconds',
      );
      return RouteResult(
        points: points,
        distanceKm: distanceMeters / 1000.0,
        durationMinutes: durationSeconds / 60.0,
        mode: 'driving',
      );
    } on DioException catch (e) {
      _debug('route_generation_failure status=${e.response?.statusCode}');
      throw StateError('Unable to generate route right now.');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final polyline = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  void _debug(String message) {
    if (!kDebugMode) return;
    debugPrint('[OutdoorSpots] $message');
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
      await _dio.post(
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

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;
  final String mode;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.mode,
  });

  String get distanceLabel {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final totalMinutes = max(1, durationMinutes.round());
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    }
    return '$totalMinutes min';
  }
}
