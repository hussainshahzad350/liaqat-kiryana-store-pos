import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class OnScreenKeyboard extends StatefulWidget {
  const OnScreenKeyboard(
      {super.key,
      required this.initialValue,
      required this.keyboardType,
      required this.obscureText,
      required this.inputFormatters});
  final TextEditingValue initialValue;
  final TextInputType keyboardType;
  final bool obscureText;
  final List<TextInputFormatter> inputFormatters;

  @override
  State<OnScreenKeyboard> createState() => _OnScreenKeyboardState();
}

class _OnScreenKeyboardState extends State<OnScreenKeyboard> {
  late final TextEditingController _controller;
  late bool _numbers;
  bool _urdu = false;
  bool _uppercase = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController.fromValue(widget.initialValue);
    _numbers = widget.keyboardType.index == TextInputType.number.index ||
        widget.keyboardType == TextInputType.phone ||
        widget.obscureText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replace(String text, {bool backspace = false, bool clear = false}) {
    final old = _controller.value;
    var start = old.selection.isValid ? old.selection.start : old.text.length;
    var end = old.selection.isValid ? old.selection.end : old.text.length;
    if (clear) {
      start = 0;
      end = old.text.length;
    }
    if (backspace && start == end && start > 0) {
      start -= old.text.substring(0, start).characters.last.length;
    }
    var next = TextEditingValue(
      text: old.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    for (final formatter in widget.inputFormatters) {
      next = formatter.formatEditUpdate(old, next);
    }
    _controller.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final rows = _numbers
        ? ['789', '456', '123', '-0.']
        : _urdu
            ? ['قورتےئیہپٹڈ', 'اسدفگھجکلحخ', 'زشچطبنمعغڑ', 'ذثصضظؤۃںءآ']
            : ['qwertyuiop', 'asdfghjkl', 'zxcvbnm', '@.,-/()'];
    final theme = Theme.of(context);
    return Theme(
        data: theme.copyWith(
            textTheme: theme.textTheme.copyWith(
          titleLarge: theme.textTheme.titleLarge?.copyWith(height: 1.2),
          bodyLarge: theme.textTheme.bodyLarge?.copyWith(height: 1.2),
          labelLarge: theme.textTheme.labelLarge?.copyWith(height: 1.2),
        )),
        child: AlertDialog(
          insetPadding: const EdgeInsets.all(16),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(loc.onScreenKeyboard),
          content: SizedBox(
            width: _numbers ? 320 : 640,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                key: const ValueKey('on-screen-keyboard-preview'),
                controller: _controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                textDirection:
                    _urdu && !_numbers ? TextDirection.rtl : TextDirection.ltr,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              ExcludeFocus(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                Wrap(spacing: 6, children: [
                  ChoiceChip(
                      label: const Text('123'),
                      selected: _numbers,
                      onSelected: (_) => setState(() => _numbers = true)),
                  ChoiceChip(
                      label: const Text('ABC'),
                      selected: !_numbers && !_urdu,
                      onSelected: (_) => setState(() {
                            _numbers = false;
                            _urdu = false;
                          })),
                  ChoiceChip(
                      label: const Text('اردو'),
                      selected: !_numbers && _urdu,
                      onSelected: (_) => setState(() {
                            _numbers = false;
                            _urdu = true;
                          })),
                ]),
                const SizedBox(height: 8),
                // Key positions do not reverse when the surrounding app is RTL.
                Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(children: [
                      for (final row in rows)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(children: [
                              for (final character in row.characters)
                                Expanded(
                                    child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: OutlinedButton(
                                    key: ValueKey('keyboard-key-$character'),
                                    style: OutlinedButton.styleFrom(
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 40)),
                                    onPressed: () => _replace(
                                        _uppercase && !_urdu
                                            ? character.toUpperCase()
                                            : character),
                                    child: Text(_uppercase && !_urdu
                                        ? character.toUpperCase()
                                        : character),
                                  ),
                                )),
                            ])),
                    ])),
                Wrap(spacing: 8, children: [
                  TextButton(
                      onPressed: () => _replace('', clear: true),
                      child: Text(loc.clearInput)),
                  if (!_numbers)
                    TextButton(
                        onPressed: () => _replace(' '),
                        child: Text(loc.keyboardSpace)),
                  if (!_numbers && !_urdu)
                    IconButton(
                        tooltip: loc.keyboardShift,
                        isSelected: _uppercase,
                        onPressed: () =>
                            setState(() => _uppercase = !_uppercase),
                        icon: const Icon(Icons.keyboard_capslock)),
                  IconButton(
                      key: const ValueKey('keyboard-backspace'),
                      tooltip: loc.keyboardBackspace,
                      onPressed: () => _replace('', backspace: true),
                      icon: const Icon(Icons.backspace_outlined)),
                ]),
              ])),
            ])),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.cancel)),
            FilledButton(
                key: const ValueKey('keyboard-apply'),
                onPressed: () => Navigator.pop(context, _controller.value),
                child: Text(loc.applyInput)),
          ],
        ));
  }
}
