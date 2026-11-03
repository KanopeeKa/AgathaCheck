import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../application/people_commands.dart';
import '../../../domain/entities/contact_summary.dart';
import '../../../domain/enums/relationship_kind.dart';
import '../linkable_pets_provider.dart';
import '../person_detail_target.dart';
import '../../labels/people_labels.dart';

Future<void> showLinkPetSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String contactId,
  List<ContactPetLink> linkedPets = const [],
}) async {
  final pets = await ref.read(linkablePetOptionsProvider.future);
  if (!context.mounted) return;
  if (pets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.peopleAddPetsEmpty)),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _LinkPetSheetBody(
      ref: ref,
      contactId: contactId,
      pets: pets,
      linkedPets: linkedPets,
    ),
  );
}

class _LinkPetSheetBody extends StatefulWidget {
  const _LinkPetSheetBody({
    required this.ref,
    required this.contactId,
    required this.pets,
    required this.linkedPets,
  });

  final WidgetRef ref;
  final String contactId;
  final List<RosterPetOption> pets;
  final List<ContactPetLink> linkedPets;

  @override
  State<_LinkPetSheetBody> createState() => _LinkPetSheetBodyState();
}

class _LinkPetSheetBodyState extends State<_LinkPetSheetBody> {
  String? _selectedPetId;
  RelationshipKind? _selectedKind;

  Widget? _linkedSubtitle(AppLocalizations l, String petId) {
    final labels = widget.linkedPets
        .where((p) => p.petId == petId)
        .map((p) => p.relationshipKind.label(l))
        .toSet();
    if (labels.isEmpty) return null;
    return Text(labels.join(', '));
  }

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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final pet in widget.pets)
              RadioListTile<String>(
                value: pet.petId,
                groupValue: _selectedPetId,
                title: Text(pet.petName),
                subtitle: _linkedSubtitle(l, pet.petId),
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
              children:
                  [
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
