import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/form/app_form_info_button.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_form/pet_form_neutered_section.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_form/pet_form_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _wrapNeutered({required Locale locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: PetFormSection(
            title: 'Health',
            children: [
              PetFormNeuteredSection(
                species: 'Dog',
                isNeutered: null,
                neuteredDate: null,
                onNeuteredChanged: (_) {},
                onPickNeuteredDate: () {},
                onClearNeuteredDate: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('places info control on label row with full-width segments', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrapNeutered(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.byType(AppFormInfoButton), findsOneWidget);
    expect(find.byKey(const Key('pet_neuter_segmented')), findsOneWidget);

    final segmented = tester.widget<SegmentedButton<PetNeuterSelection>>(
      find.byKey(const Key('pet_neuter_segmented')),
    );
    expect(segmented.showSelectedIcon, isTrue);

    final segmentRect = tester.getRect(
      find.byKey(const Key('pet_neuter_segmented')),
    );
    final sectionRect = tester.getRect(find.byType(PetFormSection));
    const sectionHorizontalPadding = 32.0;
    final expectedContentWidth = sectionRect.width - sectionHorizontalPadding;

    final infoRect = tester.getRect(find.byType(AppFormInfoButton));
    expect(segmentRect.top, greaterThan(infoRect.bottom));
    expect(segmentRect.width, closeTo(expectedContentWidth, 1));
  });

  testWidgets('info is not in the same row as SegmentedButton', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_wrapNeutered(locale: const Locale('fr')));
    await tester.pumpAndSettle();

    final infoCenter = tester.getCenter(find.byType(AppFormInfoButton));
    final segmentCenter = tester.getCenter(
      find.byKey(const Key('pet_neuter_segmented')),
    );
    expect(infoCenter.dy, lessThan(segmentCenter.dy - 20));
  });
}
