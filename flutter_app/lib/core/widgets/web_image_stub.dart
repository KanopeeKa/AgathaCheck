import 'package:flutter/material.dart';

class WebAssetImage extends StatelessWidget {
  final String assetPath;
  final double height;
  final double width;
  final BoxFit fit;
  final Widget? fallback;
  final bool clipOval;

  const WebAssetImage({
    super.key,
    required this.assetPath,
    required this.height,
    required this.width,
    this.fit = BoxFit.contain,
    this.fallback,
    this.clipOval = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return fallback ?? SizedBox(height: height, width: width);
      },
    );
  }
}
