import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Result of the weigh-in skip sheet (optional reason + note).
class SkipWeighInResult {
  const SkipWeighInResult({this.reasonCode, this.notes = ''});

  final String? reasonCode;
  final String notes;
}

/// Skip with an optional reason for weight monitoring (§6.6, D-WM-015).
Future<SkipWeighInResult?> showSkipWeighInSheet(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  String? selectedCode;
  final notesController = TextEditingController();

  return showModalBottomSheet<SkipWeighInResult>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            Widget chip(String code, String label) {
              return ChoiceChip(
                key: Key('skip_weigh_in_reason_$code'),
                label: Text(label),
                selected: selectedCode == code,
                onSelected: (selected) {
                  setState(() => selectedCode = selected ? code : null);
                },
              );
            }

            return Padding(
              key: const Key('skip_weigh_in_sheet'),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.careSkipWeighInTitle,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.careSkipReasonOptional,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      chip('could_not_weigh', l.careSkipReasonCouldNotWeigh),
                      chip('pet_unsettled', l.careSkipReasonPetUnsettled),
                      chip('vet_will_weigh', l.careSkipReasonVetWillWeigh),
                      chip('other', l.careSkipReasonOther),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('skip_weigh_in_note'),
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: l.notes,
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('skip_weigh_in_cancel'),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(l.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          key: const Key('skip_weigh_in_confirm'),
                          onPressed: () => Navigator.pop(
                            ctx,
                            SkipWeighInResult(
                              reasonCode: selectedCode,
                              notes: notesController.text.trim(),
                            ),
                          ),
                          child: Text(l.careSkip),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
