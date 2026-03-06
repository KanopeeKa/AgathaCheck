import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/organization_providers.dart';

class TransferPetScreen extends ConsumerStatefulWidget {
  const TransferPetScreen({
    super.key,
    required this.orgId,
    required this.petId,
  });

  final int orgId;
  final String petId;

  @override
  ConsumerState<TransferPetScreen> createState() => _TransferPetScreenState();
}

class _TransferPetScreenState extends ConsumerState<TransferPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  String _transferType = 'adoption';
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<(String, String, IconData)> _transferTypes(AppLocalizations l) => [
    ('adoption', l.transferTypeAdoption, Icons.favorite),
    ('transfer', l.transferTypeTransfer, Icons.swap_horiz),
    ('release', l.transferTypeRelease, Icons.nature_people),
    ('other', l.transferTypeOther, Icons.more_horiz),
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final l = AppLocalizations.of(context)!;
    try {
      await ref.read(orgPetsProvider(widget.orgId).notifier).transferPet(
            widget.petId,
            recipientEmail: _emailController.text.trim(),
            transferType: _transferType,
            notes: _notesController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.transferSuccess)),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(orgPetsProvider(widget.orgId));

    final petName = petsAsync.whenOrNull(
      data: (pets) =>
          pets.where((p) => p.id == widget.petId).firstOrNull?.name,
    ) ?? '';

    final types = _transferTypes(l);

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.transferPet),
        leading: IconButton(
          key: const Key('org_transfer_back'),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (petName.isNotEmpty)
                    MergeSemantics(
                      child: Card(
                        color: colorScheme.primaryContainer.withAlpha(80),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.pets, size: 32,
                                  color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  petName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(l.transferType,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: types.map((t) {
                      final isSelected = _transferType == t.$1;
                      return Semantics(
                        label: '${t.$2}${isSelected ? ', selected' : ''}',
                        child: ChoiceChip(
                          key: Key('org_transfer_type_${t.$1}'),
                          avatar: Icon(t.$3, size: 18),
                          label: Text(t.$2),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _transferType = t.$1);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('org_transfer_email'),
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: '${l.recipientEmail} *',
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l.recipientEmail;
                      }
                      if (!v.contains('@')) {
                        return l.orgEmail;
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('org_transfer_notes'),
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: l.transferNotes,
                      prefixIcon: const Icon(Icons.notes),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    key: const Key('org_transfer_confirm'),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send),
                    label: Text(l.confirmTransfer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
