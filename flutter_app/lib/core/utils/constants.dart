/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// The key used to store pet data in SharedPreferences.
  static const String petsStorageKey = 'pets_data';

  /// The application title displayed in the app bar.
  static const String appTitle = 'Agatha Check';

  /// List of supported pet species.
  static const List<String> species = [
    'Dog',
    'Cat',
    'Bird',
    'Fish',
    'Rabbit',
    'Hamster',
    'Reptile',
    'Other',
  ];
}
