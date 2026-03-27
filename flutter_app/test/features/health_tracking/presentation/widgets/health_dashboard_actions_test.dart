import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agathacheck/features/health_tracking/presentation/widgets/health_dashboard_actions.dart';

void main() {
  testWidgets('HealthDashboardActions renders and triggers callbacks', (WidgetTester tester) async {
    bool pdfTapped = false;
    bool csvTapped = false;
    _GroupMode? selectedMode;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HealthDashboardActions(
          onExportPdf: () => pdfTapped = true,
          onExportCsv: () => csvTapped = true,
          onGroupModeChanged: (mode) => selectedMode = mode,
          groupMode: _GroupMode.dueDate,
          lGroupBy: 'Group By',
          lByDueDate: 'Due Date',
          lByPet: 'Pet',
          lBySpecies: 'Species',
          lExportPdf: 'Export PDF',
          lExportCsv: 'Export CSV',
        ),
      ),
    ));
    expect(find.byIcon(Icons.sort), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    expect(find.byIcon(Icons.download), findsOneWidget);
    await tester.tap(find.byIcon(Icons.picture_as_pdf));
    expect(pdfTapped, isTrue);
    await tester.tap(find.byIcon(Icons.download));
    expect(csvTapped, isTrue);
  });
}

enum _GroupMode { dueDate, pet, petType }
