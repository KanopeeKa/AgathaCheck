import 'package:flutter/material.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Change date + Skip for an open occurrence (Care date identity card).
class OccurrenceScheduleActionBar extends StatelessWidget {
  const OccurrenceScheduleActionBar({
    super.key,
    required this.busy,
    required this.showChangeDate,
    required this.onChangeDate,
    required this.onSkip,
  });

  final bool busy;
  final bool showChangeDate;
  final VoidCallback? onChangeDate;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically =
            constraints.maxWidth < 360 ||
            MediaQuery.textScalerOf(context).scale(14) >= 28;

        Widget changeDate({required bool fullWidth}) {
          if (!showChangeDate) return const SizedBox.shrink();
          return Semantics(
            identifier: 'occurrence_reschedule',
            button: true,
            label: l.rescheduleActionLabel,
            child: OutlinedButton.icon(
              key: const Key('occurrence_reschedule'),
              onPressed: busy ? null : onChangeDate,
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: ExcludeSemantics(child: Text(l.rescheduleActionLabel)),
              style: fullWidth
                  ? OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))
                  : null,
            ),
          );
        }

        Widget skip({required bool fullWidth}) {
          return OutlinedButton.icon(
            key: const Key('occurrence_skip'),
            onPressed: busy ? null : onSkip,
            icon: const Icon(Icons.skip_next, size: 18),
            label: Text(l.careSkip),
            style: fullWidth
                ? OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))
                : null,
          );
        }

        if (!showChangeDate) {
          return skip(fullWidth: true);
        }

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              changeDate(fullWidth: true),
              const SizedBox(height: 8),
              skip(fullWidth: true),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: changeDate(fullWidth: false)),
            const SizedBox(width: 8),
            Expanded(child: skip(fullWidth: false)),
          ],
        );
      },
    );
  }
}
