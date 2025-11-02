import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import '../../data/datasources/fertilizers_remote_data_source.dart';
import '../../data/repositories/fertilizers_repository_impl.dart';

final fertilizersRemoteProvider = Provider(
    (ref) => FertilizersRemoteDataSource(ref.read(apiServiceProvider)));

final fertilizersRepoProvider = Provider(
    (ref) => FertilizersRepositoryImpl(ref.read(fertilizersRemoteProvider)));

final fertilizersListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(fertilizersRepoProvider);
  return repo.getFertilizers();
});

final fertilizerMixesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(fertilizersRepoProvider);
  return repo.getMixes();
});

final fertilizerControllerProvider =
    Provider((ref) => FertilizerController(ref));

class FertilizerController {
  final Ref ref;
  FertilizerController(this.ref);

  Future<Map<String, dynamic>> createMix(Map<String, dynamic> payload) async {
    final repo = ref.read(fertilizersRepoProvider);
    final created = await repo.createMix(payload);
    // invalidate mixes list
    ref.invalidate(fertilizerMixesProvider);
    return created;
  }

  Future<Map<String, dynamic>> createFertilizer(
      Map<String, dynamic> payload) async {
    final repo = ref.read(fertilizersRepoProvider);
    final created = await repo.createFertilizer(payload);
    // invalidate fertilizers list
    ref.invalidate(fertilizersListProvider);
    return created;
  }
}
