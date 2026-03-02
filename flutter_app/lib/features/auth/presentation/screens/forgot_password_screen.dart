import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/constants.dart';
import '../../data/auth_service.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.forgotPassword(email: _emailController.text.trim());
      setState(() {
        _codeSent = true;
        _isLoading = false;
        _successMessage =
            'If an account with that email exists, a reset code has been sent. Check your email.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final message = await authService.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
          title: const Text('Password Reset'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/landing');
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to sign in',
          onPressed: () => context.go('/landing'),
        ),
        title: const Text('Reset Password'),
      ),
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
                    child: Image.asset(
                      'assets/logo.png',
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                      semanticLabel: 'Agatha Check logo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _codeSent ? 'Enter Reset Code' : 'Forgot Password',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeSent
                        ? 'Enter the 6-digit code and your new password.'
                        : 'Enter your email address and we\'ll send you a code to reset your password.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_successMessage != null && _codeSent) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null) ...[
                    MergeSemantics(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: Icon(Icons.error_outline,
                                  color: theme.colorScheme.error, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style:
                                    TextStyle(color: theme.colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!_codeSent) _buildEmailStep(theme),
                  if (_codeSent) _buildResetStep(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(ThemeData theme) {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('forgot_email_field'),
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
            onFieldSubmitted: (_) => _requestCode(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('forgot_submit_button'),
              onPressed: _isLoading ? null : _requestCode,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Reset Code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(ThemeData theme) {
    return Form(
      key: _resetFormKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('reset_code_field'),
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Reset Code',
              prefixIcon: Icon(Icons.lock_clock),
              hintText: '6-digit code',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Code is required';
              if (v.trim().length != 6) return 'Enter the 6-digit code';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('reset_password_field'),
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                tooltip:
                    _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'At least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('reset_confirm_field'),
            controller: _confirmController,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                tooltip:
                    _obscureConfirm ? 'Show password' : 'Hide password',
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            obscureText: _obscureConfirm,
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            onFieldSubmitted: (_) => _resetPassword(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('reset_submit_button'),
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Reset Password'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _codeSent = false;
                _error = null;
                _successMessage = null;
                _codeController.clear();
                _passwordController.clear();
                _confirmController.clear();
              });
            },
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
