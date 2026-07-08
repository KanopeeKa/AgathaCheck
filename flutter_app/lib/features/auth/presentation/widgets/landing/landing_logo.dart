import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../../core/widgets/web_image.dart';

Widget buildLandingLogo(ThemeData theme, {required double size}) {
  final fallback = Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Icon(
        Icons.pets,
        size: size * 0.55,
        color: theme.colorScheme.primary,
      ),
    ),
  );

  return Semantics(
    label: 'Agatha Track logo',
    child: kIsWeb
        ? WebAssetImage(
            assetPath: 'assets/logo.jpg',
            height: size,
            width: size,
            fit: BoxFit.cover,
            fallback: fallback,
            clipOval: true,
          )
        : ClipOval(
            child: Image.asset(
              'assets/logo.jpg',
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            ),
          ),
  );
}
