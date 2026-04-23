import 'package:flutter/material.dart';

class OptionSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const OptionSwitch({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: icon != null ? Icon(icon, size: 20) : null,
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
