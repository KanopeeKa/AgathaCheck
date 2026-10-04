enum ContactKind {
  person('person'),
  organisation('organisation');

  const ContactKind(this.wireValue);
  final String wireValue;

  static ContactKind fromWire(String? value) {
    switch (value) {
      case 'organisation':
        return ContactKind.organisation;
      case 'person':
      default:
        return ContactKind.person;
    }
  }
}
