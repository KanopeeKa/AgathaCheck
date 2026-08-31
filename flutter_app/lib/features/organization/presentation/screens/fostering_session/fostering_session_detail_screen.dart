import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../fostering_session/presentation/widgets/session_detail_body.dart';
import '../../providers/fostering_session_providers.dart';
import '../../widgets/org_shell_app_bar_title.dart';
import '../../widgets/org_shell_scaffold.dart';

class FosteringSessionDetailScreen extends ConsumerWidget {
  const FosteringSessionDetailScreen({
    super.key,
    required this.orgId,
    required this.placementId,
  });

  final String orgId;
  final String placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final key = (orgId: orgId, placementId: placementId);
    final sessionAsync = ref.watch(fosteringSessionDetailProvider(key));

    return OrgShellScaffold(
      title: l.fosteringSessionDetailTitle,
      orgId: orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('fostering_session_detail_back'),
      child: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (detail) => SessionDetailBody(
          orgId: orgId,
          placementId: placementId,
          detail: detail,
        ),
      ),
    );
  }
}
