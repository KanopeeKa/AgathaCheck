import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Opens [uri] externally; shows [showExternalLinkFallback] when launch fails.
Future<void> launchExternalLink(
  BuildContext context, {
  required Uri uri,
  required String displayUrl,
  required String dialogTitle,
  String? failureMessage,
}) async {
  final l = AppLocalizations.of(context)!;
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      showExternalLinkFallback(
        context,
        url: displayUrl,
        dialogTitle: dialogTitle,
        failureMessage: failureMessage ?? l.externalLinkOpenFailed,
      );
    }
  } catch (_) {
    if (context.mounted) {
      showExternalLinkFallback(
        context,
        url: displayUrl,
        dialogTitle: dialogTitle,
        failureMessage: failureMessage ?? l.externalLinkOpenFailed,
      );
    }
  }
}

void showExternalLinkFallback(
  BuildContext context, {
  required String url,
  required String dialogTitle,
  required String failureMessage,
}) {
  final l = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(failureMessage),
            const SizedBox(height: 12),
            SelectableText(url),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.peopleCopiedToClipboard)),
                );
              }
            },
            child: Text(l.copy),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.ok),
          ),
        ],
      );
    },
  );
}
