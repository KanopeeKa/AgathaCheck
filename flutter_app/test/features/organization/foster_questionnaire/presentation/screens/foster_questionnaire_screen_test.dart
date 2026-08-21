import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/presentation/providers/foster_questionnaire_providers.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/presentation/providers/foster_questionnaire_review_providers.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/presentation/screens/foster_questionnaire_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../../helpers/fakes.dart';
import '../../helpers/fake_foster_questionnaire_repository.dart';

void main() {
  testWidgets('questionnaire screen loads profile section with semantics ids', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          fosterQuestionnaireRepositoryProvider.overrideWithValue(
            FakeFosterQuestionnaireRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FosterQuestionnaireScreen(orgId: 'org-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('foster_questionnaire_screen'), findsOneWidget);
    expect(find.text('Foster candidate questionnaire'), findsOneWidget);
    expect(find.text('Matching profile'), findsOneWidget);
    expect(find.bySemanticsIdentifier('foster_questionnaire_PF01_CAT'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('foster_questionnaire_next')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('foster_questionnaire_next')), findsOneWidget);
  });

  testWidgets('success panel shown after AUTO_GO submission', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          fosterQuestionnaireRepositoryProvider.overrideWithValue(
            FakeFosterQuestionnaireRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FosterQuestionnaireScreen(orgId: 'org-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final notifier = tester
        .element(find.byType(FosterQuestionnaireScreen))
        .read(fosterQuestionnaireFormProvider((orgId: 'org-1')).notifier);
    final controller = notifier.controller;
    controller.toggleProfileOption('PF01', 'CAT');
    controller.toggleProfileOption('PF02', 'ADULT');
    controller.toggleProfileOption('PF03', 'NEW');
    controller.toggleProfileOption('PF04', 'ANIMAL_HEALTH_EASY');
    controller.setCapacity('CAT', '1');
    controller.setAvailabilityStart('2026-09-01');
    controller.setAvailabilityEnd('2026-12-31');
    for (final questionId in ['Q01', 'Q02', 'Q03', 'Q04', 'Q05', 'Q06', 'Q07', 'Q08']) {
      controller.selectScreeningOption(questionId, '${questionId}_A');
    }
    controller.setCandidateAcknowledged(true);
    final l = AppLocalizations.of(
      tester.element(find.byType(FosterQuestionnaireScreen)),
    )!;
    await controller.submit(l);
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('foster_questionnaire_success_panel'), findsOneWidget);
    expect(find.text('Questionnaire submitted'), findsOneWidget);
    expect(
      find.textContaining('no immediate concern was identified'),
      findsOneWidget,
    );
  });
}

extension on Element {
  T read<T>(ProviderListenable<T> provider) {
    return ProviderScope.containerOf(this, listen: false).read(provider);
  }
}
