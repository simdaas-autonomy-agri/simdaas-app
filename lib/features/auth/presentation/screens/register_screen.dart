import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Username required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Email required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Password required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirm,
                decoration:
                    const InputDecoration(labelText: 'Confirm password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Confirm password' : null,
              ),
              const SizedBox(height: 16),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_password.text != _confirm.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Passwords do not match')));
                          return;
                        }
                        setState(() => _loading = true);
                        final svc = ref.read(authServiceProvider);
                        final ok = await svc.register(
                            _username.text.trim(),
                            _email.text.trim(),
                            _password.text.trim(),
                            _confirm.text.trim());
                        setState(() => _loading = false);
                        if (ok) {
                          // navigate to verification screen
                          if (mounted) {
                            Navigator.of(context).pushReplacementNamed(
                                '/verify-email',
                                arguments: _email.text.trim());
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Registration failed')));
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.0, vertical: 12.0),
                        child: Text('Register'),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
