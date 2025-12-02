import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the create job form
class CreateJobFormState {
  final String? operatorId;
  final String? controlUnitId;
  final String? plotId;
  final List<Map<String, dynamic>> materials;
  final DateTime? dateTime;

  const CreateJobFormState({
    this.operatorId,
    this.controlUnitId,
    this.plotId,
    this.materials = const [],
    this.dateTime,
  });

  CreateJobFormState copyWith({
    String? Function()? operatorId,
    String? Function()? controlUnitId,
    String? Function()? plotId,
    List<Map<String, dynamic>>? materials,
    DateTime? Function()? dateTime,
  }) {
    return CreateJobFormState(
      operatorId: operatorId != null ? operatorId() : this.operatorId,
      controlUnitId:
          controlUnitId != null ? controlUnitId() : this.controlUnitId,
      plotId: plotId != null ? plotId() : this.plotId,
      materials: materials ?? this.materials,
      dateTime: dateTime != null ? dateTime() : this.dateTime,
    );
  }
}

/// Notifier for managing create job form state
class CreateJobFormNotifier extends StateNotifier<CreateJobFormState> {
  CreateJobFormNotifier() : super(const CreateJobFormState());

  void setOperatorId(String? id) {
    state = state.copyWith(operatorId: () => id);
  }

  void setControlUnitId(String? id) {
    state = state.copyWith(controlUnitId: () => id);
  }

  void setPlotId(String? id) {
    state = state.copyWith(plotId: () => id);
  }

  void addMaterial(Map<String, dynamic> material) {
    // Enforce a single mix per job: if the added material looks like a mix
    // (contains 'mixId' or a non-empty 'fertilizers' list), replace the
    // existing materials with this one. Otherwise, append as before.
    final isMix = material.containsKey('mixId') ||
        ((material['fertilizers'] is List) &&
            (material['fertilizers'] as List).isNotEmpty);
    if (isMix) {
      state = state.copyWith(materials: [material]);
    } else {
      state = state.copyWith(materials: [...state.materials, material]);
    }
  }

  void removeMaterial(int index) {
    final updated = [...state.materials];
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
      state = state.copyWith(materials: updated);
    }
  }

  void setDateTime(DateTime? dateTime) {
    state = state.copyWith(dateTime: () => dateTime);
  }

  void reset() {
    state = const CreateJobFormState();
  }
}

/// Provider for create job form state
final createJobFormProvider =
    StateNotifierProvider<CreateJobFormNotifier, CreateJobFormState>((ref) {
  return CreateJobFormNotifier();
});
