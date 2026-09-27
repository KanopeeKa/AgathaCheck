import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/household_providers.dart';

class HouseholdsScreen extends ConsumerWidget {
  const HouseholdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncHouseholds = ref.watch(householdListProvider);

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      screenTitle: l.householdsTitle,
      backPath: '/pc/pets',
      child: asyncHouseholds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.errorWithMessage('$e'))),
        data: (households) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(householdListProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (households.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      l.householdsEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ...households.map(
                  (h) => Card(
                    child: ListTile(
                      title: Text(h.name),
                      subtitle: Text(
                        h.myIsOrganiser
                            ? l.householdOrganiserLabel
                            : h.myAccessTier == 'can_log_care'
                            ? l.householdCanLogCareLabel
                            : l.householdFullAccessLabel,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _createHousehold(context, ref, l),
                  icon: const Icon(Icons.home_work_outlined),
                  label: Text(l.householdCreate),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _createHousehold(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(l.householdCreate),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: l.householdNameLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l.householdCreate),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty) return;
    try {
      final token = await ref.read(authProvider.notifier).getValidAccessToken();
      if (token == null) return;
      await ref
          .read(householdRepositoryProvider)
          .createHousehold(name, token: token);
      ref.invalidate(householdListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.householdCreated)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
