import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/auth_http_client.dart';
import '../../../core/providers/api_base_url_provider.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../data/auth_repository_impl.dart';
import '../data/auth_service.dart';
import '../data/token_store.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/session_store.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return AuthService(baseUrl: baseUrl);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authServiceProvider));
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return createTokenStore(prefs);
});

class AuthState {
  final AuthUser? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  /// Set when a token refresh failed and the user was logged out mid-session.
  /// The UI uses this to show a "please sign in again" message.
  final bool sessionExpired;

  const AuthState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
    this.sessionExpired = false,
  });

  bool get isLoggedIn => user != null && accessToken != null;

  AuthState copyWith({
    AuthUser? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
    bool? sessionExpired,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      accessToken: clearUser ? null : (accessToken ?? this.accessToken),
      refreshToken: clearUser ? null : (refreshToken ?? this.refreshToken),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final SessionStore _sessionStore;

  AuthNotifier(this._authRepository, this._sessionStore)
    : super(const AuthState()) {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    if (kIsWeb) {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final newAccess = await _authRepository.refreshToken(
          kHttpOnlyRefreshSentinel,
        );
        final user = await _authRepository.getMe(newAccess);
        await _sessionStore.writeTokens(newAccess, kHttpOnlyRefreshSentinel);
        state = AuthState(
          user: user,
          accessToken: newAccess,
          refreshToken: kHttpOnlyRefreshSentinel,
        );
      } catch (_) {
        await _clearTokens();
        state = const AuthState();
      }
      return;
    }

    final accessToken = await _sessionStore.readAccessToken();
    final refreshToken = await _sessionStore.readRefreshToken();

    if (accessToken != null && refreshToken != null) {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final user = await _authRepository.getMe(accessToken);
        state = AuthState(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } catch (_) {
        try {
          final newAccess = await _authRepository.refreshToken(refreshToken);
          final user = await _authRepository.getMe(newAccess);
          await _sessionStore.writeAccessToken(newAccess);
          state = AuthState(
            user: user,
            accessToken: newAccess,
            refreshToken: refreshToken,
          );
        } catch (_) {
          await _clearTokens();
          state = const AuthState();
        }
      }
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepository.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      await _saveTokens(result.accessToken, result.refreshToken);
      state = AuthState(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
    } catch (e) {
      String msg = e.toString().replaceFirst('Exception: ', '');
      // ignore: avoid_print
      print('[Signup Error] Raw: ' + e.toString());
      if (msg.contains('Email already exists')) {
        msg = 'An account with this email already exists.';
      } else if (msg.contains('Email and password are required')) {
        msg = 'Please enter both email and password.';
      } else if (msg.contains('Signup failed')) {
        msg = 'Signup failed. Please try again.';
      }
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );
      await _saveTokens(result.accessToken, result.refreshToken);
      state = AuthState(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    final refreshToken = state.refreshToken;
    if (refreshToken != null || (kIsWeb && state.accessToken != null)) {
      try {
        await _authRepository.logout(
          refreshToken ?? kHttpOnlyRefreshSentinel,
          accessToken: state.accessToken,
        );
      } catch (_) {}
    }
    await _clearTokens();
    state = const AuthState();
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? category,
    String? bio,
    String? locale,
    String? timezone,
    String? weightUnit,
  }) async {
    if (state.accessToken == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.updateMe(
        state.accessToken!,
        firstName: firstName,
        lastName: lastName,
        category: category,
        bio: bio,
        locale: locale,
        timezone: timezone,
        weightUnit: weightUnit,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> updatePinnedOrganization(String? organizationId) async {
    if (state.accessToken == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.updateMe(
        state.accessToken!,
        pinnedOrganizationId: organizationId,
        updatePinnedOrganizationId: true,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> uploadPhoto(Uint8List bytes, String filename) async {
    if (state.accessToken == null) {
      throw Exception('Not authenticated');
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authRepository.uploadPhoto(
        state.accessToken!,
        bytes,
        filename,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: message);
      throw Exception(message);
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.accessToken == null) throw Exception('Not authenticated');
    final msg = await _authRepository.changePassword(
      state.accessToken!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _clearTokens();
    state = const AuthState();
    return msg;
  }

  Future<String> secureAccount({
    required String currentPassword,
    required String newPassword,
    String? notificationId,
  }) async {
    if (state.accessToken == null) throw Exception('Not authenticated');
    return _authRepository.secureAccount(
      state.accessToken!,
      currentPassword: currentPassword,
      newPassword: newPassword,
      notificationId: notificationId,
    );
  }

  Future<String?> getValidAccessToken() async {
    if (state.accessToken == null || state.refreshToken == null) return null;
    try {
      await _authRepository.getMe(state.accessToken!);
      return state.accessToken;
    } catch (_) {
      try {
        final newAccess = await _authRepository.refreshToken(
          state.refreshToken!,
        );
        await _sessionStore.writeAccessToken(newAccess);
        final user = await _authRepository.getMe(newAccess);
        final refreshToken = kIsWeb
            ? kHttpOnlyRefreshSentinel
            : state.refreshToken;
        state = AuthState(
          user: user,
          accessToken: newAccess,
          refreshToken: refreshToken,
        );
        return newAccess;
      } catch (_) {
        await _clearTokens();
        state = const AuthState();
        return null;
      }
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSessionExpired() {
    if (state.sessionExpired) {
      state = state.copyWith(sessionExpired: false);
    }
  }

  Future<String?>? _refreshFuture;

  Future<String?> forceRefreshAccessToken() {
    return _refreshFuture ??= _runForcedRefresh().whenComplete(
      () => _refreshFuture = null,
    );
  }

  Future<String?> _runForcedRefresh() async {
    final refreshToken = state.refreshToken;
    if (refreshToken == null) {
      await _clearTokens();
      state = const AuthState(sessionExpired: true);
      return null;
    }
    try {
      final newAccess = await _authRepository.refreshToken(refreshToken);
      await _sessionStore.writeAccessToken(newAccess);
      state = state.copyWith(
        accessToken: newAccess,
        refreshToken: kIsWeb ? kHttpOnlyRefreshSentinel : refreshToken,
      );
      return newAccess;
    } catch (_) {
      await _clearTokens();
      state = const AuthState(sessionExpired: true);
      return null;
    }
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _sessionStore.writeTokens(access, refresh);
  }

  Future<void> _clearTokens() async {
    await _sessionStore.clear();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final sessionStore = ref.watch(sessionStoreProvider);
  return AuthNotifier(authRepository, sessionStore);
});

final authHttpClientProvider = Provider<http.Client>((ref) {
  final client = AuthHttpClient(
    inner: http.Client(),
    getAccessToken: () => ref.read(authProvider).accessToken,
    refreshAccessToken: () =>
        ref.read(authProvider.notifier).forceRefreshAccessToken(),
  );
  ref.onDispose(client.close);
  return client;
});
