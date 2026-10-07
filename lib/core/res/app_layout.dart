import 'app_tokens.dart';

/// Centralized responsive-layout decisions for the desktop POS.
///
/// Keeping these calculations outside screens prevents features from inventing
/// their own breakpoint and density rules.
class AppLayout {
  const AppLayout._();

  static const double desktopCompact = 1366;
  static const double desktopWide = 1920;
  static const double desktopUltraWide = 2560;
  static const double salesPanelStandard = 500;

  static double salesSidePanelWidth(double viewportWidth) {
    if (viewportWidth >= desktopUltraWide) {
      return AppTokens.panelWidth2560;
    }
    if (viewportWidth >= desktopWide) {
      return AppTokens.panelWidth1920;
    }
    if (viewportWidth >= desktopCompact) {
      return salesPanelStandard;
    }
    return AppTokens.sidebarDefaultWidth;
  }

  static int productGridColumnCount(
    double availableWidth, {
    double preferredTileWidth = 180,
    int minimum = 4,
    int maximum = 8,
  }) {
    assert(preferredTileWidth > 0);
    assert(minimum > 0);
    assert(maximum >= minimum);

    final count = (availableWidth / preferredTileWidth).floor();
    return count.clamp(minimum, maximum);
  }
}
