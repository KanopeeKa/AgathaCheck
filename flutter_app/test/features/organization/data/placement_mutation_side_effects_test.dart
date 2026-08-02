import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/notifications/presentation/providers/notification_providers.dart';
import 'package:pet_profile_app/features/organization/presentation/providers/foster_placements_providers.dart';

void main() {
  test(
    'invalidatePlacementMutationProviders invalidates pending and notifications',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(pendingFosterPlacementsProvider);
      container.read(pendingAdoptionPlacementsProvider);
      container.read(notificationsProvider);

      invalidatePlacementMutationProviders(container);

      expect(
        container.read(pendingFosterPlacementsProvider),
        isA<AsyncLoading>(),
      );
      expect(
        container.read(pendingAdoptionPlacementsProvider),
        isA<AsyncLoading>(),
      );
      expect(container.read(notificationsProvider), isA<AsyncLoading>());
    },
  );
}
