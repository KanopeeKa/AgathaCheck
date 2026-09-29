import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../vet/presentation/widgets/vet_team_initials_avatar.dart';
import '../../../vet/presentation/widgets/vet_team_pet_row.dart';
import '../../domain/entities/people_contact.dart';
import '../providers/people_providers.dart';
import '../utils/people_contact_role_labels.dart';
import '../widgets/people_contact_coordinates_section.dart';

class PeopleDetailScreen extends ConsumerWidget {
  const PeopleDetailScreen({
    super.key,
    required this.personId,
    this.embedded = false,
  });

  final String personId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(peopleContactDetailProvider(personId));

    return detailAsync.when(
      loading: () {
        final cached = ref.watch(peopleContactByIdProvider(personId));
        if (cached != null) {
          return _buildScaffold(context, ref, l, cached, embedded);
        }
        final body = const Center(child: CircularProgressIndicator());
        if (embedded) return body;
        return ExperienceShellScaffold(
          experience: AppExperience.petCare,
          currentLocation: '/pc/people/$personId',
          screenTitle: l.peoplePageTitle,
          child: body,
        );
      },
      error: (_, __) => Center(child: Text(l.peopleListLoadError)),
      data: (contact) {
        if (contact == null) {
          final body = Center(child: Text(l.peopleDetailNotFound));
          if (embedded) return body;
          return ExperienceShellScaffold(
            experience: AppExperience.petCare,
            currentLocation: '/pc/people/$personId',
            screenTitle: l.peoplePageTitle,
            child: body,
          );
        }
        return _buildScaffold(context, ref, l, contact, embedded);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    PeopleContact contact,
    bool embedded,
  ) {
    final theme = Theme.of(context);
    final inactive = contact.inactiveAt != null;
    final rolesLine = peopleContactRolesLine(l, contact.roles);
    final pets = _linkedPets(ref, contact);

    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VetTeamInitialsAvatar(name: contact.name, organizationId: null),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (rolesLine.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: contact.roles
                          .map(
                            (r) => Chip(
                              label: Text(peopleContactRoleLabel(l, r)),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (inactive)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l.peopleStatusInactive,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!embedded)
              IconButton(
                tooltip: l.peopleEditPerson,
                onPressed: () => context.push('/pc/people/$personId/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        const SizedBox(height: 20),
        PeopleContactCoordinatesSection(
          phone: contact.phone,
          email: contact.email,
          address: contact.address,
          website: contact.website,
        ),
        if (contact.privateNote.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l.peoplePrivateNoteLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.peoplePrivateNoteHelper,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(contact.privateNote),
        ],
        const SizedBox(height: 24),
        Text(
          l.peopleLinkedPetsTitle,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (pets.isEmpty)
          Text(
            l.peopleNoLinkedPets,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...pets.asMap().entries.map(
            (e) => VetTeamPetRow(
              key: Key('people_contact_pet_${e.value.id}'),
              pet: e.value,
              showDivider: e.key < pets.length - 1,
            ),
          ),
      ],
    );

    if (embedded) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/pc/people/$personId/edit'),
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.peopleEditPerson),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: '/pc/people/$personId',
      screenTitle: contact.name,
      child: content,
    );
  }

  List<Pet> _linkedPets(WidgetRef ref, PeopleContact contact) {
    final vetId = contact.legacyVetId;
    if (vetId == null || vetId.isEmpty) return const [];
    final pets = ref.watch(petListProvider).valueOrNull ?? [];
    return pets.where((p) => p.vetId == vetId).toList();
  }
}
