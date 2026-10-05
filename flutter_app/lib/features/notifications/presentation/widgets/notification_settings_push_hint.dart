import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'push_permission_status.dart';

/// FR-SE-4: when OS push permission is denied, explain instead of showing enabled toggles.
class NotificationSettingsPushHint extends StatelessWidget {
  const NotificationSettingsPushHint({super.key, required this.showHint});

  final bool showHint;

  static bool osPushDenied() => readOsPushPermissionDenied();

  @override
  Widget build(BuildContext context) {
    if (!showHint) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.notificationSettingsPushOsHint,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
