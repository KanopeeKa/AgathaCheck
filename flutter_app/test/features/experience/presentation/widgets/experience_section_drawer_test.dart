import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_profile_app/core/providers/shared_preferences_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/experience_section_drawer.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/fakes.dart';

class _EmptyOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('drawer shows close control and section destinations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'show_organisation_section': true});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          activeExperienceProvider.overrideWith(
            (ref) => AppExperience.guardian,
          ),
          organizationListProvider.overrideWith(_EmptyOrgListNotifier.new),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            drawer: const ExperienceSectionDrawer(),
            body: const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('drawer_close')), findsOneWidget);
    expect(find.byKey(const Key('drawer_guardian')), findsOneWidget);
    expect(find.byKey(const Key('drawer_organisation')), findsOneWidget);
    expect(find.byKey(const Key('drawer_account')), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Agatha Track'), findsNothing);
    expect(find.byType(UserAccountsDrawerHeader), findsNothing);
  });
}
