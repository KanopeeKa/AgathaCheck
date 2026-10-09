import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/care/care_suggestion_form_accept.dart';
import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';

Override careSuggestionFormAcceptHandlerOverride() {
  return careSuggestionFormAcceptHandlerProvider.overrideWith(
    (ref) => careIntelligenceSuggestionFormAcceptHandler(),
  );
}
