import 'package:flutter/material.dart';

/// Retired: `/app/choose` redirects to `/app/resolve` in [experience_routes.dart].
///
/// Kept so `experience.dart` barrel exports remain stable for this programme phase.
@Deprecated('Route redirects to /app/resolve')
class ExperienceChooserScreen extends StatelessWidget {
  const ExperienceChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
