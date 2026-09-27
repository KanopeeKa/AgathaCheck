import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_item_module.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_item_section_header.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_item_status_pill.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_item_stat_row.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('CareItemModule', () {
    testWidgets('renders bordered module surface', (tester) async {
      await tester.pumpWidget(
        _host(
          const CareItemDetailCanvas(
            child: CareItemModule(
              key: Key('module'),
              child: Text('Inside'),
            ),
          ),
        ),
      );
      expect(find.text('Inside'), findsOneWidget);
      expect(find.byType(CareItemModule), findsOneWidget);
    });
  });

  group('CareItemSectionHeader', () {
    testWidgets('shows title and trailing', (tester) async {
      await tester.pumpWidget(
        _host(
          const CareItemSectionHeader(
            title: 'Schedule',
            trailing: Text('Edit'),
          ),
        ),
      );
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });
  });

  group('CareItemStatusPill', () {
    testWidgets('shows overdue label', (tester) async {
      await tester.pumpWidget(
        _host(
          const CareItemStatusPill(
            label: 'Overdue',
            tone: CareItemStatusTone.overdue,
          ),
        ),
      );
      expect(find.text('Overdue'), findsOneWidget);
    });
  });

  group('CareItemStatRow', () {
    testWidgets('renders stat cells', (tester) async {
      await tester.pumpWidget(
        _host(
          const CareItemStatRow(
            cells: [
              CareItemStatCellData(label: 'Frequency', value: 'Every month'),
              CareItemStatCellData(label: 'Reminder', value: '7 days before'),
            ],
          ),
        ),
      );
      expect(find.text('Every month'), findsOneWidget);
      expect(find.text('7 days before'), findsOneWidget);
    });
  });
}
