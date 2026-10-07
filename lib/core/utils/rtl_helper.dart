import 'package:flutter/material.dart';
import '../res/app_tokens.dart';

/// Utility class for handling RTL (Right-to-Left) text direction
/// and localized name selection.
///
/// Use this throughout the app to ensure proper bilingual support.
class RTLHelper {
  RTLHelper._(); // Private constructor - utility class

  /// Check if current text direction is RTL
  static bool isRTL(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  /// Get the appropriate name based on current text direction
  ///
  /// Returns Urdu name in RTL mode (if available), otherwise English name.
  ///
  /// Example usage:
  /// ```dart
  /// final displayName = RTLHelper.getLocalizedName(
  ///   context: context,
  ///   nameEnglish: customer.nameEnglish,
  ///   nameUrdu: customer.nameUrdu,
  /// );
  /// ```
  static String getLocalizedName({
    required BuildContext context,
    required String nameEnglish,
    String? nameUrdu,
  }) {
    if (isRTL(context) && nameUrdu != null && nameUrdu.trim().isNotEmpty) {
      return nameUrdu;
    }
    return nameEnglish;
  }

  /// Get Alignment with RTL support
  ///
  /// Example: RTLHelper.alignment(context, Alignment.centerLeft)
  /// Returns Alignment.centerRight in RTL mode
  static Alignment alignment(BuildContext context, Alignment ltrAlignment) {
    if (!isRTL(context)) return ltrAlignment;

    // Swap left/right alignments in RTL
    if (ltrAlignment == Alignment.centerLeft) {
      return Alignment.centerRight;
    } else if (ltrAlignment == Alignment.centerRight) {
      return Alignment.centerLeft;
    } else if (ltrAlignment == Alignment.topLeft) {
      return Alignment.topRight;
    } else if (ltrAlignment == Alignment.topRight) {
      return Alignment.topLeft;
    } else if (ltrAlignment == Alignment.bottomLeft) {
      return Alignment.bottomRight;
    } else if (ltrAlignment == Alignment.bottomRight) {
      return Alignment.bottomLeft;
    }

    return ltrAlignment; // center, top, bottom remain the same
  }

  /// Get TextAlign with RTL support
  ///
  /// Example: RTLHelper.textAlign(context, TextAlign.left)
  /// Returns TextAlign.right in RTL mode
  static TextAlign textAlign(BuildContext context, TextAlign ltrAlign) {
    if (!isRTL(context)) return ltrAlign;

    // Swap left/right in RTL
    if (ltrAlign == TextAlign.left) {
      return TextAlign.right;
    } else if (ltrAlign == TextAlign.right) {
      return TextAlign.left;
    }

    return ltrAlign; // center, justify, start, end remain the same
  }

  /// Get MainAxisAlignment with RTL support
  static MainAxisAlignment mainAxisAlignment(
    BuildContext context,
    MainAxisAlignment ltrAlignment,
  ) {
    if (!isRTL(context)) return ltrAlignment;

    if (ltrAlignment == MainAxisAlignment.start) {
      return MainAxisAlignment.end;
    } else if (ltrAlignment == MainAxisAlignment.end) {
      return MainAxisAlignment.start;
    }

    return ltrAlignment;
  }

  /// Get CrossAxisAlignment with RTL support
  static CrossAxisAlignment crossAxisAlignment(
    BuildContext context,
    CrossAxisAlignment ltrAlignment,
  ) {
    if (!isRTL(context)) return ltrAlignment;

    if (ltrAlignment == CrossAxisAlignment.start) {
      return CrossAxisAlignment.end;
    } else if (ltrAlignment == CrossAxisAlignment.end) {
      return CrossAxisAlignment.start;
    }

    return ltrAlignment;
  }

  /// Get dialog constraints based on size and text direction
  static BoxConstraints getDialogConstraints({
    required BuildContext context,
    required DialogSize size,
  }) {
    // Reverted to fixed widths as requested, keeping it as of english layout for both RTL/LTR
    switch (size) {
      case DialogSize.small:
        return const BoxConstraints(
          minWidth: AppTokens.dialogMinWidthSmallLTR,
          maxWidth: AppTokens.dialogMaxWidthSmallLTR,
        );
      case DialogSize.medium:
        return const BoxConstraints(
          minWidth: AppTokens.dialogMinWidthMediumLTR,
          maxWidth: AppTokens.dialogMaxWidthMediumLTR,
        );
      case DialogSize.large:
        return const BoxConstraints(
          minWidth: AppTokens.dialogMinWidthLargeLTR,
          maxWidth: AppTokens.dialogMaxWidthLargeLTR,
        );
    }
  }
}

/// Dialog size enum for type-safe dialog constraint selection
enum DialogSize {
  small, // Confirmations, simple forms (400-550px)
  medium, // Forms with multiple fields (450-600px)
  large, // Complex forms, checkout (500-700px)
}

/// Extension on BuildContext for easier RTL checks
extension RTLExtension on BuildContext {
  /// Quick check if current context is RTL
  bool get isRTL => Directionality.of(this) == TextDirection.rtl;
}
