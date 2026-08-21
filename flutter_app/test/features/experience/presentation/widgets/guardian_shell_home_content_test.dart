import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/dashboard_section.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_shell_home_content.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_operations_desk_layout.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/guardian_today_orientation.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_my_pets_section.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/health_providers.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

void main() {
  final pets = List.generate(
    6,
    (i) => Pet(id: 'pet-$i', name: 'Pet $i', species: 'Dog', breed: 'Mix'),
  );

  final vets = [
    const Vet(id: 'vet-1', name: 'Dr. Smith', address: 'Springfield'),
  ];

  Widget buildDashboard({
    List<Pet>? petList,
    HealthEntriesNotifier? healthNotifier,
    Locale? locale,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final list = petList ?? pets;
    final resolvedHealthNotifier =
        healthNotifier ?? FakeHealthEntriesNotifier();
    return ProviderScope(
      key: ValueKey(resolvedHealthNotifier),
      overrides: [
        authProvider.overrideWith((ref) => FakeAuthNotifier()),
        petListProvider.overrideWith(() => TestPetListNotifier(list)),
        vetListProvider.overrideWith(() => _TestVetListNotifier(vets)),
        healthEntriesNotifierProvider.overrideWith(
          () => resolvedHealthNotifier,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.lightTheme.copyWith(
          splashFactory: NoSplash.splashFactory,
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: GuardianShellHomeContent(
              allPets: list,
              controller: PetListController(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('baseline: dashboard shows exactly three sections', (
    tester,
  ) async {
    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(find.text('My Pets'), findsOneWidget);
    expect(find.text('Due and Overdue'), findsOneWidget);
    expect(find.text('My vets'), findsOneWidget);
    expect(find.text('All Events'), findsOneWidget);
    expect(find.text('Manage veterinarians'), findsOneWidget);
    expect(find.text('Pending foster placements'), findsNothing);
    expect(find.text('Pending Shares'), findsNothing);
    expect(find.byKey(const Key('guardian_today_orientation')), findsOneWidget);
    expect(find.byType(GuardianTodayOrientation), findsOneWidget);
    expect(find.byType(DashboardSection), findsNWidgets(3));
  });

  testWidgets(
    'My Pets preview caps at four and keeps the All Pets destination',
    (tester) async {
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();

      expect(find.text('All Pets'), findsOneWidget);
      expect(find.text('Pet 0'), findsOneWidget);
      expect(find.text('Pet 3'), findsOneWidget);
      expect(find.text('Pet 4'), findsNothing);
      expect(find.text('Pet 5'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(GuardianMyPetsSection),
          matching: find.byType(Wrap),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('empty state when no pets', (tester) async {
    await tester.pumpWidget(buildDashboard(petList: []));
    await tester.pumpAndSettle();

    expect(find.text('No pets yet'), findsOneWidget);
    expect(find.text('My Pets'), findsOneWidget);
  });

  testWidgets('uses a two-column desk layout on wide screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('guardian_desk_secondary_sections_wide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('guardian_desk_primary_section_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('guardian_desk_secondary_sections_narrow')),
      findsNothing,
    );
  });

  testWidgets('uses a single-column desk layout on narrow screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(899, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildDashboard());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('guardian_desk_secondary_sections_narrow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('guardian_desk_secondary_sections_wide')),
      findsNothing,
    );
  });

  testWidgets('maps home provider states into the orientation layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildDashboard(healthNotifier: _LoadingHealthEntriesNotifier()),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('guardian_today_orientation_loading')),
      findsOneWidget,
    );

    await tester.pumpWidget(buildDashboard(petList: []));
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const Key('guardian_today_orientation_firstUse')),
      findsOneWidget,
    );

    final errorNotifier = _RetryingErrorHealthEntriesNotifier();
    await tester.pumpWidget(buildDashboard(healthNotifier: errorNotifier));
    await tester.pump();
    await tester.pump();
    final orientation = find.byKey(const Key('guardian_today_orientation'));
    expect(
      find.descendant(
        of: orientation,
        matching: find.byKey(const Key('guardian_today_orientation_error')),
      ),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: orientation, matching: find.text('Retry')),
    );
    expect(errorNotifier.refreshCalls, 1);
  });

  testWidgets(
    'uses one natural scroll view and the correct layout across desk widths',
    (tester) async {
      const widths = [
        320.0,
        375.0,
        414.0,
        768.0,
        899.0,
        900.0,
        901.0,
        1280.0,
        1440.0,
      ];

      for (final width in widths) {
        await tester.binding.setSurfaceSize(Size(width, 800));
        await tester.pumpWidget(buildDashboard());
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(
          find.byKey(const Key('guardian_desk_secondary_sections_wide')),
          width >= GuardianOperationsDeskLayout.wideBreakpoint
              ? findsOneWidget
              : findsNothing,
        );
        expect(
          find.byKey(const Key('guardian_desk_secondary_sections_narrow')),
          width < GuardianOperationsDeskLayout.wideBreakpoint
              ? findsOneWidget
              : findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
      addTearDown(() => tester.binding.setSurfaceSize(null));
    },
  );

  testWidgets(
    'bounds desktop content and keeps actions reachable at 200% text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(buildDashboard());
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const Key('guardian_operations_desk_content')))
            .width,
        lessThanOrEqualTo(1180),
      );

      await tester.binding.setSurfaceSize(const Size(320, 700));
      await tester.pumpWidget(
        buildDashboard(
          locale: const Locale('fr'),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Gérer les vétérinaires'),
        120,
        scrollable: find.byType(Scrollable),
      );

      expect(
        find.byKey(const Key('guardian_today_orientation')),
        findsOneWidget,
      );
      expect(find.text('Gérer les vétérinaires'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _TestVetListNotifier extends VetListNotifier {
  _TestVetListNotifier(this._vets);

  final List<Vet> _vets;

  @override
  Future<List<Vet>> build() async => _vets;
}

class _LoadingHealthEntriesNotifier extends HealthEntriesNotifier {
  final _completer = Completer<List<HealthEntry>>();

  @override
  Future<List<HealthEntry>> build() => _completer.future;
}

class _RetryingErrorHealthEntriesNotifier extends HealthEntriesNotifier {
  int refreshCalls = 0;

  @override
  Future<List<HealthEntry>> build() async =>
      throw StateError('Care service unavailable');

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}
