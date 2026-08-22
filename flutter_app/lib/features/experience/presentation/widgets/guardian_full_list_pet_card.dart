import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/utils/ownership_accent.dart';
import '../../../pet_profile/presentation/utils/pet_accent_color.dart';
import '../screens/guardian/guardian_dashboard_helpers.dart';

/// Horizontal list-row card for the Guardian All Pets full-list screen.
///
/// Applies the Operations Desk visual language (ownership accent strip,
/// ownership text label, lifecycle and care-urgency status) without
/// changing [PetCard] used by organisation and non-embedded surfaces.
///
/// Ownership, lifecycle (passed away), and care urgency are kept as
/// separate, non-conflated signals:
/// - The accent strip colour reflects ownership (plum = guardian-owned,
///   green = organisation/foster).
/// - The [ownershipLabel] row describes the relationship in text.
/// - The [careState] badge describes care urgency only.
/// - The passed-away overlay is lifecycle-only and suppresses care badges.
class GuardianFullListPetCard extends StatelessWidget {
  const GuardianFullListPetCard({
    super.key,
    required this.pet,
    required this.careState,
    required this.onTap,
  });

  final Pet pet;
  final GuardianTodayPetCareState careState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ownership = resolvePetOwnershipAccent(context, pet, l);
    final ownershipLabel = _ownershipLabel(l);
    final semanticsLabel = _semanticsLabel(l, ownershipLabel);

    return Semantics(
      key: Key('guardian_full_list_pet_card_${pet.id}'),
      button: true,
      label: semanticsLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Card(
        key: Key('guardian_full_list_pet_card_visual_${pet.id}'),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── ownership accent strip ──────────────────────────────────
              Container(
                width: 4,
                color: pet.isFoster
                    ? fosterOwnershipAccentColor(context)
                    : ownership.accentColor,
              ),
              // ── photo thumbnail ────────────────────────────────────────
              SizedBox(width: 72, child: _photo(context)),
              // ── pet identity and status ────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ownershipLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      // ── lifecycle / care status badge ─────────────────
                      if (pet.passedAway) ...[
                        const SizedBox(height: 4),
                        _LifecycleBadge(label: l.passedAway),
                      ] else ...[
                        const SizedBox(height: 4),
                        _CareBadge(careState: careState, l: l),
                      ],
                    ],
                  ),
                ),
              ),
              // ── forward chevron ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ownership relationship label — derived from Pet fields, never from colour.
  String _ownershipLabel(AppLocalizations l) {
    if (pet.isShared) return l.sharedPets;
    if (pet.isFoster) return l.myFosteredPets;
    return l.myPets;
  }

  String _semanticsLabel(AppLocalizations l, String ownershipLabel) {
    final care = pet.passedAway
        ? l.passedAway
        : switch (careState) {
            GuardianTodayPetCareState.overdue => l.overdue,
            GuardianTodayPetCareState.dueToday => l.urgencyDueToday,
            GuardianTodayPetCareState.upcoming => l.careStatusUpcoming,
            GuardianTodayPetCareState.clear => l.careStatusAllClear,
          };
    return '${pet.name}, $ownershipLabel, $care';
  }

  Widget _photo(BuildContext context) {
    final color = resolvePetAccentColor(context, pet);
    Widget image;
    if (pet.photoPath?.startsWith('asset://') ?? false) {
      image = Image.asset(
        pet.photoPath!.substring('asset://'.length),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(color),
      );
    } else if (pet.photoPath?.isNotEmpty ?? false) {
      try {
        image = Image.memory(base64Decode(pet.photoPath!), fit: BoxFit.cover);
      } catch (_) {
        image = _placeholder(color);
      }
    } else {
      image = _placeholder(color);
    }

    if (!pet.passedAway) return image;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            AppColorTokens.passedAwayPhotoOverlay,
            BlendMode.lighten,
          ),
          child: image,
        ),
        Center(
          child: Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/rainbow_wings.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(Color color) {
    return ColoredBox(
      color: color.withValues(alpha: 0.12),
      child: Center(
        child: AppConstants.speciesIconWidget(
          pet.species,
          size: 28,
          color: color,
        ),
      ),
    );
  }
}

/// Lifecycle badge — only used for the passed-away state.
class _LifecycleBadge extends StatelessWidget {
  const _LifecycleBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.favorite_border,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Care urgency badge — separate from lifecycle and ownership signals.
class _CareBadge extends StatelessWidget {
  const _CareBadge({required this.careState, required this.l});
  final GuardianTodayPetCareState careState;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (careState) {
      GuardianTodayPetCareState.overdue => (l.overdue, theme.colorScheme.error),
      GuardianTodayPetCareState.dueToday => (
        l.urgencyDueToday,
        theme.colorScheme.tertiary,
      ),
      GuardianTodayPetCareState.upcoming => (
        l.careStatusUpcoming,
        theme.colorScheme.onSurfaceVariant,
      ),
      GuardianTodayPetCareState.clear => (
        l.careStatusAllClear,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconFor(careState), size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }

  IconData _iconFor(GuardianTodayPetCareState state) {
    return switch (state) {
      GuardianTodayPetCareState.overdue => Icons.warning_amber_rounded,
      GuardianTodayPetCareState.dueToday => Icons.schedule,
      GuardianTodayPetCareState.upcoming => Icons.event_outlined,
      GuardianTodayPetCareState.clear => Icons.check_circle_outline,
    };
  }
}
