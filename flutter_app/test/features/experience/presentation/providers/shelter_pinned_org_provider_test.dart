import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/data/auth_service.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/shelter_pinned_org_provider.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/organization_providers.dart';

import '../../../../helpers/fakes.dart';

class _PinnedOrgListNotifier extends OrganizationListNotifier {
  @override
  Future<List<Organization>> build() async => const [
    Organization(
      id: 'org-pin',
      name: 'Pinned Shelter',
      type: OrganizationType.charity,
      logoUrl: 'https://example.com/logo.png',
    ),
    Organization(
      id: 'org-other',
      name: 'Other Shelter',
      type: OrganizationType.charity,
    ),
  ];
}

class _PinnedAuthNotifier extends AuthNotifier {
  _PinnedAuthNotifier({String? pinnedOrganizationId})
    : super(FakeAuthService(), PrefsTokenStore(FakePrefs())) {
    state = AuthState(
      user: AuthUser(
        id: 'user-1',
        email: 'test@example.com',
        pinnedOrganizationId: pinnedOrganizationId,
      ),
      accessToken: 'token',
      refreshToken: 'refresh',
    );
  }
}

void main() {
  group('shelterPinnedOrgIdFromAuthUser', () {
    test('returns null when user is null', () {
      expect(shelterPinnedOrgIdFromAuthUser(null), isNull);
    });

    test('returns null when pin is unset', () {
      expect(
        shelterPinnedOrgIdFromAuthUser(AuthUser(id: 'u1', email: 'a@b.com')),
        isNull,
      );
    });

    test('returns pin id from auth user', () {
      expect(
        shelterPinnedOrgIdFromAuthUser(
          AuthUser(id: 'u1', email: 'a@b.com', pinnedOrganizationId: 'org-pin'),
        ),
        'org-pin',
      );
    });
  });

  group('shelterPinnedOrganizationProvider', () {
    test('resolves pinned org metadata from membership list', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => _PinnedAuthNotifier(pinnedOrganizationId: 'org-pin'),
          ),
          organizationListProvider.overrideWith(_PinnedOrgListNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(organizationListProvider.future);

      final pinned = container.read(shelterPinnedOrganizationProvider);
      expect(pinned, isNotNull);
      expect(pinned!.id, 'org-pin');
      expect(pinned.name, 'Pinned Shelter');
      expect(pinned.logoUrl, 'https://example.com/logo.png');
    });

    test('returns null when pin id is not in membership list', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => _PinnedAuthNotifier(pinnedOrganizationId: 'missing-org'),
          ),
          organizationListProvider.overrideWith(_PinnedOrgListNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(organizationListProvider.future);

      expect(container.read(shelterPinnedOrganizationProvider), isNull);
    });

    test('shelterPinnedOrgIdProvider mirrors auth pin', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(
            (ref) => _PinnedAuthNotifier(pinnedOrganizationId: 'org-pin'),
          ),
          organizationListProvider.overrideWith(_PinnedOrgListNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(shelterPinnedOrgIdProvider), 'org-pin');
    });
  });
}
