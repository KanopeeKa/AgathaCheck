import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/router/pet_care_nav_paths.dart';
import 'package:pet_profile_app/features/experience/presentation/widgets/pet_care_bottom_navigation.dart';

void main() {
  group('isPetCareActionsNavPath', () {
    test('matches global Actions queue routes', () {
      expect(isPetCareActionsNavPath('/pc/events'), isTrue);
      expect(isPetCareActionsNavPath('/pc/events?filter=due'), isFalse);
    });

    test('matches pet-scoped All care and Care Item detail routes', () {
      expect(isPetCareActionsNavPath('/pet/pet-1/events'), isTrue);
      expect(isPetCareActionsNavPath('/pet/pet-1/events/entry-1'), isTrue);
      expect(isPetCareActionsNavPath('/pet/pet-1/events/entry-1/edit'), isTrue);
    });

    test('matches legacy care-rhythms redirect source path', () {
      expect(isPetCareActionsNavPath('/pet/pet-1/care-rhythms'), isTrue);
    });

    test('matches pet-scoped add-care form routes', () {
      expect(isPetCareActionsNavPath('/pet/pet-1/care/add'), isTrue);
      expect(isPetCareActionsNavPath('/pet/pet-1/health/add'), isTrue);
      expect(isPetCareActionsNavPath('/pet/pet-1/other/add'), isTrue);
      expect(isPetCareActionsNavPath('/pet/pet-1/health/edit/entry-9'), isTrue);
    });

    test('matches global care entry routes', () {
      expect(isPetCareActionsNavPath('/health'), isTrue);
      expect(isPetCareActionsNavPath('/health/add'), isTrue);
      expect(isPetCareActionsNavPath('/health/edit/entry-1'), isTrue);
      expect(isPetCareActionsNavPath('/care/add'), isTrue);
    });

    test('does not match pet profile or quieter destinations', () {
      expect(isPetCareActionsNavPath('/pet/pet-1'), isFalse);
      expect(isPetCareActionsNavPath('/pet/pet-1/timeline'), isFalse);
      expect(isPetCareActionsNavPath('/pet/pet-1/weight'), isFalse);
      expect(isPetCareActionsNavPath('/pet/pet-1/health-issues'), isFalse);
      expect(isPetCareActionsNavPath('/pc/home'), isFalse);
      expect(isPetCareActionsNavPath('/pc/pets'), isFalse);
    });
  });

  group('PetCareBottomNavigation Actions tab index', () {
    const actionsTabIndex = 2;

    test('selects Actions for every care route', () {
      const careRoutes = [
        '/pc/events',
        '/pet/pet-1/events',
        '/pet/pet-1/events/entry-1',
        '/pet/pet-1/events/entry-1/edit',
        '/pet/pet-1/care-rhythms',
        '/pet/pet-1/care/add',
        '/pet/pet-1/health/add',
        '/pet/pet-1/other/add',
        '/care/add',
        '/health/add',
      ];
      for (final route in careRoutes) {
        expect(
          PetCareBottomNavigation.indexFor(route),
          actionsTabIndex,
          reason: route,
        );
      }
    });
  });
}
