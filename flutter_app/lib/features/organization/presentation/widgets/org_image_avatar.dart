import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/organization.dart';

/// Circular org image used in list cards and thumbnails (pet-card style).
class OrgImageAvatar extends StatelessWidget {
  const OrgImageAvatar({
    super.key,
    required this.imageUrl,
    required this.type,
    this.radius = 28,
    this.resolvedUrl,
  });

  final String imageUrl;
  final OrganizationType type;
  final double radius;
  final String? resolvedUrl;

  @override
  Widget build(BuildContext context) {
    final isPro = type == OrganizationType.professional;
    final placeholderColor = isPro ? AppTheme.orgIconBg : AppTheme.orgCharityBg;
    final iconColor = isPro ? AppTheme.orgIconFg : AppTheme.orgCharityFg;

    Widget child;
    final image = _buildImage();
    if (image != null) {
      child = ClipOval(child: image);
    } else {
      child = Icon(
        isPro ? Icons.business : Icons.volunteer_activism,
        color: iconColor,
        size: radius,
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: placeholderColor,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(80),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget? _buildImage() {
    if (imageUrl.isEmpty) return null;

    if (!imageUrl.startsWith('/') &&
        !imageUrl.startsWith('http://') &&
        !imageUrl.startsWith('https://')) {
      try {
        final bytes = base64Decode(imageUrl);
        return Image.memory(
          bytes,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return null;
      }
    }

    final url = resolvedUrl ?? imageUrl;
    if (url.isEmpty) return null;
    return Image.network(
      url,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}

/// Org logo shown on the detail page header (rectangular, not cropped to circle).
class OrgLogoImage extends StatelessWidget {
  const OrgLogoImage({
    super.key,
    required this.logoUrl,
    this.resolvedUrl,
    this.height = 56,
  });

  final String logoUrl;
  final String? resolvedUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isEmpty) return const SizedBox.shrink();

    final image = _buildImage();
    if (image == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(height: height, child: image),
    );
  }

  Widget? _buildImage() {
    if (!logoUrl.startsWith('/') &&
        !logoUrl.startsWith('http://') &&
        !logoUrl.startsWith('https://')) {
      try {
        final bytes = base64Decode(logoUrl);
        return Image.memory(bytes, height: height, fit: BoxFit.contain);
      } catch (_) {
        return null;
      }
    }

    final url = resolvedUrl ?? logoUrl;
    if (url.isEmpty) return null;
    return Image.network(
      url,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
