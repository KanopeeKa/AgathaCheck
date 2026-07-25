import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_placement.dart';
import '../../../domain/entities/foster_session_status.dart';
import '../../providers/fostering_session_providers.dart';
import '../../providers/org_provider_pets.dart';
import '../../providers/org_provider_deps.dart';
import '../../utils/foster_placement_display.dart';
import '../../utils/org_screen_theme.dart';
import '../../widgets/fostering_session/fostering_session_preparation_checklist.dart';

class FosteringSessionDetailScreen extends ConsumerWidget {
  const FosteringSessionDetailScreen({
    super.key,
    required this.orgId,
    required this.placementId,
  });

  final String orgId;
  final String placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final key = (orgId: orgId, placementId: placementId);
    final sessionAsync = ref.watch(fosteringSessionDetailProvider(key));

    return orgThemed(
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: l.fosteringSessionDetailTitle),
          leading: IconButton(
            key: const Key('fostering_session_detail_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.pop(),
          ),
        ),
        body: sessionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (placement) => _FosteringSessionDetailBody(
            orgId: orgId,
            placementId: placementId,
            placement: placement,
          ),
        ),
      ),
    );
  }
}

class _FosteringSessionDetailBody extends ConsumerStatefulWidget {
  const _FosteringSessionDetailBody({
    required this.orgId,
    required this.placementId,
    required this.placement,
  });

  final String orgId;
  final String placementId;
  final FosterPlacement placement;

  @override
  ConsumerState<_FosteringSessionDetailBody> createState() =>
      _FosteringSessionDetailBodyState();
}

class _FosteringSessionDetailBodyState
    extends ConsumerState<_FosteringSessionDetailBody> {
  var _busy = false;

  FosteringSessionDetailKey get _key =>
      (orgId: widget.orgId, placementId: widget.placementId);

  Future<void> _runAction(
    Future<FosterPlacement> Function() action, {
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
    final placement = widget.placement;
    final isAdmin = ref.watch(isOrgAdminProvider(widget.orgId));
    final isFoster = ref.watch(isOrgFosterProvider(widget.orgId));
    final fosterLabel = placement.fosterName.isNotEmpty
        ? placement.fosterName
        : placement.fosterEmail;

    return ListView(
      key: const Key('fostering_session_detail_body'),
      padding: const EdgeInsets.all(16),
      children: [
        Chip(label: Text(fosterSessionStatusLabel(l, placement.sessionStatus))),
        const SizedBox(height: 16),
        Text(
          placement.petName.isNotEmpty ? placement.petName : placement.petId,
          style: theme.textTheme.headlineSmall,
        ),
        if (fosterLabel.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l.fosterPlacementAssignedTo(fosterLabel),
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
          ),
        ],
        if (placement.isSessionReadyToStart) ...[
          const SizedBox(height: 16),
          Text(
            l.fosteringSessionDualStartTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _ConfirmationTile(
            label: l.fosteringSessionShelterStartLabel,
            confirmed: placement.shelterStartConfirmed,
            confirmedAt: placement.shelterStartConfirmedAt,
          ),
          const SizedBox(height: 8),
          _ConfirmationTile(
            label: l.fosteringSessionFosterStartLabel,
            confirmed: placement.fosterStartConfirmed,
            confirmedAt: placement.fosterStartConfirmedAt,
          ),
        ],
        const SizedBox(height: 16),
        if (isAdmin)
          TextButton.icon(
            key: const Key('fostering_session_register_export'),
            onPressed: _busy ? null : _showRegisterExport,
            icon: const Icon(Icons.description_outlined),
            label: Text(l.fosteringSessionRegisterExport),
          ),
        if (_busy)
          const Center(child: CircularProgressIndicator())
        else ...[
          if (isAdmin && placement.isSessionPendingAcceptance)
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
          if (isAdmin && placement.isSessionPreparation)
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
          if (isAdmin &&
              placement.isSessionReadyToStart &&
              !placement.shelterStartConfirmed)
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
          if (isFoster &&
              placement.isSessionReadyToStart &&
              !placement.fosterStartConfirmed)
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
          if (isAdmin &&
              placement.sessionType == FosterSessionType.fosterInViewToAdopt &&
              placement.isSessionActive) ...[
            OutlinedButton.icon(
              key: const Key('fostering_session_start_adoption'),
              onPressed: _busy ? null : _startViewToAdoptAdoption,
              icon: const Icon(Icons.favorite_border),
              label: Text(l.startAdoption),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('fostering_session_expedite_adoption'),
              onPressed: _busy ? null : _expediteVisitAndStart,
              icon: const Icon(Icons.bolt_outlined),
              label: Text(l.fosteringSessionExpediteAdoption),
            ),
            const SizedBox(height: 8),
          ],
          if (isAdmin && placement.isSessionActive)
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
          if (isAdmin && placement.isSessionEndPending) ...[
            Text(
              l.fosteringSessionEndPendingDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('fostering_session_end_returned'),
              onPressed: () =>
                  _confirmEndSession(FosterSessionEndOutcome.returnedToShelter),
              icon: const Icon(Icons.home_outlined),
              label: Text(l.fosteringSessionEndReturned),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('fostering_session_end_cancelled'),
              onPressed: () =>
                  _confirmEndSession(FosterSessionEndOutcome.cancelled),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(l.fosteringSessionEndCancelled),
            ),
          ],
        ],
      ],
    );
  }
}

class _ConfirmationTile extends StatelessWidget {
  const _ConfirmationTile({
    required this.label,
    required this.confirmed,
    this.confirmedAt,
  });

  final String label;
  final bool confirmed;
  final DateTime? confirmedAt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
        color: confirmed ? colorScheme.primary : colorScheme.outline,
      ),
      title: Text(label),
      subtitle: confirmed && confirmedAt != null
          ? Text(
              l.fosteringSessionConfirmedAt(
                DateFormat.yMMMd().add_jm().format(confirmedAt!.toLocal()),
              ),
            )
          : Text(
              l.fosteringSessionAwaitingConfirmation,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
    );
  }
}
