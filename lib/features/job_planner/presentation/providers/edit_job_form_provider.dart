import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class for edit job form
class EditJobFormState {
  final String? equipmentId;
  final String? plotId;
  final String? controlUnitId;
  final String? operatorId;
  final List<Map<String, dynamic>> materials;
  final DateTime? dateTime;

  const EditJobFormState({
    this.equipmentId,
    this.plotId,
    this.controlUnitId,
    this.operatorId,
    this.materials = const [],
    this.dateTime,
  });

  EditJobFormState copyWith({
    String? equipmentId,
    bool equipmentIdNull = false,
    String? plotId,
    bool plotIdNull = false,
    String? controlUnitId,
    bool controlUnitIdNull = false,
    String? operatorId,
    bool operatorIdNull = false,
    List<Map<String, dynamic>>? materials,
    DateTime? dateTime,
    bool dateTimeNull = false,
  }) {
    return EditJobFormState(
      equipmentId: equipmentIdNull ? null : (equipmentId ?? this.equipmentId),
      plotId: plotIdNull ? null : (plotId ?? this.plotId),
      controlUnitId:
          controlUnitIdNull ? null : (controlUnitId ?? this.controlUnitId),
      operatorId: operatorIdNull ? null : (operatorId ?? this.operatorId),
      materials: materials ?? this.materials,
      dateTime: dateTimeNull ? null : (dateTime ?? this.dateTime),
    );
  }
}

/// StateNotifier for managing edit job form state
class EditJobFormNotifier extends StateNotifier<EditJobFormState> {
  EditJobFormNotifier(EditJobFormState initialState) : super(initialState);

  void setEquipmentId(String? id) {
    state = state.copyWith(
      equipmentId: id,
      equipmentIdNull: id == null,
    );
  }

  void setPlotId(String? id) {
    state = state.copyWith(
      plotId: id,
      plotIdNull: id == null,
    );
  }

  void setControlUnitId(String? id) {
    state = state.copyWith(
      controlUnitId: id,
      controlUnitIdNull: id == null,
    );
  }

  void setOperatorId(String? id) {
    state = state.copyWith(
      operatorId: id,
      operatorIdNull: id == null,
    );
  }

  void addMaterial(Map<String, dynamic> material) {
    state = state.copyWith(
      materials: [...state.materials, material],
    );
  }

  void removeMaterial(int index) {
    if (index < 0 || index >= state.materials.length) return;
    final newMaterials = List<Map<String, dynamic>>.from(state.materials);
    newMaterials.removeAt(index);
    state = state.copyWith(materials: newMaterials);
  }

  void updateMaterial(int index, Map<String, dynamic> material) {
    if (index < 0 || index >= state.materials.length) return;
    final newMaterials = List<Map<String, dynamic>>.from(state.materials);
    newMaterials[index] = material;
    state = state.copyWith(materials: newMaterials);
  }

  void setDateTime(DateTime? dateTime) {
    state = state.copyWith(
      dateTime: dateTime,
      dateTimeNull: dateTime == null,
    );
  }

  void reset(EditJobFormState newState) {
    state = newState;
  }
}

/// Provider factory for edit job form state
/// Each job edit screen gets its own provider instance
final editJobFormProvider =
    StateNotifierProvider.family<EditJobFormNotifier, EditJobFormState, String>(
  (ref, jobId) {
    return EditJobFormNotifier(const EditJobFormState());
  },
);
