import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  final date = DateTime(2026, 1, 1);
  final colorScheme = AppTheme.lightTheme.colorScheme;

  test('formatHealthEntryStatusDate uses dd MMM yy', () {
    expect(
      formatHealthEntryStatusDate(date),
      DateFormat('dd MMM yy').format(date),
    );
    expect(formatHealthEntryStatusDate(date), '01 Jan 26');
  });

  test('formatHealthEntryStatusLine shows doneOn for completed entries', () {
    final entry = HealthEntry(
      id: '1',
      petId: 'pet-1',
      name: 'Rabies',
      type: HealthEntryType.preventive,
      frequency: HealthFrequency.once,
      startDate: date,
      completedOn: date,
      nextDueDate: DateTime(9999, 12, 31),
    );

    expect(formatHealthEntryStatusLine(entry, l), l.doneOn('01 Jan 26'));
  });

  test('formatHealthEntryStatusLine shows due date without labels', () {
    final entry = HealthEntry(
      id: '1',
      petId: 'pet-1',
      name: 'Heartgard',
      type: HealthEntryType.medication,
      frequency: HealthFrequency.monthly,
      startDate: date,
      nextDueDate: DateTime(2026, 3, 15),
    );

    expect(formatHealthEntryStatusLine(entry, l), '15 Mar 26');
  });

  group('healthEntryStatusTreatment', () {
    HealthEntry entry({
      DateTime? nextDue,
      DateTime? completedOn,
    }) {
      return HealthEntry(
        id: '1',
        petId: 'pet-1',
        name: 'Test',
        type: HealthEntryType.medication,
        frequency: HealthFrequency.monthly,
        startDate: date,
        nextDueDate: nextDue,
        completedOn: completedOn,
        remindDaysBefore: 3,
      );
    }

    test('overdue uses error foreground on subtle danger background', () {
      final treatment = healthEntryStatusTreatment(
        entry(nextDue: DateTime(2020, 1, 1)),
        colorScheme,
      );
      expect(treatment.kind, HealthEntryStatusKind.overdue);
      expect(treatment.backgroundColor, AppColorTokens.dangerLight);
      expect(treatment.foregroundColor, AppColorTokens.body);
      expect(treatment.resolvedIconColor, AppColorTokens.danger);
    });

    test('due today uses warning foreground on subtle warning background', () {
      final treatment = healthEntryStatusTreatment(
        entry(nextDue: DateTime.now()),
        colorScheme,
      );
      expect(treatment.kind, HealthEntryStatusKind.dueToday);
      expect(treatment.backgroundColor, AppColorTokens.warningLight);
      expect(treatment.foregroundColor, AppColorTokens.body);
      expect(treatment.resolvedIconColor, AppColorTokens.warning);
    });

    test('completed uses success foreground on subtle success background', () {
      final treatment = healthEntryStatusTreatment(
        HealthEntry(
          id: '1',
          petId: 'pet-1',
          name: 'Test',
          type: HealthEntryType.medication,
          frequency: HealthFrequency.once,
          startDate: date,
          completedOn: date,
          nextDueDate: DateTime(9999, 12, 31),
        ),
        colorScheme,
      );
      expect(treatment.kind, HealthEntryStatusKind.completed);
      expect(treatment.backgroundColor, AppColorTokens.successLight);
      expect(treatment.foregroundColor, AppColorTokens.body);
      expect(treatment.resolvedIconColor, AppColorTokens.success);
    });
  });

  group('HealthEntryStatusLabel', () {
    Future<void> pumpLabel(
      WidgetTester tester, {
      required HealthEntryStatusTreatment treatment,
      required String text,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: HealthEntryStatusLabel(text: text, treatment: treatment),
          ),
        ),
      );
    }

    testWidgets('renders icon for every status variant', (tester) async {
      final variants = [
        completedStatusTreatment(),
        overdueStatusTreatment(colorScheme),
        dueTodayStatusTreatment(),
        healthEntryStatusTreatment(
          HealthEntry(
            id: '1',
            petId: 'pet-1',
            name: 'Soon',
            type: HealthEntryType.medication,
            frequency: HealthFrequency.monthly,
            startDate: date,
            nextDueDate: DateTime.now().add(const Duration(days: 2)),
            remindDaysBefore: 3,
          ),
          colorScheme,
        ),
        healthEntryStatusTreatment(
          HealthEntry(
            id: '2',
            petId: 'pet-1',
            name: 'Later',
            type: HealthEntryType.medication,
            frequency: HealthFrequency.monthly,
            startDate: date,
            nextDueDate: DateTime(2026, 6, 1),
            remindDaysBefore: 3,
          ),
          colorScheme,
        ),
      ];

      for (final treatment in variants) {
        await pumpLabel(tester, treatment: treatment, text: 'Status');
        expect(find.byIcon(treatment.icon), findsOneWidget);
      }
    });

    testWidgets('semantic status treatments meet contrast on subtle backgrounds',
        (tester) async {
      final pairs = [
        (
          completedStatusTreatment(),
          AppColorTokens.body,
          AppColorTokens.successLight,
        ),
        (
          overdueStatusTreatment(colorScheme),
          AppColorTokens.body,
          AppColorTokens.dangerLight,
        ),
        (
          dueTodayStatusTreatment(),
          AppColorTokens.body,
          AppColorTokens.warningLight,
        ),
      ];

      for (final (treatment, foreground, background) in pairs) {
        final ratio = _contrastRatio(foreground, background);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '${treatment.kind} foreground/background contrast',
        );
      }
    });
  });
}

double _contrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}
