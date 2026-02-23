import 'package:flutter/material.dart';

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

  /// Get EdgeInsets with RTL-aware horizontal values
  /// 
  /// In RTL mode, left and right are swapped automatically by Flutter,
  /// but you can use this for explicit RTL-aware padding.
  static EdgeInsets edgeInsets({
    required BuildContext context,
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    }

    final isRtl = isRTL(context);
    
    return EdgeInsets.only(
      left: isRtl ? (right ?? horizontal ?? 0) : (left ?? horizontal ?? 0),
      top: top ?? vertical ?? 0,
      right: isRtl ? (left ?? horizontal ?? 0) : (right ?? horizontal ?? 0),
      bottom: bottom ?? vertical ?? 0,
    );
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

  /// Get icon rotation for RTL
  /// Returns 180 degrees for directional icons in RTL mode
  static double iconRotation(BuildContext context, {bool isDirectional = true}) {
    if (!isDirectional) return 0;
    return isRTL(context) ? 3.14159 : 0; // 180 degrees in radians
  }
}

/// Extension on BuildContext for easier RTL checks
extension RTLExtension on BuildContext {
  /// Quick check if current context is RTL
  bool get isRTL => Directionality.of(this) == TextDirection.rtl;
  
  /// Quick check if current context is LTR
  bool get isLTR => Directionality.of(this) == TextDirection.ltr;
}
