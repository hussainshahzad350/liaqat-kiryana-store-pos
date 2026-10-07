import 'app_feature_theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/res/app_tokens.dart';
import '../l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';

class AppHeader extends StatelessWidget {
  final String currentRoute;

  const AppHeader({super.key, required this.currentRoute});

  String _getScreenTitle(BuildContext context, String route) {
    final localizations = AppLocalizations.of(context)!;
    switch (route) {
      case AppRoutes.sales:
        return localizations.sales;
      case AppRoutes.purchase:
        return localizations.purchase;
      case AppRoutes.stock:
        return localizations.stockManagement;
      case AppRoutes.product:
        return localizations.product;
      case AppRoutes.customers:
      case AppRoutes.suppliers:
      case AppRoutes.accounts:
        return localizations.accounts;
      case AppRoutes.settings:
        return localizations.settings;
      case AppRoutes.cashLedger:
        return localizations.cashLedger;
      default:
        // Try to capitalize and format unknown routes or return empty
        return route.replaceAll('/', '').replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) => AppFeatureTheme(builder: _buildFeature);

  Widget _buildFeature(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenTitle = _getScreenTitle(context, currentRoute);

    return Container(
      constraints: const BoxConstraints(minHeight: AppTokens.headerHeight),
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          // CENTER: Screen Title
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                screenTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // RIGHT: Live Clock
          const LiveClock(),
        ],
      ),
    );
  }
}

class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Timer _timer;
  String _currentTime = '';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('hh:mm a').format(now);
      _currentDate = DateFormat('dd MMM yyyy').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time,
                  size: 12, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                _currentTime,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            _currentDate,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
