enum ContactStatus {
  active('active'),
  inactive('inactive');

  const ContactStatus(this.wireValue);
  final String wireValue;

  static ContactStatus fromWire(String? value) {
    switch (value) {
      case 'inactive':
        return ContactStatus.inactive;
      case 'active':
      default:
        return ContactStatus.active;
    }
  }
}
