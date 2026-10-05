/// Barrel file for the veterinarian feature.
///
/// Re-exports all public classes from the vet feature's domain,
/// data, and presentation layers for convenient access.
library;

export 'domain/entities/vet.dart';
export 'domain/repositories/vet_repository.dart';
export 'domain/usecases/get_all_vets.dart';
export 'domain/usecases/create_vet.dart';
export 'domain/usecases/update_vet.dart';
export 'domain/usecases/delete_vet.dart';
export 'presentation/providers/vet_providers.dart';
export 'presentation/screens/vet_list_screen.dart';
export 'presentation/screens/vet_form_screen.dart';
