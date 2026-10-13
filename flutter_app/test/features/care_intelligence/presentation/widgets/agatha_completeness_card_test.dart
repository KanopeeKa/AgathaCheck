import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/widgets/agatha_recommendation_eyebrow.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/providers/care_recommendations_provider.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/providers/pet_profile_care_milestone_provider.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/widgets/pet_detail/pet_profile_completeness_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_viewer_role.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/profile_fact_status.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/pet_detail_actions.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

PetDetailContext _contextWithEdit({required bool canEdit}) {
  final actions = <PetDetailAction>{PetDetailAction.downloadReport};
  if (canEdit) actions.add(PetDetailAction.editProfile);
  return PetDetailContext(
    experience: AppExperience.petCare,
    role: canEdit ? PetViewerRole.guardian : PetViewerRole.sharedCarer,
    actions: actions,
    isPolicyResolved: true,
  );
}

ProviderScope _scope({
  required Widget child,
  CareRecommendation? suggestion,
  required ProfileCompletenessDismissalStore dismissalStore,
}) {
  return ProviderScope(
    overrides: [
      profileCompletenessDismissalStoreProvider.overrideWith(
        (ref) => Future.value(dismissalStore),
      ),
      petProfileCareSafeguardProvider(
        'pet-1',
      ).overrideWith((ref) => const AsyncData(null)),
      petProfileCareSuggestionProvider(
        'pet-1',
      ).overrideWith((ref) => AsyncData(suggestion)),
      petProfileCareMilestoneProvider(
        'pet-1',
      ).overrideWith((ref) => const AsyncData(null)),
      petWelfareSuggestionsProvider(
        'pet-1',
      ).overrideWith((ref) async => []),
    ],
    child: child,
  );
}

void main() {
  late ProfileCompletenessDismissalStore dismissalStore;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dismissalStore = ProfileCompletenessDismissalStore(
      await SharedPreferences.getInstance(),
    );
  });

  testWidgets(
    'AC-AC-01 ACJ-AC-01: chip card hidden when identification known',
    (tester) async {
      const pet = Pet(
        id: 'pet-1',
        name: 'Bella',
        species: 'Dog',
        identificationStatus: profileFactStatusYes,
        chipId: '985112004123456',
        neuterStatus: profileFactStatusUnknown,
      );

      await tester.pumpWidget(
        _scope(
          suggestion: null,
          dismissalStore: dismissalStore,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: PetProfileCompletenessSection(
                pet: pet,
                viewerContext: _contextWithEdit(canEdit: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('profile_completeness_card_chip')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('profile_completeness_card_neuter')),
        findsNothing,
      );
    },
  );

  testWidgets('AC-AC-02: Agatha chrome on completeness card', (tester) async {
    const pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      identificationStatus: profileFactStatusUnknown,
      neuterStatus: profileFactStatusUnknown,
    );

    await tester.pumpWidget(
      _scope(
        suggestion: null,
        dismissalStore: dismissalStore,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetProfileCompletenessSection(
              pet: pet,
              viewerContext: _contextWithEdit(canEdit: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
    expect(find.byType(AgathaRecommendationEyebrow), findsWidgets);
  });

  testWidgets('AC-AC-03: hidden when rhythm suggestion occupies slot', (
    tester,
  ) async {
    const pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      identificationStatus: profileFactStatusUnknown,
      neuterStatus: profileFactStatusUnknown,
    );

    final suggestion = CareRecommendation(
      id: 'rec-1',
      petId: 'pet-1',
      careFamily: CareFamily.wellnessReview,
      suggestionKey: 'wellness_review_rhythm',
      status: CareRecommendationStatus.pending,
      engineVersion: '1.0.0',
      knowledgeVersion: '1.0.0',
      suggestedName: 'Wellness review',
      suggestedFrequency: 'yearly',
      suggestedFrequencyInterval: 1,
      rationaleKey: 'careSuggestionWellnessWhy',
    );

    await tester.pumpWidget(
      _scope(
        suggestion: suggestion,
        dismissalStore: dismissalStore,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetProfileCompletenessSection(
              pet: pet,
              viewerContext: _contextWithEdit(canEdit: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('profile_completeness_card_chip')),
      findsNothing,
    );
  });

  testWidgets('AC-IC-02: view-only disables Record primary', (tester) async {
    const pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      isShared: true,
      petParentName: 'Alex',
      neuterStatus: profileFactStatusUnknown,
      identificationStatus: profileFactStatusUnknown,
    );

    await tester.pumpWidget(
      _scope(
        suggestion: null,
        dismissalStore: dismissalStore,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetProfileCompletenessSection(
              pet: pet,
              viewerContext: _contextWithEdit(canEdit: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final recordButtons = tester.widgetList<FilledButton>(
      find.byType(FilledButton),
    );
    expect(recordButtons.every((b) => b.onPressed == null), isTrue);
  });
}
