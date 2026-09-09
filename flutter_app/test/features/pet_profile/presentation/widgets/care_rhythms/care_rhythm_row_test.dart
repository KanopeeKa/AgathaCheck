import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_rhythms/care_rhythm_row.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  final entry = HealthEntry(
    id: 'rhythm-1',
    petId: 'pet-1',
    name: 'Weight check',
    type: HealthEntryType.other,
    frequency: HealthFrequency.weekly,
    startDate: DateTime(2025, 1, 1),
    nextDueDate: DateTime.now().add(const Duration(days: 2)),
    careFamily: CareFamily.weightMonitoring,
  );

  Widget buildRow({required bool isEstablished}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: CareRhythmRow(
              entry: entry,
              petId: 'pet-1',
              isEstablished: isEstablished,
            ),
          ),
        ),
        GoRoute(
          path: '/pet/:petId/events/:entryId',
          builder: (context, state) => const Scaffold(body: Text('Event detail')),
        ),
      ],
    );

    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('shows Established marker when server reports establishment', (
    tester,
  ) async {
    await tester.pumpWidget(buildRow(isEstablished: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_rhythm_established_marker')), findsOneWidget);
    expect(find.text('Established'), findsOneWidget);
  });

  testWidgets('hides Established marker when not established', (tester) async {
    await tester.pumpWidget(buildRow(isEstablished: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('care_rhythm_established_marker')), findsNothing);
    expect(find.text('Established'), findsNothing);
  });

  testWidgets('due soon stays primary and Established marker is secondary', (
    tester,
  ) async {
    await tester.pumpWidget(buildRow(isEstablished: true));
    await tester.pumpAndSettle();

    final dueFinder = find.byKey(const Key('care_rhythm_next_due'));
    final markerFinder = find.byKey(const Key('care_rhythm_established_marker'));
    expect(dueFinder, findsOneWidget);
    expect(markerFinder, findsOneWidget);

    final dueWidget = tester.widget<Text>(dueFinder);
    final markerWidget = tester.widget<Text>(markerFinder);
    expect(dueWidget.style?.color, isNot(equals(markerWidget.style?.color)));
    expect(dueWidget.data, contains('Next due'));
    expect(markerWidget.data, 'Established');
  });
}
