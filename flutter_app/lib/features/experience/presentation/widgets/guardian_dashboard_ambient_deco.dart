import 'package:flutter/material.dart';

/// Asset paths for the guardian home dashboard ambient illustration family.
abstract final class GuardianDashboardDecoAssets {
  static const cat = 'assets/dashboard/dashboard-deco-cat.png';
  static const yarnSegment = 'assets/dashboard/dashboard-deco-yarn-segment.png';
  static const yarnBall = 'assets/dashboard/dashboard-deco-yarn-ball.png';
  static const puppyBowl = 'assets/dashboard/dashboard-deco-puppy-bowl.png';
}

/// Space- and viewport-gated thresholds for ambient dashboard decorations.
abstract final class GuardianDashboardDecoThresholds {
  /// No ambient decoration below this viewport width (mobile).
  static const mobileMaxWidth = 600.0;

  /// Wide two-column desk layout breakpoint (matches operations desk).
  static const wideMinWidth = 900.0;

  /// Minimum horizontal slack beside the pet rail before showing any yarn art.
  static const railMinLeftover = 120.0;

  /// Enough slack to show cat + yarn ball without the middle segment.
  static const railCatAndBall = 200.0;

  /// Enough slack for cat + stretchable yarn segment + yarn ball.
  static const railFullComposition = 280.0;

  /// Opacity for ambient sketch overlays on `background`.
  static const opacity = 0.13;

  /// Reference composition height used inside [FittedBox] scaling.
  static const compositionHeight = 72.0;

  /// Puppy watermark height on wide layouts.
  static const puppyHeight = 88.0;
}

enum GuardianPetRailDecoMode { catOnly, catAndBall, full }

/// Classifies pet-rail leftover width into a decoration mode.
GuardianPetRailDecoMode? guardianPetRailDecoModeForLeftover(double leftover) {
  if (leftover < GuardianDashboardDecoThresholds.railMinLeftover) {
    return null;
  }
  if (leftover >= GuardianDashboardDecoThresholds.railFullComposition) {
    return GuardianPetRailDecoMode.full;
  }
  if (leftover >= GuardianDashboardDecoThresholds.railCatAndBall) {
    return GuardianPetRailDecoMode.catAndBall;
  }
  return GuardianPetRailDecoMode.catOnly;
}

/// Whether ambient dashboard art is allowed for the current viewport width.
bool guardianDashboardDecoAllowedForWidth(double viewportWidth) {
  return viewportWidth >= GuardianDashboardDecoThresholds.mobileMaxWidth;
}

/// Whether the Care Team puppy watermark may appear.
bool guardianCareTeamPuppyDecoAllowed({
  required double viewportWidth,
  required bool hasCareTeamCards,
}) {
  return viewportWidth >= GuardianDashboardDecoThresholds.wideMinWidth &&
      hasCareTeamCards;
}

/// Non-interactive, non-semantic wrapper for ambient dashboard illustrations.
class GuardianDashboardAmbientDeco extends StatelessWidget {
  const GuardianDashboardAmbientDeco({
    super.key,
    required this.child,
    this.opacity = GuardianDashboardDecoThresholds.opacity,
  });

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(opacity: opacity, child: child),
      ),
    );
  }
}

/// Cat + optional yarn segment + yarn ball for slack beside the pet rail.
class GuardianPetRailYarnDeco extends StatelessWidget {
  const GuardianPetRailYarnDeco({
    super.key,
    required this.mode,
    required this.width,
    required this.height,
  });

  final GuardianPetRailDecoMode mode;
  final double width;
  final double height;

  static const _catAspect = 1448 / 1086;
  static const _ballAspect = 1448 / 1086;
  static const _yarnHeightRatio = 724 / 1086;
  static const _yarnVerticalOffset = 0.04;

  @override
  Widget build(BuildContext context) {
    final compositionHeight = GuardianDashboardDecoThresholds.compositionHeight;
    final compositionWidth = width / height * compositionHeight;

    return GuardianDashboardAmbientDeco(
      child: SizedBox(
        key: const Key('guardian_dashboard_pet_rail_deco'),
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: compositionWidth,
            height: compositionHeight,
            child: _compositionRow(compositionHeight),
          ),
        ),
      ),
    );
  }

  Widget _compositionRow(double compositionHeight) {
    final yarnHeight = compositionHeight * _yarnHeightRatio;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _endCap(
          GuardianDashboardDecoAssets.cat,
          compositionHeight * _catAspect,
          compositionHeight,
        ),
        if (mode == GuardianPetRailDecoMode.full) ...[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: compositionHeight * _yarnVerticalOffset),
              child: Image.asset(
                GuardianDashboardDecoAssets.yarnSegment,
                height: yarnHeight,
                fit: BoxFit.fitWidth,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          _endCap(
            GuardianDashboardDecoAssets.yarnBall,
            compositionHeight * _ballAspect,
            compositionHeight,
          ),
        ] else if (mode == GuardianPetRailDecoMode.catAndBall) ...[
          const Spacer(),
          _endCap(
            GuardianDashboardDecoAssets.yarnBall,
            compositionHeight * _ballAspect,
            compositionHeight,
          ),
        ],
      ],
    );
  }

  Widget _endCap(String asset, double width, double height) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Lower-right puppy watermark for the Care Team column on wide layouts.
class GuardianCareTeamPuppyDeco extends StatelessWidget {
  const GuardianCareTeamPuppyDeco({super.key});

  static const _puppyAspect = 1386 / 758;

  @override
  Widget build(BuildContext context) {
    final height = GuardianDashboardDecoThresholds.puppyHeight;
    final width = height * _puppyAspect;

    return GuardianDashboardAmbientDeco(
      child: Image.asset(
        GuardianDashboardDecoAssets.puppyBowl,
        key: const Key('guardian_dashboard_care_team_puppy_deco'),
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomRight,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Computes the horizontal width occupied by the pet preview rail content.
double guardianPetRailContentWidth({
  required int petCount,
  required double viewportWidth,
  required double cardWidth,
  required double addTileWidth,
  double separatorWidth = 12,
}) {
  if (petCount <= 0) return 0;
  return petCount * cardWidth +
      petCount * separatorWidth +
      addTileWidth;
}
