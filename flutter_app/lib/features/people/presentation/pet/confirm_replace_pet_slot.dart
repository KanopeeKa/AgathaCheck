import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../../domain/enums/relationship_kind.dart';

/// Confirms replacing an incumbent primary or out-of-hours vet before a slot write.
Future<bool> confirmReplacePetSlotIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required String petId,
  required String petName,
  required RelationshipKind slotKind,
  required String incomingContactId,
}) async {
  if (slotKind == RelationshipKind.emergencyContact) return true;
  final repo = ref.read(peopleRepositoryProvider);
  final relationships = await repo.fetchPetRelationships(petId);
  final incumbent = relationships
      .where(
        (r) =>
            r.active &&
            r.relationshipKind == slotKind &&
            r.contactId != incomingContactId,
      )
      .firstOrNull;
  if (incumbent == null) return true;
  if (!context.mounted) return false;
  final l = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.peopleReplaceSlotTitle),
      content: Text(l.peopleReplaceSlotBody(incumbent.contactName, petName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.peopleReplaceSlotConfirm),
        ),
      ],
    ),
  );
  return ok == true;
}
