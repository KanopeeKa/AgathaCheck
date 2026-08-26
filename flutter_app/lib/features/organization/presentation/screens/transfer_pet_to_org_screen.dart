import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/org_connection.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

class TransferPetToOrgScreen extends ConsumerStatefulWidget {
  const TransferPetToOrgScreen({
    super.key,
    required this.orgId,
    required this.petId,
  });

  final String orgId;
  final String petId;

  @override
  ConsumerState<TransferPetToOrgScreen> createState() =>
      _TransferPetToOrgScreenState();
}

class _TransferPetToOrgScreenState
    extends ConsumerState<TransferPetToOrgScreen> {
  final _notesController = TextEditingController();
  OrgConnection? _selected;
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _submitting = true);
    final l = AppLocalizations.of(context)!;
    try {
      await requestCustodyTransferAction(
        ref,
        orgId: widget.orgId,
        petId: widget.petId,
        transferKind: 'org_to_org',
        toOrgId: _selected!.peerOrgId,
        notes: _notesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.transferRequestSent)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final connectionsAsync = ref.watch(orgConnectionsProvider(widget.orgId));
    final petsAsync = ref.watch(orgPetsProvider(widget.orgId));
    final petName =
        petsAsync.whenOrNull(
          data: (pets) =>
              pets.where((p) => p.id == widget.petId).firstOrNull?.name,
        ) ??
        '';

    return OrgShellScaffold(
      title: l.transferToOrganisation,
      orgId: widget.orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      child: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (connections) {
          if (connections.isEmpty) {
            return Center(child: Text(l.orgConnectionsEmpty));
          }
          return RadioGroup<OrgConnection>(
            groupValue: _selected,
            onChanged: (value) => setState(() => _selected = value),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.transferConfirmMessage(petName)),
                const SizedBox(height: 16),
                Text(l.selectConnectedOrg),
                ...connections.map(
                  (c) => RadioListTile<OrgConnection>(
                    value: c,
                    title: Text(c.peerOrgName),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l.orgToOrgTransferNotes,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('confirm_org_transfer'),
                  onPressed: _selected == null || _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.confirmTransfer),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
