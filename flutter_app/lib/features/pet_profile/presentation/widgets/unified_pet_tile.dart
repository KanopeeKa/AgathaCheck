import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pet.dart';
import '../utils/ownership_accent.dart';
import '../utils/pet_accent_color.dart';
import '../utils/pet_tile_dimensions.dart';
import 'pet_tile_status_line.dart';

/// Cross-domain pet tile: photo-forward card with ownership stripe and two text lines.
class UnifiedPetTile extends StatelessWidget {
  const UnifiedPetTile({
    super.key,
    required this.pet,
    required this.onTap,
    this.statusLine,
    this.width,
    this.height,
    this.semanticsLabel,
  });

  final Pet pet;
  final VoidCallback? onTap;
  final PetTileStatusLineData? statusLine;
  final double? width;
  final double? height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ownership = resolvePetOwnershipAccent(context, pet, l);
    final statusBarColor = pet.isFoster
        ? fosterOwnershipAccentColor(context)
        : ownership.accentColor;
    final resolvedStatus =
        statusLine ??
        resolvePetTileStatusLine(
          l: l,
          pet: pet,
          context: PetTileContext.petCare,
          careUrgency: PetTileCareUrgency.clear,
        );
    final label =
        semanticsLabel ?? '${pet.name}, ${resolvedStatus.label}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth =
            width ??
            (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth.clamp(
                    PetTileDimensions.minWidth,
                    PetTileDimensions.maxWidth,
                  )
                : PetTileDimensions.widthFor(MediaQuery.sizeOf(context).width));
        final tileHeight = height ?? PetTileDimensions.heightFor(context);
        final flex = PetTileDimensions.flexFor(context);

        return SizedBox(
          width: tileWidth,
          height: tileHeight,
          child: MergeSemantics(
            child: Semantics(
              identifier: 'unified_pet_tile',
              button: onTap != null,
              label: label,
              child: Card(
                key: Key('unified_pet_tile_${pet.id}'),
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: onTap,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        color: statusBarColor,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: flex.photo,
                              child: _PhotoArea(pet: pet),
                            ),
                            Expanded(
                              flex: flex.text,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 2, 8, 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      pet.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (resolvedStatus.label.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      _StatusRow(status: resolvedStatus),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status});

  final PetTileStatusLineData status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!status.showCareStyling || status.icon == null || status.label.isEmpty) {
      return Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: status.color ?? theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Row(
      children: [
        Icon(status.icon, size: 14, color: status.color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoArea extends StatelessWidget {
  const _PhotoArea({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final petColor = resolvePetAccentColor(context, pet);
    Widget image = _photoOrPlaceholder(petColor);

    if (pet.passedAway) {
      image = Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              AppColorTokens.passedAwayPhotoOverlay,
              BlendMode.lighten,
            ),
            child: image,
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                'assets/rainbow_wings.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      );
    }

    return image;
  }

  Widget _photoOrPlaceholder(Color petColor) {
    if (pet.photoPath != null && pet.photoPath!.isNotEmpty) {
      if (pet.photoPath!.startsWith('asset://')) {
        return Image.asset(
          pet.photoPath!.substring('asset://'.length),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(petColor),
        );
      }
      try {
        final bytes = base64Decode(pet.photoPath!);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return _placeholder(petColor);
      }
    }
    return _placeholder(petColor);
  }

  Widget _placeholder(Color petColor) {
    return ColoredBox(
      color: petColor.withValues(alpha: 0.12),
      child: Center(
        child: AppConstants.speciesIconWidget(
          pet.species,
          size: 32,
          color: petColor,
        ),
      ),
    );
  }
}
