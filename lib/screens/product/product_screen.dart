import '../../widgets/app_feature_theme.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_management_tabs.dart';
import '../../l10n/app_localizations.dart';
import 'views/categories_management_view.dart';
import 'views/items_management_view.dart';
import 'views/units_management_view.dart';

class ProductScreen extends StatelessWidget {
  final int initialTabIndex;

  const ProductScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) => AppFeatureTheme(builder: _buildFeature);

  Widget _buildFeature(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppManagementTabs(
        title: loc.product,
        labels: [loc.items, loc.categories, loc.units],
        initialIndex: initialTabIndex.clamp(0, 2),
        views: const [
          ItemsManagementView(),
          CategoriesManagementView(),
          UnitsManagementView()
        ]);
  }
}
