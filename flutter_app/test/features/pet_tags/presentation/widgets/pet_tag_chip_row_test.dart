import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_tags/domain/entities/pet_tag.dart';
import 'package:pet_profile_app/features/pet_tags/presentation/providers/pet_tag_providers.dart';
import 'package:pet_profile_app/features/pet_tags/presentation/widgets/pet_tag_chip_row.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _LoadedPetTagListNotifier extends PetTagListNotifier {
  _LoadedPetTagListNotifier(this.tags);

  final List<PetTag> tags;

  @override
  Future<List<PetTag>> build() async => tags;
}

void main() {
  const petId = 'pet-1';

  testWidgets('does not show My tags section title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petTagListProvider.overrideWith(
            () => _LoadedPetTagListNotifier([
              const PetTag(id: 't1', name: 'Fred', petIds: [petId]),
            ]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PetTagChipRow(petId: petId)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My tags'), findsNothing);
    expect(find.text('Fred'), findsOneWidget);
    expect(find.byKey(const Key('pet_tag_add_chip')), findsOneWidget);
  });
}
