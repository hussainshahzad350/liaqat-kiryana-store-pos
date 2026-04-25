import 'package:flutter/material.dart';
import '../../items/items_screen.dart';

class ItemsManagementView extends StatefulWidget {
  const ItemsManagementView({super.key});

  @override
  State<ItemsManagementView> createState() => _ItemsManagementViewState();
}

class _ItemsManagementViewState extends State<ItemsManagementView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const ItemsScreen();
  }

  @override
  bool get wantKeepAlive => true;
}
