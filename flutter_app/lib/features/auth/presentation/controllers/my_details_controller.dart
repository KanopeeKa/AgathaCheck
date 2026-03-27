import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_service.dart';
import '../providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class MyDetailsController extends StateNotifier<MyDetailsState> {
  MyDetailsController(this.ref) : super(MyDetailsState());

  final Ref ref;

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String category,
    required String bio,
    Uint8List? photoBytes,
    String? photoFilename,
  }) async {
    if (photoBytes != null && photoFilename != null) {
      await ref.read(authProvider.notifier).uploadPhoto(photoBytes, photoFilename);
    }
    await ref.read(authProvider.notifier).updateProfile(
      firstName: firstName,
      lastName: lastName,
      category: category,
      bio: bio,
    );
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final msg = await ref.read(authProvider.notifier).changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return msg;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}

class MyDetailsState {
  // Add any state fields needed for the UI
}
