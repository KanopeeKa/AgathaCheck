import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/organization_pets_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

const _orgPet = Pet(
  id: 'org-pet-1',
  name: 'Max',
  species: 'Dog',
  breed: 'Labrador',
  organizationId: 'org-1',
  organizationName: 'Happy Paws Shelter',
);

class _Host extends ConsumerWidget {
  const _Host({required this.orgGroups});

  final Map<String, List<Pet>> orgGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrganizationPetsSection(
      orgGroups: orgGroups,
      l: AppLocalizations.of(context)!,
      theme: Theme.of(context),
      ref: ref,
      parentContext: context,
    );
  }
}

void main() {
  testWidgets('tapping org pet card navigates to pet detail', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: _Host(orgGroups: {'Happy Paws Shelter': [_orgPet]}),
          ),
        ),
        GoRoute(
          path: '/pet/:petId',
          builder: (context, state) => Scaffold(
            body: Text('Pet ${state.pathParameters['petId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Max'));
    await tester.pumpAndSettle();

    expect(find.text('Pet org-pet-1'), findsOneWidget);
  });
}
