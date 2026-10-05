import 'dart:typed_data';

import '../entities/auth_result.dart';
import '../entities/auth_user.dart';
import '../entities/delete_account_result.dart';

abstract class AuthRepository {
  Future<AuthResult> signup({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  });

  Future<AuthResult> login({required String email, required String password});

  Future<String> refreshToken(String refreshToken);

  Future<void> logout(String refreshToken, {String? accessToken});

  Future<AuthUser> getMe(String accessToken);

  Future<AuthUser> updateMe(
    String accessToken, {
    String? firstName,
    String? lastName,
    String? category,
    String? bio,
    String? locale,
    String? timezone,
    String? pinnedOrganizationId,
    bool updatePinnedOrganizationId = false,
  });

  Future<AuthUser> uploadPhoto(
    String accessToken,
    Uint8List bytes,
    String filename,
  );

  Future<String> changePassword(
    String accessToken, {
    required String currentPassword,
    required String newPassword,
  });

  Future<String> forgotPassword({required String email});

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<DeleteAccountResult> deleteAccount(
    String accessToken, {
    required String password,
  });

  Future<Map<String, dynamic>> exportData(String accessToken);
}
