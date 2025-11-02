import '../../domain/entities/job.dart';
import '../datasources/job_remote_data_source.dart';
import '../models/job_model.dart';

class JobRepositoryImpl {
  final JobRemoteDataSource remote;
  JobRepositoryImpl(this.remote);

  Future<void> createJob(JobModel job) => remote.createJob(job);
  Future<void> updateJob(JobModel job) => remote.updateJob(job);
  Future<List<JobEntity>> getJobs(String userId) => remote.getJobs(userId);
}
