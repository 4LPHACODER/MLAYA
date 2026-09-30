import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../community/application/providers/community_providers.dart';
import '../../application/providers/app_preferences_providers.dart';
import '../../domain/entities/app_preferences.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appPreferencesProvider);
    final preferencesNotifier = ref.read(appPreferencesProvider.notifier);
    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    final user = authState.user;
    final myAddedSpots = ref.watch(myAddedSpotsProvider);
    final myCapturedMoments = ref.watch(myCapturedMomentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user?.photoUrl == null
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              title: Text(user?.displayName ?? 'Malaya user'),
              subtitle: Text(user?.email ?? 'No email available'),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Map',
            children: [
              _DropdownRow<MapStylePreference>(
                label: 'Map style',
                value: preferences.mapStyle,
                items: MapStylePreference.values,
                itemLabel: (value) => value.label,
                onChanged: (value) {
                  if (value != null) {
                    preferencesNotifier.setMapStyle(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Notifications',
            children: [
              SwitchListTile(
                value: preferences.notificationsEnabled,
                title: const Text('Enable weather notifications'),
                subtitle: const Text(
                  'Keep this on to allow future severe weather alerts.',
                ),
                onChanged: preferencesNotifier.setNotificationsEnabled,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Units',
            children: [
              _DropdownRow<TemperatureUnitPreference>(
                label: 'Temperature unit',
                value: preferences.temperatureUnit,
                items: TemperatureUnitPreference.values,
                itemLabel: (value) => value.label,
                onChanged: (value) {
                  if (value != null) {
                    preferencesNotifier.setTemperatureUnit(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _DropdownRow<WindSpeedUnitPreference>(
                label: 'Wind speed unit',
                value: preferences.windSpeedUnit,
                items: WindSpeedUnitPreference.values,
                itemLabel: (value) => value.label,
                onChanged: (value) {
                  if (value != null) {
                    preferencesNotifier.setWindSpeedUnit(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'My Added Spots',
            children: [
              myAddedSpots.when(
                data: (spots) {
                  if (spots.isEmpty) {
                    return const Text('No added spots yet.');
                  }
                  return Column(
                    children: spots
                        .take(5)
                        .map(
                          (spot) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                spot.imageUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              spot.spotName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${spot.category} • ${DateFormat('MMM d, y').format(spot.createdAt.toLocal())}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Failed to load spots: $error'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'My Captured Moments',
            children: [
              myCapturedMoments.when(
                data: (moments) {
                  if (moments.isEmpty) {
                    return const Text('No captured moments yet.');
                  }
                  return Column(
                    children: moments
                        .take(5)
                        .map(
                          (moment) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                moment.imageUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: Text(
                              moment.caption?.trim().isNotEmpty == true
                                  ? moment.caption!
                                  : 'Untitled moment',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              DateFormat(
                                'MMM d, y • h:mm a',
                              ).format(moment.createdAt.toLocal()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('Failed to load moments: $error'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: authState.isLoading
                ? null
                : () async {
                    await authNotifier.signOut();
                  },
            icon: authState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(authState.isLoading ? 'Signing out...' : 'Log out'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
