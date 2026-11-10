import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/core/widgets/async_state/async_state.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  // Bounded pumps: progress indicators animate forever.
  await tester.pump();
}

void main() {
  group('AsyncErrorState', () {
    testWidgets('shows localized defaults and a Retry that calls back', (
      tester,
    ) async {
      var retries = 0;
      await _pump(
        tester,
        AsyncErrorState(
          onRetry: () => retries++,
          retryKey: const Key('test_retry'),
        ),
      );

      expect(find.text("We couldn't load this"), findsOneWidget);
      expect(find.text('Check your connection and try again.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('test_retry')));
      expect(retries, 1);
    });

    testWidgets('uses the caller title and detail', (tester) async {
      await _pump(
        tester,
        AsyncErrorState(
          title: "We couldn't load your pets",
          detail: 'Detail line',
          onRetry: () {},
        ),
      );

      expect(find.text("We couldn't load your pets"), findsOneWidget);
      expect(find.text('Detail line'), findsOneWidget);
    });

    testWidgets('hides Retry when there is nothing to retry', (tester) async {
      await _pump(tester, const AsyncErrorState());

      expect(find.text('Retry'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('Retry meets the 48 dp touch target', (tester) async {
      await _pump(tester, AsyncErrorState(onRetry: () {}));

      final size = tester.getSize(find.byType(OutlinedButton));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    testWidgets('title is exposed as a live-region header', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, AsyncErrorState(onRetry: () {}));

      expect(
        tester.getSemantics(find.text("We couldn't load this")),
        matchesSemantics(
          label: "We couldn't load this",
          isHeader: true,
          isLiveRegion: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('is localized in French', (tester) async {
      await _pump(
        tester,
        AsyncErrorState(onRetry: () {}),
        locale: const Locale('fr'),
      );

      expect(find.text('Impossible de charger ce contenu'), findsOneWidget);
      expect(
        find.text('Vérifiez votre connexion et réessayez.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });

  group('LabelledProgress', () {
    testWidgets('defaults to the localized Loading label', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const LabelledProgress());

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      handle.dispose();
    });

    testWidgets('announces the caller label', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const LabelledProgress(label: 'Loading away plans'));

      expect(find.bySemanticsLabel('Loading away plans'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('can render inline without centring', (tester) async {
      await _pump(
        tester,
        const Row(children: [LabelledProgress(centered: false, size: 16)]),
      );

      expect(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(Center),
        ),
        findsNothing,
      );
    });
  });

  group('SupplementalStateCaption', () {
    testWidgets('loading shows the label and no Retry', (tester) async {
      await _pump(
        tester,
        SupplementalStateCaption(
          state: SupplementalState.loading,
          label: 'Tag filters loading',
          onRetry: () {},
        ),
      );

      expect(find.text('Tag filters loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('unavailable shows the label and a Retry that calls back', (
      tester,
    ) async {
      var retries = 0;
      await _pump(
        tester,
        SupplementalStateCaption(
          state: SupplementalState.unavailable,
          label: 'Tag filters unavailable',
          onRetry: () => retries++,
          retryKey: const Key('caption_retry'),
        ),
      );

      expect(find.text('Tag filters unavailable'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byKey(const Key('caption_retry')));
      expect(retries, 1);
      expect(
        tester.getSize(find.byKey(const Key('caption_retry'))).height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('unavailable without a callback shows no Retry', (
      tester,
    ) async {
      await _pump(
        tester,
        const SupplementalStateCaption(
          state: SupplementalState.unavailable,
          label: 'Care status unavailable',
        ),
      );

      expect(find.text('Care status unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
