import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/pet_care_dashboard_section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/auth.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/pet_people.dart';
import '../../domain/services/group_pet_people.dart';
import '../add/add_person_route_args.dart';
import 'pet_emergency_manage_sheet.dart';
import 'pet_people_section_rows.dart';
import 'widgets/people_group_box.dart';

/// "People around {pet}" on the pet profile — one grouped module (D-040).
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
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            kPetDetailSectionInsetTop,
            16,
            0,
          ),
          child: PetCareDashboardSectionChrome(
            title: l.peopleAroundPetTitle(petName),
            linkLabel: canManage && async.valueOrNull?.scope == 'full'
                ? l.peoplePetEmergencyManage
                : null,
            linkKey: const Key('pet_emergency_manage_button'),
            onLinkPressed:
                canManage &&
                    async.valueOrNull?.scope == 'full' &&
                    async.valueOrNull != null
                ? () => showPetEmergencyManageSheet(
                    context: context,
                    ref: ref,
                    people: async.valueOrNull!,
                  )
                : null,
          ),
        ),
        const SizedBox(height: kPetDetailSectionTitleGap),
        async.when(
          loading: () => const _PetPeopleBoxState(child: _LoadingBody()),
          error: (_, __) =>
              _PetPeopleBoxState(child: Text(l.peopleListLoadError)),
          data: (people) {
            if (people == null) return const SizedBox.shrink();
            return _PetPeopleData(
              people: people,
              canManage: canManage && people.scope == 'full',
              petId: petId,
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PetPeopleBoxState extends StatelessWidget {
  const _PetPeopleBoxState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PeopleGroupBox(sections: const [], footer: child);
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PetPeopleData extends ConsumerWidget {
  const _PetPeopleData({
    required this.people,
    required this.canManage,
    required this.petId,
  });

  final PetPeople people;
  final bool canManage;
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewerUserId = ref.watch(authProvider.select((s) => s.user?.id));
    final l = AppLocalizations.of(context)!;
    final grouped = groupPetPeople(people);
    final useRoster = people.scope == 'full';
    final rosterAsync = useRoster ? ref.watch(rosterProvider) : null;
    final roster = rosterAsync?.valueOrNull;
    final rosterReady = !useRoster || rosterAsync?.hasValue == true;

    final sections = buildPetPeopleGroupSections(
      context: context,
      l: l,
      people: people,
      grouped: grouped,
      rosterReady: rosterReady,
      roster: roster,
      viewerUserId: viewerUserId,
    );

    final footer = canManage && people.scope == 'full'
        ? Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('pet_people_add_someone'),
              onPressed: () => context.push(
                '/pc/people/new',
                extra: AddPersonRouteArgs(initialPetIds: [petId]),
              ),
              child: Text(l.peopleAddSomeonePet),
            ),
          )
        : null;

    return PeopleGroupBox(sections: sections, footer: footer);
  }
}
