import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../organization/presentation/providers/foster_placements_providers.dart';
import '../../../organization/presentation/providers/org_provider_custody.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../sharing/domain/entities/invite_preview.dart';
import '../../../sharing/domain/entities/pet_access.dart';
import '../../../sharing/presentation/providers/sharing_providers.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/services/notification_inline_action_support.dart';
import '../providers/notification_providers.dart';

/// Executes inline Accept / Decline for needs-response notifications (PR4).
class NotificationInlineActionRunner {
  NotificationInlineActionRunner(this.ref);

  final WidgetRef ref;

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
      case NotificationInlineActionKind.fosterPlacement:
        await _acceptFosterPlacement(notification);
      case NotificationInlineActionKind.adoptionPlacement:
        await _acceptAdoptionPlacement(notification);
      case NotificationInlineActionKind.custodyTransfer:
        await _acceptCustodyTransfer(notification);
    }
    await ref.read(notificationsProvider.notifier).refresh();
    ref.invalidate(petListProvider);
  }

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

    await _declineImmediate(context, notification);
    await ref.read(notificationsProvider.notifier).refresh();
  }

  Future<void> _declineImmediate(
    BuildContext context,
    AppNotification notification,
  ) async {
    final kind = NotificationInlineActionSupport.kindFor(notification);
    if (kind == null) return;

    switch (kind) {
      case NotificationInlineActionKind.shareInvite:
        await _declineShareInvite(notification);
      case NotificationInlineActionKind.householdInvite:
        _openInviteLanding(context, notification);
      case NotificationInlineActionKind.fosterPlacement:
        await _declineFosterPlacement(notification);
      case NotificationInlineActionKind.adoptionPlacement:
        await _declineAdoptionPlacement(notification);
      case NotificationInlineActionKind.custodyTransfer:
        await _declineCustodyTransfer(notification);
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
    final repo = ref.read(sharingRepositoryProvider);
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

    final token = ref.read(authProvider).accessToken;
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
    final token = ref.read(authProvider).accessToken;
    if (token == null) throw Exception('Not authenticated');
    final repo = ref.read(sharingRepositoryProvider);
    final preview = await repo.getInvitePreview(code);
    if (!preview.isPending) throw StaleNotificationException();
    await repo.declineInvite(preview.inviteId, token);
  }

  Future<void> _acceptFosterPlacement(AppNotification notification) async {
    final placementId = await _resolveFosterPlacementId(notification);
    await ref
        .read(pendingFosterPlacementsProvider.notifier)
        .accept(placementId);
    ref.invalidate(notificationsProvider);
  }

  Future<void> _declineFosterPlacement(AppNotification notification) async {
    final placementId = await _resolveFosterPlacementId(notification);
    await ref
        .read(pendingFosterPlacementsProvider.notifier)
        .decline(placementId);
    ref.invalidate(notificationsProvider);
  }

  Future<void> _acceptAdoptionPlacement(AppNotification notification) async {
    final placementId = await _resolveAdoptionPlacementId(notification);
    await ref
        .read(pendingAdoptionPlacementsProvider.notifier)
        .confirm(placementId);
    ref.invalidate(notificationsProvider);
  }

  Future<void> _declineAdoptionPlacement(AppNotification notification) async {
    final placementId = await _resolveAdoptionPlacementId(notification);
    await ref
        .read(pendingFosterPlacementsProvider.notifier)
        .decline(placementId);
    ref.invalidate(notificationsProvider);
  }

  Future<void> _acceptCustodyTransfer(AppNotification notification) async {
    final transferId = await _resolveCustodyTransferId(notification);
    await ref.read(pendingCustodyTransfersProvider.notifier).accept(transferId);
  }

  Future<void> _declineCustodyTransfer(AppNotification notification) async {
    final transferId = await _resolveCustodyTransferId(notification);
    await ref.read(pendingCustodyTransfersProvider.notifier).cancel(transferId);
  }

  Future<String> _resolveFosterPlacementId(AppNotification notification) async {
    final petId = notification.petId;
    if (petId == null || petId.isEmpty) {
      throw Exception('Missing pet id');
    }
    final pending = await ref.read(pendingFosterPlacementsProvider.future);
    final match = pending.where((p) => p.petId == petId).firstOrNull;
    if (match == null) throw StaleNotificationException();
    return match.id;
  }

  Future<String> _resolveAdoptionPlacementId(
    AppNotification notification,
  ) async {
    final petId = notification.petId;
    if (petId == null || petId.isEmpty) {
      throw Exception('Missing pet id');
    }
    final pending = await ref.read(pendingAdoptionPlacementsProvider.future);
    final match = pending.where((p) => p.petId == petId).firstOrNull;
    if (match == null) throw StaleNotificationException();
    return match.id;
  }

  Future<String> _resolveCustodyTransferId(AppNotification notification) async {
    final petId = notification.petId;
    if (petId == null || petId.isEmpty) {
      throw Exception('Missing pet id');
    }
    final pending = await ref.read(pendingCustodyTransfersProvider.future);
    final match = pending.where((p) => p.petId == petId).firstOrNull;
    if (match == null) throw StaleNotificationException();
    return match.id;
  }
}

class StaleNotificationException implements Exception {}

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
