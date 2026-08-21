import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/utils/calendar_date_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/organization_member.dart';
import '../../../domain/services/org_permissions.dart';
import '../../../presentation/providers/org_provider_list.dart';
import '../providers/foster_home_visit_providers.dart';

class FosterHomeVisitScheduleForm extends StatefulWidget {
  const FosterHomeVisitScheduleForm({
    super.key,
    required this.busy,
    required this.onSubmit,
    this.initialAddress = '',
    this.submitLabel,
  });

  final bool busy;
  final String initialAddress;
  final String? submitLabel;
  final Future<void> Function({
    required String visitDate,
    required String visitTime,
    required String address,
    required String notes,
  })
  onSubmit;

  @override
  State<FosterHomeVisitScheduleForm> createState() =>
      _FosterHomeVisitScheduleFormState();
}

class _FosterHomeVisitScheduleFormState extends State<FosterHomeVisitScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  final _timeController = TextEditingController(text: '09:00');
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _visitDate;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress;
  }

  @override
  void dispose() {
    _timeController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showCalendarDatePicker(
      context: context,
      initialDate: _visitDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: AppLocalizations.of(context)!.fosterHomeVisitDateLabel,
    );
    if (picked != null) {
      setState(() => _visitDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fosterHomeVisitDateRequired),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final visitDate = toCalendarDateString(_visitDate);
    if (visitDate == null) return;
    await widget.onSubmit(
      visitDate: visitDate,
      visitTime: _timeController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.fosterHomeVisitScheduleTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            identifier: 'foster_home_visit_schedule_date',
            button: true,
            child: OutlinedButton.icon(
              key: const Key('foster_home_visit_date_picker'),
              onPressed: widget.busy ? null : _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _visitDate == null
                    ? l.fosterHomeVisitDateLabel
                    : formatCalendarDateDisplay(_visitDate!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('foster_home_visit_time_field'),
            controller: _timeController,
            enabled: !widget.busy,
            decoration: InputDecoration(
              labelText: l.fosterHomeVisitTimeLabel,
              border: const OutlineInputBorder(),
              hintText: '09:00',
            ),
            validator: (value) {
              final raw = value?.trim() ?? '';
              if (!RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$').hasMatch(raw)) {
                return l.fosterHomeVisitTimeInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('foster_home_visit_address_field'),
            controller: _addressController,
            enabled: !widget.busy,
            decoration: InputDecoration(
              labelText: l.fosterHomeVisitAddressLabel,
              border: const OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('foster_home_visit_notes_field'),
            controller: _notesController,
            enabled: !widget.busy,
            decoration: InputDecoration(
              labelText: l.notes,
              border: const OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('foster_home_visit_schedule_submit'),
            onPressed: widget.busy ? null : _submit,
            icon: widget.busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.event_available_outlined),
            label: Text(widget.submitLabel ?? l.fosterHomeVisitScheduleAction),
          ),
        ],
      ),
    );
  }
}

class FosterHomeVisitValidateForm extends StatefulWidget {
  const FosterHomeVisitValidateForm({
    super.key,
    required this.busy,
    required this.onSubmit,
  });

  final bool busy;
  final Future<void> Function({
    required String outcome,
    required String outcomeReason,
  })
  onSubmit;

  @override
  State<FosterHomeVisitValidateForm> createState() =>
      _FosterHomeVisitValidateFormState();
}

class _FosterHomeVisitValidateFormState extends State<FosterHomeVisitValidateForm> {
  final _formKey = GlobalKey<FormState>();
  final _outcomeReasonController = TextEditingController();
  String? _selectedOutcome;

  @override
  void dispose() {
    _outcomeReasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedOutcome == null || _selectedOutcome!.isEmpty) {
      setState(() {});
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      outcome: _selectedOutcome!,
      outcomeReason: _outcomeReasonController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.fosterHomeVisitValidateTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            identifier: 'foster_home_visit_outcome_yes',
            child: RadioListTile<String>(
              key: const Key('foster_home_visit_outcome_yes'),
              title: Text(l.fosterHomeVisitOutcomeYes),
              value: 'yes',
              groupValue: _selectedOutcome,
              onChanged: widget.busy
                  ? null
                  : (value) => setState(() => _selectedOutcome = value),
            ),
          ),
          Semantics(
            identifier: 'foster_home_visit_outcome_no',
            child: RadioListTile<String>(
              key: const Key('foster_home_visit_outcome_no'),
              title: Text(l.fosterHomeVisitOutcomeNo),
              value: 'no',
              groupValue: _selectedOutcome,
              onChanged: widget.busy
                  ? null
                  : (value) => setState(() => _selectedOutcome = value),
            ),
          ),
          if (_selectedOutcome == null)
            Text(
              l.fosterHomeVisitOutcomeRequired,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('foster_home_visit_outcome_reason'),
            controller: _outcomeReasonController,
            enabled: !widget.busy,
            decoration: InputDecoration(
              labelText: l.fosterHomeVisitOutcomeReasonLabel,
              border: const OutlineInputBorder(),
            ),
            minLines: 3,
            maxLines: 5,
            validator: (value) {
              if (_selectedOutcome == 'no' &&
                  (value == null || value.trim().isEmpty)) {
                return l.fosterHomeVisitOutcomeReasonRequired;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('foster_home_visit_validate_submit'),
            onPressed: widget.busy ? null : _submit,
            icon: widget.busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_outlined),
            label: Text(l.fosterHomeVisitValidateAction),
          ),
        ],
      ),
    );
  }
}

class FosterHomeVisitAdminLink extends ConsumerWidget {
  const FosterHomeVisitAdminLink({
    super.key,
    required this.orgId,
    required this.fosterParentId,
  });

  final String orgId;
  final String fosterParentId;

  bool _canManage(WidgetRef ref) {
    final org = ref
        .watch(organizationListProvider)
        .valueOrNull
        ?.where((item) => item.id == orgId)
        .firstOrNull;
    if (org?.role == null) return false;
    return hasPermission(
      OrgMemberRole.fromWire(org!.role!),
      orgId,
      'home_visits',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_canManage(ref)) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      key: const Key('foster_home_visit_admin_link'),
      onPressed: () => context.push(
        fosterHomeVisitAdminRoutePath(orgId, fosterParentId),
      ),
      icon: const Icon(Icons.home_work_outlined, size: 18),
      label: Text(l.fosterHomeVisitAdminLink),
    );
  }
}

class FosterHomeVisitStatusLink extends ConsumerWidget {
  const FosterHomeVisitStatusLink({
    super.key,
    required this.orgId,
  });

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fosterParentId = ref.watch(fosterSelfParentIdProvider(orgId));
    if (fosterParentId == null) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      key: const Key('foster_home_visit_status_link'),
      onPressed: () => context.push(
        fosterHomeVisitStatusRoutePath(orgId, fosterParentId),
      ),
      icon: const Icon(Icons.event_note_outlined, size: 18),
      label: Text(l.fosterHomeVisitStatusLink),
    );
  }
}
