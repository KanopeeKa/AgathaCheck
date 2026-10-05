/// Public API for in-app notifications and notification settings.
library;

export 'domain/entities/app_notification.dart';
export 'domain/services/notification_inline_action_support.dart';
export 'domain/services/notification_inline_actions.dart';
export 'domain/entities/notification_kind.dart';
export 'domain/entities/notification_preferences.dart';
export 'domain/entities/notification_scope.dart';
export 'domain/repositories/notification_repository.dart';
export 'domain/services/notification_scope_rules.dart';
export 'presentation/providers/notification_inline_actions_provider.dart';
export 'presentation/providers/notification_providers.dart';
export 'presentation/screens/notification_settings_screen.dart';
export 'presentation/screens/notifications_screen.dart';
export 'presentation/screens/pending_actions_screen.dart';
export 'presentation/widgets/notification_panel.dart';
