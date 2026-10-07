import 'app_tokens.dart';

/// Centralized responsive-layout decisions for the desktop POS.
///
/// Keeping these calculations outside screens prevents features from inventing
/// their own breakpoint and density rules.
class AppLayout {
  const AppLayout._();

  static const double minimumDesktopWidth = 1024;
  static const double minimumDesktopHeight = 720;

  /// A settings/card grid uses its own available pane width, not the window.
  static int settingsColumnCount(double availableWidth) =>
      availableWidth < 900 ? 2 : 3;

  static const double desktopCompact = 1366;
  static const double desktopWide = 1920;
  static const double desktopUltraWide = 2560;
  static const double salesPanelStandard = 500;

  /// Use a rail when navigation would crowd the task workspace.
  static bool useNavigationRail(double clientWidth) => clientWidth < 1200;

  /// Reserve most of the actual workspace for product selection.
  static double salesSidePanelWidth(double availableWidth) =>
      (availableWidth * 0.42).clamp(360.0, AppTokens.panelWidth2560);

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
