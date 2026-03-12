import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../widgets/skeleton_loader.dart';

class ActivityTableSkeletonWidget extends StatelessWidget {
  final ColorScheme colorScheme;

  const ActivityTableSkeletonWidget({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppTokens.cardBorderRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(width: 150, height: 24.0),
            const SizedBox(height: AppTokens.spacingLarge),
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTokens.spacingStandard),
                itemBuilder: (_, __) => const SkeletonLoader(height: 24.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
