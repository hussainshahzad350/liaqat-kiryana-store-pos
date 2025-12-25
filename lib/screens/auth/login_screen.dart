import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart'; // Import the localizations delegate

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ FIXED: Marked final
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // ✅ FIXED: Added dispose method
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Helper to access localizations easier
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center( 
        child: Container(
          width: 400, 
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store, size: 80, color: colorScheme.primary),
                  const SizedBox(height: 20),
                  // UPDATED: Use localized app title
                  Text(
                    localizations.appTitle, 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  // UPDATED: Use localized POS system label
                  Text(
                    localizations.posSystem, 
                    style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      // UPDATED: Use localized password label
                      labelText: localizations.password,
                      // Border handled by global theme
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // In a real app, you would validate the password here asynchronously
                        // and check `if (!mounted) return;` before navigating.
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      // UPDATED: Use localized Login button text
                      child: Text(localizations.login, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // UPDATED: Use localized Forgot Password text
                  TextButton(
                    onPressed: () {}, 
                    child: Text(localizations.forgotPassword),
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