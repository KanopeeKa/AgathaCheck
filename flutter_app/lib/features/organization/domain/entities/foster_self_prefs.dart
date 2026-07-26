enum FosterVisibleTo {
  otherFosters,
  admins,
  both,
  nobody;

  String get wire => switch (this) {
    FosterVisibleTo.otherFosters => 'other_fosters',
    FosterVisibleTo.admins => 'admins',
    FosterVisibleTo.both => 'both',
    FosterVisibleTo.nobody => 'nobody',
  };

  static FosterVisibleTo fromWire(String? value) {
    switch (value) {
      case 'other_fosters':
        return FosterVisibleTo.otherFosters;
      case 'admins':
        return FosterVisibleTo.admins;
      case 'nobody':
        return FosterVisibleTo.nobody;
      case 'both':
      default:
        return FosterVisibleTo.both;
    }
  }
}

enum FosterAddressVisibility {
  full,
  town,
  hidden;

  String get wire => name;

  static FosterAddressVisibility fromWire(String? value) {
    switch (value) {
      case 'town':
        return FosterAddressVisibility.town;
      case 'hidden':
        return FosterAddressVisibility.hidden;
      case 'full':
      default:
        return FosterAddressVisibility.full;
    }
  }
}

enum FosterContactVisibility {
  email,
  phone,
  neither,
  both;

  String get wire => switch (this) {
    FosterContactVisibility.email => 'email',
    FosterContactVisibility.phone => 'phone',
    FosterContactVisibility.neither => 'neither',
    FosterContactVisibility.both => 'both',
  };

  static FosterContactVisibility fromWire(String? value) {
    switch (value) {
      case 'email':
        return FosterContactVisibility.email;
      case 'phone':
        return FosterContactVisibility.phone;
      case 'neither':
        return FosterContactVisibility.neither;
      case 'both':
      default:
        return FosterContactVisibility.both;
    }
  }
}

enum FosterMessageNotificationChannel {
  inApp,
  email,
  both;

  String get wire => switch (this) {
    FosterMessageNotificationChannel.inApp => 'in_app',
    FosterMessageNotificationChannel.email => 'email',
    FosterMessageNotificationChannel.both => 'both',
  };

  static FosterMessageNotificationChannel fromWire(String? value) {
    switch (value) {
      case 'email':
        return FosterMessageNotificationChannel.email;
      case 'both':
        return FosterMessageNotificationChannel.both;
      case 'in_app':
      default:
        return FosterMessageNotificationChannel.inApp;
    }
  }
}

class FosterSelfPrefs {
  const FosterSelfPrefs({
    this.visibleTo = FosterVisibleTo.both,
    this.addressVisibility = FosterAddressVisibility.full,
    this.contactVisibility = FosterContactVisibility.both,
    this.messageChannel = FosterMessageNotificationChannel.inApp,
    this.rulesAgreementAt,
  });

  final FosterVisibleTo visibleTo;
  final FosterAddressVisibility addressVisibility;
  final FosterContactVisibility contactVisibility;
  final FosterMessageNotificationChannel messageChannel;
  final DateTime? rulesAgreementAt;

  bool get hasRulesAgreement => rulesAgreementAt != null;

  FosterSelfPrefs copyWith({
    FosterVisibleTo? visibleTo,
    FosterAddressVisibility? addressVisibility,
    FosterContactVisibility? contactVisibility,
    FosterMessageNotificationChannel? messageChannel,
    DateTime? rulesAgreementAt,
    bool clearRulesAgreement = false,
  }) {
    return FosterSelfPrefs(
      visibleTo: visibleTo ?? this.visibleTo,
      addressVisibility: addressVisibility ?? this.addressVisibility,
      contactVisibility: contactVisibility ?? this.contactVisibility,
      messageChannel: messageChannel ?? this.messageChannel,
      rulesAgreementAt: clearRulesAgreement
          ? null
          : (rulesAgreementAt ?? this.rulesAgreementAt),
    );
  }

  factory FosterSelfPrefs.fromJson(Map<String, dynamic> json) {
    return FosterSelfPrefs(
      visibleTo: FosterVisibleTo.fromWire(json['visible_to']?.toString()),
      addressVisibility: FosterAddressVisibility.fromWire(
        json['address_visibility']?.toString(),
      ),
      contactVisibility: FosterContactVisibility.fromWire(
        json['contact_visibility']?.toString(),
      ),
      messageChannel: FosterMessageNotificationChannel.fromWire(
        json['notification_message_channel']?.toString(),
      ),
      rulesAgreementAt: json['rules_agreement_at'] != null
          ? DateTime.tryParse(json['rules_agreement_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visible_to': visibleTo.wire,
      'address_visibility': addressVisibility.wire,
      'contact_visibility': contactVisibility.wire,
      'notification_message_channel': messageChannel.wire,
    };
  }
}
