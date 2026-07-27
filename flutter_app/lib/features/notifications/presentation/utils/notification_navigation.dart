import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_notification.dart';

/// Navigates from a notification tap to the appropriate destination.
///
/// Care notifications with a health entry open the view-entry screen.
/// Other pet notifications fall back to the pet profile.
void navigateFromNotification(BuildContext context, AppNotification notification) {
  final petId = notification.petId;
  final entryId = notification.healthEntryId;

  if (petId != null && petId.isNotEmpty) {
    if (entryId != null && entryId.isNotEmpty) {
      context.go('/pet/$petId/events/$entryId');
      return;
    }
    context.go('/pet/$petId');
    return;
  }

  final organizationId = notification.organizationId;
  if (organizationId != null && organizationId.isNotEmpty) {
    context.go('/o/orgs/$organizationId');
  }
}
