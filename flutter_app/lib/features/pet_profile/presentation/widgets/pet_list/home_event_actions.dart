import 'package:flutter/material.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';

/// Shared navigation helpers for due event cards.
class HomeEventActions {
  const HomeEventActions._();

  static void viewEntry(BuildContext context, HealthEntry entry) {
    final petId = entry.petId;
    if (petId.isEmpty) return;
    openPetEventView(context, petId: petId, entryId: entry.id);
  }

  /// Opens the read-only event view screen (not edit).
  @Deprecated('Use viewEntry')
  static void openEntry(BuildContext context, HealthEntry entry) =>
      viewEntry(context, entry);
}
