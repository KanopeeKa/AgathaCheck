/// Shared layout constants for organisation profile hero (display + edit).
abstract final class OrgProfileHeroLayout {
  static const double coverHeight = 180;
  static const double logoHeight = 96;
  static const double logoOverlap = 48;
  static const double horizontalPadding = 16;
  static const double bandGap = 12;
  static const double coverUploadFabInset = 12;
  static const double coverUploadFabSize = 40;

  /// Right inset for cover guidance so text clears the upload FAB.
  static double get coverGuidanceRightInset =>
      coverUploadFabInset + coverUploadFabSize;
}
