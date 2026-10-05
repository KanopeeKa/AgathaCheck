import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pet_profile_app/features/auth/application/auth_providers.dart';
import 'package:pet_profile_app/features/auth/data/token_store.dart';
import 'package:pet_profile_app/features/auth/domain/entities/auth_result.dart';
import 'package:pet_profile_app/features/auth/domain/entities/auth_user.dart';
import 'package:pet_profile_app/features/auth/domain/entities/delete_account_result.dart';
import 'package:pet_profile_app/features/auth/domain/repositories/auth_repository.dart';

/// H.1-3: AuthNotifier session flows via port fakes (F.4 delete-account behaviour).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier with fake AuthRepository', () {
    late FakeRecordingAuthRepository repository;
    late PrefsTokenStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      store = PrefsTokenStore(prefs);
      repository = FakeRecordingAuthRepository();
    });

    test('login persists tokens and user', () async {
      final notifier = AuthNotifier(repository, store);

      await notifier.login(email: 'a@b.c', password: 'secret');

      expect(notifier.state.isLoggedIn, isTrue);
      expect(notifier.state.user?.email, 'a@b.c');
      expect(await store.readAccessToken(), 'access-login');
      expect(await store.readRefreshToken(), 'refresh-login');
      expect(repository.loginCalls, 1);
    });

    test('logout clears session and calls repository', () async {
      final notifier = AuthNotifier(repository, store);
      await notifier.login(email: 'a@b.c', password: 'secret');

      await notifier.logout();

      expect(notifier.state.isLoggedIn, isFalse);
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
      expect(repository.logoutCalls, 1);
    });

    test('session restore loads user from stored tokens', () async {
      await store.writeTokens('stored-access', 'stored-refresh');
      repository.meUser = AuthUser(id: '1', email: 'stored@example.com');

      final notifier = AuthNotifier(repository, store);
      for (var i = 0; i < 100 && !notifier.state.isLoggedIn; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(notifier.state.user?.email, 'stored@example.com');
      expect(notifier.state.accessToken, 'stored-access');
      expect(repository.getMeCalls, greaterThanOrEqualTo(1));
    });

    test('deleteAccount via repository then logout clears state', () async {
      final notifier = AuthNotifier(repository, store);
      await notifier.login(email: 'a@b.c', password: 'secret');

      final result = await repository.deleteAccount(
        notifier.state.accessToken!,
        password: 'secret',
      );

      expect(result.accepted, isTrue);
      await notifier.logout();
      expect(notifier.state.isLoggedIn, isFalse);
    });
  });
}

class FakeRecordingAuthRepository implements AuthRepository {
  int loginCalls = 0;
  int logoutCalls = 0;
  int getMeCalls = 0;
  AuthUser? meUser;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    return AuthResult(
      user: AuthUser(id: '1', email: email),
      accessToken: 'access-login',
      refreshToken: 'refresh-login',
    );
  }

  @override
  Future<void> logout(String refreshToken, {String? accessToken}) async {
    logoutCalls++;
  }

  @override
  Future<AuthUser> getMe(String accessToken) async {
    getMeCalls++;
    return meUser ?? AuthUser(id: '1', email: 'a@b.c');
  }

  @override
  Future<DeleteAccountResult> deleteAccount(
    String accessToken, {
    required String password,
  }) async {
    return const DeleteAccountResult(
      message: 'Account deleted',
      operationId: 'op-1',
      accepted: true,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
