import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/form/app_form_labeled_field.dart';
import 'package:pet_profile_app/core/widgets/form/app_form_section.dart';

void main() {
  testWidgets('AppFormSection renders title and child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormSection(
            title: 'Details',
            children: [const Text('Field content')],
          ),
        ),
      ),
    );

    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Field content'), findsOneWidget);
  });

  testWidgets('AppFormLabeledField renders external label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormLabeledField(
            label: 'Name',
            child: TextFormField(decoration: const InputDecoration()),
          ),
        ),
      ),
    );

    expect(find.text('Name'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  testWidgets('AppFormLabeledField associates label with child semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFormLabeledField(
            label: 'Email',
            subtitle: 'Optional',
            child: TextFormField(decoration: const InputDecoration()),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Email. Optional'), findsOneWidget);
  });
}
