import 'package:flutter/material.dart';
import '../../../bloc/sales/sales_state.dart';
import '../../../core/res/app_layout.dart';
import '../../../core/res/app_tokens.dart';
import '../../../core/services/sales_kpi_service.dart';
import '../../../widgets/loading_overlay.dart';
import 'sales_actions_toolbar.dart';
import 'sales_kpi_header.dart';

/// Responsive presentation frame. It neither calculates nor persists sales.
class SalesWorkspace extends StatelessWidget {
  const SalesWorkspace(
      {super.key,
      required this.state,
      required this.service,
      required this.onRefresh,
      required this.onClearCart,
      required this.products,
      required this.cart});
  final SalesState state;
  final SalesKpiService service;
  final VoidCallback onRefresh;
  final VoidCallback onClearCart;
  final Widget products;
  final Widget cart;
  @override
  Widget build(BuildContext context) => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Stack(children: [
        Column(children: [
          Row(children: [
            Expanded(child: SalesKpiHeader(service: service)),
            SalesActionsToolbar(onRefresh: onRefresh, onClearCart: onClearCart),
          ]),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(AppTokens.surfacePadding),
                  child: LayoutBuilder(
                      builder: (context, constraints) => Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: products),
                                const SizedBox(width: AppTokens.contentGap),
                                SizedBox(
                                    width: AppLayout.salesSidePanelWidth(
                                        constraints.maxWidth -
                                            AppTokens.contentGap),
                                    child: cart),
                              ])))),
        ]),
        if (state.status == SalesStatus.loading) const LoadingOverlay(),
      ]));
}
