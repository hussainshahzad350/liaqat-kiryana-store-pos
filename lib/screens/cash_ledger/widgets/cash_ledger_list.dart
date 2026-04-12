import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/res/app_tokens.dart';
import '../controller/cash_ledger_controller.dart';
import 'cash_ledger_list_tile.dart';

class CashLedgerList extends StatefulWidget {
  const CashLedgerList({super.key});

  @override
  State<CashLedgerList> createState() => _CashLedgerListState();
}

class _CashLedgerListState extends State<CashLedgerList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter < AppTokens.spacingXXXLarge) {
      context.read<CashLedgerController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CashLedgerController>(
      builder: (context, controller, child) {
        if (controller.state == CashLedgerState.loading && controller.allEntries.isEmpty) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (controller.state == CashLedgerState.error) {
          return Center(
            child: Text(
              controller.errorMessage ?? "An error occurred",
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          );
        }

        if (controller.allEntries.isEmpty) {
          return Center(
            child: Text(
              loc.noData,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return Card(
          elevation: AppTokens.cardElevation,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: controller.allEntries.length + (controller.isLoadMoreRunning ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == controller.allEntries.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spacingMedium),
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    ),
                  );
                }
                return CashLedgerListTile(entry: controller.allEntries[index]);
              },
            ),
          ),
        );
      },
    );
  }
}
