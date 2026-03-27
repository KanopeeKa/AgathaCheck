import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfilePhotoAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final Uint8List? photoBytes;
  final double radius;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const ProfilePhotoAvatar({
    super.key,
    this.photoUrl,
    required this.initials,
    this.photoBytes,
    this.radius = 48,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: photoBytes != null
                ? MemoryImage(photoBytes!)
                : (photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null) as ImageProvider?,
            child: (photoBytes == null && (photoUrl == null || photoUrl!.isEmpty))
                ? Text(
                    initials,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  )
                : null,
          ),
          if (showEditIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt,
                    size: 16, color: theme.colorScheme.onPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
