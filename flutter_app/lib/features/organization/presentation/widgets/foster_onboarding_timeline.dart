import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_onboarding_step.dart';
import '../../domain/entities/org_person.dart';
import '../../domain/entities/organization_member.dart';
import '../../domain/services/org_permissions.dart';
import '../providers/org_provider_deps.dart';
import '../providers/org_provider_list.dart';
import '../providers/org_provider_people.dart';

String localizedFosterOnboardingStepLabel(AppLocalizations l, String key) => switch (key) {
  'connected' => l.fosterOnboardingStepConnected,
  'profile' => l.fosterOnboardingStepProfile,
  'invitation_accepted' => l.fosterOnboardingStepInvitationAccepted,
  'under_review' => l.fosterOnboardingStepUnderReview,
  'onboarding_form' => l.fosterOnboardingStepOnboardingForm,
  'home_visit' => l.fosterOnboardingStepHomeVisit,
  'competencies' => l.fosterOnboardingStepCompetencies,
  'agreement' => l.fosterOnboardingStepAgreement,
  'approved' => l.fosterOnboardingStepApproved,
  _ => key,
};

class FosterOnboardingTimeline extends ConsumerStatefulWidget {
  const FosterOnboardingTimeline({
    super.key,
    required this.orgId,
    required this.kind,
    required this.recordId,
    required this.timeline,
  });

  final String orgId;
  final String kind;
  final String recordId;
  final FosterOnboardingStatus timeline;

  @override
  ConsumerState<FosterOnboardingTimeline> createState() => _FosterOnboardingTimelineState();
}

class _FosterOnboardingTimelineState extends ConsumerState<FosterOnboardingTimeline> {
  var _busyStepKey = '';

  OrgPersonDetailKey get _detailKey => (
    orgId: widget.orgId,
    kind: OrgPersonKind.fromWire(widget.kind),
    recordId: widget.recordId,
  );

  bool _canConfirmSteps() {
    final org = ref.watch(organizationListProvider).valueOrNull
        ?.where((item) => item.id == widget.orgId).firstOrNull;
    if (org?.role == null) return false;
    return hasPermission(OrgMemberRole.fromWire(org!.role!), widget.orgId, 'review_foster_onboarding');
  }

  Future<void> _confirmStep(String stepKey) async {
    setState(() => _busyStepKey = stepKey);
    try {
      await ref.read(orgPersonDetailProvider(_detailKey).notifier).confirmFosterOnboardingStep(stepKey);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busyStepKey = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final xp = context.experienceColors;
    final canConfirm = _canConfirmSteps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.fosterOnboardingStatusTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...List.generate(widget.timeline.steps.length, (index) {
          final step = widget.timeline.steps[index];
          final label = localizedFosterOnboardingStepLabel(l, step.key);
          return _FosterOnboardingTimelineRow(
            step: step,
            label: label,
            showConnectorBelow: index < widget.timeline.steps.length - 1,
            canConfirm: canConfirm && step.canConfirm && !step.isComplete,
            busy: _busyStepKey == step.key,
            onConfirm: () => _confirmStep(step.key),
            organizationPrimary: xp.organizationPrimary,
            dangerColor: xp.danger,
            notRecordedLabel: l.fosterOnboardingNotRecordedYet,
            confirmLabel: l.fosterOnboardingConfirmStep,
            colorScheme: theme.colorScheme,
            theme: theme,
          );
        }),
      ],
    );
  }
}

class _FosterOnboardingTimelineRow extends StatelessWidget {
  const _FosterOnboardingTimelineRow({
    required this.step, required this.label, required this.showConnectorBelow,
    required this.canConfirm, required this.busy, required this.onConfirm,
    required this.organizationPrimary, required this.dangerColor,
    required this.notRecordedLabel, required this.confirmLabel,
    required this.colorScheme, required this.theme,
  });

  final FosterOnboardingStep step;
  final String label;
  final bool showConnectorBelow;
  final bool canConfirm;
  final bool busy;
  final VoidCallback onConfirm;
  final Color organizationPrimary;
  final Color dangerColor;
  final String notRecordedLabel;
  final String confirmLabel;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      key: Key('foster_onboarding_step_${step.key}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FosterOnboardingDisc(
            state: step.state,
            showConnectorBelow: showConnectorBelow,
            organizationPrimary: organizationPrimary,
            dangerColor: dangerColor,
            outlineColor: colorScheme.outline,
            label: label,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnectorBelow ? 12 : 0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      if (step.deferred && !step.isComplete) ...[
                        const SizedBox(height: 4),
                        Text(notRecordedLabel, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ],
                      if (canConfirm) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          key: Key('foster_onboarding_confirm_${step.key}'),
                          onPressed: busy ? null : onConfirm,
                          child: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(confirmLabel),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FosterOnboardingDisc extends StatelessWidget {
  const _FosterOnboardingDisc({
    required this.state, required this.showConnectorBelow,
    required this.organizationPrimary, required this.dangerColor,
    required this.outlineColor, required this.label,
  });

  final FosterOnboardingStepState state;
  final bool showConnectorBelow;
  final Color organizationPrimary;
  final Color dangerColor;
  final Color outlineColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final connectorColor = state == FosterOnboardingStepState.complete
        ? organizationPrimary : outlineColor.withValues(alpha: 0.45);
    final decoration = switch (state) {
      FosterOnboardingStepState.complete => BoxDecoration(color: organizationPrimary, shape: BoxShape.circle),
      FosterOnboardingStepState.current => BoxDecoration(color: organizationPrimary, shape: BoxShape.circle),
      FosterOnboardingStepState.issue => BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: dangerColor, width: 2)),
      FosterOnboardingStepState.notStarted => BoxDecoration(shape: BoxShape.circle, border: Border.all(color: outlineColor)),
    };
    final child = state == FosterOnboardingStepState.complete
        ? const Icon(Icons.check, size: 14, color: Colors.white) : null;

    return SizedBox(
      width: 32,
      child: Column(children: [
        Semantics(
          label: label,
          child: Container(
            key: Key('foster_onboarding_disc_${state.wire}'),
            width: 24, height: 24, decoration: decoration, alignment: Alignment.center, child: child,
          ),
        ),
        if (showConnectorBelow) Expanded(child: Center(child: Container(width: 2, color: connectorColor))),
      ]),
    );
  }
}
