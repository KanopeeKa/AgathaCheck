import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Count-labelled bulk Mark done / Skip pair (FR-13, FR-15).
class CareItemBulkActionBar extends StatelessWidget {
  const CareItemBulkActionBar({
    super.key,
    required this.count,
    required this.muted,
    required this.onMarkAllDone,
    required this.onSkipAll,
  });

  final int count;
  final bool muted;
  final VoidCallback onMarkAllDone;
  final VoidCallback onSkipAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    Widget markButton({required bool fullWidth}) {
      return FilledButton.icon(
        key: const Key('care_item_bulk_mark_done'),
        onPressed: muted ? null : onMarkAllDone,
        icon: const Icon(Icons.check_circle, size: 18),
        label: Text(l.careBulkMarkDoneCount(count)),
        style: fullWidth
            ? FilledButton.styleFrom(minimumSize: const Size.fromHeight(48))
            : null,
      );
    }

    Widget skipButton({required bool fullWidth}) {
      return OutlinedButton.icon(
        key: const Key('care_item_bulk_skip'),
        onPressed: muted ? null : onSkipAll,
        icon: const Icon(Icons.skip_next, size: 18),
        label: Text(l.careBulkSkipCount(count)),
        style: fullWidth
            ? OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))
            : null,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(14) >= 28;
        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              markButton(fullWidth: true),
              const SizedBox(height: 8),
              skipButton(fullWidth: true),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: markButton(fullWidth: false)),
            const SizedBox(width: 8),
            Expanded(child: skipButton(fullWidth: false)),
          ],
        );
      },
    );
  }
}
