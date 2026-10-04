import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/care_item_blocks.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/care_category_blocks/care_category_blocks_edit_section.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class _StaticPetListNotifier extends PetListNotifier {
  _StaticPetListNotifier(this.pets);

  final List<Pet> pets;

  @override
  Future<List<Pet>> build() async => pets;
}

void main() {
  Widget wrap(Widget child, {List<Pet> pets = const []}) {
    return ProviderScope(
      overrides: [
        petListProvider.overrideWith(() => _StaticPetListNotifier(pets)),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('medication shows collapsed add dose control', (tester) async {
    await tester.pumpWidget(
      wrap(
        CareCategoryBlocksEditSection(
          careFamily: CareFamily.medication,
          blocks: const CareItemBlocks(),
          selectedPetIds: const {'pet-1'},
          onBlocksChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('care_block_add_Product and amount')),
      findsOneWidget,
    );
  });

  testWidgets('weight monitoring shows pet reference weight', (tester) async {
    const pet = Pet(
      id: 'pet-1',
      name: 'Agatha',
      species: 'dog',
      weightReferenceValue: 12.5,
    );
    await tester.pumpWidget(
      wrap(
        CareCategoryBlocksEditSection(
          careFamily: CareFamily.weightMonitoring,
          blocks: const CareItemBlocks(),
          selectedPetIds: const {'pet-1'},
          onBlocksChanged: (_) {},
        ),
        pets: [pet],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_block_weight_target')), findsOneWidget);
    expect(find.textContaining('12.5'), findsOneWidget);
  });
}
