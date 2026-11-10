import 'package:flutter/material.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Title row, destinations, and mark-all-read for the notification slide-over panel.
class NotificationPanelHeader extends StatelessWidget {
  const NotificationPanelHeader({
    super.key,
    required this.l,
    required this.theme,
    required this.onOpenInbox,
    required this.onOpenSettings,
    this.onMarkAllRead,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onOpenInbox;
  final VoidCallback onOpenSettings;
  final VoidCallback? onMarkAllRead;

  static const _minTouch = Size(48, 48);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.notifications,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 0,
            children: [
              Semantics(
                identifier: 'notification_panel_open_inbox',
                button: true,
                label: l.notificationOpenInbox,
                child: IconButton(
                  tooltip: l.notificationOpenInbox,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: onOpenInbox,
                  icon: const Icon(Icons.inbox_outlined),
                ),
              ),
              Semantics(
                identifier: 'notification_panel_settings',
                button: true,
                label: l.notificationSettingsTooltip,
                child: IconButton(
                  tooltip: l.notificationSettingsTooltip,
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
              Semantics(
                identifier: 'notification_panel_mark_all_read',
                button: true,
                enabled: onMarkAllRead != null,
                label: l.markAllRead,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: _minTouch,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onMarkAllRead,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text(l.markAllRead),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
