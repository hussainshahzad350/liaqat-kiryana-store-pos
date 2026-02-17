import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/constants/desktop_dimensions.dart';
import '../../../models/cart_item_model.dart';
import '../../../domain/entities/money.dart';

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
      if (double.tryParse(_qtyCtrl.text) != widget.item.quantity) {
        _qtyCtrl.text = widget.item.quantity.toString();
      }
    }
    if (widget.item.unitPrice != oldWidget.item.unitPrice) {
      Money currentPrice;
      try {
        currentPrice = Money.fromRupeesString(_priceCtrl.text);
      } catch (_) {
        currentPrice = Money.zero;
      }
      if (currentPrice != widget.item.unitPrice) {
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
      Money price;
      try {
        price = Money.fromRupeesString(_priceCtrl.text);
      } catch (_) {
        price = Money.zero;
      }
      widget.onUpdate(widget.index, qty, price);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesktopDimensions.spacingStandard,
          vertical: DesktopDimensions.spacingSmall),
      color: widget.index % 2 == 0
          ? widget.colorScheme.surface
          : widget.colorScheme.surfaceVariant.withOpacity(0.2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isRTL && widget.item.nameUrdu.isNotEmpty
                      ? widget.item.nameUrdu
                      : widget.item.nameEnglish,
                  style: textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.item.itemCode != null)
                  Text(widget.item.itemCode!,
                      style: textTheme.labelSmall?.copyWith(
                          color: widget.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: DesktopDimensions.formFieldHeight,
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    vertical: DesktopDimensions.spacingSmall,
                    horizontal: DesktopDimensions.spacingXSmall),
                border: InputBorder.none,
                hintText: '0',
              ),
              style: textTheme.bodyMedium,
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: DesktopDimensions.spacingSmall),
          SizedBox(
            width: 70,
            height: DesktopDimensions.formFieldHeight,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: DesktopDimensions.spacingSmall,
                    horizontal: DesktopDimensions.spacingXSmall),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        DesktopDimensions.formFieldBorderRadius)),
              ),
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: DesktopDimensions.spacingSmall),
          SizedBox(
            width: 80,
            child: Text(
              widget.item.total.toString().replaceAll('Rs ', ''),
              textAlign: TextAlign.end,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: DesktopDimensions.iconSizeXLarge,
            child: IconButton(
              icon: Icon(Icons.close,
                  color: widget.colorScheme.error,
                  size: DesktopDimensions.iconSizeMedium),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => widget.onRemove(widget.index),
            ),
          ),
        ],
      ),
    );
  }
}
