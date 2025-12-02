import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/features/auth/presentation/screens/login_screen.dart';
import 'package:simdaas/temp_features/control_centres_dashboard.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);

    // Wait until auth service has loaded persisted tokens
    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If token exists, go to dashboard; otherwise show login
    if (auth.token != null) {
      return const TempDashboard();
    }

    return const LoginScreen();
  }
}
