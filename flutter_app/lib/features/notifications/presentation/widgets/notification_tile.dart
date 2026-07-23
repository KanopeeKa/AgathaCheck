import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/app_notification.dart';

/// Single notification row in the notifications list.
class NotificationTile extends ConsumerWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final xp = context.experienceColors;
    final isUnread = !notification.isRead;

    IconData icon;
    Color iconColor;

    final hasOrg =
        notification.organizationId != null &&
        notification.organizationId!.isNotEmpty;
    final hasPet = notification.petId != null && notification.petId!.isNotEmpty;
    final isOrgOnly = hasOrg && !hasPet;

    switch (notification.type) {
      case NotificationType.overdue:
        icon = Icons.warning_amber_rounded;
        iconColor = theme.colorScheme.error;
        break;
      case NotificationType.dueSoon:
        icon = Icons.schedule;
        iconColor = Colors.orange;
        break;
      case NotificationType.reminder:
        icon = Icons.schedule;
        iconColor = theme.colorScheme.primary;
        break;
      case NotificationType.completed:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.general:
        icon = isOrgOnly ? Icons.business : Icons.notifications;
        iconColor = isOrgOnly
            ? xp.organizationPrimary
            : theme.colorScheme.primary;
        break;
    }

    final pets = ref.watch(petListProvider).valueOrNull ?? [];
    final pet = notification.petId != null
        ? pets.where((p) => p.id == notification.petId).firstOrNull
        : null;
    final petColor = pet?.colorValue != null ? Color(pet!.colorValue!) : null;

    final tileColor = isUnread
        ? theme.colorScheme.primaryContainer.withAlpha(40)
        : null;
    final stripColor = petColor ?? theme.colorScheme.outlineVariant;

    return MergeSemantics(
      child: Semantics(
        label:
            '${notification.type.label} notification: ${notification.title}, ${formatNotificationRelativeTime(notification.createdAt)}${isUnread ? ', unread' : ''}${notification.petName != null ? ', pet: ${notification.petName}' : ''}',
        child: InkWell(
          onTap: onTap,
          child: Container(
            color: tileColor,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: stripColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: iconColor.withAlpha(30),
                              child: ExcludeSemantics(
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (notification.petName != null &&
                                    notification.petName!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.pets,
                                          size: 13,
                                          color:
                                              petColor ??
                                              theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          notification.petName!,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                color:
                                                    petColor ??
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  notification.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  notification.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                formatNotificationRelativeTime(
                                  notification.createdAt,
                                ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (isUnread)
                                ExcludeSemantics(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatNotificationRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m ago';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  } else {
    return DateFormat.Hm().format(dateTime);
  }
}
