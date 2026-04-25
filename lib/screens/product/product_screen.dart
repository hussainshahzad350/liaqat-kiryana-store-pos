import 'package:flutter/material.dart';
import '../../core/res/app_tokens.dart';
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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 3,
      initialIndex: initialTabIndex,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.product,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            TabBar(
              tabs: [
                Tab(text: localizations.items),
                Tab(text: localizations.categories),
                Tab(text: localizations.units),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            const Expanded(
              child: TabBarView(
                children: [
                  ItemsManagementView(),
                  CategoriesManagementView(),
                  UnitsManagementView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
