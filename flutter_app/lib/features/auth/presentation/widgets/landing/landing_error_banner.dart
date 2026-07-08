import 'package:flutter/material.dart';

import '../../providers/auth_providers.dart';

class LandingErrorBanner extends StatelessWidget {
  const LandingErrorBanner({
    super.key,
    required this.theme,
    required this.auth,
  });

  final ThemeData theme;
  final AuthState auth;

  @override
  Widget build(BuildContext context) {
    if (auth.error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: MergeSemantics(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  auth.error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
