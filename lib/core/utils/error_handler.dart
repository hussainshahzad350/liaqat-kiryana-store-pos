import 'package:flutter/material.dart';
import 'package:liaqat_store/core/utils/logger.dart';
import '../../l10n/app_localizations.dart';

class ErrorHandler {
  static void handleError(
    BuildContext context,
    dynamic error, {
    String tag = 'Error',
    bool showSnackbar = true,
  }) {
    AppLogger.error('$error', tag: tag);

    if (showSnackbar && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getLocalizedMessage(
              error.toString(), AppLocalizations.of(context)!)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Converts technical error messages to user-friendly localized strings
  ///
  /// Returns the localized error message if a mapping exists,
  /// otherwise logs the raw message and returns unknownError
  static String getLocalizedMessage(
    String? errorMessage,
    AppLocalizations loc,
  ) {
    if (errorMessage == null || errorMessage.isEmpty) {
      return loc.unknownError;
    }

    final normalized = errorMessage.replaceFirst('Exception: ', '').trim();

    if (normalized.startsWith('CATEGORY_IN_USE:')) {
      final countText = normalized.substring('CATEGORY_IN_USE:'.length);
      final count = int.tryParse(countText) ?? 0;
      return loc.categoryInUseDeleteError(count);
    }

    if (normalized.startsWith('DEPARTMENT_IN_USE:')) {
      final countText = normalized.substring('DEPARTMENT_IN_USE:'.length);
      final count = int.tryParse(countText) ?? 0;
      return loc.departmentInUseDeleteError(count);
    }

    if (normalized.startsWith('SUBCATEGORY_IN_USE:')) {
      final countText = normalized.substring('SUBCATEGORY_IN_USE:'.length);
      final count = int.tryParse(countText) ?? 0;
      return loc.subCategoryInUseDeleteError(count);
    }

    // Handle INSUFFICIENT_STOCK with optional item payload
    if (normalized.startsWith('INSUFFICIENT_STOCK:')) {
      final item = normalized.substring('INSUFFICIENT_STOCK:'.length).trim();
      return item.isNotEmpty
          ? loc.insufficientStockForItem(item)
          : loc.insufficientStock;
    }

    // Exact-match sentinel codes
    final Map<String, String Function(AppLocalizations)> sentinelMap = {
      'PRODUCT_NOT_FOUND': (l) => l.productNotFound,
      'PURCHASE_NOT_FOUND': (l) => l.purchaseNotFound,
      'INVOICE_NOT_FOUND': (l) => l.invoiceNotFound,
      'SUPPLIER_NOT_FOUND': (l) => l.supplierNotFound,
      'INSUFFICIENT_STOCK_FOR_CANCELLATION': (l) =>
          l.insufficientStockForCancellation,
      'INSUFFICIENT_STOCK': (l) => l.insufficientStock,
      'NEGATIVE_STOCK': (l) => l.negativeStockError,
      'INVALID_PRICE_ADJUSTMENT': (l) => l.invalidPriceAdjustment,
      'CREDIT_LIMIT_EXCEEDED': (l) => l.creditLimitExceeded,
      'INVOICE_MATH_ERROR': (l) => l.invoiceMathError,
      'INVOICE_EMPTY': (l) => l.invoiceEmpty,
      'PAYMENT_NEGATIVE': (l) => l.paymentNegative,
      'PAYMENT_SPLIT_MISMATCH': (l) => l.paymentSplitMismatch,
      'PAYMENT_FAILED': (l) => l.paymentFailed,
    };
    final sentinelResult = sentinelMap[normalized]?.call(loc);
    if (sentinelResult != null) return sentinelResult;

    final errorMap = {
      'Cannot print cancelled invoice': loc.cannotPrintCancelled,
      'Phone already exists': loc.phoneExistsError,
      'Phone number is required': loc.phoneRequired,
      'Name is required': loc.nameRequired,
      'Insufficient stock': loc.insufficientStockError,
      'Out of stock': loc.outOfStockError,
      'Stock limit reached': loc.stockLimitError,
      'Product sale price cannot be negative': loc.negativePriceError,
      'Item price cannot be negative': loc.itemNegativePriceError,
      'Stock adjustment submitted': loc.stockUpdated,
      'Transaction cancelled successfully': loc.invoiceCancelledSuccess,
      'System units cannot be edited.': loc.systemUnitWarning,
      'System units cannot be deleted.': loc.systemUnitWarning,
    };

    final mapped = errorMap[normalized];
    if (mapped != null) {
      return mapped;
    }

    AppLogger.error(
      'Unmapped error message: $normalized',
      tag: 'ErrorHandler',
    );
    return loc.unknownError;
  }
}
