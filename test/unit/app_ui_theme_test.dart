import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liaqat_store/core/res/app_layout.dart';
import 'package:liaqat_store/core/theme/app_ui_theme.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
}

void main() {
  for (final color in ['green', 'blue', 'orange']) {
    for (final brightness in Brightness.values) {
      for (final rtl in [false, true]) {
        test(
            '$color $brightness rtl=$rtl has readable roles and visible states',
            () {
          final theme = AppUiTheme.build(color, brightness, isRTL: rtl);
          final colors = theme.colorScheme;
          for (final pair in [
            (colors.primary, colors.onPrimary),
            (colors.surface, colors.onSurface),
            (colors.errorContainer, colors.onErrorContainer),
            (colors.primaryContainer, colors.onPrimaryContainer),
            (colors.surface, colors.error),
            (colors.surface, colors.secondary),
            (colors.surface, colors.tertiary),
            (colors.surface, colors.onSurfaceVariant),
            (colors.inverseSurface, colors.onInverseSurface),
          ]) {
            expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
          }
          expect(theme.textTheme.bodyMedium!.fontFamily,
              rtl ? 'NooriNastaleeq' : 'Roboto');
          expect(theme.textTheme.bodyMedium!.height, 1.2);
          final input = theme.inputDecorationTheme;
          expect(input.focusedBorder!.borderSide.width,
              greaterThan(input.enabledBorder!.borderSide.width));
          expect(input.focusedErrorBorder!.borderSide.color, colors.error);
          final button = theme.filledButtonTheme.style!;
          expect(button.overlayColor!.resolve({WidgetState.hovered})!.a,
              greaterThan(0));
          expect(button.overlayColor!.resolve({WidgetState.disabled})!.a, 0);
          expect(button.side!.resolve({WidgetState.focused})!.color,
              isNot(button.side!.resolve({})!.color));
          expect(button.minimumSize!.resolve({})!.height,
              greaterThanOrEqualTo(48));
          expect(button.foregroundColor!.resolve({WidgetState.disabled}),
              isNot(button.foregroundColor!.resolve({})!));
          expect(theme.dataTableTheme.dataRowMaxHeight, double.infinity);
        });
      }
    }
  }
  test('desktop minimum and settings grid boundaries are explicit', () {
    expect(AppLayout.minimumDesktopWidth, 1024);
    expect(AppLayout.minimumDesktopHeight, 720);
    expect(AppLayout.settingsColumnCount(899), 2);
    expect(AppLayout.settingsColumnCount(900), 3);
  });
}
