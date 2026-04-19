import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../controller/customer_controller.dart';

class CustomerSearchBar extends StatefulWidget {
  const CustomerSearchBar({super.key});

  @override
  State<CustomerSearchBar> createState() => _CustomerSearchBarState();
}

class _CustomerSearchBarState extends State<CustomerSearchBar> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus search bar for POS fast workflow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final controller = context.read<CustomerController>();
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            controller.handleKeyboardNavigation(true);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            controller.handleKeyboardNavigation(false);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            controller.submitSelected();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Card(
        elevation: AppTokens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.cardPadding),
          child: TextField(
            focusNode: _focusNode,
            onChanged: (val) => context.read<CustomerController>().onSearchChanged(val),
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: loc.searchPlaceholder,
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.buttonBorderRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingStandard,
                vertical: AppTokens.spacingStandard,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
