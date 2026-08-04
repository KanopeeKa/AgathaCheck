import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/organization_providers.dart';
import '../widgets/org_shell_app_bar_title.dart';
import '../widgets/org_shell_scaffold.dart';

class AcceptConnectionScreen extends ConsumerStatefulWidget {
  const AcceptConnectionScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptConnectionScreen> createState() =>
      _AcceptConnectionScreenState();
}

class _AcceptConnectionScreenState
    extends ConsumerState<AcceptConnectionScreen> {
  bool _submitting = false;

  Future<void> _accept() async {
    setState(() => _submitting = true);
    final l = AppLocalizations.of(context)!;
    try {
      await acceptOrgConnectionToken(ref, widget.token);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.connectionAccepted)));
        context.go('/o/orgs');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return OrgShellScaffold(
      title: l.acceptConnection,
      navVariant: OrgNavTitleVariant.textOnly,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.acceptConnection),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('accept_connection_button'),
              onPressed: _submitting ? null : _accept,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.acceptConnection),
            ),
          ],
        ),
      ),
    );
  }
}
