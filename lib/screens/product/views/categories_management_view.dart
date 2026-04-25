import 'package:flutter/material.dart';
import '../../categories/categories_screen.dart';

class CategoriesManagementView extends StatefulWidget {
  const CategoriesManagementView({super.key});

  @override
  State<CategoriesManagementView> createState() =>
      _CategoriesManagementViewState();
}

class _CategoriesManagementViewState extends State<CategoriesManagementView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const CategoriesScreen();
  }

  @override
  bool get wantKeepAlive => true;
}
