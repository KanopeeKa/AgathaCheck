import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/organization_invite_by_email_dialog.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

class _InviteDialogHost extends ConsumerWidget {
  const _InviteDialogHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => showOrganizationInviteByEmailDialog(
            context: context,
            ref: ref,
            orgId: 'org-1',
          ),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('org invite dialog requires a valid email', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _InviteDialogHost(),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('org_invite_send')));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('org_invite_email')), 'not-an-email');
    await tester.tap(find.byKey(const Key('org_invite_send')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address'), findsOneWidget);
  });
}
