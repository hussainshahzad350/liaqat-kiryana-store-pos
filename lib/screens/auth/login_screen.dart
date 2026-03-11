import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/res/app_tokens.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Container(
          width: AppTokens.sidebarWidthMedium,
          padding: const EdgeInsets.all(AppTokens.spacingXLarge),
          child: Card(
            elevation: AppTokens.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppTokens.cardBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store,
                    size: AppTokens.aboutIconSize,
                    color: colorScheme.primary,
                  ),

                  const SizedBox(height: AppTokens.spacingLarge),

                  Text(
                    localizations.appTitle,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppTokens.spacingSmall),

                  Text(
                    localizations.posSystem,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppTokens.spacingLarge),

                  // Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.spacingSmall),
                    child: SizedBox(
                      height: AppTokens.inputHeight,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: localizations.password,
                          labelStyle: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTokens.spacingLarge),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: AppTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: Text(
                        localizations.login,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTokens.spacingSmall),

                  // Forgot Password
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      localizations.forgotPassword,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
