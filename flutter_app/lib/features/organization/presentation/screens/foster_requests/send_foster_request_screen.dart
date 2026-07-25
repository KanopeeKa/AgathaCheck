import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/app_logo_title.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/foster_requests_providers.dart';
import '../../providers/organization_providers.dart';
import '../../utils/org_screen_theme.dart';

class SendFosterRequestScreen extends ConsumerStatefulWidget {
  const SendFosterRequestScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<SendFosterRequestScreen> createState() =>
      _SendFosterRequestScreenState();
}

class _SendFosterRequestScreenState
    extends ConsumerState<SendFosterRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _selectedPetIds = <String>{};
  final _selectedFosterIds = <String>{};
  var _submitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool send}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPetIds.isEmpty || _selectedFosterIds.isEmpty) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.fosterRequestSelectionRequired)));
      return;
    }

    setState(() => _submitting = true);
    final l = AppLocalizations.of(context)!;
    try {
      final request = await ref
          .read(orgFosterRequestsProvider(widget.orgId).notifier)
          .createRequest(
            message: _messageController.text.trim(),
            petIds: _selectedPetIds.toList(growable: false),
            orgFosterParentIds: _selectedFosterIds.toList(growable: false),
            send: send,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            send ? l.fosterRequestSendSuccess : l.fosterRequestDraftSaved,
          ),
        ),
      );
      context.go('/o/orgs/${widget.orgId}/foster-requests/${request.id}');
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
    final petsAsync = ref.watch(orgPetsProvider(widget.orgId));
    final fostersAsync = ref.watch(orgFosterParentsProvider(widget.orgId));

    return orgThemed(
      child: Scaffold(
        appBar: AppBar(
          title: AppLogoTitle(title: l.fosterRequestSendNew),
          leading: IconButton(
            key: const Key('send_foster_request_back'),
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _submitting ? null : () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            key: const Key('send_foster_request_form'),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l.fosterRequestSendDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('send_foster_request_message'),
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: l.fosterRequestMessageLabel,
                  hintText: l.fosterRequestMessageHint,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l.fosterRequestMessageRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                l.fosterRequestSelectPets,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              petsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (pets) {
                  final available = pets.where((p) => !p.passedAway).toList();
                  if (available.isEmpty) {
                    return Text(
                      l.fosterRequestNoPets,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    );
                  }
                  return Column(
                    children: [
                      for (final pet in available)
                        CheckboxListTile(
                          key: Key('send_foster_request_pet_${pet.id}'),
                          value: _selectedPetIds.contains(pet.id),
                          onChanged: _submitting
                              ? null
                              : (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedPetIds.add(pet.id);
                                    } else {
                                      _selectedPetIds.remove(pet.id);
                                    }
                                  });
                                },
                          title: Text(pet.name),
                          subtitle: pet.species.isNotEmpty
                              ? Text(pet.species)
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                l.fosterRequestSelectFosters,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              fostersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (parents) {
                  final eligible = eligibleFosterRequestTargets(parents);
                  if (eligible.isEmpty) {
                    return Text(
                      l.fosterRequestNoEligibleFosters,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    );
                  }
                  return Column(
                    children: [
                      for (final parent in eligible)
                        CheckboxListTile(
                          key: Key('send_foster_request_foster_${parent.id}'),
                          value: _selectedFosterIds.contains(parent.id),
                          onChanged: _submitting
                              ? null
                              : (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedFosterIds.add(parent.id);
                                    } else {
                                      _selectedFosterIds.remove(parent.id);
                                    }
                                  });
                                },
                          title: Text(parent.displayName),
                          subtitle: parent.email != null
                              ? Text(parent.email!)
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('send_foster_request_save_draft'),
                      onPressed: _submitting
                          ? null
                          : () => _submit(send: false),
                      child: Text(l.fosterRequestSaveDraft),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('send_foster_request_send'),
                      onPressed: _submitting ? null : () => _submit(send: true),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.fosterRequestSendNow),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
