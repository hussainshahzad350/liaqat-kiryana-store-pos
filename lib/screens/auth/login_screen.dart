import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/res/app_tokens.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/pin_auth_service.dart';
import '../../l10n/app_localizations.dart';

// ─── Login modes ─────────────────────────────────────────────────────────────

enum _LoginMode {
  /// No PIN set yet — show Set-PIN form.
  setup,

  /// PIN exists — show verify form.
  verify,

  /// Forgot PIN — show recovery-code form.
  recover,

  /// Recovery succeeded — show Set-PIN form for new PIN.
  resetAfterRecovery,
}

// ─── LoginScreen ─────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── controllers ──────────────────────────────────────────────────────────
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _recoveryController = TextEditingController();

  // ── state ─────────────────────────────────────────────────────────────────
  _LoginMode _mode = _LoginMode.verify;
  bool _loading = true;
  String? _errorText;
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  // lockout
  int _lockRemaining = 0;
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _init();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _recoveryController.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  // ── init ─────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final service = context.read<PinAuthService>();
    final hasPin = await service.hasPin();
    final lockout = await service.getLockoutStatus();

    if (!mounted) return;
    setState(() {
      _mode = hasPin ? _LoginMode.verify : _LoginMode.setup;
      _loading = false;
    });

    if (lockout.isLocked) _startLockTimer(lockout.remainingSeconds);
  }

  // ── lockout timer ─────────────────────────────────────────────────────────

  void _startLockTimer(int seconds) {
    _lockTimer?.cancel();
    setState(() => _lockRemaining = seconds);
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final remaining = _lockRemaining - 1;
      if (remaining <= 0) {
        t.cancel();
        setState(() => _lockRemaining = 0);
      } else {
        setState(() => _lockRemaining = remaining);
      }
    });
  }

  // ── actions ───────────────────────────────────────────────────────────────

  Future<void> _submitVerify() async {
    if (_lockRemaining > 0) return;
    final loc = AppLocalizations.of(context)!;
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 6) {
      setState(() => _errorText = loc.pinTooShort);
      return;
    }
    setState(() {
      _loading = true;
      _errorText = null;
    });

    final service = context.read<PinAuthService>();
    final result = await service.verifyPin(pin);

    if (!mounted) return;
    switch (result) {
      case PinVerifyResult.success:
        _navigateToDashboard();
        return;
      case PinVerifyResult.lockedOut:
        final lockout = await service.getLockoutStatus();
        if (mounted) {
          _startLockTimer(lockout.remainingSeconds);
          setState(() {
            _loading = false;
            _errorText = null;
          });
        }
        return;
      case PinVerifyResult.invalid:
        // Remaining-attempts feedback
        final lockout = await service.getLockoutStatus();
        if (!mounted) return;
        if (lockout.isLocked) {
          _startLockTimer(lockout.remainingSeconds);
          setState(() {
            _loading = false;
            _errorText = null;
          });
        } else {
          setState(() {
            _loading = false;
            _errorText = loc.pinIncorrect;
          });
        }
    }
  }

  Future<void> _submitSetup() async {
    final loc = AppLocalizations.of(context)!;
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4 || pin.length > 6) {
      setState(() => _errorText = loc.pinTooShort);
      return;
    }
    if (pin != confirm) {
      setState(() => _errorText = loc.pinMismatch);
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final service = context.read<PinAuthService>();
    final isReset = _mode == _LoginMode.resetAfterRecovery;
    final recoveryCode =
        isReset ? await service.resetPinWithNewPin(pin) : await service.setupPin(pin);

    if (!mounted) return;
    setState(() => _loading = false);
    await _showRecoveryCodeDialog(recoveryCode);
    if (mounted) _navigateToDashboard();
  }

  Future<void> _submitRecovery() async {
    final loc = AppLocalizations.of(context)!;
    final code = _recoveryController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final service = context.read<PinAuthService>();
    final valid = await service.verifyRecoveryCode(code);

    if (!mounted) return;
    if (valid) {
      setState(() {
        _loading = false;
        _mode = _LoginMode.resetAfterRecovery;
        _pinController.clear();
        _confirmController.clear();
        _errorText = null;
      });
    } else {
      setState(() {
        _loading = false;
        _errorText = loc.recoveryCodeInvalid;
      });
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, AppRoutes.sales);
  }

  // ── recovery-code dialog ──────────────────────────────────────────────────

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

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Container(
          width: AppTokens.sidebarWidthMedium,
          padding: const EdgeInsets.all(AppTokens.spacingXLarge),
          child: Card(
            elevation: AppTokens.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.cardPadding),
              child: _buildBody(loc, colorScheme, textTheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations loc,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    switch (_mode) {
      case _LoginMode.setup:
      case _LoginMode.resetAfterRecovery:
        return _buildSetupForm(loc, colorScheme, textTheme);
      case _LoginMode.verify:
        return _buildVerifyForm(loc, colorScheme, textTheme);
      case _LoginMode.recover:
        return _buildRecoveryForm(loc, colorScheme, textTheme);
    }
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      AppLocalizations loc, ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        Icon(
          Icons.store,
          size: AppTokens.aboutIconSize,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppTokens.spacingLarge),
        Text(
          loc.appTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTokens.spacingSmall),
        Text(
          loc.posSystem,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.spacingLarge),
      ],
    );
  }

  // ── verify form ───────────────────────────────────────────────────────────

  Widget _buildVerifyForm(
    AppLocalizations loc,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final locked = _lockRemaining > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(loc, colorScheme, textTheme),
        _PinField(
          controller: _pinController,
          label: loc.enterPin,
          hint: loc.pinHint,
          obscure: _obscurePin,
          onToggleObscure: () => setState(() => _obscurePin = !_obscurePin),
          enabled: !locked,
          onSubmitted: locked ? null : (_) => _submitVerify(),
          errorText: _errorText,
        ),
        if (locked)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spacingSmall),
            child: Text(
              loc.pinLockedOut(_lockRemaining),
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: AppTokens.spacingLarge),
        SizedBox(
          width: double.infinity,
          height: AppTokens.buttonHeight,
          child: FilledButton(
            onPressed: locked ? null : _submitVerify,
            child: Text(
              loc.login,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingSmall),
        TextButton(
          onPressed: () => setState(() {
            _mode = _LoginMode.recover;
            _errorText = null;
            _recoveryController.clear();
          }),
          child: Text(
            loc.forgotPassword,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  // ── setup form ────────────────────────────────────────────────────────────

  Widget _buildSetupForm(
    AppLocalizations loc,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(loc, colorScheme, textTheme),
        _PinField(
          controller: _pinController,
          label: loc.setPin,
          hint: loc.pinHint,
          obscure: _obscurePin,
          onToggleObscure: () => setState(() => _obscurePin = !_obscurePin),
          errorText: _errorText,
        ),
        const SizedBox(height: AppTokens.spacingSmall),
        _PinField(
          controller: _confirmController,
          label: loc.confirmPin,
          hint: loc.pinHint,
          obscure: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          onSubmitted: (_) => _submitSetup(),
        ),
        const SizedBox(height: AppTokens.spacingLarge),
        SizedBox(
          width: double.infinity,
          height: AppTokens.buttonHeight,
          child: FilledButton(
            onPressed: _submitSetup,
            child: Text(
              loc.setPin,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── recovery form ──────────────────────────────────────────────────────────

  Widget _buildRecoveryForm(
    AppLocalizations loc,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(loc, colorScheme, textTheme),
        TextField(
          controller: _recoveryController,
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: loc.recoveryCode,
            hintText: loc.recoveryCodeHint,
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            errorText: _errorText,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitRecovery(),
        ),
        const SizedBox(height: AppTokens.spacingLarge),
        SizedBox(
          width: double.infinity,
          height: AppTokens.buttonHeight,
          child: FilledButton(
            onPressed: _submitRecovery,
            child: Text(
              loc.recover,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingSmall),
        TextButton(
          onPressed: () => setState(() {
            _mode = _LoginMode.verify;
            _errorText = null;
          }),
          child: Text(
            loc.backToLogin,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

// ─── _PinField ────────────────────────────────────────────────────────────────

/// Reusable PIN input field (numeric, 4-6 digits).
class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.onToggleObscure,
    this.enabled = true,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleObscure,
        ),
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: onSubmitted,
    );
  }
}

