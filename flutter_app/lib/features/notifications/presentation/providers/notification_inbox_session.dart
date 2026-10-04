import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/notification_inbox_v2_rules.dart';

/// Session-only remembered inbox tab (FR-IN-7); resets on app restart.
final notificationInboxSessionTabProvider =
    StateProvider<NotificationInboxTab>((ref) => NotificationInboxTab.activity);
