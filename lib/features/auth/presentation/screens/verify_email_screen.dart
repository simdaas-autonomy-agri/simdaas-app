import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _email;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String) _email = arg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text('Verification code was sent to ${_email ?? "your email"}'),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Code'),
            ),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (_code.text.trim().isEmpty) return;
                      setState(() => _loading = true);
                      final svc = ref.read(authServiceProvider);
                      final ok = await svc.verifyEmail(
                          _email ?? '', _code.text.trim());
                      setState(() => _loading = false);
                      if (ok) {
                        if (mounted)
                          Navigator.of(context).pushReplacementNamed('/login');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Verification failed')));
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      child: Text('Verify'),
                    ),
                  ),
            const SizedBox(height: 8),
            TextButton(
                onPressed: () async {
                  if ((_email ?? '').isEmpty) return;
                  final svc = ref.read(authServiceProvider);
                  final ok = await svc.resendVerification(_email ?? '');
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(ok ? 'Code resent' : 'Resend failed')));
                },
                child: const Text('Resend code'))
          ],
        ),
      ),
    );
  }
}
