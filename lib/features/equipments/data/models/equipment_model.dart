import '../../domain/entities/equipment.dart';

class EquipmentModel extends EquipmentEntity {
  EquipmentModel({
    required super.id,
    required super.category,
    required super.name,
    super.userId,
    super.status,
    super.controlUnitId,
    super.mountingHeight,
    super.lidarNozzleDistance,
    super.ultrasonicDistance,
    super.wheelDiameter,
    super.screwsInWheel,
    super.axleLength,
  super.nozzleCount,
  super.tankCapacity,
    super.hingeToAxle,
    super.hingeToNozzle,
    super.hingeToControlUnit,
    super.macAddress,
    super.linkedSprayerId,
    super.linkedTractorId,
    super.linkedPlotId,
    super.createdAt,
    super.updatedAt,
  });

  factory EquipmentModel.fromJson(String id, Map<String, dynamic> json) =>
      // dispatch to specific typed model based on category
      (json['category'] as String? ?? '').toString() == 'tractor'
          ? TractorModel(
              id: id,
              category: json['category'] as String? ?? '',
              name: json['name'] as String? ?? '',
              // prefer canonical 'userId' but fall back to legacy 'ownerId'
              userId: json['userId'] as String? ?? json['ownerId'] as String?,
              status: json['status'] as String?,
              controlUnitId: json['controlUnitId'] as String?,
              mountingHeight: (json['mountingHeight'] as num?)?.toDouble(),
              lidarNozzleDistance:
                  (json['lidarNozzleDistance'] as num?)?.toDouble(),
              ultrasonicDistance:
                  (json['ultrasonicDistance'] as num?)?.toDouble(),
              wheelDiameter: (json['wheelDiameter'] as num?)?.toDouble(),
              screwsInWheel: (json['screwsInWheel'] as num?)?.toInt(),
              axleLength: (json['axleLength'] as num?)?.toDouble(),
              createdAt: json['createdAt'] != null
                  ? DateTime.tryParse(json['createdAt'].toString())
                  : null,
              updatedAt: json['updatedAt'] != null
                  ? DateTime.tryParse(json['updatedAt'].toString())
                  : null,
            )
          : (json['category'] as String? ?? '').toString() == 'control_unit'
              ? ControlUnitModel(
                  id: id,
                  category: json['category'] as String? ?? '',
                  name: json['name'] as String? ?? '',
                  userId:
                      json['userId'] as String? ?? json['ownerId'] as String?,
                  status: json['status'] as String?,
                  controlUnitId: json['controlUnitId'] as String?,
                  mountingHeight: (json['mountingHeight'] as num?)?.toDouble(),
                  lidarNozzleDistance:
                      (json['lidarNozzleDistance'] as num?)?.toDouble(),
                  ultrasonicDistance:
                      (json['ultrasonicDistance'] as num?)?.toDouble(),
                  wheelDiameter: (json['wheelDiameter'] as num?)?.toDouble(),
                  screwsInWheel: (json['screwsInWheel'] as num?)?.toInt(),
                  hingeToControlUnit:
                      (json['hingeToControlUnit'] as num?)?.toDouble(),
                  macAddress: json['macAddress'] as String?,
                  linkedSprayerId: json['linkedSprayerId'] as String?,
                  linkedTractorId: json['linkedTractorId'] as String?,
                  linkedPlotId: json['linkedPlotId'] as String?,
                  createdAt: json['createdAt'] != null
                      ? DateTime.tryParse(json['createdAt'].toString())
                      : null,
                  updatedAt: json['updatedAt'] != null
                      ? DateTime.tryParse(json['updatedAt'].toString())
                      : null,
                )
              : SprayerModel(
                  id: id,
                  category: json['category'] as String? ?? '',
                  name: json['name'] as String? ?? '',
                  userId:
                      json['userId'] as String? ?? json['ownerId'] as String?,
                  status: json['status'] as String?,
                  controlUnitId: json['controlUnitId'] as String?,
                  mountingHeight: (json['mountingHeight'] as num?)?.toDouble(),
                  lidarNozzleDistance:
                      (json['lidarNozzleDistance'] as num?)?.toDouble(),
                  ultrasonicDistance:
                      (json['ultrasonicDistance'] as num?)?.toDouble(),
                  wheelDiameter: (json['wheelDiameter'] as num?)?.toDouble(),
                  screwsInWheel: (json['screwsInWheel'] as num?)?.toInt(),
          axleLength: (json['axleLength'] as num?)?.toDouble(),
          nozzleCount: (json['nozzleCount'] as num?)?.toInt(),
          tankCapacity: (json['tankCapacity'] as num?)?.toDouble(),
          hingeToAxle: (json['hingeToAxle'] as num?)?.toDouble(),
          hingeToNozzle: (json['hingeToNozzle'] as num?)?.toDouble(),
          hingeToControlUnit:
            (json['hingeToControlUnit'] as num?)?.toDouble(),
                  createdAt: json['createdAt'] != null
                      ? DateTime.tryParse(json['createdAt'].toString())
                      : null,
                  updatedAt: json['updatedAt'] != null
                      ? DateTime.tryParse(json['updatedAt'].toString())
                      : null,
                );

