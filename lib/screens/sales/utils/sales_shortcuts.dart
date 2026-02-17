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
    };
  }

  /// Creates action handlers for the shortcuts
  /// 
  /// Parameters:
  /// - onCheckout: Called when F9 is pressed (requires non-empty cart)
  /// - onClearCart: Called when ESC is pressed (requires non-empty cart)
  /// - onFocusSearch: Called when Ctrl+F is pressed
  /// - onAddCustomer: Called when Ctrl+N is pressed
  static Map<Type, Action<Intent>> createActions({
    required VoidCallback onCheckout,
    required VoidCallback onClearCart,
    required VoidCallback onFocusSearch,
    required VoidCallback onAddCustomer,
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
    };
  }
}
