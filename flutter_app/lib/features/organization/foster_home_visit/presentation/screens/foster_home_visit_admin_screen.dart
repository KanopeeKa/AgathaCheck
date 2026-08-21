import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../presentation/widgets/org_shell_app_bar_title.dart';
import '../../../presentation/widgets/org_shell_scaffold.dart';
import '../../domain/entities/foster_home_visit.dart';
import '../providers/foster_home_visit_providers.dart';
import '../widgets/foster_home_visit_forms.dart';
import '../widgets/foster_home_visit_status_panel.dart';

class FosterHomeVisitAdminScreen extends ConsumerStatefulWidget {
  const FosterHomeVisitAdminScreen({
    super.key,
    required this.orgId,
    required this.fosterParentId,
    this.initialAddress = '',
  });

  final String orgId;
  final String fosterParentId;
  final String initialAddress;

  @override
  ConsumerState<FosterHomeVisitAdminScreen> createState() =>
      _FosterHomeVisitAdminScreenState();
}

class _FosterHomeVisitAdminScreenState
    extends ConsumerState<FosterHomeVisitAdminScreen> {
  var _busy = false;
  var _showReschedule = false;

  FosterHomeVisitAdminKey get _key => (
    orgId: widget.orgId,
    fosterParentId: widget.fosterParentId,
  );

  Future<void> _run(Future<void> Function() action, String successMessage) async {
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

  Future<void> _confirmCancel(FosterHomeVisit visit) async {
    final l = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final cancelReason = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.fosterHomeVisitCancelTitle),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: l.fosterHomeVisitCancelReasonLabel,
          ),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text.trim()),
            child: Text(l.fosterHomeVisitCancelAction),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (cancelReason == null || !mounted) return;

    await _run(() async {
      await ref
          .read(fosterHomeVisitAdminProvider(_key).notifier)
          .cancelVisit(visit.id, cancelReason: cancelReason);
    }, l.fosterHomeVisitCancelSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final visitsAsync = ref.watch(fosterHomeVisitAdminProvider(_key));

    return OrgShellScaffold(
      title: l.fosterHomeVisitAdminTitle,
      orgId: widget.orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('foster_home_visit_admin_back'),
      child: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (visits) {
          FosterHomeVisit? scheduled;
          for (final visit in visits) {
            if (visit.isScheduled) {
              scheduled = visit;
              break;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (scheduled != null) ...[
                FosterHomeVisitStatusPanel(
                  snapshot: FosterHomeVisitStatusSnapshot(activeVisit: scheduled),
                  showAddress: true,
                ),
                const SizedBox(height: 16),
                if (!_showReschedule)
                  OutlinedButton.icon(
                    key: const Key('foster_home_visit_reschedule_toggle'),
                    onPressed: _busy
                        ? null
                        : () => setState(() => _showReschedule = true),
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: Text(l.fosterHomeVisitRescheduleAction),
                  )
                else ...[
                  FosterHomeVisitScheduleForm(
                    busy: _busy,
                    initialAddress: scheduled.address,
                    submitLabel: l.fosterHomeVisitRescheduleAction,
                    onSubmit: ({
                      required visitDate,
                      required visitTime,
                      required address,
                      required notes,
                    }) async {
                      await _run(() async {
                        await ref
                            .read(fosterHomeVisitAdminProvider(_key).notifier)
                            .rescheduleVisit(
                              scheduled!.id,
                              visitDate: visitDate,
                              visitTime: visitTime,
                              address: address,
                              notes: notes,
                            );
                        setState(() => _showReschedule = false);
                      }, l.fosterHomeVisitRescheduleSaved);
                    },
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _showReschedule = false),
                    child: Text(l.cancel),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('foster_home_visit_cancel_button'),
                  onPressed: _busy ? null : () => _confirmCancel(scheduled!),
                  icon: const Icon(Icons.event_busy_outlined),
                  label: Text(l.fosterHomeVisitCancelAction),
                ),
                const SizedBox(height: 24),
                FosterHomeVisitValidateForm(
                  busy: _busy,
                  onSubmit: ({
                    required outcome,
                    required outcomeReason,
                  }) async {
                    await _run(() async {
                      await ref
                          .read(fosterHomeVisitAdminProvider(_key).notifier)
                          .validateVisit(
                            scheduled!.id,
                            outcome: outcome,
                            outcomeReason: outcomeReason,
                          );
                    }, l.fosterHomeVisitValidateSaved);
                  },
                ),
              ] else ...[
                FosterHomeVisitScheduleForm(
                  busy: _busy,
                  initialAddress: widget.initialAddress,
                  onSubmit: ({
                    required visitDate,
                    required visitTime,
                    required address,
                    required notes,
                  }) async {
                    await _run(() async {
                      await ref
                          .read(fosterHomeVisitAdminProvider(_key).notifier)
                          .scheduleVisit(
                            visitDate: visitDate,
                            visitTime: visitTime,
                            address: address,
                            notes: notes,
                          );
                    }, l.fosterHomeVisitScheduleSaved);
                  },
                ),
              ],
              const SizedBox(height: 24),
              FosterHomeVisitHistoryList(visits: visits),
            ],
          );
        },
      ),
    );
  }
}
