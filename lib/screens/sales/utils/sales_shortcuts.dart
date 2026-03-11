import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// Intent classes for keyboard shortcuts
class CheckoutIntent extends Intent {
  const CheckoutIntent();
}

class ClearCartIntent extends Intent {
  const ClearCartIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class AddCustomerIntent extends Intent {
  const AddCustomerIntent();
}

class NewSaleIntent extends Intent {
  const NewSaleIntent();
}

class PrintReceiptIntent extends Intent {
  const PrintReceiptIntent();
}

/// Provides keyboard shortcuts configuration for the Sales screen
class SalesShortcuts {
  /// Returns the keyboard shortcuts mapping for sales operations
  static Map<ShortcutActivator, Intent> getShortcuts() {
    return const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.f9): CheckoutIntent(),
      SingleActivator(LogicalKeyboardKey.escape): ClearCartIntent(),
      SingleActivator(LogicalKeyboardKey.keyF, control: true):
          FocusSearchIntent(),
      SingleActivator(LogicalKeyboardKey.keyN, control: true):
          AddCustomerIntent(),
      // Ctrl+Shift+N = New Sale (Ctrl+N is taken by Add Customer)
      SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true):
          NewSaleIntent(),
      // Ctrl+P = Print last receipt
      SingleActivator(LogicalKeyboardKey.keyP, control: true):
          PrintReceiptIntent(),
    };
  }

  /// Creates action handlers for the shortcuts
  static Map<Type, Action<Intent>> createActions({
    required VoidCallback onCheckout,
    required VoidCallback onClearCart,
    required VoidCallback onFocusSearch,
    required VoidCallback onAddCustomer,
    required VoidCallback onNewSale,
    required VoidCallback onPrint,
  }) {
    return <Type, Action<Intent>>{
      CheckoutIntent: CallbackAction<CheckoutIntent>(
        onInvoke: (_) {
          onCheckout();
          return null;
        },
      ),
      ClearCartIntent: CallbackAction<ClearCartIntent>(
        onInvoke: (_) {
          onClearCart();
          return null;
        },
      ),
      FocusSearchIntent: CallbackAction<FocusSearchIntent>(
        onInvoke: (_) {
          onFocusSearch();
          return null;
        },
      ),
      AddCustomerIntent: CallbackAction<AddCustomerIntent>(
        onInvoke: (_) {
          onAddCustomer();
          return null;
        },
      ),
      NewSaleIntent: CallbackAction<NewSaleIntent>(
        onInvoke: (_) {
          onNewSale();
          return null;
        },
      ),
      PrintReceiptIntent: CallbackAction<PrintReceiptIntent>(
        onInvoke: (_) {
          onPrint();
          return null;
        },
      ),
    };
  }
}
