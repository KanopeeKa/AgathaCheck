import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/foster_request.dart';
import '../../providers/foster_requests_providers.dart';
import '../../utils/org_screen_theme.dart';

class FosterRequestRespondScreen extends ConsumerStatefulWidget {
  const FosterRequestRespondScreen({
    super.key,
    required this.orgId,
    required this.requestId,
  });

  final String orgId;
  final String requestId;

  @override
  ConsumerState<FosterRequestRespondScreen> createState() =>
      _FosterRequestRespondScreenState();
}

class _FosterRequestRespondScreenState
    extends ConsumerState<FosterRequestRespondScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  FosterResponseType _response = FosterResponseType.canHelp;
  DateTime? _earliestAvailability;
  var _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _earliestAvailability ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _earliestAvailability = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_response == FosterResponseType.canHelp &&
        _earliestAvailability == null) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fosterRequestAvailabilityRequired)),
      );
      return;
    }

    setState(() => _submitting = true);
    final l = AppLocalizations.of(context)!;
    try {
      await ref
          .read(
            orgFosterRequestDetailProvider((
              orgId: widget.orgId,
              requestId: widget.requestId,
            )).notifier,
          )
          .respond(
            response: _response,
            message: _messageController.text.trim(),
            earliestAvailability: _earliestAvailability,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.fosterRequestRespondSuccess)));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return orgThemed(
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: l.fosterRequestRespondTitle),
          leading: IconButton(
            key: const Key('foster_request_respond_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _submitting ? null : () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            key: const Key('foster_request_respond_form'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l.fosterRequestRespondDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<FosterResponseType>(
                key: const Key('foster_request_response_type'),
                segments: [
                  ButtonSegment(
                    value: FosterResponseType.canHelp,
                    label: Text(l.fosterRequestResponseCanHelp),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: FosterResponseType.cannotHelp,
                    label: Text(l.fosterRequestResponseCannotHelp),
                    icon: const Icon(Icons.cancel_outlined),
                  ),
                ],
                selected: {_response},
                onSelectionChanged: _submitting
                    ? null
                    : (selection) {
                        setState(() => _response = selection.first);
                      },
              ),
              const SizedBox(height: 16),
              if (_response == FosterResponseType.canHelp) ...[
                ListTile(
                  key: const Key('foster_request_availability_picker'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.fosterRequestEarliestAvailabilityLabel),
                  subtitle: Text(
                    _earliestAvailability != null
                        ? toCalendarDateString(_earliestAvailability)!
                        : l.fosterRequestSelectDate,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    tooltip: l.fosterRequestSelectDate,
                    onPressed: _submitting ? null : _pickDate,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                key: const Key('foster_request_respond_message'),
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: l.fosterRequestRespondMessageLabel,
                  hintText: l.fosterRequestRespondMessageHint,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('foster_request_respond_submit'),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.fosterRequestRespondSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
