import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/res/app_tokens.dart';

/// Shared desktop search surface with optional keyboard list navigation.
class AppSearchCard extends StatefulWidget {
  const AppSearchCard({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onMoveDown,
    this.onMoveUp,
    this.onSubmitSelection,
    this.autoFocus = true,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onMoveDown;
  final VoidCallback? onMoveUp;
  final VoidCallback? onSubmitSelection;
  final bool autoFocus;

  @override
  State<AppSearchCard> createState() => _AppSearchCardState();
}

class _AppSearchCardState extends State<AppSearchCard> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
        ),
        child: Padding(
          padding: EdgeInsets.zero,
          child: TextField(
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: Icon(Icons.search, color: colorScheme.primary),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppTokens.buttonBorderRadius),
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        widget.onMoveDown != null) {
      widget.onMoveDown!();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        widget.onMoveUp != null) {
      widget.onMoveUp!();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        widget.onSubmitSelection != null) {
      widget.onSubmitSelection!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
