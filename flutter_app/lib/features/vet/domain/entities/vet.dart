/// Represents a veterinarian entity in the domain layer.
///
/// This is the core business object that holds all information
/// about a veterinarian contact. It is immutable and uses
/// value-based equality on [id].
class Vet {
  /// Creates a new [Vet] instance.
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

  /// The unique identifier for this veterinarian.
  final String id;

  /// The name of the veterinarian or veterinary practice.
  final String name;

  /// The phone number of the veterinarian.
  final String phone;

  /// The email address of the veterinarian.
  final String email;

  /// The website URL of the veterinarian or practice.
  final String website;

  /// The physical address of the veterinary practice.
  final String address;

  /// Additional notes about the veterinarian.
  final String notes;

  /// The timestamp when this veterinarian record was created.
  final DateTime? createdAt;

  /// The timestamp when this veterinarian record was last updated.
  final DateTime? updatedAt;

  /// Creates a copy of this [Vet] with the given fields replaced.
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
