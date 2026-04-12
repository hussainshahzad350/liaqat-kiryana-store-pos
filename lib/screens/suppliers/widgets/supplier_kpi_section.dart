import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../domain/entities/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../controller/supplier_controller.dart';
import 'supplier_kpi_card.dart';

class SupplierKpiSection extends StatelessWidget {
  const SupplierKpiSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        return SizedBox(
          height: 115.0,
          child: Row(
            children: [
              Expanded(
                child: SupplierKpiCard(
                  title: loc.dashboardTotal,
                  count: controller.countTotal,
                  balance: Money(controller.balTotal),
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: SupplierKpiCard(
                  title: loc.dashboardActive,
                  count: controller.countActive,
                  balance: Money(controller.balActive),
                ),
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Expanded(
                child: SupplierKpiCard(
                  title: loc.dashboardArchived,
                  count: controller.countArchived,
                  balance: Money(controller.balArchived),
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
