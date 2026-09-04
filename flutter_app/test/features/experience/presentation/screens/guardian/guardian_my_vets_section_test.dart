import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_my_vets_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/features/vet/presentation/widgets/care_team_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

void main() {
  const vets = [
    Vet(
      id: 'vet-1',
      name: 'Clinique du Parc',
      address: '10 rue du Parc, Paris',
    ),
    Vet(id: 'vet-2', name: 'Dr. Avery', address: 'Lyon'),
  ];

  Widget buildSection({
    AuthState? authState,
    required VetListNotifier vetNotifier,
    PetListNotifier? petNotifier,
    bool useWideDeskLayout = false,
  }) {
    final resolvedAuthState = authState ?? loggedInAuthState;
    final router = GoRouter(
      initialLocation: '/pc/home',
      routes: [
        GoRoute(
          path: '/pc/home',
          builder: (_, __) => Scaffold(
            body: GuardianMyVetsSection(useWideDeskLayout: useWideDeskLayout),
          ),
        ),
        GoRoute(
          path: '/pc/vets/add',
          builder: (_, __) => const Scaffold(body: Text('add-vet-route')),
        ),
        GoRoute(
          path: '/pc/vets',
          builder: (_, __) => const Scaffold(body: Text('manage-vets-route')),
        ),
        GoRoute(
          path: '/pc/vets/:id',
          builder: (_, state) =>
              Scaffold(body: Text('vet-detail-${state.pathParameters['id']}')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => _TestAuthNotifier(resolvedAuthState),
        ),
        vetListProvider.overrideWith(() => vetNotifier),
        petListProvider.overrideWith(
          () => petNotifier ?? _FixedPetNotifier(const []),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('shows puppy watermark only on wide desk layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSection(
        vetNotifier: _FixedVetNotifier(vets),
        useWideDeskLayout: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('guardian_dashboard_care_team_puppy_deco')),
      findsOneWidget,
    );
  });

  testWidgets('hides puppy watermark on narrow desk layout', (tester) async {
    await tester.pumpWidget(
      buildSection(
        vetNotifier: _FixedVetNotifier(vets),
        useWideDeskLayout: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('guardian_dashboard_care_team_puppy_deco')),
      findsNothing,
    );
  });

  testWidgets('shows the care team eyebrow label', (tester) async {
    await tester.pumpWidget(buildSection(vetNotifier: _FixedVetNotifier(vets)));
    await tester.pumpAndSettle();

    expect(find.text('CARE TEAM'), findsOneWidget);
  });

  testWidgets('waits for authentication without showing a false empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSection(
        authState: const AuthState(isLoading: true),
        vetNotifier: _FixedVetNotifier(vets),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('guardian_vets_auth_waiting')), findsOneWidget);
    expect(find.text('Keep your vet close at hand'), findsNothing);
  });

  testWidgets('shows provider loading independently after authentication', (
    tester,
  ) async {
    await tester.pumpWidget(buildSection(vetNotifier: _LoadingVetNotifier()));
    await tester.pump();

    expect(find.byKey(const Key('guardian_vets_loading')), findsOneWidget);
    expect(find.byKey(const Key('guardian_vets_auth_waiting')), findsNothing);
  });

  testWidgets('shows an actionable retry when the vet provider fails', (
    tester,
  ) async {
    final notifier = _RetryingVetNotifier();
    await tester.pumpWidget(buildSection(vetNotifier: notifier));
    await tester.pumpAndSettle();

    expect(find.text('Error'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Retry'));
    expect(notifier.refreshCalls, 1);
  });

  testWidgets('shows an illustrated empty state with an add-vet action', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSection(vetNotifier: _FixedVetNotifier(const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Keep your vet close at hand'), findsOneWidget);
    expect(
      find.byKey(const Key('guardian_dashboard_empty_vets')),
      findsOneWidget,
    );
  });

  testWidgets('shows caring copy and navigates to vet details', (tester) async {
    await tester.pumpWidget(
      buildSection(
        vetNotifier: _FixedVetNotifier(vets),
        petNotifier: _FixedPetNotifier(const [
          Pet(id: 'pet-1', name: 'Milo', species: 'Dog', vetId: 'vet-1'),
          Pet(id: 'pet-2', name: 'Nova', species: 'Cat', vetId: 'vet-1'),
          Pet(id: 'pet-3', name: 'Pip', species: 'Dog', vetId: 'vet-2'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Veterinary clinic · Paris'), findsOneWidget);
    expect(find.text('Caring for 2 pets'), findsOneWidget);
    expect(find.text('Caring for 1 pet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('care_team_card_vet-1')));
    await tester.pumpAndSettle();
    expect(find.text('vet-detail-vet-1'), findsOneWidget);
  });

  testWidgets('does not present missing pet data as a zero linked-pet count', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSection(
        vetNotifier: _FixedVetNotifier(vets),
        petNotifier: _LoadingPetNotifier(),
      ),
    );
    await tester.pump();

    expect(find.text('Clinique du Parc'), findsOneWidget);
    expect(find.text('Veterinary clinic · Paris'), findsOneWidget);
    expect(find.textContaining('Caring for'), findsNothing);
  });

  testWidgets('keeps the uncapped care team list reachable at phone widths', (
    tester,
  ) async {
    const widths = [320.0, 375.0, 414.0];
    final manyVets = List.generate(
      8,
      (index) => Vet(
        id: 'vet-$index',
        name: 'Veterinary practice $index',
        address: 'Address $index, Paris',
      ),
    );

    for (final width in widths) {
      await tester.binding.setSurfaceSize(Size(width, 2400));
      await tester.pumpWidget(
        buildSection(vetNotifier: _FixedVetNotifier(manyVets)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CareTeamCard), findsNWidgets(manyVets.length));
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('keeps add reachable from the empty-state action', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSection(vetNotifier: _FixedVetNotifier(const [])),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('guardian_dashboard_empty_vets_action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('add-vet-route'), findsOneWidget);
  });

  testWidgets('keeps the full care team list reachable without a top plus', (
    tester,
  ) async {
    await tester.pumpWidget(buildSection(vetNotifier: _FixedVetNotifier(vets)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('All care teams'));
    await tester.pumpAndSettle();

    expect(find.text('manage-vets-route'), findsOneWidget);
  });
}

class _TestAuthNotifier extends FakeAuthNotifier {
  _TestAuthNotifier(AuthState authState) {
    state = authState;
  }
}

class _FixedVetNotifier extends VetListNotifier {
  _FixedVetNotifier(this._vets);

  final List<Vet> _vets;

  @override
  Future<List<Vet>> build() async => _vets;
}

class _LoadingVetNotifier extends VetListNotifier {
  final _completer = Completer<List<Vet>>();

  @override
  Future<List<Vet>> build() => _completer.future;
}

class _RetryingVetNotifier extends VetListNotifier {
  int refreshCalls = 0;

  @override
  Future<List<Vet>> build() async => throw StateError('Network unavailable');

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

class _FixedPetNotifier extends PetListNotifier {
  _FixedPetNotifier(this._pets);

  final List<Pet> _pets;

  @override
  Future<List<Pet>> build() async => _pets;
}

class _LoadingPetNotifier extends PetListNotifier {
  final _completer = Completer<List<Pet>>();

  @override
  Future<List<Pet>> build() => _completer.future;
}
