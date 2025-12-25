import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  // Dummy data for units
  List<Map<String, dynamic>> units = [
    {'id': 1, 'name': 'Kilogram', 'code': 'KG'},
    {'id': 2, 'name': 'Gram', 'code': 'G'},
    {'id': 3, 'name': 'Liter', 'code': 'L'},
    {'id': 4, 'name': 'Milliliter', 'code': 'ML'},
    {'id': 5, 'name': 'Dozen', 'code': 'DZN'},
    {'id': 6, 'name': 'Piece', 'code': 'PCS'},
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(loc.units, style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUnitDialog,
            tooltip: loc.addItem,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: units.length,
        itemBuilder: (context, index) {
          final unit = units[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: colorScheme.surface,
            elevation: 2,
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(Icons.square_foot, color: colorScheme.onPrimaryContainer),
                ),
              ),
              title: Text(
                unit['name'],
                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              subtitle: Text(unit['code'], style: TextStyle(color: colorScheme.onSurfaceVariant)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 20, color: colorScheme.secondary),
                    onPressed: () => _showEditUnitDialog(unit),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
                    onPressed: () => _deleteUnit(unit['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUnitDialog,
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  void _showAddUnitDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => UnitDialog(
        onSave: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.saveChangesSuccess)),
          );
        },
      ),
    );
  }

  void _showEditUnitDialog(Map<String, dynamic> unit) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => UnitDialog(
        unit: unit,
        onSave: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.saveChangesSuccess)),
          );
        },
      ),
    );
  }

  void _deleteUnit(int id) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(loc.confirm, style: TextStyle(color: colorScheme.onSurface)),
        content: Text(loc.confirmDeleteItem, style: TextStyle(color: colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.no, style: TextStyle(color: colorScheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                units.removeWhere((u) => u['id'] == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.itemDeleted), backgroundColor: colorScheme.primary),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
            child: Text(loc.yesDelete),
          ),
        ],
      ),
    );
  }
}

class UnitDialog extends StatelessWidget {
  final Map<String, dynamic>? unit;
  final VoidCallback onSave;

  const UnitDialog({super.key, this.unit, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = unit != null;
    final nameCtrl = TextEditingController(text: unit?['name']);
    final codeCtrl = TextEditingController(text: unit?['code']);

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(isEdit ? loc.editItem : loc.addItem, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(labelText: loc.name, filled: true, fillColor: colorScheme.surfaceVariant, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: codeCtrl,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(labelText: 'Code (e.g. KG)', filled: true, fillColor: colorScheme.surfaceVariant, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancel, style: TextStyle(color: colorScheme.onSurface)),
        ),
        ElevatedButton(
          onPressed: () {
            onSave();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
          child: Text(loc.save),
        ),
      ],
    );
  }
}