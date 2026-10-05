import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../domain/entities/household_invite_preview.dart';
import 'household_tier_labels.dart';

class HouseholdInviteLandingScreen extends ConsumerStatefulWidget {
  const HouseholdInviteLandingScreen({super.key, required this.inviteCode});

  final String inviteCode;

  @override
  ConsumerState<HouseholdInviteLandingScreen> createState() =>
      _HouseholdInviteLandingScreenState();
}

class _HouseholdInviteLandingScreenState
    extends ConsumerState<HouseholdInviteLandingScreen> {
  HouseholdInvitePreview? _preview;
  bool _loading = true;
  bool _notFound = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final preview = await ref
          .read(householdsRepositoryProvider)
          .fetchHouseholdInvitePreview(widget.inviteCode);
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _notFound = true;
        _loading = false;
      });
    }
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .acceptHouseholdInvite(widget.inviteCode);
      if (mounted) context.go('/pc/people/households/${_preview!.householdId}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.peopleSaveError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(peopleCommandsProvider)
          .declineHouseholdInvite(widget.inviteCode);
      if (mounted) context.go('/pc/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.peopleSaveError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_notFound || _preview == null) {
      return Scaffold(body: Center(child: Text(l.shareInviteNotFound)));
    }
    final preview = _preview!;
    final tier = householdTierLabel(
      l,
      preview.accessTier,
      organiser: preview.isOrganiser,
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppLogoTitle(title: l.householdsTitle, showTitle: false),
              const SizedBox(height: 24),
              Text(
                l.peopleHouseholdInviteLandingTitle(preview.householdName),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                l.peopleHouseholdInviteLandingBody(preview.inviterName, tier),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('household_invite_accept'),
                onPressed: _busy ? null : _accept,
                child: Text(l.peopleHouseholdInviteAccept),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('household_invite_decline'),
                onPressed: _busy ? null : _decline,
                child: Text(l.peopleHouseholdInviteDecline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
