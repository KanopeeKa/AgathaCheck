import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/data/care_intelligence_exception.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_recommendation.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_safeguard.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/repositories/care_intelligence_repository.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/providers/care_recommendations_provider.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/widgets/care_safeguard_card.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeCareIntelligenceRepository implements CareIntelligenceRepository {
  _FakeCareIntelligenceRepository({this.onDismissSafeguard});

  final Future<CareSafeguard> Function({
    required String petId,
    required String safeguardId,
  })?
  onDismissSafeguard;

  @override
  Future<List<CareRecommendation>> getRecommendations(String petId) async => [];

  @override
  Future<List<CareSafeguard>> getSafeguards(String petId) async => [];

  @override
  Future<CareSafeguard> dismissSafeguard({
    required String petId,
    required String safeguardId,
  }) {
    if (onDismissSafeguard == null) {
      return Future.value(_safeguard);
    }
    return onDismissSafeguard!(petId: petId, safeguardId: safeguardId);
  }

  @override
  Future<CareRecommendation> respond({
    required String petId,
    required String recommendationId,
    required CareRecommendationResponseAction action,
    Map<String, dynamic>? adjust,
  }) {
    throw UnimplementedError();
  }
}

CareSafeguard get _safeguard => CareSafeguard(
  id: 'sg-1',
  petId: 'pet-1',
  safeguardType: 'weight_change',
  safeguardKey: 'unexplained_material_decline',
  status: 'active',
  policyVersion: '1.0.0',
  copyKey: 'careSafeguardWeightTrendDown',
  evidence: const {'direction': 'down', 'delta_pct': 25.0},
);

Widget _wrap({
  required Widget child,
  required CareIntelligenceRepository repository,
}) {
  return ProviderScope(
    overrides: [
      careIntelligenceRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('dismiss shows error snackbar when dismissSafeguard throws', (
    tester,
  ) async {
    final repository = _FakeCareIntelligenceRepository(
      onDismissSafeguard: ({required petId, required safeguardId}) async {
        throw const CareIntelligenceException(500);
      },
    );

    await tester.pumpWidget(
      _wrap(
        repository: repository,
        child: CareSafeguardCard(
          petId: 'pet-1',
          petName: 'Rex',
          safeguard: _safeguard,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('care_safeguard_dismiss_sg-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Could not dismiss this. Try again.'), findsOneWidget);
  });

  testWidgets('dismiss re-enables button after failure', (tester) async {
    final repository = _FakeCareIntelligenceRepository(
      onDismissSafeguard: ({required petId, required safeguardId}) async {
        throw const CareIntelligenceException(500);
      },
    );

    await tester.pumpWidget(
      _wrap(
        repository: repository,
        child: CareSafeguardCard(
          petId: 'pet-1',
          petName: 'Rex',
          safeguard: _safeguard,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final buttonBefore = tester.widget<TextButton>(
      find.byKey(const Key('care_safeguard_dismiss_sg-1')),
    );
    expect(buttonBefore.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('care_safeguard_dismiss_sg-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final buttonAfter = tester.widget<TextButton>(
      find.byKey(const Key('care_safeguard_dismiss_sg-1')),
    );
    expect(buttonAfter.onPressed, isNotNull);
  });

  testWidgets('403 error shows forbidden snackbar', (tester) async {
    final repository = _FakeCareIntelligenceRepository(
      onDismissSafeguard: ({required petId, required safeguardId}) async {
        throw const CareIntelligenceException(403);
      },
    );

    await tester.pumpWidget(
      _wrap(
        repository: repository,
        child: CareSafeguardCard(
          petId: 'pet-1',
          petName: 'Rex',
          safeguard: _safeguard,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('care_safeguard_dismiss_sg-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      find.text("You can view this pet's care but cannot add rhythms."),
      findsOneWidget,
    );
  });
}
