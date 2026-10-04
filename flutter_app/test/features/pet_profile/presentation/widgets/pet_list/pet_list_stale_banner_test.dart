import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_cache_freshness.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_list/pet_list_stale_banner.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _FixedMetadataNotifier extends PetListFetchMetadataNotifier {
  _FixedMetadataNotifier(this.metadata);

  final PetListFetchMetadata metadata;

  @override
  PetListFetchMetadata build() => metadata;
}

void main() {
  Widget wrap(Widget child, PetListFetchMetadata metadata) {
    return ProviderScope(
      overrides: [
        petListFetchMetadataProvider.overrideWith(
          () => _FixedMetadataNotifier(metadata),
        ),
        petListProvider.overrideWith(() => _NoopPetListNotifier()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('hides when data is fresh', (tester) async {
    await tester.pumpWidget(
      wrap(const PetListStaleBanner(), const PetListFetchMetadata()),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsNothing);
  });

  testWidgets('stale shows offline info without retry', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PetListStaleBanner(),
        PetListFetchMetadata(
          freshness: PetCacheFreshness.stale,
          fetchedAt: DateTime.utc(2026, 10, 4, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('expired shows warning with retry semantics', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PetListStaleBanner(),
        const PetListFetchMetadata(freshness: PetCacheFreshness.expired),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved data may be out of date'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

class _NoopPetListNotifier extends PetListNotifier {
  @override
  Future<List<Pet>> build() async => const [];
}
