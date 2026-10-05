import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/weight/weight_unit.dart';
import '../../../../core/weight/weight_unit_preference.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_history_entry.dart';
import 'event_history_formatter.dart';

/// Administration log dialog shared by edit and view entry screens.
Future<void> showPetEventAdministrationHistoryDialog(
  BuildContext context, {
  required List<HealthHistoryEntry> history,
}) {
  final l = AppLocalizations.of(context)!;
  final dateFormat = DateFormat.yMMMd();
  final dateTimeFormat = DateFormat.yMMMd().add_jm();

  return showDialog<void>(
    context: context,
    builder: (ctx) => Consumer(
      builder: (ctx, ref, _) {
        final unit = ref.watch(weightUnitPreferenceProvider);
        return AlertDialog(
          title: Text(l.administrationHistory),
          content: SizedBox(
            width: double.maxFinite,
            child: history.isEmpty
                ? Text(l.noHistoryYet)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (_, i) {
                      final h = history[i];
                      final linked = h.linkedWeight;
                      final subtitleLines = <String>[
                        if (linked != null) formatWeight(linked.valueKg, unit),
                        if (h.notes.isNotEmpty) h.notes,
                      ];
                      return ListTile(
                        key: linked != null
                            ? Key('history_row_linked_weight_${h.id}')
                            : null,
                        leading: Icon(
                          h.isSkipped ? Icons.skip_next : Icons.check_circle,
                          color: h.isSkipped
                              ? Theme.of(ctx).colorScheme.onSurfaceVariant
                              : AppColorTokens.success,
                        ),
                        title: Text(
                          h.isSkipped
                              ? '${l.occurrenceSkipped}: ${h.dueDate != null ? dateFormat.format(h.dueDate!) : l.notSet}'
                              : formatEventHistoryLine(
                                  h,
                                  l,
                                  dateFormat,
                                  dateTimeFormat,
                                ),
                        ),
                        subtitle: subtitleLines.isEmpty
                            ? null
                            : Text(subtitleLines.join('\n')),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.close),
            ),
          ],
        );
      },
    ),
  );
}
