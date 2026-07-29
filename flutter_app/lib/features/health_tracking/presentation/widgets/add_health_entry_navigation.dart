import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigates to the unified health-entry add form (all four event types).
///
/// When [petId] is set, opens the pet-scoped form; otherwise the global
/// multi-pet form at `/health/add`.
void navigateToAddHealthEntry(BuildContext context, {String? petId}) {
  if (petId != null) {
    context.push('/pet/$petId/health/add');
  } else {
    context.push('/health/add');
  }
}
