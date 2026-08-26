import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_fostering_screen.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_shell_scaffold.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_fostering_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';

class _LoadingPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async {
    final completer = Completer<List<Pet>>();
    ref.onDispose(() {
      if (!completer.isCompleted) {
        completer.complete(const []);
      }
    });
    return completer.future;
  }
}

class _ErrorPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => throw StateError('pets unavailable');
}

const _fosterPet = Pet(
  id: 'foster-1',
  name: 'Miso',
  species: 'Cat',
  isFoster: true,
  organizationName: 'Harbour Shelter',
  fosterPlacementStatus: 'active',
);

Widget _buildScreen({
  required PetListNotifier Function() petListFactory,
}) {
  final router = GoRouter(
    initialLocation: '/g/fostering',
    routes: [
      GoRoute(
        path: '/g/fostering',
        builder: (context, state) => const GuardianFosteringScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      petListProvider.overrideWith(petListFactory),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows loading indicator while pets load', (tester) async {
    await tester.pumpWidget(
      _buildScreen(petListFactory: _LoadingPetListNotifier.new),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(GuardianFosteringSection), findsNothing);
  });

  testWidgets('shows localized error when pet list fails', (tester) async {
    await tester.pumpWidget(
      _buildScreen(petListFactory: _ErrorPetListNotifier.new),
    );
    await tester.pumpAndSettle();

    expect(find.text('Error'), findsOneWidget);
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.byType(GuardianFosteringSection), findsNothing);
  });

  testWidgets('renders fostering section with loaded pets', (tester) async {
    await tester.pumpWidget(
      _buildScreen(
        petListFactory: () => TestPetListNotifier(const [_fosterPet]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GuardianFosteringSection), findsOneWidget);
    expect(find.text('Miso'), findsOneWidget);
    expect(find.text('Harbour Shelter'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('uses shell scaffold with fostering title', (tester) async {
    await tester.pumpWidget(
      _buildScreen(
        petListFactory: () => TestPetListNotifier(const [_fosterPet]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExperienceShellScaffold), findsOneWidget);
    expect(find.text('Fostering Sessions'), findsWidgets);
  });
}
