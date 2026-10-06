import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/notifications/presentation/widgets/notification_panel_error_view.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('NotificationPanelErrorView retry', (tester) async {
    var retried = false;
    late AppLocalizations l;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l = AppLocalizations.of(context)!;
            return Scaffold(
              body: NotificationPanelErrorView(
                error: Exception('network'),
                l: l,
                theme: Theme.of(context),
                onRetry: () => retried = true,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.retry));
    expect(retried, isTrue);
  });
}
