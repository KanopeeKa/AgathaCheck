import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet.dart';
import '../providers/pet_providers.dart';

class NeuterReminderController {
  final WidgetRef ref;
  NeuterReminderController(this.ref);

  Future<void> dismissNeuterReminder(Pet pet) async {
    final updated = pet.copyWith(neuterDismissed: true);
    await ref.read(petListProvider.notifier).updatePet(updated);
  }
}
