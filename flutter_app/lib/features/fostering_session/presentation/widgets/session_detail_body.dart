import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../organization/domain/entities/foster_placement.dart';
import '../../../organization/domain/entities/foster_session_status.dart';
import '../../../organization/presentation/providers/fostering_session_providers.dart';
import '../../../organization/presentation/providers/org_provider_deps.dart';
import '../../../organization/presentation/utils/foster_placement_display.dart';
import '../../../organization/presentation/widgets/fostering_session/fostering_session_preparation_checklist.dart';
import '../../domain/entities/fostering_session_detail.dart';
import '../../domain/entities/session_viewer_context.dart';
import 'session_confirmation_tile.dart';

typedef SessionDetailActionRunner = Future<FosterPlacement> Function();

class SessionDetailBody extends ConsumerStatefulWidget {
  const SessionDetailBody({
    super.key,
    required this.orgId,
    required this.placementId,
    required this.detail,
  });

  final String orgId;
  final String placementId;
  final FosteringSessionDetail detail;

  @override
  ConsumerState<SessionDetailBody> createState() => _SessionDetailBodyState();
}

class _SessionDetailBodyState extends ConsumerState<SessionDetailBody> {
  var _busy = false;

  FosteringSessionDetailKey get _key =>
      (placementId: widget.placementId, orgId: widget.orgId);

  FosteringSessionDetail get _detail => widget.detail;

  FosterPlacement get _placement => _detail.placement;

