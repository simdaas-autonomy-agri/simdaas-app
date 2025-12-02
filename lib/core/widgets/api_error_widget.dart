import 'package:flutter/material.dart';
import 'package:simdaas/core/utils/error_utils.dart';

class ApiErrorWidget extends StatelessWidget {
  const ApiErrorWidget({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = extractErrorMessage(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(msg, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
        ]),
      ),
    );
  }
}
