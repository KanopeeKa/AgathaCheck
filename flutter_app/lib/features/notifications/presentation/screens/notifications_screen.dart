import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).checkDueEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification Settings',
            onPressed: () => context.push('/notifications/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark All as Read',
            onPressed: () async {
              await ref
                  .read(notificationsProvider.notifier)
                  .markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load notifications: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('No notifications',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up! Notifications will appear\nwhen health entries are due.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final grouped = _groupByDate(notifications);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        group.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...group.notifications.map(
                      (n) => _NotificationTile(
                        notification: n,
                        onTap: () async {
                          if (!n.isRead) {
                            await ref
                                .read(notificationsProvider.notifier)
                                .markAsRead(n.id);
                          }
                          if (n.petId != null &&
                              n.petId!.isNotEmpty &&
                              context.mounted) {
                            context.go('/pet/${n.petId}');
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<_NotificationGroup> _groupByDate(List<AppNotification> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AppNotification>> groups = {};

    for (final n in notifications) {
      final date = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat.yMMMd().format(date);
      }
      groups.putIfAbsent(label, () => []).add(n);
    }

    return groups.entries
        .map((e) => _NotificationGroup(label: e.key, notifications: e.value))
        .toList();
  }
}

class _NotificationGroup {
  final String label;
  final List<AppNotification> notifications;

  _NotificationGroup({required this.label, required this.notifications});
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    IconData icon;
    Color iconColor;
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
        icon = Icons.notifications_active;
        iconColor = theme.colorScheme.primary;
        break;
      case NotificationType.general:
        icon = Icons.info_outline;
        iconColor = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withAlpha(30),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.message,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          if (notification.petName != null && notification.petName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                notification.petName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      tileColor:
          isUnread ? theme.colorScheme.primaryContainer.withAlpha(40) : null,
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dateTime) {
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
}
