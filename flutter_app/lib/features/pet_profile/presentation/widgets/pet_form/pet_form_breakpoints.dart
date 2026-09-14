import '../../../../../core/widgets/form/app_form_breakpoints.dart';

typedef PetFormLayoutSize = AppFormLayoutSize;

abstract final class PetFormBreakpoints {
  static const double phoneMax = AppFormBreakpoints.phoneMax;
  static const double tabletMin = AppFormBreakpoints.tabletMin;
  static const double desktopMin = AppFormBreakpoints.desktopMin;
  static const double tabletContentMaxWidth =
      AppFormBreakpoints.tabletContentMaxWidth;
  static const double desktopPageMaxWidth =
      AppFormBreakpoints.desktopPageMaxWidth;
  static const double desktopFormMaxWidth =
      AppFormBreakpoints.desktopFormMaxWidth;

  static PetFormLayoutSize layoutForWidth(double width) =>
      AppFormBreakpoints.layoutForWidth(width);
}
