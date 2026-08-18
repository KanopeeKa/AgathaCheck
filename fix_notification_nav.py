import re

with open('flutter_app/lib/features/notifications/presentation/utils/notification_navigation.dart', 'r') as f:
    content = f.read()

new_navigate = """import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/experience/domain/entities/app_experience.dart';
import '../../../../features/experience/presentation/providers/experience_providers.dart';

/// Navigates from a notification tap to the appropriate destination.
///
/// Care notifications with a health entry open the view-entry screen.
/// Administrative pending-object types open the pending-actions surface.
void navigateFromNotification(
  BuildContext context,
  WidgetRef ref,
  AppNotification notification,
) {
  final wireType = notification.wireType;
  
  final organizationId = notification.organizationId;
  if (organizationId != null && organizationId.isNotEmpty) {
    ref.read(activeExperienceProvider.notifier).state = AppExperience.organization;
  } else {
    ref.read(activeExperienceProvider.notifier).state = AppExperience.guardian;
  }
"""

content = re.sub(
    r"/// Navigates from a notification tap to the appropriate destination\.\n///\n/// Care notifications with a health entry open the view-entry screen\.\n/// Administrative pending-object types open the pending-actions surface\.\nvoid navigateFromNotification\(\n  BuildContext context,\n  AppNotification notification,\n\) \{\n  final wireType = notification\.wireType;",
    new_navigate,
    content
)

with open('flutter_app/lib/features/notifications/presentation/utils/notification_navigation.dart', 'w') as f:
    f.write(content)
