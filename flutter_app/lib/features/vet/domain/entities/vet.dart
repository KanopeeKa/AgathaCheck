class Vet {
  const Vet({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Vet copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vet(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
