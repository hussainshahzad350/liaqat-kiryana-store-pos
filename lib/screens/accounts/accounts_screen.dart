import 'package:flutter/material.dart';
import '../../core/res/app_tokens.dart';
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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.accounts,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            TabBar(
              tabs: [
                Tab(text: localizations.customers),
                Tab(text: localizations.suppliers),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            const Expanded(
              child: TabBarView(
                children: [
                  CustomersManagementView(),
                  SuppliersManagementView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
