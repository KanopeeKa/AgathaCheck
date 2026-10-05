import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/contact_summary.dart';
import '../../domain/entities/household.dart';
import '../../domain/entities/roster.dart';
import '../../domain/services/desk_ranking.dart';
import '../labels/people_labels.dart';
import '../widgets/person_card.dart';

/// Today dashboard People module — vet team, trusted carers, household rail.
class PeopleDeskModule extends ConsumerWidget {
  const PeopleDeskModule({super.key});

  static const _previewLimit = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final rosterAsync = ref.watch(rosterProvider);

    return Semantics(
      container: true,
      label: l.peoplePageTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DeskSectionChrome(
            title: l.peoplePageTitle.toUpperCase(),
            linkLabel: l.peopleDeskSeeAll,
            linkKey: const Key('pet_care_dashboard_all_people'),
            onLinkPressed: () => context.go('/pc/people'),
          ),
          const SizedBox(height: 10),
          rosterAsync.when(
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
                  onPressed: () => ref.read(rosterProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l.retry),
                ),
              ],
            ),
            data: (roster) => _DeskBody(roster: roster),
          ),
        ],
      ),
    );
  }
}

class _DeskBody extends StatelessWidget {
  const _DeskBody({required this.roster});

  final Roster roster;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ctx = _deskContextFromRoster(roster);
    final vetTeam = rankVetTeamContacts(
      roster.contacts,
      ctx,
      limit: PeopleDeskModule._previewLimit,
    );
    final carers = rankTrustedCarerContacts(
      roster.contacts,
      limit: PeopleDeskModule._previewLimit,
    );

    if (roster.contacts.isEmpty && roster.households.isEmpty) {
      return _DeskEmpty(onAdd: () => context.push('/pc/people/new'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (roster.households.isNotEmpty) ...[
          _Subheading(text: l.peopleDeskHouseholdRail),
          const SizedBox(height: 6),
          _HouseholdRail(households: roster.households),
          const SizedBox(height: 14),
        ],
        _Subheading(text: l.peopleDeskVetTeam),
        const SizedBox(height: 6),
        if (vetTeam.isEmpty)
          Text(
            l.peopleEmptyProfessionals,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final contact in vetTeam)
            _DeskPersonCard(
              key: Key('pet_care_people_pro_${contact.id}'),
              contact: contact,
              linkedPetCount: ctx.linkedPetCountByContactId[contact.id],
            ),
        const SizedBox(height: 14),
        _Subheading(text: l.peopleTrustedCarersSection),
        const SizedBox(height: 6),
        if (carers.isEmpty)
          Text(
            l.peopleEmptyCarers,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final contact in carers)
            _DeskPersonCard(
              key: Key('pet_care_people_carer_${contact.id}'),
              contact: contact,
            ),
      ],
    );
  }
}

DeskRankingContext _deskContextFromRoster(Roster roster) {
  final byLegacy = <String, int>{};
  final byContact = <String, int>{};
  final primaryVets = <String>{};
  for (final contact in roster.contacts) {
    if (contact.pets.isNotEmpty) {
      byContact[contact.id] = contact.pets.length;
    }
    final vetRecordId = contact.linkedVetRecordId;
    if (vetRecordId != null && vetRecordId.isNotEmpty) {
      byLegacy[vetRecordId] = (byLegacy[vetRecordId] ?? 0) + contact.pets.length;
    }
    if (contact.pets.any((p) => p.isPrimary)) {
      primaryVets.add(contact.id);
    }
  }
  return DeskRankingContext(
    linkedPetCountByVetRecordId: byLegacy,
    linkedPetCountByContactId: byContact,
    primaryVetContactIds: primaryVets,
  );
}

class _DeskSectionChrome extends StatelessWidget {
  const _DeskSectionChrome({
    required this.title,
    required this.linkLabel,
    required this.linkKey,
    required this.onLinkPressed,
  });

  final String title;
  final String linkLabel;
  final Key linkKey;
  final VoidCallback onLinkPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColorTokens.petCareActive,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextButton(
          key: linkKey,
          onPressed: onLinkPressed,
          child: Text(linkLabel),
        ),
      ],
    );
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
  const _HouseholdRail({required this.households});

  final List<Household> households;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: households.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final household = households[index];
          final name = household.name;
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

class _DeskPersonCard extends StatelessWidget {
  const _DeskPersonCard({
    super.key,
    required this.contact,
    this.linkedPetCount,
  });

  final ContactSummary contact;
  final int? linkedPetCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rolesLine = contact.roles.isEmpty
        ? contact.kind.label(l)
        : contactRolesLine(l, contact.roles);
    final petsLine = linkedPetCount != null && linkedPetCount! > 0
        ? l.peopleDeskLinkedPets(linkedPetCount!)
        : null;
    return PersonCard(
      contact: contact,
      compact: true,
      roleLine: rolesLine,
      petsLine: petsLine,
      showChevron: false,
      onTap: () => context.go('/pc/people/${contact.id}'),
    );
  }
}

class _DeskEmpty extends StatelessWidget {
  const _DeskEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      key: const Key('pet_care_dashboard_empty_people'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.peopleEmptyCarers,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(l.peopleDeskEmptyBody),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('pet_care_dashboard_empty_people_action'),
          onPressed: onAdd,
          child: Text(l.peopleAddPerson),
        ),
      ],
    );
  }
}
