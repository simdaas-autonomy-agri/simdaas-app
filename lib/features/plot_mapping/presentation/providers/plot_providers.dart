import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import '../../data/datasources/plot_remote_data_source.dart';
import '../../data/repositories/plot_repository_impl.dart';

final plotRepoProvider = Provider((ref) =>
    PlotRepositoryImpl(PlotRemoteDataSourceImpl(ref.read(apiServiceProvider))));

final plotsListProvider = FutureProvider.family((ref, String userId) async {
  final repo = ref.read(plotRepoProvider);
  return repo.getPlots(userId);
});
