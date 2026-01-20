import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants/desktop_dimensions.dart';

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
          width: DesktopDimensions.sidebarWidthMedium,
          padding: const EdgeInsets.all(DesktopDimensions.spacingXLarge),
          child: Card(
            elevation: DesktopDimensions.cardElevation,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DesktopDimensions.cardBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(DesktopDimensions.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store,
                    size: DesktopDimensions.aboutIconSize,
                    color: colorScheme.primary,
                  ),

                  const SizedBox(height: DesktopDimensions.spacingLarge),

                  Text(
                    localizations.appTitle,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: DesktopDimensions.spacingSmall),

                  Text(
                    localizations.posSystem,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: DesktopDimensions.spacingLarge),

                  // Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesktopDimensions.spacingSmall),
                    child: SizedBox(
                      height: DesktopDimensions.inputHeight,
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

                  const SizedBox(height: DesktopDimensions.spacingLarge),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: DesktopDimensions.buttonHeight,
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

                  const SizedBox(height: DesktopDimensions.spacingSmall),

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
