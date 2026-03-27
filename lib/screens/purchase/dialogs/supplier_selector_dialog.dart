import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class SupplierSelectorDialog extends StatefulWidget {
  final List<Map<String, dynamic>> suppliers;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const SupplierSelectorDialog({
    super.key,
    required this.suppliers,
    required this.onSelected,
  });

  @override
  State<SupplierSelectorDialog> createState() => _SupplierSelectorDialogState();
}

class _SupplierSelectorDialogState extends State<SupplierSelectorDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final filtered = widget.suppliers.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final name = (s['name_english'] as String?)?.toLowerCase() ?? '';
      final contact = (s['contact_primary'] as String?)?.toLowerCase() ?? '';
      return name.contains(q) || contact.contains(q);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 400, maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.selectSupplier,
                  style: textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  tooltip: loc.cancel,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            const Divider(),
            const SizedBox(height: 16.0),
            
            // Search TextField
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: loc.search,
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() {
                  _query = val;
                });
              },
            ),
            const SizedBox(height: 16.0),
            
            // Scrollable Content
            Flexible(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(loc.noItemsFound),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final supplier = filtered[index];
                        final name = supplier['name_english'] as String? ?? '';
                        final contact = supplier['contact_primary'] as String? ?? '';
                        return ListTile(
                          title: Text(name),
                          subtitle: contact.isNotEmpty ? Text(contact) : null,
                          onTap: () {
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            widget.onSelected(supplier);
                          },
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 8.0),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: Text(loc.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
