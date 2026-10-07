import '../../widgets/app_feature_theme.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_management_tabs.dart';
import '../../l10n/app_localizations.dart';
import 'views/customers_management_view.dart';
import 'views/suppliers_management_view.dart';

class AccountsScreen extends StatelessWidget {
  final int initialTabIndex;

  const AccountsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context) => AppFeatureTheme(builder: _buildFeature);

  Widget _buildFeature(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AppManagementTabs(
        title: loc.accounts,
        labels: [loc.customers, loc.suppliers],
        initialIndex: initialTabIndex,
        views: const [CustomersManagementView(), SuppliersManagementView()]);
  }
}
