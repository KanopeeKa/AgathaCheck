import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile_completeness_dismissal_store.dart';

final profileCompletenessDismissalStoreProvider =
    FutureProvider<ProfileCompletenessDismissalStore>((ref) async {
      return ProfileCompletenessDismissalStore.create();
    });
