import 'package:flutter_test/flutter_test.dart';
import 'package:simdaas/features/equipments/data/models/equipment_model.dart';

void main() {
  test('EquipmentModel.fromJson parses snake_case sprayer json correctly', () {
    final json = {
      'category': 'sprayer',
      'name': 'Test Sprayer',
      'user': {'id': 'user123', 'username': 'joe'},
      'status': 'vacant',
      'wheel_diameter': 1.0,
      'screws_per_wheel': 6,
      'axle_length': 1.2,
      'nozzle_count': 3,
      'tank_capacity': 2.0,
      'distance_hinge_axle': 0.5,
      'distance_hinge_nozzle': 0.7,
      'distance_hinge_control_unit': 0.2,
      'created_at': '2023-01-01T00:00:00Z',
      'updated_at': '2023-01-02T00:00:00Z',
    };

    final model = EquipmentModel.fromJson('spr-1', json) as SprayerModel;

    expect(model.id, 'spr-1');
    expect(model.category, 'sprayer');
    expect(model.name, 'Test Sprayer');
    expect(model.userId, 'user123');
    expect(model.wheelDiameter, 1.0);
    expect(model.screwsInWheel, 6);
    expect(model.axleLength, 1.2);
    expect(model.nozzleCount, 3);
    expect(model.tankCapacity, 2.0);
    expect(model.hingeToAxle, 0.5);
    expect(model.hingeToNozzle, 0.7);
    expect(model.hingeToControlUnit, 0.2);
    expect(
        model.createdAt?.toUtc().toIso8601String(), '2023-01-01T00:00:00.000Z');
    expect(
        model.updatedAt?.toUtc().toIso8601String(), '2023-01-02T00:00:00.000Z');
  });
}
