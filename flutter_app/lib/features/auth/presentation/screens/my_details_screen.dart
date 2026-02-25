import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';

class MyDetailsScreen extends ConsumerStatefulWidget {
  const MyDetailsScreen({super.key});

  @override
  ConsumerState<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends ConsumerState<MyDetailsScreen> {
  late TextEditingController _nameController;
  bool _nameEdited = false;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _changingPassword = false;
  String? _passwordMessage;
  bool _passwordSuccess = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    await ref
        .read(authProvider.notifier)
        .updateProfile(name: _nameController.text.trim());
    if (mounted) {
      setState(() => _nameEdited = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated')),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    setState(() {
      _changingPassword = true;
      _passwordMessage = null;
    });

    try {
      final msg = await ref.read(authProvider.notifier).changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (mounted) {
        setState(() {
          _changingPassword = false;
          _passwordMessage = msg;
          _passwordSuccess = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _changingPassword = false;
          _passwordMessage = e.toString().replaceFirst('Exception: ', '');
          _passwordSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Details')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                (user.name.isNotEmpty
                                        ? user.name[0]
                                        : user.email[0])
                                    .toUpperCase(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                    color:
                                        theme.colorScheme.onPrimaryContainer),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Profile',
                                      style: theme.textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  Text(user.email,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            prefixIcon: Icon(Icons.person_outlined),
                          ),
                          onChanged: (v) {
                            if (!_nameEdited) setState(() => _nameEdited = true);
                          },
                        ),
                        if (_nameEdited) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: auth.isLoading ? null : _saveName,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Save Name'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: user.email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          readOnly: true,
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change Password',
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureCurrent
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscureCurrent = !_obscureCurrent),
                              ),
                            ),
                            obscureText: _obscureCurrent,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Current password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: const Icon(Icons.lock_reset),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureNew
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () => setState(
                                    () => _obscureNew = !_obscureNew),
                              ),
                            ),
                            obscureText: _obscureNew,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'New password is required';
                              }
                              if (v.length < 6) {
                                return 'At least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm New Password',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                            obscureText: true,
                            validator: (v) {
                              if (v != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          if (_passwordMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _passwordSuccess
                                    ? Colors.green.shade50
                                    : theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _passwordSuccess
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    color: _passwordSuccess
                                        ? Colors.green
                                        : theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(_passwordMessage!,
                                          style: TextStyle(
                                              color: _passwordSuccess
                                                  ? Colors.green.shade800
                                                  : theme.colorScheme.error))),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed:
                                  _changingPassword ? null : _changePassword,
                              child: _changingPassword
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Text('Change Password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
