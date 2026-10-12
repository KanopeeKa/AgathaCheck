import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/profile_fact_status.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/profile_fact_capture_sheet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _RecordingPetListNotifier extends PetListNotifier {
  _RecordingPetListNotifier(this.initial);

  final List<Pet> initial;
  Pet? lastUpdated;

  @override
  Future<List<Pet>> build() async => initial;

  @override
  Future<void> updatePet(Pet pet) async {
    lastUpdated = pet;
    state = AsyncData([pet]);
  }
}

class _SheetLauncher extends ConsumerWidget {
  const _SheetLauncher({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () => showProfileFactCaptureSheet(
          context,
          ref,
          pet: pet,
          topic: ProfileFactCaptureTopic.neuter,
        ),
        child: const Text('open'),
      ),
    );
  }
}

void main() {
  testWidgets('AC-IC-01: saving neuter no updates pet status', (tester) async {
    const pet = Pet(
      id: 'pet-1',
      name: 'Bella',
      species: 'Dog',
      neuterStatus: profileFactStatusUnknown,
    );
    final notifier = _RecordingPetListNotifier([pet]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [petListProvider.overrideWith(() => notifier)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const _SheetLauncher(pet: pet),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_fact_capture_sheet')), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_fact_capture_save')));
    await tester.pumpAndSettle();

    expect(notifier.lastUpdated?.neuterStatus, profileFactStatusNo);
    expect(notifier.lastUpdated?.neuterStatusSource, 'user');
    expect(find.byKey(const Key('profile_fact_capture_sheet')), findsNothing);
  });
}
