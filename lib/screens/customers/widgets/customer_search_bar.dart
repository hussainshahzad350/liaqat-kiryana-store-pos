import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_search_card.dart';
import '../controller/customer_controller.dart';

class CustomerSearchBar extends StatelessWidget {
  const CustomerSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CustomerController>();

    return AppSearchCard(
      hintText: AppLocalizations.of(context)!.searchPlaceholder,
      onChanged: (value) {
        controller.onSearchChanged(value);
      },
      onMoveDown: () => controller.handleKeyboardNavigation(true),
      onMoveUp: () => controller.handleKeyboardNavigation(false),
      onSubmitSelection: () => controller.submitSelected(),
    );
  }
}
