/// Platform-agnostic interface for exporting user data.
Future<void> exportUserDataWebOnly(List<int> bytes) async {
  throw UnsupportedError('Web export is only supported on web platform.');
}
