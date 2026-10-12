import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_viewer_role.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/profile_fact_status.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/pet_detail_actions.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/widgets/pet_detail/pet_profile_completeness_prompt.dart';
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

void main() {
  testWidgets('collapses neuter and chip prompts into one card', (
    tester,
  ) async {
    const pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      neuterStatus: profileFactStatusUnknown,
      identificationStatus: profileFactStatusUnknown,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetProfileCompletenessPrompt(
              pet: pet,
              viewerContext: _contextWithEdit(canEdit: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pet_profile_completeness_prompt')),
      findsOneWidget,
    );
    expect(find.text('Neutering status not recorded'), findsOneWidget);
    expect(find.text('Microchip details not added'), findsOneWidget);
    expect(find.text('Record'), findsNWidgets(2));
  });

  testWidgets('hides when both prompts are dismissed or filled', (
    tester,
  ) async {
    final pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      chipId: 'FR-123',
      identificationStatus: profileFactStatusYes,
      neuterStatus: profileFactStatusYes,
      neuteredDate: DateTime(2024, 1, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetProfileCompletenessPrompt(
              pet: pet,
              viewerContext: _contextWithEdit(canEdit: true),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pet_profile_completeness_prompt')),
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
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetProfileCompletenessPrompt(
              pet: pet,
              viewerContext: _contextWithEdit(canEdit: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final recordButtons = tester.widgetList<TextButton>(
      find.byKey(const Key('profile_fact_capture_record')),
    );
    expect(recordButtons.every((b) => b.onPressed == null), isTrue);
  });
}
