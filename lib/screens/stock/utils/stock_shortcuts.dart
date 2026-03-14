import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Intent classes
class RefreshIntent extends Intent {
  const RefreshIntent();
}

class ActivateSearchIntent extends Intent {
  const ActivateSearchIntent();
}

class ClosePanelIntent extends Intent {
  const ClosePanelIntent();
}

class MoveSelectionUpIntent extends Intent {
  const MoveSelectionUpIntent();
}

class MoveSelectionDownIntent extends Intent {
  const MoveSelectionDownIntent();
}

class ActivateSelectionIntent extends Intent {
  const ActivateSelectionIntent();
}

class NewPurchaseIntent extends Intent {
  const NewPurchaseIntent();
}

// Shortcuts definition
class StockShortcuts {
  static const Map<ShortcutActivator, Intent> shortcuts =
      <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.f5): RefreshIntent(),
    SingleActivator(LogicalKeyboardKey.keyF, control: true):
        ActivateSearchIntent(),
    SingleActivator(LogicalKeyboardKey.escape): ClosePanelIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionUpIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionDownIntent(),
    SingleActivator(LogicalKeyboardKey.enter): ActivateSelectionIntent(),
    SingleActivator(LogicalKeyboardKey.keyN, control: true):
        NewPurchaseIntent(),
  };

  static Map<Type, Action<Intent>> createActions({
    required Function onRefresh,
    required Function onSearch,
    required Function onClosePanel,
    required Function onMoveUp,
    required Function onMoveDown,
    required Function onActivate,
    required Function onNewPurchase,
  }) {
    return <Type, Action<Intent>>{
      RefreshIntent: CallbackAction<RefreshIntent>(onInvoke: (_) {
        onRefresh();
        return null;
      }),
      ActivateSearchIntent: CallbackAction<ActivateSearchIntent>(onInvoke: (_) {
        onSearch();
        return null;
      }),
      ClosePanelIntent: CallbackAction<ClosePanelIntent>(onInvoke: (_) {
        onClosePanel();
        return null;
      }),
      MoveSelectionUpIntent:
          CallbackAction<MoveSelectionUpIntent>(onInvoke: (_) {
        onMoveUp();
        return null;
      }),
      MoveSelectionDownIntent:
          CallbackAction<MoveSelectionDownIntent>(onInvoke: (_) {
        onMoveDown();
        return null;
      }),
      ActivateSelectionIntent:
          CallbackAction<ActivateSelectionIntent>(onInvoke: (_) {
        onActivate();
        return null;
      }),
      NewPurchaseIntent: CallbackAction<NewPurchaseIntent>(onInvoke: (_) {
        onNewPurchase();
        return null;
      }),
    };
  }
}
