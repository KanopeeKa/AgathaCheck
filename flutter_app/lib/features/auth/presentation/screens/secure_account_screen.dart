import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

class SecureAccountScreen extends ConsumerStatefulWidget {
  const SecureAccountScreen({super.key, this.notificationId});

  final String? notificationId;

  @override
  ConsumerState<SecureAccountScreen> createState() =>
      _SecureAccountScreenState();
}

class _SecureAccountScreenState extends ConsumerState<SecureAccountScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).secureAccount(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
            notificationId: widget.notificationId,
          );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.secureAccountSuccess),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.secureAccountTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(l.secureAccountIntro, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _currentController,
              obscureText: true,
              decoration: InputDecoration(labelText: l.currentPassword),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: true,
              decoration: InputDecoration(labelText: l.newPassword),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.secureAccountSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
