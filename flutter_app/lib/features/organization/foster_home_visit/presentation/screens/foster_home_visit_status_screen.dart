import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../presentation/widgets/org_shell_app_bar_title.dart';
import '../../../presentation/widgets/org_shell_scaffold.dart';
import '../../domain/entities/foster_home_visit.dart';
import '../providers/foster_home_visit_providers.dart';
import '../widgets/foster_home_visit_status_panel.dart';

class FosterHomeVisitStatusScreen extends ConsumerWidget {
  const FosterHomeVisitStatusScreen({
    super.key,
    required this.orgId,
    required this.fosterParentId,
  });

  final String orgId;
  final String fosterParentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(
      fosterHomeVisitStatusProvider((
        orgId: orgId,
        fosterParentId: fosterParentId,
      )),
    );

    return Semantics(
      identifier: 'foster_home_visit_status_screen',
      container: true,
      child: OrgShellScaffold(
        title: l.fosterHomeVisitStatusTitle,
        orgId: orgId,
        navVariant: OrgNavTitleVariant.withOrgLogo,
        leadingKey: const Key('foster_home_visit_status_back'),
        child: statusAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (snapshot) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l.fosterHomeVisitStatusIntro,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Semantics(
                identifier: snapshot.latestValidated?.outcome ==
                        FosterHomeVisitOutcome.yes
                    ? 'foster_home_visit_status_validated'
                    : null,
                container: true,
                child: FosterHomeVisitStatusPanel(snapshot: snapshot),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
