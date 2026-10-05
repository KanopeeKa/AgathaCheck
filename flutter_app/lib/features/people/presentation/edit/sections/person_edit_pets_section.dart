import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/form/app_form_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../application/people_commands.dart';
import '../../../application/people_providers.dart';
import '../../../domain/entities/contact_summary.dart';
import '../../../domain/enums/relationship_kind.dart';
import '../../labels/people_labels.dart';
import '../../detail/widgets/link_pet_sheet.dart';
import '../../detail/person_detail_target.dart';

class PersonEditPetsSection extends ConsumerStatefulWidget {
  const PersonEditPetsSection({
    super.key,
    required this.contactId,
    required this.petLinks,
    required this.rosterPetOptions,
  });

  final String contactId;
  final List<ContactPetLink> petLinks;
  final List<RosterPetOption> rosterPetOptions;

  @override
  ConsumerState<PersonEditPetsSection> createState() =>
      _PersonEditPetsSectionState();
}

class _PersonEditPetsSectionState extends ConsumerState<PersonEditPetsSection> {
  bool _busy = false;

  Future<void> _setSlot(
    BuildContext context,
    ContactPetLink pet,
    RelationshipKind slotKind,
  ) async {
    final l = AppLocalizations.of(context)!;
    final repo = ref.read(peopleRepositoryProvider);
    final relationships = await repo.fetchPetRelationships(pet.petId);
    final incumbent = relationships
        .where(
          (r) =>
              r.active &&
              r.relationshipKind == slotKind &&
              r.contactId != widget.contactId,
        )
        .firstOrNull;
    if (incumbent != null && context.mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.peopleReplaceSlotTitle),
          content: Text(
            l.peopleReplaceSlotBody(incumbent.contactName, pet.petName),
          ),
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
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .setPetSlot(
            contactId: widget.contactId,
            petId: pet.petId,
            slotKind: slotKind,
            slotContactId: widget.contactId,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeLink(ContactPetLink pet) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(peopleRepositoryProvider);
      final relationships = await repo.fetchPetRelationships(pet.petId);
      final match = relationships
          .where((r) => r.active && r.contactId == widget.contactId)
          .firstOrNull;
      if (match == null) return;
      await ref
          .read(peopleCommandsProvider)
          .removePetRelationship(
            contactId: widget.contactId,
            petId: pet.petId,
            relationshipId: match.id,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _moveEmergency(
    String petId,
    List<String> ids,
    int index,
    int delta,
  ) async {
    if (index + delta < 0 || index + delta >= ids.length) return;
    final next = List<String>.from(ids);
    final item = next.removeAt(index);
    next.insert(index + delta, item);
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .reorderEmergencyContacts(
            contactId: widget.contactId,
            petId: petId,
            orderedRelationshipIds: next,
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppFormSection(
      title: l.peopleLinkedPetsTitle,
      children: [
        if (widget.petLinks.isEmpty)
          Text(
            l.peopleNoLinkedPets,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        for (final pet in widget.petLinks) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(pet.petName),
            subtitle: Text(pet.relationshipKind.label(l)),
            trailing: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<String>(
                    key: Key('people_edit_pet_menu_${pet.petId}'),
                    onSelected: (value) async {
                      switch (value) {
                        case 'primary':
                          await _setSlot(
                            context,
                            pet,
                            RelationshipKind.primaryVet,
                          );
                        case 'ooh':
                          await _setSlot(
                            context,
                            pet,
                            RelationshipKind.outOfHoursVet,
                          );
                        case 'remove':
                          await _removeLink(pet);
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'primary',
                        child: Text(l.peopleEditSetPrimaryVet),
                      ),
                      PopupMenuItem(
                        value: 'ooh',
                        child: Text(l.peopleEditSetOutOfHoursVet),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(l.peopleEditRemovePetLink),
                      ),
                    ],
                  ),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () => showLinkPetSheet(
                  context: context,
                  ref: ref,
                  contactId: widget.contactId,
                  pets: widget.rosterPetOptions,
                ),
          icon: const Icon(Icons.link),
          label: Text(l.peopleDetailLinkToPet),
        ),
        _EmergencyReorder(
          contactId: widget.contactId,
          petLinks: widget.petLinks,
          busy: _busy,
          onMove: _moveEmergency,
        ),
      ],
    );
  }
}

class _EmergencyReorder extends ConsumerWidget {
  const _EmergencyReorder({
    required this.contactId,
    required this.petLinks,
    required this.busy,
    required this.onMove,
  });

  final String contactId;
  final List<ContactPetLink> petLinks;
  final bool busy;
  final Future<void> Function(
    String petId,
    List<String> ids,
    int index,
    int delta,
  )
  onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder(
      future: _loadEmergencyIds(ref),
      builder: (context, snapshot) {
        final byPet = snapshot.data ?? {};
        if (byPet.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              l.peopleEditEmergencyOrderTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final entry in byPet.entries) ...[
              Text(
                petLinks
                        .where((p) => p.petId == entry.key)
                        .map((p) => p.petName)
                        .firstOrNull ??
                    entry.key,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              for (var i = 0; i < entry.value.length; i++)
                Row(
                  children: [
                    Expanded(child: Text(entry.value[i].name)),
                    IconButton(
                      key: Key('people_edit_emergency_up_${entry.value[i].id}'),
                      onPressed: busy
                          ? null
                          : () => onMove(
                              entry.value.first.petId,
                              entry.value.map((e) => e.id).toList(),
                              i,
                              -1,
                            ),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      key: Key(
                        'people_edit_emergency_down_${entry.value[i].id}',
                      ),
                      onPressed: busy
                          ? null
                          : () => onMove(
                              entry.value.first.petId,
                              entry.value.map((e) => e.id).toList(),
                              i,
                              1,
                            ),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                ),
            ],
          ],
        );
      },
    );
  }

  Future<Map<String, List<_EmergencyRow>>> _loadEmergencyIds(
    WidgetRef ref,
  ) async {
    final repo = ref.read(peopleRepositoryProvider);
    final out = <String, List<_EmergencyRow>>{};
    for (final link in petLinks) {
      if (link.relationshipKind != RelationshipKind.emergencyContact) continue;
      final rels = await repo.fetchPetRelationships(link.petId);
      final emergency = rels
          .where(
            (r) =>
                r.active &&
                r.relationshipKind == RelationshipKind.emergencyContact,
          )
          .toList();
      if (emergency.length > 1) {
        out[link.petId] = emergency
            .map((r) => _EmergencyRow(r.id, r.contactName, link.petId))
            .toList();
      }
    }
    return out;
  }
}

class _EmergencyRow {
  const _EmergencyRow(this.id, this.name, this.petId);
  final String id;
  final String name;
  final String petId;
}
