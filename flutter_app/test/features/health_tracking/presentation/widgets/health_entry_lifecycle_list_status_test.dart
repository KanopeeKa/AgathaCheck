import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

HealthEntry _closedEntry({String? careClosedReason}) {
  return HealthEntry(
    id: 'closed-1',
    petId: 'pet-1',
    name: 'Heart meds',
    type: HealthEntryType.medication,
    frequency: HealthFrequency.daily,
    startDate: DateTime(2024, 1, 1),
    status: 'closed',
    careClosedReason: careClosedReason,
    remindDaysBefore: 1,
  );
}

void main() {
  testWidgets(
    'user-closed row shows Closed by you with stop icon and grey pill',
    (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l = AppLocalizations.of(context)!;
              final entry = _closedEntry(careClosedReason: 'stopped_by_user');
              final treatment = healthEntryLifecycleStatusTreatment(
                entry,
                Theme.of(context).colorScheme,
              );
              return Scaffold(
                body: HealthEntryStatusLabel(
                  text: formatHealthEntryLifecycleStatusLabel(entry, l),
                  treatment: treatment,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Closed by you'), findsOneWidget);
      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
      final scheme = Theme.of(
        tester.element(find.byType(HealthEntryStatusLabel)),
      ).colorScheme;
      final entry = _closedEntry(careClosedReason: 'stopped_by_user');
      final treatment = healthEntryLifecycleStatusTreatment(entry, scheme);
      expect(treatment.backgroundColor, scheme.surfaceContainerHighest);
      expect(treatment.iconColor, scheme.onSurfaceVariant);
    },
  );
}
