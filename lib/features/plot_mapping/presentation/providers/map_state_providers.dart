import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

// State classes for map functionality
class MapState {
  final List<LatLng> points;
  final int? selectedVertex;
  final bool absorbMap;

  const MapState({
    this.points = const [],
    this.selectedVertex,
    this.absorbMap = false,
  });

  MapState copyWith({
    List<LatLng>? points,
    int? selectedVertex,
    bool selectedVertexNull = false,
    bool? absorbMap,
  }) {
    return MapState(
      points: points ?? this.points,
      selectedVertex:
          selectedVertexNull ? null : (selectedVertex ?? this.selectedVertex),
      absorbMap: absorbMap ?? this.absorbMap,
    );
  }
}

class SearchState {
  final List<Map<String, dynamic>> suggestions;
  final bool isSearching;

  const SearchState({
    this.suggestions = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    List<Map<String, dynamic>>? suggestions,
    bool? isSearching,
  }) {
    return SearchState(
      suggestions: suggestions ?? this.suggestions,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

// StateNotifier for map state
class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier() : super(const MapState());

  void addPoint(LatLng point) {
    state = state.copyWith(points: [...state.points, point]);
  }

  void insertPoint(int index, LatLng point) {
    final newPoints = List<LatLng>.from(state.points);
    newPoints.insert(index, point);
    state = state.copyWith(points: newPoints);
  }

  void updatePoint(int index, LatLng point) {
    if (index < 0 || index >= state.points.length) return;
    final newPoints = List<LatLng>.from(state.points);
    newPoints[index] = point;
    state = state.copyWith(points: newPoints);
  }

  void deletePoint(int index) {
    if (index < 0 || index >= state.points.length) return;
    final newPoints = List<LatLng>.from(state.points);
    newPoints.removeAt(index);
    state = state.copyWith(points: newPoints, selectedVertexNull: true);
  }

  void setPoints(List<LatLng> points) {
    state = state.copyWith(points: points);
  }

  void selectVertex(int? index) {
    if (index == null) {
      state = state.copyWith(selectedVertexNull: true);
    } else {
      state = state.copyWith(selectedVertex: index);
    }
  }

  void setAbsorbMap(bool absorb) {
    state = state.copyWith(absorbMap: absorb);
  }

  void clearSelection() {
    state = state.copyWith(selectedVertexNull: true);
  }

  void clearAll() {
    state = const MapState();
  }
}

// StateNotifier for search state
class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(const SearchState());

  void setSuggestions(List<Map<String, dynamic>> suggestions) {
    state = state.copyWith(suggestions: suggestions, isSearching: false);
  }

  void setSearching(bool isSearching) {
    state = state.copyWith(isSearching: isSearching);
  }

  void clearSuggestions() {
    state = state.copyWith(suggestions: [], isSearching: false);
  }
}

// Providers
final mapStateProvider =
    StateNotifierProvider<MapStateNotifier, MapState>((ref) {
  return MapStateNotifier();
});

final searchStateProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
  return SearchStateNotifier();
});
