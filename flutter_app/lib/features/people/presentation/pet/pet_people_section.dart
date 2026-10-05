import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/pet_people.dart';
import '../../domain/services/pet_people_grouping.dart';
import '../households/household_tier_labels.dart';
import '../labels/people_labels.dart';
import 'pet_emergency_card.dart';

/// "People around {pet}" on the pet profile: emergency card and grouped contacts.
class PetPeopleSection extends ConsumerWidget {
  const PetPeopleSection({
    super.key,
    required this.petId,
    required this.petName,
    required this.canManage,
  });

  final String petId;
  final String petName;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(petPeopleProvider(petId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (people) {
        if (people == null) return const SizedBox.shrink();
        return _PetPeopleBody(
          people: people,
          canManage: canManage && people.scope == 'full',
        );
      },
    );
  }
}

class _PetPeopleBody extends StatelessWidget {
  const _PetPeopleBody({required this.people, required this.canManage});

  final PetPeople people;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final carers = trustedCarerRelationships(people);
    final professionals = professionalRelationships(people);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.peopleAroundPetTitle(people.petName),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                l.peoplePetOwnerQuiet(people.petName, people.owner.displayName),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        PetEmergencyCard(people: people, canManage: canManage),
        if (people.scope == 'full')
          _PeopleGroup(
            title: l.peopleGroupAtHome,
            emptyLabel: l.peoplePetEmptyAtHome,
            children: people.householdMembers
                .map(
                  (m) => _PersonLine(
                    name: m.displayName,
                    subtitle: householdTierLabel(
                      l,
                      m.tier,
                      organiser: m.isOrganiser,
                    ),
                  ),
                )
                .toList(),
          ),
        _PeopleGroup(
          title: l.peopleGroupCarers,
          emptyLabel: l.peopleEmptyCarers,
          children: carers
              .map(
                (r) => _PersonLine(
                  name: r.contactName,
                  subtitle: r.relationshipKind.label(l),
                ),
              )
              .toList(),
        ),
        _PeopleGroup(
          title: l.peopleGroupProfessionals,
          emptyLabel: l.peopleEmptyProfessionals,
          children: professionals
              .map(
                (r) => _PersonLine(
                  name: r.contactName,
                  subtitle: r.relationshipKind.label(l),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PeopleGroup extends StatelessWidget {
  const _PeopleGroup({
    required this.title,
    required this.emptyLabel,
    required this.children,
  });

  final String title;
  final String emptyLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            Text(
              emptyLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _PersonLine extends StatelessWidget {
  const _PersonLine({required this.name, required this.subtitle});

  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(name),
      subtitle: Text(subtitle),
    );
  }
}
