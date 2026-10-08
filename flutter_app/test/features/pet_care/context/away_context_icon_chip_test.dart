import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_care/presentation/widgets/away_context_icon_chip.dart';

void main() {
  testWidgets('AwayContextIconChip uses away context tokens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: AwayContextIconChip()),
      ),
    );

    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.color, AppColorTokens.awayContextSurface);

    final icon = tester.widget<Icon>(find.byIcon(Icons.event_busy_outlined));
    expect(icon.color, AppColorTokens.awayContextAccent);
  });
}
