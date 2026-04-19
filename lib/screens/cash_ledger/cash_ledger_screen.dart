import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/res/app_tokens.dart';
import '../../core/repositories/cash_repository.dart';
import 'controller/cash_ledger_controller.dart';
import 'widgets/cash_ledger_kpi_section.dart';
import 'widgets/cash_ledger_search_bar.dart';
import 'widgets/cash_ledger_list.dart';
import 'dialogs/add_transaction_dialog.dart';

class CashLedgerScreen extends StatelessWidget {
  const CashLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CashLedgerController(CashRepository())..init(),
      child: const _CashLedgerScreenInternal(),
    );
  }
}

class _CashLedgerScreenInternal extends StatelessWidget {
  const _CashLedgerScreenInternal();

  void _showAddTransactionDialog(BuildContext context, String type) {
    final controller = context.read<CashLedgerController>();
    showDialog(
      context: context,
      builder: (_) => AddTransactionDialog(
        initialType: type,
        repository: CashRepository(),
        onSaved: () => controller.refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacingLarge),
      child: Column(
        children: [
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLarge, vertical: AppTokens.spacingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddTransactionDialog(context, 'IN'),
                  icon: const Icon(Icons.add),
                  label: Text(loc.cashIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    minimumSize: const Size(0, AppTokens.buttonHeight),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingMedium),
                ElevatedButton.icon(
                  onPressed: () => _showAddTransactionDialog(context, 'OUT'),
                  icon: const Icon(Icons.remove),
                  label: Text(loc.cashOut),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                    minimumSize: const Size(0, AppTokens.buttonHeight),
                  ),
                ),
              ],
            ),
          ),

          // KPI Cards
          const CashLedgerKpiSection(),
          
          // Search & Filter Bar
          const CashLedgerSearchBar(),
          
          // List
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTokens.spacingLarge),
              child: CashLedgerList(),
            ),
          ),
        ],
      ),
    );
  }
}
