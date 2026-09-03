import 'package:flutter/material.dart';

/// Deprecated: default-experience radios removed (D-v3-VIS-2).
///
/// Organisation visibility toggle removed (D-v5-WORKSPACE-1).
class ExperienceSettingsSection extends StatelessWidget {
  const ExperienceSettingsSection({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
