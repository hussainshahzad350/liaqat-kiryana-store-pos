import 'package:flutter/material.dart';
import '../../customers/customers_screen.dart';

class CustomersManagementView extends StatefulWidget {
  const CustomersManagementView({super.key});

  @override
  State<CustomersManagementView> createState() =>
      _CustomersManagementViewState();
}

class _CustomersManagementViewState extends State<CustomersManagementView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const CustomersScreen();
  }

  @override
  bool get wantKeepAlive => true;
}
