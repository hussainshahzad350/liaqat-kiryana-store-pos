// lib/widgets/app_navigation_sidebar.dart

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';

class AppNavigationSidebar extends StatefulWidget {
  final String currentRoute;
  final bool isExpanded;
  final VoidCallback onToggle;

  const AppNavigationSidebar({
    super.key,
    required this.currentRoute,
    this.isExpanded = true,
    required this.onToggle,
  });

  @override
  State<AppNavigationSidebar> createState() => _AppNavigationSidebarState();
}

class _AppNavigationSidebarState extends State<AppNavigationSidebar> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isExpanded ? 240 : 70,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: BorderDirectional(
          end: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ClipRect(
        child: Column(
          children: [
            // Logo Section
            _buildSidebarHeader(localizations),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildMenuItem(
                    icon: Icons.dashboard,
                    title: localizations.home,
                    route: AppRoutes.home,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.shopping_cart,
                    title: localizations.salesPos,
                    route: AppRoutes.sales,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.warehouse,
                    title: localizations.stockManagement,
                    route: AppRoutes.stock,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.inventory,
                    title: localizations.items,
                    route: AppRoutes.items,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.people,
                    title: localizations.customers,
                    route: AppRoutes.customers,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.business,
                    title: localizations.suppliers,
                    route: AppRoutes.suppliers,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.category,
                    title: localizations.categories,
                    route: AppRoutes.categories,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.square_foot,
                    title: localizations.units,
                    route: AppRoutes.units,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.analytics,
                    title: localizations.reports,
                    route: AppRoutes.reports,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.attach_money,
                    title: localizations.cashLedger,
                    route: AppRoutes.cashLedger,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.settings,
                    title: localizations.settings,
                    route: AppRoutes.settings,

                  ),
                  
                  const Divider(height: 1),
                  
                  _buildMenuItem(
                    icon: Icons.info,
                    title: localizations.aboutApp,
                    route: AppRoutes.about,

                  ),
                  
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: localizations.logout,
                    route: '/logout',
                    color: colorScheme.error,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                ],
              ),
            ),
            
            // Footer
            _buildSidebarFooter(localizations),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebarHeader(AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: widget.isExpanded ? 55 : 35,
            height: widget.isExpanded ? 55 : 35,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.store,
              size: widget.isExpanded ? 28 : 20,
              color: colorScheme.primary,
            ),
          ),
          
          if (widget.isExpanded) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                localizations.appTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isActive = widget.currentRoute == route;
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap ?? () {
        if (!isActive) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: widget.isExpanded 
              ? MainAxisAlignment.start 
              : MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: widget.isExpanded ? 12.0 : 0),
              child: Icon(
                icon,
                size: 22,
                color: color ?? (isActive ? colorScheme.primary : colorScheme.onSurfaceVariant),
              ),
            ),
            
            if (widget.isExpanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: color ?? (isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebarFooter(AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isExpanded) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          localizations.systemOnline,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 9,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggle,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant, width: 1),
                  ),
                ),
                child: Icon(
                  widget.isExpanded 
                      ? Icons.chevron_left 
                      : Icons.chevron_right,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}