import 'package:flutter_bloc/flutter_bloc.dart';

/// State: bool = true means expanded, false means collapsed
class SidebarCubit extends Cubit<bool> {
  SidebarCubit() : super(true); // Default: expanded

  /// Toggle between expanded and collapsed
  void toggle() => emit(!state);

  /// Force expand the sidebar
  void expand() => emit(true);

  /// Force collapse the sidebar
  void collapse() => emit(false);

  /// Whether the sidebar is currently expanded
  bool get isExpanded => state;
}
