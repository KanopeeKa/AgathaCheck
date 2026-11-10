import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/widgets/async_state/async_error_state.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Error state when the notification inbox fails to load.
class NotificationPanelErrorView extends StatelessWidget {
  const NotificationPanelErrorView({
    super.key,
    required this.error,
    required this.l,
    required this.theme,
    required this.onRetry,
  });

  /// Retained for call-site compatibility; never shown to the user.
  final Object error;
  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AsyncErrorState(
      title: l.notificationsLoadError,
      onRetry: onRetry,
    );
  }
}
