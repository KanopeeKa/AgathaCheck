import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/contact_usage.dart';

Future<void> showContactUsagesDialog(
  BuildContext context, {
  required List<ContactUsage> usages,
  required VoidCallback onMarkInactive,
  VoidCallback? onReplaceUsage,
}) async {
  final l = AppLocalizations.of(context)!;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.peopleUsagesDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.peopleUsagesDialogBody),
            const SizedBox(height: 12),
            for (final usage in usages)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(usage.label),
                subtitle: Text(usage.kind),
                trailing: onReplaceUsage == null
                    ? null
                    : TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onReplaceUsage();
                        },
                        child: Text(l.peopleUsagesReplace),
                      ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onMarkInactive();
          },
          child: Text(l.peopleMarkInactive),
        ),
      ],
    ),
  );
}
