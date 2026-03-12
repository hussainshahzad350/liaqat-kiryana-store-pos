import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../widgets/skeleton_loader.dart';

class StockTableSkeletonWidget extends StatelessWidget {
  final ColorScheme colorScheme;

  const StockTableSkeletonWidget({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTokens.cardBorderRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: 200, height: 24.0),
            const SizedBox(height: AppTokens.spacingLarge),
            Expanded(
              child: ListView.separated(
                itemCount: 10,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTokens.spacingMedium),
                itemBuilder: (_, __) => const Row(
                  children: [
                    Expanded(flex: 2, child: SkeletonLoader(height: 14.0)),
                    SizedBox(width: AppTokens.spacingMedium),
                    Expanded(flex: 1, child: SkeletonLoader(height: 14.0)),
                    SizedBox(width: AppTokens.spacingMedium),
                    Expanded(flex: 1, child: SkeletonLoader(height: 14.0)),
                    SizedBox(width: AppTokens.spacingMedium),
                    Expanded(flex: 1, child: SkeletonLoader(height: 14.0)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
