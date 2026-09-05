import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import 'shelter_task_item.dart';
import 'shelter_tasks_preview.dart';

class ShelterTaskRow extends StatelessWidget {
  const ShelterTaskRow({super.key, required this.task, required this.l});

  final ShelterTaskItem task;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = shelterTaskTitle(l, task);
    final subtitle = shelterTaskSubtitle(l, task);

    if (task.isPendingInvite && task.invite != null) {
      return Padding(
        key: Key('shelter_task_row_${task.id}'),
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (task.invite!.inviterName.isNotEmpty ||
                task.invite!.inviterEmail.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                l.invitedBy(
                  task.invite!.inviterName.isNotEmpty
                      ? task.invite!.inviterName
                      : task.invite!.inviterEmail,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            ShelterTaskInviteActions(invite: task.invite!, l: l),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          key: Key('shelter_task_row_${task.id}'),
          contentPadding: EdgeInsets.zero,
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(task.routePath),
        ),
      ),
    );
  }
}
