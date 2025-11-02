import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/plot_providers.dart';

// reuse plotRepoProvider from plot_providers
final plotsListProvider = FutureProvider.family((ref, String userId) async {
  final repo = ref.read(plotRepoProvider);
  return repo.getPlots(userId);
});
