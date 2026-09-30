import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:windify_v2/features/notifications/domain/entities/app_notification.dart';
import 'package:windify_v2/features/notifications/presentation/providers/notification_provider.dart';
import 'package:windify_v2/features/auth/presentation/controllers/auth_controller.dart';
import 'package:windify_v2/features/community/presentation/pages/community_spots_page.dart';
import 'package:windify_v2/features/outdoor_recommendations/application/providers/outdoor_recommendations_providers.dart';
import 'package:windify_v2/features/outdoor_recommendations/domain/entities/recommended_spot_model.dart';
import 'package:windify_v2/features/outdoor_recommendations/infrastructure/repositories/recommended_spot_repository.dart';

class OutdoorRecommendationsPage extends ConsumerStatefulWidget {
  const OutdoorRecommendationsPage({
    super.key,
    required this.activeCenter,
    required this.centerLabel,
  });

  final LatLng activeCenter;
  final String centerLabel;

  @override
  ConsumerState<OutdoorRecommendationsPage> createState() =>
      _OutdoorRecommendationsPageState();
}

class _OutdoorRecommendationsPageState
    extends ConsumerState<OutdoorRecommendationsPage> {
  final TextEditingController _activityController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String _selectedActivity = 'Swimming';
  List<RecommendedSpotModel> _spots = const [];

  static const List<String> _quickActivities = [
    'Swimming',
    'Surfing',
    'Skateboarding',
    'Camping',
    'Falls',
    'Hiking',
    'Beach',
    'Fishing',
  ];

  @override
  void initState() {
    super.initState();
    _activityController.text = _selectedActivity;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search(_selectedActivity);
    });
  }

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _search(String activity) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedActivity = activity.trim().isEmpty
          ? _selectedActivity
          : activity;
    });
    try {
      final results = await ref
          .read(recommendedSpotServiceProvider)
          .recommend(activity: _selectedActivity, center: widget.activeCenter);
      if (!mounted) return;
      setState(() {
        _spots = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _spots = const [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSpot(RecommendedSpotModel spot) async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      _showMessage('Sign in to save spots.');
      return;
    }
    try {
      await ref
          .read(recommendedSpotRepositoryProvider)
          .saveSpot(userId: user.id, spot: spot);
      await ref.read(notificationsProvider.notifier).addNotification(
        title: 'Spot saved',
        message: '${spot.name} was added to your saved spots.',
        type: NotificationType.savedSpot,
        spotName: spot.name,
        latitude: spot.latitude,
        longitude: spot.longitude,
      );
      _showMessage('Spot saved successfully.');
    } on RecommendedSpotSaveException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Could not save spot right now.');
    }
  }

  void _visitSpot(RecommendedSpotModel spot) {
    Navigator.of(context).pop(
      OutdoorSpotActionResult(type: OutdoorSpotActionType.visit, spot: spot),
    );
  }

  void _routeToSpot(RecommendedSpotModel spot) {
    if (!spot.hasValidCoordinates) {
      _showMessage('Route unavailable for this spot.');
      return;
    }
    debugPrint(
      '[OutdoorSpots] Route pressed: ${spot.name} lat=${spot.latitude} lon=${spot.longitude}',
    );
    // #region agent log
    unawaited(
      _agentLog(
        runId: 'route-bug-investigation',
        hypothesisId: 'H4',
        location: 'outdoor_recommendations_page.dart:_routeToSpot',
        message: 'route_pressed_from_outdoor_spots',
        data: {
          'spotName': spot.name,
          'lat': spot.latitude,
          'lon': spot.longitude,
          'hasValidCoordinates': spot.hasValidCoordinates,
        },
      ),
    );
    // #endregion
    Navigator.of(context).pop(
      OutdoorSpotActionResult(type: OutdoorSpotActionType.route, spot: spot),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Outdoor Spots',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Community spots',
                    icon: const Icon(Icons.groups_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CommunitySpotsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: _activityController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _search,
                  decoration: InputDecoration(
                    hintText: 'Search around Current Location',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.centerLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final activity = _quickActivities[index];
                    final isSelected =
                        _selectedActivity.toLowerCase() ==
                        activity.toLowerCase();
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(activity),
                      onSelected: (_) {
                        _activityController.text = activity;
                        _search(activity);
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemCount: _quickActivities.length,
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.orange),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _search(_selectedActivity),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_spots.isEmpty) {
      final isFishing = _selectedActivity.toLowerCase().trim() == 'fishing';
      final isBeach = _selectedActivity.toLowerCase().trim() == 'beach' ||
          _selectedActivity.toLowerCase().trim() == 'beaches';
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isFishing
                  ? 'No fishing spots found nearby. Try increasing the search distance or searching near a river, beach, bay, or coastal area.'
                  : isBeach
                      ? 'No beach spots found nearby. Try increasing the distance or searching around another location.'
                      : 'No nearby spots found. Try increasing the distance or selecting another activity.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _spots.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final spot = _spots[index];
        final badgeColor = _safetyColor(spot.safetyAdvice?.level);
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spot.address ?? 'Address unavailable',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _MetaPill(icon: Icons.route, text: spot.distanceLabel),
                    for (final tag in spot.displayTags.take(3))
                      _MetaPill(icon: Icons.interests, text: tag),
                  ],
                ),
                if (spot.description != null &&
                    spot.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    spot.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 10),
                if (spot.weather != null)
                  Row(
                    children: [
                      Image.network(
                        'https://openweathermap.org/img/wn/${spot.weather!.icon}@2x.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.cloud_outlined, size: 22),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${spot.weather!.temperature.toStringAsFixed(1)}°C • '
                          '${spot.weather!.condition} • '
                          'Humidity ${spot.weather!.humidity}% • '
                          'Wind ${spot.weather!.windSpeed.toStringAsFixed(1)} m/s',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (spot.safetyAdvice != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '${spot.safetyAdvice!.label}: ${spot.safetyAdvice!.explanation}',
                      style: TextStyle(color: badgeColor),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final hasRoute = spot.hasValidCoordinates;
                    final routeButton = ElevatedButton.icon(
                      onPressed: hasRoute ? () => _routeToSpot(spot) : null,
                      icon: const Icon(Icons.directions),
                      label: const Text('Route'),
                    );
                    if (constraints.maxWidth >= 360) {
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _visitSpot(spot),
                              icon: const Icon(Icons.explore_outlined),
                              label: const Text('Visit'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _saveSpot(spot),
                              icon: const Icon(Icons.bookmark_add_outlined),
                              label: const Text('Save'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: routeButton),
                        ],
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _visitSpot(spot),
                          icon: const Icon(Icons.explore_outlined),
                          label: const Text('Visit'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _saveSpot(spot),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Save'),
                        ),
                        routeButton,
                      ],
                    );
                  },
                ),
                if (!spot.hasValidCoordinates) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Route unavailable for this spot.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _safetyColor(WeatherSafetyLevel? level) {
    switch (level) {
      case WeatherSafetyLevel.good:
        return Colors.green.shade700;
      case WeatherSafetyLevel.caution:
        return Colors.orange.shade700;
      case WeatherSafetyLevel.avoid:
        return Colors.red.shade700;
      case null:
        return Colors.blueGrey.shade700;
    }
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14), const SizedBox(width: 6), Text(text)],
      ),
    );
  }
}
