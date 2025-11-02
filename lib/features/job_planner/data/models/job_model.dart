import '../../domain/entities/job.dart';

class JobModel extends JobEntity {
  JobModel({
    required super.id,
    required super.name,
    required super.userId,
    super.plotId,
    super.controlUnitId,
    required super.createdAt,
    super.scheduleTime,
    super.operatorId,
    super.sprayRate,
    super.productMix,
    required super.status,
    // ownerId removed in favor of canonical userId; keep ownerId key in JSON for compatibility
  });

  factory JobModel.fromJson(String id, Map<String, dynamic> json) {
    // parse createdAt
    DateTime parseCreated(dynamic s) {
      if (s == null) return DateTime.now();
      if (s is String) return DateTime.tryParse(s) ?? DateTime.now();
      if (s is int) return DateTime.fromMillisecondsSinceEpoch(s);
      return DateTime.now();
    }

    DateTime createdAt = parseCreated(json['createdAt'] ??
        json['created'] ??
        json['dateTime'] ??
        json['created_at']);

    DateTime? parseSchedule(dynamic s) {
      if (s == null) return null;
      if (s is String) return DateTime.tryParse(s);
      if (s is int) return DateTime.fromMillisecondsSinceEpoch(s);
      return null;
    }

    final schedule = parseSchedule(
        json['scheduleTime'] ?? json['scheduledAt'] ?? json['schedule_time']);

    JobStatus determineStatus() {
      final s = (json['status'] as String?) ?? (json['state'] as String?);
      if (s != null) {
        switch (s.toLowerCase()) {
          case 'scheduled':
            return JobStatus.scheduled;
          case 'ongoing':
            return JobStatus.ongoing;
          case 'completed':
            return JobStatus.completed;
          case 'delayed':
            return JobStatus.delayed;
        }
      }
      // Default to scheduled if no status from server
      return JobStatus.scheduled;
    }

    final status = determineStatus();

    // operator may be an id or an object
    String? operatorId;
    final opVal = json['operator'] ?? json['operatorId'] ?? json['operator_id'];
    if (opVal is String)
      operatorId = opVal;
    else if (opVal is int)
      operatorId = opVal.toString();
    else if (opVal is Map)
      operatorId = (opVal['id'] ?? opVal['pk'])?.toString();

    // productMix: normalize into a list of maps where possible
    List<Map<String, dynamic>>? normalizedProductMix;
    final rawPm = json['productMix'] ?? json['product_mix'];
    if (rawPm == null) {
      normalizedProductMix = null;
    } else if (rawPm is List) {
      normalizedProductMix = rawPm.map<Map<String, dynamic>>((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        return {'id': e};
      }).toList();
    } else if (rawPm is Map) {
      normalizedProductMix = [Map<String, dynamic>.from(rawPm)];
    } else {
      // numeric or string id
      normalizedProductMix = [
        {'id': rawPm}
      ];
    }

    return JobModel(
      id: id,
      name: json['name'] as String? ?? '',
      // userId: prefer 'user' or 'userId' or legacy 'createdBy'
      userId: (json['user']?.toString() ??
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          json['createdBy']?.toString() ??
          ''),
      plotId: (json['plot']?.toString() ??
          json['plotId']?.toString() ??
          json['fieldId']?.toString()),
      controlUnitId: (json['controlUnit']?.toString() ??
          json['controlUnitId']?.toString() ??
          json['control_unit']?.toString()),
      createdAt: createdAt,
      scheduleTime: schedule,
      operatorId: operatorId,
      sprayRate: (() {
        final sr = json['sprayRate'] ?? json['spray_rate'];
        if (sr == null) return null;
        if (sr is num) return sr.toDouble();
        if (sr is String) return double.tryParse(sr);
        return null;
      })(),
      productMix: normalizedProductMix,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'userId': userId,
        'status': status.toString().split('.').last,
        'plot': plotId,
        'controlUnit': controlUnitId,
        'createdAt': createdAt.toIso8601String(),
        'scheduleTime': scheduleTime?.toIso8601String(),
        'operator': operatorId,
        'sprayRate': sprayRate,
        'productMix': productMix,
        // keep legacy ownerId for backwards compatibility
        'ownerId': userId,
      };
}
