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
    'Ferret',
    'Horse / Poney',
    'Reptile',
    'Other',
  ];

  static const List<String> speciesWithoutNeutering = [
    'Bird',
    'Fish',
    'Reptile',
    'Hamster',
    'Ferret',
    'Horse / Poney',
  ];

  static String identificationTitle(String species, String petName) {
    switch (species) {
      case 'Fish':
        return '$petName has no identification';
      case 'Bird':
        return '$petName has no identification';
      case 'Reptile':
        return '$petName has no identification';
      case 'Horse / Poney':
        return '$petName has no identification';
      default:
        return '$petName has no identification';
    }
  }

  static String identificationMessage(String species) {
    switch (species) {
      case 'Fish':
        return 'Keeping a record of your fish helps track lineage, health history, and tank assignments. '
            'Use a tank label, photo log, or internal reference number to identify your fish and add it to their profile.';
      case 'Bird':
        return 'Birds can be identified with a closed leg ring fitted at a young age, or with a microchip implanted by a vet. '
            'Identification is important for proof of ownership and in case your bird escapes. '
            'Contact your vet or breeder to discuss the best option and add the ID to their profile.';
      case 'Reptile':
        return 'Reptiles can be identified with a microchip implanted by an experienced vet, or through photo documentation of unique markings. '
            'Some species may also be registered with a CITES permit number. '
            'Contact your vet for the best identification method and add the ID to their profile.';
      case 'Hamster':
        return 'Hamsters are rarely microchipped due to their small size. '
            'You can identify your hamster using distinct markings, photos, or an internal reference number. '
            'Add any identification details to their profile for your records.';
      case 'Ferret':
        return 'Ferrets can be microchipped just like cats and dogs, and it is recommended in case they escape. '
            'Many ferrets from breeders already have a microchip implanted. '
            'Contact your vet to get your ferret chipped and add the ID number to their profile.';
      case 'Horse / Poney':
        return 'Horses and ponies must be identified with a passport and microchip in most countries. '
            'Equine identification is a legal requirement for traceability, health records, and competition entry. '
            'Contact your vet or equine registry to ensure your animal is properly identified and add the ID to their profile.';
      case 'Rabbit':
        return 'Rabbits can be microchipped by a vet, which is recommended in case they escape. '
            'Identification helps prove ownership and track health records. '
            'Contact your vet to get your rabbit chipped and add the ID number to their profile.';
      default:
        return 'Microchipping is a legal requirement in many countries '
            'and helps reunite lost pets with their owners. A microchip '
            'is a small, permanent form of identification implanted '
            'under your pet\'s skin. Contact your vet to get your pet '
            'chipped and add the ID number to their profile.';
    }
  }
}
