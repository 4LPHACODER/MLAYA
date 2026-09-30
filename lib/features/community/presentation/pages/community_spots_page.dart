import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/providers/community_providers.dart';

class CommunitySpotsPage extends ConsumerWidget {
  const CommunitySpotsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(publicAddedSpotsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Community Spots')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publicAddedSpotsProvider);
          await ref.read(publicAddedSpotsProvider.future);
        },
        child: spotsAsync.when(
          data: (spots) {
            if (spots.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No community spots yet.')),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              itemCount: spots.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final spot = spots[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(spot.imageUrl, fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.spotName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${spot.category} • by ${spot.uploaderName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (spot.location != null &&
                                spot.location!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(spot.location!),
                            ],
                            if (spot.description != null &&
                                spot.description!.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(spot.description!),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM d, y • h:mm a').format(
                                spot.createdAt.toLocal(),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text(
                  'Failed to load spots.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
