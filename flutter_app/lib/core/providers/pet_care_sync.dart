import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cross-feature refresh after weight or care mutations (D-WM-016).
abstract class PetCareSync {
  Future<void> weightChanged(String petId);
  Future<void> careChanged(String petId);
}

class NoopPetCareSync implements PetCareSync {
  const NoopPetCareSync();

  @override
  Future<void> weightChanged(String petId) async {}

  @override
  Future<void> careChanged(String petId) async {}
}

final petCareSyncProvider = Provider<PetCareSync>(
  (ref) => const NoopPetCareSync(),
);
