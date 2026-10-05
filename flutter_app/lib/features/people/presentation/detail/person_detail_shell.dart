import 'package:flutter/material.dart';

import 'package:pet_profile_app/core/experience/app_experience.dart';
import 'package:pet_profile_app/core/router/experience_shell_scaffold.dart';

class PersonDetailShell extends StatelessWidget {
  const PersonDetailShell({
    super.key,
    required this.embedded,
    required this.personId,
    required this.body,
    this.title,
    this.editAction,
  });

  final bool embedded;
  final String personId;
  final Widget body;
  final String? title;
  final Widget? editAction;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Column(
        children: [
          if (editAction != null)
            Align(alignment: Alignment.centerRight, child: editAction!),
          Expanded(child: body),
        ],
      );
    }

    return ExperienceShellScaffold(
      experience: AppExperience.petCare,
      currentLocation: '/pc/people/$personId',
      screenTitle: title ?? '',
      contextualActions: editAction != null ? [editAction!] : const [],
      child: body,
    );
  }
}
