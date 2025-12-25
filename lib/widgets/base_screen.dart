// lib/widgets/base_screen.dart

import 'package:flutter/material.dart';
import 'app_navigation_sidebar.dart';

class BaseScreen extends StatefulWidget {
  final String currentRoute;
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const BaseScreen({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  bool isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
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
            child: Column(
              children: [
                // Header
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (widget.actions != null) ...widget.actions!,
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}