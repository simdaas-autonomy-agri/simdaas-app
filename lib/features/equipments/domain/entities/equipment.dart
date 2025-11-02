class EquipmentEntity {
  final String id;
  final String category; // e.g., tractor, sprayer
  final String name;
  final String? userId;
  final String? status; // e.g., 'vacant', 'assigned', 'in_service'

  // sprayer-specific fields
  final double? mountingHeight; // meters
  final double? lidarNozzleDistance; // meters
  final double?
      ultrasonicDistance; // meters from center line (for ultrasonic sensors)
  final double? wheelDiameter; // meters
  final int? screwsInWheel;
  // control unit specific
  final String? controlUnitId;
  // tractor-specific
  final double? axleLength;
  // sprayer nozzle / tank
  final int? nozzleCount;
  final double? tankCapacity; // liters
  // sprayer hinge distances
  final double? hingeToAxle;
  final double? hingeToNozzle;
  final double? hingeToControlUnit;
  // control unit specifics
  final String? macAddress;
  final String? linkedSprayerId;
  final String? linkedTractorId;
  final String? linkedPlotId;
  // timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // legacy mounting/w lidar/ultrasonic kept for compatibility

  EquipmentEntity({
    required this.id,
    required this.category,
    required this.name,
    this.userId,
    this.status,
    this.mountingHeight,
    this.lidarNozzleDistance,
    this.ultrasonicDistance,
    this.wheelDiameter,
    this.screwsInWheel,
    this.controlUnitId,
    this.axleLength,
    this.nozzleCount,
    this.tankCapacity,
    this.hingeToAxle,
    this.hingeToNozzle,
    this.hingeToControlUnit,
    this.macAddress,
    this.linkedSprayerId,
    this.linkedTractorId,
    this.linkedPlotId,
    this.createdAt,
    this.updatedAt,
  });
}

class TractorEntity extends EquipmentEntity {
  TractorEntity({
    required String id,
    required String category,
    required String name,
    String? userId,
    String? status,
    double? wheelDiameter,
    int? screwsInWheel,
    double? axleLength,
  }) : super(
          id: id,
          category: category,
          name: name,
          userId: userId,
          status: status,
          wheelDiameter: wheelDiameter,
          screwsInWheel: screwsInWheel,
          axleLength: axleLength,
        );
}

class SprayerEntity extends EquipmentEntity {
  SprayerEntity({
    required String id,
    required String category,
    required String name,
    String? userId,
    String? status,
    double? mountingHeight,
    double? lidarNozzleDistance,
    double? ultrasonicDistance,
    double? hingeToAxle,
    double? hingeToNozzle,
    double? hingeToControlUnit,
    double? axleLength,
    int? nozzleCount,
    double? tankCapacity,
  }) : super(
          id: id,
          category: category,
          name: name,
          userId: userId,
          status: status,
          mountingHeight: mountingHeight,
          lidarNozzleDistance: lidarNozzleDistance,
          ultrasonicDistance: ultrasonicDistance,
          hingeToAxle: hingeToAxle,
          hingeToNozzle: hingeToNozzle,
          hingeToControlUnit: hingeToControlUnit,
          axleLength: axleLength,
          nozzleCount: nozzleCount,
          tankCapacity: tankCapacity,
        );
}

class ControlUnitEntity extends EquipmentEntity {
  ControlUnitEntity({
    required String id,
    required String category,
    required String name,
    String? userId,
    String? status,
    String? controlUnitId,
    String? macAddress,
    String? linkedSprayerId,
    String? linkedTractorId,
    String? linkedPlotId,
    double? lidarNozzleDistance,
    double? mountingHeight,
    double? ultrasonicDistance,
  }) : super(
          id: id,
          category: category,
          name: name,
          userId: userId,
          status: status,
          controlUnitId: controlUnitId,
          macAddress: macAddress,
          linkedSprayerId: linkedSprayerId,
          linkedTractorId: linkedTractorId,
          linkedPlotId: linkedPlotId,
          lidarNozzleDistance: lidarNozzleDistance,
          mountingHeight: mountingHeight,
          ultrasonicDistance: ultrasonicDistance,
        );
}
