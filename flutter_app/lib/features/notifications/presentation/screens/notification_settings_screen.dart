import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/notification_preferences.dart';
import '../providers/notification_providers.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _emailReminders = false;
  int _reminderDays = 1;
  bool _notifyOverdue = true;
  bool _notifyDueSoon = true;
  bool _notifyCompleted = true;
  bool _initialized = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);
    final theme = Theme.of(context);

    prefsAsync.whenData((prefs) {
      if (!_initialized) {
        _emailReminders = prefs.emailRemindersEnabled;
        _reminderDays = prefs.reminderDaysBefore;
        _notifyOverdue = prefs.notifyOverdue;
        _notifyDueSoon = prefs.notifyDueSoon;
        _notifyCompleted = prefs.notifyCompleted;
        _initialized = true;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to notifications',
          onPressed: () => context.pop(),
        ),
      ),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (_) => ListView(
          children: [
            const SizedBox(height: 8),
            _SectionHeader(title: 'In-App Notifications', theme: theme),
            SwitchListTile(
              title: const Text('Overdue Alerts'),
              subtitle:
                  const Text('Get notified when health entries are overdue'),
              value: _notifyOverdue,
              onChanged: (v) => setState(() => _notifyOverdue = v),
              secondary: Icon(Icons.warning_amber_rounded,
                  color: theme.colorScheme.error),
            ),
            SwitchListTile(
              title: const Text('Due Soon Alerts'),
              subtitle:
                  const Text('Get notified when health entries are coming up'),
              value: _notifyDueSoon,
              onChanged: (v) => setState(() => _notifyDueSoon = v),
              secondary:
                  Icon(Icons.schedule, color: Colors.orange),
            ),
            SwitchListTile(
              title: const Text('Completed Alerts'),
              subtitle:
                  const Text('Get notified when health entries are completed'),
              value: _notifyCompleted,
              onChanged: (v) => setState(() => _notifyCompleted = v),
              secondary:
                  Icon(Icons.check_circle, color: Colors.green),
            ),
            const Divider(),
            _SectionHeader(title: 'Email Reminders', theme: theme),
            SwitchListTile(
              title: const Text('Email Reminders'),
              subtitle: const Text(
                  'Receive email reminders for upcoming health entries'),
              value: _emailReminders,
              onChanged: (v) => setState(() => _emailReminders = v),
              secondary:
                  Icon(Icons.email_outlined, color: theme.colorScheme.primary),
            ),
            if (_emailReminders) ...[
              ListTile(
                title: const Text('Remind Before'),
                subtitle: Text('$_reminderDays day${_reminderDays == 1 ? '' : 's'} before due date'),
                leading:
                    Icon(Icons.timer_outlined, color: theme.colorScheme.primary),
                trailing: SizedBox(
                  width: 140,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Decrease reminder days',
                        onPressed: _reminderDays > 1
                            ? () => setState(() => _reminderDays--)
                            : null,
                      ),
                      Text(
                        '$_reminderDays',
                        style: theme.textTheme.titleMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Increase reminder days',
                        onPressed: _reminderDays < 14
                            ? () => setState(() => _reminderDays++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(),
            _SectionHeader(title: 'Local Notifications', theme: theme),
            ListTile(
              leading: Icon(Icons.phone_android,
                  color: theme.colorScheme.onSurfaceVariant),
              title: const Text('Push Notifications'),
              subtitle: const Text(
                  'Push notifications will be available in the native mobile app'),
              enabled: false,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                key: const Key('save_notification_settings_button'),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Settings'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .updatePreferences(NotificationPreferences(
            emailRemindersEnabled: _emailReminders,
            reminderDaysBefore: _reminderDays,
            notifyOverdue: _notifyOverdue,
            notifyDueSoon: _notifyDueSoon,
            notifyCompleted: _notifyCompleted,
          ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
