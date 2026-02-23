/// Desktop-specific dimensions and constants for the POS application.
/// 
/// RTL-AWARE DIMENSIONS - Now includes separate values for:
/// - LTR (Left-to-Right) layouts - English
/// - RTL (Right-to-Left) layouts - Urdu
class DesktopDimensions {
  const DesktopDimensions._(); // Private constructor

  // Header & Footer
  static const double headerHeight = 70.0;
  static const double footerHeight = 40.0;
  static const double actionBarHeight = 70.0;
  static const double headerTitleFontSize = 18.0;
  static const double headerClockFontSize = 16.0;
  static const double headerPaddingHorizontal = 20.0;

  // Panels
  static const double sidebarMinWidth = 300.0;
  static const double sidebarMaxWidth = 500.0;
  static const double sidebarDefaultWidth = 450.0;
  static const double clockWidth = 200.0;
  static const double departmentPaneWidth = 250.0;

  // --- Spacing ---
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingStandard = 12.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 20.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  static const double spacingXXXLarge = 64.0;
  static const double spacingXXSmall = 2.0;

  // --- Border Radius ---
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double dialogBorderRadius = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const double smallBorderRadius = 6.0;
  static const double mediumBorderRadius = 8.0;
  static const double extraSmallBorderRadius = 4.0;

  // --- Card Dimensions ---
  static const double cardElevation = 2.0;
  static const double cardPadding = 16.0;
  static const double aboutLogoSize = 100.0;
  static const double aboutIconSize = 60.0;
  static const double aboutIconScale = 48.0;
  static const double labelWidthStandard = 150.0;

  // KPIs
  static const double kpiHeight = 135.0;
  static const double kpiIconSize = 24.0;
  static const double kpiValueSize = 24.0;

  // --- Dialog Dimensions ---
  // UPDATED: Wider dialogs for Urdu text
  static const double dialogWidth = 500.0;
  static const double dialogHeight = 400.0;
  static const double dialogPadding = 24.0;
  
  // Small Dialogs (Confirmations, simple forms)
  static const double dialogMinWidthSmallLTR = 400.0;
  static const double dialogMaxWidthSmallLTR = 500.0;
  static const double dialogMinWidthSmallRTL = 450.0; // +50px for Urdu
  static const double dialogMaxWidthSmallRTL = 550.0;
  
  // Medium Dialogs (Forms with multiple fields)
  static const double dialogMinWidthMediumLTR = 450.0;
  static const double dialogMaxWidthMediumLTR = 550.0;
  static const double dialogMinWidthMediumRTL = 500.0; // +50px for Urdu
  static const double dialogMaxWidthMediumRTL = 600.0;
  
  // Large Dialogs (Complex forms, checkout)
  static const double dialogMinWidthLargeLTR = 500.0;
  static const double dialogMaxWidthLargeLTR = 650.0;
  static const double dialogMinWidthLargeRTL = 550.0; // +50px for Urdu
  static const double dialogMaxWidthLargeRTL = 700.0;

  // --- Typography ---
  static const double appTitleSize = 20.0;
  static const double headingSize = 18.0;
  static const double bodySize = 14.0;
  static const double captionSize = 11.0;
  static const double breadcrumbFontSize = 12.0;
  static const double statValueFontSize = 18.0;
  static const double titleLargeSize = 22.0;
  static const double bodyLargeSize = 16.0;
  static const double labelMediumSize = 13.0;
  static const double badgeFontSize = 10.0;

  // Responsive Breakpoints
  static const double breakpointLarge = 1400.0;
  static const double breakpointMedium = 1150.0;
  static const double breakpointSmall = 950.0;

  // Panel Widths (Responsive breakpoints)
  static const double panelWidth1366 = 450.0;
  static const double panelWidth1920 = 550.0;
  static const double panelWidth2560 = 600.0;

  // Sidebar Widths
  static const double sidebarWidthLarge = 480.0;
  static const double sidebarWidthMedium = 400.0;
  static const double sidebarWidthSmall = 350.0;
  static const double sidebarWidth = 240.0;
  static const double sidebarCollapsedWidth = 64.0;

  // Logo Size
  static const double logoSize = 80.0;

  // --- Icon Sizes ---
  static const double iconSizeXXXSmall = 8.0;
  static const double iconSizeXSmall = 12.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeSmallMedium = 18.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;
  static const double iconSizeXXLarge = 48.0;

  // --- Button Heights ---
  static const double buttonHeight = 40.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Inputs
  static const double inputHeight = 40.0;
  static const double inputHeightSmall = 40.0;
  static const double inputHeightMedium = 48.0;
  static const double inputHeightLarge = 56.0;

  // Tables & Lists
  static const double tableRowHeight = 40.0;
  static const double tableHeaderHeight = 40.0;
  static const double tableDataRowHeight = 48.0;
  static const double tableHeaderFontSize = 13.0;
  static const double listItemHeight = 56.0;
  static const double listItemHeightCompact = 48.0;
  static const double selectionAreaHeight = 64.0;
  static const double dataRowHeight = 48.0;
  static const double dataRowHeightCompact = 40.0;

  // Forms/Input screens
  static const double formFieldHeight = 48.0;
  static const double formFieldBorderRadius = 8.0;
  static const double formLabelWidth = 120.0;

  // --- Elevation ---
  static const double elevationLow = 1.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // --- AppBar ---
  static const double appBarHeight = 64.0;
  static const double toolbarHeight = 56.0;

  // Badges/Chips
  static const double badgeHeight = 24.0;
  static const double badgeBorderRadius = 12.0;
  
  // Dividers/Separators
  static const double dividerThickness = 1.0;
  static const double separatorHeight = 1.0;

  static const double scrollLoadThreshold = 64.0;
}
