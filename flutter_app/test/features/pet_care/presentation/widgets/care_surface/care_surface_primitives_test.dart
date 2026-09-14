import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/widgets/health_entry_status.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_action_row.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_attention_callout.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_collection_inset_list.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_destination_row.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_surface_tokens.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_insight_tile.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/care_surface/care_trend_sparkline.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_family_icon.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('CareCollectionInsetList', () {
    testWidgets('renders collection background and inset dividers', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CareCollectionInsetList(
            key: const Key('collection_demo'),
            children: [
              const CareCollectionInsetItem(child: Text('First row')),
              const CareCollectionInsetItem(
                showDividerBefore: true,
                child: Text('Second row'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('First row'), findsOneWidget);
      expect(find.text('Second row'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);

      final collection = tester.widget<Material>(
        find.descendant(
          of: find.byKey(const Key('collection_demo')),
          matching: find.byType(Material),
        ),
      );
      expect(collection.color, AppColorTokens.petCareCollection);
    });
  });

  group('CareAttentionCallout', () {
    testWidgets('renders message with semantic label', (tester) async {
      await tester.pumpWidget(
        _host(
          CareAttentionCallout(
            key: const Key('attention_demo'),
            message: 'Flea treatment is overdue',
            semanticLabel: 'Attention: flea treatment overdue',
          ),
        ),
      );

      expect(find.text('Flea treatment is overdue'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('CareActionRow', () {
    testWidgets('renders title, subtitle, status, and action', (tester) async {
      await tester.pumpWidget(
        _host(
          CareActionRow(
            key: const Key('action_demo'),
            title: 'Evening supplement',
            subtitle: 'Medication · daily',
            statusLabel: 'Due today',
            statusTreatment: dueTodayStatusTreatment(),
            semanticLabel: 'Evening supplement, due today',
            leading: const CareFamilyIcon(family: CareFamily.medication),
            trailingLabel: 'Done',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Evening supplement'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Due today'), findsOneWidget);
    });
  });

  group('CareInsightTile', () {
    testWidgets('renders summary and sparkline', (tester) async {
      await tester.pumpWidget(
        _host(
          CareInsightTile(
            key: const Key('insight_demo'),
            title: 'Weight',
            summary: 'Stable over 4 weeks',
            semanticLabel: 'Weight insight, stable over 4 weeks',
            sparklineSemanticLabel: 'Weight trend rising slightly',
            sparklineValues: const [27.4, 27.6, 27.5, 27.8],
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Stable over 4 weeks'), findsOneWidget);
      expect(
        find.byKey(const Key('care_trend_sparkline_chart')),
        findsOneWidget,
      );
    });
  });

  group('CareDestinationRow', () {
    testWidgets('renders label and chevron', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          CareDestinationRow(
            key: const Key('destination_demo'),
            label: 'Health & history',
            semanticLabel: 'Open health and history',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Health & history'));
      expect(tapped, isTrue);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('CareTrendSparkline', () {
    testWidgets('shows empty state without flat line', (tester) async {
      await tester.pumpWidget(
        _host(
          const CareTrendSparkline(
            key: Key('sparkline_empty'),
            values: [],
            emptyLabel: 'No weigh-ins yet',
          ),
        ),
      );

      expect(find.text('No weigh-ins yet'), findsOneWidget);
      expect(find.byKey(const Key('care_trend_sparkline_chart')), findsNothing);
    });

    testWidgets('shows insufficient-data state for one point', (tester) async {
      await tester.pumpWidget(
        _host(
          const CareTrendSparkline(
            key: Key('sparkline_insufficient'),
            values: [27.5],
            insufficientLabel: 'Need more weigh-ins',
          ),
        ),
      );

      expect(find.text('Need more weigh-ins'), findsOneWidget);
      expect(find.byKey(const Key('care_trend_sparkline_chart')), findsNothing);
    });

    testWidgets('draws line for sufficient points', (tester) async {
      await tester.pumpWidget(
        _host(
          const CareTrendSparkline(
            key: Key('sparkline_data'),
            values: [27.0, 27.4, 27.8],
          ),
        ),
      );

      expect(
        find.byKey(const Key('care_trend_sparkline_chart')),
        findsOneWidget,
      );
    });
  });

  testWidgets('four roles render side by side for visual review', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            CareAttentionCallout(
              key: const Key('roles_attention'),
              message: 'Needs attention',
              semanticLabel: 'Needs attention',
            ),
            const SizedBox(height: 8),
            CareActionRow(
              key: const Key('roles_action'),
              title: 'Walk check-in',
              subtitle: 'Exercise',
              statusLabel: 'Due today',
              statusTreatment: dueTodayStatusTreatment(),
              semanticLabel: 'Walk check-in due today',
              leading: const CareFamilyIcon(family: CareFamily.other),
              trailingLabel: 'Done',
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            CareInsightTile(
              key: const Key('roles_insight'),
              title: 'Weight',
              summary: 'Trend stable',
              semanticLabel: 'Weight insight',
              sparklineValues: const [12, 12.1, 12.0, 12.2],
              onTap: () {},
            ),
            CareDestinationRow(
              key: const Key('roles_destination'),
              label: 'Health & history',
              semanticLabel: 'Health and history',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('roles_attention')), findsOneWidget);
    expect(find.byKey(const Key('roles_action')), findsOneWidget);
    expect(find.byKey(const Key('roles_insight')), findsOneWidget);
    expect(find.byKey(const Key('roles_destination')), findsOneWidget);
  });

  test('care surface widgets use token colours only', () {
    expect(CareSurfaceTokens.collectionBackground(), AppColorTokens.petCareCollection);
    expect(CareSurfaceTokens.moduleBackground(), AppColorTokens.surface);
    expect(AppColorTokens.dangerLight, isNotNull);
  });
}
