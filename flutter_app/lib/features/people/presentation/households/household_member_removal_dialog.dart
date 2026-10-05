import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/household.dart';
import '../../domain/repositories/people_repository.dart';

enum HouseholdRemovalChoice { householdOnly, allAccess }

Future<HouseholdRemovalResult?> showHouseholdMemberRemovalDialog({
  required BuildContext context,
  required HouseholdMemberRemovalPreview preview,
  required List<HouseholdMember> successorCandidates,
  required bool removingSelf,
}) {
  return showDialog<HouseholdRemovalResult>(
    context: context,
    builder: (ctx) => _HouseholdMemberRemovalDialog(
      preview: preview,
      successorCandidates: successorCandidates,
      removingSelf: removingSelf,
    ),
  );
}

class HouseholdRemovalResult {
  const HouseholdRemovalResult({required this.choice, this.successorUserId});

  final HouseholdRemovalChoice choice;
  final String? successorUserId;
}

class _HouseholdMemberRemovalDialog extends StatefulWidget {
  const _HouseholdMemberRemovalDialog({
    required this.preview,
    required this.successorCandidates,
    required this.removingSelf,
  });

  final HouseholdMemberRemovalPreview preview;
  final List<HouseholdMember> successorCandidates;
  final bool removingSelf;

  @override
  State<_HouseholdMemberRemovalDialog> createState() =>
      _HouseholdMemberRemovalDialogState();
}

class _HouseholdMemberRemovalDialogState
    extends State<_HouseholdMemberRemovalDialog> {
  String? _successorUserId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final preview = widget.preview;
    final needsSuccessor = preview.requiresSuccessor;

    return AlertDialog(
      title: Text(
        widget.removingSelf
            ? l.peopleHouseholdLeaveTitle
            : l.peopleMemberRemovalTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.removingSelf
                  ? l.peopleHouseholdLeaveBody
                  : l.peopleMemberRemovalBody,
            ),
            if (preview.remainingAccess.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l.peopleMemberRemovalRemaining),
              for (final access in preview.remainingAccess)
                Text('• ${access.petName} (${access.source})'),
            ],
            if (needsSuccessor) ...[
              const SizedBox(height: 16),
              Text(l.peopleHouseholdSuccessorLabel),
              const SizedBox(height: 8),
              DropdownMenu<String>(
                initialSelection: _successorUserId,
                label: Text(l.peopleHouseholdSuccessorLabel),
                dropdownMenuEntries: [
                  for (final member in widget.successorCandidates)
                    DropdownMenuEntry(
                      value: member.userId,
                      label: member.displayName,
                    ),
                ],
                onSelected: (value) => setState(() => _successorUserId = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        if (!widget.removingSelf)
          TextButton(
            onPressed: needsSuccessor && _successorUserId == null
                ? null
                : () => Navigator.pop(
                    context,
                    HouseholdRemovalResult(
                      choice: HouseholdRemovalChoice.householdOnly,
                      successorUserId: _successorUserId,
                    ),
                  ),
            child: Text(l.peopleMemberRemovalHouseholdOnly),
          ),
        FilledButton(
          onPressed: needsSuccessor && _successorUserId == null
              ? null
              : () => Navigator.pop(
                  context,
                  HouseholdRemovalResult(
                    choice: widget.removingSelf
                        ? HouseholdRemovalChoice.householdOnly
                        : HouseholdRemovalChoice.allAccess,
                    successorUserId: _successorUserId,
                  ),
                ),
          child: Text(
            widget.removingSelf
                ? l.peopleHouseholdLeaveAction
                : l.peopleMemberRemovalAllAccess,
          ),
        ),
      ],
    );
  }
}
