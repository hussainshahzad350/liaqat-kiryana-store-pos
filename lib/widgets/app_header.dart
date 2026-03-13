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
      case AppRoutes.home:
        return localizations.dashboard;
      case AppRoutes.sales:
        return localizations.sales;
      case AppRoutes.purchase:
        return localizations.purchase;
      case AppRoutes.stock:
        return localizations.stockManagement;
      case AppRoutes.customers:
        return localizations.customers;
      case AppRoutes.reports:
        return localizations.reports;
      case AppRoutes.settings:
        return localizations.settings;
      case AppRoutes.cashLedger:
        return localizations.cashLedger;
      case AppRoutes.about:
        return localizations.about;
      default:
        // Try to capitalize and format unknown routes or return empty
        return route.replaceAll('/', '').replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenTitle = _getScreenTitle(context, currentRoute);

    return Container(
      height: AppTokens.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingLarge),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // CENTER: Screen Title
          Expanded(
            child: Center(
              child: Text(
                screenTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
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
        color: colorScheme.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: colorScheme.onPrimary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time,
                  size: 12, color: colorScheme.onPrimary.withValues(alpha: 0.9)),
              const SizedBox(width: 4),
              Text(
                _currentTime,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            _currentDate,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
