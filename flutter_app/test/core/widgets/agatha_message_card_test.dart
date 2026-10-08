import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/agatha_message_card.dart';

void main() {
  testWidgets('AgathaMessageCard uses message surface and border', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AgathaMessageCard(child: Text('body'))),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    expect(card.color, AppColorTokens.agathaMessageSurface);
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.side.color, AppColorTokens.agathaMessageBorder);
  });

  testWidgets('themeSuggestionActions styles filled and text buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AgathaMessageCard(
            themeSuggestionActions: true,
            child: Column(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Accept')),
                TextButton(onPressed: () {}, child: const Text('Why')),
                OutlinedButton(onPressed: () {}, child: const Text('Why')),
              ],
            ),
          ),
        ),
      ),
    );

    final filledContext = tester.element(find.byType(FilledButton));
    expect(
      Theme.of(
        filledContext,
      ).filledButtonTheme.style?.backgroundColor?.resolve({}),
      AppColorTokens.agathaTealAction,
    );

    final textContext = tester.element(find.byType(TextButton));
    expect(
      Theme.of(textContext).textButtonTheme.style?.foregroundColor?.resolve({}),
      AppColorTokens.agathaTealAction,
    );

    final outlinedContext = tester.element(find.byType(OutlinedButton));
    expect(
      Theme.of(
        outlinedContext,
      ).outlinedButtonTheme.style?.foregroundColor?.resolve({}),
      AppColorTokens.agathaTealAction,
    );
  });
}
