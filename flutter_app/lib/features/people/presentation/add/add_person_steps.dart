import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../../domain/enums/contact_role.dart';
import '../../domain/enums/relationship_kind.dart';
import '../labels/people_labels.dart';
import '../widgets/role_chips.dart';
import 'add_person_providers.dart';
import 'add_person_dedupe.dart';
import 'add_person_step_finalize.dart';
import 'add_person_entry.dart';
import 'add_person_flow_controller.dart';
import 'add_person_pet_selection.dart';

class AddPersonStepWho extends StatelessWidget {
  const AddPersonStepWho({super.key, required this.controller});

  final AddPersonFlowController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.peopleAddStepWhoTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _EntryTile(
          key: const Key('people_add_tile_household'),
          title: l.peopleAddTileHousehold,
          helper: l.peopleAddTileHouseholdHelper,
          icon: Icons.home_outlined,
          selected: controller.entry == AddPersonEntry.household,
          onTap: () => controller.selectEntry(AddPersonEntry.household),
        ),
        _EntryTile(
          key: const Key('people_add_tile_carer'),
          title: l.peopleAddTileCarer,
          helper: l.peopleAddTileCarerHelper,
          icon: Icons.favorite_outline,
          selected: controller.entry == AddPersonEntry.carer,
          onTap: () => controller.selectEntry(AddPersonEntry.carer),
        ),
        _EntryTile(
          key: const Key('people_add_tile_professional'),
          title: l.peopleAddTileProfessional,
          helper: l.peopleAddTileProfessionalHelper,
          icon: Icons.medical_services_outlined,
          selected: controller.entry == AddPersonEntry.professional,
          onTap: () => controller.selectEntry(AddPersonEntry.professional),
        ),
        _EntryTile(
          key: const Key('people_add_tile_organisation'),
          title: l.peopleAddTileOrganisation,
          helper: l.peopleAddTileOrganisationHelper,
          icon: Icons.business_outlined,
          selected: controller.entry == AddPersonEntry.organisation,
          onTap: () => controller.selectEntry(AddPersonEntry.organisation),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    super.key,
    required this.title,
    required this.helper,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String helper;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        helper,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AddPersonStepAbout extends ConsumerWidget {
  const AddPersonStepAbout({super.key, required this.controller});

  final AddPersonFlowController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final form = controller.form;
    final roster = ref.watch(rosterProvider).valueOrNull;
    final matches = roster == null
        ? const []
        : findAddPersonDuplicates(
            roster: roster.contacts,
            name: form.name,
            phone: form.phone,
            email: form.email,
          );

    return ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.peopleAddStepAbout,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AppFormLabeledField(
              label: l.peopleNameLabel,
              child: TextFormField(
                key: const Key('people_add_name_field'),
                initialValue: form.name,
                decoration: InputDecoration(
                  errorText: form.nameError == null
                      ? null
                      : l.peopleNameRequired,
                ),
                onChanged: form.setName,
                autofocus: true,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: form.phone,
              decoration: InputDecoration(labelText: l.peoplePhoneLabel),
              keyboardType: TextInputType.phone,
              onChanged: form.setPhone,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: form.email,
              decoration: InputDecoration(
                labelText: l.peopleEmailLabel,
                errorText: form.emailError == null
                    ? null
                    : l.orgInviteEmailInvalid,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: form.setEmail,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: form.address,
              decoration: InputDecoration(labelText: l.peopleAddressLabel),
              minLines: 2,
              maxLines: 3,
              onChanged: form.setAddress,
            ),
            const SizedBox(height: 16),
            Text(
              l.peopleAddDedupeTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (matches.isEmpty)
              Text(
                l.peopleAddDedupeEmpty,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final match in matches)
                ListTile(
                  key: Key('people_add_dedupe_${match.id}'),
                  leading: const Icon(Icons.person_search_outlined),
                  title: Text(match.name),
                  subtitle: Text(contactRolesLine(l, match.roles)),
                  trailing: TextButton(
                    onPressed: () => context.push('/pc/people/${match.id}'),
                    child: Text(l.peopleAddOpenExisting),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class AddPersonStepRoles extends StatelessWidget {
  const AddPersonStepRoles({super.key, required this.controller});

  final AddPersonFlowController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entry = controller.entry!;
    final form = controller.form;
    final group = entry.suggestedRoleGroup;

    return ListenableBuilder(
      listenable: form,
      builder: (context, _) {
        final roles = group == null
            ? ContactRole.values
            : ContactRole.values.where((r) => r.group == group).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.peopleAddStepRelationship,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            RoleChips(
              roles: roles,
              mode: RoleChipsMode.groupedSelect,
              selected: form.roles,
              onToggle: form.toggleRole,
            ),
            if (controller.rolesError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.peopleAddRolesRequired,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AddPersonStepPets extends ConsumerWidget {
  const AddPersonStepPets({super.key, required this.controller});

  final AddPersonFlowController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entry = controller.entry!;
    final petsAsync = ref.watch(addPersonPetsProvider);
    return petsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(l.peopleListLoadError),
      data: (petNames) {
        if (controller.pets.isEmpty && petNames.isNotEmpty) {
          controller.setPets(
            petNames
                .map(
                  (p) => AddPersonPetSelection(
                    petId: p.id,
                    petName: p.name,
                  ),
                )
                .toList(),
          );
        }
        final selections = controller.pets;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.peopleAddStepPets,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (selections.isEmpty)
              Text(l.peopleAddPetsEmpty, style: Theme.of(context).textTheme.bodySmall)
            else
              for (final pet in selections)
                _PetRow(
                  selection: pet,
                  entry: entry,
                  onChanged: controller.touchPets,
                ),
          ],
        );
      },
    );
  }
}

class _PetRow extends StatelessWidget {
  const _PetRow({
    required this.selection,
    required this.entry,
    required this.onChanged,
  });

  final AddPersonPetSelection selection;
  final AddPersonEntry entry;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        CheckboxListTile(
          value: selection.selected,
          onChanged: (v) {
            selection.selected = v ?? false;
            onChanged();
          },
          title: Text(selection.petName),
        ),
        if (selection.selected && entry == AddPersonEntry.professional)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: DropdownButtonFormField<RelationshipKind>(
              initialValue: selection.relationshipKind,
              decoration: InputDecoration(labelText: l.peopleAddPetLinkKind),
              items: const [
                RelationshipKind.primaryVet,
                RelationshipKind.outOfHoursVet,
                RelationshipKind.careProvider,
              ]
                  .map(
                    (k) => DropdownMenuItem(
                      value: k,
                      child: Text(k.label(l)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  selection.relationshipKind = v;
                  onChanged();
                }
              },
            ),
          ),
        if (selection.selected && entry == AddPersonEntry.carer)
          SwitchListTile(
            title: Text(l.peopleAddEmergencyContact),
            value: selection.emergencyContact,
            onChanged: (v) {
              selection.emergencyContact = v;
              if (v) {
                selection.relationshipKind = RelationshipKind.emergencyContact;
              }
              onChanged();
            },
          ),
      ],
    );
  }
}
