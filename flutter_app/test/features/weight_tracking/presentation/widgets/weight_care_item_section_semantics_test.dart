import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/providers/weight_providers.dart';
import 'package:pet_profile_app/features/weight_tracking/presentation/widgets/weight_care_item_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _EmptyWeightEntriesNotifier extends WeightEntriesNotifier {
  @override
  Future<List<WeightEntry>> build(String arg) async => [];
}

void main() {
  testWidgets('weight_care_item_section exposes E2E semantics identifier', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiBaseUrlProvider.overrideWithValue('http://test.local'),
          weightEntriesNotifierProvider.overrideWith(() => _EmptyWeightEntriesNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: WeightCareItemSection(petId: 'pet-1', entryId: 'entry-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier('weight_care_item_section'), findsOneWidget);
  });
}
