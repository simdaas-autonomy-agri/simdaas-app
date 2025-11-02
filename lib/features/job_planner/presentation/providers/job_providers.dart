import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import '../../data/datasources/job_remote_data_source.dart';
import '../../data/repositories/job_repository_impl.dart';

final jobRepoProvider = Provider((ref) =>
    JobRepositoryImpl(JobRemoteDataSourceImpl(ref.read(apiServiceProvider))));

final jobsListProvider = FutureProvider.family((ref, String userId) async {
  final repo = ref.read(jobRepoProvider);
  return repo.getJobs(userId);
});

final jobUpdateProvider = Provider((ref) => ref.read(jobRepoProvider));
