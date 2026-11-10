import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../core/widgets/invite_recipient_block.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:pet_profile_app/features/auth/auth.dart';
import '../../../pet_profile/pet_profile.dart';
import '../../application/people_commands.dart';
import '../../application/people_providers.dart';
import '../../data/households_api.dart';
import '../../domain/entities/household_invite_preview.dart';
import 'household_tier_labels.dart';

Future<List<String>?> _sharePetsAfterInvite(
  BuildContext context,
  List<Pet> pets,
) {
  if (pets.isEmpty) return Future.value(const []);
  final selected = <String>{};
  final l = AppLocalizations.of(context)!;
  return showDialog<List<String>>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(l.peopleHouseholdPetReviewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final pet in pets)
              CheckboxListTile(
                key: Key('household_share_pet_${pet.id}'),
                value: selected.contains(pet.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    selected.add(pet.id);
                  } else {
                    selected.remove(pet.id);
                  }
                }),
                title: Text(pet.name),
              ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('household_share_pets_skip'),
            onPressed: () => Navigator.pop(ctx, const []),
            child: Text(l.later),
          ),
          FilledButton(
            key: const Key('household_share_pets_confirm'),
            onPressed: () => Navigator.pop(ctx, selected.toList()),
            child: Text(l.continueButton),
          ),
        ],
      ),
    ),
  );
}

/// Landing screen for household invites at `/household-invite/:code`.
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
  String? _errorKey;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorKey = null;
      _preview = null;
    });
    try {
      final preview = await ref
          .read(householdsRepositoryProvider)
          .fetchHouseholdInvitePreview(widget.inviteCode);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } on HouseholdInvitePreviewExpiredException {
      if (!mounted) return;
      setState(() {
        _errorKey = 'expired';
        _loading = false;
      });
    } on HouseholdInvitePreviewNotFoundException {
      if (!mounted) return;
      setState(() {
        _errorKey = 'not_found';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorKey = 'load_failed';
        _loading = false;
      });
    }
  }

  Future<void> _accept() async {
    if (!ref.read(authProvider).isLoggedIn) return;
    setState(() => _busy = true);
    try {
      final preview = _preview!;
      await ref
          .read(peopleCommandsProvider)
          .acceptHouseholdInvite(widget.inviteCode);
      if (!mounted) return;

      final ownedPets = ref.read(petListProvider).valueOrNull ?? const <Pet>[];
      final selectedPetIds = await _sharePetsAfterInvite(context, ownedPets);
      if (!mounted || selectedPetIds == null) return;

      if (selectedPetIds.isNotEmpty) {
        final detail = await ref
            .read(householdsRepositoryProvider)
            .fetchHouseholdDetail(preview.householdId);
        final existingPetIds = detail.pets.map((p) => p.petId).toSet();
        existingPetIds.addAll(selectedPetIds);
        await ref
            .read(peopleCommandsProvider)
            .setHouseholdPets(
              householdId: preview.householdId,
              petIds: existingPetIds.toList(),
            );
      }
      if (mounted) context.go('/pc/people/households/${preview.householdId}');
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
    if (!ref.read(authProvider).isLoggedIn) return;
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

  String _inviterDisplay(AppLocalizations l, HouseholdInvitePreview preview) {
    final raw = preview.inviterName;
    if (raw.trim().isNotEmpty) return raw.trim();
    return l.sharedPetLinkIdentityUnavailable;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    final invitePath = '/household-invite/${widget.inviteCode}';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.householdsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorKey != null || _preview == null) {
      if (_errorKey == 'load_failed') {
        return Scaffold(
          appBar: AppBar(title: AppLogoTitle(title: l.householdsTitle)),
          body: AsyncErrorState(
            title: l.peopleHouseholdInviteLoadFailed,
            onRetry: _loadPreview,
          ),
        );
      }
      final errorMessage = switch (_errorKey) {
        'expired' => l.shareInviteExpired,
        _ => l.shareInviteNotFound,
      };
      return Scaffold(
        appBar: AppBar(title: AppLogoTitle(title: l.householdsTitle)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mark_email_unread,
                  size: 64,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home),
                  label: Text(l.goToPetCare),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final preview = _preview!;
    final tier = householdTierLabel(
      l,
      preview.accessTier,
      organiser: preview.isOrganiser,
    );
    final inviter = _inviterDisplay(l, preview);

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.householdsTitle),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: l.goToPetCare,
          onPressed: () => context.go('/'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isLoggedIn)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.peopleHouseholdInviteLandingTitle(preview.householdName),
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.peopleHouseholdInviteLandingBody(inviter, tier),
                    ),
                  ],
                ),
              ),
            )
          else
            InviteRecipientBlock(
              invitePath: invitePath,
              scopeDescription: tier,
              inviterName: preview.inviterName,
              householdSummary: preview.householdName,
            ),
          if (isLoggedIn) ...[
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('household_invite_accept'),
              onPressed: _busy ? null : _accept,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.peopleHouseholdInviteAccept),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('household_invite_decline'),
              onPressed: _busy ? null : _decline,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(l.peopleHouseholdInviteDecline),
            ),
          ],
        ],
      ),
    );
  }
}
