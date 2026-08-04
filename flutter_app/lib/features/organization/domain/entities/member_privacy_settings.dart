/// Per-org member privacy settings (Organisation UX v3 Phase 8).
class MemberPrivacySettings {
  const MemberPrivacySettings({
    this.cardVisibility = CardVisibility.all,
    this.phoneVisibility = ContactVisibility.adminsOrNamed,
    this.emailVisibility = ContactVisibility.adminsOrNamed,
    this.addressVisibility = AddressVisibility.adminsOrNamed,
    this.grants = const MemberPrivacyGrants(),
    this.availableMembers = const [],
  });

  final CardVisibility cardVisibility;
  final ContactVisibility phoneVisibility;
  final ContactVisibility emailVisibility;
  final AddressVisibility addressVisibility;
  final MemberPrivacyGrants grants;
  final List<MemberPrivacyMemberOption> availableMembers;

  MemberPrivacySettings copyWith({
    CardVisibility? cardVisibility,
    ContactVisibility? phoneVisibility,
    ContactVisibility? emailVisibility,
    AddressVisibility? addressVisibility,
    MemberPrivacyGrants? grants,
    List<MemberPrivacyMemberOption>? availableMembers,
  }) {
    return MemberPrivacySettings(
      cardVisibility: cardVisibility ?? this.cardVisibility,
      phoneVisibility: phoneVisibility ?? this.phoneVisibility,
      emailVisibility: emailVisibility ?? this.emailVisibility,
      addressVisibility: addressVisibility ?? this.addressVisibility,
      grants: grants ?? this.grants,
      availableMembers: availableMembers ?? this.availableMembers,
    );
  }

  Map<String, dynamic> toJson() => {
    'card_visibility': cardVisibility.wireValue,
    'phone_visibility': phoneVisibility.wireValue,
    'email_visibility': emailVisibility.wireValue,
    'address_visibility': addressVisibility.wireValue,
    'grants': grants.toJson(),
  };

  factory MemberPrivacySettings.fromJson(Map<String, dynamic> json) {
    return MemberPrivacySettings(
      cardVisibility: CardVisibility.fromWire(
        json['card_visibility'] as String?,
      ),
      phoneVisibility: ContactVisibility.fromWire(
        json['phone_visibility'] as String?,
      ),
      emailVisibility: ContactVisibility.fromWire(
        json['email_visibility'] as String?,
      ),
      addressVisibility: AddressVisibility.fromWire(
        json['address_visibility'] as String?,
      ),
      grants: MemberPrivacyGrants.fromJson(
        json['grants'] as Map<String, dynamic>?,
      ),
      availableMembers: (json['available_members'] as List<dynamic>? ?? [])
          .map(
            (row) =>
                MemberPrivacyMemberOption.fromJson(row as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class MemberPrivacyGrants {
  const MemberPrivacyGrants({
    this.card = const [],
    this.phone = const [],
    this.email = const [],
    this.address = const [],
  });

  final List<String> card;
  final List<String> phone;
  final List<String> email;
  final List<String> address;

  MemberPrivacyGrants copyWith({
    List<String>? card,
    List<String>? phone,
    List<String>? email,
    List<String>? address,
  }) {
    return MemberPrivacyGrants(
      card: card ?? this.card,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
    'card': card,
    'phone': phone,
    'email': email,
    'address': address,
  };

  factory MemberPrivacyGrants.fromJson(Map<String, dynamic>? json) {
    final data = json ?? {};
    List<String> ids(String key) =>
        (data[key] as List<dynamic>? ?? []).map((e) => '$e').toList();
    return MemberPrivacyGrants(
      card: ids('card'),
      phone: ids('phone'),
      email: ids('email'),
      address: ids('address'),
    );
  }
}

class MemberPrivacyMemberOption {
  const MemberPrivacyMemberOption({
    required this.userId,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String displayName;
  final String role;

  factory MemberPrivacyMemberOption.fromJson(Map<String, dynamic> json) {
    return MemberPrivacyMemberOption(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

enum CardVisibility {
  all('all'),
  admins('admins'),
  named('named');

  const CardVisibility(this.wireValue);
  final String wireValue;

  static CardVisibility fromWire(String? value) {
    return CardVisibility.values.firstWhere(
      (item) => item.wireValue == value,
      orElse: () => CardVisibility.all,
    );
  }
}

enum ContactVisibility {
  admins('admins'),
  adminsAndFosterManagers('admins_and_foster_managers'),
  adminsOrNamed('admins_or_named'),
  named('named');

  const ContactVisibility(this.wireValue);
  final String wireValue;

  static ContactVisibility fromWire(String? value) {
    return ContactVisibility.values.firstWhere(
      (item) => item.wireValue == value,
      orElse: () => ContactVisibility.adminsOrNamed,
    );
  }
}

enum AddressVisibility {
  adminsOrNamed('admins_or_named'),
  admins('admins'),
  named('named'),
  hidden('hidden');

  const AddressVisibility(this.wireValue);
  final String wireValue;

  static AddressVisibility fromWire(String? value) {
    return AddressVisibility.values.firstWhere(
      (item) => item.wireValue == value,
      orElse: () => AddressVisibility.adminsOrNamed,
    );
  }
}