  Future<void> _runAction(
    SessionDetailActionRunner action, {
    required String successMessage,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmEndSession(String outcome) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.fosteringSessionEndConfirmTitle),
        content: Text(
          outcome == FosterSessionEndOutcome.returnedToShelter
              ? l.fosteringSessionEndConfirmReturned
              : l.fosteringSessionEndConfirmCancelled,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runAction(
      () => ref
          .read(fosteringSessionDetailProvider(_key).notifier)
          .endSession(outcome: outcome),
      successMessage: l.fosteringSessionEndSuccess,
    );
  }

  Future<void> _showRegisterExport() async {
    final l = AppLocalizations.of(context)!;
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    setState(() => _busy = true);
    try {
      final export = await ref
          .read(organizationRepositoryProvider)
          .getRegisterExport(widget.orgId, widget.placementId, token);
      if (!mounted) return;
      final content = export['content']?.toString() ?? '';
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.fosteringSessionRegisterExportTitle),
          content: SingleChildScrollView(child: SelectableText(content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startViewToAdoptAdoption() async {
    final l = AppLocalizations.of(context)!;
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(organizationRepositoryProvider)
          .startAdoption(widget.orgId, widget.placementId, token: token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fosteringSessionStartAdoptionSuccess)),
      );
      ref.invalidate(fosteringSessionDetailProvider(_key));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fosteringSessionVisitPathBlocked('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _expediteVisitAndStart() async {
    final l = AppLocalizations.of(context)!;
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(organizationRepositoryProvider)
          .completeVisitAndStartAdoption(
            widget.orgId,
            widget.placementId,
            token: token,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fosteringSessionExpediteAdoptionSuccess)),
      );
      ref.invalidate(fosteringSessionDetailProvider(_key));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final placement = _placement;
    final detail = _detail;
    final counterpartyLabel = detail.counterparty.displayName.isNotEmpty
        ? detail.counterparty.displayName
        : (placement.fosterName.isNotEmpty
              ? placement.fosterName
              : placement.fosterEmail);
    final petName = detail.pet.name.isNotEmpty
        ? detail.pet.name
        : (placement.petName.isNotEmpty ? placement.petName : placement.petId);

    return ListView(
      key: const Key('fostering_session_detail_body'),
      padding: const EdgeInsets.all(16),
      children: [
        if (detail.flaggedForAdminReview)
          Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.notificationActionNeeded,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
        if (detail.flaggedForAdminReview) const SizedBox(height: 12),
        Chip(label: Text(fosterSessionStatusLabel(l, placement.sessionStatus))),
        const SizedBox(height: 16),
        Text(petName, style: theme.textTheme.headlineSmall),
        if (counterpartyLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l.fosterPlacementAssignedTo(counterpartyLabel),
            style: theme.textTheme.bodyLarge,
          ),
        ],
        if (placement.startDate != null) ...[
          const SizedBox(height: 8),
          Text(
            l.fosterPlacementStartDate(
              DateFormat.yMMMd().format(placement.startDate!),
            ),
          ),
        ],
        if (placement.nearlyFinished) ...[
          const SizedBox(height: 8),
          Text(
            l.fosteringSessionDerivedNearlyFinished,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
        if (placement.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l.notes, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(placement.notes),
        ],
        if (placement.isSessionPreparation) ...[
          const SizedBox(height: 16),
          FosteringSessionPreparationChecklist(
            orgId: widget.orgId,
            placementId: widget.placementId,
            initialChecklist: detail.checklist.toChecklistMap(),
            canUpdate: detail.can(SessionAction.updateChecklistItem),
          ),
        ],
        if (placement.isSessionReadyToStart) ...[
          const SizedBox(height: 16),
          Text(
            l.fosteringSessionDualStartTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SessionConfirmationTile(
            label: l.fosteringSessionShelterStartLabel,
            confirmed: placement.shelterStartConfirmed,
            confirmedAt: placement.shelterStartConfirmedAt,
          ),
          const SizedBox(height: 8),
          SessionConfirmationTile(
            label: l.fosteringSessionFosterStartLabel,
            confirmed: placement.fosterStartConfirmed,
            confirmedAt: placement.fosterStartConfirmedAt,
          ),
        ],
        const SizedBox(height: 16),
        if (detail.can(SessionAction.registerExport))
          TextButton.icon(
            key: const Key('fostering_session_register_export'),
            onPressed: _busy ? null : _showRegisterExport,
            icon: const Icon(Icons.description_outlined),
            label: Text(l.fosteringSessionRegisterExport),
          ),
        if (_busy)
          const Center(child: CircularProgressIndicator())
        else ...[
          if (detail.can(SessionAction.acceptInvite))
            FilledButton.icon(
              key: const Key('session_action_accept_invite'),
              onPressed: () => _runAction(
                () => ref
                    .read(fosteringSessionDetailProvider(_key).notifier)
                    .acceptInvite(),
                successMessage: l.fosterPlacementAccepted,
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l.acceptInvite),
            ),
          if (detail.can(SessionAction.declineInvite))
            OutlinedButton.icon(
              key: const Key('session_action_decline_invite'),
              onPressed: () => _runAction(
                () => ref
                    .read(fosteringSessionDetailProvider(_key).notifier)
                    .declineInvite(),
                successMessage: l.fosterPlacementDeclined,
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(l.declineInvite),
            ),
          if (detail.can(SessionAction.transitionPreparation))
            FilledButton.icon(
              key: const Key('fostering_session_start_preparation'),
              onPressed: () => _runAction(
                () => ref
                    .read(fosteringSessionDetailProvider(_key).notifier)
                    .transitionSession(FosterSessionStatus.preparation),
                successMessage: l.fosteringSessionTransitionSuccess,
              ),
              icon: const Icon(Icons.playlist_add_check),
              label: Text(l.fosteringSessionStartPreparation),
            ),
          if (detail.can(SessionAction.transitionReadyToStart))
            FilledButton.icon(
              key: const Key('fostering_session_mark_ready'),
              onPressed: () => _runAction(
                () => ref
                    .read(fosteringSessionDetailProvider(_key).notifier)
                    .transitionSession(FosterSessionStatus.readyToStart),
                successMessage: l.fosteringSessionTransitionSuccess,
              ),
              icon: const Icon(Icons.flag_outlined),
              label: Text(l.fosteringSessionMarkReady),
            ),
          if (detail.can(SessionAction.confirmShelterStart))
            FilledButton.icon(
              key: const Key('fostering_session_confirm_shelter_start'),
              onPressed: () => _runAction(
                () => ref
                    .read(fosteringSessionDetailProvider(_key).notifier)
                    .confirmShelterStart(),
                successMessage: l.fosteringSessionShelterStartSuccess,
              ),
              icon: const Icon(Icons.home_work_outlined),
              label: Text(l.fosteringSessionConfirmShelterStart),
            ),
          if (detail.can(SessionAction.confirmFosterStart))
            FilledButton.icon(
              key: const Key('fostering_session_confirm_foster_start'),
              onPressed: () => _runAction(
                () => ref
                    .read(fosteringSessionDetailProvider(_key).notifier)
                    .confirmFosterStart(),
                successMessage: l.fosteringSessionFosterStartSuccess,
              ),
              icon: const Icon(Icons.pets),
              label: Text(l.fosteringSessionConfirmFosterStart),
            ),
          if (detail.can(SessionAction.startAdoptionJourney)) ...[
            OutlinedButton.icon(
              key: const Key('fostering_session_start_adoption'),
              onPressed: _busy ? null : _startViewToAdoptAdoption,
              icon: const Icon(Icons.favorite_border),
              label: Text(l.startAdoption),
            ),
            const SizedBox(height: 8),
          ],
          if (detail.can(SessionAction.expediteVisitAdoption)) ...[
            FilledButton.icon(
              key: const Key('fostering_session_expedite_adoption'),
              onPressed: _busy ? null : _expediteVisitAndStart,
              icon: const Icon(Icons.bolt_outlined),
              label: Text(l.fosteringSessionExpediteAdoption),
            ),
            const SizedBox(height: 8),
          ],
          if (detail.can(SessionAction.requestEnd))
            OutlinedButton.icon(
              key: const Key('fostering_session_request_end'),
              onPressed: () => _runAction(
                () => ref
                    .read(fosteringSessionDetailProvider(_key).notifier)
                    .requestEnd(),
                successMessage: l.fosteringSessionRequestEndSuccess,
              ),
              icon: const Icon(Icons.event_busy_outlined),
              label: Text(l.fosteringSessionRequestEnd),
            ),
          if (detail.can(SessionAction.completeEndReturned) ||
              detail.can(SessionAction.completeEndCancelled)) ...[
            Text(
              l.fosteringSessionEndPendingDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (detail.can(SessionAction.completeEndReturned))
            FilledButton.icon(
              key: const Key('fostering_session_end_returned'),
              onPressed: () =>
                  _confirmEndSession(FosterSessionEndOutcome.returnedToShelter),
              icon: const Icon(Icons.home_outlined),
              label: Text(l.fosteringSessionEndReturned),
            ),
          if (detail.can(SessionAction.completeEndReturned) &&
              detail.can(SessionAction.completeEndCancelled))
            const SizedBox(height: 8),
          if (detail.can(SessionAction.completeEndCancelled))
            OutlinedButton.icon(
              key: const Key('fostering_session_end_cancelled'),
              onPressed: () =>
                  _confirmEndSession(FosterSessionEndOutcome.cancelled),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(l.fosteringSessionEndCancelled),
            ),
        ],
      ],
    );
  }
}
