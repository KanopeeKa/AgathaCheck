import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_detail/pet_profile_weight_insight_section.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FakeWeightEntriesNotifier extends WeightEntriesNotifier {
  _FakeWeightEntriesNotifier(this._entries);

  final List<WeightEntry> _entries;

  @override
  Future<List<WeightEntry>> build(String arg) async => _entries;

  @override
  Future<void> addEntry(WeightEntry entry) async {
    state = AsyncValue.data([entry, ..._entries]);
  }
}

void main() {
  testWidgets('FW-4 profile tile uses weightEntriesNotifierProvider', (
    tester,
  ) async {
    final entry = WeightEntry(
      id: 'w-1',
      petId: 'pet-1',
      date: DateTime(2025, 6, 1),
      weight: 12.0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weightEntriesNotifierProvider.overrideWith(
            () => _FakeWeightEntriesNotifier([entry]),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PetProfileWeightInsightSection(
              petId: 'pet-1',
              pet: const Pet(id: 'pet-1', name: 'Rex', species: 'Dog'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('12.0 kg'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PetProfileWeightInsightSection)),
    );
    await container
        .read(weightEntriesNotifierProvider('pet-1').notifier)
        .addEntry(
          WeightEntry(
            id: 'w-2',
            petId: 'pet-1',
            date: DateTime(2025, 6, 2),
            weight: 11.0,
          ),
        );
    await tester.pumpAndSettle();

    expect(find.textContaining('11.0 kg'), findsOneWidget);
  });
}
