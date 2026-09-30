import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/added_spot.dart';
import '../../domain/entities/captured_moment.dart';
import '../../infrastructure/repositories/community_repository.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

final myAddedSpotsProvider = FutureProvider.autoDispose<List<AddedSpot>>((
  ref,
) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null) return const [];
  final repository = ref.watch(communityRepositoryProvider);
  return repository.fetchMyAddedSpots(user.id);
});

final publicAddedSpotsProvider = FutureProvider.autoDispose<List<AddedSpot>>((
  ref,
) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.fetchPublicAddedSpots();
});

final myCapturedMomentsProvider =
    FutureProvider.autoDispose<List<CapturedMoment>>((ref) async {
      final user = ref.watch(authControllerProvider).user;
      if (user == null) return const [];
      final repository = ref.watch(communityRepositoryProvider);
      return repository.fetchMyCapturedMoments(user.id);
    });
