import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_importance.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_setting.dart';
import 'package:pet_profile_app/features/care_taxonomy/presentation/widgets/care_classification_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  testWidgets('shows family, setting, and priority controls on add', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        CareClassificationSection(
          isEdit: false,
          careFamily: null,
          careSetting: CareSetting.home,
          careImportance: CareImportance.essential,
          careFamilyRequiredError: null,
          showCareFamilySuggestion: false,
          showCareFamilyPicker: true,
          suggestedCareFamily: CareFamily.medication,
          onCareFamilyChanged: (_) {},
          onCareSettingChanged: (_) {},
          onCareImportanceChanged: (_) {},
          onAcceptSuggestion: () {},
          onChooseDifferentSuggestion: () {},
          onDismissSuggestion: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_family_picker')), findsOneWidget);
    expect(find.byKey(const Key('care_setting_picker')), findsOneWidget);
    expect(find.byKey(const Key('care_importance_essential')), findsOneWidget);
    expect(find.text('Where'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
  });

  testWidgets('family change applies taxonomy defaults via callbacks', (
    WidgetTester tester,
  ) async {
    CareSetting? capturedSetting;
    CareImportance? capturedImportance;

    await tester.pumpWidget(
      wrap(
        CareClassificationSection(
          isEdit: false,
          careFamily: CareFamily.vaccination,
          careSetting: CareSetting.vet,
          careImportance: CareImportance.essential,
          careFamilyRequiredError: null,
          showCareFamilySuggestion: false,
          showCareFamilyPicker: true,
          suggestedCareFamily: CareFamily.medication,
          onCareFamilyChanged: (_) {},
          onCareSettingChanged: (setting) => capturedSetting = setting,
          onCareImportanceChanged: (importance) =>
              capturedImportance = importance,
          onAcceptSuggestion: () {},
          onChooseDifferentSuggestion: () {},
          onDismissSuggestion: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('care_setting_picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('At home').last);
    await tester.pumpAndSettle();
    expect(capturedSetting, CareSetting.home);

    await tester.tap(find.byKey(const Key('care_importance_recommended')));
    await tester.pumpAndSettle();
    expect(capturedImportance, CareImportance.recommended);
  });

  testWidgets('edit uncategorised entry shows suggestion banner only', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        CareClassificationSection(
          isEdit: true,
          careFamily: null,
          careSetting: CareSetting.other,
          careImportance: CareImportance.optional,
          careFamilyRequiredError: null,
          showCareFamilySuggestion: true,
          showCareFamilyPicker: false,
          suggestedCareFamily: CareFamily.parasitePrevention,
          onCareFamilyChanged: (_) {},
          onCareSettingChanged: (_) {},
          onCareImportanceChanged: (_) {},
          onAcceptSuggestion: () {},
          onChooseDifferentSuggestion: () {},
          onDismissSuggestion: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('care_family_suggestion_banner')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('care_setting_picker')), findsNothing);
  });
}
