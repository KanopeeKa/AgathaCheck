import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/features/support/hub/hub.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

GoRouter _hubRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const ContactHubScreen()),
      GoRoute(
        path: '/contact/support',
        builder: (_, _) => const SupportIntakeFormScreen(),
      ),
    ],
  );
}

Future<void> _pumpHub(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _hubRouter(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ContactHubScreen shows cards and mailbox addresses', (
    tester,
  ) async {
    await _pumpHub(tester, const Locale('en'));
    final context = tester.element(find.byType(ContactHubScreen));
    final l = AppLocalizations.of(context)!;

    expect(find.text(l.contactHubTitle), findsOneWidget);
    expect(find.text(l.contactHubHelpSupportTitle), findsOneWidget);
    expect(find.text(l.contactHubPartnershipsTitle), findsOneWidget);
    expect(find.text(l.contactHubLegalPrivacyTitle), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(SupportContactEmails.contact),
      120,
    );
    expect(find.text(SupportContactEmails.support), findsWidgets);
    expect(find.text(SupportContactEmails.legal), findsWidgets);
    expect(find.text(SupportContactEmails.partnerships), findsWidgets);

    await tester.tap(find.byKey(const Key('contact_hub_help_support')));
    await tester.pumpAndSettle();
    expect(find.byType(SupportIntakeFormScreen), findsOneWidget);
  });

  testWidgets('ContactHubScreen French strings render', (tester) async {
    await _pumpHub(tester, const Locale('fr'));
    final context = tester.element(find.byType(ContactHubScreen));
    final l = AppLocalizations.of(context)!;

    expect(find.text(l.contactHubHelpSupportTitle), findsOneWidget);
    expect(l.contactHubHelpSupportTitle, 'Aide et assistance');
  });
}
