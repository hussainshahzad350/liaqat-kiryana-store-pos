import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'on_screen_keyboard.dart';

/// Presentation-only input aid. Edits go through EditableText's normal input
/// formatters and onChanged callback, just like physical keyboard input.
class AppMouseInput extends StatefulWidget {
  const AppMouseInput({super.key, required this.child});
  final Widget child;

  @override
  State<AppMouseInput> createState() => _AppMouseInputState();
}

class _AppMouseInputState extends State<AppMouseInput> {
  EditableTextState? _target;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_focusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusChanged());
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_focusChanged);
    super.dispose();
  }

  void _focusChanged() {
    if (!mounted || _open) return;
    final context = FocusManager.instance.primaryFocus?.context;
    final target =
        context is StatefulElement && context.state is EditableTextState
            ? context.state as EditableTextState
            : context?.findAncestorStateOfType<EditableTextState>();
    if (target != _target) setState(() => _target = target);
  }

  Future<void> _showKeyboard() async {
    final target = _target;
    if (target == null || !target.mounted || target.widget.readOnly || _open) {
      return;
    }
    setState(() => _open = true);
    final value = await showDialog<TextEditingValue>(
      context: target.context,
      builder: (_) => OnScreenKeyboard(
        initialValue: target.widget.controller.value,
        keyboardType: target.widget.keyboardType,
        obscureText: target.widget.obscureText,
        inputFormatters: target.widget.inputFormatters ?? const [],
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (value != null && target.mounted && !target.widget.readOnly) {
      target.userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);
      target.widget.focusNode.requestFocus();
    }
    _focusChanged();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final canEdit = !_open &&
        _target != null &&
        _target!.mounted &&
        !_target!.widget.readOnly;
    return Column(children: [
      Expanded(child: widget.child),
      Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
              child: Row(children: [
                Expanded(
                    child: Text(loc.mouseInputHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall)),
                // Clicking the aid must not steal focus from its target field.
                TextFieldTapRegion(
                    child: ExcludeFocus(
                        child: TextButton.icon(
                  key: const ValueKey('open-on-screen-keyboard'),
                  onPressed: canEdit ? _showKeyboard : null,
                  icon: const Icon(Icons.keyboard_outlined, size: 20),
                  label: Text(loc.onScreenKeyboard),
                ))),
              ]),
            )),
      ),
    ]);
  }
}
