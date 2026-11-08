import 'package:flutter/material.dart';

/// Overlay delete control for horizontal health document strips (48×48 touch target).
class HealthDocumentStripDeleteButton extends StatelessWidget {
  const HealthDocumentStripDeleteButton({
    super.key,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: Semantics(
        label: semanticsLabel,
        button: true,
        child: Material(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
              tooltip: semanticsLabel,
              onPressed: onPressed,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ),
    );
  }
}
