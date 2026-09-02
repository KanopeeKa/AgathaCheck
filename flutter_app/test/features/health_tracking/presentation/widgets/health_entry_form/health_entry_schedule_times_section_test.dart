import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/controllers/health_entry_form_controller.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_form/health_entry_schedule_times_section.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  group('HealthEntryScheduleTimesSection', () {
    late ProviderContainer container;
    late HealthEntryFormController controller;

    setUp(() {
      container = ProviderContainer();
      controller = container.read(
        healthEntryFormControllerProvider(
          const HealthEntryFormParams(),
        ).notifier,
      );
    });

    tearDown(() => container.dispose());

    Widget wrap(Widget child) {
      return ProviderScope(
        parent: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('shows time rows when checkbox enabled', (tester) async {
      controller.setScheduleAtSpecificTimes(true);
      controller.addScheduleTime();

      await tester.pumpWidget(
        wrap(
          HealthEntryScheduleTimesSection(
            scheduleAtSpecificTimes: true,
            scheduleTimes: const ['08:00', '20:00'],
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('schedule_time_picker_0')), findsOneWidget);
      expect(find.byKey(const Key('schedule_time_picker_1')), findsOneWidget);
      expect(find.byKey(const Key('add_schedule_time_button')), findsOneWidget);
    });

    testWidgets('hides time rows when checkbox off', (tester) async {
      await tester.pumpWidget(
        wrap(
          HealthEntryScheduleTimesSection(
            scheduleAtSpecificTimes: false,
            scheduleTimes: const ['08:00'],
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('schedule_time_picker_0')), findsNothing);
    });
  });
}
