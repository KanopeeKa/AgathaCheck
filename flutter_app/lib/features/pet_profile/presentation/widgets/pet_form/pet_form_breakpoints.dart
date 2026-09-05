/// Layout breakpoints for the add/edit pet form.
enum PetFormLayoutSize { phone, tablet, desktop }

/// Width thresholds and max-width constraints for responsive pet form layouts.
abstract final class PetFormBreakpoints {
  static const double phoneMax = 599;
  static const double tabletMin = 600;
  static const double desktopMin = 1024;

  static const double tabletContentMaxWidth = 720;
  static const double desktopPageMaxWidth = 1100;
  static const double desktopFormMaxWidth = 560;

  static PetFormLayoutSize layoutForWidth(double width) {
    if (width >= desktopMin) return PetFormLayoutSize.desktop;
    if (width >= tabletMin) return PetFormLayoutSize.tablet;
    return PetFormLayoutSize.phone;
  }
}
