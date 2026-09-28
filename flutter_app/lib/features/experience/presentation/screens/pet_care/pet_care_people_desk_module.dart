import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../people/domain/entities/people_contact.dart';
import '../../../../people/presentation/providers/people_providers.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../sharing/presentation/providers/household_providers.dart';
import '../../widgets/pet_care_dashboard_section_header.dart';
import '../../widgets/pet_care_illustrated_empty_state.dart';

/// Today dashboard People module — top professionals, carers, household rail.
class PetCarePeopleDeskModule extends ConsumerWidget {
  const PetCarePeopleDeskModule({super.key});

  static const _previewLimit = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final auth = ref.watch(authProvider);
    final contactsAsync = ref.watch(peopleContactsProvider);
    final petsAsync = ref.watch(petListProvider);
    final householdsAsync = ref.watch(householdListProvider);

    return Semantics(
      container: true,
      label: l.peoplePageTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetCareDashboardSectionChrome(
            title: l.peoplePageTitle.toUpperCase(),
            linkLabel: l.peopleDeskSeeAll,
            linkKey: const Key('pet_care_dashboard_all_people'),
            onLinkPressed: () => context.go('/pc/people'),
          ),
          const SizedBox(height: 10),
          if (auth.accessToken == null)
            const SizedBox(
              key: Key('pet_care_people_auth_waiting'),
              height: 24,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            contactsAsync.when(
              loading: () => const SizedBox(
                key: Key('pet_care_people_loading'),
                height: 24,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline),
                  const SizedBox(height: 4),
                  Text(l.error),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(peopleContactsProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l.retry),
                  ),
                ],
              ),
              data: (contacts) {
                final pets = petsAsync.valueOrNull ?? const <Pet>[];
                final vetPetCounts = _linkedPetCountByVetId(pets);
                final pros = _topProfessionals(contacts, vetPetCounts);
                final carers = _topCarers(contacts);
                final households = householdsAsync.valueOrNull ?? const [];

                if (contacts.isEmpty && households.isEmpty) {
                  return PetCareIllustratedEmptyState(
                    key: const Key('pet_care_dashboard_empty_people'),
                    title: l.peopleEmptyCarers,
                    body: l.peopleDeskEmptyBody,
                    actionLabel: l.peopleAddPerson,
                    actionKey: const Key('pet_care_dashboard_empty_people_action'),
                    onAction: () => context.push('/pc/people/new'),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (households.isNotEmpty) ...[
                      _Subheading(text: l.peopleDeskHouseholdRail),
                      const SizedBox(height: 6),
                      _HouseholdRail(householdNames: households.map((h) => h.name).toList()),
                      const SizedBox(height: 14),
                    ],
                    _Subheading(text: l.peopleProfessionalsSection),
                    const SizedBox(height: 6),
                    if (pros.isEmpty)
                      Text(l.peopleEmptyProfessionals, style: Theme.of(context).textTheme.bodyMedium)
                    else
                      for (final contact in pros)
                        _DeskContactRow(
                          key: Key('pet_care_people_pro_${contact.id}'),
                          contact: contact,
                          subtitle: _petCountLabel(l, vetPetCounts[contact.legacyVetId ?? ''] ?? 0),
                        ),
                    const SizedBox(height: 14),
                    _Subheading(text: l.peopleTrustedCarersSection),
                    const SizedBox(height: 6),
                    if (carers.isEmpty)
                      Text(l.peopleEmptyCarers, style: Theme.of(context).textTheme.bodyMedium)
                    else
                      for (final contact in carers)
                        _DeskContactRow(
                          key: Key('pet_care_people_carer_${contact.id}'),
                          contact: contact,
                        ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  static Map<String, int> _linkedPetCountByVetId(List<Pet> pets) {
    final counts = <String, int>{};
    for (final pet in pets) {
      final vetId = pet.vetId;
      if (vetId == null || vetId.isEmpty) continue;
      counts[vetId] = (counts[vetId] ?? 0) + 1;
    }
    return counts;
  }

  static List<PeopleContact> _topProfessionals(
    List<PeopleContact> contacts,
    Map<String, int> vetPetCounts,
  ) {
    final pros = contacts.where((c) => c.isProfessional).toList();
    pros.sort((a, b) {
      final aCount = vetPetCounts[a.legacyVetId ?? ''] ?? 0;
      final bCount = vetPetCounts[b.legacyVetId ?? ''] ?? 0;
      if (aCount != bCount) return bCount.compareTo(aCount);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return pros.take(_previewLimit).toList();
  }

  static List<PeopleContact> _topCarers(List<PeopleContact> contacts) {
    final carers = contacts.where((c) => !c.isProfessional).toList();
    carers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return carers.take(_previewLimit).toList();
  }

  static String? _petCountLabel(AppLocalizations l, int count) {
    if (count <= 0) return null;
    return l.peopleDeskLinkedPets(count);
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _HouseholdRail extends StatelessWidget {
  const _HouseholdRail({required this.householdNames});

  final List<String> householdNames;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: householdNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = householdNames[index];
          final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
          return ActionChip(
            key: Key('pet_care_people_household_$index'),
            avatar: CircleAvatar(child: Text(initial)),
            label: Text(name),
            onPressed: () => context.push('/pc/pets/households'),
          );
        },
      ),
    );
  }
}

class _DeskContactRow extends StatelessWidget {
  const _DeskContactRow({
    super.key,
    required this.contact,
    this.subtitle,
  });

  final PeopleContact contact;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(
          contact.name.isNotEmpty ? contact.name.trim()[0].toUpperCase() : '?',
        ),
      ),
      title: Text(contact.name),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: () => context.go('/pc/people'),
    );
  }
}
