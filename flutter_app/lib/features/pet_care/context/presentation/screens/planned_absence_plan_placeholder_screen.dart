import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../experience/domain/entities/app_experience.dart';
import '../../../../experience/presentation/widgets/experience_shell_scaffold.dart';
import '../../../../../l10n/app_localizations.dart';

/// Placeholder for the away plan page (`/pc/away/:id`).
///
/// Replaced by the full plan page in AW-7.
class PlannedAbsencePlanPlaceholderScreen extends StatelessWidget {
  const PlannedAbsencePlanPlaceholderScreen({
    super.key,
    required this.absenceId,
  });

  final String absenceId;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: GoRouterState.of(context).uri.path,
      screenTitle: l.careContextAwayFlowTitle,
      backPath: '/pc/away',
      child: Center(child: Text('Away plan $absenceId')),
    );
  }
}
