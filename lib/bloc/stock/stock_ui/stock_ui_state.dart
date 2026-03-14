part of 'stock_ui_cubit.dart';

class StockUiState extends Equatable {
  final int sortColumnIndex;
  final bool isAscending;
  final int focusedIndex;
  final bool showSidePanel;
  final String sidePanelTitle;

  const StockUiState({
    this.sortColumnIndex = 0,
    this.isAscending = true,
    this.focusedIndex = 0,
    this.showSidePanel = false,
    this.sidePanelTitle = '',
  });

  StockUiState copyWith({
    int? sortColumnIndex,
    bool? isAscending,
    int? focusedIndex,
    bool? showSidePanel,
    String? sidePanelTitle,
  }) =>
      StockUiState(
        sortColumnIndex: sortColumnIndex ?? this.sortColumnIndex,
        isAscending: isAscending ?? this.isAscending,
        focusedIndex: focusedIndex ?? this.focusedIndex,
        showSidePanel: showSidePanel ?? this.showSidePanel,
        sidePanelTitle: sidePanelTitle ?? this.sidePanelTitle,
      );

  @override
  List<Object?> get props => [
        sortColumnIndex,
        isAscending,
        focusedIndex,
        showSidePanel,
        sidePanelTitle,
      ];
}
