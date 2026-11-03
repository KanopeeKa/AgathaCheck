import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../application/people_commands.dart';
import '../../../application/people_providers.dart';
import '../../../domain/entities/contact_summary.dart';
import '../../../domain/entities/pet_people.dart';
import '../../../domain/enums/contact_role.dart';
import '../../../domain/enums/relationship_kind.dart';
import '../linkable_pets_provider.dart';
import '../person_detail_target.dart';
import '../../labels/people_labels.dart';
import '../../pet/confirm_replace_pet_slot.dart';

Future<void> showLinkPetSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String contactId,
  List<ContactPetLink> linkedPets = const [],
}) async {
  final List<RosterPetOption> pets;
  try {
    pets = await ref.read(linkablePetOptionsProvider.future);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.peopleListLoadError),
      ),
    );
    return;
  }
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
      contactId: contactId,
      pets: pets,
      linkedPets: linkedPets,
    ),
  );
}

List<RelationshipKind> linkPetRelationshipKindOptions({required bool isVet}) {
  if (isVet) {
    return const [
      RelationshipKind.primaryVet,
      RelationshipKind.outOfHoursVet,
      RelationshipKind.careProvider,
      RelationshipKind.emergencyContact,
      RelationshipKind.other,
    ];
  }
  return const [
    RelationshipKind.careProvider,
    RelationshipKind.emergencyContact,
    RelationshipKind.other,
  ];
}

bool readContactHasVetRole(WidgetRef ref, String contactId) {
  final summary = ref.read(personSummaryProvider(contactId));
  if (summary != null) {
    return summary.roles.contains(ContactRole.vet);
  }
  final detail = ref.read(personDetailProvider(contactId)).valueOrNull;
  return detail?.roles.contains(ContactRole.vet) ?? false;
}

class _LinkPetSheetBody extends ConsumerStatefulWidget {
  const _LinkPetSheetBody({
    required this.contactId,
    required this.pets,
    required this.linkedPets,
  });

  final String contactId;
  final List<RosterPetOption> pets;
  final List<ContactPetLink> linkedPets;

  @override
  ConsumerState<_LinkPetSheetBody> createState() => _LinkPetSheetBodyState();
}

class _LinkPetSheetBodyState extends ConsumerState<_LinkPetSheetBody> {
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

  Future<void> _onPetSelected(String? petId) async {
    setState(() {
      _selectedPetId = petId;
      _selectedKind = null;
    });
    if (petId == null) return;
    if (!readContactHasVetRole(ref, widget.contactId)) return;

    List<PetRelationship> relationships;
    try {
      final repo = ref.read(peopleRepositoryProvider);
      relationships = await repo.fetchPetRelationships(petId);
    } catch (_) {
      return;
    }
    if (!mounted || _selectedPetId != petId || _selectedKind != null) return;
    final hasPrimaryVet = relationships.any(
      (r) => r.active && r.relationshipKind == RelationshipKind.primaryVet,
    );
    if (!hasPrimaryVet) {
      setState(() => _selectedKind = RelationshipKind.primaryVet);
    }
  }

  Future<void> _confirmLink() async {
    final petId = _selectedPetId!;
    final kind = _selectedKind!;
    final petName = widget.pets.firstWhere((p) => p.petId == petId).petName;
    final commands = ref.read(peopleCommandsProvider);

    if (kind == RelationshipKind.primaryVet ||
        kind == RelationshipKind.outOfHoursVet) {
      final ok = await confirmReplacePetSlotIfNeeded(
        context: context,
        ref: ref,
        petId: petId,
        petName: petName,
        slotKind: kind,
        incomingContactId: widget.contactId,
      );
      if (!ok || !mounted) return;
      Navigator.of(context).pop();
      await commands.setPetSlot(
        contactId: widget.contactId,
        petId: petId,
        slotKind: kind,
        slotContactId: widget.contactId,
      );
      return;
    }

    Navigator.of(context).pop();
    await commands.linkContactToPet(
      contactId: widget.contactId,
      petId: petId,
      relationshipKind: kind,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final summary = ref.watch(personSummaryProvider(widget.contactId));
    final detailAsync = ref.watch(personDetailProvider(widget.contactId));
    final isVet = summary != null
        ? summary.roles.contains(ContactRole.vet)
        : (detailAsync.valueOrNull?.roles.contains(ContactRole.vet) ?? false);
    final kindOptions = linkPetRelationshipKindOptions(isVet: isVet);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
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
                    subtitle: _linkedSubtitle(l, pet.petId),
                    onChanged: _onPetSelected,
                  ),
                const SizedBox(height: 8),
                Text(
                  l.peopleDetailLinkPetChooseKind,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: kindOptions.map((kind) {
                    return FilterChip(
                      label: Text(kind.label(l)),
                      selected: _selectedKind == kind,
                      onSelected: (_) => setState(() => _selectedKind = kind),
                    );
                  }).toList(),
                ),
                if (_selectedPetId != null && _selectedKind == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l.peopleDetailLinkPetKindRequired,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('people_detail_link_pet_confirm'),
                  onPressed: _selectedPetId == null || _selectedKind == null
                      ? null
                      : _confirmLink,
                  child: Text(l.peopleDetailLinkToPet),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
