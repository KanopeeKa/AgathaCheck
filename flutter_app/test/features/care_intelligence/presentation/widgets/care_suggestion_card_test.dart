import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

CareRecommendation get _recommendation =>
    _recommendationWith(frequency: 'monthly');

CareRecommendation _recommendationWith({
  required String frequency,
  int interval = 1,
}) => CareRecommendation(
  id: 'rec-1',
  petId: 'pet-1',
  careFamily: CareFamily.weightMonitoring,
  suggestionKey: 'weight_monitoring_rhythm',
  status: CareRecommendationStatus.pending,
  engineVersion: '1.0.0',
  knowledgeVersion: '1.0.0',
  suggestedName: 'Weight check',
  suggestedFrequency: frequency,
  suggestedFrequencyInterval: interval,
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
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: child,
              bottomNavigationBar: const SizedBox.shrink(),
            ),
          ),
          GoRoute(
            path: '/pet/:petId/care/add',
            builder: (context, state) => Scaffold(
              body: Text(
                'review-form:${state.uri.queryParameters['careRecommendationId']}',
              ),
            ),
          ),
        ],
      ),
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
  testWidgets('add routine opens the review form with recommendation id', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: _FakeCareIntelligenceRepository(),
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('care_suggestion_accept_rec-1')));
    await tester.pumpAndSettle();

    expect(find.text('review-form:rec-1'), findsOneWidget);
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

  testWidgets('later shows error snackbar when respond fails', (tester) async {
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

    await tester.tap(find.byKey(const Key('care_suggestion_later_rec-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not update this suggestion. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'exposes a named group with the suggestion title and reachable action buttons',
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

      final groupSemantics = tester.getSemantics(
        find.byKey(const ValueKey('care_suggestion_group')),
      );
      expect(
        groupSemantics.getSemanticsData().label,
        contains('Agatha recommends'),
      );
      expect(
        groupSemantics.getSemanticsData().label,
        contains('Monthly weight check'),
      );

      final acceptSemantics = tester.getSemantics(
        find.byKey(const Key('care_suggestion_accept_rec-1')),
      );
      expect(acceptSemantics.getSemanticsData().label, 'Add routine');
      expect(
        acceptSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      expect(
        tester.getSemantics(find.text('Later')).getSemanticsData().label,
        'Later',
      );
      expect(
        tester.getSemantics(find.text('No thanks')).getSemanticsData().label,
        'No thanks',
      );
    },
  );

  testWidgets('shows an identity row when the host supplies an avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: _FakeCareIntelligenceRepository(),
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
          petName: 'Luna',
          petAvatar: SizedBox(key: Key('pet_avatar'), width: 32, height: 32),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luna'), findsOneWidget);
    expect(find.byKey(const Key('pet_avatar')), findsOneWidget);
  });

  testWidgets('omits the identity row without an avatar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: _FakeCareIntelligenceRepository(),
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
          petName: 'Luna',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luna'), findsNothing);
  });

  testWidgets('cadence line is localized and pluralized', (tester) async {
    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: _FakeCareIntelligenceRepository(),
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendationWith(frequency: 'weekly', interval: 3),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Every 3 weeks'), findsOneWidget);
  });

  testWidgets('cadence line is omitted for an unknown frequency', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: _FakeCareIntelligenceRepository(),
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendationWith(frequency: 'fortnightly'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('fortnightly'), findsNothing);
    expect(find.text('Monthly weight check'), findsOneWidget);
  });

  testWidgets('why sheet names the pet, routine, and cadence', (tester) async {
    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: _FakeCareIntelligenceRepository(),
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
          petName: 'Luna',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Why this matters'));
    await tester.pumpAndSettle();

    final sheet = find.ancestor(
      of: find.text('Why Agatha suggests this'),
      matching: find.byType(BottomSheet),
    );
    expect(
      find.descendant(of: sheet, matching: find.text('For Luna')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.text('Monthly weight check · Every month'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.textContaining(
          'Monthly weigh-ins build a simple record',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'rebuilds accept when pet policy resolves after restricted load',
    (tester) async {
      final policyResolved = StateProvider<bool>((ref) => false);
      final container = ProviderContainer(
        overrides: [
          careIntelligenceRepositoryProvider.overrideWithValue(
            _FakeCareIntelligenceRepository(),
          ),
          petDetailViewerContextProvider('pet-1').overrideWith((ref) {
            final resolved = ref.watch(policyResolved);
            return resolved
                ? _viewerContext(canEditHealth: true)
                : PetDetailContext.restricted(
                    experience: AppExperience.petCare,
                  );
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CareSuggestionCard(
                petId: 'pet-1',
                recommendation: _recommendation,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      var accept = tester.widget<FilledButton>(
        find.byKey(const Key('care_suggestion_accept_rec-1')),
      );
      expect(accept.onPressed, isNull);

      container.read(policyResolved.notifier).state = true;
      await tester.pumpAndSettle();

      accept = tester.widget<FilledButton>(
        find.byKey(const Key('care_suggestion_accept_rec-1')),
      );
      expect(accept.onPressed, isNotNull);

      container.dispose();
    },
  );

  testWidgets('why sheet omits the pet line when the pet is unknown', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        viewerContext: _viewerContext(canEditHealth: true),
        repository: _FakeCareIntelligenceRepository(),
        child: CareSuggestionCard(
          petId: 'pet-1',
          recommendation: _recommendation,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Why this matters'));
    await tester.pumpAndSettle();

    expect(find.textContaining('For '), findsNothing);
    expect(find.text('Monthly weight check · Every month'), findsOneWidget);
  });
}
