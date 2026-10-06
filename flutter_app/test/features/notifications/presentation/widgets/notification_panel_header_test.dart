import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/notifications/presentation/widgets/notification_panel_header.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  testWidgets('NotificationPanelHeader mark all read', (tester) async {
    var marked = false;
    late AppLocalizations l;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l = AppLocalizations.of(context)!;
            return Scaffold(
              body: NotificationPanelHeader(
                l: l,
                theme: Theme.of(context),
                onMarkAllRead: () => marked = true,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l.markAllRead));
    expect(marked, isTrue);
  });
}
