import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/auth_http_client.dart';
import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/auth_service.dart';
import '../../data/token_store.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return AuthService(baseUrl: baseUrl);
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
  final AuthService _authService;
  final TokenStore _tokenStore;

  AuthNotifier(this._authService, this._tokenStore) : super(const AuthState()) {
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    final accessToken = await _tokenStore.readAccessToken();
    final refreshToken = await _tokenStore.readRefreshToken();

    if (accessToken != null && refreshToken != null) {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        final user = await _authService.getMe(accessToken);
        state = AuthState(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      } catch (_) {
        try {
          final newAccess = await _authService.refreshToken(refreshToken);
          final user = await _authService.getMe(newAccess);
          await _tokenStore.writeAccessToken(newAccess);
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
      final result = await _authService.signup(
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
      // Debug print for error
      // ignore: avoid_print
      print('[Signup Error] Raw: ' + e.toString());
      // User-friendly error mapping
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
      final result = await _authService.login(email: email, password: password);
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
    if (state.refreshToken != null) {
      try {
        await _authService.logout(state.refreshToken!);
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
  }) async {
    if (state.accessToken == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.updateMe(
        state.accessToken!,
        firstName: firstName,
        lastName: lastName,
        category: category,
        bio: bio,
        locale: locale,
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
    if (state.accessToken == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.uploadPhoto(
        state.accessToken!,
        bytes,
        filename,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.accessToken == null) throw Exception('Not authenticated');
    final msg = await _authService.changePassword(
      state.accessToken!,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    await _clearTokens();
    state = const AuthState();
    return msg;
  }

  Future<String?> getValidAccessToken() async {
    if (state.accessToken == null || state.refreshToken == null) return null;
    try {
      await _authService.getMe(state.accessToken!);
      return state.accessToken;
    } catch (_) {
      try {
        final newAccess = await _authService.refreshToken(state.refreshToken!);
        await _tokenStore.writeAccessToken(newAccess);
        final user = await _authService.getMe(newAccess);
        state = AuthState(
          user: user,
          accessToken: newAccess,
          refreshToken: state.refreshToken,
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

  /// Forces a single access-token refresh using the stored refresh token,
  /// returning the new token or `null` if the session can no longer be
  /// refreshed. Concurrent callers share one in-flight refresh so a burst of
  /// 401s only triggers one network round-trip. On failure the session is
  /// cleared and [AuthState.sessionExpired] is set so the UI can react.
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
      final newAccess = await _authService.refreshToken(refreshToken);
      await _tokenStore.writeAccessToken(newAccess);
      state = state.copyWith(accessToken: newAccess);
      return newAccess;
    } catch (_) {
      await _clearTokens();
      state = const AuthState(sessionExpired: true);
      return null;
    }
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _tokenStore.writeTokens(access, refresh);
  }

  Future<void> _clearTokens() async {
    await _tokenStore.clear();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  // Secure storage on mobile; SharedPreferences on web/desktop/tests.
  return AuthNotifier(authService, createTokenStore(prefs));
});

/// A shared [http.Client] that auto-injects the current access token and, on a
/// 401, refreshes the token once and replays the request. Inject this into all
/// authenticated remote data sources so sessions survive access-token expiry
/// without the user being silently logged out.
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
