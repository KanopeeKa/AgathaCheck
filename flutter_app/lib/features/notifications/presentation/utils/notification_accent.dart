import 'package:flutter/material.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../domain/entities/notification_scope.dart';

/// Plum vs green cues for notification lists (navigation v2).
class NotificationAccent {
  const NotificationAccent({
    required this.scope,
    required this.primary,
    required this.onPrimary,
    required this.unreadSurface,
  });

  final NotificationScope scope;
  final Color primary;
  final Color onPrimary;

  /// Subtle unread row fill — paired with [primary] unread dot.
  final Color unreadSurface;

  bool get isOrganization => scope == NotificationScope.organization;
}

NotificationAccent resolveNotificationAccent(
  BuildContext context,
  NotificationScope scope,
) {
  final xp = context.experienceColors;
  switch (scope) {
    case NotificationScope.organization:
      return NotificationAccent(
        scope: scope,
        primary: xp.organizationPrimary,
        onPrimary: xp.organizationOnPrimary,
        unreadSurface: xp.organizationLight.withAlpha(120),
      );
    case NotificationScope.guardian:
      return NotificationAccent(
        scope: scope,
        primary: xp.guardianPrimary,
        onPrimary: xp.guardianOnPrimary,
        unreadSurface: xp.guardianLight.withAlpha(120),
      );
  }
}
