import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/care_provider_field.dart';

/// People directory for care provider pickers — overridden in the experience layer.
final careProviderContactOptionsProvider =
    Provider<AsyncValue<List<CareProviderContactOption>>>((ref) {
      return const AsyncData([]);
    });
