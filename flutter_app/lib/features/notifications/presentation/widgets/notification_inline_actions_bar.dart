import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Accept / Decline controls for needs-response rows (FR-IA-1, FR-AR-5/6).
class NotificationInlineActionsBar extends StatelessWidget {
  const NotificationInlineActionsBar({
    super.key,
    required this.busy,
    required this.errorMessage,
    required this.onAccept,
    required this.onDecline,
    required this.onRetry,
    this.declineLabel,
    this.acceptLabel,
  });

  final bool busy;
  final String? errorMessage;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onRetry;
  final String? declineLabel;
  final String? acceptLabel;

  static const _minTap = 48.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage != null) ...[
            Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: busy ? null : onRetry,
                child: Text(l.notificationInlineRetry),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: declineLabel ?? l.declineShare,
                  child: SizedBox(
                    height: _minTap,
                    child: OutlinedButton(
                      onPressed: busy ? null : onDecline,
                      child: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(declineLabel ?? l.declineShare),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  button: true,
                  label: acceptLabel ?? l.acceptShare,
                  child: SizedBox(
                    height: _minTap,
                    child: FilledButton(
                      onPressed: busy ? null : onAccept,
                      child: Text(acceptLabel ?? l.acceptShare),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
