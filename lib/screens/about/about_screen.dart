import 'package:flutter/material.dart';
import '../../widgets/main_layout.dart';
import '../../core/constants/desktop_dimensions.dart';
import '../../core/res/app_dimensions.dart';
import '../../core/routes/app_routes.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_header.dart';


class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return MainLayout(
      currentRoute: AppRoutes.about,
      child: Column(
        children: [
          AppHeader(
            title: loc.about,
            icon: Icons.info_outline,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesktopDimensions.spacingLarge),
              child: Column(
                children: [
                  // App Logo and Info
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          DesktopDimensions.cardBorderRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                          DesktopDimensions.spacingXXLarge),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                  DesktopDimensions.cardBorderRadius),
                            ),
                            child: Icon(
                              Icons.store,
                              size: 60,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(
                              height: DesktopDimensions.spacingLarge),
                          Text(
                            loc.appTitle,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingSmall),
                          Text(
                            '${loc.version}: 1.0.0',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(
                              height: AppDimensions.spacingMedium),
                          Text(
                            loc.appDescription,
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesktopDimensions.spacingLarge),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          DesktopDimensions.cardBorderRadius),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(DesktopDimensions.spacingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.techInfo,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingLarge),
                          _buildTechItem(context, loc.framework, 'Flutter 3.0+'),
                          _buildTechItem(
                              context, loc.platform, 'Linux Desktop'),
                          _buildTechItem(context, loc.database,
                              'SQLite with sqflite_common_ffi'),
                          _buildTechItem(
                              context, loc.stateManagement, 'Bloc'),
                          _buildTechItem(context, loc.uiFramework,
                              'Material Design 3'),
                          _buildTechItem(
                              context, loc.lastUpdated, 'December 2024'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesktopDimensions.spacingLarge),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          DesktopDimensions.cardBorderRadius),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(DesktopDimensions.spacingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.features,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(
                              height: AppDimensions.spacingMedium),
                          _buildFeatureItem(context, loc.featurePos),
                          _buildFeatureItem(
                              context, loc.featureStockManagement),
                          _buildFeatureItem(
                              context, loc.featureCustomerManagement),
                          _buildFeatureItem(
                              context, loc.featureReporting),
                          _buildFeatureItem(
                              context, loc.featureBackup),
                          _buildFeatureItem(
                              context, loc.featureBilingual),
                          _buildFeatureItem(
                              context, loc.featurePrinter),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DesktopDimensions.spacingXXLarge),
                  Container(
                    padding:
                        const EdgeInsets.all(DesktopDimensions.spacingLarge),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                    child: Column(
                      children: [
                        Text(
                          loc.copyright,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSmall),
                        Text(
                          loc.allRightsReserved,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesktopDimensions.spacingXXLarge),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            ': ',
            style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) { // Added context
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colorScheme.primary, size: 16), // Use theme primary color
          const SizedBox(width: 10),
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