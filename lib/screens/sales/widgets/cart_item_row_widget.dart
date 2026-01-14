import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/entities/money.dart';
import '../../../models/cart_item_model.dart';

class CartItemRow extends StatefulWidget {
  final CartItem item;
  final int index;
  final bool isRTL;
  final ColorScheme colorScheme;
  final Function(int) onRemove;
  final Function(int, double, Money) onUpdate;

  const CartItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.isRTL,
    required this.colorScheme,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  State<CartItemRow> createState() => _CartItemRowState();
}

class _CartItemRowState extends State<CartItemRow> {
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _priceCtrl =
        TextEditingController(text: widget.item.unitPrice.toRupeesString());
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void didUpdateWidget(CartItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.quantity != oldWidget.item.quantity) {
      final currentVal = double.tryParse(_qtyCtrl.text);
      if (currentVal != widget.item.quantity) {
        _qtyCtrl.text = widget.item.quantity.toString();
      }
    }
    if (widget.item.unitPrice != oldWidget.item.unitPrice) {
      final currentVal = Money.fromRupeesString(_priceCtrl.text);
      if (currentVal != widget.item.unitPrice) {
        _priceCtrl.text = widget.item.unitPrice.toRupeesString();
      }
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final double qty = double.tryParse(_qtyCtrl.text) ?? 1.0;
      final Money price = Money.fromRupeesString(_priceCtrl.text);
      widget.onUpdate(widget.index, qty, price);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showUrdu =
        widget.isRTL && widget.item.nameUrdu.trim().isNotEmpty;
    return ListTile(
      title: Text(showUrdu ? widget.item.nameUrdu : widget.item.nameEnglish),
      subtitle: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.item.total.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildTextField(_priceCtrl),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _buildTextField(_qtyCtrl),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.close, color: widget.colorScheme.error, size: 20),
        onPressed: () => widget.onRemove(widget.index),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return SizedBox(
      height: 36, // Adjust height to make it compact
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: (_) => _onChanged(),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
