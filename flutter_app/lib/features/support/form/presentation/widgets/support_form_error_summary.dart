import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class SupportFormErrorSummary extends StatelessWidget {
  const SupportFormErrorSummary({
    super.key,
    required this.errorCount,
    required this.focusNode,
    this.serverMessage,
  });

  final int errorCount;
  final FocusNode focusNode;
  final String? serverMessage;

  @override
  Widget build(BuildContext context) {
    if (errorCount <= 0 && (serverMessage == null || serverMessage!.isEmpty)) {
      return const SizedBox.shrink();
    }

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final messages = <String>[];
    if (errorCount > 0) {
      messages.add(l.supportFormErrorSummaryFieldCount(errorCount));
    }
    if (serverMessage != null && serverMessage!.isNotEmpty) {
      messages.add(serverMessage!);
    }

    return Focus(
      focusNode: focusNode,
      child: Semantics(
        liveRegion: true,
        container: true,
        label: l.supportFormErrorSummaryTitle,
        child: Card(
          color: theme.colorScheme.errorContainer,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.supportFormErrorSummaryTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (final line in messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
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
