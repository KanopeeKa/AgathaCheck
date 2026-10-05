import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/people/application/people_providers.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/household_invite.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/presentation/routes/people_routes.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class TestRosterNotifier extends RosterNotifier {
  TestRosterNotifier(this.roster);

  final Roster roster;

  @override
  Future<Roster> build() async => roster;
}

Roster sampleHubRoster() {
  return Roster(
    households: const [],
    contacts: [
      ContactSummary(
        id: 'carer-1',
        directory: const ContactDirectoryRef(type: 'personal'),
        kind: ContactKind.person,
        name: 'Jamie Taylor',
        roles: const [ContactRole.sitter],
        group: ContactGroup.carer,
        status: ContactStatus.active,
        pets: const [
          ContactPetLink(
            petId: 'pet-1',
            petName: 'Buddy',
            relationshipKind: RelationshipKind.careProvider,
          ),
        ],
      ),
      ContactSummary(
        id: 'vet-1',
        directory: const ContactDirectoryRef(type: 'personal'),
        kind: ContactKind.organisation,
        name: 'Greenhill Vet',
        roles: const [ContactRole.vet],
        group: ContactGroup.professional,
        status: ContactStatus.active,
      ),
    ],
    pendingInvites: const [
      HouseholdInvite(
        id: 'inv-1',
        source: 'share',
        email: 'pat@example.com',
        petIds: ['pet-1'],
      ),
    ],
  );
}

Widget peopleHubTestApp({
  required GoRouter router,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

GoRouter buildTestPeopleRouter({String initialLocation = '/pc/people'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [buildPeopleHubShellRoute()],
  );
}
