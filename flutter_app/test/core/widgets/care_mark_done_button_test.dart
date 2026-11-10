import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_action_row.dart';
import 'package:pet_profile_app/core/widgets/care_mark_done_button.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

Color? _fillColor(WidgetTester tester) {
  return tester
      .widget<Material>(
        find.descendant(
          of: find.byType(IconButton),
          matching: find.byType(Material),
        ),
      )
      .color;
}

void main() {
  group('CareMarkDoneButton', () {
    testWidgets('renders dark filled background with white tick', (
      tester,
    ) async {
      await tester.pumpWidget(_host(CareMarkDoneButton(onPressed: () {})));

      final colorScheme = AppTheme.lightTheme.colorScheme;
      expect(_fillColor(tester), colorScheme.primary);

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.icon, Icons.check_circle);
      final iconColor = IconTheme.of(
        tester.element(find.byIcon(Icons.check_circle)),
      ).color;
      expect(iconColor, colorScheme.onPrimary);
      expect(colorScheme.onPrimary, Colors.white);
    });

    testWidgets('has a 40dp visual inside a 48dp touch target', (tester) async {
      await tester.pumpWidget(_host(CareMarkDoneButton(onPressed: () {})));

      expect(
        tester.getSize(find.byType(CareMarkDoneButton)),
        const Size.square(CareMarkDoneButton.touchTargetSize),
      );
      final visual = find.descendant(
        of: find.byType(IconButton),
        matching: find.byType(Material),
      );
      expect(
        tester.getSize(visual),
        const Size.square(CareMarkDoneButton.visualSize),
      );
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(CareMarkDoneButton(onPressed: () => taps++)),
      );

      await tester.tap(find.byType(CareMarkDoneButton));
      expect(taps, 1);
    });

    testWidgets('null onPressed renders disabled and ignores taps', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const CareMarkDoneButton(onPressed: null)));

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
      await tester.tap(find.byType(CareMarkDoneButton), warnIfMissed: false);
      expect(
        tester.getSemantics(find.byType(CareMarkDoneButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
    });

    testWidgets('exposes localized default and custom semantics labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(CareMarkDoneButton(onPressed: () {})));
      expect(
        tester.getSemantics(find.byType(CareMarkDoneButton)),
        isSemantics(label: 'Mark as done', isButton: true, hasTapAction: true),
      );

      await tester.pumpWidget(
        _host(
          CareMarkDoneButton(
            onPressed: () {},
            semanticLabel: 'Mark Heartworm pill as done',
            semanticsIdentifier: 'done_entry-1',
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(CareMarkDoneButton));
      expect(node.label, 'Mark Heartworm pill as done');
      expect(node.identifier, 'done_entry-1');
      handle.dispose();
    });

    testWidgets('shows "Mark as done" tooltip on long press', (tester) async {
      await tester.pumpWidget(_host(CareMarkDoneButton(onPressed: () {})));

      await tester.longPress(find.byType(CareMarkDoneButton));
      await tester.pumpAndSettle();
      expect(find.text('Mark as done'), findsOneWidget);
    });
  });

  group('shared across care rows', () {
    testWidgets('CareActionRow (pet screen / All Care) uses it', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          CareActionRow(
            title: 'Evening supplement',
            subtitle: 'Medication · daily',
            statusLabel: 'Due today',
            statusTreatment: dueTodayStatusTreatment(),
            semanticLabel: 'Evening supplement, due today',
            leading: const CareFamilyIcon(family: CareFamily.medication),
            markDoneKey: const Key('row_done'),
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(CareMarkDoneButton), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Done'), findsNothing);
      await tester.tap(find.byKey(const Key('row_done')));
      expect(taps, 1);
    });

    testWidgets('CareActionRow hides it without an action', (tester) async {
      await tester.pumpWidget(
        _host(
          CareActionRow(
            title: 'Closed series',
            subtitle: 'Medication',
            statusLabel: 'Closed',
            statusTreatment: dueTodayStatusTreatment(),
            semanticLabel: 'Closed series',
            leading: const CareFamilyIcon(family: CareFamily.medication),
          ),
        ),
      );

      expect(find.byType(CareMarkDoneButton), findsNothing);
    });
  });
}
