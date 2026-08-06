import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/screens/organization_role_defaults_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

class _RoleDefaultsRepo extends RecordingOrganizationRepository {
  final List<Map<String, dynamic>> saveCalls = [];

  @override
  Future<Map<String, dynamic>> saveRolePermissionDefaults(
    String orgId,
    String tier,
    List<String> grantedKeys,
    String token,
  ) async {
    saveCalls.add({
      'tier': tier,
      'grantedKeys': grantedKeys,
    });
    return {
      'tier': tier,
      'effective_defaults': grantedKeys,
      'members_affected': 2,
    };
  }
}

void main() {
  Future<void> pumpScreen(WidgetTester tester, _RoleDefaultsRepo repo) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OrganizationRoleDefaultsScreen(orgId: 'org-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows tier selector and grouped permission toggles', (
    tester,
  ) async {
    await pumpScreen(tester, _RoleDefaultsRepo());

    expect(find.byKey(const Key('org_role_defaults_screen')), findsOneWidget);
    expect(find.byKey(const Key('org_role_defaults_tier_selector')), findsOneWidget);
    expect(find.text('Foster Admin'), findsOneWidget);
    expect(find.text('Pet Admin'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Team Admin'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Team Admin'), findsOneWidget);
  });

  testWidgets('super admin tier is read-only', (tester) async {
    await pumpScreen(tester, _RoleDefaultsRepo());

    await tester.tap(find.text('Super Admin'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Super Admin defaults come from the platform baseline and cannot be changed per organisation.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('org_role_defaults_save')), findsNothing);
    final switchFinder = find.byKey(const Key('org_role_default_manage_fosters'));
    if (switchFinder.evaluate().isNotEmpty) {
      final switchWidget = tester.widget<SwitchListTile>(switchFinder.first);
      expect(switchWidget.onChanged, isNull);
    }
  });

  testWidgets('save shows confirmation and persists associate defaults', (
    tester,
  ) async {
    final repo = _RoleDefaultsRepo();
    await pumpScreen(tester, repo);

    await tester.tap(find.byKey(const Key('org_role_default_manage_fosters')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('org_role_defaults_save')));
    await tester.pumpAndSettle();

    expect(find.text('Apply organisation-wide?'), findsOneWidget);
    await tester.tap(find.text('Save defaults').last);
    await tester.pumpAndSettle();

    expect(repo.saveCalls, hasLength(1));
    expect(repo.saveCalls.first['tier'], 'associate');
    expect(
      (repo.saveCalls.first['grantedKeys'] as List).cast<String>(),
      contains('manage_fosters'),
    );
    expect(find.textContaining('Default permissions updated'), findsOneWidget);
  });
}
