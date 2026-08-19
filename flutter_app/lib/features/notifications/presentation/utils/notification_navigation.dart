import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_kind.dart';

/// Navigates from a notification tap to the appropriate destination.
///
/// Care notifications with a health entry open the view-entry screen.
/// Administrative pending-object types open the pending-actions surface.
void navigateFromNotification(
  BuildContext context,
  AppNotification notification,
) {
  final wireType = notification.wireType;

  switch (wireType) {
    case 'pendingFosterPlacementReceived':
      context.go('/pending-actions?focus=foster');
      return;
    case 'pendingAdoptionPlacementReceived':
      context.go('/pending-actions?focus=adoption');
      return;
    case 'pendingCustodyTransferReceived':
      context.go('/pending-actions?focus=custody');
      return;
    case 'pendingShareReceived':
      context.go('/pending-actions?focus=share');
      return;
    case 'fosterRequestReceived':
      final orgId = notification.organizationId;
      final requestId = notification.healthEntryId;
      if (orgId != null &&
          orgId.isNotEmpty &&
          requestId != null &&
          requestId.isNotEmpty) {
        context.go('/o/orgs/$orgId/foster-requests/$requestId/respond');
        return;
      }
      if (orgId != null && orgId.isNotEmpty) {
        context.go('/o/orgs/$orgId/foster-requests');
        return;
      }
      context.go('/pending-actions');
      return;
  }

  final petId = notification.petId;
  final entryId = notification.healthEntryId;

  if (petId != null && petId.isNotEmpty) {
    if (entryId != null &&
        entryId.isNotEmpty &&
        notification.kind != NotificationKind.administrative) {
      context.go('/pet/$petId/events/$entryId');
      return;
    }
    context.go('/pet/$petId');
    return;
  }

  final organizationId = notification.organizationId;
  if (organizationId != null && organizationId.isNotEmpty) {
    context.go('/o/orgs/$organizationId');
    return;
  }
}
