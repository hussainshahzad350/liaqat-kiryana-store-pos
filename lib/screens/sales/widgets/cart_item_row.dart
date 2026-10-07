import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/res/app_tokens.dart';
import '../../../models/cart_item_model.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';

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
        TextEditingController(text: widget.item.unitPrice.toInputString());
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
        _priceCtrl.text = widget.item.unitPrice.toInputString();
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
      final Money price = Money.tryParse(_priceCtrl.text) ?? Money.zero;
      widget.onUpdate(widget.index, qty, price);
    });
  }

  void _stepQuantity(double step) {
    final current = double.tryParse(_qtyCtrl.text) ?? widget.item.quantity;
    final next = current + step;
    if (next <= 0) return;
    final text = next == next.truncateToDouble()
        ? next.toInt().toString()
        : next.toString();
    _qtyCtrl.value = TextEditingValue(
        text: text, selection: TextSelection.collapsed(offset: text.length));
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingStandard,
          vertical: AppTokens.spacingSmall),
      color: widget.index % 2 == 0
          ? widget.colorScheme.surface
          : widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                    message: widget.isRTL && widget.item.nameUrdu.isNotEmpty
                        ? widget.item.nameUrdu
                        : widget.item.nameEnglish,
                    child: Text(
                      widget.isRTL && widget.item.nameUrdu.isNotEmpty
                          ? widget.item.nameUrdu
                          : widget.item.nameEnglish,
                      style: textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                if (widget.item.itemCode != null)
                  Text(widget.item.itemCode!,
                      style: textTheme.labelSmall?.copyWith(
                          color: widget.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: AppTokens.formFieldHeight,
            child: TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                    vertical: AppTokens.spacingSmall,
                    horizontal: AppTokens.spacingXSmall),
                hintText: '0',
              ),
              style: textTheme.bodyMedium,
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: AppTokens.spacingSmall),
          SizedBox(
            width: 70,
            height: AppTokens.formFieldHeight,
            child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: AppTokens.spacingSmall,
                    horizontal: AppTokens.spacingXSmall),
                suffixIconConstraints: const BoxConstraints.tightFor(width: 24),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _qtyCtrl,
                  builder: (context, value, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final increase in [true, false])
                        IconButton(
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(24, 22),
                            maximumSize: const Size(24, 22),
                          ),
                          key: ValueKey(
                              'quantity-${increase ? 'increase' : 'decrease'}-${widget.item.id}'),
                          tooltip: increase
                              ? AppLocalizations.of(context)!.increaseQuantity
                              : AppLocalizations.of(context)!.decreaseQuantity,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                              width: 24, height: 22),
                          iconSize: 16,
                          onPressed: increase ||
                                  (double.tryParse(value.text) ??
                                          widget.item.quantity) >
                                      1
                              ? () => _stepQuantity(increase ? 1 : -1)
                              : null,
                          icon: Icon(increase
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down),
                        ),
                    ],
                  ),
                ),
              ),
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              onChanged: (_) => _onChanged(),
            ),
          ),
          const SizedBox(width: AppTokens.spacingSmall),
          SizedBox(
            width: 80,
            child: Text(
              widget.item.total.valueOnly,
              textAlign: TextAlign.end,
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: AppTokens.iconSizeXLarge,
            child: IconButton(
              icon: Icon(Icons.close,
                  color: widget.colorScheme.error,
                  size: AppTokens.iconSizeMedium),
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
