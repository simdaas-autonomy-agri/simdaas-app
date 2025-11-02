import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SortBy { time, status, supervisor }

// Simple state notifier for sort preference
class SortByNotifier extends StateNotifier<SortBy> {
  SortByNotifier() : super(SortBy.time);

  void setSortBy(SortBy sortBy) {
    state = sortBy;
  }
}

// Provider for job list sorting
final jobListSortProvider =
    StateNotifierProvider<SortByNotifier, SortBy>((ref) {
  return SortByNotifier();
});
