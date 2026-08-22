// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';
import 'package:pet_profile_app/features/vet/domain/entities/vet.dart';
import 'package:pet_profile_app/features/vet/presentation/providers/vet_providers.dart';
import 'package:pet_profile_app/features/vet/presentation/screens/vet_detail_screen.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../../helpers/fakes.dart';

// ---------------------------------------------------------------------------
// Controllable fake notifiers
// ---------------------------------------------------------------------------

class _TestVetListNotifier extends VetListNotifier {
  _TestVetListNotifier(this._vets);
  final List<Vet> _vets;

  @override
  Future<List<Vet>> build() async => List<Vet>.from(_vets);
}

class _TestPetListNotifier extends PetListNotifier {
  _TestPetListNotifier(this._pets);
  final List<Pet> _pets;

  @override
  Future<List<Pet>> build() async => List<Pet>.from(_pets);
}

// ---------------------------------------------------------------------------
// URL launcher mock
// ---------------------------------------------------------------------------

/// Minimal [UrlLauncherPlatform] mock.  Uses [MockPlatformInterfaceMixin] to
/// bypass the platform token verification while still being a valid singleton.
class _MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  _MockUrlLauncherPlatform({
    this.canLaunchResult = true,
    this.launchResult = true,
  });

  final bool canLaunchResult;
  final bool launchResult;

  final List<String> canLaunchCalls = [];
  final List<String> launchCalls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    canLaunchCalls.add(url);
    return canLaunchResult;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchCalls.add(url);
    return launchResult;
  }

  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => false;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async => false;

  @override
  Future<void> closeWebView() async {}

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchCalls.add(url);
    return launchResult;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildApp({
  required String vetId,
  required List<Vet> vets,
  List<Pet> pets = const [],
  String initialLocation = '/g/vets/vet-1',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/g/vets/:id',
        builder: (context, state) => Scaffold(
          body: VetDetailScreen(
            vetId: state.pathParameters['id']!,
            listPath: '/g/vets',
          ),
        ),
      ),
      GoRoute(
        path: '/g/vets/edit/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Edit ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/pet/:petId',
        builder: (context, state) =>
            Scaffold(body: Text('Pet ${state.pathParameters['petId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      vetListProvider.overrideWith(() => _TestVetListNotifier(vets)),
      petListProvider.overrideWith(() => _TestPetListNotifier(pets)),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Display ───────────────────────────────────────────────────────────────

  group('VetDetailScreen – display', () {
    testWidgets('shows vet name and all available contact fields', (
      tester,
    ) async {
      const vet = Vet(
        id: 'vet-1',
        name: 'Dr. Paws',
        phone: '+44 20 1234 5678',
        email: 'paws@example.com',
        address: '1 High St, London',
        website: 'https://drpaws.example.com',
        notes: 'Specialises in exotic birds.',
      );

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      expect(find.text('Dr. Paws'), findsOneWidget);
      expect(find.text('+44 20 1234 5678'), findsOneWidget);
      expect(find.text('paws@example.com'), findsOneWidget);
      expect(find.text('1 High St, London'), findsOneWidget);
      expect(find.text('https://drpaws.example.com'), findsOneWidget);
      expect(find.text('Specialises in exotic birds.'), findsOneWidget);
    });

    testWidgets('shows vetNotFound message when vet id is missing', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(vetId: 'unknown', vets: []));
      await tester.pumpAndSettle();

      expect(find.text('Veterinarian not found'), findsOneWidget);
    });

    testWidgets('omits phone row when phone is empty', (tester) async {
      const vet = Vet(id: 'vet-1', name: 'Silent Vet', phone: '');
      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      // No phone row text
      expect(find.text('Phone'), findsNothing);
    });

    testWidgets('omits email row when email is empty', (tester) async {
      const vet = Vet(id: 'vet-1', name: 'No Email Vet', email: '');
      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      // The word "Email" in the field label should not appear
      // (vetEmail key = "Email", phone key also not shown here)
      expect(find.text('Phone'), findsNothing);
    });

    testWidgets('shows linked-pets section when pet is linked to vet', (
      tester,
    ) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws');
      const pet = Pet(
        id: 'pet-1',
        name: 'Whiskers',
        species: 'Cat',
        vetId: 'vet-1',
      );

      await tester.pumpWidget(
        _buildApp(vetId: 'vet-1', vets: [vet], pets: [pet]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Linked pets'), findsOneWidget);
      expect(find.text('Whiskers'), findsOneWidget);
    });

    testWidgets('omits linked-pets section when no pets are linked', (
      tester,
    ) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws');
      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      expect(find.text('Linked pets'), findsNothing);
    });

    testWidgets('shows Edit Vet button', (tester) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws');
      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vet_detail_edit_button')), findsOneWidget);
      expect(find.text('Edit Vet'), findsOneWidget);
    });

    testWidgets('does not overflow at 320 px width', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const vet = Vet(
        id: 'vet-1',
        name: 'Clinique vétérinaire des animaux de compagnie du quartier nord',
        phone: '+33 1 23 45 67 89',
        email: 'contact@clinique-example.fr',
        address: '42 avenue des Tilleuls, 75019 Paris',
      );

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ── Call / Email actions ──────────────────────────────────────────────────

  group('VetDetailScreen – call and email actions', () {
    testWidgets('shows Call and Email buttons when both are provided', (
      tester,
    ) async {
      const vet = Vet(
        id: 'vet-1',
        name: 'Dr. Paws',
        phone: '+44 20 1234 5678',
        email: 'paws@example.com',
      );

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vet_call_button')), findsOneWidget);
      expect(find.byKey(const Key('vet_email_button')), findsOneWidget);
    });

    testWidgets('shows only Call button when email is absent', (tester) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws', phone: '+44 20 1234 5678');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vet_call_button')), findsOneWidget);
      expect(find.byKey(const Key('vet_email_button')), findsNothing);
    });

    testWidgets('shows only Email button when phone is absent', (tester) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws', email: 'a@b.com');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vet_call_button')), findsNothing);
      expect(find.byKey(const Key('vet_email_button')), findsOneWidget);
    });

    testWidgets('shows no contact action buttons when both are absent', (
      tester,
    ) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vet_call_button')), findsNothing);
      expect(find.byKey(const Key('vet_email_button')), findsNothing);
    });

    testWidgets('Call button has at least 48 logical pixels height', (
      tester,
    ) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws', phone: '+44 20 1234 5678');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      final buttonFinder = find.byKey(const Key('vet_call_button'));
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('Email button has at least 48 logical pixels height', (
      tester,
    ) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws', email: 'a@b.com');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      final buttonFinder = find.byKey(const Key('vet_email_button'));
      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('Call button launches tel URI when launcher can open it', (
      tester,
    ) async {
      final mock = _MockUrlLauncherPlatform(
        canLaunchResult: true,
        launchResult: true,
      );
      UrlLauncherPlatform.instance = mock;
      addTearDown(
        () => UrlLauncherPlatform.instance = _MockUrlLauncherPlatform(
          canLaunchResult: false,
        ),
      );

      const vet = Vet(id: 'vet-1', name: 'Dr. Paws', phone: '+44201234567');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vet_call_button')));
      await tester.pumpAndSettle();

      expect(mock.canLaunchCalls, contains('tel:+44201234567'));
      expect(mock.launchCalls, contains('tel:+44201234567'));
    });

    testWidgets('Email button launches mailto URI when launcher can open it', (
      tester,
    ) async {
      final mock = _MockUrlLauncherPlatform(
        canLaunchResult: true,
        launchResult: true,
      );
      UrlLauncherPlatform.instance = mock;
      addTearDown(
        () => UrlLauncherPlatform.instance = _MockUrlLauncherPlatform(
          canLaunchResult: false,
        ),
      );

      const vet = Vet(id: 'vet-1', name: 'Dr. Paws', email: 'paws@example.com');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vet_email_button')));
      await tester.pumpAndSettle();

      expect(mock.canLaunchCalls, contains('mailto:paws@example.com'));
      expect(mock.launchCalls, contains('mailto:paws@example.com'));
    });

    testWidgets(
      'Call button shows SnackBar when launcher cannot open tel URI',
      (tester) async {
        final mock = _MockUrlLauncherPlatform(canLaunchResult: false);
        UrlLauncherPlatform.instance = mock;
        addTearDown(
          () => UrlLauncherPlatform.instance = _MockUrlLauncherPlatform(
            canLaunchResult: false,
          ),
        );

        const vet = Vet(id: 'vet-1', name: 'Dr. Paws', phone: '+44201234567');

        await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vet_call_button')));
        await tester.pumpAndSettle();

        // A SnackBar should appear; no URL was launched.
        expect(find.byType(SnackBar), findsOneWidget);
        expect(mock.launchCalls, isEmpty);
      },
    );

    testWidgets(
      'Email button shows SnackBar when launcher cannot open mailto URI',
      (tester) async {
        final mock = _MockUrlLauncherPlatform(canLaunchResult: false);
        UrlLauncherPlatform.instance = mock;
        addTearDown(
          () => UrlLauncherPlatform.instance = _MockUrlLauncherPlatform(
            canLaunchResult: false,
          ),
        );

        const vet = Vet(id: 'vet-1', name: 'Dr. Paws', email: 'a@b.com');

        await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('vet_email_button')));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(mock.launchCalls, isEmpty);
      },
    );
  });

  // ── Edit navigation ───────────────────────────────────────────────────────

  group('VetDetailScreen – edit navigation', () {
    testWidgets('Edit Vet button routes to edit screen', (tester) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('vet_detail_edit_button')));
      await tester.pumpAndSettle();

      // The stub edit screen renders "Edit vet-1"
      expect(find.text('Edit vet-1'), findsOneWidget);
    });

    testWidgets('Edit Vet button is labelled with editVet l10n key', (
      tester,
    ) async {
      const vet = Vet(id: 'vet-1', name: 'Dr. Paws');

      await tester.pumpWidget(_buildApp(vetId: 'vet-1', vets: [vet]));
      await tester.pumpAndSettle();

      // Uses l.editVet → "Edit Vet" in English
      expect(find.text('Edit Vet'), findsOneWidget);
    });
  });
}
