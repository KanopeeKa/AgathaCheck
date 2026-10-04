enum ContactGroup {
  carer('carer'),
  professional('professional');

  const ContactGroup(this.wireValue);
  final String wireValue;

  static ContactGroup fromWire(String? value) {
    switch (value) {
      case 'professional':
        return ContactGroup.professional;
      case 'carer':
      default:
        return ContactGroup.carer;
    }
  }
}
