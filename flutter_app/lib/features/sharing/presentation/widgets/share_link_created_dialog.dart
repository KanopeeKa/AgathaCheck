import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

/// Dialog shown after generating a share link (owner, foster, co-parent flows).
class ShareLinkCreatedDialog extends StatelessWidget {
  const ShareLinkCreatedDialog({
    required this.petName,
    required this.shareCode,
    super.key,
  });

  final String petName;
  final String shareCode;

  static Future<void> show(
    BuildContext context, {
    required String petName,
    required String shareCode,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) =>
          ShareLinkCreatedDialog(petName: petName, shareCode: shareCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final baseUrl = Uri.base.origin;
    final link = '$baseUrl/#/shared/$shareCode';

    return AlertDialog(
      title: Text(l.shareLinkTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.shareLinkDescription(petName)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(link, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: link));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l.linkCopied)));
            Navigator.pop(context);
          },
          icon: const Icon(Icons.copy, size: 18),
          label: Text(l.copyLinkAgain),
        ),
      ],
    );
  }
}
