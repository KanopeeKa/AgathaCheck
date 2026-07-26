/// Per-org admin self-management prefs (Phase 3 stub — persist via
/// `notification_preferences` org extension when backend lands).
enum AdminPhoneVisibility {
  fosters,
  admins,
  all,
  nobody;

  String get wire => name;
}

enum AdminMessageNotificationChannel {
  inApp,
  email,
  both;

  String get wire => name;
}

class AdminContactSelfPrefs {
  const AdminContactSelfPrefs({
    this.phoneVisibility = AdminPhoneVisibility.admins,
    this.messageChannel = AdminMessageNotificationChannel.inApp,
  });

  final AdminPhoneVisibility phoneVisibility;
  final AdminMessageNotificationChannel messageChannel;

  AdminContactSelfPrefs copyWith({
    AdminPhoneVisibility? phoneVisibility,
    AdminMessageNotificationChannel? messageChannel,
  }) {
    return AdminContactSelfPrefs(
      phoneVisibility: phoneVisibility ?? this.phoneVisibility,
      messageChannel: messageChannel ?? this.messageChannel,
    );
  }
}
