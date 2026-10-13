import 'package:flutter/material.dart';

/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// The key used to store pet data in SharedPreferences.
  static const String petsStorageKey = 'pets_data';

  /// The application title displayed in the app bar.
  static const String appTitle = 'AgathaTrack';

  /// List of supported pet species.
  static const List<String> species = [
    'Dog',
    'Cat',
    'Bird',
    'Fish',
    'Rabbit',
    'Hamster',
    'Ferret',
    'Horse / Poney',
    'Other',
  ];

  static const List<String> speciesWithoutNeutering = [
    'Bird',
    'Fish',
    'Hamster',
    'Ferret',
    'Horse / Poney',
  ];

  static IconData speciesIcon(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'fish':
        return Icons.water;
      case 'rabbit':
        return Icons.cruelty_free;
      case 'hamster':
        return Icons.cruelty_free;
      case 'ferret':
        return Icons.pets;
      case 'horse / poney':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  static Widget speciesIconWidget(
    String species, {
    double size = 32,
    Color? color,
  }) {
    if (species.toLowerCase() == 'horse / poney') {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            '🐴',
            style: TextStyle(fontSize: size * 0.75, height: 1),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Icon(speciesIcon(species), size: size, color: color);
  }
}
