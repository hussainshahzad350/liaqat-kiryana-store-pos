// lib/widgets/main_layout.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_navigation_sidebar.dart';
import '../l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';
import '../core/providers/sidebar_provider.dart';
import 'app_header.dart';

class MainLayout extends StatelessWidget {
  final String currentRoute;
  final Widget child;

  const MainLayout({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isEnglish = localizations.localeName == 'en';
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);

    const newSaleIntent = _NewSaleIntent();
    const refreshIntent = _RefreshIntent();
    const toggleSidebarIntent = _ToggleSidebarIntent();

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyN): newSaleIntent,
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyR): refreshIntent,
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyB): toggleSidebarIntent,
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewSaleIntent: CallbackAction<_NewSaleIntent>(onInvoke: (intent) {
            Navigator.pushNamed(context, AppRoutes.sales);
            return null;
          }),
          _RefreshIntent: CallbackAction<_RefreshIntent>(onInvoke: (intent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizations.refreshingData,
                  style: TextStyle(color: colorScheme.onInverseSurface),
                ),
                backgroundColor: colorScheme.inverseSurface,
              ),
            );
            return null;
          }),
          _ToggleSidebarIntent: CallbackAction<_ToggleSidebarIntent>(onInvoke: (intent) {
            sidebarProvider.toggleSidebar();
            return null;
          }),
        },
        child: FocusTraversalGroup(
          child: Scaffold(
            body: Row(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
              children: [
                AppNavigationSidebar(
                  currentRoute: currentRoute,
                ),
                Expanded(
                  child: Column(
                    children: [
                      AppHeader(currentRoute: currentRoute),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// KEYBOARD SHORTCUT INTENTS
// Moved from home_screen.dart to main_layout.dart for global usage
// ============================================================================

class _NewSaleIntent extends Intent {
  const _NewSaleIntent();
}

class _RefreshIntent extends Intent {
  const _RefreshIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}