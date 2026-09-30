import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:windify_v2/features/outdoor_recommendations/application/services/activity_weather_advisor.dart';
import 'package:windify_v2/features/outdoor_recommendations/application/services/recommended_spot_service.dart';
import 'package:windify_v2/features/outdoor_recommendations/infrastructure/repositories/recommended_spot_repository.dart';
import 'package:windify_v2/features/outdoor_recommendations/infrastructure/services/geoapify_service.dart';
import 'package:windify_v2/features/outdoor_recommendations/infrastructure/services/route_service.dart';

final activityWeatherAdvisorProvider = Provider<ActivityWeatherAdvisor>((ref) {
  return const ActivityWeatherAdvisor();
});

final geoapifyServiceProvider = Provider<GeoapifyService>((ref) {
  return GeoapifyService();
});

final recommendedSpotServiceProvider = Provider<RecommendedSpotService>((ref) {
  final advisor = ref.watch(activityWeatherAdvisorProvider);
  final geoapify = ref.watch(geoapifyServiceProvider);
  return RecommendedSpotService(
    activityWeatherAdvisor: advisor,
    geoapifyService: geoapify,
  );
});

final recommendedSpotRepositoryProvider = Provider<RecommendedSpotRepository>((
  ref,
) {
  return RecommendedSpotRepository();
});

final routeServiceProvider = Provider<RouteService>((ref) {
  return RouteService();
});
