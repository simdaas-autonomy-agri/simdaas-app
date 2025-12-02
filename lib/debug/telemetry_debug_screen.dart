import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/services/telemetry_service.dart';

class TelemetryDebugScreen extends ConsumerStatefulWidget {
  const TelemetryDebugScreen({super.key});

  @override
  ConsumerState<TelemetryDebugScreen> createState() =>
      _TelemetryDebugScreenState();
}

class _TelemetryDebugScreenState extends ConsumerState<TelemetryDebugScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(telemetryServiceProvider);
    final subs = svc.subscribedDeviceIds;
    final latest = svc.latestTelemetry;
    final now = DateTime.now().toUtc();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('TelemetryDebugScreen: refresh pressed');
              setState(() {});
            },
            tooltip: 'Refresh',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manual subscribe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                        hintText: 'Enter device MAC (e.g. 10:20:BA:47:BD:3C)'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final val = _controller.text.trim();
                    if (val.isNotEmpty) {
                      debugPrint(
                          'TelemetryDebugScreen: manual subscribe to $val');
                      ref.read(telemetryServiceProvider).subscribe(val);
                      setState(() {});
                    }
                  },
                  child: const Text('Subscribe'),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Subscribed device IDs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (subs.isEmpty)
              const Text('No subscriptions')
            else
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: subs.map((s) => Chip(label: Text(s))).toList(),
              ),
            const Divider(height: 24),
            const Text('Latest telemetry (snapshot)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: latest.isEmpty
                  ? const Center(child: Text('No telemetry received yet'))
                  : ListView.separated(
                      itemCount: latest.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, idx) {
                        final key = latest.keys.elementAt(idx);
                        final t = latest[key]!;
                        final age =
                            now.difference(t.timestamp.toUtc()).inSeconds;
                        final ts = DateFormat("yyyy-MM-dd HH:mm:ss")
                            .format(t.timestamp.toLocal());
                        return ListTile(
                          title: Text(key),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('timestamp: $ts (age: ${age}s)'),
                              if (t.lat != null && t.lon != null)
                                Text('lat/lon: ${t.lat}, ${t.lon}'),
                              if (t.gpsSignalQuality != null)
                                Text('gps signal: ${t.gpsSignalQuality}'),
                              if (t.simSignalQuality != null)
                                Text('sim signal: ${t.simSignalQuality}'),
                            ],
                          ),
                          trailing: age <= 10
                              ? const Icon(Icons.wifi, color: Colors.green)
                              : const Icon(Icons.wifi_off, color: Colors.grey),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
