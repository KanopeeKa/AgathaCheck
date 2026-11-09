import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/form/app_form_info_button.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('uses onSurfaceVariant and 48px minimum target', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppFormInfoButton(message: 'Help copy')),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.info_outline));
    final theme = AppTheme.lightTheme;
    expect(icon.color, theme.colorScheme.onSurfaceVariant);
    expect(icon.color, isNot(theme.colorScheme.outline));

    final iconButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(
      iconButton.style?.minimumSize?.resolve({}),
      const Size(48, 48),
    );
  });

  testWidgets('keyboard activates dialog', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppFormInfoButton(message: 'Neuter help')),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Neuter help'), findsWidgets);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
}
