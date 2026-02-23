import 'package:flutter/material.dart';

/// Desktop-specific dimensions and constants for the POS application.
/// 
/// RTL-AWARE DIMENSIONS - Now includes separate values for:
/// - LTR (Left-to-Right) layouts - English
/// - RTL (Right-to-Left) layouts - Urdu
class DesktopDimensions {
  DesktopDimensions._(); // Private constructor

  // --- Spacing ---
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingStandard = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // --- Border Radius ---
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double dialogBorderRadius = 12.0;
  static const double cardBorderRadius = 8.0;

  // --- Dialog Dimensions ---
  // UPDATED: Wider dialogs for Urdu text
  
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

  static const double dialogPadding = 24.0;

  // --- Panel Widths (Responsive breakpoints) ---
  // Right panel in sales screen, etc.
  static const double panelWidth1366 = 450.0;
  static const double panelWidth1920 = 550.0;
  static const double panelWidth2560 = 600.0;

  // --- Icon Sizes ---
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // --- Button Heights ---
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // --- Input Field Heights ---
  static const double inputHeightSmall = 40.0;
  static const double inputHeightMedium = 48.0;
  static const double inputHeightLarge = 56.0;

  // --- Elevation ---
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // --- AppBar ---
  static const double appBarHeight = 64.0;
  static const double toolbarHeight = 56.0;

  // --- Sidebar ---
  static const double sidebarWidth = 240.0;
  static const double sidebarCollapsedWidth = 64.0;

  // --- List Item Heights ---
  static const double listItemHeight = 56.0;
  static const double listItemHeightCompact = 48.0;

  // --- Card Dimensions ---
  static const double cardElevation = 0.0; // Flat cards for modern look
  static const double cardPadding = 16.0;

  // --- Data Table ---
  static const double dataRowHeight = 48.0;
  static const double dataRowHeightCompact = 40.0;

  // --- Helper Methods ---

  /// Get dialog constraints based on size and text direction
  /// 
  /// Example:
  /// ```dart
  /// constraints: DesktopDimensions.getDialogConstraints(
  ///   context: context,
  ///   size: DialogSize.medium,
  /// )
  /// ```
  static BoxConstraints getDialogConstraints({
    required BuildContext context,
    required DialogSize size,
  }) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    switch (size) {
      case DialogSize.small:
        return BoxConstraints(
          minWidth: isRTL ? dialogMinWidthSmallRTL : dialogMinWidthSmallLTR,
          maxWidth: isRTL ? dialogMaxWidthSmallRTL : dialogMaxWidthSmallLTR,
        );
      case DialogSize.medium:
        return BoxConstraints(
          minWidth: isRTL ? dialogMinWidthMediumRTL : dialogMinWidthMediumLTR,
          maxWidth: isRTL ? dialogMaxWidthMediumRTL : dialogMaxWidthMediumLTR,
        );
      case DialogSize.large:
        return BoxConstraints(
          minWidth: isRTL ? dialogMinWidthLargeRTL : dialogMinWidthLargeLTR,
          maxWidth: isRTL ? dialogMaxWidthLargeRTL : dialogMaxWidthLargeLTR,
        );
    }
  }

  /// Get responsive panel width based on screen size
  static double getResponsivePanelWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 2560) {
      return panelWidth2560;
    } else if (screenWidth >= 1920) {
      return panelWidth1920;
    } else {
      return panelWidth1366;
    }
  }

  /// Get EdgeInsets with RTL-aware horizontal padding
  /// 
  /// In RTL mode, adds extra padding for Urdu text breathing room
  static EdgeInsets getContentPadding({
    required BuildContext context,
    bool isInput = false,
  }) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    if (isInput) {
      return EdgeInsets.symmetric(
        horizontal: isRTL ? 16.0 : 12.0, // More padding for Urdu
        vertical: isRTL ? 16.0 : 14.0,
      );
    }

    return EdgeInsets.symmetric(
      horizontal: isRTL ? 20.0 : 16.0,
      vertical: isRTL ? 12.0 : 8.0,
    );
  }
}

/// Dialog size enum for type-safe dialog constraint selection
enum DialogSize {
  small,  // Confirmations, simple forms (400-550px)
  medium, // Forms with multiple fields (450-600px)
  large,  // Complex forms, checkout (500-700px)
}
