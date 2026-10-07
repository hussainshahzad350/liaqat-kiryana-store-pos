import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_search_card.dart';
import '../controller/supplier_controller.dart';

class SupplierSearchBar extends StatelessWidget {
  const SupplierSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SupplierController>();

    return AppSearchCard(
      hintText: AppLocalizations.of(context)!.search,
      onChanged: (value) {
        controller.onSearchChanged(value);
      },
      onMoveDown: () => controller.handleKeyboardNavigation(true),
      onMoveUp: () => controller.handleKeyboardNavigation(false),
      onSubmitSelection: () => controller.submitSelected(),
    );
  }
}
