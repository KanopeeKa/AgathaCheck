import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/organization_add_foster_parent_dialog.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';
import '../../helpers/organization_provider_test_helpers.dart';

class _AddFosterDialogHost extends ConsumerWidget {
  const _AddFosterDialogHost({required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showOrganizationAddFosterParentDialog(
            context: context,
            ref: ref,
            orgId: orgId,
          ),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('add external foster dialog requires display name and email', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            RecordingOrganizationRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _AddFosterDialogHost(orgId: 'org-1'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add foster parent'));
    await tester.pumpAndSettle();

    expect(find.text('Organisation name is required'), findsOneWidget);
    expect(
      find.text('Email is required so we can send a privacy notice'),
      findsOneWidget,
    );
  });

  testWidgets('add external foster dialog requires lawful basis confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          organizationRepositoryProvider.overrideWithValue(
            RecordingOrganizationRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _AddFosterDialogHost(orgId: 'org-1'),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Display name'),
      'Off-app Parent',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'off@example.com',
    );
    await tester.tap(find.text('Add foster parent'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please confirm you have a lawful basis to add this contact.'),
      findsOneWidget,
    );
  });
}
