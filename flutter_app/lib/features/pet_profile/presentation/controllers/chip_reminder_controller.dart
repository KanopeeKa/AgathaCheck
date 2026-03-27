import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

class ChipReminderController {
  final WidgetRef ref;
  ChipReminderController(this.ref);

  Future<void> dismissChipReminder(Pet pet) async {
    final updated = pet.copyWith(chipDismissed: true);
    await ref.read(petListProvider.notifier).updatePet(updated);
  }
}
