import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/res/app_tokens.dart';
import '../../../core/services/pin_auth_service.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/setting_section.dart';

/// Settings page for changing the login PIN.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorText;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    final loc = AppLocalizations.of(context)!;
    final current = _currentController.text.trim();
    final newPin = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.length < 4 || current.length > 6) {
      setState(() => _errorText = loc.pinTooShort);
      return;
    }
    if (newPin.length < 4 || newPin.length > 6) {
      setState(() => _errorText = loc.pinTooShort);
      return;
    }
    if (newPin != confirm) {
      setState(() => _errorText = loc.pinMismatch);
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final service = context.read<PinAuthService>();
    final recoveryCode = await service.changePin(current, newPin);

    if (!mounted) return;
    setState(() => _loading = false);

    if (recoveryCode == null) {
      final lockout = await service.getLockoutStatus();
      if (!mounted) return;
      setState(() {
        _errorText = lockout.isLocked
            ? loc.pinLockedOut(lockout.remainingSeconds)
            : loc.pinIncorrect;
      });
      return;
    }

    _currentController.clear();
    _newController.clear();
    _confirmController.clear();

    await _showRecoveryCodeDialog(recoveryCode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.pinChanged),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _showRecoveryCodeDialog(String code) async {
    final loc = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(loc.recoveryCodeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.recoveryCodeInstructions),
            const SizedBox(height: AppTokens.spacingLarge),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.spacingMedium,
                horizontal: AppTokens.spacingLarge,
              ),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMedium),
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: Text(loc.copyCode),
              onPressed: () => Clipboard.setData(ClipboardData(text: code)),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.spacingLarge),
          child: Column(
            children: [
              SettingSection(
                title: loc.changePin,
                icon: Icons.lock_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc.changePinSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppTokens.spacingLarge),
                    _PinFormField(
                      controller: _currentController,
                      label: loc.currentPin,
                      obscure: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _PinFormField(
                      controller: _newController,
                      label: loc.newPin,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: AppTokens.spacingMedium),
                    _PinFormField(
                      controller: _confirmController,
                      label: loc.confirmNewPin,
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      onSubmitted: (_) => _changePin(),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: AppTokens.spacingSmall),
                      Text(
                        _errorText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppTokens.spacingLarge),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _loading ? null : _changePin,
                        child: Text(loc.changePin),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_loading)
          Container(
            color: Colors.black.withValues(alpha: 0.35),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _PinFormField extends StatelessWidget {
  const _PinFormField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTokens.inputHeight,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggle,
          ),
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}
