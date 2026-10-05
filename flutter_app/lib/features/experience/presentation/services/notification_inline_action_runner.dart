import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/features/auth/auth.dart';
import 'package:pet_profile_app/features/notifications/notifications.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/sharing/sharing.dart';

import '../../../../l10n/app_localizations.dart';

/// Experience-layer implementation of [NotificationInlineActions] (PR4).
class NotificationInlineActionRunner implements NotificationInlineActions {
  NotificationInlineActionRunner(this._ref);

  final WidgetRef _ref;

  @override
  Future<void> accept(
    BuildContext context,
    AppNotification notification,
  ) async {
    final kind = NotificationInlineActionSupport.kindFor(notification);
    if (kind == null) return;
    switch (kind) {
      case NotificationInlineActionKind.shareInvite:
        await _acceptShareInvite(context, notification);
      case NotificationInlineActionKind.householdInvite:
        _openInviteLanding(context, notification);
      case NotificationInlineActionKind.accountNewSignIn:
        await startSecureAccountFlow(context, notification);
    }
    await _ref.read(notificationsProvider.notifier).refresh();
    _ref.invalidate(petListProvider);
  }

  @override
  Future<void> confirmAccountSignInWasMe(
    BuildContext context,
    AppNotification notification,
  ) async {
    final token = _ref.read(authProvider).accessToken;
    if (token == null) throw Exception('Not authenticated');
    await _ref
        .read(notificationsProvider.notifier)
        .submitAccountSecurityFeedback(notification.id, 'this_was_me');
    await _ref.read(notificationsProvider.notifier).refresh();
  }

  @override
  Future<void> startSecureAccountFlow(
    BuildContext context,
    AppNotification notification,
  ) async {
    if (!context.mounted) return;
    final id = Uri.encodeComponent(notification.id);
    context.push('/secure-account?notificationId=$id');
  }

  @override
  Future<void> declineWithUndoSnackBar(
    BuildContext context,
    AppNotification notification,
  ) async {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    var undone = false;
    final done = Completer<void>();

    messenger.showSnackBar(
      SnackBar(
        content: Text(l.declineShare),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l.notificationInlineUndo,
          onPressed: () {
            undone = true;
            if (!done.isCompleted) done.complete();
          },
        ),
      ),
    );
    unawaited(
      Future<void>.delayed(const Duration(seconds: 5)).then((_) {
        if (!done.isCompleted) done.complete();
      }),
    );
    await done.future;
    if (undone || !context.mounted) return;

    await _declineImmediate(notification);
    await _ref.read(notificationsProvider.notifier).refresh();
  }

  Future<void> _declineImmediate(AppNotification notification) async {
    final kind = NotificationInlineActionSupport.kindFor(notification);
    if (kind == null) return;

    switch (kind) {
      case NotificationInlineActionKind.shareInvite:
        await _declineShareInvite(notification);
      case NotificationInlineActionKind.householdInvite:
        await _declineShareInvite(notification);
      case NotificationInlineActionKind.accountNewSignIn:
        return;
    }
  }

  Future<void> _acceptShareInvite(
    BuildContext context,
    AppNotification notification,
  ) async {
    final code = notification.healthEntryId;
    if (code == null || code.isEmpty) {
      throw Exception('Missing invite code');
    }
    final repo = _ref.read(sharingRepositoryProvider);
    final preview = await repo.getInvitePreview(code);
    if (!preview.isPending) {
      throw StaleNotificationException();
    }
    if (!context.mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _ShareInviteConfirmSheet(preview: preview),
    );
    if (confirmed != true || !context.mounted) return;

    final token = _ref.read(authProvider).accessToken;
    if (token == null) throw Exception('Not authenticated');
    await repo.acceptInviteByCode(code, token);
  }

  void _openInviteLanding(BuildContext context, AppNotification notification) {
    final code = notification.healthEntryId;
    if (code == null || code.isEmpty) return;
    context.go('/invite/$code');
  }

  Future<void> _declineShareInvite(AppNotification notification) async {
    final code = notification.healthEntryId;
    if (code == null || code.isEmpty) throw Exception('Missing invite code');
    final token = _ref.read(authProvider).accessToken;
    if (token == null) throw Exception('Not authenticated');
    final repo = _ref.read(sharingRepositoryProvider);
    final preview = await repo.getInvitePreview(code);
    if (!preview.isPending) throw StaleNotificationException();
    await repo.declineInvite(preview.inviteId, token);
  }
}

class _ShareInviteConfirmSheet extends StatelessWidget {
  const _ShareInviteConfirmSheet({required this.preview});

  final InvitePreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final roleLabel = preview.role.toWire();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.acceptShare, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${preview.inviterName} → ${preview.petNamesDisplay} ($roleLabel)',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.acceptShare),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
