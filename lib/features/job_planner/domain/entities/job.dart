enum JobStatus { scheduled, ongoing, completed, delayed }

class JobEntity {
  final String id;
  final String name;

  /// The user who created/owns the job (user id)
  final String userId;

  /// Reference to the plot (plot id)
  final String? plotId;

  /// Reference to the control unit used for this job
  final String? controlUnitId;

  /// When the job was created
  final DateTime createdAt;

  /// Scheduled time for the job (nullable)
  final DateTime? scheduleTime;

  /// Operator assigned to the job (operator id)
  final String? operatorId;

  /// Spray rate (L/min or L/ha depending on context)
  final double? sprayRate;

  /// Product mix / materials for the job
  final List<Map<String, dynamic>>? productMix;

  /// Current status of the job
  final JobStatus status;

  JobEntity({
    required this.id,
    required this.name,
    required this.userId,
    this.plotId,
    this.controlUnitId,
    required this.createdAt,
    this.scheduleTime,
    this.operatorId,
    this.sprayRate,
    this.productMix,
    required this.status,
  });
}
