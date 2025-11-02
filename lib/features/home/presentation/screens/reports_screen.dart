import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
              onPressed: () {
                // TODO: wire sort logic
              },
              icon: const Icon(Icons.sort)),
        ],
      ),
      body: const Center(
        child: Text('Reports list - TODO: implement fetching logic'),
      ),
    );
  }
}
