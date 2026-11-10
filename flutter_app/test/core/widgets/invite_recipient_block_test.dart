import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_profile_app/core/widgets/invite_recipient_block.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('continue action opens landing with returnTo', (tester) async {
    final router = GoRouter(
      initialLocation: '/invite/testcode',
      routes: [
        GoRoute(
          path: '/invite/:code',
          builder: (context, state) => Scaffold(
            body: InviteRecipientBlock(
              invitePath: state.uri.path,
              inviterName: 'Jamie',
              petsSummary: 'Luna',
              scopeDescription: 'Carer',
            ),
          ),
        ),
        GoRoute(
          path: '/landing',
          builder: (context, state) =>
              Scaffold(body: Text('landing:${state.uri}')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invite_recipient_continue_account')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/landing');
    expect(router.state.uri.queryParameters['returnTo'], '/invite/testcode');
  });
}
