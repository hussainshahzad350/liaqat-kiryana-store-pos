import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../domain/entities/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../controller/customer_controller.dart';
import 'customer_kpi_card.dart';

class CustomerKpiSection extends StatelessWidget {
  const CustomerKpiSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Consumer<CustomerController>(
      builder: (context, controller, child) {
        return SizedBox(
          height: 115.0,
          child: Row(
            children: [
              Expanded(
                child: CustomerKpiCard(
                  title: loc.dashboardTotal,
                  count: controller.countTotal,
                  balance: Money(controller.balTotal),
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: CustomerKpiCard(
                  title: loc.dashboardActive,
                  count: controller.countActive,
                  balance: Money(controller.balActive),
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: CustomerKpiCard(
                  title: loc.dashboardArchived,
                  count: controller.countArchived,
                  balance: Money(controller.balArchived),
                  isTertiary: true,
                  onTap: () {
                    controller.toggleArchiveView();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
