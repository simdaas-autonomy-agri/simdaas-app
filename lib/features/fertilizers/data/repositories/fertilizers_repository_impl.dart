import '../../data/datasources/fertilizers_remote_data_source.dart';

class FertilizersRepositoryImpl {
  final FertilizersRemoteDataSource remote;
  FertilizersRepositoryImpl(this.remote);

  Future<List<Map<String, dynamic>>> getFertilizers() =>
      remote.getFertilizers();
  Future<List<Map<String, dynamic>>> getMixes() => remote.getFertilizerMixes();
  Future<Map<String, dynamic>> createMix(Map<String, dynamic> payload) =>
      remote.createMix(payload);
  Future<Map<String, dynamic>> createFertilizer(Map<String, dynamic> payload) =>
      remote.createFertilizer(payload);
}
