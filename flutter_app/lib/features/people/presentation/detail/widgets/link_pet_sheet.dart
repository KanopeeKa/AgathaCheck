import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../application/people_commands.dart';
import '../../../domain/enums/relationship_kind.dart';
import '../person_detail_target.dart';
import '../../labels/people_labels.dart';

Future<void> showLinkPetSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String contactId,
  required List<RosterPetOption> pets,
}) async {
  if (pets.isEmpty) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _LinkPetSheetBody(
      ref: ref,
      contactId: contactId,
      pets: pets,
    ),
  );
}

class _LinkPetSheetBody extends StatefulWidget {
  const _LinkPetSheetBody({
    required this.ref,
    required this.contactId,
    required this.pets,
  });

  final WidgetRef ref;
  final String contactId;
  final List<RosterPetOption> pets;

  @override
  State<_LinkPetSheetBody> createState() => _LinkPetSheetBodyState();
}

class _LinkPetSheetBodyState extends State<_LinkPetSheetBody> {
  String? _selectedPetId;
  RelationshipKind? _selectedKind;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.peopleDetailLinkPetTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final pet in widget.pets)
              RadioListTile<String>(
                value: pet.petId,
                groupValue: _selectedPetId,
                title: Text(pet.petName),
                onChanged: (value) => setState(() => _selectedPetId = value),
              ),
            const SizedBox(height: 8),
            Text(
              l.peopleDetailLinkPetChooseKind,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                RelationshipKind.careProvider,
                RelationshipKind.emergencyContact,
                RelationshipKind.other,
              ].map((kind) {
                return FilterChip(
                  label: Text(kind.label(l)),
                  selected: _selectedKind == kind,
                  onSelected: (_) => setState(() => _selectedKind = kind),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('people_detail_link_pet_confirm'),
              onPressed: _selectedPetId == null || _selectedKind == null
                  ? null
                  : () async {
                      final petId = _selectedPetId!;
                      final kind = _selectedKind!;
                      Navigator.of(context).pop();
                      await widget.ref
                          .read(peopleCommandsProvider)
                          .linkContactToPet(
                            contactId: widget.contactId,
                            petId: petId,
                            relationshipKind: kind,
                          );
                    },
              child: Text(l.peopleDetailLinkToPet),
            ),
          ],
        ),
      ),
    );
  }
}
