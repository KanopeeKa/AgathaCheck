import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/theme/app_theme.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/shelter_pinned_org_provider.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_screen_theme.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_membership_tile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const organizationWithoutPhoto = Organization(
    id: 'org-1',
    name: 'Rescue Hearts',
    type: OrganizationType.charity,
    memberCount: 3,
    petCount: 12,
  );

  const organizationWithMeta = Organization(
    id: 'org-2',
    name: 'Paws Haven',
    type: OrganizationType.charity,
    memberCount: 2,
    petCount: 8,
    bio: 'A calm foster-first rescue helping dogs find homes.',
    town: 'Bristol',
    publicProfileMetadata: {'postcode': 'BS1 4DJ'},
  );

  Future<void> pumpTile(
    WidgetTester tester,
    Widget tile, {
    AuthNotifier? authNotifier,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => authNotifier ?? _TestAuthNotifier(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: orgThemed(child: Scaffold(body: tile)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('org membership tile uses pet-grid aspect ratio', (tester) async {
    const tileWidth = 160.0;

    await pumpTile(
      tester,
      OrgMembershipTile(
        organization: organizationWithoutPhoto,
        tileWidth: tileWidth,
      ),
    );

    final sizedBox = tester.widget<SizedBox>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.width == tileWidth &&
            widget.height == OrgMembershipTile.tileHeightFor(tileWidth),
      ),
    );
    expect(sizedBox.width, tileWidth);
    expect(sizedBox.height, tileWidth * 1.5);
  });

  testWidgets('org membership tile without cover uses organizationPrimary', (
    tester,
  ) async {
    await pumpTile(
      tester,
      OrgMembershipTile(
        organization: organizationWithoutPhoto,
        tileWidth: 160,
      ),
    );

    final coloredBox = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const Key('org_membership_tile_org-1')),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(coloredBox.color, AppColorTokens.organizationPrimary);
  });

  testWidgets('org membership tile shows bio and town with postcode', (
    tester,
  ) async {
    await pumpTile(
      tester,
      OrgMembershipTile(
        organization: organizationWithMeta,
        tileWidth: 160,
      ),
    );

    expect(find.text('Paws Haven'), findsOneWidget);
    expect(find.text('Bristol, BS1 4DJ'), findsOneWidget);
    expect(
      find.text('A calm foster-first rescue helping dogs find homes.'),
      findsOneWidget,
    );
  });

  testWidgets('org membership tile shows pin button with unpinned tooltip', (
    tester,
  ) async {
    await pumpTile(
      tester,
      OrgMembershipTile(
        organization: organizationWithoutPhoto,
        tileWidth: 160,
      ),
    );

    expect(
      find.byKey(const Key('shelter_membership_pin_org-1')),
      findsNothing,
    );
    expect(
      find.bySemanticsIdentifier('shelter_membership_pin_org-1'),
      findsOneWidget,
    );

    final semantics = tester.getSemantics(
      find.bySemanticsIdentifier('shelter_membership_pin_org-1'),
    );
    expect(
      semantics.label,
      'Pin Rescue Hearts to navigation',
    );

    await tester.longPress(
      find.bySemanticsIdentifier('shelter_membership_pin_org-1'),
    );
    await tester.pumpAndSettle();
    expect(find.text(ShelterMembershipPinButton.unpinnedTooltip), findsOneWidget);
  });

  testWidgets('pin button toggles pinned org preference', (tester) async {
    final authNotifier = _TestAuthNotifier();

    await pumpTile(
      tester,
      OrgMembershipTile(
        organization: organizationWithoutPhoto,
        tileWidth: 160,
      ),
      authNotifier: authNotifier,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('shelter_membership_pin_org-1'));
    await tester.pumpAndSettle();

    expect(authNotifier.pinUpdates, ['org-1']);
    expect(authNotifier.state.user?.pinnedOrganizationId, 'org-1');

    await tester.tap(find.bySemanticsIdentifier('shelter_membership_pin_org-1'));
    await tester.pumpAndSettle();

    expect(authNotifier.pinUpdates, ['org-1', null]);
    expect(authNotifier.state.user?.pinnedOrganizationId, isNull);
  });

  testWidgets('pin button shows pinned state when org is pinned', (
    tester,
  ) async {
    await pumpTile(
      tester,
      Builder(
        builder: (context) {
          final pinId = ProviderScope.containerOf(
            context,
          ).read(shelterPinnedOrgIdProvider);
          expect(pinId, 'org-1');
          return OrgMembershipTile(
            organization: organizationWithoutPhoto,
            tileWidth: 160,
          );
        },
      ),
      authNotifier: _TestAuthNotifier(pinnedOrganizationId: 'org-1'),
    );
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(
      find.bySemanticsIdentifier('shelter_membership_pin_org-1'),
    );
    expect(
      semantics.label,
      'Rescue Hearts pinned to navigation',
    );

    await tester.longPress(
      find.bySemanticsIdentifier('shelter_membership_pin_org-1'),
    );
    await tester.pumpAndSettle();
    expect(find.text(ShelterMembershipPinButton.pinnedTooltip), findsOneWidget);
  });

  testWidgets('org membership tile uses equal cover and meta flex', (
    tester,
  ) async {
    await pumpTile(
      tester,
      OrgMembershipTile(
        organization: organizationWithoutPhoto,
        tileWidth: 160,
      ),
    );

    final tileColumn = tester.widget<Column>(
      find.descendant(
        of: find.byKey(const Key('org_membership_tile_org-1')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Column &&
              widget.children.length == 2 &&
              widget.children.every((child) => child is Expanded),
        ),
      ),
    );
    final expanded = tileColumn.children.cast<Expanded>();
    expect(expanded, hasLength(2));
    expect(expanded[0].flex, 1);
    expect(expanded[1].flex, 1);
  });
}

class _RecordingAuthService implements AuthService {
  @override
  Future<AuthUser> updateMe(
    String accessToken, {
    String? firstName,
    String? lastName,
    String? category,
    String? bio,
    String? locale,
    String? pinnedOrganizationId,
    bool updatePinnedOrganizationId = false,
  }) async {
    return AuthUser(
      id: 'test-user-id',
      email: 'test@example.com',
      pinnedOrganizationId: pinnedOrganizationId,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier({String? pinnedOrganizationId})
    : _service = _RecordingAuthService(),
      pinUpdates = [],
      super(_RecordingAuthService(), PrefsTokenStore(_FakePrefs())) {
    state = AuthState(
      user: AuthUser(
        id: 'test-user-id',
        email: 'test@example.com',
        pinnedOrganizationId: pinnedOrganizationId,
      ),
      accessToken: 'dummy-token',
      refreshToken: 'dummy-refresh',
    );
  }

  final _RecordingAuthService _service;
  final List<String?> pinUpdates;

  @override
  Future<void> updatePinnedOrganization(String? organizationId) async {
    pinUpdates.add(organizationId);
    final user = await _service.updateMe(
      state.accessToken!,
      pinnedOrganizationId: organizationId,
      updatePinnedOrganizationId: true,
    );
    state = state.copyWith(user: user, isLoading: false);
  }
}

class _FakePrefs implements SharedPreferences {
  final Map<String, Object?> _store = {};

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
