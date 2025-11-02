import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  // rename: username field
  final _usernameCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to continue',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person_outline),
              hintText: 'Enter your username',
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your username' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passCtrl,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
              hintText: 'Enter your password',
            ),
            obscureText: true,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please enter your password' : null,
          ),
          const SizedBox(height: 24),
          authAsync is AsyncLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    await ref.read(authProvider.notifier).signIn(
                        _usernameCtrl.text.trim(), _passCtrl.text.trim());
                    final state = ref.read(authProvider);
                    if (state is AsyncData) {
                      final user = state.value?.user;
                      if (user != null && mounted) {
                        // After login, send user to the default dashboard which
                        // presents the three role buttons (Admin/Job Supervisor/Technician).
                        Navigator.of(context)
                            .pushReplacementNamed('/dashboard');
                      }
                    } else if (state is AsyncError) {
                      // navigate to plot list
                      final err = state.error?.toString() ?? 'Unknown error';
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(child: Text('Login failed: $err')),
                              ],
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Sign In'),
                  ),
                ),
        ],
      ),
    );
  }
}
