import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();

    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted && ref.read(authProvider).isLoggedIn) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/logo.png',
                        height: 80, width: 80, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  Text(AppConstants.appTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Sign in to your account',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: theme.colorScheme.error, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(auth.error!,
                                      style: TextStyle(
                                          color: theme.colorScheme.error)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: auth.isLoading ? null : _submit,
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: () => context.go('/signup'),
                              child: const Text('Sign Up'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
