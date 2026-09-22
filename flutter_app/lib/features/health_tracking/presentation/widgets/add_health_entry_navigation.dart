import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigates to the unified care add form (all event types).
///
/// When [petId] is set, opens the pet-scoped form; otherwise the global
/// multi-pet form at `/care/add`.
void navigateToAddHealthEntry(BuildContext context, {String? petId}) {
  if (petId != null) {
    context.push('/pet/$petId/care/add');
  } else {
    context.push('/care/add');
  }
}
