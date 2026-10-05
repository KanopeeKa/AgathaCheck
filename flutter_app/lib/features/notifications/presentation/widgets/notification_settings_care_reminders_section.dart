import 'package:flutter/material.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Care reminders are not in the v2 inbox matrix (§8.1, AC-SE-8).
class NotificationSettingsCareRemindersSection extends StatelessWidget {
  const NotificationSettingsCareRemindersSection({
    super.key,
    required this.emailReminders,
    required this.reminderDays,
    required this.notifyOverdue,
    required this.notifyDueSoon,
    required this.notifyCompleted,
    required this.onEmailRemindersChanged,
    required this.onReminderDaysChanged,
    required this.onNotifyOverdueChanged,
    required this.onNotifyDueSoonChanged,
    required this.onNotifyCompletedChanged,
  });

  final bool emailReminders;
  final int reminderDays;
  final bool notifyOverdue;
  final bool notifyDueSoon;
  final bool notifyCompleted;
  final ValueChanged<bool> onEmailRemindersChanged;
  final ValueChanged<int> onReminderDaysChanged;
  final ValueChanged<bool> onNotifyOverdueChanged;
  final ValueChanged<bool> onNotifyDueSoonChanged;
  final ValueChanged<bool> onNotifyCompletedChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final xp = context.experienceColors;
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l.notificationSettingsCareRemindersTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            l.notificationSettingsCareRemindersHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SwitchListTile(
          title: Text(l.overdueAlerts),
          subtitle: Text(l.notificationSettingsOverdueHelp),
          value: notifyOverdue,
          onChanged: onNotifyOverdueChanged,
          secondary: Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
          ),
        ),
        SwitchListTile(
          title: Text(l.dueSoonAlerts),
          subtitle: Text(l.notificationSettingsDueSoonHelp),
          value: notifyDueSoon,
          onChanged: onNotifyDueSoonChanged,
          secondary: Icon(Icons.schedule, color: xp.warning),
        ),
        SwitchListTile(
          title: Text(l.completedAlerts),
          subtitle: Text(l.notificationSettingsCompletedHelp),
          value: notifyCompleted,
          onChanged: onNotifyCompletedChanged,
          secondary: Icon(Icons.check_circle, color: xp.success),
        ),
        SwitchListTile(
          title: Text(l.emailReminders),
          subtitle: Text(l.notificationSettingsEmailRemindersHelp),
          value: emailReminders,
          onChanged: onEmailRemindersChanged,
          secondary: Icon(
            Icons.email_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        if (emailReminders)
          ListTile(
            title: Text(l.reminderDaysBefore),
            subtitle: Text(
              '$reminderDays ${l.day}${reminderDays == 1 ? '' : 's'}',
            ),
            leading: Icon(
              Icons.timer_outlined,
              color: theme.colorScheme.primary,
            ),
            trailing: SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: l.notificationSettingsDecreaseDays,
                    onPressed: reminderDays > 1
                        ? () => onReminderDaysChanged(reminderDays - 1)
                        : null,
                  ),
                  Text('$reminderDays', style: theme.textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: l.notificationSettingsIncreaseDays,
                    onPressed: reminderDays < 14
                        ? () => onReminderDaysChanged(reminderDays + 1)
                        : null,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
