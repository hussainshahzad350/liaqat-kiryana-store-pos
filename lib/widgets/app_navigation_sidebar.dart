import 'app_feature_theme.dart';
// lib/widgets/app_navigation_sidebar.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';
import '../core/cubits/sidebar_cubit.dart';
import '../core/res/app_tokens.dart';
import '../core/res/app_layout.dart';
import 'app_shell.dart';

class AppNavigationSidebar extends StatelessWidget {
  final String currentRoute;

  const AppNavigationSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) => AppFeatureTheme(builder: _buildFeature);

  Widget _buildFeature(BuildContext context) {
    final isExpanded = context.watch<SidebarCubit>().isExpanded &&
        !AppLayout.useNavigationRail(MediaQuery.sizeOf(context).width);
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: isExpanded
          ? AppTokens.sidebarExpandedWidth
          : AppTokens.sidebarCollapsedWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: BorderDirectional(
          end: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
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
                    icon: Icons.shopping_cart,
                    title: localizations.salesPos,
                    route: AppRoutes.sales,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.warehouse,
                    title: localizations.productsAndStock,
                    route: AppRoutes.stock,
                    activeRoutes: const {AppRoutes.product},
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.receipt_long,
                    title: localizations.purchase,
                    route: AppRoutes.purchase,
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.account_balance_wallet,
                    title: localizations.accounts,
                    route: AppRoutes.accounts,
                    activeRoutes: const {
                      AppRoutes.customers,
                      AppRoutes.suppliers
                    },
                  ),
                  _buildMenuItem(
                    context,
                    isExpanded: isExpanded,
                    icon: Icons.payments_outlined,
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
                    icon: Icons.logout,
                    title: localizations.logout,
                    route: AppRoutes.logout,
                    color: colorScheme.error,
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.logout,
                        (_) => false,
                      );
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
      height: AppTokens.sidebarHeaderHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTokens.radius8),
            ),
            child: Icon(
              Icons.store,
              size: 22,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.appTitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                textAlign: TextAlign.start,
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
    Set<String>? activeRoutes,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isActive = currentRoute == route ||
        (activeRoutes != null && activeRoutes.contains(currentRoute));
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
        message: title,
        child: Semantics(
            selected: isActive,
            label: isExpanded ? null : title,
            button: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingSmall,
                  vertical: AppTokens.spacingSmall / 2),
              child: Material(
                color: isActive
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius8),
                  side: isActive
                      ? BorderSide(color: colorScheme.primary, width: 1)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: onTap ??
                      () {
                        if (currentRoute != route) {
                          AppShell.navigateTo(context, route);
                        }
                      },
                  borderRadius: BorderRadius.circular(AppTokens.radius8),
                  child: SizedBox(
                    height: AppTokens.menuItemHeight,
                    child: Row(
                      mainAxisAlignment: isExpanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                              start: isExpanded ? 12.0 : 0),
                          child: Icon(
                            icon,
                            size: AppTokens.menuItemIconSize,
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
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
                ),
              ),
            )));
  }

  Widget _buildSidebarFooter(
      BuildContext context, bool isExpanded, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExpanded) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingMedium,
                  vertical: AppTokens.spacingSmall),
              child: SingleChildScrollView(
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
                        const SizedBox(width: AppTokens.spacingSmall),
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
            ),
          ],
          if (!AppLayout.useNavigationRail(MediaQuery.sizeOf(context).width))
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.read<SidebarCubit>().toggle(),
                child: Container(
                  height: AppTokens.sidebarFooterHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: colorScheme.outlineVariant, width: 1),
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
