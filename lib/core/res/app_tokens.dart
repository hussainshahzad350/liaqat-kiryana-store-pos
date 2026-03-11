/// Single source of truth for all design tokens and dimensions in the POS application.
/// This file consolidates values from previous dimension files to ensure consistency
/// across all platforms and layouts (LTR English and RTL Urdu).
class AppTokens {
  const AppTokens._();

  // Spacing
  static const double spacingXXSmall = 2.0;
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingStandard = 12.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 20.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  static const double spacingXXXLarge = 64.0;

  // Space (numeric tokens)
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // Border Radius
  static const double radius4 = 4.0;
  static const double radius6 = 6.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;

  // Legacy border radius names (use radius* instead)
  static const double borderRadius = radius8;
  static const double borderRadiusSmall = radius4;
  static const double borderRadiusMedium = radius8;
  static const double borderRadiusLarge = radius12;
  static const double dialogBorderRadius = radius16;
  static const double cardBorderRadius = radius12;
  static const double buttonBorderRadius = radius8;
  static const double smallBorderRadius = radius6;
  static const double mediumBorderRadius = radius8;
  static const double extraSmallBorderRadius = radius4;
  static const double formFieldBorderRadius = radius8;
  static const double badgeBorderRadius = radius12;

  // Layout
  // Header & Footer
  static const double headerHeight = 56.0;
  static const double footerHeight = 40.0;
  static const double actionBarHeight = 70.0;
  static const double appBarHeight = 64.0;
  static const double toolbarHeight = 56.0;
  static const double sidebarHeaderHeight = 100.0;
  static const double sidebarFooterHeight = 50.0;

  // Sidebar
  static const double sidebarExpandedWidth = 250.0;
  static const double sidebarCollapsedWidth = 64.0;
  static const double sidebarMinWidth = 300.0;
  static const double sidebarMaxWidth = 500.0;
  static const double sidebarDefaultWidth = 450.0;
  static const double sidebarWidth = 240.0;
  static const double sidebarWidthLarge = 480.0;
  static const double sidebarWidthMedium = 400.0;
  static const double sidebarWidthSmall = 350.0;

  // Panels
  static const double clockWidth = 200.0;
  static const double departmentPaneWidth = 250.0;
  static const double panelWidth1366 = 450.0;
  static const double panelWidth1920 = 550.0;
  static const double panelWidth2560 = 600.0;

  // Menu Items
  static const double menuItemHeight = 40.0;
  static const double menuItemIconSize = 22.0;
  // ⚠️ Font size tokens below — prefer Theme.of(context).textTheme over these.
  // These exist for legacy sidebar/table widgets migrating from AppDimensions.
  static const double menuItemFontSize = 13.0;

  // Cards
  static const double cardPadding = 16.0;
  static const double cardElevation = 2.0;

  // KPIs
  static const double kpiHeight = 135.0;
  static const double kpiIconSize = 24.0;
  static const double kpiValueSize = 24.0;

  // Logo
  static const double logoSize = 80.0;
  static const double aboutLogoSize = 100.0;
  static const double aboutIconSize = 60.0;
  static const double aboutIconScale = 48.0;

  // Buttons
  static const double buttonHeight = 40.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Inputs
  static const double inputHeight = 40.0;
  static const double inputHeightSmall = 40.0;
  static const double inputHeightMedium = 48.0;
  static const double inputHeightLarge = 56.0;
  static const double formFieldHeight = 48.0;
  static const double formLabelWidth = 120.0;
  static const double labelWidthStandard = 150.0;

  // Tables & Lists
  static const double tableRowHeight = 40.0;
  static const double tableHeaderHeight = 40.0;
  static const double tableDataRowHeight = 48.0;
  // ⚠️ Font size tokens below — prefer Theme.of(context).textTheme over these.
  // These exist for legacy sidebar/table widgets migrating from AppDimensions.
  static const double tableHeaderFontSize = 13.0;
  static const double listItemHeight = 56.0;
  static const double listItemHeightCompact = 48.0;
  static const double selectionAreaHeight = 64.0;
  static const double dataRowHeight = 48.0;
  static const double dataRowHeightCompact = 40.0;

  // Badges/Chips
  static const double badgeHeight = 24.0;

  // Dividers/Separators
  static const double dividerThickness = 1.0;
  static const double separatorHeight = 1.0;

  // Misc
  static const double headerPaddingHorizontal = 20.0;
  static const double scrollLoadThreshold = 64.0;

  // Icons
  static const double iconSizeXXXSmall = 8.0;
  static const double iconSizeXSmall = 12.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeSmallMedium = 18.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 32.0;
  static const double iconSizeXXLarge = 48.0;

  // Dialogs
  static const double dialogWidth = 500.0;
  static const double dialogHeight = 400.0;
  static const double dialogPadding = 24.0;
  static const double dialogRtlExtra = 50.0;

  // Small Dialogs (Confirmations, simple forms)
  static const double dialogMinWidthSmallLTR = 400.0;
  static const double dialogMaxWidthSmallLTR = 500.0;
  static const double dialogMinWidthSmallRTL = 450.0;
  static const double dialogMaxWidthSmallRTL = 550.0;

  // Medium Dialogs (Forms with multiple fields)
  static const double dialogMinWidthMediumLTR = 450.0;
  static const double dialogMaxWidthMediumLTR = 550.0;
  static const double dialogMinWidthMediumRTL = 500.0;
  static const double dialogMaxWidthMediumRTL = 600.0;

  // Large Dialogs (Complex forms, checkout)
  static const double dialogMinWidthLargeLTR = 500.0;
  static const double dialogMaxWidthLargeLTR = 650.0;
  static const double dialogMinWidthLargeRTL = 550.0;
  static const double dialogMaxWidthLargeRTL = 700.0;

  // Breakpoints
  static const double breakpointLarge = 1400.0;
  static const double breakpointMedium = 1150.0;
  static const double breakpointSmall = 950.0;

  // Elevation
  static const double elevationLow = 1.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
}
