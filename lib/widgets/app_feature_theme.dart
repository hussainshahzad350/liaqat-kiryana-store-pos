import 'package:flutter/material.dart';
import '../core/theme/app_ui_theme.dart';

/// Applies the shared presentation foundation at a feature boundary.
/// The builder receives the themed context so pushed dialogs inherit it.
class AppFeatureTheme extends StatelessWidget {
  const AppFeatureTheme({super.key, required this.builder});
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context) => Theme(
      data: AppUiTheme.fromTheme(Theme.of(context),
          isRTL: Directionality.of(context) == TextDirection.rtl),
      child: Builder(builder: builder));
}
