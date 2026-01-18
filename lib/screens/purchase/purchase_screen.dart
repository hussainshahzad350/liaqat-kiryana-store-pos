import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:liaqat_store/core/constants/desktop_dimensions.dart';
import '../../core/repositories/purchase_repository.dart';
import '../../core/repositories/suppliers_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../domain/entities/money.dart';
import '../../core/routes/app_routes.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final PurchaseRepository _purchaseRepo = PurchaseRepository();
  final SuppliersRepository _suppliersRepo = SuppliersRepository();
  final ItemsRepository _itemsRepo = ItemsRepository();

  // Form State
  Map<String, dynamic>? _selectedSupplier;
  final TextEditingController _invoiceCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  // Cart State
  final List<Map<String, dynamic>> _cartItems = [];

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      _cartItems.fold(0, (sum, item) => sum + (item['total_amount'] as int));

  void _selectSupplier() async {
    // Simple dialog to select supplier
    final suppliers = await _suppliersRepo.getSuppliers();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Supplier'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final s = suppliers[index];
              return ListTile(
                title: Text(s['name_english']),
                subtitle: Text(s['contact_primary'] ?? ''),
                onTap: () {
                  setState(() => _selectedSupplier = s);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Navigate to Add Supplier Screen (Shortcut)
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.suppliers);
            },
            child: const Text('+ New Supplier'),
          ),
        ],
      ),
    );
  }

  void _addItem() async {
    // Simple dialog to select item
    final products = await _itemsRepo
        .getAllProducts(); // Should use a search optimized method in real app
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Item'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Search Item...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: DesktopDimensions.spacingSmall),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      title: Text(product.nameEnglish),
                      subtitle: Text('Stock: ${product.currentStock}'),
                      onTap: () {
                        Navigator.pop(context);
                        _showItemDetailsDialog(product.toMap());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.items);
            },
            child: const Text('+ New Item'),
          ),
        ],
      ),
    );
  }

  void _showItemDetailsDialog(Map<String, dynamic> item) {
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController(
        text: Money(item['avg_cost_price'] ?? 0).toRupeesString());
    final batchCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add: ${item['name_english']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Quantity', border: OutlineInputBorder()),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Buy Price (Unit)',
                    border: OutlineInputBorder(),
                    prefixText: 'Rs '),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              TextField(
                controller: batchCtrl,
                decoration: const InputDecoration(
                    labelText: 'Batch Number (Optional)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: DesktopDimensions.spacingStandard),
              TextField(
                controller: expiryCtrl,
                decoration: const InputDecoration(
                    labelText: 'Expiry Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                    hintText: '2025-12-31'),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    expiryCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyCtrl.text) ?? 0;
              final cost = Money.fromRupeesString(costCtrl.text).paisas;

              if (qty > 0 && cost >= 0) {
                setState(() {
                  _cartItems.add({
                    'product_id': item['id'],
                    'name': item['name_english'],
                    'quantity': qty,
                    'cost_price': cost,
                    'total_amount': (qty * cost).toInt(),
                    'batch_number': batchCtrl.text,
                    'expiry_date': expiryCtrl.text,
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add to Bill'),
          ),
        ],
      ),
    );
  }

  void _savePurchase() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    final purchaseData = {
      'supplier_id': _selectedSupplier!['id'],
      'invoice_number': _invoiceCtrl.text.isEmpty
          ? 'PUR-${DateTime.now().millisecondsSinceEpoch}'
          : _invoiceCtrl.text,
      'purchase_date': DateFormat('yyyy-MM-dd HH:mm').format(_purchaseDate),
      'total_amount': _totalAmount.toInt(),
      'notes': _notesCtrl.text,
      'items': _cartItems,
    };

    try {
      await _purchaseRepo.createPurchase(purchaseData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Saved Successfully')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            SavePurchaseIntent(),
        SingleActivator(LogicalKeyboardKey.keyI, control: true):
            AddItemIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SavePurchaseIntent: CallbackAction<SavePurchaseIntent>(onInvoke: (_) {
            _savePurchase();
            return null;
          }),
          AddItemIntent: CallbackAction<AddItemIntent>(onInvoke: (_) {
            _addItem();
            return null;
          }),
        },
        child: Scaffold(
          body: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectSupplier,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Supplier',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        DesktopDimensions.cardBorderRadius /
                                            2)),
                                prefixIcon: const Icon(Icons.store),
                              ),
                              child: Text(
                                _selectedSupplier?['name_english'] ??
                                    'Select Supplier',
                                style: TextStyle(
                                  color: _selectedSupplier == null
                                      ? Colors.grey
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: DesktopDimensions.spacingMedium),
                        Expanded(
                          child: TextField(
                            controller: _invoiceCtrl,
                            decoration: InputDecoration(
                              labelText: 'Supplier Invoice #',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      DesktopDimensions.cardBorderRadius / 2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesktopDimensions.spacingStandard),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _purchaseDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _purchaseDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Purchase Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(DateFormat('yyyy-MM-dd')
                                  .format(_purchaseDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: DesktopDimensions.spacingMedium),
                        Expanded(
                          child: TextField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: _cartItems.isEmpty
                    ? Center(
                        child: TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_circle_outline, size: 48),
                          label: const Text('Add Items'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
                        itemCount: _cartItems.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return ListTile(
                            title: Text(item['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Qty: ${item['quantity']} | Batch: ${item['batch_number'] ?? '-'} | Exp: ${item['expiry_date'] ?? '-'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(Money(item['total_amount'])
                                    .formattedNoDecimal),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => setState(
                                      () => _cartItems.removeAt(index)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(DesktopDimensions.spacingMedium),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add,
                          size: DesktopDimensions.kpiIconSize),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesktopDimensions.spacingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.cardBorderRadius),
                        ),
                        textStyle: const TextStyle(
                            fontSize: DesktopDimensions.bodySize,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _savePurchase,
                      icon: const Icon(Icons.save,
                          size: DesktopDimensions.kpiIconSize),
                      label: const Text('SAVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesktopDimensions.spacingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              DesktopDimensions.cardBorderRadius),
                        ),
                        textStyle: const TextStyle(
                            fontSize: DesktopDimensions.bodySize,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'Total: ${Money(_totalAmount.toInt()).formattedNoDecimal}',
                      style: TextStyle(
                          fontSize: DesktopDimensions.bodySize + 2,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavePurchaseIntent extends Intent {
  const SavePurchaseIntent();
}

class AddItemIntent extends Intent {
  const AddItemIntent();
}
