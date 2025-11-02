import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../plot_mapping/presentation/providers/plot_providers.dart'
    as fm_providers;
import '../../../plot_mapping/data/models/plot_model.dart' as fm_models;

// Stream of dummy realtime metrics per plot id.
final monitoringStreamProvider =
    StreamProvider.family<Map<String, Map<String, dynamic>>, String>(
        (ref, String userId) async* {
  // Load plots once
  List plots;
  try {
    plots = await ref.watch(fm_providers.plotsListProvider(userId).future);
  } catch (_) {
    plots = [];
  }

  final rnd = Random();
  while (true) {
    final out = <String, Map<String, dynamic>>{};
    for (final p in plots.cast<fm_models.PlotModel>()) {
      out[p.id] = {
        'yield': (rnd.nextDouble() * 200).toStringAsFixed(1),
        'moisture': (rnd.nextInt(60) + 10).toString(),
        'acres': (rnd.nextDouble() * 100).toStringAsFixed(2),
        'fieldLbs': (rnd.nextDouble() * 2000).toStringAsFixed(1),
        'loadYield': (rnd.nextDouble() * 200).toStringAsFixed(1),
        'loadLbs': (rnd.nextDouble() * 2000).toStringAsFixed(1),
        'online': rnd.nextBool(),
      };
    }
    yield out;
    await Future.delayed(const Duration(seconds: 1));
  }
});
