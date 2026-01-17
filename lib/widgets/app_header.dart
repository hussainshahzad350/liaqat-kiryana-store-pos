import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/res/app_dimensions.dart';
import '../l10n/app_localizations.dart';
import '../core/routes/app_routes.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String currentRoute;

  const AppHeader({super.key, required this.currentRoute});

  String _getScreenTitle(BuildContext context, String route) {
    final localizations = AppLocalizations.of(context)!;
    switch (route) {
      case AppRoutes.home:
        return localizations.dashboard;
      case AppRoutes.sales:
        return localizations.sales;
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
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final screenTitle = _getScreenTitle(context, currentRoute);

    return Container(
      height: AppDimensions.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLarge),
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
          // LEFT: Shop Icon + Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store_mall_directory,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMedium),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.appTitle, // "Liaqat Kiryana Store"
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    'POS System', // Subtitle or specific branch if needed
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // CENTER: Screen Title
          Expanded(
            child: Center(
              child: Text(
                screenTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                  letterSpacing: 0.5,
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
  
  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.headerHeight);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.onPrimary.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 14, color: colorScheme.onPrimary.withOpacity(0.9)),
              const SizedBox(width: 6),
              Text(
                _currentTime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _currentDate,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onPrimary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
