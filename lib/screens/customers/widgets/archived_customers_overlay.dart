import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer_model.dart';
import '../../../core/res/app_tokens.dart';
import 'customer_list_tile.dart';

class ArchivedCustomersOverlay extends StatelessWidget {
  final List<Customer> customers;
  final VoidCallback onClose;
  final void Function(Customer) onUnarchive;
  final void Function(Customer) onDelete;
  final void Function(Customer) onLedger;

  const ArchivedCustomersOverlay({
    super.key,
    required this.customers,
    required this.onClose,
    required this.onUnarchive,
    required this.onDelete,
    required this.onLedger,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(color: colorScheme.shadow.withValues(alpha: 0.5)),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(AppTokens.spacingMedium),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
              border: Border.all(color: colorScheme.outline, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.archivedCustomers,
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: onClose,
                    ),
                  ],
                ),
                Divider(color: colorScheme.primary),
                Expanded(
                  child: customers.isEmpty
                      ? Center(
                          child: Text(loc.noCustomersFound,
                              style: textTheme.bodyMedium))
                      : ListView.builder(
                          itemCount: customers.length,
                          itemBuilder: (_, i) => CustomerListTile(
                            customer: customers[i],
                            onLedger: () => onLedger(customers[i]),
                            onEdit: () {},
                            onArchive: () => onUnarchive(customers[i]),
                            onDelete: () => onDelete(customers[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