  Map<String, dynamic> toJson() => {
        'category': category,
        'name': name,
        // canonical field
        'userId': userId,
        // keep legacy key for compatibility
        'ownerId': userId,
        'status': status,
        'controlUnitId': controlUnitId,
        'mountingHeight': mountingHeight,
        'lidarNozzleDistance': lidarNozzleDistance,
        'ultrasonicDistance': ultrasonicDistance,
        'wheelDiameter': wheelDiameter,
        'screwsInWheel': screwsInWheel,
        'axleLength': axleLength,
  'nozzleCount': nozzleCount,
  'tankCapacity': tankCapacity,
        'hingeToAxle': hingeToAxle,
        'hingeToNozzle': hingeToNozzle,
        'hingeToControlUnit': hingeToControlUnit,
        'macAddress': macAddress,
        'linkedSprayerId': linkedSprayerId,
        'linkedTractorId': linkedTractorId,
        'linkedPlotId': linkedPlotId,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

// Specific typed models for clarity and future specialization
class TractorModel extends EquipmentModel {
  TractorModel({
    required super.id,
    required super.category,
    required super.name,
    super.userId,
    super.status,
    super.controlUnitId,
    super.mountingHeight,
    super.lidarNozzleDistance,
    super.ultrasonicDistance,
    super.wheelDiameter,
    super.screwsInWheel,
    super.axleLength,
    super.createdAt,
    super.updatedAt,
  });
}

class SprayerModel extends EquipmentModel {
  SprayerModel({
    required super.id,
    required super.category,
    required super.name,
    super.userId,
    super.status,
    super.controlUnitId,
    super.mountingHeight,
    super.lidarNozzleDistance,
    super.ultrasonicDistance,
    super.wheelDiameter,
    super.screwsInWheel,
    super.hingeToAxle,
    super.hingeToNozzle,
    super.hingeToControlUnit,
    super.axleLength,
    super.nozzleCount,
    super.tankCapacity,
    super.createdAt,
    super.updatedAt,
  });
}

class ControlUnitModel extends EquipmentModel {
  ControlUnitModel({
    required super.id,
    required super.category,
    required super.name,
    super.userId,
    super.status,
    super.controlUnitId,
    super.mountingHeight,
    super.lidarNozzleDistance,
    super.ultrasonicDistance,
    super.wheelDiameter,
    super.screwsInWheel,
    super.hingeToControlUnit,
    super.macAddress,
    super.linkedSprayerId,
    super.linkedTractorId,
    super.linkedPlotId,
    super.createdAt,
    super.updatedAt,
  });
}
