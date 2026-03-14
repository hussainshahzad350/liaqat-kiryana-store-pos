
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'stock_ui_state.dart';

class StockUiCubit extends Cubit<StockUiState> {
  StockUiCubit() : super(const StockUiState());

  void setSort(int columnIndex, bool ascending) => emit(
      state.copyWith(sortColumnIndex: columnIndex, isAscending: ascending));

  void setFocusedIndex(int index) => emit(state.copyWith(focusedIndex: index));

  void moveFocusUp() {
    if (state.focusedIndex > 0) {
      emit(state.copyWith(focusedIndex: state.focusedIndex - 1));
    }
  }

  void moveFocusDown(int maxItems) {
    if (state.focusedIndex < maxItems - 1) {
      emit(state.copyWith(focusedIndex: state.focusedIndex + 1));
    }
  }

  void openSidePanel(String title) => emit(state.copyWith(
        showSidePanel: true,
        sidePanelTitle: title,
      ));

  void closeSidePanel() => emit(state.copyWith(showSidePanel: false));
}
