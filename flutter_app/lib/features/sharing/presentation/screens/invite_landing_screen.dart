import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/invite_preview.dart';
import '../../domain/entities/pet_access.dart';
import '../providers/sharing_providers.dart';
import '../widgets/shared_pet_accept_section.dart';

/// Landing screen for email share invites at `/invite/:code`.
class InviteLandingScreen extends ConsumerStatefulWidget {
  const InviteLandingScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  ConsumerState<InviteLandingScreen> createState() =>
      _InviteLandingScreenState();
}

class _InviteLandingScreenState extends ConsumerState<InviteLandingScreen> {
  InvitePreview? _preview;
  bool _loading = true;
  String? _errorKey;
  bool _accepting = false;
  bool _declining = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final repo = ref.read(sharingRepositoryProvider);
      final preview = await repo.getInvitePreview(widget.inviteCode);
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } on InvitePreviewExpiredException {
      setState(() {
        _errorKey = 'expired';
        _loading = false;
      });
    } on InvitePreviewNotFoundException {
      setState(() {
        _errorKey = 'not_found';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _errorKey = 'load_failed';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorKey != null || _preview == null) {
      final errorMessage = switch (_errorKey) {
        'expired' => l.shareInviteExpired,
        'load_failed' => l.sharedPetLoadFailed,
        _ => l.shareInviteNotFound,
      };
      return Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.shareInviteTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_email_unread, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(errorMessage, style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: Text(l.goToPetCare),
              ),
            ],
          ),
        ),
      );
    }

    final preview = _preview!;
    final roleLabel = preview.role == PetAccessRole.coParent
        ? l.coParent
        : l.shareInviteRoleCarer;
    final petNames = preview.petNamesDisplay;

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.shareInviteTitle),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: l.goToPetCare,
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.shareInviteLandingHeadline(preview.inviterName),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (petNames.isNotEmpty)
                    Text(
                      l.shareInviteLandingPets(petNames),
                      style: theme.textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l.shareInviteLandingRole(roleLabel),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (preview.isAccepted)
            Card(
              color: colorScheme.primaryContainer.withAlpha(80),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.shareInviteAlreadyAccepted)),
                  ],
                ),
              ),
            )
          else ...[
            SharedPetAcceptSection(
              isLoggedIn: ref.watch(authProvider).isLoggedIn,
              accepting: _accepting,
              onAccept: _accept,
              theme: theme,
              colorScheme: colorScheme,
              promptText: l.shareInviteAcceptPrompt,
              buttonText: _accepting ? l.sharedPetAdding : l.shareInviteAccept,
            ),
            const SizedBox(height: 12),
            if (ref.watch(authProvider).isLoggedIn)
              OutlinedButton.icon(
                onPressed: _declining ? null : _decline,
                icon: _declining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close),
                label: Text(l.shareInviteDecline),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    final l = AppLocalizations.of(context)!;
    try {
      final token = await ref.read(authProvider.notifier).getValidAccessToken();
      if (token == null) return;
      final repo = ref.read(sharingRepositoryProvider);
      await repo.acceptInviteByCode(widget.inviteCode, token);
      ref.invalidate(allPetsIncludingOrgProvider);
      await ref.read(allPetsIncludingOrgProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.shareInviteAccepted)));
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _decline() async {
    final preview = _preview;
    if (preview == null || preview.inviteId.isEmpty) return;
    setState(() => _declining = true);
    final l = AppLocalizations.of(context)!;
    try {
      final token = await ref.read(authProvider.notifier).getValidAccessToken();
      if (token == null) return;
      final repo = ref.read(sharingRepositoryProvider);
      await repo.declineInvite(preview.inviteId, token);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.shareInviteDeclined)));
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _declining = false);
    }
  }
}
