import 'package:dio/dio.dart';

import '../../domain/entities/weather_data.dart';
import '../../../../core/config/env_config.dart';

/// Service for fetching weather data from OpenWeather API
class WeatherApiService {
  final Dio _dio;
  final String _apiKey;
  final String _baseUrl;

  WeatherApiService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? EnvConfig.openWeatherApiKey ?? '',
        _baseUrl = EnvConfig.openWeatherBaseUrl;

  /// Fetch current weather by coordinates
  Future<CurrentWeather> getCurrentWeatherByCoords({
    required double lat,
    required double lon,
    String units = 'metric',
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
          'OpenWeather API key not configured. '
          'Please check your .env file contains OPENWEATHER_API_KEY=your_key',
      );
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': _apiKey,
          'units': units,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return CurrentWeather.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw StateError(
            'Failed to fetch weather data: HTTP ${response.statusCode} ${response.data}',
        );
      }
    } on DioException catch (e) {
      _handleDioError(e, 'Weather API');
    }
  }

  /// Get 5-day forecast (useful for wind/wave trends)
  Future<Map<String, dynamic>> getForecast({
    required double lat,
    required double lon,
    String units = 'metric',
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
          'OpenWeather API key not configured. '
          'Please check your .env file contains OPENWEATHER_API_KEY=your_key',
      );
    }

    final response = await _dio.get(
      '$_baseUrl/forecast',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': _apiKey,
        'units': units,
      },
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw StateError(
          'Failed to fetch forecast: HTTP ${response.statusCode} ${response.data}',
      );
    }
  }

  /// Get precipitation/rain data (for radar simulation)
  Future<Map<String, dynamic>?> getPrecipitation({
    required double lat,
    required double lon,
  }) async {
    try {
      final weather = await getCurrentWeatherByCoords(lat: lat, lon: lon);
      return {
        'precipitation': weather.precipitation ?? 0,
        'timestamp': weather.timestamp.toIso8601String(),
      };
    } catch (_) {
      return null;
    }
  }

  Never _handleDioError(DioException e, String source) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw StateError('$source: Connection timeout. Please check your internet.');
    }
    if (e.type == DioExceptionType.badResponse) {
      final status = e.response?.statusCode;
      if (status == 401) {
        throw StateError('$source: Invalid API key. Please check your OPENWEATHER_API_KEY.');
      }
      if (status == 429) {
        throw StateError('$source: Request limit exceeded. Please try again later.');
      }
      throw StateError('$source: HTTP $status ${e.response?.statusMessage ?? ''}');
    }
    if (e.type == DioExceptionType.badCertificate) {
      throw StateError('$source: SSL certificate error. Please check your network.');
    }
    throw StateError('$source: Unknown error: ${e.message}');
  }
}
