import 'package:flutter/material.dart';
import '../../suppliers/suppliers_screen.dart';

class SuppliersManagementView extends StatefulWidget {
  const SuppliersManagementView({super.key});

  @override
  State<SuppliersManagementView> createState() =>
      _SuppliersManagementViewState();
}

class _SuppliersManagementViewState extends State<SuppliersManagementView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const SuppliersScreen();
  }

  @override
  bool get wantKeepAlive => true;
}
