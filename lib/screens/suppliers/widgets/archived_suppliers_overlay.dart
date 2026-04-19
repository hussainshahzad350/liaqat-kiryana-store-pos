import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/supplier_model.dart';
import '../../../../core/res/app_tokens.dart';

class ArchivedSuppliersOverlay extends StatelessWidget {
  final List<Supplier> suppliers;
  final VoidCallback onClose;
  final void Function(Supplier) onUnarchive;
  final void Function(Supplier) onDelete;
  final void Function(Supplier) onLedger;

  const ArchivedSuppliersOverlay({
    super.key,
    required this.suppliers,
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
                    Text(
                        "Archived Suppliers", // loc.archivedSuppliers might not exist, using hardcoded english fallback safely
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
                  child: suppliers.isEmpty
                      ? Center(
                          child: Text(loc.noSuppliersFound,
                              style: textTheme.bodyMedium))
                      : ListView.builder(
                          itemCount: suppliers.length,
                          itemBuilder: (_, i) {
                            // Can't import SupplierListTile due to circular dependency issues potentially if not careful,
                            // but we can just use the same card mapping or manually render.
                            final s = suppliers[i];
                            final name = s.nameUrdu?.isNotEmpty == true
                                ? s.nameUrdu!
                                : s.nameEnglish;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                  leading: const Icon(Icons.business),
                                  title: Text(name),
                                  subtitle: Text(s.contactPrimary ?? ''),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.receipt_long,
                                            color: colorScheme.primary),
                                        tooltip: loc.viewLedgerTooltip,
                                        onPressed: () => onLedger(s),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.unarchive,
                                            color: colorScheme.primary),
                                        onPressed: () => onUnarchive(s),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: colorScheme.error),
                                        onPressed: () => onDelete(s),
                                      ),
                                    ],
                                  )),
                            );
                          },
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
