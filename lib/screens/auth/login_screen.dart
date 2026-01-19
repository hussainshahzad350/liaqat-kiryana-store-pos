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
              padding: const EdgeInsets.symmetric(
                horizontal: DesktopDimensions.cardPadding,
                vertical: DesktopDimensions.spacingLarge,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store,
                    size: DesktopDimensions.kpiIconSize * 2.5,
                    color: colorScheme.primary,
                  ),

                  const SizedBox(height: DesktopDimensions.spacingLarge),

                  Text(
                    localizations.appTitle,
                    style: TextStyle(
                      fontSize: DesktopDimensions.appTitleSize,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: DesktopDimensions.spacingSmall),

                  Text(
                    localizations.posSystem,
                    style: TextStyle(
                      fontSize: DesktopDimensions.bodySize,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: DesktopDimensions.spacingLarge),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: DesktopDimensions.spacingSmall),
                    child: SizedBox(
                      height: DesktopDimensions.inputHeight,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: DesktopDimensions.bodySize,
                        ),
                        decoration: InputDecoration(
                          labelText: localizations.password,
                          labelStyle:
                              TextStyle(color: colorScheme.onSurfaceVariant),
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

                  SizedBox(
                    width: double.infinity,
                    height: DesktopDimensions.inputHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: Text(
                        localizations.login,
                        style: TextStyle(
                          fontSize: DesktopDimensions.bodySize,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: DesktopDimensions.spacingSmall),

                  TextButton(
                    onPressed: () {},
                    child: Text(
                      localizations.forgotPassword,
                      style: TextStyle(
                        fontSize: DesktopDimensions.bodySize,
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
