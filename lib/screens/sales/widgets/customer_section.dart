import 'package:flutter/material.dart';
import '../../../core/constants/desktop_dimensions.dart';
import '../../../models/customer_model.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/rtl_helper.dart';

class CustomerSection extends StatelessWidget {
  final TextEditingController searchController;
  final List<Customer> filteredCustomers;
  final bool showCustomerList;
  final int? selectedCustomerId;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchTap;
  final Function(Customer?) onSelectCustomer;
  final VoidCallback onAddCustomer;

  const CustomerSection({
    super.key,
    required this.searchController,
    required this.filteredCustomers,
    required this.showCustomerList,
    required this.selectedCustomerId,
    required this.onSearchChanged,
    required this.onSearchTap,
    required this.onSelectCustomer,
    required this.onAddCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: DesktopDimensions.cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: loc.searchCustomerHint,
                      isDense: true,
                      prefixIcon: Icon(Icons.person_search,
                          color: colorScheme.onSurfaceVariant),
                      suffixIcon: selectedCustomerId != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => onSelectCustomer(null))
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.cardBorderRadius / 2)),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant,
                    ),
                    onChanged: onSearchChanged,
                    onTap: onSearchTap,
                  ),
                ),
                const SizedBox(width: DesktopDimensions.spacingSmall),
                SizedBox(
                  height: DesktopDimensions.buttonHeight,
                  width: DesktopDimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: onAddCustomer,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.buttonBorderRadius)),
                    ),
                    child: const Icon(Icons.person_add),
                  ),
                ),
              ],
            ),
            if (showCustomerList)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                margin:
                    const EdgeInsets.only(top: DesktopDimensions.spacingXSmall),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.buttonBorderRadius),
                  boxShadow: [
                    BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: DesktopDimensions.spacingXSmall)
                  ],
                ),
                child: filteredCustomers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(loc.noCustomersFound,
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredCustomers.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = filteredCustomers[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              RTLHelper.getLocalizedName(
                                context: context,
                                nameEnglish: c.nameEnglish,
                                nameUrdu: c.nameUrdu,
                              ),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(c.contactPrimary ?? ''),
                            trailing: Text(
                                '${loc.currBal}: ${Money(c.outstandingBalance).toString()}'),
                            onTap: () => onSelectCustomer(c),
                            hoverColor:
                                colorScheme.primaryContainer.withOpacity(0.1),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
