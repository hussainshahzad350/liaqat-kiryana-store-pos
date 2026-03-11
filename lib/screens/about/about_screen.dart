import 'package:flutter/material.dart';
import '../../core/res/app_tokens.dart';
import '../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.spacingMedium),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // App Logo and Info
                  Card(
                    elevation: AppTokens.cardElevation,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppTokens.cardBorderRadius),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppTokens.spacingXLarge),
                      child: Column(
                        children: [
                          Container(
                            width: AppTokens.aboutLogoSize,  // ✅ Fixed
                            height: AppTokens.aboutLogoSize, // ✅ Fixed
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                  AppTokens.cardBorderRadius),
                            ),
                            child: Icon(
                              Icons.store,
                              size: AppTokens.aboutIconScale,  // ✅ Fixed
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(
                              height: AppTokens.spacingLarge),
                          Text(
                            loc.appTitle,
                            style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface),
                          ),
                          const SizedBox(
                              height: AppTokens.spacingSmall),
                          Text(
                            '${loc.version}: 1.0.0',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(
                              height: AppTokens.spacingSmall),
                          Text(
                            loc.appDescription,
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingLarge),

                  Card(
                    elevation: AppTokens.cardElevation,  // ✅ Added
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppTokens.cardBorderRadius),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppTokens.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.techInfo,
                            style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface),
                          ),
                          const SizedBox(
                              height: AppTokens.spacingXSmall),
                          _buildTechItem(
                              context, loc.framework, 'Flutter 3.0+'),
                          _buildTechItem(
                              context, loc.platform, 'Linux Desktop'),
                          _buildTechItem(context, loc.database,
                              'SQLite with sqflite_common_ffi'),
                          _buildTechItem(context, loc.stateManagement, 'Bloc'),
                          _buildTechItem(
                              context, loc.uiFramework, 'Material Design 3'),
                          const SizedBox(
                              height: AppTokens.spacingXSmall),
                          Text(
                            loc.lastUpdated('December 2024'),
                            style: textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingLarge),

                  Card(
                    elevation: AppTokens.cardElevation,  // ✅ Added
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppTokens.cardBorderRadius),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppTokens.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.features,
                            style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface),
                          ),
                          const SizedBox(
                              height: AppTokens.spacingMedium),
                          _buildFeatureItem(context, loc.featurePos),
                          _buildFeatureItem(
                              context, loc.featureStockManagement),
                          _buildFeatureItem(
                              context, loc.featureCustomerManagement),
                          _buildFeatureItem(context, loc.featureReporting),
                          _buildFeatureItem(context, loc.featureBackup),
                          _buildFeatureItem(context, loc.featureBilingual),
                          _buildFeatureItem(context, loc.featurePrinter),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingLarge),

                  // ✅ Changed from Container to Card for consistency
                  Card(
                    elevation: AppTokens.cardElevation,  // ✅ Added
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppTokens.cardBorderRadius),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(AppTokens.spacingMedium),
                      child: Column(
                        children: [
                          Text(
                            loc.copyright,
                            style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: AppTokens.spacingSmall),
                          Text(
                            loc.allRightsReserved,
                            style: textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(BuildContext context, String label, String value) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppTokens.spacingSmall),
      child: Row(
        children: [
          SizedBox(
            width: AppTokens.sidebarMinWidth / 3,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            ': ',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: AppTokens.spacingSmall),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              color: colorScheme.primary,
              size: AppTokens.kpiIconSize),
          const SizedBox(width: AppTokens.spacingMedium),
          Expanded(
              child: Text(
            feature,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          )),
        ],
      ),
    );
  }
}
