import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../data/auth_service.dart';

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

  const AuthState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null && accessToken != null;

  AuthState copyWith({
    AuthUser? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      accessToken: clearUser ? null : (accessToken ?? this.accessToken),
      refreshToken: clearUser ? null : (refreshToken ?? this.refreshToken),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final SharedPreferences _prefs;

  AuthNotifier(this._authService, this._prefs) : super(const AuthState()) {
    _loadSavedSession();
  }

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  Future<void> _loadSavedSession() async {
    final accessToken = _prefs.getString(_accessTokenKey);
    final refreshToken = _prefs.getString(_refreshTokenKey);

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
          await _prefs.setString(_accessTokenKey, newAccess);
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
    String name = '',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authService.signup(
          email: email, password: password, name: name);
      await _saveTokens(result.accessToken, result.refreshToken);
      state = AuthState(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result =
          await _authService.login(email: email, password: password);
      await _saveTokens(result.accessToken, result.refreshToken);
      state = AuthState(
        user: result.user,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
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
    String? name,
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
        name: name,
        firstName: firstName,
        lastName: lastName,
        category: category,
        bio: bio,
        locale: locale,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
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
          isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
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
        await _prefs.setString(_accessTokenKey, newAccess);
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

  Future<void> _saveTokens(String access, String refresh) async {
    await _prefs.setString(_accessTokenKey, access);
    await _prefs.setString(_refreshTokenKey, refresh);
  }

  Future<void> _clearTokens() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(authService, prefs);
});
