// lib/widgets/app_navigation_sidebar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';
import '../core/providers/sidebar_provider.dart';
import '../core/res/app_dimensions.dart';

class AppNavigationSidebar extends StatelessWidget {
  final String currentRoute;

  const AppNavigationSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final sidebarProvider = Provider.of<SidebarProvider>(context);
    final isExpanded = sidebarProvider.isSidebarExpanded;
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isExpanded
          ? AppDimensions.sidebarExpandedWidth
          : AppDimensions.sidebarCollapsedWidth,
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
            _buildSidebarHeader(context, isExpanded, localizations),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.dashboard,
                    title: localizations.home,
                    route: AppRoutes.home,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.shopping_cart,
                    title: localizations.salesPos,
                    route: AppRoutes.sales,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.warehouse,
                    title: localizations.stockManagement,
                    route: AppRoutes.stock,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.inventory,
                    title: localizations.items,
                    route: AppRoutes.items,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.people,
                    title: localizations.customers,
                    route: AppRoutes.customers,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.business,
                    title: localizations.suppliers,
                    route: AppRoutes.suppliers,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.category,
                    title: localizations.categories,
                    route: AppRoutes.categories,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.square_foot,
                    title: localizations.units,
                    route: AppRoutes.units,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.analytics,
                    title: localizations.reports,
                    route: AppRoutes.reports,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.attach_money,
                    title: localizations.cashLedger,
                    route: AppRoutes.cashLedger,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.settings,
                    title: localizations.settings,
                    route: AppRoutes.settings,
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.info,
                    title: localizations.aboutApp,
                    route: AppRoutes.about,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
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
            _buildSidebarFooter(context, isExpanded, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(
      BuildContext context, bool isExpanded, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: AppDimensions.sidebarHeaderHeight,
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
            width: isExpanded ? 55 : 35,
            height: isExpanded ? 55 : 35,
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
              size: isExpanded ? 28 : 20,
              color: colorScheme.primary,
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMedium),
              child: Text(
                localizations.appTitle,
                style: TextStyle(
                  fontSize: AppDimensions.menuItemFontSize,
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

  Widget _buildMenuItem(
    BuildContext context, {
    required bool isExpanded,
    required IconData icon,
    required String title,
    required String route,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isActive = currentRoute == route;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap ??
          () {
            if (!isActive) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
      child: Container(
        height: AppDimensions.menuItemHeight,
        margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingSmall,
            vertical: AppDimensions.spacingSmall),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.spacingMedium),
          border: isActive
              ? Border.all(color: colorScheme.primary, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment:
              isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: isExpanded ? 12.0 : 0),
              child: Icon(
                icon,
                size: AppDimensions.menuItemIconSize,
                color: color ??
                    (isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant),
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppDimensions.menuItemFontSize,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: color ??
                        (isActive
                            ? colorScheme.primary
                            : colorScheme.onSurface),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(
      BuildContext context, bool isExpanded, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    final sidebarProvider = Provider.of<SidebarProvider>(context, listen: false);

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
          if (isExpanded) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 40),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMedium,
                  vertical: AppDimensions.spacingSmall),
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
                      const SizedBox(width: AppDimensions.spacingSmall),
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
              onTap: () => sidebarProvider.toggleSidebar(),
              child: Container(
                height: AppDimensions.sidebarFooterHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant, width: 1),
                  ),
                ),
                child: Icon(
                  isExpanded ? Icons.chevron_left : Icons.chevron_right,
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