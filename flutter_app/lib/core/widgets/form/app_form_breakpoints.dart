/// Layout breakpoints for harmonised create/edit forms.
enum AppFormLayoutSize { phone, tablet, desktop }

/// Width thresholds and max-width constraints for responsive form layouts.
abstract final class AppFormBreakpoints {
  static const double phoneMax = 599;
  static const double tabletMin = 600;
  static const double desktopMin = 1024;

  static const double tabletContentMaxWidth = 720;
  static const double desktopPageMaxWidth = 1100;
  static const double desktopFormMaxWidth = 560;

  static AppFormLayoutSize layoutForWidth(double width) {
    if (width >= desktopMin) return AppFormLayoutSize.desktop;
    if (width >= tabletMin) return AppFormLayoutSize.tablet;
    return AppFormLayoutSize.phone;
  }
}
