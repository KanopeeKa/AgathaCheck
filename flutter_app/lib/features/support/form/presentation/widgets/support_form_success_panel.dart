import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';

class SupportFormSuccessPanel extends StatelessWidget {
  const SupportFormSuccessPanel({
    super.key,
    required this.reference,
    required this.onCopy,
  });

  final String reference;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      container: true,
      label: l.supportFormSuccessAnnouncement(reference),
      child: Card(
        key: const Key('support_form_success'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.supportFormSuccessTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.supportFormSuccessBody(reference),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SelectableText(
                reference,
                key: const Key('support_form_reference'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('support_form_copy_reference'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: reference));
                  onCopy();
                },
                icon: const Icon(Icons.copy),
                label: Text(l.supportFormCopyReference),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
