import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_importance.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_setting.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/recurrence_anchor.dart';
import 'package:pet_profile_app/features/health_tracking/domain/repositories/health_repository.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_form/health_entry_advanced_settings_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _StubHealthRepository implements HealthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'advanced settings collapsed hides schedule type until expanded',
    (tester) async {
      const params = HealthEntryFormParams(petId: 'p1');
      final container = ProviderContainer(
        overrides: [
          healthRepositoryProvider.overrideWithValue(_StubHealthRepository()),
        ],
      );
      final controller = container.read(
        healthEntryFormControllerProvider(params).notifier,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: HealthEntryAdvancedSettingsSection(
                  careSetting: CareSetting.home,
                  careImportance: CareImportance.essential,
                  frequency: HealthFrequency.daily,
                  recurrenceAnchor: RecurrenceAnchor.fromCompletion,
                  lateCompletionChoice: null,
                  providerContactId: null,
                  providerTypedName: null,
                  photos: const [],
                  pendingPhotos: const [],
                  isUploadingPhoto: false,
                  baseUrl: 'http://localhost:3000',
                  controller: controller,
                  onPickCamera: () {},
                  onPickGallery: () {},
                  onDeletePhoto: (_) {},
                  onRemovePendingPhoto: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Advanced settings'), findsOneWidget);
      expect(find.text('Schedule type'), findsNothing);
      await tester.tap(find.byKey(const Key('health_entry_advanced_settings')));
      await tester.pumpAndSettle();
      expect(find.text('Schedule type'), findsOneWidget);
      expect(find.byKey(const Key('care_item_if_done_late')), findsOneWidget);
      container.dispose();
    },
  );
}
