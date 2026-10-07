import 'package:flutter/material.dart';

import '../res/app_tokens.dart';
import 'app_themes.dart';

/// Opt-in presentation foundation for new slices and the component gallery.
/// Existing feature themes migrate explicitly rather than changing globally.
class AppUiTheme {
  const AppUiTheme._();

  static ThemeData build(String color, Brightness brightness,
      {bool isRTL = false}) {
    final base = AppThemes.getTheme(color, brightness, isRTL: isRTL);
    return fromTheme(base, isRTL: isRTL);
  }

  /// Adopt the foundation while retaining the active palette, font and mode.
  static ThemeData fromTheme(ThemeData base, {bool isRTL = false}) {
    // Material pairs choose readable foregrounds in both brightness modes.
    final dark = base.brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
            seedColor: base.colorScheme.primary, brightness: base.brightness)
        .copyWith(
      surface: dark ? const Color(0xFF202426) : const Color(0xFFFFFFFF),
      surfaceContainerLowest:
          dark ? const Color(0xFF171B1D) : const Color(0xFFF5F6F7),
      surfaceContainerLow:
          dark ? const Color(0xFF202426) : const Color(0xFFFFFFFF),
      surfaceContainer:
          dark ? const Color(0xFF282D30) : const Color(0xFFF1F3F4),
      surfaceContainerHigh:
          dark ? const Color(0xFF303639) : const Color(0xFFF5F6F7),
      surfaceContainerHighest:
          dark ? const Color(0xFF373E42) : const Color(0xFFEBEEF0),
    );
    TextStyle? compact(TextStyle? style) => style?.copyWith(
        height: AppTokens.compactLineHeight,
        letterSpacing: isRTL ? 0 : style.letterSpacing);
    final text = base.textTheme.copyWith(
      headlineLarge: compact(base.textTheme.headlineLarge),
      headlineMedium: compact(base.textTheme.headlineMedium),
      headlineSmall: compact(base.textTheme.headlineSmall),
      titleLarge: compact(base.textTheme.titleLarge),
      titleMedium: compact(base.textTheme.titleMedium),
      titleSmall: compact(base.textTheme.titleSmall),
      bodyLarge: compact(base.textTheme.bodyLarge),
      bodyMedium: compact(base.textTheme.bodyMedium),
      bodySmall: compact(base.textTheme.bodySmall),
      labelLarge: compact(base.textTheme.labelLarge),
      labelMedium: compact(base.textTheme.labelMedium),
      labelSmall: compact(base.textTheme.labelSmall),
    );
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.controlRadius));
    final common = ButtonStyle(
      minimumSize:
          const WidgetStatePropertyAll(Size(0, AppTokens.controlMinHeight)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(
          horizontal: AppTokens.surfacePadding,
          vertical: AppTokens.relatedGap)),
      shape: WidgetStatePropertyAll(shape),
      textStyle: WidgetStatePropertyAll(text.labelLarge),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStateProperty.resolveWith((states) => BorderSide(
          color: states.contains(WidgetState.focused) &&
                  !states.contains(WidgetState.disabled)
              ? colors.primary
              : Colors.transparent,
          width: AppTokens.focusBorderWidth)),
    );
    WidgetStateProperty<Color?> overlay(Color foreground) =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.transparent;
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused)) {
            return foreground.withValues(alpha: AppTokens.activeOpacity);
          }
          if (states.contains(WidgetState.hovered)) {
            return foreground.withValues(alpha: AppTokens.hoverOpacity);
          }
          return Colors.transparent;
        });
    final filled = common.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? colors.onSurface.withValues(alpha: AppTokens.disabledOpacity)
              : colors.onPrimary),
      backgroundColor: WidgetStateProperty.resolveWith((states) => states
              .contains(WidgetState.disabled)
          ? colors.onSurface.withValues(alpha: AppTokens.disabledFillOpacity)
          : colors.primary),
      // A high-contrast outline remains visible outside the filled surface.
      side: WidgetStateProperty.resolveWith((states) => BorderSide(
          color: states.contains(WidgetState.focused) &&
                  !states.contains(WidgetState.disabled)
              ? colors.onSurface
              : Colors.transparent,
          width: AppTokens.focusBorderWidth)),
      overlayColor: overlay(colors.onPrimary),
    );
    final secondary = common.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.disabled)
              ? colors.onSurface.withValues(alpha: AppTokens.disabledOpacity)
              : colors.primary),
      overlayColor: overlay(colors.primary),
      side: WidgetStateProperty.resolveWith((states) => BorderSide(
          color: states.contains(WidgetState.focused)
              ? colors.primary
              : colors.outline,
          width: states.contains(WidgetState.focused)
              ? AppTokens.focusBorderWidth
              : AppTokens.borderWidth)),
    );
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.controlRadius),
        borderSide: BorderSide(color: color, width: width));
    return base.copyWith(
      colorScheme: colors,
      textTheme: text,
      scaffoldBackgroundColor: colors.surfaceContainerLowest,
      visualDensity: VisualDensity.standard,
      filledButtonTheme: FilledButtonThemeData(style: filled),
      elevatedButtonTheme: ElevatedButtonThemeData(style: filled),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondary),
      textButtonTheme: TextButtonThemeData(
          style: common.copyWith(
              foregroundColor: secondary.foregroundColor,
              overlayColor: overlay(colors.primary))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppTokens.surfacePadding,
            vertical: AppTokens.contentGap),
        border: border(colors.outline, AppTokens.borderWidth),
        enabledBorder: border(colors.outline, AppTokens.borderWidth),
        disabledBorder: border(colors.outlineVariant, AppTokens.borderWidth),
        focusedBorder: border(colors.primary, AppTokens.focusBorderWidth),
        errorBorder: border(colors.error, AppTokens.borderWidth),
        focusedErrorBorder: border(colors.error, AppTokens.focusBorderWidth),
        labelStyle: text.bodyMedium,
        hintStyle: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: colors.error),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.surfaceRadius)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerHigh,
        elevation: AppTokens.modalElevation,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.modalRadius)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.inverseSurface,
          contentTextStyle:
              text.bodyMedium?.copyWith(color: colors.onInverseSurface)),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: text.labelLarge,
        dataTextStyle: text.bodyMedium,
        headingRowColor: WidgetStatePropertyAll(colors.surfaceContainerHighest),
        dataRowColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? colors.primaryContainer
                : null),
        dataRowMinHeight: AppTokens.controlMinHeight,
        dataRowMaxHeight: double.infinity,
        horizontalMargin: AppTokens.surfacePadding,
        columnSpacing: AppTokens.sectionGap,
      ),
    );
  }
}
