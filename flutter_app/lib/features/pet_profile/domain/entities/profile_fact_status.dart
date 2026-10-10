/// Wire values for `identificationStatus` / `neuterStatus` on the pet API.
const String profileFactStatusYes = 'yes';
const String profileFactStatusNo = 'no';
const String profileFactStatusUnknown = 'unknown';

const Set<String> profileFactStatusValues = {
  profileFactStatusYes,
  profileFactStatusNo,
  profileFactStatusUnknown,
};

/// Parses API JSON; unknown or invalid values default to [profileFactStatusUnknown].
String parseProfileFactStatusWire(dynamic raw) {
  if (raw == null) return profileFactStatusUnknown;
  final value = raw.toString().toLowerCase();
  if (profileFactStatusValues.contains(value)) return value;
  return profileFactStatusUnknown;
}
