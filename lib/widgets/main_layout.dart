// lib/widgets/main_layout.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for keyboard shortcuts
import 'app_navigation_sidebar.dart';
import '../l10n/app_localizations.dart'; // Import for localization
import '../core/routes/app_routes.dart'; // Import for AppRoutes

class MainLayout extends StatefulWidget {
  final String currentRoute;
  final Widget child;

  const MainLayout({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isEnglish = localizations.localeName == 'en';
    final colorScheme = Theme.of(context).colorScheme;

    // Move the Intents here or to a separate file if they are truly global and used by multiple layouts.
    // For now, moving them here as per the plan.
    const _NewSaleIntent newSaleIntent = _NewSaleIntent();
    const _RefreshIntent refreshIntent = _RefreshIntent();
    const _ToggleSidebarIntent toggleSidebarIntent = _ToggleSidebarIntent();

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyN): newSaleIntent,
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyR): refreshIntent,
        LogicalKeySet(LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyB): toggleSidebarIntent, // 'B' for sidebar
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewSaleIntent: CallbackAction<_NewSaleIntent>(onInvoke: (intent) {
            Navigator.pushNamed(context, AppRoutes.sales); // Assuming AppRoutes is imported
            return null;
          }),
          _RefreshIntent: CallbackAction<_RefreshIntent>(onInvoke: (intent) {
            // How to refresh the current child screen? This needs more thought.
            // For now, a simple snackbar or a refresh callback could be passed to MainLayout if needed.
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
            setState(() {
              isSidebarExpanded = !isSidebarExpanded;
            });
            return null;
          }),
        },
        child: FocusTraversalGroup(
          child: Scaffold(
            body: Row(
              textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl, // Set text direction based on language
              children: [
                // Sidebar
                AppNavigationSidebar(
                  currentRoute: widget.currentRoute,
                  isExpanded: isSidebarExpanded,
                  onToggle: () {
                    setState(() {
                      isSidebarExpanded = !isSidebarExpanded;
                    });
                  },
                ),
                
                // Main Content
                Expanded(
                  child: widget.child,
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