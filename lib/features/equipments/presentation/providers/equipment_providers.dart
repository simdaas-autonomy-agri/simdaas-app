import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import '../../data/datasources/equipment_remote_data_source.dart';
import '../../data/repositories/equipment_repository_impl.dart';
import '../../domain/entities/equipment.dart';

final equipmentRepoProvider = Provider((ref) => EquipmentRepositoryImpl(
    EquipmentRemoteDataSourceImpl(ref.read(apiServiceProvider))));

final equipmentsListProvider =
    FutureProvider.family<List<EquipmentEntity>, String>((ref, userId) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getEquipments(userId);
});

// Dedicated category providers to avoid fetching all equipment when only one
// category is required.
final tractorsProvider =
    FutureProvider.family<List<EquipmentEntity>, String>((ref, userId) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getTractors(userId);
});

final sprayersProvider =
    FutureProvider.family<List<EquipmentEntity>, String>((ref, userId) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getSprayers(userId);
});

final controlUnitsProvider =
    FutureProvider.family<List<EquipmentEntity>, String>((ref, userId) async {
  final repo = ref.read(equipmentRepoProvider);
  return repo.getControlUnits(userId);
});

final equipmentControllerProvider = Provider((ref) => EquipmentController(ref));

class EquipmentController {
  final Ref ref;
  EquipmentController(this.ref);

  Future<void> add(Map<String, dynamic> data) async {
    final repo = ref.read(equipmentRepoProvider);
    await repo.addEquipment(data);
    // After adding, invalidate equipment providers so UI lists refresh.
    final currentUserId =
        ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    ref.invalidate(equipmentsListProvider(currentUserId));
    final category = (data['category'] as String?)?.toLowerCase();
    switch (category) {
      case 'control_unit':
        ref.invalidate(controlUnitsProvider(currentUserId));
        break;
      case 'sprayer':
        ref.invalidate(sprayersProvider(currentUserId));
        break;
      case 'tractor':
        ref.invalidate(tractorsProvider(currentUserId));
        break;
      default:
        break;
    }
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final repo = ref.read(equipmentRepoProvider);
    await repo.updateEquipment(id, data);
    // After updating, invalidate equipment providers so UI lists refresh.
    final currentUserId =
        ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    ref.invalidate(equipmentsListProvider(currentUserId));
    final category = (data['category'] as String?)?.toLowerCase();
    switch (category) {
      case 'control_unit':
        ref.invalidate(controlUnitsProvider(currentUserId));
        break;
      case 'sprayer':
        ref.invalidate(sprayersProvider(currentUserId));
        break;
      case 'tractor':
        ref.invalidate(tractorsProvider(currentUserId));
        break;
      default:
        break;
    }
  }

  Future<void> delete(String id, {String? category}) async {
    final repo = ref.read(equipmentRepoProvider);
    await repo.deleteEquipment(id, category: category);
    // After deleting, invalidate equipment providers so UI lists refresh.
    final currentUserId =
        ref.read(authServiceProvider).currentUserId ?? 'demo_user';
    ref.invalidate(equipmentsListProvider(currentUserId));
    final cat = (category ?? '').toLowerCase();
    switch (cat) {
      case 'control_unit':
        ref.invalidate(controlUnitsProvider(currentUserId));
        break;
      case 'sprayer':
        ref.invalidate(sprayersProvider(currentUserId));
        break;
      case 'tractor':
        ref.invalidate(tractorsProvider(currentUserId));
        break;
      default:
        break;
    }
  }
}
