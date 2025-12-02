import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simdaas/core/services/auth_service.dart';
import 'package:simdaas/core/services/api_exception.dart';

class ForgotPasswordConfirmScreen extends ConsumerStatefulWidget {
  const ForgotPasswordConfirmScreen({super.key, this.email});
  final String? email;

  @override
  ConsumerState<ForgotPasswordConfirmScreen> createState() =>
      _ForgotPasswordConfirmScreenState();
}

class _ForgotPasswordConfirmScreenState
    extends ConsumerState<ForgotPasswordConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) _emailCtrl.text = widget.email!;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validatePassword(String v) {
    if (v.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(v)) return false;
    if (!RegExp(r'[0-9]').hasMatch(v)) return false;
    if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(v)) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Map && arg['email'] is String && _emailCtrl.text.isEmpty) {
      _emailCtrl.text = arg['email'];
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'Enter the 6-digit code sent to your email and choose a new password.'),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(children: [
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please enter your email'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Verification code'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Enter the verification code'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a password';
                        if (!_validatePassword(v)) {
                          return 'Password must be >=8 chars, include uppercase, number and special char';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscure,
                      decoration:
                          const InputDecoration(labelText: 'Confirm password'),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Confirm your password';
                        if (v != _passwordCtrl.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _loading
                        ? const CircularProgressIndicator()
                        : Column(children: [
                            ElevatedButton(
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate())
                                    return;
                                  setState(() => _loading = true);
                                  final auth = ref.read(authServiceProvider);
                                  final email = _emailCtrl.text.trim();
                                  final code = _codeCtrl.text.trim();
                                  final pw = _passwordCtrl.text;
                                  try {
                                    await auth.confirmPasswordReset(
                                        email, code, pw);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Password reset successful')));
                                    // navigate back to login
                                    Navigator.of(context)
                                        .pushReplacementNamed('/login');
                                  } catch (e) {
                                    String msg;
                                    if (e is ApiException && e.body != null) {
                                      try {
                                        final parsed = json.decode(e.body!)
                                            as Map<String, dynamic>;
                                        final msgs = <String>[];
                                        parsed.forEach((k, v) {
                                          if (v is List && v.isNotEmpty) {
                                            msgs.add('${k}: ${v.first}');
                                          } else if (v is String) {
                                            msgs.add('${k}: $v');
                                          } else {
                                            msgs.add('$k: ${v.toString()}');
                                          }
                                        });
                                        msg = msgs.join(' • ');
                                      } catch (_) {
                                        msg = e.toString();
                                      }
                                    } else {
                                      msg = e.toString();
                                    }
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(msg)));
                                  } finally {
                                    if (mounted)
                                      setState(() => _loading = false);
                                  }
                                },
                                child: const Text('Reset password')),
                            const SizedBox(height: 8),
                            TextButton(
                                onPressed: () async {
                                  final email = _emailCtrl.text.trim();
                                  if (email.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Enter email to resend')));
                                    return;
                                  }
                                  setState(() => _loading = true);
                                  try {
                                    await ref
                                        .read(authServiceProvider)
                                        .resendPasswordReset(email);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Verification code sent successfully')));
                                  } catch (e) {
                                    String msg;
                                    if (e is ApiException && e.body != null) {
                                      try {
                                        final parsed = json.decode(e.body!)
                                            as Map<String, dynamic>;
                                        final msgs = <String>[];
                                        parsed.forEach((k, v) {
                                          if (v is List && v.isNotEmpty) {
                                            msgs.add('${k}: ${v.first}');
                                          } else if (v is String) {
                                            msgs.add('${k}: $v');
                                          } else {
                                            msgs.add('$k: ${v.toString()}');
                                          }
                                        });
                                        msg = msgs.join(' • ');
                                      } catch (_) {
                                        msg = e.toString();
                                      }
                                    } else {
                                      msg = e.toString();
                                    }
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(msg)));
                                  } finally {
                                    if (mounted)
                                      setState(() => _loading = false);
                                  }
                                },
                                child: const Text('Resend code'))
                          ]),
                  ]),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
