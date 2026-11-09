import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Help icon that opens a dialog with explanatory copy for form fields.
class AppFormInfoButton extends StatelessWidget {
  const AppFormInfoButton({
    super.key,
    required this.message,
    this.semanticsIdentifier,
  });

  final String message;

  /// Optional semantics identifier for E2E and screen readers.
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final button = IconButton(
      key: const Key('app_form_info_button'),
      icon: Icon(
        Icons.info_outline,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      tooltip: message,
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.ok),
              ),
            ],
          ),
        );
      },
    );

    if (semanticsIdentifier == null) {
      return button;
    }

    return Semantics(
      identifier: semanticsIdentifier,
      button: true,
      label: message,
      child: button,
    );
  }
}
