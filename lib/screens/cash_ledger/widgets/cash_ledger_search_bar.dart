import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/res/app_tokens.dart';
import '../controller/cash_ledger_controller.dart';

class CashLedgerSearchBar extends StatefulWidget {
  const CashLedgerSearchBar({super.key});

  @override
  State<CashLedgerSearchBar> createState() => _CashLedgerSearchBarState();
}

class _CashLedgerSearchBarState extends State<CashLedgerSearchBar> {
  final _searchCtrl = TextEditingController();
  late final FocusNode _focusNode;

  void _handleSearchTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _searchCtrl.addListener(_handleSearchTextChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_handleSearchTextChanged);
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CashLedgerController>(
      builder: (context, controller, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLarge, vertical: AppTokens.spacingMedium),
          child: Row(
            children: [
              // Search Input
              Expanded(
                child: KeyboardListener(
                  focusNode: _focusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                      _searchCtrl.clear();
                      controller.setSearchQuery('');
                    }
                  },
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: "Search ledger...", // Needs localization fallback
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                controller.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.buttonBorderRadius),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTokens.buttonBorderRadius),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppTokens.spacingMedium,
                        horizontal: AppTokens.spacingLarge,
                      ),
                    ),
                    onChanged: (val) => controller.setSearchQuery(val),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),

              // Filter Dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppTokens.buttonBorderRadius),
                  color: colorScheme.surface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMedium),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.paymentModeFilter,
                    icon: Icon(Icons.filter_list, color: colorScheme.onSurfaceVariant),
                    dropdownColor: colorScheme.surface,
                    items: [
                      DropdownMenuItem(value: 'ALL', child: Text(loc.allModes)),
                      DropdownMenuItem(value: 'CASH', child: Text(loc.physicalCash)),
                      DropdownMenuItem(value: 'DIGITAL', child: Text(loc.digitalBank)),
                    ],
                    onChanged: (val) {
                      if (val != null) controller.setPaymentModeFilter(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: controller.selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(colorScheme: colorScheme),
                        child: child!),
                  );
                  if (picked != null) {
                    controller.updateDate(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTokens.spacingMedium),
                  decoration: BoxDecoration(
                    color: controller.selectedDate != null
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTokens.buttonBorderRadius),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: AppTokens.iconSizeMedium,
                          color: controller.selectedDate != null
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppTokens.spacingStandard),
                      Text(
                        controller.selectedDate != null
                            ? DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(controller.selectedDate!)
                            : 'All Dates',
                        style: textTheme.bodyMedium?.copyWith(
                          color: controller.selectedDate != null
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller.selectedDate != null) ...[
                        const SizedBox(width: AppTokens.spacingSmall),
                        InkWell(
                          onTap: () => controller.updateDate(null),
                          child: Icon(Icons.close, size: 16,
                              color: colorScheme.onPrimaryContainer),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
