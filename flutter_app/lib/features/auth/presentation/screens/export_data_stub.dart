import 'dart:typed_data';

/// Whether the current platform can save or download an export file.
bool get isUserDataExportDeliveryAvailable => false;

/// Delivers encoded export bytes to the user. Must not be called when
/// [isUserDataExportDeliveryAvailable] is false.
Future<bool> deliverUserDataExport(Uint8List bytes) async {
  throw UnsupportedError(
    'User data export delivery is not available on this platform.',
  );
}
