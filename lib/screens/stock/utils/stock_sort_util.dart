import '../../../core/entity/stock_item_entity.dart';

class StockSortUtil {
  static List<StockItemEntity> sort({
    required List<StockItemEntity> items,
    required int columnIndex,
    required bool ascending,
  }) {
    final sorted = List<StockItemEntity>.from(items);
    sorted.sort((a, b) {
      int result = 0;
      switch (columnIndex) {
        case 0:
          result = a.nameEnglish.compareTo(b.nameEnglish);
          break;
        case 1:
          result = (a.categoryName ?? '').compareTo(b.categoryName ?? '');
          break;
        case 2:
          result = a.costPrice.paisas.compareTo(b.costPrice.paisas);
          break;
        case 3:
          result = a.salePrice.paisas.compareTo(b.salePrice.paisas);
          break;
        case 4:
          result = a.currentStock.compareTo(b.currentStock);
          break;
        case 5:
          result = a.totalSalesValue.paisas.compareTo(b.totalSalesValue.paisas);
          break;
      }
      return ascending ? result : -result;
    });
    return sorted;
  }
}
