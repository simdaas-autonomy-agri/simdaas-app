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

  factory EquipmentModel.fromJson(String id, Map<String, dynamic> json) {
    // helper to read either snake_case or camelCase numeric fields
    double? _num(String a, [String? b]) =>
        (json[a] as num?)?.toDouble() ??
        (b != null ? (json[b] as num?)?.toDouble() : null);
    int? _int(String a, [String? b]) =>
        (json[a] as num?)?.toInt() ??
        (b != null ? (json[b] as num?)?.toInt() : null);

    // user id may be provided as userId/ownerId or as nested user object
    String? userId = json['userId'] as String? ?? json['ownerId'] as String?;
    if (userId == null && json['user'] is Map) {
      final u = json['user'] as Map<String, dynamic>;
      userId = u['id'] != null
          ? u['id'].toString()
          : (u['user'] as String? ?? u['username'] as String?);
    }

    final category = (json['category'] as String? ?? '').toString();
    // parse timestamps with snake_case fallback
    DateTime? _parseTime(String a, [String? b]) {
      final v = json[a] ?? (b != null ? json[b] : null);
      return v != null ? DateTime.tryParse(v.toString()) : null;
    }

    if (category == 'tractor') {
      return TractorModel(
        id: id,
        category: category,
        name: json['name'] as String? ?? '',
        userId: userId,
        status: json['status'] as String?,
        controlUnitId: json['controlUnitId'] as String?,
        mountingHeight: _num('mountingHeight', 'mounting_height'),
        lidarNozzleDistance:
            _num('lidarNozzleDistance', 'lidar_nozzle_distance'),
        ultrasonicDistance: _num('ultrasonicDistance', 'ultrasonic_distance'),
        wheelDiameter: _num('wheelDiameter', 'wheel_diameter'),
        screwsInWheel: _int('screwsInWheel', 'screws_per_wheel'),
        axleLength: _num('axleLength', 'axle_length'),
        createdAt: _parseTime('createdAt', 'created_at'),
        updatedAt: _parseTime('updatedAt', 'updated_at'),
      );
    } else if (category == 'control_unit') {
      return ControlUnitModel(
        id: id,
        category: category,
        name: json['name'] as String? ?? '',
        userId: userId,
        status: json['status'] as String?,
        controlUnitId: json['controlUnitId'] as String?,
        mountingHeight: _num('mountingHeight', 'mounting_height'),
        lidarNozzleDistance:
            _num('lidarNozzleDistance', 'lidar_nozzle_distance'),
        ultrasonicDistance: _num('ultrasonicDistance', 'ultrasonic_distance'),
        wheelDiameter: _num('wheelDiameter', 'wheel_diameter'),
        screwsInWheel: _int('screwsInWheel', 'screws_per_wheel'),
        hingeToControlUnit:
            _num('hingeToControlUnit', 'distance_hinge_control_unit'),
        macAddress:
            json['macAddress'] as String? ?? json['mac_address'] as String?,
        linkedSprayerId: json['linkedSprayerId'] as String? ??
            json['linked_sprayer_id'] as String?,
        linkedTractorId: json['linkedTractorId'] as String? ??
            json['linked_tractor_id'] as String?,
        linkedPlotId: json['linkedPlotId'] as String? ??
            json['linked_plot_id'] as String?,
        createdAt: _parseTime('createdAt', 'created_at'),
        updatedAt: _parseTime('updatedAt', 'updated_at'),
      );
    } else {
      // default to SprayerModel
      return SprayerModel(
        id: id,
        category: category,
        name: json['name'] as String? ?? '',
        userId: userId,
        status: json['status'] as String?,
        controlUnitId: json['controlUnitId'] as String? ??
            json['control_unit_id'] as String?,
        mountingHeight: _num('mountingHeight', 'mounting_height'),
        lidarNozzleDistance:
            _num('lidarNozzleDistance', 'lidar_nozzle_distance'),
        ultrasonicDistance: _num('ultrasonicDistance', 'ultrasonic_distance'),
        wheelDiameter: _num('wheelDiameter', 'wheel_diameter'),
        screwsInWheel: _int('screwsInWheel', 'screws_per_wheel'),
        axleLength: _num('axleLength', 'axle_length'),
        nozzleCount: _int('nozzleCount', 'nozzle_count'),
        tankCapacity: _num('tankCapacity', 'tank_capacity'),
        hingeToAxle: _num('hingeToAxle', 'distance_hinge_axle'),
        hingeToNozzle: _num('hingeToNozzle', 'distance_hinge_nozzle'),
        hingeToControlUnit:
            _num('hingeToControlUnit', 'distance_hinge_control_unit'),
        createdAt: _parseTime('createdAt', 'created_at'),
        updatedAt: _parseTime('updatedAt', 'updated_at'),
      );
    }
  }

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
