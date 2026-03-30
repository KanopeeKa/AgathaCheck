
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../organization/presentation/providers/organization_providers.dart';
import '../../controllers/pet_form_controller.dart';


class PetAssignmentSection extends ConsumerWidget {
  final PetFormController controller;
  final int orgId;
  const PetAssignmentSection({required this.controller, required this.orgId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final membersAsync = ref.watch(orgMembersProvider(orgId));
    // ...existing code for assignment section UI, using controller.state
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.assignTo,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
        // ...rest of the UI, update controller state on selection
      ],
    );
  }
}
