class ContactUsage {
  const ContactUsage({
    required this.kind,
    required this.id,
    required this.label,
    this.petId,
    this.active,
  });

  final String kind;
  final String id;
  final String label;
  final String? petId;
  final bool? active;

  @override
  bool operator ==(Object other) {
    return other is ContactUsage &&
        other.kind == kind &&
        other.id == id &&
        other.label == label &&
        other.petId == petId &&
        other.active == active;
  }

  @override
  int get hashCode => Object.hash(kind, id, label, petId, active);
}
