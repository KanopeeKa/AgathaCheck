import 'dart:typed_data';

import '../domain/entities/auth_result.dart';
import '../domain/entities/auth_user.dart';
import '../domain/entities/delete_account_result.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_service.dart';

/// Data-layer [AuthRepository] — delegates to [AuthService] (HTTP transport).
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service);

  final AuthService _service;

  @override
  Future<AuthResult> signup({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) => _service.signup(
    email: email,
    password: password,
    firstName: firstName,
    lastName: lastName,
  );

  @override
  Future<AuthResult> login({required String email, required String password}) =>
      _service.login(email: email, password: password);

  @override
  Future<String> refreshToken(String refreshToken) =>
      _service.refreshToken(refreshToken);

  @override
  Future<void> logout(String refreshToken, {String? accessToken}) =>
      _service.logout(refreshToken, accessToken: accessToken);

  @override
  Future<AuthUser> getMe(String accessToken) => _service.getMe(accessToken);

  @override
  Future<AuthUser> updateMe(
    String accessToken, {
    String? firstName,
    String? lastName,
    String? category,
    String? bio,
    String? locale,
    String? timezone,
    String? weightUnit,
    String? pinnedOrganizationId,
    bool updatePinnedOrganizationId = false,
  }) => _service.updateMe(
    accessToken,
    firstName: firstName,
    lastName: lastName,
    category: category,
    bio: bio,
    locale: locale,
    timezone: timezone,
    weightUnit: weightUnit,
    pinnedOrganizationId: pinnedOrganizationId,
    updatePinnedOrganizationId: updatePinnedOrganizationId,
  );

  @override
  Future<AuthUser> uploadPhoto(
    String accessToken,
    Uint8List bytes,
    String filename,
  ) => _service.uploadPhoto(accessToken, bytes, filename);

  @override
  Future<String> changePassword(
    String accessToken, {
    required String currentPassword,
    required String newPassword,
  }) => _service.changePassword(
    accessToken,
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  @override
  Future<String> forgotPassword({required String email}) =>
      _service.forgotPassword(email: email);

  @override
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _service.resetPassword(
    email: email,
    code: code,
    newPassword: newPassword,
  );

  @override
  Future<DeleteAccountResult> deleteAccount(
    String accessToken, {
    required String password,
  }) => _service.deleteAccount(accessToken, password: password);

  @override
  Future<Map<String, dynamic>> exportData(String accessToken) =>
      _service.exportData(accessToken);
}
