import 'dart:convert';
import 'package:flutter/material.dart';

class PetPhotoSection extends StatelessWidget {
  final String? photoBase64;
  final VoidCallback onPickImage;

  const PetPhotoSection({
    super.key,
    required this.photoBase64,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 56,
            backgroundColor: Colors.grey[200],
            backgroundImage: photoBase64 != null
                ? MemoryImage(base64Decode(photoBase64!))
                : null,
            child: photoBase64 == null
                ? const Icon(Icons.pets, size: 48, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton.small(
              heroTag: 'pick_pet_photo',
              onPressed: onPickImage,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }
}
