// lib/core/providers/sidebar_provider.dart

import 'package:flutter/material.dart';

class SidebarProvider with ChangeNotifier {
  bool _isSidebarExpanded = true;

  bool get isSidebarExpanded => _isSidebarExpanded;

  void toggleSidebar() {
    _isSidebarExpanded = !_isSidebarExpanded;
    notifyListeners();
  }
}
