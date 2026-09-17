import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/data/care_intelligence_exception.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_recommendation.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/entities/care_safeguard.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/repositories/care_intelligence_repository.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/providers/care_recommendations_provider.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/widgets/care_suggestion_card.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_viewer_role.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/pet_detail_actions.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_detail_viewer_context_provider.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeCareIntelligenceRepository implements CareIntelligenceRepository {
  _FakeCareIntelligenceRepository({this.onRespond});

  final Future<CareRecommendation> Function({
    required String petId,
    required String recommendationId,
    required CareRecommendationResponseAction action,
  })?
  onRespond;

  @override
  Future<List<CareRecommendation>> getRecommendations(String petId) async => [];

  @override
  Future<List<CareSafeguard>> getSafeguards(String petId) async => [];

  @override
  Future<CareSafeguard> dismissSafeguard({
    required String petId,
    required String safeguardId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<CareRecommendation> respond({
    required String petId,
    required String recommendationId,
    required CareRecommendationResponseAction action,
    Map<String, dynamic>? adjust,
  }) {
    if (onRespond == null) {
      return Future.value(_recommendation);
    }
    return onRespond!(
      petId: petId,
      recommendationId: recommendationId,
      action: action,
    );
  }
}

CareRecommendation get _recommendation => CareRecommendation(
  id: 'rec-1',
  petId: 'pet-1',
  careFamily: CareFamily.weightMonitoring,
  suggestionKey: 'weight_monitoring_rhythm',
  status: CareRecommendationStatus.pending,
  engineVersion: '1.0.0',
  knowledgeVersion: '1.0.0',
  suggestedName: 'Weight check',
  suggestedFrequency: 'monthly',
  suggestedFrequencyInterval: 1,
  suggestedHealthEntryType: 'other',
  rationaleKey: 'careSuggestionWeightMonitoringWhy',
);

Widget _wrap({
  required Widget child,
  required PetDetailContext viewerContext,
  required CareIntelligenceRepository repository,
}) {
  return ProviderScope(
    overrides: [
      careIntelligenceRepositoryProvider.overrideWithValue(repository),
      petDetailViewerContextProvider('pet-1').overrideWithValue(viewerContext),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child, bottomNavigationBar: const SizedBox.shrink()),
    ),
  );
}

PetDetailContext _viewerContext({required bool canEditHealth}) {
  final actions = <PetDetailAction>{PetDetailAction.downloadReport};
  if (canEditHealth) {
    actions.addAll({
      PetDetailAction.editProfile,
      PetDetailAction.editHealth,
      PetDetailAction.assignVet,
      PetDetailAction.manageSharing,
    });
  }
  return PetDetailContext(
    experience: AppExperience.petCare,
    role: PetViewerRole.guardian,
    actions: actions,
    isPolicyResolved: true,
  );
}

void main() {
  testWidgets('accept shows success snackbar when respond succeeds', (
    tester,
  ) async {
    final repository = _FakeCareIntelligenceRepository(
      onRespond:
          ({required petId, required recommendationId, required action}) async {
            expect(action, CareRecommendationResponseAction.accept);
            return _recommendation;
          },
    );

    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: repository,
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('care_suggestion_accept_rec-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Weight check rhythm added'), findsOneWidget);
  });

  testWidgets('accept shows error snackbar when respond fails', (tester) async {
    final repository = _FakeCareIntelligenceRepository(
      onRespond:
          ({required petId, required recommendationId, required action}) async {
            throw const CareIntelligenceException(500);
          },
    );

    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: repository,
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('care_suggestion_accept_rec-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not update this suggestion. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('accept is disabled without editHealth capability', (
    tester,
  ) async {
    final repository = _FakeCareIntelligenceRepository();

    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: false),
        repository: repository,
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('care_suggestion_accept_rec-1')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('403 error shows forbidden snackbar', (tester) async {
    final repository = _FakeCareIntelligenceRepository(
      onRespond:
          ({required petId, required recommendationId, required action}) async {
            throw const CareIntelligenceException(403);
          },
    );

    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: repository,
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('care_suggestion_accept_rec-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      find.text("You can view this pet's care but cannot add rhythms."),
      findsOneWidget,
    );
  });

  testWidgets(
    'exposes a merged semantics group labelled with the suggestion title',
    (tester) async {
      final repository = _FakeCareIntelligenceRepository();

      await tester.pumpWidget(
        _wrap(
          viewerContext: _viewerContext(canEditHealth: true),
          repository: repository,
          child: CareSuggestionCard(
            petId: 'pet-1',
            recommendation: _recommendation,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(
        find
            .descendant(
              of: find.byKey(const Key('care_suggestion_card_rec-1')),
              matching: find.byType(MergeSemantics),
            )
            .first,
      );
      expect(
        semantics.label,
        'Suggested by Agatha\nWeight check\nEvery 1 monthly',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('care_suggestion_card_rec-1')),
          matching: find.byKey(const Key('care_suggestion_accept_rec-1')),
        ),
        findsOneWidget,
      );
    },
  );
}
