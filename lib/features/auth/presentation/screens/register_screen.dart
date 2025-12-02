import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/core/utils/error_utils.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'Minimum 6 characters',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password required';
                  if (v.trim().length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirm,
                decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    )),
                obscureText: _obscureConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirm password';
                  if (v.trim().length < 6)
                    return 'Password must be at least 6 characters';
                  if (v != _password.text) return 'Passwords do not match';
                  return null;
                },
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
                        try {
                          await svc.register(
                              _username.text.trim(),
                              _email.text.trim(),
                              _password.text.trim(),
                              _confirm.text.trim());
                          setState(() => _loading = false);
                          if (mounted) {
                            Navigator.of(context).pushReplacementNamed(
                                '/verify-email',
                                arguments: _email.text.trim());
                          }
                        } catch (e) {
                          setState(() => _loading = false);
                          showPolishedError(context, e,
                              fallback: 'Registration failed');
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
